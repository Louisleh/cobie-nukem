#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Capture visual quality candidates from declared manifest adapters."
    )
    parser.add_argument("--manifest", required=True, help="Path to capture manifest JSON.")
    parser.add_argument(
        "--baseline",
        default=None,
        help="Baseline output directory (defaults to manifest policy value).",
    )
    parser.add_argument(
        "--candidate",
        default=None,
        help="Candidate output directory (defaults to manifest policy value).",
    )
    parser.add_argument(
        "--view",
        action="append",
        default=[],
        help="Capture only the named view(s). Repeat to capture multiple.",
    )
    parser.add_argument(
        "--approve",
        action="store_true",
        help="Copy captured files into baseline directory (overwrite enabled).",
    )
    parser.add_argument(
        "--run-id",
        default=None,
        help="Custom candidate run id used as the leaf folder under candidate root.",
    )
    return parser.parse_args()


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _load_json(path: Path) -> Dict[str, Any]:
    raw = path.read_text(encoding="utf-8")
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError(f"manifest did not parse as object: {path}")
    return data


def _aspect_map(manifest: Dict[str, Any]) -> List[Dict[str, int]]:
    aspects = manifest.get("aspects")
    if not isinstance(aspects, list):
        raise ValueError("manifest missing aspects")
    for aspect in aspects:
        if not isinstance(aspect, dict):
            raise ValueError(f"invalid aspect entry: {aspect}")
        if not aspect.get("id") or int(aspect.get("width", 0)) <= 0 or int(aspect.get("height", 0)) <= 0:
            raise ValueError(f"invalid aspect entry: {aspect}")
    return [
        {
            "id": str(aspect["id"]),
            "width": int(aspect["width"]),
            "height": int(aspect["height"]),
        }
        for aspect in aspects
    ]


def _select_views(manifest: Dict[str, Any], requested: List[str]) -> List[Dict[str, Any]]:
    views = manifest.get("views")
    if not isinstance(views, list):
        raise ValueError("manifest missing views")
    view_by_id = {str(view.get("id", "")): view for view in views if isinstance(view, dict)}
    if not requested:
        return [view for view in views if isinstance(view, dict)]
    selected: List[Dict[str, Any]] = []
    for requested_id in requested:
        view = view_by_id.get(str(requested_id))
        if view is None:
            raise ValueError(f"requested view not found in manifest: {requested_id}")
        selected.append(view)
    return selected


def _native_capture_output(
    output_root: Path,
    run_id: str,
    width: int,
    height: int,
) -> Path:
    capture_script = _repo_root() / "tools" / "capture_native_evidence.sh"
    temp_output = output_root / run_id
    temp_output.mkdir(parents=True, exist_ok=True)
    subprocess.check_call(
        ["/bin/bash", str(capture_script), str(temp_output)],
        env={
            **os.environ,
            "GODOT_BIN": os.environ.get("GODOT_BIN", "/opt/homebrew/bin/godot"),
            "CAPTURE_WIDTH": str(width),
            "CAPTURE_HEIGHT": str(height),
        },
    )
    return temp_output


def _copy_capture(
    source_file: Path,
    target_path: Path,
    expected_width: int,
    expected_height: int,
) -> None:
    with Image.open(source_file) as source:
        if source.size != (expected_width, expected_height):
            raise ValueError(
                f"capture dimensions {source.size} do not match requested "
                f"{expected_width}x{expected_height}: {source_file}"
            )
    target_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_file, target_path)


