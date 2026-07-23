#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime
import hashlib
from itertools import combinations
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


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
_DIRECT_CAPTURE_BOOTSTRAP_RESOLUTION = "1280x720"

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


def _run_capture_process(command: List[str], env: Dict[str, str]) -> str:
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
    return result.stdout


def _finite_vector3(value: Any, label: str) -> Tuple[float, float, float]:
    if not isinstance(value, list) or len(value) != 3:
        raise RuntimeError(f"{label} must be a three-number array")
    vector: List[float] = []
    for component in value:
        if isinstance(component, bool) or not isinstance(component, (int, float)):
            raise RuntimeError(f"{label} must contain only finite numbers")
        number = float(component)
        if not math.isfinite(number):
            raise RuntimeError(f"{label} must contain only finite numbers")
        vector.append(number)
    return vector[0], vector[1], vector[2]


def _positive_size2(value: Any, label: str) -> Tuple[int, int]:
    if (
        not isinstance(value, list)
        or len(value) != 2
        or any(isinstance(component, bool) or not isinstance(component, int) for component in value)
        or any(component <= 0 for component in value)
    ):
        raise RuntimeError(f"{label} must be a two-positive-integer array")
    return int(value[0]), int(value[1])


def _camera_pose_receipt(
    output: str,
    view: Dict[str, Any],
    receipt_image_path: Optional[Path] = None,
    expected_image_size: Optional[Tuple[int, int]] = None,
) -> Optional[Dict[str, Any]]:
    requires_receipt = bool(view.get("require_camera_pose_receipt", False))
    prefix = "CAPTURE_CAMERA_POSE "
    receipt_lines = [line[len(prefix):] for line in output.splitlines() if line.startswith(prefix)]
    if not requires_receipt:
        return None
    if len(receipt_lines) != 1:
        raise RuntimeError(
            f"direct capture requires exactly one camera pose receipt for {view.get('id', '')}; "
            f"found {len(receipt_lines)}"
        )
    try:
        receipt = json.loads(receipt_lines[0])
    except json.JSONDecodeError as error:
        raise RuntimeError(f"invalid camera pose receipt for {view.get('id', '')}: {error}") from error
    if not isinstance(receipt, dict):
        raise RuntimeError(f"camera pose receipt is not an object for {view.get('id', '')}")
    expected_receipt_keys = {
        "staging_id",
        "capture_frame",
        "script_frame",
        "capture_seed",
        "capture_window_size",
        "receipt_image_size",
        "capture_window_borderless",
        "player_origin",
        "camera_origin",
        "camera_forward",
        "camera_fov",
        "position_error",
        "camera_position_error",
        "direction_dot",
        "active_camera_under_player",
        "receipt_image_sha256",
    }
    if set(receipt) != expected_receipt_keys:
        raise RuntimeError(
            f"camera pose receipt fields drifted for {view.get('id', '')}: "
            f"found={sorted(receipt)}, expected={sorted(expected_receipt_keys)}"
        )
    view_id = str(view.get("id", ""))
    staging_id = str(view.get("staging_id", ""))
    if str(receipt.get("staging_id", "")) != staging_id:
        raise RuntimeError(
            f"camera pose receipt staging mismatch for {view_id}: "
            f"expected {staging_id}, found {receipt.get('staging_id', '')}"
        )
    expected_frame = int(view.get("frame", -1))
    expected_seed = int(view.get("seed", -1))
    capture_frame = receipt.get("capture_frame")
    script_frame = receipt.get("script_frame")
    capture_seed = receipt.get("capture_seed")
    if (
        isinstance(capture_frame, bool)
        or not isinstance(capture_frame, int)
        or capture_frame != expected_frame
        or isinstance(script_frame, bool)
        or not isinstance(script_frame, int)
        or script_frame != expected_frame
        or isinstance(capture_seed, bool)
        or not isinstance(capture_seed, int)
        or capture_seed != expected_seed
    ):
        raise RuntimeError(
            f"camera pose receipt frame/seed mismatch for {view_id}: "
            f"capture_frame={capture_frame}, script_frame={script_frame}, capture_seed={capture_seed}"
        )
    expected_pose = view.get("expected_camera_pose")
    if not isinstance(expected_pose, dict):
        raise RuntimeError(f"camera pose contract missing for {view_id}")
    expected_player = _finite_vector3(expected_pose.get("player_origin"), f"{view_id} expected player origin")
    expected_camera = _finite_vector3(expected_pose.get("camera_origin"), f"{view_id} expected camera origin")
    look_target = _finite_vector3(expected_pose.get("look_target"), f"{view_id} expected look target")
    expected_fov = expected_pose.get("camera_fov")
    if isinstance(expected_fov, bool) or not isinstance(expected_fov, (int, float)) or not math.isfinite(float(expected_fov)):
        raise RuntimeError(f"{view_id} expected camera FOV must be finite")
    player_origin = _finite_vector3(receipt.get("player_origin"), f"{view_id} player origin")
    camera_origin = _finite_vector3(receipt.get("camera_origin"), f"{view_id} camera origin")
    camera_forward = _finite_vector3(receipt.get("camera_forward"), f"{view_id} camera forward")
    camera_fov = receipt.get("camera_fov")
    if isinstance(camera_fov, bool) or not isinstance(camera_fov, (int, float)) or not math.isfinite(float(camera_fov)):
        raise RuntimeError(f"{view_id} camera FOV must be finite")
    position_error = math.dist(player_origin, expected_player)
    camera_position_error = math.dist(camera_origin, expected_camera)
    expected_forward = tuple(look_target[index] - camera_origin[index] for index in range(3))
    expected_length = math.sqrt(sum(component * component for component in expected_forward))
    actual_length = math.sqrt(sum(component * component for component in camera_forward))
    if expected_length <= 1.0e-6 or actual_length <= 1.0e-6:
        raise RuntimeError(f"camera pose receipt has a degenerate direction for {view_id}")
    direction_dot = sum(
        (camera_forward[index] / actual_length) * (expected_forward[index] / expected_length)
        for index in range(3)
    )
    active_camera = receipt.get("active_camera_under_player") is True
    if (
        position_error > 0.01
        or camera_position_error > 0.01
        or direction_dot < 0.999
        or abs(float(camera_fov) - float(expected_fov)) > 0.001
        or not active_camera
    ):
        raise RuntimeError(
            f"camera pose receipt failed independent validation for {view_id}: "
            f"position_error={position_error:.6f}, camera_position_error={camera_position_error:.6f}, "
            f"direction_dot={direction_dot:.6f}, camera_fov={float(camera_fov):.3f}, "
            f"active_camera_under_player={active_camera}"
        )
    if receipt_image_path is None or not receipt_image_path.is_file():
        raise RuntimeError(f"camera pose receipt image is missing for {view_id}")
    if expected_image_size is None:
        raise RuntimeError(f"camera pose receipt expected image size is missing for {view_id}")
    capture_window_size = _positive_size2(
        receipt.get("capture_window_size"), f"{view_id} capture window size"
    )
    receipt_image_size = _positive_size2(
        receipt.get("receipt_image_size"), f"{view_id} receipt image size"
    )
    if receipt.get("capture_window_borderless") is not True:
        raise RuntimeError(f"camera pose receipt window was not borderless for {view_id}")
    from PIL import Image

    with Image.open(receipt_image_path) as receipt_image:
        actual_image_size = receipt_image.size
    if (
        capture_window_size != expected_image_size
        or receipt_image_size != expected_image_size
        or actual_image_size != expected_image_size
    ):
        raise RuntimeError(
            f"camera pose receipt dimensions mismatch for {view_id}: "
            f"expected={expected_image_size}, window={capture_window_size}, "
            f"receipt={receipt_image_size}, actual={actual_image_size}"
        )
    receipt_image_sha256 = str(receipt.get("receipt_image_sha256", ""))
    actual_image_sha256 = hashlib.sha256(receipt_image_path.read_bytes()).hexdigest()
    if receipt_image_sha256 != actual_image_sha256:
        raise RuntimeError(
            f"camera pose receipt image hash mismatch for {view_id}: "
            f"receipt={receipt_image_sha256}, actual={actual_image_sha256}"
        )
    receipt["validated_position_error"] = position_error
    receipt["validated_camera_position_error"] = camera_position_error
    receipt["validated_direction_dot"] = direction_dot
    return receipt


