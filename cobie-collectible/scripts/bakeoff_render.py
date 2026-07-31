#!/usr/bin/env python3
"""Phase 2: render every candidate mesh identically, for scoring.

Run:
    uv run --project cobie-collectible/tools \
        python cobie-collectible/scripts/bakeoff_render.py

Reads every .glb in cobie-collectible/generated-meshes/ (except selected.glb)
and renders each one from the same five camera positions under the same neutral
clay material, then writes receipts and a scorecard to
builds/collectible/bakeoff/<run_id>/.

Why clay, and why no texture
----------------------------
PRD section 8.2: the V1 prints in neutral resin and is painted by hand, so
texture quality cannot inform the choice. Worse, a convincing texture actively
hides geometry that is expensive or impossible to manufacture. Candidates are
therefore judged on identity, silhouette and cleanable geometry under a flat
neutral material -- which is also the only way two meshes from different
generators can be compared at all.

The distinctness gate exists because it is genuinely easy to download the same
mesh twice, or to have a generator return something near-identical, and then
"choose" between two copies of one candidate.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))

import receipt as receipt_module
from _common import (
    BUILDS,
    FIGURE_HEIGHT_MM,
    Failure,
    GENERATED_MESHES,
    ROOT,
    TURNAROUND_VIEWS,
    UNIT_SCALE_LENGTH,
    candidate_count_failures,
    report,
    sha256_file,
    view_seed,
    write_json,
)

RESOLUTION = (512, 512)
CAMERA_DISTANCE = 300.0
CAMERA_HEIGHT = FIGURE_HEIGHT_MM
ORTHO_SCALE = 180.0
RUN_ID = "bakeoff-001"

# Two candidates whose silhouettes overlap more than this from every angle are
# the same mesh wearing two filenames.
MAX_SILHOUETTE_IOU = 0.985
MIN_COVERAGE = 0.02


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for collection in (bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.meshes):
        for block in list(collection):
            collection.remove(block)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = UNIT_SCALE_LENGTH


def clay_material() -> bpy.types.Material:
    """Flat neutral clay. Deliberately featureless."""
    material = bpy.data.materials.new("CN_Clay")
    material.use_nodes = True
    bsdf = material.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.55, 0.54, 0.52, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.75
    bsdf.inputs["Metallic"].default_value = 0.0
    return material


def setup_world() -> tuple[bpy.types.Object, bpy.types.Material]:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = RESOLUTION
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.view_settings.look = "AgX - Medium High Contrast"

    camera_data = bpy.data.cameras.new("BakeoffCamera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = ORTHO_SCALE
    camera = bpy.data.objects.new("BakeoffCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera

    # Fixed three-point rig, matching the house idiom in
    # tools/blender/build_rain_city_enforcer_atlas.py. Lighting is identical for
    # every candidate so differences in the render are differences in geometry.
    for name, rotation, energy in (
        ("Key", (0.9, 0.0, 0.6), 4.0),
        ("Fill", (1.1, 0.0, -1.2), 1.6),
        ("Rim", (1.4, 0.0, 3.1), 2.4),
    ):
        light_data = bpy.data.lights.new(name, "SUN")
        light_data.energy = energy
        light = bpy.data.objects.new(name, light_data)
        light.rotation_euler = rotation
        bpy.context.collection.objects.link(light)

    return camera, clay_material()


def place_camera(camera: bpy.types.Object, yaw_degrees: float) -> tuple[tuple, tuple]:
    origin = receipt_module.expected_camera_origin(yaw_degrees, CAMERA_DISTANCE, CAMERA_HEIGHT)
    camera.location = origin
    target = (0.0, 0.0, CAMERA_HEIGHT * 0.5)
    direction = tuple(t - o for t, o in zip(target, origin))
    from mathutils import Vector

    camera.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    forward = tuple(Vector(direction).normalized())
    return origin, forward


def import_candidate(path: Path, material: bpy.types.Material) -> list[bpy.types.Object]:
    from mathutils import Vector

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    imported = [obj for obj in bpy.data.objects if obj not in before and obj.type == "MESH"]
    if not imported:
        return []

    # Normalise every candidate to the same height and centre it on the origin,
    # or the comparison measures import scale rather than character design.
    corners = [obj.matrix_world @ Vector(corner) for obj in imported for corner in obj.bound_box]
    lowest = min(corner.z for corner in corners)
    highest = max(corner.z for corner in corners)
    span = highest - lowest
    factor = FIGURE_HEIGHT_MM / span if span else 1.0
    centre_x = sum(corner.x for corner in corners) / len(corners)
    centre_y = sum(corner.y for corner in corners) / len(corners)

    for obj in imported:
        obj.scale = tuple(component * factor for component in obj.scale)
        obj.location = (
            (obj.location.x - centre_x) * factor,
            (obj.location.y - centre_y) * factor,
            (obj.location.z - lowest) * factor,
        )
        obj.data.materials.clear()
        obj.data.materials.append(material)
    bpy.context.view_layer.update()
    return imported


def render_candidate(path: Path, camera: bpy.types.Object, material, out_dir: Path) -> tuple[list[dict], list[Failure]]:
    failures: list[Failure] = []
    candidate_id = path.stem
    imported = import_candidate(path, material)
    if not imported:
        return [], [Failure("import", candidate_id, "no mesh objects found in the file")]

    mesh_hash = sha256_file(path)
    receipts: list[dict] = []
    for view, yaw in TURNAROUND_VIEWS.items():
        origin, forward = place_camera(camera, yaw)
        image_path = out_dir / f"{candidate_id}__{view}.png"
        bpy.context.scene.render.filepath = str(image_path)
        bpy.ops.render.render(write_still=True)

        entry = receipt_module.build(
            view=view,
            candidate_id=candidate_id,
            render_seed=view_seed(view),
            render_engine=bpy.context.scene.render.engine,
            resolution=RESOLUTION,
            camera_origin=origin,
            camera_forward=forward,
            ortho_scale=camera.data.ortho_scale,
            yaw_degrees=yaw,
            mesh_sha256=mesh_hash,
            image_path=image_path,
            root=ROOT,
        )
        # Verify immediately, against the same contract a reader would apply.
        failures.extend(
            receipt_module.verify(
                entry,
                distance=CAMERA_DISTANCE,
                height=CAMERA_HEIGHT,
                ortho_scale=ORTHO_SCALE,
                root=ROOT,
            )
        )
        receipts.append(entry)

    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)
    return receipts, failures


def silhouette(path: Path):
    import numpy as np
    from PIL import Image

    with Image.open(path) as handle:
        return np.array(handle.convert("RGBA"))[..., 3] > 127


def check_distinctness(receipts: list[dict], out_dir: Path) -> tuple[list[Failure], dict]:
    import numpy as np

    failures: list[Failure] = []
    by_view: dict[str, dict[str, Path]] = {}
    for entry in receipts:
        by_view.setdefault(entry["view"], {})[entry["candidate_id"]] = ROOT / entry["image_path"]

    metrics: dict[str, dict] = {}
    pair_max: dict[tuple[str, str], float] = {}

    for view, candidates in by_view.items():
        masks = {name: silhouette(path) for name, path in candidates.items()}
        for name, mask in masks.items():
            coverage = float(mask.mean())
            metrics.setdefault(name, {})[f"{view}_coverage"] = round(coverage, 5)
            if coverage < MIN_COVERAGE:
                failures.append(
                    Failure("empty_render", f"{name}/{view}", f"silhouette covers only {coverage:.2%} of the frame")
                )

        names = sorted(masks)
        for i, left in enumerate(names):
            for right in names[i + 1 :]:
                a, b = masks[left], masks[right]
                union = np.logical_or(a, b).sum()
                iou = float(np.logical_and(a, b).sum() / union) if union else 1.0
                key = (left, right)
                pair_max[key] = max(pair_max.get(key, 0.0), iou)
                metrics.setdefault(f"{left}|{right}", {})[f"{view}_silhouette_iou"] = round(iou, 5)

    # A pair is only a duplicate if it matches from EVERY angle. Two genuinely
    # different characters can share a front silhouette; they will not share
    # all five.
    for (left, right), worst in pair_max.items():
        minimum = min(
            value
            for key, value in metrics.get(f"{left}|{right}", {}).items()
            if key.endswith("_silhouette_iou")
        )
        if minimum > MAX_SILHOUETTE_IOU:
            failures.append(
                Failure(
                    "duplicate_candidates",
                    f"{left} vs {right}",
                    f"silhouettes agree at IoU >= {minimum:.4f} from every view; "
                    "these are the same mesh, so the bakeoff has fewer real candidates than it appears",
                )
            )

    write_json(out_dir / "distinctness.json", metrics)
    return failures, metrics


SCORECARD_HEADER = """# Cobie figurine mesh bakeoff -- scorecard

