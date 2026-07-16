#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import numpy as np
from PIL import Image

JSON_SUFFIX = ".json"
MARKDOWN_SUFFIX = ".md"
DIFF_IMAGE_SUFFIX = ".png"


@dataclass(frozen=True)
class ImageMetrics:
    width: int
    height: int
    alpha_coverage: float
    blank_coverage: float
    luminance_min: float
    luminance_max: float
    luminance_mean: float
    luminance_median: float
    luminance_p05: float
    luminance_p95: float
    luminance_std: float
    contrast: float

    def as_dict(self) -> Dict[str, Any]:
        return {
            "dimensions": {"width": self.width, "height": self.height},
            "alpha_coverage": self.alpha_coverage,
            "blank_coverage": self.blank_coverage,
            "luminance": {
                "min": self.luminance_min,
                "max": self.luminance_max,
                "mean": self.luminance_mean,
                "median": self.luminance_median,
                "p05": self.luminance_p05,
                "p95": self.luminance_p95,
                "std": self.luminance_std,
            },
            "contrast": self.contrast,
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare visual capture artifacts against a manifest-defined baseline."
    )
    parser.add_argument("--manifest", required=True, help="Path to capture manifest JSON.")
    parser.add_argument(
        "--baseline",
        required=True,
        help="Directory containing baseline capture PNGs.",
    )
    parser.add_argument(
        "--candidate",
        required=True,
        help="Directory containing candidate capture PNGs.",
    )
    parser.add_argument(
        "--out",
        default="builds/visual-quality/compare",
        help="Directory to write comparison artifacts.",
    )
    return parser.parse_args()


def _load_json(path: Path) -> Dict[str, Any]:
    raw = path.read_text(encoding="utf-8")
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError(f"manifest did not parse as object: {path}")
    return data


def load_manifest(manifest_path: Path) -> Dict[str, Any]:
    return _load_json(Path(manifest_path))


def _aspect_map(manifest: Dict[str, Any]) -> Dict[str, Tuple[int, int]]:
    aspect_entries = manifest.get("aspects")
    if not isinstance(aspect_entries, list) or not aspect_entries:
        raise ValueError("manifest missing aspects")
    result: Dict[str, Tuple[int, int]] = {}
    for aspect in aspect_entries:
        if not isinstance(aspect, dict):
            continue
        aspect_id = aspect.get("id")
        width = int(aspect.get("width", 0))
        height = int(aspect.get("height", 0))
        if not aspect_id or width <= 0 or height <= 0:
            raise ValueError(f"invalid aspect entry: {aspect}")
        result[str(aspect_id)] = (width, height)
    return result


def _supported_states(manifest: Dict[str, Any]) -> List[str]:
    states = manifest.get("support_states")
    if not isinstance(states, list):
        return ["supported", "unsupported"]
    return [str(state) for state in states]


def _read_image(path: Path) -> np.ndarray:
    with Image.open(path) as image:
        return np.array(image.convert("RGBA"), dtype=np.float32) / 255.0


def _luminance(image: np.ndarray) -> np.ndarray:
    rgb = image[..., :3]
    return 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]


def _image_metrics(path: Path) -> ImageMetrics:
    image = _read_image(path)
    alpha = image[..., 3]
    alpha_mask = alpha >= 0.01
    alpha_coverage = float(np.mean(alpha_mask))
    rgb_masked = image[..., :3][alpha_mask]
    if rgb_masked.size == 0:
        blank_coverage = 1.0
        luminance_values = np.array([0.0, 0.0], dtype=np.float32)
    else:
        luminance_values = _luminance(image)[alpha_mask]
        blank_mask = np.max(np.abs(image[..., :3] - 0.0), axis=2) <= 0.02
        blank_coverage = float(np.mean(np.logical_or(~alpha_mask, blank_mask)))
    luminance_min = float(np.min(luminance_values))
    luminance_max = float(np.max(luminance_values))
    luminance_mean = float(np.mean(luminance_values))
    luminance_median = float(np.median(luminance_values))
    luminance_p05 = float(np.percentile(luminance_values, 5))
    luminance_p95 = float(np.percentile(luminance_values, 95))
    luminance_std = float(np.std(luminance_values))
    contrast = float(
        (luminance_max - luminance_min) / max(1e-6, (luminance_max + luminance_min))
    )
    return ImageMetrics(
        width=int(image.shape[1]),
        height=int(image.shape[0]),
        alpha_coverage=alpha_coverage,
        blank_coverage=blank_coverage,
        luminance_min=luminance_min,
        luminance_max=luminance_max,
        luminance_mean=luminance_mean,
        luminance_median=luminance_median,
        luminance_p05=luminance_p05,
        luminance_p95=luminance_p95,
        luminance_std=luminance_std,
        contrast=contrast,
    )