def _direct_scene_capture(
    output_root: Path,
    view: Dict[str, Any],
    aspect: Dict[str, Any],
    render_fps: int,
    physics_tps: int,
) -> Tuple[Path, Optional[Dict[str, Any]]]:
    frame = int(view.get("frame", 0))
    capture = view.get("capture", {})
    quit_after = int(capture.get("quit_after", frame + 10)) if isinstance(capture, dict) else frame + 10
    scene_path = str(view.get("scene_path", ""))
    if not scene_path.startswith("res://") or frame <= 0 or quit_after <= frame:
        raise ValueError(f"invalid direct scene capture contract: {view.get('id', '')}")
    prefix = output_root / f"{view.get('id', 'view')}-{aspect['id']}" / "capture.png"
    prefix.parent.mkdir(parents=True, exist_ok=True)
    receipt_image_path = prefix.parent / "receipt.png"
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
        # Boot at a desktop-safe size. On macOS an oversized decorated startup
        # window becomes maximized and remains clamped even after going
        # borderless; the capture host switches to borderless before applying
        # the exact target dimensions and instantiating the production scene.
        "--resolution", _DIRECT_CAPTURE_BOOTSTRAP_RESOLUTION,
        "--write-movie", str(prefix),
        "--fixed-fps", str(render_fps),
        "res://scenes/debug/visual_direct_capture.tscn",
        "--",
        f"--target-scene={scene_path}",
        f"--cleanup-frame={quit_after}",
        f"--staging-id={view.get('staging_id', '')}",
        f"--capture-size={aspect['width']}x{aspect['height']}",
        f"--capture-frame={frame}",
        f"--receipt-image={receipt_image_path}",
        f"--capture-seed={int(view.get('seed', 1))}",
        f"--physics-tps={physics_tps}",
    ]
    output = _run_capture_process(command, _isolated_capture_env(prefix.parent / "user-data")) or ""
    receipt = _camera_pose_receipt(
        output,
        view,
        receipt_image_path,
        (int(aspect["width"]), int(aspect["height"])),
    )
    frame_path = prefix.parent / f"capture{frame:08d}.png"
    if not frame_path.is_file():
        raise FileNotFoundError(f"direct scene frame missing: {frame_path}")
    if bool(view.get("require_camera_pose_receipt", False)):
        return receipt_image_path, receipt
    return frame_path, receipt