Score each candidate 1-5 from the clay and silhouette renders in this
directory. Do not score from textured previews (PRD 8.2).

Texture is deliberately absent. If a candidate only looks good with texture on,
it is not a good candidate.

| Candidate | Identity | Silhouette | Proportions | Paws | Tail | Accessory coherence | Hidden side | Cleanup burden | Total |
|---|---|---|---|---|---|---|---|---|---|
"""


def main() -> int:
    candidates = sorted(p for p in GENERATED_MESHES.glob("*.glb") if p.name != "selected.glb")
    out_dir = BUILDS / "bakeoff" / RUN_ID
    out_dir.mkdir(parents=True, exist_ok=True)

    if not candidates:
        print(f"  no candidate .glb files in {GENERATED_MESHES.relative_to(ROOT)}")
        print("  Generate at least three (Hunyuan3D multi-view, TRELLIS, Stable Fast 3D)")
        print("  from the validated turnaround, then rerun.")
        print("COBIE_BAKEOFF_RENDER: FAIL (no candidates)")
        return 1

    failures = candidate_count_failures(len(candidates))
    if failures:
        print(f"  FAIL: only {len(candidates)} candidate(s); at least three are required")

    reset_scene()
    camera, material = setup_world()

    receipts: list[dict] = []
    for path in candidates:
        print(f"  rendering {path.name}")
        entries, candidate_failures = render_candidate(path, camera, material, out_dir)
        receipts.extend(entries)
        failures.extend(candidate_failures)

    distinct_failures, distinct_metrics = check_distinctness(receipts, out_dir)
    failures.extend(distinct_failures)

    write_json(
        out_dir / "capture_report.json",
        {
            "run_id": RUN_ID,
            "candidates": [path.name for path in candidates],
            "environment": receipt_module.environment_stamp(),
            "receipts": receipts,
            "distinctness": distinct_metrics,
            "failures": [failure.as_dict() for failure in failures],
        },
    )

    scorecard = out_dir / "scorecard.md"
    if not scorecard.exists():
        rows = "".join(f"| {path.stem} | | | | | | | | | |\n" for path in candidates)
        scorecard.write_text(SCORECARD_HEADER + rows)

    print(f"  renders and receipts: {out_dir.relative_to(ROOT)}")
    return report("COBIE_BAKEOFF_RENDER", failures, {"candidates": len(candidates), "renders": len(receipts)})


if __name__ == "__main__":
    raise SystemExit(main())