def run_capture(
    manifest_path: Path,
    baseline_root: Optional[Path],
    candidate_root: Optional[Path],
    selected_views: List[str],
    approve: bool,
    run_id: Optional[str],
) -> int:
    manifest = _load_json(manifest_path)
    policy = manifest.get("capture_policy", {})
    if not isinstance(policy, dict):
        policy = {}

    candidate_root = (
        Path(candidate_root)
        if candidate_root is not None
        else Path(policy.get("default_candidate_root", "builds/visual-quality/candidates"))
    )
    baseline_root = (
        Path(baseline_root)
        if baseline_root is not None
        else Path(policy.get("default_baseline_root", "builds/visual-quality/baselines"))
    )

    supported_states = manifest.get("support_states", ["supported", "unsupported"])
    if not isinstance(supported_states, list) or "supported" not in supported_states:
        raise ValueError("manifest support_states missing required supported state")

    views = _select_views(manifest, selected_views)
    run_id = run_id or datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    candidate_run = candidate_root / run_id
    candidate_run.mkdir(parents=True, exist_ok=True)
    baseline_root.mkdir(parents=True, exist_ok=True)

    aspects = _aspect_map(manifest)
    captured: Dict[str, List[str]] = {}
    unsupported_requested: List[str] = []
    capture_failures: List[str] = []

    supported_views = [view for view in views if view.get("capture_support") == "supported"]
    if supported_views:
        with tempfile.TemporaryDirectory(prefix="visual_quality_native_") as temp_root:
            for aspect in aspects:
                aspect_id = str(aspect["id"])
                native_output = _native_capture_output(
                    Path(temp_root),
                    f"{run_id}-{aspect_id}",
                    int(aspect["width"]),
                    int(aspect["height"]),
                )
                for view in supported_views:
                    view_id = str(view.get("id"))
                    adapter = str(view.get("adapter", ""))
                    capture = view.get("capture")
                    if adapter != "native_vertical_slice_capture":
                        capture_failures.append(f"{view_id}: unsupported adapter for capture tool: {adapter}")
                        continue
                    if not isinstance(capture, dict):
                        capture_failures.append(f"{view_id}: missing capture config")
                        continue
                    source_file_name = capture.get("source_file")
                    filenames = view.get("filenames", {})
                    if not source_file_name or not isinstance(filenames, dict):
                        capture_failures.append(f"{view_id}: incomplete capture or filename config")
                        continue
                    filename = filenames.get(aspect_id)
                    source_path = native_output / str(source_file_name)
                    if not filename or not source_path.is_file():
                        capture_failures.append(f"{view_id}:{aspect_id}: missing declared source or target")
                        continue
                    target_path = candidate_run / str(filename)
                    _copy_capture(
                        source_path,
                        target_path,
                        int(aspect["width"]),
                        int(aspect["height"]),
                    )
                    captured.setdefault(view_id, []).append(str(target_path))

    for view in views:
        view_id = str(view.get("id", ""))
        if view.get("capture_support", "") != "unsupported":
            continue
        unsupported_requested.append(view_id)

    if approve:
        for paths in captured.values():
            for path in paths:
                path_obj = Path(path)
                rel = path_obj.name
                baseline_target = baseline_root / rel
                baseline_target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(path_obj, baseline_target)

    report_path = candidate_run / "capture_report.json"
    report_path.write_text(
        json.dumps(
            {
                "manifest": str(manifest_path),
                "run_id": run_id,
                "candidate_root": str(candidate_run),
                "baseline_root": str(baseline_root),
                "captured": captured,
                "unsupported_requested": unsupported_requested,
                "failures": capture_failures,
                "approved": approve,
                "policy_requires_approve": not bool(policy.get("overwrite_baseline_without_approve", True)),
            },
            indent=2,
            sort_keys=True,
        ),
        encoding="utf-8",
    )
    if capture_failures:
        print("Capture completed with failures:")
        for failure in capture_failures:
            print(f"- {failure}")
        return 1
    print("Visual capture complete.")
    print(f"  Candidate directory: {candidate_run}")
    if unsupported_requested:
        print("  Unsupported views requested:")
        for view in unsupported_requested:
            print(f"  - {view}")
    if approve:
        print(f"  Baseline directory updated at {baseline_root}")
    else:
        print("  Baseline is not modified without --approve.")
    return 0


def main() -> int:
    args = parse_args()
    return run_capture(
        manifest_path=Path(args.manifest),
        baseline_root=Path(args.baseline) if args.baseline else None,
        candidate_root=Path(args.candidate) if args.candidate else None,
        selected_views=args.view,
        approve=args.approve,
        run_id=args.run_id,
    )


if __name__ == "__main__":
    raise SystemExit(main())