def _resize_for_perceptual(image: np.ndarray, target: Tuple[int, int]) -> np.ndarray:
    mode = "RGBA" if image.shape[-1] == 4 else "RGB"
    with Image.fromarray((np.clip(image * 255, 0, 255).astype(np.uint8)), mode=mode) as image_obj:
        resized = image_obj.resize(target, resample=Image.Resampling.BILINEAR).convert("RGB")
        return np.array(resized, dtype=np.float32) / 255.0


def _pair_metrics(
    baseline_path: Path,
    candidate_path: Path,
) -> Dict[str, Any]:
    baseline_image = _read_image(baseline_path)
    candidate_image = _read_image(candidate_path)

    baseline_metrics = _image_metrics(baseline_path)
    candidate_metrics = _image_metrics(candidate_path)

    baseline_rgb = baseline_image[..., :3]
    candidate_rgb = candidate_image[..., :3]
    if baseline_image.shape != candidate_image.shape:
        candidate_shape_aligned = _resize_for_perceptual(
            candidate_image, (baseline_rgb.shape[1], baseline_rgb.shape[0])
        )[..., :3]
    else:
        candidate_shape_aligned = candidate_image

    rgb_baseline = baseline_image[..., :3]
    rgb_candidate = candidate_shape_aligned[..., :3]
    delta = np.abs(rgb_baseline - rgb_candidate)
    mae = float(np.mean(delta))
    rmse = float(math.sqrt(float(np.mean(np.square(delta)))))
    max_delta = float(np.max(delta))
    low_baseline = _resize_for_perceptual(
        baseline_image,
        (64, 64),
    )[..., :3]
    low_candidate = _resize_for_perceptual(
        candidate_shape_aligned,
        (64, 64),
    )[..., :3]
    low_delta = np.abs(low_baseline[..., 0] - low_candidate[..., 0])
    low_delta += np.abs(low_baseline[..., 1] - low_candidate[..., 1])
    low_delta += np.abs(low_baseline[..., 2] - low_candidate[..., 2])
    low_delta /= 3.0
    perceptual_mae = float(np.mean(low_delta))

    return {
        "baseline": baseline_metrics.as_dict(),
        "candidate": candidate_metrics.as_dict(),
        "delta": {
            "mae": mae,
            "rmse": rmse,
            "max": max_delta,
            "perceptual_mae": perceptual_mae,
        },
        "delta_dimensions": {
            "baseline": {"width": int(baseline_rgb.shape[1]), "height": int(baseline_rgb.shape[0])},
            "candidate": {"width": int(candidate_shape_aligned.shape[1]), "height": int(candidate_shape_aligned.shape[0])},
            "raw_candidate": {
                "width": int(candidate_rgb.shape[1]),
                "height": int(candidate_rgb.shape[0]),
            },
        },
    }


def _write_difference_image(
    baseline_path: Path,
    candidate_path: Path,
    output_root: Path,
    view_id: str,
    aspect_id: str,
) -> Optional[str]:
    output_root.mkdir(parents=True, exist_ok=True)
    with Image.open(baseline_path) as baseline_image:
        baseline_rgb = np.array(baseline_image.convert("RGB"), dtype=np.float32) / 255.0
    with Image.open(candidate_path) as candidate_image:
        candidate_rgb = np.array(candidate_image.convert("RGB"), dtype=np.float32) / 255.0

    if baseline_rgb.shape != candidate_rgb.shape:
        candidate_rgb = _resize_for_perceptual(
            np.dstack([candidate_rgb, np.ones((candidate_rgb.shape[0], candidate_rgb.shape[1], 1))]),
            (baseline_rgb.shape[1], baseline_rgb.shape[0]),
        )[..., :3]

    difference = np.abs(baseline_rgb - candidate_rgb)
    grayscale = np.mean(difference, axis=2)
    visible = np.clip(grayscale * 255.0, 0.0, 255.0).astype(np.uint8)
    output_image = np.stack([visible, visible, visible], axis=2)

    output_path = output_root / f"{view_id}_{aspect_id}_diff{DIFF_IMAGE_SUFFIX}"
    with Image.fromarray(output_image, mode="RGB") as image_obj:
        image_obj.save(output_path, format="PNG")
    return str(output_path)


def _add_hard_failure(results: Dict[str, Any], message: str) -> None:
    if message not in results["hard_failures"]:
        results["hard_failures"].append(message)


