#!/usr/bin/env python3
"""Validate one cover-refinement scorecard against current digital evidence.

Usage:
    COBIE_ITERATION_ID=I01 \
      uv run --project cobie-collectible/tools --locked \
      python cobie-collectible/scripts/score_refinement.py

The ratings are an explicit GPT-5.6/human visual judgment, not an invented
feature detector. This script only validates the rubric math, evidence binding,
and hard mechanical gates.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    BUILD_REPORT,
    COLLECTIBLE,
    EXPORTS,
    ROOT,
    SLICER_TESTS,
    VALIDATION_RENDERS,
    Failure,
    check_build_receipt,
    report,
    sha256_file,
    write_json,
)

CATEGORIES = {
    "silhouette": 20,
    "head_and_fur_identity": 20,
    "pose_and_weight": 15,
    "jacket_construction": 15,
    "fetch_launcher": 15,
    "aviators": 5,
    "neutral_geometry_evidence": 5,
    "material_and_color_cohesion": 5,
}
TARGET_SCORE = 85
TARGET_MINIMUM_RATING = 4
ITERATION_ID = os.environ.get("COBIE_ITERATION_ID", "")
RATING_DIR = COLLECTIBLE / "refinement" / "cover-v2" / "ratings"
RATING_PATH = RATING_DIR / f"{ITERATION_ID}.json"
REPORT_PATH = RATING_DIR / f"{ITERATION_ID}_report.json"
PRINT_REPORT = EXPORTS / "print_check_report.json"
SLICER_REPORT = SLICER_TESTS / "prusaslicer_import_report.json"


def weighted_score(ratings: dict[str, int]) -> float:
    return sum(
        CATEGORIES[category] * ratings.get(category, 0) / 5.0
        for category in CATEGORIES
    )


def acceptance_target_met(ratings: dict[str, int]) -> bool:
    return (
        bool(ratings)
        and weighted_score(ratings) >= TARGET_SCORE
        and min(ratings.values()) >= TARGET_MINIMUM_RATING
    )


def _load_object(path: Path, *, check: str, failures: list[Failure]) -> dict:
    if path.is_symlink() or not path.is_file():
        failures.append(Failure(check, str(path), "file is missing or is a symlink"))
        return {}
    try:
        payload = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        failures.append(Failure(check, str(path), f"cannot parse JSON: {exc}"))
        return {}
    if not isinstance(payload, dict):
        failures.append(Failure(check, str(path), "JSON root must be an object"))
        return {}
    return payload


def _check_gate_report(
    path: Path,
    *,
    check: str,
    expected_build_sha256: str,
    failures: list[Failure],
) -> dict:
    payload = _load_object(path, check=check, failures=failures)
    if payload.get("failures") != []:
        failures.append(Failure(check, str(path), "gate report does not contain an empty failure list"))
    receipt = payload.get("build_receipt")
    if not isinstance(receipt, dict):
        metrics = payload.get("metrics")
        if isinstance(metrics, dict):
            receipt = metrics.get("build_receipt")
    if not isinstance(receipt, dict) or receipt.get("sha256") != expected_build_sha256:
        failures.append(Failure(check, str(path), "report is not bound to the current build receipt"))
    return payload


def _run() -> int:
    failures: list[Failure] = []
    if not ITERATION_ID or not ITERATION_ID.startswith("I"):
        failures.append(
            Failure(
                "iteration_id",
                ITERATION_ID or "(empty)",
                "set COBIE_ITERATION_ID to a named rating packet such as I01",
            )
        )
    rating = _load_object(RATING_PATH, check="rating_packet", failures=failures)
    ratings = rating.get("ratings")
    if not isinstance(ratings, dict) or set(ratings) != set(CATEGORIES):
        observed = sorted(ratings) if isinstance(ratings, dict) else []
        failures.append(
            Failure(
                "rating_inventory",
                str(RATING_PATH),
                f"expected={sorted(CATEGORIES)} observed={observed}",
            )
        )
        ratings = {}

    numeric_ratings: dict[str, int] = {}
    for category in CATEGORIES:
        value = ratings.get(category)
        if not isinstance(value, int) or isinstance(value, bool) or not 0 <= value <= 5:
            failures.append(
                Failure(
                    "rating_range",
                    category,
                    f"rating must be an integer from 0 through 5, got {value!r}",
                )
            )
            continue
        numeric_ratings[category] = value

    score = weighted_score(numeric_ratings)
    score_before = rating.get("score_before")
    if not isinstance(score_before, (int, float)) or isinstance(score_before, bool):
        failures.append(
            Failure("score_before", str(RATING_PATH), "score_before must be numeric")
        )
        score_before = score

    receipt_failures, build_receipt = check_build_receipt()
    failures.extend(receipt_failures)
    build_sha256 = sha256_file(BUILD_REPORT) if BUILD_REPORT.is_file() else ""
    _check_gate_report(
        PRINT_REPORT,
        check="print_gate",
        expected_build_sha256=build_sha256,
        failures=failures,
    )
    _check_gate_report(
        SLICER_REPORT,
        check="slicer_gate",
        expected_build_sha256=build_sha256,
        failures=failures,
    )

    evidence = rating.get("evidence")
    if not isinstance(evidence, dict):
        failures.append(Failure("evidence", str(RATING_PATH), "evidence must be an object"))
        evidence = {}
    neutral_id = evidence.get("neutral_render_id")
    neutral_path = (
        VALIDATION_RENDERS / neutral_id / "render_report.json"
        if isinstance(neutral_id, str)
        else Path("__missing_neutral_report__")
    )
    neutral = _load_object(neutral_path, check="neutral_render", failures=failures)
    if neutral.get("failures") != []:
        failures.append(Failure("neutral_render", str(neutral_path), "neutral packet did not pass"))
    neutral_receipt = neutral.get("build_receipt")
    if not isinstance(neutral_receipt, dict) or neutral_receipt.get("sha256") != build_sha256:
        failures.append(
            Failure("neutral_render", str(neutral_path), "neutral packet is not bound to current build")
        )

    lookdev_relative = evidence.get("lookdev_report")
    if isinstance(lookdev_relative, str):
        lookdev_path = (ROOT / lookdev_relative).resolve()
        root = ROOT.resolve()
        if lookdev_path == root or root not in lookdev_path.parents:
            failures.append(
                Failure("lookdev_render", lookdev_relative, "lookdev report path escapes repository")
            )
        else:
            lookdev = _load_object(lookdev_path, check="lookdev_render", failures=failures)
            if lookdev.get("failures") != []:
                failures.append(
                    Failure("lookdev_render", lookdev_relative, "lookdev packet did not pass")
                )
            source_path = build_receipt.get("source_blend")
            expected_source_hash = build_receipt.get("source_blend_sha256")
            if (
                lookdev.get("source_master") != source_path
                or lookdev.get("source_sha256_before") != expected_source_hash
                or lookdev.get("source_sha256_after") != expected_source_hash
                or lookdev.get("source_unchanged") is not True
            ):
                failures.append(
                    Failure("lookdev_render", lookdev_relative, "lookdev source is not current")
                )
    elif numeric_ratings.get("material_and_color_cohesion", 0) > 0:
        failures.append(
            Failure(
                "lookdev_render",
                str(RATING_PATH),
                "a positive material/color rating requires a lookdev report",
            )
        )

    improved = score > float(score_before)
    if not improved:
        failures.append(
            Failure(
                "score_improvement",
                ITERATION_ID,
                f"candidate score {score:.1f} did not exceed {float(score_before):.1f}",
            )
        )
    target_met = acceptance_target_met(numeric_ratings)
    payload = {
        "iteration_id": ITERATION_ID,
        "rating_packet": str(RATING_PATH.relative_to(ROOT)) if RATING_PATH.is_relative_to(ROOT) else str(RATING_PATH),
        "rating_packet_sha256": sha256_file(RATING_PATH) if RATING_PATH.is_file() else None,
        "weights": CATEGORIES,
        "ratings": numeric_ratings,
        "score_before": score_before,
        "weighted_score": round(score, 1),
        "improved": improved,
        "target_score": TARGET_SCORE,
        "target_minimum_rating": TARGET_MINIMUM_RATING,
        "target_met": target_met,
        "build_receipt_sha256": build_sha256 or None,
        "failures": [failure.as_dict() for failure in failures],
        "human_gates": {
            "identity_approved": False,
            "physical_prototype_approved": False,
        },
    }
    write_json(REPORT_PATH, payload)
    print(
        f"  {ITERATION_ID}: {float(score_before):.1f} -> {score:.1f}; "
        f"target_met={str(target_met).lower()}"
    )
    return report("COBIE_REFINEMENT_SCORE", failures)


def main() -> int:
    RATING_DIR.mkdir(parents=True, exist_ok=True)
    try:
        return _run()
    except Exception as exc:
        failure = Failure("score_exception", str(REPORT_PATH), f"{type(exc).__name__}: {exc}")
        write_json(
            REPORT_PATH,
            {
                "iteration_id": ITERATION_ID,
                "failures": [failure.as_dict()],
                "target_met": False,
            },
        )
        return report("COBIE_REFINEMENT_SCORE", [failure])


if __name__ == "__main__":
    raise SystemExit(main())
