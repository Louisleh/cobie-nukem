#!/usr/bin/env python3
"""Build the Visual Foundry before/candidate/difference review image."""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFont, ImageOps

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    BUILD_REPORT,
    ROOT,
    TURNAROUND_VIEWS,
    VALIDATION_RENDERS,
    Failure,
    check_build_receipt,
    figurine_render_protocol,
    report,
    sha256_file,
    write_json,
)

BASELINE_ID = os.environ.get("COBIE_RENDER_BASELINE_ID", "proxy-baseline")
CANDIDATE_ID = os.environ.get("COBIE_RENDER_ID", "prototype-v1")
VIEWS = ("front", "hero")
PANEL_SIZE = 640
HEADER_HEIGHT = 54
FOOTER_HEIGHT = 58
VIEW_ORDER = ("front", "left", "rear", "right", "hero")
EXPECTED_PROTOCOL = figurine_render_protocol()
HEX_OBJECT_RE = re.compile(r"[0-9a-f]{40}(?:[0-9a-f]{24})?")
SHA256_RE = re.compile(r"[0-9a-f]{64}")


def label(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, colour: tuple[int, int, int]) -> None:
    draw.text((x, y), text, fill=colour, font=ImageFont.load_default(size=20))


def git_history_contains_file_hash(relative_path: str, expected_sha256: str) -> bool:
    """Accept an older committed generator/renderer after the live file moves on."""
    try:
        revisions = subprocess.run(
            ["git", "log", "--all", "--format=%H", "--", relative_path],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout.splitlines()
        for revision in revisions:
            content = subprocess.run(
                ["git", "show", f"{revision}:{relative_path}"],
                cwd=ROOT,
                check=True,
                capture_output=True,
                timeout=10,
            ).stdout
            if hashlib.sha256(content).hexdigest() == expected_sha256:
                return True
    except (OSError, subprocess.SubprocessError):
        return False
    return False


def validate_historical_source(payload: dict, subject: str) -> list[Failure]:
    """Require an immutable file or an exact Git revision for a baseline."""
    provenance = payload.get("source_provenance")
    if not isinstance(provenance, dict):
        source = payload.get("source_blend")
        if not isinstance(source, str):
            return [
                Failure(
                    "render_source_provenance",
                    subject,
                    "historical baseline has neither Git provenance nor a source Blender path",
                )
            ]
        relative = Path(source)
        if relative.is_absolute() or ".." in relative.parts:
            return [
                Failure("render_source_provenance", subject, f"unsafe source path {source!r}")
            ]
        source_path = ROOT / relative
        if (
            source_path.is_symlink()
            or not source_path.is_file()
            or payload.get("source_blend_sha256") != sha256_file(source_path)
        ):
            return [
                Failure(
                    "render_source_provenance",
                    subject,
                    "historical baseline source file is absent or its hash drifted",
                )
            ]
        return []

    if provenance.get("kind") == "deterministic_refinement_stage":
        required = {
            "kind",
            "generator_path",
            "generator_sha256",
            "renderer_path",
            "renderer_sha256",
            "refinement_stage",
            "historical_blend_sha256",
            "build_receipt_sha256",
        }
        if set(provenance) != required:
            return [
                Failure(
                    "render_source_provenance",
                    subject,
                    f"refinement provenance schema differs; expected={sorted(required)} "
                    f"observed={sorted(provenance)}",
                )
            ]
        failures: list[Failure] = []
        for path_key, hash_key in (
            ("generator_path", "generator_sha256"),
            ("renderer_path", "renderer_sha256"),
        ):
            raw_path = provenance.get(path_key)
            relative = Path(raw_path) if isinstance(raw_path, str) else Path("..")
            source_path = (ROOT / relative).resolve()
            root = ROOT.resolve()
            expected_hash = provenance.get(hash_key)
            safe_path = (
                isinstance(raw_path, str)
                and not relative.is_absolute()
                and ".." not in relative.parts
                and source_path != root
                and root in source_path.parents
            )
            live_matches = (
                safe_path
                and not source_path.is_symlink()
                and source_path.is_file()
                and isinstance(expected_hash, str)
                and SHA256_RE.fullmatch(expected_hash) is not None
                and expected_hash == sha256_file(source_path)
            )
            history_matches = (
                safe_path
                and isinstance(expected_hash, str)
                and SHA256_RE.fullmatch(expected_hash) is not None
                and git_history_contains_file_hash(raw_path, expected_hash)
            )
            if (
                not safe_path
                or not (live_matches or history_matches)
            ):
                failures.append(
                    Failure(
                        "render_source_provenance",
                        subject,
                        f"{path_key} is unsafe, missing, or no longer matches its recorded hash",
                    )
                )
        if provenance.get("refinement_stage") not in {
            "silhouette",
            "head",
            "costume",
            "launcher",
            "final",
        }:
            failures.append(
                Failure(
                    "render_source_provenance",
                    subject,
                    f"invalid refinement stage {provenance.get('refinement_stage')!r}",
                )
            )
        receipt = payload.get("build_receipt")
        if (
            not isinstance(receipt, dict)
            or not isinstance(provenance.get("historical_blend_sha256"), str)
            or SHA256_RE.fullmatch(provenance["historical_blend_sha256"]) is None
            or provenance.get("historical_blend_sha256")
            != payload.get("source_blend_sha256")
            or provenance.get("build_receipt_sha256") != receipt.get("sha256")
        ):
            failures.append(
                Failure(
                    "render_source_provenance",
                    subject,
                    "refinement source/build hashes are malformed or internally inconsistent",
                )
            )
        return failures

    required = {
        "kind",
        "repository_revision",
        "script_path",
        "script_blob_oid",
        "script_sha256",
        "historical_blend_sha256",
    }
    if set(provenance) != required:
        return [
            Failure(
                "render_source_provenance",
                subject,
                f"Git provenance schema differs; expected={sorted(required)} "
                f"observed={sorted(provenance)}",
            )
        ]
    revision = provenance["repository_revision"]
    script_path = provenance["script_path"]
    blob_oid = provenance["script_blob_oid"]
    script_hash = provenance["script_sha256"]
    blend_hash = provenance["historical_blend_sha256"]
    relative = Path(script_path) if isinstance(script_path, str) else Path("..")
    if (
        provenance["kind"] != "git_revision_geometry_source"
        or not isinstance(revision, str)
        or HEX_OBJECT_RE.fullmatch(revision) is None
        or not isinstance(script_path, str)
        or relative.is_absolute()
        or ".." in relative.parts
        or not isinstance(blob_oid, str)
        or HEX_OBJECT_RE.fullmatch(blob_oid) is None
        or not isinstance(script_hash, str)
        or SHA256_RE.fullmatch(script_hash) is None
        or not isinstance(blend_hash, str)
        or SHA256_RE.fullmatch(blend_hash) is None
    ):
        return [
            Failure(
                "render_source_provenance",
                subject,
                "Git provenance contains an invalid kind, revision, path, object ID, or hash",
            )
        ]

    object_spec = f"{revision}:{script_path}"
    try:
        observed_blob = subprocess.run(
            ["git", "rev-parse", "--verify", object_spec],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout.strip()
        script_content = subprocess.run(
            ["git", "show", object_spec],
            cwd=ROOT,
            check=True,
            capture_output=True,
            timeout=10,
        ).stdout
    except (OSError, subprocess.SubprocessError) as exc:
        return [
            Failure(
                "render_source_provenance",
                subject,
                f"cannot resolve historical Git source {object_spec}: {exc}",
            )
        ]
    if (
        observed_blob != blob_oid
        or hashlib.sha256(script_content.encode()).hexdigest() != script_hash
    ):
        return [
            Failure(
                "render_source_provenance",
                subject,
                "historical source revision does not match its recorded blob/content hashes",
            )
        ]
    return []


def validate_render_packet(render_id: str, *, require_current: bool) -> tuple[list[Failure], dict]:
    directory = VALIDATION_RENDERS / render_id
    report_path = directory / "render_report.json"
    subject = f"{render_id}/render_report.json"
    if not report_path.is_file():
        return [Failure("render_report_missing", subject, "render report is missing")], {}
    try:
        payload = json.loads(report_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return [Failure("render_report_invalid", subject, str(exc))], {}
    if not isinstance(payload, dict):
        return [Failure("render_report_invalid", subject, "report root must be a JSON object")], {}

    failures: list[Failure] = []
    if payload.get("render_id") != render_id:
        failures.append(
            Failure("render_id", subject, f"report identifies {payload.get('render_id')!r}")
        )
    if payload.get("failures") != []:
        failures.append(
            Failure("render_failures", subject, "source render packet did not pass its own gate")
        )
    if payload.get("resolution") != [PANEL_SIZE, PANEL_SIZE]:
        failures.append(
            Failure("render_resolution", subject, f"reported {payload.get('resolution')!r}")
        )
    if payload.get("protocol") != EXPECTED_PROTOCOL:
        failures.append(
            Failure(
                "render_protocol",
                subject,
                "camera, target, lighting, material, world, or render settings "
                "do not match the canonical review protocol",
            )
        )

    views = payload.get("views")
    if not isinstance(views, dict) or set(views) != set(VIEW_ORDER):
        observed = sorted(views) if isinstance(views, dict) else []
        failures.append(
            Failure(
                "render_view_inventory",
                subject,
                f"expected {list(VIEW_ORDER)}, observed {observed}",
            )
        )
        views = {}
    for view in VIEW_ORDER:
        entry = views.get(view)
        expected_path = directory / f"{view}.png"
        if not isinstance(entry, dict):
            continue
        if entry.get("yaw_degrees") != TURNAROUND_VIEWS[view]:
            failures.append(
                Failure("render_yaw", f"{render_id}/{view}", f"reported {entry.get('yaw_degrees')!r}")
            )
        expected_relative = str(expected_path.relative_to(ROOT))
        if entry.get("path") != expected_relative:
            failures.append(
                Failure("render_path", f"{render_id}/{view}", f"reported {entry.get('path')!r}")
            )
        if expected_path.is_symlink() or not expected_path.is_file():
            failures.append(
                Failure("render_missing", f"{render_id}/{view}", "PNG is missing or is a symlink")
            )
            continue
        if entry.get("sha256") != sha256_file(expected_path):
            failures.append(
                Failure("render_hash", f"{render_id}/{view}", "PNG hash does not match report")
            )
        with Image.open(expected_path) as image:
            if list(image.size) != payload.get("resolution"):
                failures.append(
                    Failure(
                        "render_dimensions",
                        f"{render_id}/{view}",
                        f"on-disk {list(image.size)} != report {payload.get('resolution')!r}",
                    )
                )

    contact = payload.get("contact_sheet")
    contact_path = directory / "contact_sheet.png"
    if not isinstance(contact, dict):
        failures.append(Failure("contact_sheet", subject, "contact-sheet record is missing"))
    else:
        if contact.get("path") != str(contact_path.relative_to(ROOT)):
            failures.append(
                Failure("contact_sheet_path", subject, f"reported {contact.get('path')!r}")
            )
        if contact_path.is_symlink() or not contact_path.is_file():
            failures.append(Failure("contact_sheet_missing", subject, "contact sheet is missing"))
        elif contact.get("sha256") != sha256_file(contact_path):
            failures.append(Failure("contact_sheet_hash", subject, "contact sheet hash does not match"))

    if require_current:
        receipt_failures, build_receipt = check_build_receipt()
        failures.extend(receipt_failures)
        recorded_source = build_receipt.get("source_blend")
        expected_source = recorded_source if isinstance(recorded_source, str) else ""
        source_path = (ROOT / expected_source).resolve()
        root = ROOT.resolve()
        if (
            not expected_source
            or source_path == root
            or root not in source_path.parents
        ):
            failures.append(
                Failure("render_source", subject, "build receipt has an unsafe source path")
            )
            source_path = ROOT / "__invalid_collectible_source__"
        if payload.get("source_blend") != expected_source:
            failures.append(
                Failure("render_source", subject, f"reported {payload.get('source_blend')!r}")
            )
        if (
            not source_path.is_file()
            or payload.get("source_blend_sha256") != sha256_file(source_path)
        ):
            failures.append(
                Failure("render_source_hash", subject, "candidate render is not from the current .blend")
            )
        receipt_entry = payload.get("build_receipt")
        if not isinstance(receipt_entry, dict):
            failures.append(
                Failure("render_build_receipt", subject, "candidate omits its build receipt")
            )
        elif (
            not BUILD_REPORT.is_file()
            or receipt_entry.get("sha256") != sha256_file(BUILD_REPORT)
            or receipt_entry.get("status") != "PASS"
        ):
            failures.append(
                Failure("render_build_receipt", subject, "candidate receipt hash is not current")
            )
    else:
        failures.extend(validate_historical_source(payload, subject))
    return failures, payload


def _run() -> int:
    baseline_dir = VALIDATION_RENDERS / BASELINE_ID
    candidate_dir = VALIDATION_RENDERS / CANDIDATE_ID
    candidate_dir.mkdir(parents=True, exist_ok=True)
    output = candidate_dir / "before_candidate_difference.png"
    comparison_report = candidate_dir / "comparison_report.json"
    output.unlink(missing_ok=True)
    write_json(
        comparison_report,
        {
            "baseline_id": BASELINE_ID,
            "candidate_id": CANDIDATE_ID,
            "output": None,
            "failures": [
                Failure(
                    "comparison_incomplete",
                    str(comparison_report),
                    "comparison started but has not completed",
                ).as_dict()
            ],
        },
    )

    baseline_failures, baseline_report = validate_render_packet(BASELINE_ID, require_current=False)
    candidate_failures, candidate_report = validate_render_packet(CANDIDATE_ID, require_current=True)
    failures = [*baseline_failures, *candidate_failures]
    if BASELINE_ID == CANDIDATE_ID:
        failures.append(
            Failure("comparison_identity", BASELINE_ID, "baseline and candidate IDs must differ")
        )
    baseline_environment = baseline_report.get("environment")
    candidate_environment = candidate_report.get("environment")
    baseline_engine = (
        baseline_environment.get("render_engine")
        if isinstance(baseline_environment, dict)
        else None
    )
    candidate_engine = (
        candidate_environment.get("render_engine")
        if isinstance(candidate_environment, dict)
        else None
    )
    if (
        baseline_report.get("resolution") != candidate_report.get("resolution")
        or baseline_report.get("ortho_scale_mm") != candidate_report.get("ortho_scale_mm")
        or baseline_report.get("protocol") != candidate_report.get("protocol")
        or baseline_engine != candidate_engine
    ):
        failures.append(
            Failure(
                "comparison_contract",
                f"{BASELINE_ID}<->{CANDIDATE_ID}",
                "resolution, camera/lighting protocol, or render engine differs",
            )
        )
    if failures:
        write_json(
            comparison_report,
            {
                "baseline_id": BASELINE_ID,
                "candidate_id": CANDIDATE_ID,
                "output": None,
                "failures": [failure.as_dict() for failure in failures],
            },
        )
        return report("COBIE_FIGURINE_COMPARE", failures)

    width = PANEL_SIZE * 3
    height = HEADER_HEIGHT + PANEL_SIZE * len(VIEWS) + FOOTER_HEIGHT
    canvas = Image.new("RGB", (width, height), (15, 18, 22))
    draw = ImageDraw.Draw(canvas)
    label(draw, 18, 16, f"BEFORE -- {BASELINE_ID}", (220, 224, 228))
    label(draw, PANEL_SIZE + 18, 16, f"CANDIDATE -- {CANDIDATE_ID}", (220, 224, 228))
    label(draw, PANEL_SIZE * 2 + 18, 16, "AMPLIFIED PIXEL DIFFERENCE", (220, 224, 228))

    for row, view in enumerate(VIEWS):
        with Image.open(baseline_dir / f"{view}.png") as handle:
            baseline = handle.convert("RGB")
        with Image.open(candidate_dir / f"{view}.png") as handle:
            candidate = handle.convert("RGB")
        difference = ImageChops.difference(baseline, candidate)
        difference = ImageOps.autocontrast(difference, cutoff=1)
        difference = ImageEnhance.Contrast(difference).enhance(1.5)
        y = HEADER_HEIGHT + row * PANEL_SIZE
        canvas.paste(baseline, (0, y))
        canvas.paste(candidate, (PANEL_SIZE, y))
        canvas.paste(difference, (PANEL_SIZE * 2, y))
        label(draw, 16, y + 16, view.upper(), (255, 255, 255))

    footer_y = HEADER_HEIGHT + PANEL_SIZE * len(VIEWS) + 16
    label(
        draw,
        18,
        footer_y,
        "PROVISIONAL DIGITAL PROTOTYPE -- identity approval + photo pack remain OPEN; no physical print claim",
        (186, 194, 202),
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output)
    write_json(
        comparison_report,
        {
            "baseline_id": BASELINE_ID,
            "baseline_render_report_sha256": sha256_file(baseline_dir / "render_report.json"),
            "candidate_id": CANDIDATE_ID,
            "candidate_render_report_sha256": sha256_file(candidate_dir / "render_report.json"),
            "output": {
                "path": str(output.relative_to(ROOT)),
                "sha256": sha256_file(output),
            },
            "failures": [],
        },
    )
    print(f"  comparison: {output}")
    print("COBIE_FIGURINE_COMPARE: PASS")
    return 0


def main() -> int:
    candidate_dir = VALIDATION_RENDERS / CANDIDATE_ID
    candidate_dir.mkdir(parents=True, exist_ok=True)
    output = candidate_dir / "before_candidate_difference.png"
    comparison_report = candidate_dir / "comparison_report.json"
    try:
        return _run()
    except Exception as exc:
        output.unlink(missing_ok=True)
        failure = Failure(
            "comparison_exception",
            str(comparison_report),
            f"{type(exc).__name__}: {exc}",
        )
        write_json(
            comparison_report,
            {
                "baseline_id": BASELINE_ID,
                "candidate_id": CANDIDATE_ID,
                "output": None,
                "failures": [failure.as_dict()],
            },
        )
        return report("COBIE_FIGURINE_COMPARE", [failure])


if __name__ == "__main__":
    raise SystemExit(main())