def compare_views(
    manifest: Dict[str, Any],
    baseline_dir: Path,
    candidate_dir: Path,
    output_root: Path,
) -> Dict[str, Any]:
    aspects = _aspect_map(manifest)
    views = manifest.get("views", [])
    supported = set(_supported_states(manifest))
    results = {
        "hard_failures": [],
        "warnings": [],
        "skipped": [],
        "items": [],
    }

    diff_root = output_root / "differences"

    for view in views if isinstance(views, list) else []:
        if not isinstance(view, dict):
            continue
        view_id = str(view.get("id", ""))
        support = str(view.get("capture_support", ""))
        filenames = view.get("filenames", {})

        if support not in supported:
            _add_hard_failure(results, f"invalid support state for {view_id}: {support}")
            continue
        if support != "supported":
            results["skipped"].append(
                {
                    "view_id": view_id,
                    "reason": "capture_support is unsupported by current adapter",
                }
            )
            continue

        if not isinstance(filenames, dict):
            _add_hard_failure(results, f"missing filename map for supported view {view_id}")
            continue

        for aspect_id, (expected_width, expected_height) in aspects.items():
            filename = filenames.get(aspect_id)
            if not isinstance(filename, str) or not filename:
                _add_hard_failure(results, f"missing filename for {view_id}:{aspect_id}")
                continue
            baseline_path = baseline_dir / filename
            candidate_path = candidate_dir / filename

            if not baseline_path.is_file():
                _add_hard_failure(
                    results,
                    f"baseline missing {view_id}:{aspect_id} -> {baseline_path}",
                )
                continue
            if not candidate_path.is_file():
                _add_hard_failure(
                    results,
                    f"candidate missing {view_id}:{aspect_id} -> {candidate_path}",
                )
                continue

            pair = _pair_metrics(baseline_path, candidate_path)
            baseline_dimensions = pair["baseline"]["dimensions"]
            candidate_dimensions = pair["candidate"]["dimensions"]
            difference_path = _write_difference_image(
                baseline_path,
                candidate_path,
                diff_root,
                view_id,
                aspect_id,
            )

            if (baseline_dimensions["width"], baseline_dimensions["height"]) != (
                expected_width,
                expected_height,
            ):
                _add_hard_failure(
                    results,
                    f"wrong baseline dimensions for {view_id}:{aspect_id} expected "
                    f"{expected_width}x{expected_height}, found "
                    f"{baseline_dimensions['width']}x{baseline_dimensions['height']}",
                )
            if (candidate_dimensions["width"], candidate_dimensions["height"]) != (
                expected_width,
                expected_height,
            ):
                _add_hard_failure(
                    results,
                    f"wrong candidate dimensions for {view_id}:{aspect_id} expected "
                    f"{expected_width}x{expected_height}, found "
                    f"{candidate_dimensions['width']}x{candidate_dimensions['height']}",
                )

            candidate_alpha = float(pair["candidate"]["alpha_coverage"])
            if candidate_alpha < 0.98:
                _add_hard_failure(
                    results,
                    f"candidate mostly transparent for {view_id}:{aspect_id} (alpha coverage={candidate_alpha:.4f})",
                )
            candidate_luminance = pair["candidate"]["luminance"]
            baseline_luminance = pair["baseline"]["luminance"]
            if float(pair["candidate"]["blank_coverage"]) > 0.99 or float(candidate_luminance["std"]) < 0.001:
                _add_hard_failure(
                    results,
                    f"candidate blank image for {view_id}:{aspect_id} (blank coverage={pair['candidate']['blank_coverage']:.4f})",
                )
            if float(pair["baseline"]["blank_coverage"]) > 0.99 or float(baseline_luminance["std"]) < 0.001:
                _add_hard_failure(
                    results,
                    f"baseline blank image for {view_id}:{aspect_id} (blank coverage={pair['baseline']['blank_coverage']:.4f})",
                )
            if float(pair["baseline"]["alpha_coverage"]) < 0.98:
                _add_hard_failure(
                    results,
                    f"baseline mostly transparent for {view_id}:{aspect_id} (alpha coverage={pair['baseline']['alpha_coverage']:.4f})",
                )

            delta = pair["delta"]
            if delta["mae"] > 0.002:
                results["warnings"].append(
                    {
                        "view_id": view_id,
                        "aspect": aspect_id,
                        "type": "delta_mae",
                        "value": delta["mae"],
                        "message": "pixel MAE exceeded review threshold",
                    }
                )
            if delta["perceptual_mae"] > 0.002:
                results["warnings"].append(
                    {
                        "view_id": view_id,
                        "aspect": aspect_id,
                        "type": "perceptual_mae",
                        "value": delta["perceptual_mae"],
                        "message": "perceptual difference exceeded review threshold",
                    }
                )

            results["items"].append(
                {
                    "view_id": view_id,
                    "aspect": aspect_id,
                    "filename": filename,
                    "baseline": baseline_dimensions,
                    "candidate": candidate_dimensions,
                    "delta": delta,
                    "difference_image": difference_path,
                    "baseline_metrics": pair["baseline"],
                    "candidate_metrics": pair["candidate"],
                }
            )

    return results


