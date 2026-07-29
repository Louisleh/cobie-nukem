#!/usr/bin/env python3
"""Fail-closed structure/provenance gate for the V2 Blender master."""

from __future__ import annotations

import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from _common import PART_NAMES, PIPELINE_VERSION, ROOT, sha256_file
from create_refinement_master import MASTER_BLEND, REFERENCE_SPECS, TOP_LEVEL_COLLECTIONS

REFINEMENT_STAGES = ("silhouette", "head", "costume", "launcher", "final")


def main() -> None:
    failures: list[str] = []
    if not MASTER_BLEND.is_file():
        raise FileNotFoundError(MASTER_BLEND)
    bpy.ops.wm.open_mainfile(filepath=str(MASTER_BLEND))

    scene = bpy.context.scene
    observed_top_level = {collection.name for collection in scene.collection.children}
    expected_top_level = set(TOP_LEVEL_COLLECTIONS)
    if observed_top_level != expected_top_level:
        failures.append(
            f"top-level collections differ: expected={sorted(expected_top_level)} "
            f"observed={sorted(observed_top_level)}"
        )

    print_collection = bpy.data.collections.get("PRINT_EXPORT")
    print_inventory = (
        {obj.name for obj in print_collection.objects}
        if print_collection is not None
        else set()
    )
    if print_inventory != set(PART_NAMES):
        failures.append(
            f"PRINT_EXPORT differs: expected={sorted(PART_NAMES)} observed={sorted(print_inventory)}"
        )
    elif any(obj.type != "MESH" for obj in print_collection.objects):
        failures.append("every PRINT_EXPORT object must be a mesh")

    source_collection = bpy.data.collections.get("SCULPT_SOURCE")
    source_meshes = (
        [obj for obj in source_collection.all_objects if obj.type == "MESH"]
        if source_collection is not None
        else []
    )
    if len(source_meshes) < len(PART_NAMES):
        failures.append("SCULPT_SOURCE must retain editable semantic construction meshes")
    for obj in source_meshes:
        if obj.get("cobie_part") not in PART_NAMES:
            failures.append(f"{obj.name}: missing canonical cobie_part")
        if not isinstance(obj.get("cobie_zone"), str):
            failures.append(f"{obj.name}: missing cobie_zone")
        if not isinstance(obj.get("cobie_role"), str):
            failures.append(f"{obj.name}: missing cobie_role")
        if obj.get("cobie_stage") not in REFINEMENT_STAGES:
            failures.append(f"{obj.name}: invalid cobie_stage {obj.get('cobie_stage')!r}")

    lookdev_collection = bpy.data.collections.get("LOOKDEV")
    lookdev_meshes = (
        [obj for obj in lookdev_collection.all_objects if obj.type == "MESH"]
        if lookdev_collection is not None
        else []
    )
    if not lookdev_meshes:
        failures.append("LOOKDEV must contain semantic meshes")
    for obj in lookdev_meshes:
        if obj.get("cobie_part") not in PART_NAMES:
            failures.append(f"{obj.name}: LOOKDEV mesh lacks canonical cobie_part")
        if not obj.material_slots or any(
            slot.material is None for slot in obj.material_slots
        ):
            failures.append(f"{obj.name}: LOOKDEV mesh lacks a bound material")

    active_stage = scene.get("refinement_stage")
    if active_stage not in REFINEMENT_STAGES:
        failures.append(f"invalid scene refinement_stage {active_stage!r}")
    else:
        active_index = REFINEMENT_STAGES.index(active_stage)
        for obj in lookdev_meshes:
            object_stage = obj.get("cobie_stage")
            if (
                object_stage not in REFINEMENT_STAGES
                or REFINEMENT_STAGES.index(object_stage) > active_index
            ):
                failures.append(
                    f"{obj.name}: inactive stage {object_stage!r} leaked into LOOKDEV"
                )

    reference_collection = bpy.data.collections.get("REFERENCE")
    reference_objects = (
        {obj.name: obj for obj in reference_collection.objects}
        if reference_collection is not None
        else {}
    )
    for name, source_path, expected_sha256, role in REFERENCE_SPECS:
        marker = reference_objects.get(name)
        disk_path = ROOT / source_path
        if marker is None:
            failures.append(f"missing reference marker {name}")
            continue
        if marker.get("source_path") != source_path or marker.get("role") != role:
            failures.append(f"reference marker metadata drifted for {name}")
        if not disk_path.is_file():
            failures.append(f"reference file missing: {source_path}")
        elif sha256_file(disk_path) != expected_sha256:
            failures.append(f"reference hash drifted: {source_path}")
        if marker.get("source_sha256") != expected_sha256:
            failures.append(f"embedded reference hash drifted for {name}")

    if bpy.data.images:
        failures.append("master must not embed or externally link image datablocks")
    if bpy.data.libraries:
        failures.append("master must not link external Blender libraries")
    if scene.get("cobie_pipeline_version") != PIPELINE_VERSION:
        failures.append("master pipeline version does not match current source")
    if scene.get("build_mode") != "cover_refinement_v2":
        failures.append("master build_mode must be cover_refinement_v2")
    if scene.get("identity_approved") is not False:
        failures.append("identity_approved must remain false before owner photo review")
    if scene.get("physical_validation_complete") is not False:
        failures.append("physical_validation_complete must remain false before a physical test")
    if scene.get("physical_prototype_approved") is not False:
        failures.append("physical_prototype_approved must remain false before a physical test")
    if scene.get("manufacture_authorized") is not False:
        failures.append("manufacture_authorized must remain false before human/physical approval")

    review_collection = bpy.data.collections.get("REVIEW_RIG")
    review_objects = list(review_collection.all_objects) if review_collection else []
    if sum(obj.type == "CAMERA" for obj in review_objects) != 1:
        failures.append("REVIEW_RIG must contain exactly one camera")
    if sum(obj.type == "LIGHT" for obj in review_objects) != 3:
        failures.append("REVIEW_RIG must contain exactly three lights")

    if failures:
        for failure in failures:
            print(f"  - {failure}")
        raise SystemExit("COBIE_REFINEMENT_MASTER_VALIDATE: FAIL")
    print("COBIE_REFINEMENT_MASTER_VALIDATE: PASS")


if __name__ == "__main__":
    main()
