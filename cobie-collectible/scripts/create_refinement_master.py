#!/usr/bin/env python3
"""Create the LFS-backed V2 refinement master from the proven V1 baseline.

Run with native Blender:
    /Applications/Blender.app/Contents/MacOS/Blender --background \
      --python cobie-collectible/scripts/create_refinement_master.py

This is intentionally a one-way seed operation. Future accepted sculpt/lookdev
work lives in the master rather than being regenerated from this script.
"""

from __future__ import annotations

import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from _common import FIGURINE_BLEND, PART_NAMES, ROOT, SCALE_CONTRACT, UNIT_SCALE_LENGTH

MASTER_BLEND = FIGURINE_BLEND.with_name("cobie_figurine_v2_master.blend")
TOP_LEVEL_COLLECTIONS = (
    "REFERENCE",
    "SCULPT_SOURCE",
    "LOOKDEV",
    "PRINT_EXPORT",
    "REVIEW_RIG",
)
REFERENCE_SPECS = (
    (
        "REF_PrimaryCover",
        "assets/brand/cobie_nukem_cover.png",
        "d9261853c1c5013b22164667d24958e639fcc6e97967e342be017f63a1810d6f",
        "geometry_pose_identity_direction",
    ),
    (
        "REF_SecondaryCover",
        "cobie-collectible/references/game-art/cobie_nukem_dual_blaster_cover_reference.png",
        "70d17b427cd8e4c6a686b34cf188155bf180d5de7e9e16f83556e5f497d18478",
        "fur_leather_material_hardsurface_direction_only",
    ),
)


def _collection(name: str) -> bpy.types.Collection:
    collection = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if collection.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(collection)
    return collection


def _unlink_everywhere(obj: bpy.types.Object) -> None:
    for collection in list(obj.users_collection):
        collection.objects.unlink(obj)


def _add_reference_markers(collection: bpy.types.Collection) -> None:
    for name, source_path, source_sha256, role in REFERENCE_SPECS:
        marker = bpy.data.objects.new(name, None)
        marker.empty_display_type = "IMAGE"
        marker.empty_display_size = 20.0
        marker["source_path"] = source_path
        marker["source_sha256"] = source_sha256
        marker["role"] = role
        marker["embedded_pixels"] = False
        collection.objects.link(marker)


def _add_review_rig(collection: bpy.types.Collection) -> None:
    camera_data = bpy.data.cameras.new("Review_Camera_Data")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 166.0
    camera = bpy.data.objects.new("Review_Camera", camera_data)
    camera.location = (0.0, -360.0, 82.0)
    camera["protocol"] = "neutral_geometry_v1"
    collection.objects.link(camera)
    bpy.context.scene.camera = camera

    lights = (
        ("Review_Key", (-105.0, -145.0, 205.0), 3.8, 0.16),
        ("Review_Fill", (130.0, -95.0, 120.0), 1.45, 0.32),
        ("Review_Rim", (40.0, 130.0, 185.0), 2.35, 0.22),
    )
    for name, location, energy, angle in lights:
        light_data = bpy.data.lights.new(f"{name}_Data", type="SUN")
        light_data.energy = energy
        light_data.angle = angle
        light = bpy.data.objects.new(name, light_data)
        light.location = location
        light["protocol"] = "neutral_geometry_v1"
        collection.objects.link(light)


def main() -> None:
    if not FIGURINE_BLEND.is_file():
        raise FileNotFoundError(
            f"{FIGURINE_BLEND.relative_to(ROOT)} is missing; run build_figurine.py first"
        )
    bpy.ops.wm.open_mainfile(filepath=str(FIGURINE_BLEND))

    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = UNIT_SCALE_LENGTH
    scene["scale_contract"] = SCALE_CONTRACT
    scene["work_id"] = "cobie-collectible-cover-refinement-v2"
    scene["baseline_revision"] = "ed050bebc9e2f4524593a7cb8b92ad50a69d8d51"
    scene["primary_cover_role"] = "geometry_pose_identity_direction"
    scene["secondary_cover_role"] = "surface_hardsurface_direction_only"
    scene["identity_approved"] = False
    scene["physical_prototype_approved"] = False

    collections = {name: _collection(name) for name in TOP_LEVEL_COLLECTIONS}

    print_objects: list[bpy.types.Object] = []
    for part_name in PART_NAMES:
        obj = bpy.data.objects.get(part_name)
        if obj is None or obj.type != "MESH":
            raise RuntimeError(f"baseline is missing canonical mesh {part_name}")
        _unlink_everywhere(obj)
        collections["PRINT_EXPORT"].objects.link(obj)
        obj["role"] = "canonical_print_export"
        print_objects.append(obj)

    for obj in print_objects:
        source = obj.copy()
        source.data = obj.data
        source.name = f"SRC_{obj.name}"
        source.hide_render = True
        source["role"] = "linked_baseline_sculpt_seed"
        source["derived_print_part"] = obj.name
        collections["SCULPT_SOURCE"].objects.link(source)

    collections["LOOKDEV"]["semantic_status"] = "pending_v2_refinement"
    collections["LOOKDEV"]["print_silhouette_parity_required"] = True
    _add_reference_markers(collections["REFERENCE"])
    _add_review_rig(collections["REVIEW_RIG"])

    for obj in tuple(scene.collection.objects):
        if not obj.users_collection:
            bpy.data.objects.remove(obj, do_unlink=True)

    MASTER_BLEND.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(MASTER_BLEND), check_existing=False)
    print(f"COBIE_REFINEMENT_MASTER_CREATE: PASS ({MASTER_BLEND.relative_to(ROOT)})")


if __name__ == "__main__":
    main()