def compare_captures(
    manifest_path: Path,
    baseline_dir: Path,
    candidate_dir: Path,
    output_dir: Path,
) -> Dict[str, Any]:
    manifest = load_manifest(manifest_path)
    baseline_root = Path(baseline_dir)
    candidate_root = Path(candidate_dir)
    output_root = Path(output_dir)
    output_root.mkdir(parents=True, exist_ok=True)

    comparison = compare_views(manifest, baseline_root, candidate_root, output_root)
    comparison["manifest"] = str(manifest_path)
    comparison["baseline_dir"] = str(baseline_root)
    comparison["candidate_dir"] = str(candidate_root)
    comparison["supported_states"] = _supported_states(manifest)
    comparison["exit_code"] = 1 if comparison["hard_failures"] else 0

    report_json = output_root / ("comparison" + JSON_SUFFIX)
    report_markdown = output_root / ("comparison" + MARKDOWN_SUFFIX)
    report_json.write_text(
        json.dumps(comparison, indent=2, sort_keys=True), encoding="utf-8"
    )
    report_markdown.write_text(_render_markdown(manifest, comparison), encoding="utf-8")
    return comparison


def _render_markdown(manifest: Dict[str, Any], report: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append("# Visual Capture Comparison")
    lines.append("")
    lines.append(f"- manifest: {report.get('manifest', '')}")
    lines.append(f"- baseline: {report.get('baseline_dir', '')}")
    lines.append(f"- candidate: {report.get('candidate_dir', '')}")
    lines.append(f"- status: {'PASS' if report.get('exit_code', 1) == 0 else 'FAIL'}")
    lines.append("")

    hard_failures = report.get("hard_failures", [])
    if hard_failures:
        lines.append("## Hard failures")
        for failure in hard_failures:
            lines.append(f"- {failure}")
        lines.append("")

    warnings = report.get("warnings", [])
    if warnings:
        lines.append("## Review warnings")
        lines.append("")
        lines.append("| View | Aspect | Type | Value | Message |")
        lines.append("| --- | --- | --- | --- | --- |")
        for item in warnings:
            lines.append(
                "| {view} | {aspect} | {type} | {value} | {message} |".format(
                    view=str(item.get("view_id", "")),
                    aspect=str(item.get("aspect", "")),
                    type=str(item.get("type", "")),
                    value=f"{float(item.get('value', 0.0)):.6f}",
                    message=str(item.get("message", "")),
                )
            )
        lines.append("")

    skipped = report.get("skipped", [])
    if skipped:
        lines.append("## Skipped views")
        for item in skipped:
            lines.append(f"- {item.get('view_id', '')}: {item.get('reason', '')}")
        lines.append("")

    lines.append("## Compared views")
    lines.append(
        "| View | Aspect | MAE | RMSE | Perceptual MAE | Baseline dims | Candidate dims | Difference |"
    )
    lines.append(
        "| --- | --- | --- | --- | --- | --- | --- | --- |"
    )
    for item in report.get("items", []):
        baseline = item.get("baseline", {})
        candidate = item.get("candidate", {})
        delta = item.get("delta", {})
        lines.append(
            "| {view} | {aspect} | {mae:.6f} | {rmse:.6f} | {perceptual:.6f} | "
            "{bw}x{bh} | {cw}x{ch} | {diff} |".format(
                view=str(item.get("view_id", "")),
                aspect=str(item.get("aspect", "")),
                mae=float(delta.get("mae", 0.0)),
                rmse=float(delta.get("rmse", 0.0)),
                perceptual=float(delta.get("perceptual_mae", 0.0)),
                bw=int(baseline.get("width", 0)),
                bh=int(baseline.get("height", 0)),
                cw=int(candidate.get("width", 0)),
                ch=int(candidate.get("height", 0)),
                diff=str(item.get("difference_image", "")),
            )
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    result = compare_captures(
        manifest_path=Path(args.manifest),
        baseline_dir=Path(args.baseline),
        candidate_dir=Path(args.candidate),
        output_dir=Path(args.out),
    )
    if result.get("exit_code", 1) != 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
