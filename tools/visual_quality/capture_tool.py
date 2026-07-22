#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional


_ALLOWED_CAPTURE_DIAGNOSTICS = {
    "ERROR: 1 shaders of type ParticlesShaderGLES3 were never freed": 1,
    "ERROR: 1 RID allocations of type 'N5GLES36ShaderE' were leaked at exit.": 1,
}
_FATAL_CAPTURE_DIAGNOSTICS = (
    re.compile(r"^ERROR:"),
    re.compile(r"^SCRIPT ERROR:"),
    re.compile(r"ObjectDB instances? (?:(?:was|were) )?leaked at exit"),
    re.compile(r"resources? still in use at exit"),
    re.compile(r"\borphan\b", re.IGNORECASE),
)

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
    parser.add_argument("--aspect", action="append", default=[], help="Capture only the named aspect ID(s).")
    parser.add_argument("--render-fps", type=int, default=None, help="Deterministic MovieWriter render FPS.")
    parser.add_argument("--physics-tps", type=int, default=None, help="Physics tick rate for interpolation diagnostics.")
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


def _aspect_map(manifest: Dict[str, Any], requested: List[str]) -> List[Dict[str, int]]:
    aspects = manifest.get("aspects")
    if not isinstance(aspects, list):
        raise ValueError("manifest missing aspects")
    for aspect in aspects:
        if not isinstance(aspect, dict):
            raise ValueError(f"invalid aspect entry: {aspect}")
        if not aspect.get("id") or int(aspect.get("width", 0)) <= 0 or int(aspect.get("height", 0)) <= 0:
            raise ValueError(f"invalid aspect entry: {aspect}")
    result = [
        {
            "id": str(aspect["id"]),
            "width": int(aspect["width"]),
            "height": int(aspect["height"]),
        }
        for aspect in aspects
    ]
    if requested:
        available = {aspect["id"] for aspect in result}
        missing = sorted(set(requested) - available)
        if missing:
            raise ValueError(f"requested aspect not found in manifest: {', '.join(missing)}")
        result = [aspect for aspect in result if aspect["id"] in requested]
    return result


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
    render_fps: int,
    physics_tps: int,
    force_touch: bool = False,
    capture_seed: int = 2026071601,
) -> Path:
    capture_script = _repo_root() / "tools" / "capture_native_evidence.sh"
    temp_output = output_root / run_id
    temp_output.mkdir(parents=True, exist_ok=True)
    env = _isolated_capture_env(temp_output / "user-data")
    env.update(
        {
            "GODOT_BIN": os.environ.get("GODOT_BIN", "/opt/homebrew/bin/godot"),
            "CAPTURE_WIDTH": str(width),
            "CAPTURE_HEIGHT": str(height),
            "CAPTURE_FPS": str(render_fps),
            "CAPTURE_PHYSICS_TPS": str(physics_tps),
            "CAPTURE_FORCE_TOUCH": "1" if force_touch else "0",
            "CAPTURE_SEED": str(capture_seed),
        }
    )
    _run_capture_process(["/bin/bash", str(capture_script), str(temp_output)], env)
    return temp_output