def _copy_capture(
    source_file: Path,
    target_path: Path,
    expected_width: int,
    expected_height: int,
) -> Path:
    from PIL import Image

    with Image.open(source_file) as source:
        if source.size != (expected_width, expected_height):
            raise ValueError(
                f"capture dimensions {source.size} do not match requested "
                f"{expected_width}x{expected_height}: {source_file}"
            )
    target_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_file, target_path)
    return target_path


def _scene_edge_metrics(first_path: Path, second_path: Path) -> Dict[str, float]:
    from PIL import Image, ImageFilter

    with Image.open(first_path) as first_source, Image.open(second_path) as second_source:
        first = first_source.convert("L")
        second = second_source.convert("L")
    if first.size != second.size:
        raise ValueError(f"distinctness inputs have mismatched dimensions: {first.size} != {second.size}")
    width, height = first.size
    scene_roi = (0, int(height * 0.14), width, int(height * 0.70))
    first_scene = first.crop(scene_roi)
    second_scene = second.crop(scene_roi)

    def edge_threshold(value: int) -> int:
        return 255 if value >= 20 else 0

    def edge_mask(image: Any) -> bytes:
        edges = image.filter(ImageFilter.FIND_EDGES)
        if edges.width > 4 and edges.height > 4:
            edges = edges.crop((1, 1, edges.width - 1, edges.height - 1))
        return edges.point(edge_threshold).filter(ImageFilter.MaxFilter(5)).tobytes()

    first_mask = edge_mask(first_scene)
    second_mask = edge_mask(second_scene)
    first_edges = sum(edge > 0 for edge in first_mask)
    second_edges = sum(edge > 0 for edge in second_mask)
    intersection = sum(first_edge > 0 and second_edge > 0 for first_edge, second_edge in zip(first_mask, second_mask))
    union = sum(first_edge > 0 or second_edge > 0 for first_edge, second_edge in zip(first_mask, second_mask))
    pixel_count = max(1, len(first_mask))
    first_low_frequency = first_scene.filter(ImageFilter.GaussianBlur(4.0)).resize((64, 32)).tobytes()
    second_low_frequency = second_scene.filter(ImageFilter.GaussianBlur(4.0)).resize((64, 32)).tobytes()
    low_frequency_mae = sum(
        abs(first_value - second_value)
        for first_value, second_value in zip(first_low_frequency, second_low_frequency)
    ) / float(255 * max(1, len(first_low_frequency)))
    return {
        "scene_edge_iou": float(intersection) / float(union) if union else 1.0,
        "first_edge_fraction": float(first_edges) / float(pixel_count),
        "second_edge_fraction": float(second_edges) / float(pixel_count),
        "low_frequency_mae": low_frequency_mae,
    }


