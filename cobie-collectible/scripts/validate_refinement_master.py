#!/usr/bin/env python3
"""Fail-closed structure/provenance gate for the V2 Blender master."""

from __future__ import annotations

import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from _common import PART_NAMES, ROOT, sha256_file
from create_refinement_master import MASTER_BLEND, REFERENCE_SPECS, TOP_LEVEL_COLLECTIONS


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
    expected_sources = {f"SRC_{name}" for name in PART_NAMES}
    source_inventory = (
        {obj.name for obj in source_collection.objects}
        if source_collection is not None
        else set()
    )
    if source_inventory != expected_sources:
        failures.append(
            f"SCULPT_SOURCE differs: expected={sorted(expected_sources)} "
            f"observed={sorted(source_inventory)}"
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
    if scene.get("identity_approved") is not False:
        failures.append("identity_approved must remain false before owner photo review")
    if scene.get("physical_prototype_approved") is not False:
        failures.append("physical_prototype_approved must remain false before a physical test")

    if failures:
        for failure in failures:
            print(f"  - {failure}")
        raise SystemExit("COBIE_REFINEMENT_MASTER_VALIDATE: FAIL")
    print("COBIE_REFINEMENT_MASTER_VALIDATE: PASS")


if __name__ == "__main__":
    main()