def _isolated_capture_env(root: Path) -> Dict[str, str]:
    home = root / "home"
    env = {
        **os.environ,
        "HOME": str(home),
        "CFFIXED_USER_HOME": str(home),
        "XDG_DATA_HOME": str(root / "xdg-data"),
        "XDG_CONFIG_HOME": str(root / "xdg-config"),
        "XDG_CACHE_HOME": str(root / "xdg-cache"),
    }
    for key in ("HOME", "XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    return env


def _run_capture_process(command: List[str], env: Dict[str, str]) -> None:
    result = subprocess.run(
        command,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.returncode != 0:
        raise subprocess.CalledProcessError(result.returncode, command, output=result.stdout)
    allowed_counts = {line: 0 for line in _ALLOWED_CAPTURE_DIAGNOSTICS}
    unexpected_errors = []
    for raw_line in result.stdout.splitlines():
        line = raw_line.strip()
        if line in allowed_counts:
            allowed_counts[line] += 1
            if allowed_counts[line] > _ALLOWED_CAPTURE_DIAGNOSTICS[line]:
                unexpected_errors.append(line)
        elif any(pattern.search(line) for pattern in _FATAL_CAPTURE_DIAGNOSTICS):
            unexpected_errors.append(line)
    if unexpected_errors:
        raise RuntimeError("visual capture emitted engine errors:\n" + "\n".join(unexpected_errors))


def _direct_scene_capture(
    output_root: Path,
    view: Dict[str, Any],
    aspect: Dict[str, Any],
    render_fps: int,
    physics_tps: int,
) -> Path:
    frame = int(view.get("frame", 0))
    capture = view.get("capture", {})
    quit_after = int(capture.get("quit_after", frame + 10)) if isinstance(capture, dict) else frame + 10
    scene_path = str(view.get("scene_path", ""))
    if not scene_path.startswith("res://") or frame <= 0 or quit_after <= frame:
        raise ValueError(f"invalid direct scene capture contract: {view.get('id', '')}")
    prefix = output_root / f"{view.get('id', 'view')}-{aspect['id']}" / "capture.png"
    prefix.parent.mkdir(parents=True, exist_ok=True)
    capture_project = output_root / f"project-{aspect['id']}"
    if not (capture_project / "project.godot").is_file():
        subprocess.check_call(
            [
                sys.executable,
                str(_repo_root() / "tools" / "visual_quality" / "prepare_capture_project.py"),
                str(_repo_root()),
                str(capture_project),
                str(aspect["width"]),
                str(aspect["height"]),
            ]
        )
    command = [
        os.environ.get("GODOT_BIN", "/opt/homebrew/bin/godot"),
        "--path", str(capture_project),
        "--resolution", f"{aspect['width']}x{aspect['height']}",
        "--write-movie", str(prefix),
        "--fixed-fps", str(render_fps),
        "res://scenes/debug/visual_direct_capture.tscn",
        "--",
        f"--target-scene={scene_path}",
        f"--cleanup-frame={quit_after}",
        f"--staging-id={view.get('staging_id', '')}",
        f"--capture-size={aspect['width']}x{aspect['height']}",
        f"--capture-seed={int(view.get('seed', 1))}",
        f"--physics-tps={physics_tps}",
    ]
    _run_capture_process(command, _isolated_capture_env(prefix.parent / "user-data"))
    frame_path = prefix.parent / f"capture{frame:08d}.png"
    if not frame_path.is_file():
        raise FileNotFoundError(f"direct scene frame missing: {frame_path}")
    return frame_path


def _copy_capture(
    source_file: Path,
    target_path: Path,
    expected_width: int,
    expected_height: int,
) -> None:
    from PIL import Image

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
    selected_aspects: List[str],
    approve: bool,
    run_id: Optional[str],
    render_fps: Optional[int],
    physics_tps: Optional[int],
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

    aspects = _aspect_map(manifest, selected_aspects)
    render_fps = int(render_fps or policy.get("default_render_fps", 30))
    physics_tps = int(physics_tps or policy.get("default_physics_tps", 60))
    if render_fps not in [30, 60, 120] or not 10 <= physics_tps <= 240:
        raise ValueError("render FPS must be 30/60/120 and physics TPS must be 10..240")
    captured: Dict[str, List[str]] = {}
    unsupported_requested: List[str] = []
    capture_failures: List[str] = []

    supported_views = [view for view in views if view.get("capture_support") == "supported"]
    if supported_views:
        with tempfile.TemporaryDirectory(prefix="visual_quality_native_") as temp_root:
            for aspect in aspects:
                aspect_id = str(aspect["id"])
                native_output: Optional[Path] = None
                touch_output: Optional[Path] = None
                native_error: Optional[str] = None
                touch_error: Optional[str] = None
                for view in supported_views:
                    view_id = str(view.get("id"))
                    adapter = str(view.get("adapter", ""))
                    capture = view.get("capture")
                    try:
                        if not isinstance(capture, dict):
                            raise ValueError("missing capture config")
                        if adapter == "native_vertical_slice_capture":
                            if native_error is not None:
                                raise RuntimeError(f"native adapter unavailable: {native_error}")
                            if native_output is None:
                                try:
                                    native_output = _native_capture_output(Path(temp_root), f"{run_id}-{aspect_id}", int(aspect["width"]), int(aspect["height"]), render_fps, physics_tps, False, int(view.get("seed", 1)))
                                except Exception as error:
                                    native_error = str(error)
                                    raise
                            source_path = native_output / str(capture.get("source_file", ""))
                        elif adapter == "native_vertical_slice_touch_capture":
                            if touch_error is not None:
                                raise RuntimeError(f"touch adapter unavailable: {touch_error}")
                            if touch_output is None:
                                try:
                                    touch_output = _native_capture_output(Path(temp_root), f"{run_id}-{aspect_id}-touch", int(aspect["width"]), int(aspect["height"]), render_fps, physics_tps, True, int(view.get("seed", 1)))
                                except Exception as error:
                                    touch_error = str(error)
                                    raise
                            source_path = touch_output / str(capture.get("source_file", ""))
                        elif adapter == "direct_scene_capture":
                            source_path = _direct_scene_capture(Path(temp_root), view, aspect, render_fps, physics_tps)
                        else:
                            raise ValueError(f"unsupported adapter for capture tool: {adapter}")
                        filenames = view.get("filenames", {})
                        if not isinstance(filenames, dict):
                            raise ValueError("incomplete filename config")
                        filename = filenames.get(aspect_id)
                        if not filename or not source_path.is_file():
                            raise FileNotFoundError("missing declared source or target")
                        target_path = candidate_run / str(filename)
                        _copy_capture(
                            source_path,
                            target_path,
                            int(aspect["width"]),
                            int(aspect["height"]),
                        )
                        captured.setdefault(view_id, []).append(str(target_path))
                    except Exception as error:
                        capture_failures.append(
                            f"{view_id}:{aspect_id}: {type(error).__name__}: {error}"
                        )

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
                "render_fps": render_fps,
                "physics_tps": physics_tps,
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
        selected_aspects=args.aspect,
        approve=args.approve,
        run_id=args.run_id,
        render_fps=args.render_fps,
        physics_tps=args.physics_tps,
    )


if __name__ == "__main__":
    raise SystemExit(main())