def _scene_edge_iou(first_path: Path, second_path: Path) -> float:
    return _scene_edge_metrics(first_path, second_path)["scene_edge_iou"]


def _capture_distinctness_metrics(
    views: List[Dict[str, Any]],
    aspects: List[Dict[str, int]],
    candidate_run: Path,
) -> Tuple[List[Dict[str, Any]], List[str]]:
    metrics: List[Dict[str, Any]] = []
    failures: List[str] = []
    grouped: Dict[str, List[Dict[str, Any]]] = {}
    for view in views:
        group = str(view.get("distinctness_group", ""))
        if group:
            grouped.setdefault(group, []).append(view)
    for group, grouped_views in grouped.items():
        for aspect in aspects:
            aspect_id = str(aspect["id"])
            captured_views: List[Tuple[str, Path, float, float, float]] = []
            for view in grouped_views:
                filenames = view.get("filenames", {})
                filename = filenames.get(aspect_id) if isinstance(filenames, dict) else None
                path = candidate_run / str(filename) if filename else None
                if path is not None and path.is_file():
                    captured_views.append(
                        (
                            str(view.get("id", "")),
                            path,
                            float(view.get("distinctness_edge_iou_max", 0.80)),
                            float(view.get("distinctness_min_edge_fraction", 0.002)),
                            float(view.get("distinctness_low_frequency_mae_min", 0.0)),
                        )
                    )
            sparse_failures: set[str] = set()
            for first, second in combinations(captured_views, 2):
                edge_metrics = _scene_edge_metrics(first[1], second[1])
                edge_iou = edge_metrics["scene_edge_iou"]
                threshold = min(first[2], second[2])
                low_frequency_mae = edge_metrics["low_frequency_mae"]
                low_frequency_threshold = max(first[4], second[4])
                metrics.append(
                    {
                        "group": group,
                        "aspect": aspect_id,
                        "first_view": first[0],
                        "second_view": second[0],
                        "scene_edge_iou": edge_iou,
                        "maximum_edge_iou": threshold,
                        "first_edge_fraction": edge_metrics["first_edge_fraction"],
                        "second_edge_fraction": edge_metrics["second_edge_fraction"],
                        "low_frequency_mae": low_frequency_mae,
                        "minimum_low_frequency_mae": low_frequency_threshold,
                    }
                )
                if edge_metrics["first_edge_fraction"] < first[3]:
                    sparse_failures.add(
                        f"{group}:{aspect_id}: {first[0]} has insufficient scene edges "
                        f"({edge_metrics['first_edge_fraction']:.6f}, minimum={first[3]:.6f})"
                    )
                if edge_metrics["second_edge_fraction"] < second[3]:
                    sparse_failures.add(
                        f"{group}:{aspect_id}: {second[0]} has insufficient scene edges "
                        f"({edge_metrics['second_edge_fraction']:.6f}, minimum={second[3]:.6f})"
                    )
                if low_frequency_mae <= low_frequency_threshold:
                    failures.append(
                        f"{group}:{aspect_id}: route captures {first[0]} and {second[0]} lack distinct "
                        f"low-frequency composition (MAE={low_frequency_mae:.4f}, "
                        f"minimum={low_frequency_threshold:.4f})"
                    )
                if edge_iou >= threshold:
                    failures.append(
                        f"{group}:{aspect_id}: route captures {first[0]} and {second[0]} are near-duplicates "
                        f"(scene edge IoU={edge_iou:.4f}, maximum={threshold:.4f})"
                    )
            failures.extend(sorted(sparse_failures))
    return metrics, failures


def _distinctness_group_completeness(
    manifest: Dict[str, Any],
    selected: List[Dict[str, Any]],
    selected_aspects: List[Dict[str, int]],
) -> List[Dict[str, Any]]:
    all_views = manifest.get("views", [])
    if not isinstance(all_views, list):
        return []
    required_by_group: Dict[str, set[str]] = {}
    for view in all_views:
        if not isinstance(view, dict) or view.get("capture_support") != "supported":
            continue
        group = str(view.get("distinctness_group", ""))
        if group:
            required_by_group.setdefault(group, set()).add(str(view.get("id", "")))
    selected_by_group: Dict[str, set[str]] = {}
    for view in selected:
        group = str(view.get("distinctness_group", ""))
        if group:
            selected_by_group.setdefault(group, set()).add(str(view.get("id", "")))
    manifest_aspects = manifest.get("aspects", [])
    required_aspect_ids = {
        str(aspect.get("id", ""))
        for aspect in manifest_aspects
        if isinstance(aspect, dict) and str(aspect.get("id", ""))
    } if isinstance(manifest_aspects, list) else set()
    selected_aspect_ids = {str(aspect["id"]) for aspect in selected_aspects}
    completeness: List[Dict[str, Any]] = []
    for group, selected_ids in sorted(selected_by_group.items()):
        required_ids = required_by_group.get(group, set())
        completeness.append(
            {
                "group": group,
                "required_views": sorted(required_ids),
                "selected_views": sorted(selected_ids),
                "required_aspects": sorted(required_aspect_ids),
                "selected_aspects": sorted(selected_aspect_ids),
                "complete": selected_ids == required_ids and selected_aspect_ids == required_aspect_ids,
            }
        )
    return completeness


def _promote_baseline_transactionally(captured: Dict[str, List[str]], baseline_root: Path) -> None:
    baseline_root.parent.mkdir(parents=True, exist_ok=True)
    stage_root = Path(
        tempfile.mkdtemp(prefix=f".{baseline_root.name}-stage-", dir=str(baseline_root.parent))
    )
    backup_root = Path(
        tempfile.mkdtemp(prefix=f".{baseline_root.name}-backup-", dir=str(baseline_root.parent))
    )
    shutil.rmtree(backup_root)
    baseline_moved = False
    preserve_backup = False
    try:
        if baseline_root.is_dir():
            shutil.copytree(baseline_root, stage_root, dirs_exist_ok=True)
        for paths in captured.values():
            for path in paths:
                source = Path(path)
                target = stage_root / source.name
                shutil.copy2(source, target)
                if hashlib.sha256(source.read_bytes()).digest() != hashlib.sha256(target.read_bytes()).digest():
                    raise RuntimeError(f"staged baseline hash mismatch for {source.name}")
        if baseline_root.exists():
            os.replace(baseline_root, backup_root)
            baseline_moved = True
        os.replace(stage_root, baseline_root)
    except Exception:
        if baseline_moved and backup_root.exists():
            try:
                if baseline_root.exists():
                    if baseline_root.is_dir():
                        shutil.rmtree(baseline_root)
                    else:
                        baseline_root.unlink()
                os.replace(backup_root, baseline_root)
            except Exception as restore_error:
                preserve_backup = True
                raise RuntimeError(
                    f"baseline promotion and rollback failed; approved backup retained at {backup_root}"
                ) from restore_error
        raise
    finally:
        if stage_root.exists():
            shutil.rmtree(stage_root, ignore_errors=True)
        if backup_root.exists() and not preserve_backup:
            shutil.rmtree(backup_root, ignore_errors=True)


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
    camera_pose_receipts: Dict[str, List[Dict[str, Any]]] = {}
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
                    pose_receipt: Optional[Dict[str, Any]] = None
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
                            source_path, pose_receipt = _direct_scene_capture(
                                Path(temp_root), view, aspect, render_fps, physics_tps
                            )
                        else:
                            raise ValueError(f"unsupported adapter for capture tool: {adapter}")
                        filenames = view.get("filenames", {})
                        if not isinstance(filenames, dict):
                            raise ValueError("incomplete filename config")
                        filename = filenames.get(aspect_id)
                        if not filename or not source_path.is_file():
                            raise FileNotFoundError("missing declared source or target")
                        target_path = _copy_capture(
                            source_path,
                            candidate_run / str(filename),
                            int(aspect["width"]),
                            int(aspect["height"]),
                        )
                        captured.setdefault(view_id, []).append(str(target_path))
                        if pose_receipt is not None:
                            image_digest = hashlib.sha256(target_path.read_bytes()).hexdigest()
                            camera_pose_receipts.setdefault(view_id, []).append(
                                {
                                    **pose_receipt,
                                    "aspect": aspect_id,
                                    "image_path": str(target_path),
                                    "image_sha256": image_digest,
                                }
                            )
                    except Exception as error:
                        capture_failures.append(
                            f"{view_id}:{aspect_id}: {type(error).__name__}: {error}"
                        )

    distinctness_metrics, distinctness_failures = _capture_distinctness_metrics(
        supported_views,
        aspects,
        candidate_run,
    )
    capture_failures.extend(distinctness_failures)
    distinctness_group_completeness = _distinctness_group_completeness(manifest, supported_views, aspects)

    for view in views:
        view_id = str(view.get("id", ""))
        if view.get("capture_support", "") != "unsupported":
            continue
        unsupported_requested.append(view_id)

    if approve:
        for group_status in distinctness_group_completeness:
            if not bool(group_status["complete"]):
                capture_failures.append(
                    f"baseline approval requires complete distinctness group {group_status['group']}: "
                    f"selected_views={group_status['selected_views']}, required_views={group_status['required_views']}, "
                    f"selected_aspects={group_status['selected_aspects']}, "
                    f"required_aspects={group_status['required_aspects']}"
                )
        if unsupported_requested:
            capture_failures.append(
                "baseline approval cannot include unsupported views: " + ", ".join(unsupported_requested)
            )

    approved = False
    if approve and not capture_failures:
        try:
            _promote_baseline_transactionally(captured, baseline_root)
            approved = True
        except Exception as error:
            capture_failures.append(
                f"baseline approval transaction failed: {type(error).__name__}: {error}"
            )

    report_path = candidate_run / "capture_report.json"
    report_path.write_text(
        json.dumps(
            {
                "manifest": str(manifest_path),
                "run_id": run_id,
                "candidate_root": str(candidate_run),
                "baseline_root": str(baseline_root),
                "captured": captured,
                "camera_pose_receipts": camera_pose_receipts,
                "distinctness_metrics": distinctness_metrics,
                "distinctness_group_completeness": distinctness_group_completeness,
                "unsupported_requested": unsupported_requested,
                "failures": capture_failures,
                "approval_requested": approve,
                "approved": approved,
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
