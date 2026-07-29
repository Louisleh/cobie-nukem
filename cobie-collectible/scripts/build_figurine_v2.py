#!/usr/bin/env python3
"""Build the cover-driven Cobie figurine V2 master and printable assembly.

The script is deterministic and uses only project-owned references plus
procedural Blender primitives.  It keeps three representations in one source:

* SCULPT_SOURCE: named editable construction primitives with semantic zones.
* LOOKDEV: material-assigned duplicates for colour review.
* PRINT_EXPORT: exactly the five fused, socketed, canonical printable meshes.

The remaining top-level collections are REFERENCE and REVIEW_RIG.  No other
top-level collection is created.

Default output is the canonical collectible pipeline:

    uv run --project cobie-collectible/tools --locked \
      python cobie-collectible/scripts/build_figurine_v2.py

For a non-publishing validation run, set COBIE_V2_OUTPUT_ROOT to a temporary
directory.  That redirects the master, STLs, and receipt away from the repo.
"""

from __future__ import annotations

import math
import os
import struct
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    BASE_DIAMETER_MM,
    BASE_PEG_SPECS,
    BASE_THICKNESS_MM,
    BLEND_DIR,
    BUILD_REPORT,
    EXPORTS,
    GLASSES_PIN_SPECS,
    HEAD_KEY_SPECS,
    NECK_CENTRE,
    NECK_DEPTH_MM,
    NECK_RADIUS_MM,
    PART_NAMES,
    PIPELINE_VERSION,
    PROP_PIN_SPECS,
    ROOT,
    SCALE_CONTRACT,
    SLICER_TESTS,
    SUNGLASSES_ARM_MM,
    UNIT_SCALE_LENGTH,
    sha256_file,
    write_json,
)


MODE = "cover_refinement_v2"
ASSET_ID = "cobie_figurine_v2"
STAGES = ("silhouette", "head", "costume", "launcher", "final")
ACTIVE_STAGE = os.environ.get("COBIE_V2_STAGE", "final").strip().lower()
if ACTIVE_STAGE not in STAGES:
    raise ValueError(
        f"COBIE_V2_STAGE must be one of {STAGES}; got {ACTIVE_STAGE!r}"
    )
FETCH_LAUNCHER_SOURCE = (
    ROOT / "assets" / "models" / "weapons" / "fetch_launcher_viewmodel.glb"
)
COVER_REFERENCE = ROOT / "assets" / "brand" / "cobie_nukem_cover.png"
SECONDARY_COVER_REFERENCE = (
    ROOT
    / "cobie-collectible"
    / "references"
    / "game-art"
    / "cobie_nukem_dual_blaster_cover_reference.png"
)

OUTPUT_OVERRIDE = os.environ.get("COBIE_V2_OUTPUT_ROOT")
if OUTPUT_OVERRIDE:
    OUTPUT_ROOT = Path(OUTPUT_OVERRIDE).expanduser().resolve()
    EXPORT_DESTINATION = OUTPUT_ROOT / "exports"
    BUILD_REPORT_PATH = EXPORT_DESTINATION / "build_report.json"
    BLEND_PATH = OUTPUT_ROOT / "cobie_figurine_v2_master.blend"
    SLICER_REPORT_PATH = OUTPUT_ROOT / "slicer-tests" / "prusaslicer_import_report.json"
else:
    OUTPUT_ROOT = ROOT
    EXPORT_DESTINATION = EXPORTS
    BUILD_REPORT_PATH = BUILD_REPORT
    BLEND_PATH = BLEND_DIR / "cobie_figurine_v2_master.blend"
    SLICER_REPORT_PATH = SLICER_TESTS / "prusaslicer_import_report.json"

TOP_LEVEL_COLLECTIONS = (
    "REFERENCE",
    "SCULPT_SOURCE",
    "LOOKDEV",
    "PRINT_EXPORT",
    "REVIEW_RIG",
)

REMESH_BODY_MM = 0.55
REMESH_HEAD_MM = 0.50
REMESH_DETAIL_MM = 0.30
REMESH_PROP_MM = 0.40

BASE_TOP = BASE_THICKNESS_MM
HEAD_CENTRE_Z = 117.0
HEAD_RADIUS = 17.5

BASE_SOCKET_CLEARANCES_MM = (0.25, 0.32)
HEAD_SOCKET_CLEARANCES_MM = (0.27, 0.26)
NECK_SOCKET_CLEARANCE_MM = 0.28
GLASSES_ENVELOPE_CLEARANCE_MM = 0.27
PROP_BULK_CLEARANCE_MM = 0.55
PROP_SOCKET_CLEARANCES_MM = (0.31, 0.30)

PROP_ROLL_RADIANS = math.radians(12.0)


@dataclass(frozen=True)
class Component:
    obj: bpy.types.Object
    zone: str
    role: str = "surface"
    stage: str = "silhouette"


COLLECTIONS: dict[str, bpy.types.Collection] = {}
MATERIALS: dict[str, bpy.types.Material] = {}
SOURCE_PARTS: dict[str, list[Component]] = {}


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    for child in list(scene.collection.children):
        scene.collection.children.unlink(child)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = UNIT_SCALE_LENGTH
    scene.unit_settings.length_unit = "MILLIMETERS"

    COLLECTIONS.clear()
    for name in TOP_LEVEL_COLLECTIONS:
        collection = bpy.data.collections.new(name)
        scene.collection.children.link(collection)
        COLLECTIONS[name] = collection


def move_to_collection(
    obj: bpy.types.Object,
    collection: bpy.types.Collection,
) -> bpy.types.Object:
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def new_mesh_object(name: str, collection: bpy.types.Collection) -> bpy.types.Object:
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    return move_to_collection(obj, collection)


def component(
    obj: bpy.types.Object,
    zone: str,
    *,
    role: str = "surface",
    stage: str = "silhouette",
) -> Component:
    obj["cobie_zone"] = zone
    obj["cobie_role"] = role
    obj["cobie_stage"] = stage
    return Component(obj, zone, role, stage)


def stage_at_least(stage: str) -> bool:
    return STAGES.index(ACTIVE_STAGE) >= STAGES.index(stage)


def sphere(
    name: str,
    radius: float,
    location,
    *,
    scale=(1.0, 1.0, 1.0),
    zone="fur",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> Component:
    bpy.ops.mesh.primitive_uv_sphere_add(
        radius=radius,
        location=location,
        segments=24,
        ring_count=12,
    )
    obj = new_mesh_object(name, COLLECTIONS[collection_name])
    obj.scale = scale
    return component(obj, zone, role=role, stage=stage)


def cylinder(
    name: str,
    radius: float,
    depth: float,
    location,
    *,
    rotation=(0.0, 0.0, 0.0),
    zone="fur",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> Component:
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
        vertices=32,
    )
    obj = new_mesh_object(name, COLLECTIONS[collection_name])
    return component(obj, zone, role=role, stage=stage)


def cube(
    name: str,
    size,
    location,
    *,
    rotation=(0.0, 0.0, 0.0),
    zone="leather",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> Component:
    bpy.ops.mesh.primitive_cube_add(
        size=1.0,
        location=location,
        rotation=rotation,
    )
    obj = new_mesh_object(name, COLLECTIONS[collection_name])
    obj.scale = size
    return component(obj, zone, role=role, stage=stage)


def torus(
    name: str,
    major: float,
    minor: float,
    location,
    *,
    rotation=(0.0, 0.0, 0.0),
    zone="brass",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> Component:
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major,
        minor_radius=minor,
        location=location,
        rotation=rotation,
        major_segments=24,
        minor_segments=10,
    )
    obj = new_mesh_object(name, COLLECTIONS[collection_name])
    return component(obj, zone, role=role, stage=stage)


def prism(
    name: str,
    points_xz: list[tuple[float, float]],
    centre_y: float,
    depth: float,
    *,
    zone="leather",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> Component:
    half = depth * 0.5
    vertices = [(x, centre_y - half, z) for x, z in points_xz]
    vertices.extend((x, centre_y + half, z) for x, z in points_xz)
    count = len(points_xz)
    faces: list[tuple[int, ...]] = [
        tuple(reversed(range(count))),
        tuple(range(count, count * 2)),
    ]
    for index in range(count):
        nxt = (index + 1) % count
        faces.append((index, nxt, count + nxt, count + index))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    COLLECTIONS[collection_name].objects.link(obj)
    return component(obj, zone, role=role, stage=stage)


def capsule(
    name: str,
    radius: float,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    *,
    zone="fur",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> list[Component]:
    a = Vector(start)
    b = Vector(end)
    direction = b - a
    if direction.length == 0.0:
        return [
            sphere(
                f"{name}_cap",
                radius,
                start,
                zone=zone,
                role=role,
                stage=stage,
                collection_name=collection_name,
            )
        ]
    middle = (a + b) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius,
        depth=direction.length,
        location=middle,
        vertices=24,
    )
    shaft = new_mesh_object(f"{name}_shaft", COLLECTIONS[collection_name])
    shaft.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return [
        component(shaft, zone, role=role, stage=stage),
        sphere(
            f"{name}_start",
            radius,
            start,
            zone=zone,
            role=role,
            stage=stage,
            collection_name=collection_name,
        ),
        sphere(
            f"{name}_end",
            radius,
            end,
            zone=zone,
            role=role,
            stage=stage,
            collection_name=collection_name,
        ),
    ]


def cylinder_between(
    name: str,
    radius: float,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    *,
    zone="gunmetal",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> Component:
    a = Vector(start)
    b = Vector(end)
    direction = b - a
    middle = (a + b) * 0.5
    item = cylinder(
        name,
        radius,
        direction.length,
        middle,
        zone=zone,
        role=role,
        stage=stage,
        collection_name=collection_name,
    )
    item.obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return item


def oriented_torus(
    name: str,
    major: float,
    minor: float,
    location: tuple[float, float, float],
    direction: tuple[float, float, float],
    *,
    zone="gunmetal",
    role="surface",
    stage="silhouette",
    collection_name="SCULPT_SOURCE",
) -> Component:
    item = torus(
        name,
        major,
        minor,
        location,
        zone=zone,
        role=role,
        stage=stage,
        collection_name=collection_name,
    )
    item.obj.rotation_euler = Vector(direction).to_track_quat("Z", "Y").to_euler()
    return item


def text_relief(
    name: str,
    body: str,
    location: tuple[float, float, float],
    size: float,
    *,
    zone="silver",
    stage="costume",
) -> Component:
    bpy.ops.object.text_add(
        location=location,
        rotation=(math.pi / 2.0, 0.0, 0.0),
    )
    obj = bpy.context.active_object
    obj.name = name
    obj.data.body = body
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    obj.data.size = size
    obj.data.extrude = 0.8
    obj.data.bevel_depth = 0.15
    obj.data.space_character = 0.92
    bpy.ops.object.convert(target="MESH")
    obj.data.name = name
    move_to_collection(obj, COLLECTIONS["SCULPT_SOURCE"])
    return component(obj, zone, stage=stage)


def fur_lock(
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius: float,
    *,
    scale=(1.0, 0.78, 1.0),
    stage="final",
) -> list[Component]:
    pieces = capsule(name, radius, start, end, zone="fur", stage=stage)
    pieces[-1].obj.scale = scale
    return pieces


def add_source_part(name: str, pieces: list[Component]) -> list[Component]:
    for index, item in enumerate(pieces):
        item.obj["cobie_part"] = name
        item.obj["cobie_component_index"] = index
    active = [item for item in pieces if stage_at_least(item.stage)]
    SOURCE_PARTS[name] = active
    return active


def clone_components(
    pieces: list[Component],
    collection_name: str,
    prefix: str,
    *,
    materials: bool,
) -> list[Component]:
    clones: list[Component] = []
    destination = COLLECTIONS[collection_name]
    for index, item in enumerate(pieces):
        clone = item.obj.copy()
        clone.data = item.obj.data.copy()
        clone.name = f"{prefix}{index:03d}__{item.zone}__{item.obj.name}"
        clone.data.name = clone.name
        destination.objects.link(clone)
        if materials:
            clone.data.materials.clear()
            clone.data.materials.append(MATERIALS[item.zone])
        clone["cobie_zone"] = item.zone
        clone["cobie_role"] = item.role
        clone["cobie_stage"] = item.stage
        clone["cobie_source_name"] = item.obj.name
        clones.append(Component(clone, item.zone, item.role, item.stage))
    return clones


def remesh(obj: bpy.types.Object, voxel_size: float) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new("PrintVoxelRemesh", "REMESH")
    modifier.mode = "VOXEL"
    modifier.voxel_size = voxel_size
    modifier.use_smooth_shade = False
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-4)
    bpy.ops.mesh.dissolve_degenerate(threshold=1e-4)
    bpy.ops.mesh.delete_loose()
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")


def remove_tiny_shells(
    obj: bpy.types.Object,
    *,
    maximum_secondary_fraction: float = 0.005,
) -> None:
    """Remove only remesh/Boolean crumbs; reject a genuinely split part."""
    mesh = obj.data
    adjacency: list[list[int]] = [[] for _ in mesh.vertices]
    for edge in mesh.edges:
        left, right = edge.vertices
        adjacency[left].append(right)
        adjacency[right].append(left)
    remaining = set(range(len(mesh.vertices)))
    islands: list[set[int]] = []
    while remaining:
        root = remaining.pop()
        island = {root}
        stack = [root]
        while stack:
            current = stack.pop()
            for neighbour in adjacency[current]:
                if neighbour in remaining:
                    remaining.remove(neighbour)
                    island.add(neighbour)
                    stack.append(neighbour)
        islands.append(island)
    if len(islands) <= 1:
        return

    islands.sort(key=len, reverse=True)
    secondary_fraction = len(islands[1]) / max(len(islands[0]), 1)
    if secondary_fraction > maximum_secondary_fraction:
        raise RuntimeError(
            f"{obj.name}: Boolean/remesh produced a material secondary shell "
            f"({secondary_fraction:.2%} of the primary vertex count)"
        )
    retained = islands[0]
    retained_indices = sorted(retained)
    remap = {old: new for new, old in enumerate(retained_indices)}
    vertices = [tuple(mesh.vertices[index].co) for index in retained_indices]
    faces = [
        tuple(remap[index] for index in polygon.vertices)
        for polygon in mesh.polygons
        if all(index in retained for index in polygon.vertices)
    ]
    replacement = bpy.data.meshes.new(f"{obj.name}__largest_shell")
    replacement.from_pydata(vertices, [], faces)
    replacement.update()
    old_mesh = obj.data
    obj.data = replacement
    obj.data.name = obj.name
    bpy.data.meshes.remove(old_mesh)
    for polygon in obj.data.polygons:
        polygon.use_smooth = obj.name != "Base_Keyed"


def join_and_solidify(
    name: str,
    pieces: list[Component],
    voxel_size: float,
) -> bpy.types.Object:
    objects = [item.obj for item in pieces]
    if not objects:
        raise RuntimeError(f"{name}: no geometry to fuse")
    for obj in objects:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    target = objects[0]
    bpy.context.view_layer.objects.active = target
    if len(objects) > 1:
        bpy.ops.object.join()
    target.name = name
    target.data.name = name
    remesh(target, voxel_size)
    for polygon in target.data.polygons:
        polygon.use_smooth = name != "Base_Keyed"
    return target


def expanded_mating_cutter(
    source: bpy.types.Object,
    name: str,
    clearance: float,
    voxel_size: float,
) -> bpy.types.Object:
    cutter = source.copy()
    cutter.data = source.data.copy()
    cutter.name = name
    cutter.data.name = name
    COLLECTIONS["PRINT_EXPORT"].objects.link(cutter)
    bpy.ops.object.select_all(action="DESELECT")
    cutter.select_set(True)
    bpy.context.view_layer.objects.active = cutter
    modifier = cutter.modifiers.new("MatingClearance", "DISPLACE")
    modifier.direction = "NORMAL"
    modifier.mid_level = 0.0
    modifier.strength = clearance
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    remesh(cutter, min(voxel_size, max(0.12, clearance * 0.5)))
    return cutter


def cut_sockets(
    target: bpy.types.Object,
    cutters: list[bpy.types.Object],
    voxel_size: float,
) -> None:
    for cutter in cutters:
        bpy.ops.object.select_all(action="DESELECT")
        target.select_set(True)
        bpy.context.view_layer.objects.active = target
        modifier = target.modifiers.new(f"Socket_{cutter.name}", "BOOLEAN")
        modifier.operation = "DIFFERENCE"
        modifier.solver = "EXACT"
        modifier.object = cutter
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.data.objects.remove(cutter, do_unlink=True)
        if len(target.data.polygons) < 500:
            raise RuntimeError(
                f"socket Boolean collapsed {target.name} "
                f"to {len(target.data.polygons)} faces"
            )
    remesh(target, voxel_size)


def build_base_source() -> list[Component]:
    pieces = [
        cylinder(
            "SRC__base_disc",
            BASE_DIAMETER_MM / 2.0,
            BASE_THICKNESS_MM,
            (0.0, 0.0, BASE_THICKNESS_MM / 2.0),
            zone="base",
        )
    ]
    for index, (x, y, radius, height) in enumerate(BASE_PEG_SPECS):
        pieces.append(
            cylinder(
                f"SRC__base_key_{index}",
                radius,
                height,
                (x, y, BASE_TOP + height / 2.0 - 0.45),
                zone="base",
                role="registration",
            )
        )
    return add_source_part("Base_Keyed", pieces)


def build_body_source() -> list[Component]:
    pieces: list[Component] = []

    leg_specs = (
        (-1, -12.0, -2.0, -8.0, 52.5),
        (1, 13.0, 2.5, -2.0, 53.5),
    )
    for side, x, knee_y, paw_y, thigh_z in leg_specs:
        pieces.append(
            sphere(
                f"SRC__haunch_{side}",
                11.0,
                (x * 0.78, 2.0, thigh_z),
                scale=(1.05, 0.88, 1.0),
            )
        )
        pieces.extend(
            capsule(
                f"SRC__shin_{side}",
                6.2,
                (x * 0.88, knee_y, 45.5),
                (x, paw_y, 19.0),
            )
        )
        pieces.append(
            sphere(
                f"SRC__calf_lock_{side}",
                6.4,
                (x, paw_y + 1.5, 30.0),
                scale=(1.06, 0.92, 1.2),
            )
        )
        pieces.append(
            sphere(
                f"SRC__paw_{side}",
                7.8,
                (x, paw_y - 1.0, 11.4),
                scale=(1.2, 1.45, 0.75),
            )
        )
        for toe in (-1, 0, 1):
            pieces.append(
                sphere(
                    f"SRC__paw_toe_{side}_{toe}",
                    2.5,
                    (x + toe * 3.2, paw_y - 9.5, 8.7),
                    scale=(1.05, 1.15, 0.72),
                )
            )
        pieces.extend(
            fur_lock(
                f"SRC__leg_fur_{side}",
                (x - side * 2.0, paw_y - 4.0, 37.0),
                (x + side * 1.5, paw_y - 5.0, 31.0),
                2.1,
            )
        )

    # Keep the inherited asymmetric base-key centres unchanged.  These compact
    # sole housings sit inside the broader V2 paws and provide complete socket
    # walls through the validator's engagement bands.
    for index, (x, y, radius, _height) in enumerate(BASE_PEG_SPECS):
        pieces.append(
            cylinder(
                f"SRC__sole_socket_housing_{index}",
                radius + 3.8,
                8.0,
                (x, y, 9.5),
                zone="fur",
            )
        )

    pieces.append(
        sphere(
            "SRC__torso",
            20.0,
            (1.2, 1.5, 75.5),
            scale=(1.03, 0.78, 1.20),
        )
    )
    pieces.append(
        sphere(
            "SRC__jacket_core",
            19.0,
            (1.0, 2.5, 79.0),
            scale=(1.22, 0.82, 1.05),
            zone="leather",
        )
    )
    pieces.append(
        sphere(
            "SRC__chest_ruff",
            12.0,
            (0.0, -12.5, 84.0),
            scale=(1.05, 0.68, 1.12),
        )
    )
    chest_locks = (
        (-8.0, -18.0, 90.5, -5.0, -18.8, 85.5),
        (-1.0, -18.5, 92.0, 1.0, -19.0, 86.5),
        (7.0, -18.0, 90.0, 5.0, -18.8, 84.0),
        (-5.0, -18.0, 82.0, -2.0, -18.7, 77.5),
        (4.0, -18.0, 82.0, 2.0, -18.8, 77.0),
    )
    for index, values in enumerate(chest_locks):
        pieces.extend(
            fur_lock(
                f"SRC__chest_lock_{index}",
                values[:3],
                values[3:],
                2.5,
            )
        )

    for side in (-1, 1):
        pieces.append(
            sphere(
                f"SRC__shoulder_{side}",
                10.5,
                (side * 17.0 + 1.0, 0.0, 88.5),
                scale=(1.05, 0.82, 0.76),
                zone="leather",
            )
        )

    pieces.extend(
        [
            prism(
                "SRC__jacket_panel_left",
                [(-20.0, 91.5), (-9.0, 94.0), (-2.0, 81.0), (-6.0, 67.0), (-19.0, 70.0)],
                -13.2,
                4.0,
                zone="leather",
                stage="costume",
            ),
            prism(
                "SRC__jacket_panel_right",
                [(20.5, 91.5), (9.0, 94.0), (2.5, 81.0), (7.0, 67.0), (20.0, 71.0)],
                -13.0,
                4.0,
                zone="leather",
                stage="costume",
            ),
            prism(
                "SRC__lapel_left",
                [(-18.0, 94.0), (-8.0, 95.0), (-1.5, 82.0), (-8.0, 85.0), (-14.0, 79.0)],
                -16.0,
                2.6,
                zone="leather",
                stage="costume",
            ),
            prism(
                "SRC__lapel_right",
                [(18.0, 94.0), (8.0, 95.0), (1.5, 82.0), (9.0, 85.5), (15.0, 79.0)],
                -15.8,
                2.6,
                zone="leather",
                stage="costume",
            ),
            prism(
                "SRC__jacket_back_yoke",
                [(-18.0, 90.0), (18.0, 90.0), (15.0, 82.5), (-15.0, 82.5)],
                15.3,
                2.8,
                zone="leather",
                stage="costume",
            ),
        ]
    )
    pieces.extend(
        capsule(
            "SRC__asymmetric_zip",
            1.25,
            (7.0, -17.4, 89.0),
            (-4.0, -17.5, 69.0),
            zone="silver",
            stage="costume",
        )
    )
    for side in (-1, 1):
        for z in (88.5, 81.5):
            pieces.append(
                sphere(
                    f"SRC__jacket_snap_{side}_{z}",
                    1.45,
                    (side * 12.5, -17.5, z),
                    scale=(1.0, 0.72, 1.0),
                    zone="silver",
                    stage="costume",
                )
            )

    arm_paths = {
        -1: ((-17.0, -2.0, 87.5), (-20.0, -10.0, 77.0), (-8.0, -18.2, 73.5)),
        1: ((18.0, -1.0, 87.0), (21.0, -9.0, 75.0), (11.0, -18.0, 63.0)),
    }
    for side, (shoulder, elbow, hand) in arm_paths.items():
        pieces.extend(
            capsule(
                f"SRC__upper_arm_{side}",
                6.8,
                shoulder,
                elbow,
                zone="leather",
            )
        )
        pieces.extend(
            capsule(
                f"SRC__forearm_{side}",
                6.0,
                elbow,
                hand,
                zone="leather",
            )
        )
        cuff_start = Vector(elbow).lerp(Vector(hand), 0.72)
        cuff_end = Vector(elbow).lerp(Vector(hand), 0.88)
        pieces.extend(
            capsule(
                f"SRC__cuff_{side}",
                6.6,
                tuple(cuff_start),
                tuple(cuff_end),
                zone="leather",
                stage="costume",
            )
        )
        pieces.append(
            sphere(
                f"SRC__grip_paw_{side}",
                6.2,
                hand,
                scale=(1.05, 0.92, 1.0),
            )
        )
        for toe in (-1, 0, 1):
            pieces.append(
                sphere(
                    f"SRC__grip_toe_{side}_{toe}",
                    2.2,
                    (hand[0] + toe * 2.5, hand[1] - 3.8, hand[2] - 1.0),
                )
            )

    pieces.extend(
        capsule(
            "SRC__tail_root",
            5.0,
            (11.0, 10.0, 59.0),
            (20.0, 14.0, 67.0),
        )
    )
    pieces.extend(
        capsule(
            "SRC__tail_tip",
            4.6,
            (20.0, 14.0, 67.0),
            (17.0, 13.0, 76.0),
        )
    )
    pieces.extend(
        fur_lock(
            "SRC__tail_lock",
            (19.5, 11.5, 72.0),
            (16.0, 10.5, 77.0),
            2.3,
        )
    )

    pieces.append(
        cylinder(
            "SRC__neck",
            9.5,
            14.0,
            (0.0, -0.5, 98.0),
        )
    )
    for index, (x, y, radius, height) in enumerate(HEAD_KEY_SPECS):
        pieces.append(
            cylinder(
                f"SRC__head_key_{index}",
                radius,
                height,
                (x, y, 104.0 + height / 2.0),
                role="registration",
            )
        )

    pieces.append(
        torus(
            "SRC__collar_chain",
            11.5,
            1.8,
            (0.0, -0.5, 95.0),
            zone="silver",
            stage="costume",
        )
    )
    pieces.append(
        cube(
            "SRC__dog_tag",
            (12.0, 2.8, 10.0),
            (0.0, -17.0, 88.5),
            zone="silver",
            stage="costume",
        )
    )
    pieces.append(
        text_relief(
            "SRC__dog_tag_text",
            "COBIE",
            (0.0, -18.55, 88.5),
            3.2,
            zone="tag_text",
        )
    )
    return add_source_part("Cobie_Body", pieces)


def build_head_source() -> list[Component]:
    pieces: list[Component] = [
        sphere(
            "SRC__skull",
            HEAD_RADIUS,
            (0.0, 0.0, HEAD_CENTRE_Z),
            scale=(1.06, 0.96, 1.0),
        ),
        sphere(
            "SRC__forehead_bridge",
            7.0,
            (0.0, -11.5, 121.5),
            scale=(0.72, 1.05, 1.18),
            stage="head",
        ),
        sphere(
            "SRC__cheek_left",
            8.4,
            (-7.0, -12.5, 112.0),
            scale=(1.0, 0.92, 0.88),
            stage="head",
        ),
        sphere(
            "SRC__cheek_right",
            8.4,
            (7.0, -12.5, 112.0),
            scale=(1.0, 0.92, 0.88),
            stage="head",
        ),
        sphere(
            "SRC__muzzle_left",
            7.5,
            (-4.6, -16.6, 112.0),
            scale=(1.05, 0.86, 0.72),
        ),
        sphere(
            "SRC__muzzle_right",
            7.5,
            (4.6, -16.6, 112.0),
            scale=(1.05, 0.86, 0.72),
        ),
        sphere(
            "SRC__lower_jaw",
            7.2,
            (0.0, -14.7, 105.5),
            scale=(1.18, 0.82, 0.88),
            stage="head",
        ),
        sphere(
            "SRC__nose",
            4.7,
            (0.0, -22.0, 113.6),
            scale=(1.2, 0.74, 0.78),
            zone="nose",
        ),
        cylinder(
            "SRC__head_neck_collar",
            12.5,
            5.0,
            (0.0, -0.5, 103.5),
        ),
    ]

    crown_curls = (
        (-12.0, -1.0, 131.0, 4.8),
        (-7.0, 1.0, 134.0, 5.0),
        (-1.5, 0.0, 135.0, 4.8),
        (4.0, 1.0, 134.5, 4.8),
        (9.5, -0.5, 132.5, 4.8),
        (-9.5, -7.0, 129.0, 4.2),
        (-3.0, -8.5, 131.0, 4.2),
        (4.0, -8.0, 130.5, 4.2),
        (10.0, -6.0, 128.5, 4.2),
    )
    for index, (x, y, z, radius) in enumerate(crown_curls):
        pieces.append(
            sphere(
                f"SRC__crown_curl_{index}",
                radius,
                (x, y, z),
                scale=(1.0, 0.85, 1.0),
            )
        )
    crown_locks = (
        ((-10.0, -8.0, 132.0), (-6.0, -9.5, 136.0)),
        ((-3.0, -9.0, 133.0), (0.0, -10.0, 137.0)),
        ((4.0, -8.5, 132.0), (8.0, -9.0, 135.5)),
    )
    for index, (start, end) in enumerate(crown_locks):
        pieces.extend(
            fur_lock(
                f"SRC__crown_lock_{index}",
                start,
                end,
                2.2,
                stage="head",
            )
        )

    muzzle_locks = (
        ((-9.0, -18.0, 113.0), (-6.0, -20.0, 109.0)),
        ((-4.0, -18.5, 108.5), (-1.0, -19.5, 104.5)),
        ((4.0, -18.5, 108.5), (1.0, -19.5, 104.5)),
        ((9.0, -18.0, 113.0), (6.0, -20.0, 109.0)),
    )
    for index, (start, end) in enumerate(muzzle_locks):
        pieces.extend(
            fur_lock(
                f"SRC__muzzle_lock_{index}",
                start,
                end,
                2.2,
                stage="head",
            )
        )

    pieces.extend(
        capsule(
            "SRC__mouth_left",
            1.15,
            (-5.5, -20.0, 108.5),
            (0.0, -20.8, 107.8),
            zone="mouth",
            stage="head",
        )
    )
    pieces.extend(
        capsule(
            "SRC__mouth_right",
            1.15,
            (0.0, -20.8, 107.8),
            (5.5, -20.0, 108.5),
            zone="mouth",
            stage="head",
        )
    )

    for side in (-1, 1):
        pieces.extend(
            capsule(
                f"SRC__ear_core_{side}",
                8.0,
                (side * 14.0, 0.5, 123.0),
                (side * 17.0, 0.0, 105.5),
            )
        )
        ear_lobes = (
            (side * 19.0, -4.0, 123.0, 4.4),
            (side * 21.0, -2.0, 117.0, 4.7),
            (side * 21.0, -4.0, 111.0, 4.7),
            (side * 19.0, -2.0, 105.0, 4.5),
        )
        for index, (x, y, z, radius) in enumerate(ear_lobes):
            pieces.append(
                sphere(
                    f"SRC__ear_lobe_{side}_{index}",
                    radius,
                    (x, y, z),
                    scale=(0.9, 1.0, 1.0),
                )
            )
        pieces.extend(
            fur_lock(
                f"SRC__ear_lock_upper_{side}",
                (side * 18.0, -7.0, 122.0),
                (side * 21.0, -7.5, 116.0),
                2.1,
                stage="head",
            )
        )
        pieces.extend(
            fur_lock(
                f"SRC__ear_lock_lower_{side}",
                (side * 21.0, -6.0, 112.0),
                (side * 18.0, -6.5, 105.0),
                2.1,
                stage="head",
            )
        )
    return add_source_part("Cobie_Head", pieces)


def build_sunglasses_source() -> list[Component]:
    thickness = max(SUNGLASSES_ARM_MM, 1.8)
    lens_z = 121.0
    pieces: list[Component] = [
        cube(
            "SRC__aviator_top_bridge",
            (8.0, thickness, 1.8),
            (0.0, -20.7, lens_z + 3.0),
            zone="brass",
        ),
        cube(
            "SRC__aviator_lower_bridge",
            (5.0, thickness, 1.5),
            (0.0, -20.8, lens_z + 0.5),
            zone="brass",
        ),
    ]
    outlines: list[list[tuple[float, float]]] = []
    base_outline = (
        (-6.6, 3.8),
        (4.8, 3.8),
        (6.4, 1.4),
        (4.2, -4.6),
        (0.8, -6.2),
        (-4.8, -4.8),
        (-6.6, -1.0),
    )
    for side in (-1, 1):
        centre_x = side * 7.8
        points = [(centre_x + side * x, lens_z + z) for x, z in base_outline]
        outlines.append(points)
        pieces.append(
            prism(
                f"SRC__aviator_lens_{side}",
                points,
                -20.6,
                thickness,
                zone="lens",
            )
        )
        for index in range(len(points)):
            start_x, start_z = points[index]
            end_x, end_z = points[(index + 1) % len(points)]
            pieces.extend(
                capsule(
                    f"SRC__aviator_rim_{side}_{index}",
                    1.0,
                    (start_x, -21.6, start_z),
                    (end_x, -21.6, end_z),
                    zone="brass",
                    stage="costume",
                )
            )
        pieces.extend(
            capsule(
                f"SRC__aviator_arm_{side}",
                1.15,
                (side * 14.2, -19.8, lens_z + 2.2),
                (side * 12.0, -8.5, 121.5),
                zone="brass",
            )
        )
        pieces.append(
            sphere(
                f"SRC__aviator_hinge_{side}",
                1.65,
                (side * 14.0, -20.2, lens_z + 2.1),
                zone="brass",
                stage="costume",
            )
        )
    for index, (x, y, z, radius, depth) in enumerate(GLASSES_PIN_SPECS):
        pieces.append(
            cylinder(
                f"SRC__glasses_pin_{index}",
                radius,
                depth,
                (x, y, z),
                rotation=(math.pi / 2.0, 0.0, 0.0),
                zone="brass",
                role="registration",
            )
        )
    return add_source_part("Cobie_Sunglasses", pieces)


def launcher_components(
    prefix: str,
    *,
    clearance: float = 0.0,
    include_pins: bool,
    collection_name="SCULPT_SOURCE",
) -> list[Component]:
    c = clearance
    angle = PROP_ROLL_RADIANS
    pieces: list[Component] = [
        cube(
            f"{prefix}__receiver_core",
            (22.0 + 2 * c, 14.0 + 2 * c, 16.0 + 2 * c),
            (-5.0, -20.0, 70.0),
            rotation=(0.0, angle, 0.0),
            zone="gunmetal",
            collection_name=collection_name,
        ),
        cube(
            f"{prefix}__receiver_step",
            (13.0 + 2 * c, 15.0 + 2 * c, 10.0 + 2 * c),
            (-13.0, -19.8, 71.5),
            rotation=(0.0, angle, 0.0),
            zone="dark_metal",
            stage="launcher",
            collection_name=collection_name,
        ),
        cylinder(
            f"{prefix}__drum",
            8.8 + c,
            9.0 + 2 * c,
            (-7.0, -22.0, 70.5),
            rotation=(math.pi / 2.0, 0.0, 0.0),
            zone="hazard",
            stage="launcher",
            collection_name=collection_name,
        ),
        sphere(
            f"{prefix}__loaded_ball",
            5.8 + c,
            (-7.0, -27.0, 73.5),
            zone="tennis",
            stage="launcher",
            collection_name=collection_name,
        ),
        cylinder_between(
            f"{prefix}__barrel",
            5.5 + c,
            (2.0, -20.0, 68.0),
            (30.0, -20.0, 61.8),
            zone="dark_metal",
            collection_name=collection_name,
        ),
        cylinder_between(
            f"{prefix}__underbarrel",
            2.7 + c,
            (7.0, -19.8, 61.5),
            (24.0, -19.8, 57.7),
            zone="gunmetal",
            stage="launcher",
            collection_name=collection_name,
        ),
        cylinder_between(
            f"{prefix}__muzzle",
            7.2 + c,
            (28.5, -20.0, 62.2),
            (34.0, -20.0, 61.0),
            zone="gunmetal",
            collection_name=collection_name,
        ),
    ]

    direction = (1.0, 0.0, -math.tan(angle))
    for index, (x, z) in enumerate(((5.0, 67.3), (13.0, 65.5), (21.0, 63.8))):
        pieces.append(
            oriented_torus(
                f"{prefix}__cage_{index}",
                6.6,
                1.35 + c,
                (x, -20.0, z),
                direction,
                zone="gunmetal",
                stage="launcher",
                collection_name=collection_name,
            )
        )
    pieces.append(
        oriented_torus(
            f"{prefix}__charge_ring",
            7.0,
            1.55 + c,
            (27.0, -20.0, 62.5),
            direction,
            zone="cyan",
            stage="launcher",
            collection_name=collection_name,
        )
    )
    pieces.extend(
        capsule(
            f"{prefix}__carry_handle",
            2.5 + c,
            (-13.0, -20.0, 80.5),
            (2.0, -20.0, 77.2),
            zone="gunmetal",
            stage="launcher",
            collection_name=collection_name,
        )
    )
    pieces.extend(
        capsule(
            f"{prefix}__grip",
            4.1 + c,
            (-10.0, -18.0, 64.0),
            (-13.0, -16.0, 54.0),
            zone="dark_metal",
            collection_name=collection_name,
        )
    )
    pieces.extend(
        capsule(
            f"{prefix}__spine",
            3.2 + c,
            (-12.0, -20.0, 70.5),
            (31.0, -20.0, 61.0),
            zone="gunmetal",
            collection_name=collection_name,
        )
    )
    pieces.extend(
        capsule(
            f"{prefix}__trigger_guard",
            2.0 + c,
            (-4.0, -20.0, 62.0),
            (1.5, -20.0, 60.5),
            zone="gunmetal",
            stage="launcher",
            collection_name=collection_name,
        )
    )

    pieces.extend(
        [
            cube(
                f"{prefix}__hazard_panel",
                (11.0 + 2 * c, 1.8 + 2 * c, 6.0 + 2 * c),
                (-4.0, -27.4, 70.2),
                rotation=(0.0, angle, 0.0),
                zone="hazard",
                stage="launcher",
                collection_name=collection_name,
            ),
            cube(
                f"{prefix}__charge_meter",
                (3.0 + 2 * c, 2.0 + 2 * c, 8.0 + 2 * c),
                (0.5, -27.2, 71.2),
                rotation=(0.0, angle, 0.0),
                zone="cyan",
                stage="launcher",
                collection_name=collection_name,
            ),
            sphere(
                f"{prefix}__paw_badge",
                2.4 + c,
                (-7.5, -28.0, 70.0),
                scale=(1.0, 0.72, 1.0),
                zone="hazard",
                stage="launcher",
                collection_name=collection_name,
            ),
        ]
    )
    for index, (x, z) in enumerate(((-9.2, 72.2), (-8.0, 73.0), (-6.7, 72.8), (-5.6, 71.6))):
        pieces.append(
            sphere(
                f"{prefix}__paw_toe_{index}",
                1.25 + c,
                (x, -28.3, z),
                scale=(1.0, 0.72, 1.0),
                zone="hazard",
                stage="launcher",
                collection_name=collection_name,
            )
        )

    if include_pins:
        for index, (x, y, z, radius, depth) in enumerate(PROP_PIN_SPECS):
            pieces.append(
                cylinder(
                    f"{prefix}__pin_{index}",
                    radius,
                    depth,
                    (x, y, z),
                    rotation=(math.pi / 2.0, 0.0, 0.0),
                    zone="gunmetal",
                    role="registration",
                    collection_name=collection_name,
                )
            )
    return pieces


def build_prop_source() -> list[Component]:
    if not FETCH_LAUNCHER_SOURCE.is_file():
        raise FileNotFoundError(
            f"project-owned Fetch Launcher source is missing: {FETCH_LAUNCHER_SOURCE}"
        )
    return add_source_part(
        "Cobie_Prop_FetchLauncher",
        launcher_components("SRC__launcher", include_pins=True),
    )


def material(
    name: str,
    rgba: tuple[float, float, float, float],
    roughness: float,
    metallic: float = 0.0,
) -> bpy.types.Material:
    item = bpy.data.materials.new(name)
    item.use_nodes = True
    item.diffuse_color = rgba
    principled = item.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        principled.inputs["Base Color"].default_value = rgba
        principled.inputs["Roughness"].default_value = roughness
        principled.inputs["Metallic"].default_value = metallic
    return item


def create_materials() -> None:
    MATERIALS.clear()
    MATERIALS.update(
        {
            "fur": material("Cobie_Fur_GoldenHoney", (0.57, 0.25, 0.07, 1.0), 0.72),
            "leather": material("Cobie_Leather_NearBlack", (0.018, 0.022, 0.027, 1.0), 0.30),
            "silver": material("Cobie_Hardware_AgedSilver", (0.38, 0.42, 0.46, 1.0), 0.30, 0.75),
            "tag_text": material("Cobie_Tag_Recess", (0.055, 0.060, 0.065, 1.0), 0.48, 0.35),
            "nose": material("Cobie_Nose_GlossBlack", (0.006, 0.008, 0.010, 1.0), 0.16),
            "mouth": material("Cobie_Mouth_DarkBrown", (0.035, 0.012, 0.008, 1.0), 0.55),
            "lens": material("Cobie_Aviator_SmokedLens", (0.015, 0.020, 0.025, 1.0), 0.12, 0.25),
            "brass": material("Cobie_Aviator_WarmBrass", (0.48, 0.23, 0.045, 1.0), 0.26, 0.82),
            "gunmetal": material("FetchLauncher_Gunmetal", (0.075, 0.085, 0.10, 1.0), 0.34, 0.72),
            "dark_metal": material("FetchLauncher_BlackSteel", (0.018, 0.024, 0.032, 1.0), 0.31, 0.58),
            "hazard": material("FetchLauncher_HazardGold", (0.70, 0.30, 0.015, 1.0), 0.38, 0.30),
            "tennis": material("FetchLauncher_TennisBall", (0.48, 0.68, 0.035, 1.0), 0.76),
            "cyan": material("FetchLauncher_ChargeCyan", (0.00, 0.42, 0.60, 1.0), 0.23, 0.20),
            "base": material("Cobie_Base_Charcoal", (0.035, 0.045, 0.055, 1.0), 0.82),
        }
    )


def build_lookdev() -> None:
    for part_name in PART_NAMES:
        clones = clone_components(
            SOURCE_PARTS[part_name],
            "LOOKDEV",
            f"LOOK__{part_name}__",
            materials=True,
        )
        for item in clones:
            item.obj["cobie_part"] = part_name


def print_component_clones(
    part_name: str,
    *,
    include_roles: set[str] | None = None,
) -> list[Component]:
    pieces = SOURCE_PARTS[part_name]
    if include_roles is not None:
        pieces = [item for item in pieces if item.role in include_roles]
    return clone_components(
        pieces,
        "PRINT_EXPORT",
        f"TMP__{part_name}__",
        materials=False,
    )


def print_object_from_source(
    part_name: str,
    voxel_size: float,
) -> bpy.types.Object:
    return join_and_solidify(
        part_name,
        print_component_clones(part_name),
        voxel_size,
    )


def cutter_cylinder(
    name: str,
    radius: float,
    depth: float,
    location,
    *,
    rotation=(0.0, 0.0, 0.0),
) -> bpy.types.Object:
    return cylinder(
        name,
        radius,
        depth,
        location,
        rotation=rotation,
        zone="base",
        collection_name="PRINT_EXPORT",
    ).obj


def cut_head_assembly_sockets(
    head: bpy.types.Object,
    glasses: bpy.types.Object,
) -> None:
    cutters = [
        cutter_cylinder(
            "TMP__neck_recess",
            NECK_RADIUS_MM + NECK_SOCKET_CLEARANCE_MM,
            NECK_DEPTH_MM + 3.0,
            NECK_CENTRE,
        ),
        expanded_mating_cutter(
            glasses,
            "TMP__glasses_mating_envelope",
            GLASSES_ENVELOPE_CLEARANCE_MM,
            REMESH_DETAIL_MM,
        ),
    ]
    for index, (x, y, radius, _height) in enumerate(HEAD_KEY_SPECS):
        cutters.append(
            cutter_cylinder(
                f"TMP__head_socket_{index}",
                radius + HEAD_SOCKET_CLEARANCES_MM[index],
                13.0,
                (x, y, 109.5),
            )
        )
    cut_sockets(head, cutters, REMESH_DETAIL_MM)


def build_launcher_mating_envelope() -> bpy.types.Object:
    exterior = [
        item
        for item in SOURCE_PARTS["Cobie_Prop_FetchLauncher"]
        if item.role != "registration"
    ]
    fused = join_and_solidify(
        "TMP__launcher_bulk",
        clone_components(
            exterior,
            "PRINT_EXPORT",
            "TMP__launcher_bulk__",
            materials=False,
        ),
        REMESH_PROP_MM,
    )
    expanded = expanded_mating_cutter(
        fused,
        "TMP__launcher_mating_envelope",
        PROP_BULK_CLEARANCE_MM,
        REMESH_PROP_MM,
    )
    bpy.data.objects.remove(fused, do_unlink=True)
    return expanded


def cut_body_assembly_sockets(body: bpy.types.Object) -> None:
    cutters: list[bpy.types.Object] = []
    for index, (x, y, radius, height) in enumerate(BASE_PEG_SPECS):
        cutters.append(
            cutter_cylinder(
                f"TMP__base_socket_{index}",
                radius + BASE_SOCKET_CLEARANCES_MM[index],
                height + 1.5,
                (x, y, BASE_TOP + height / 2.0 - 0.2),
            )
        )
    cutters.append(build_launcher_mating_envelope())
    for index, (x, y, z, radius, depth) in enumerate(PROP_PIN_SPECS):
        cutters.append(
            cutter_cylinder(
                f"TMP__launcher_socket_{index}",
                radius + PROP_SOCKET_CLEARANCES_MM[index],
                depth + 2.0,
                (x, y + 0.5, z),
                rotation=(math.pi / 2.0, 0.0, 0.0),
            )
        )
    cut_sockets(body, cutters, REMESH_BODY_MM)


def build_print_export() -> list[bpy.types.Object]:
    body = print_object_from_source("Cobie_Body", REMESH_BODY_MM)
    head = print_object_from_source("Cobie_Head", REMESH_HEAD_MM)
    glasses = print_object_from_source("Cobie_Sunglasses", REMESH_DETAIL_MM)
    prop = print_object_from_source("Cobie_Prop_FetchLauncher", REMESH_PROP_MM)
    base = print_object_from_source("Base_Keyed", REMESH_BODY_MM)
    cut_head_assembly_sockets(head, glasses)
    cut_body_assembly_sockets(body)
    parts = [body, head, glasses, prop, base]
    for part in parts:
        remove_tiny_shells(part)
    observed = {obj.name for obj in COLLECTIONS["PRINT_EXPORT"].objects if obj.type == "MESH"}
    if observed != set(PART_NAMES):
        raise RuntimeError(
            "PRINT_EXPORT must contain exactly the five canonical meshes; "
            f"observed={sorted(observed)}"
        )
    return parts


def create_reference() -> None:
    reference_specs = (
        (
            "REF_PrimaryCover",
            COVER_REFERENCE,
            "geometry_pose_identity_direction",
        ),
        (
            "REF_SecondaryCover",
            SECONDARY_COVER_REFERENCE,
            "fur_leather_material_hardsurface_direction_only",
        ),
    )
    for index, (name, source, role) in enumerate(reference_specs):
        if not source.is_file():
            raise FileNotFoundError(f"cover reference is missing: {source}")
        marker = bpy.data.objects.new(name, None)
        marker.empty_display_type = "IMAGE"
        marker.empty_display_size = 20.0
        marker.location = (index * 24.0, 38.0, 78.0)
        marker.hide_render = True
        marker["source_path"] = str(source.relative_to(ROOT))
        marker["source_sha256"] = sha256_file(source)
        marker["role"] = role
        marker["embedded_pixels"] = False
        COLLECTIONS["REFERENCE"].objects.link(marker)


def create_review_rig() -> None:
    floor = cube(
        "REVIEW__Floor",
        (180.0, 180.0, 0.5),
        (0.0, 0.0, -0.5),
        zone="base",
        collection_name="REVIEW_RIG",
    ).obj
    floor.data.materials.append(MATERIALS["base"])

    camera_data = bpy.data.cameras.new("REVIEW__Camera")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 170.0
    camera = bpy.data.objects.new("REVIEW__Camera", camera_data)
    COLLECTIONS["REVIEW_RIG"].objects.link(camera)
    camera.location = (0.0, -360.0, 82.0)
    camera.rotation_euler = (
        Vector((0.0, 0.0, 70.0)) - camera.location
    ).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = camera

    light_specs = (
        ("REVIEW__Key", (-105.0, -145.0, 205.0), 3.8, 0.16),
        ("REVIEW__Fill", (130.0, -95.0, 120.0), 1.45, 0.32),
        ("REVIEW__Rim", (40.0, 130.0, 185.0), 2.35, 0.22),
    )
    for name, location, energy, angle in light_specs:
        data = bpy.data.lights.new(name, "SUN")
        data.energy = energy
        data.angle = angle
        obj = bpy.data.objects.new(name, data)
        COLLECTIONS["REVIEW_RIG"].objects.link(obj)
        obj.location = location
        obj.rotation_euler = (
            Vector((0.0, 0.0, 70.0)) - obj.location
        ).to_track_quat("-Z", "Y").to_euler()

    world = bpy.data.worlds.new("REVIEW__World")
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    if background is not None:
        background.inputs["Color"].default_value = (0.012, 0.018, 0.026, 1.0)
        background.inputs["Strength"].default_value = 0.28
    bpy.context.scene.world = world


def configure_collection_visibility() -> None:
    COLLECTIONS["REFERENCE"].hide_render = True
    COLLECTIONS["SCULPT_SOURCE"].hide_render = True
    COLLECTIONS["SCULPT_SOURCE"].hide_viewport = True
    COLLECTIONS["LOOKDEV"].hide_render = False
    COLLECTIONS["LOOKDEV"].hide_viewport = False
    COLLECTIONS["PRINT_EXPORT"].hide_render = True
    COLLECTIONS["PRINT_EXPORT"].hide_viewport = True
    COLLECTIONS["REVIEW_RIG"].hide_render = False


def stamp_provenance() -> None:
    scene = bpy.context.scene
    scene["cobie_pipeline_version"] = PIPELINE_VERSION
    scene["cobie_asset_id"] = ASSET_ID
    scene["category"] = "physical_collectible"
    scene["scale_contract"] = SCALE_CONTRACT
    scene["units"] = "millimetres"
    scene["forward_axis"] = "-Y"
    scene["up_axis"] = "+Z"
    scene["build_mode"] = MODE
    scene["refinement_stage"] = ACTIVE_STAGE
    scene["identity_approved"] = False
    scene["physical_validation_complete"] = False
    scene["physical_prototype_approved"] = False
    scene["manufacture_authorized"] = False
    scene["license"] = "Project-original procedural Blender construction"
    scene["assembly_clearance_target_mm"] = "0.20-0.35 measured on exported STL"
    scene["cover_geometry_reference"] = str(COVER_REFERENCE.relative_to(ROOT))
    scene["cover_geometry_reference_sha256"] = sha256_file(COVER_REFERENCE)
    scene["secondary_cover_reference"] = str(
        SECONDARY_COVER_REFERENCE.relative_to(ROOT)
    )
    scene["secondary_cover_reference_sha256"] = sha256_file(
        SECONDARY_COVER_REFERENCE
    )
    scene["hero_prop_visual_reference"] = str(FETCH_LAUNCHER_SOURCE.relative_to(ROOT))
    scene["hero_prop_visual_reference_sha256"] = sha256_file(FETCH_LAUNCHER_SOURCE)
    scene["top_level_collection_contract"] = ",".join(TOP_LEVEL_COLLECTIONS)


def export_parts(
    parts: list[bpy.types.Object],
    destination: Path,
) -> list[Path]:
    destination.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    export_collection = COLLECTIONS["PRINT_EXPORT"]
    was_hidden = export_collection.hide_viewport
    was_render_hidden = export_collection.hide_render
    export_collection.hide_viewport = False
    export_collection.hide_render = False
    bpy.context.view_layer.update()
    try:
        for part in parts:
            if len(part.data.polygons) == 0:
                raise RuntimeError(f"{part.name}: fused print mesh has no polygons")
            bpy.ops.object.select_all(action="DESELECT")
            part.hide_set(False)
            part.hide_viewport = False
            part.hide_render = False
            part.select_set(True)
            bpy.context.view_layer.objects.active = part
            path = destination / f"{part.name}.stl"
            bpy.ops.wm.stl_export(
                filepath=str(path),
                export_selected_objects=True,
                global_scale=1.0,
                apply_modifiers=True,
                evaluation_mode="DAG_EVAL_VIEWPORT",
            )
            raw = path.read_bytes()
            triangle_count = (
                struct.unpack("<I", raw[80:84])[0] if len(raw) >= 84 else 0
            )
            if triangle_count == 0:
                raise RuntimeError(
                    f"{part.name}: STL export contains zero triangles"
                )
            written.append(path)
    finally:
        export_collection.hide_viewport = was_hidden
        export_collection.hide_render = was_render_hidden
        bpy.context.view_layer.update()
    return written


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def write_build_report(
    status: str,
    detail: str = "",
    *,
    written: list[Path] | None = None,
) -> None:
    payload: dict = {
        "status": status,
        "mode": MODE,
        "refinement_stage": ACTIVE_STAGE,
        "pipeline_version": PIPELINE_VERSION,
        "detail": detail,
        "selected_candidate_sha256": None,
        "identity_approved": False,
        "physical_validation_complete": False,
        "source_blend": display_path(BLEND_PATH) if BLEND_PATH.is_file() else None,
        "source_blend_sha256": sha256_file(BLEND_PATH) if BLEND_PATH.is_file() else None,
        "generator": {
            "path": display_path(Path(__file__).resolve()),
            "sha256": sha256_file(Path(__file__).resolve()),
        },
        "exports": {},
    }
    if written:
        payload["exports"] = {path.name: sha256_file(path) for path in written}
    write_json(BUILD_REPORT_PATH, payload)


def publish_exports(staged: list[Path]) -> list[Path]:
    expected = {f"{name}.stl" for name in PART_NAMES}
    observed = {path.name for path in staged if path.is_file()}
    if observed != expected:
        raise RuntimeError(
            f"staged export inventory mismatch: expected={sorted(expected)} "
            f"observed={sorted(observed)}"
        )
    EXPORT_DESTINATION.mkdir(parents=True, exist_ok=True)
    published: list[Path] = []
    with tempfile.TemporaryDirectory(
        prefix=".cobie-v2-backup-",
        dir=EXPORT_DESTINATION,
    ) as raw_backup:
        backup = Path(raw_backup)
        previous = [
            path
            for path in EXPORT_DESTINATION.iterdir()
            if path.is_file() and path.suffix.lower() == ".stl"
        ]
        backed_up: list[tuple[Path, Path]] = []
        try:
            for path in previous:
                backup_path = backup / path.name
                os.replace(path, backup_path)
                backed_up.append((backup_path, path))
            for source in staged:
                destination = EXPORT_DESTINATION / source.name
                os.replace(source, destination)
                published.append(destination)
        except Exception:
            for path in published:
                path.unlink(missing_ok=True)
            for backup_path, original in backed_up:
                if backup_path.exists():
                    os.replace(backup_path, original)
            raise
    for report_path in (
        EXPORT_DESTINATION / "print_check_report.json",
        SLICER_REPORT_PATH,
    ):
        report_path.unlink(missing_ok=True)
    return published


def validate_collection_contract() -> None:
    observed = tuple(collection.name for collection in bpy.context.scene.collection.children)
    if observed != TOP_LEVEL_COLLECTIONS:
        raise RuntimeError(
            f"top-level collection contract drift: expected={TOP_LEVEL_COLLECTIONS} "
            f"observed={observed}"
        )
    print_meshes = {
        obj.name
        for obj in COLLECTIONS["PRINT_EXPORT"].objects
        if obj.type == "MESH"
    }
    if print_meshes != set(PART_NAMES):
        raise RuntimeError(
            f"PRINT_EXPORT contract drift: observed={sorted(print_meshes)}"
        )


def build_and_publish() -> int:
    reset_scene()
    create_materials()
    create_reference()
    build_body_source()
    build_head_source()
    build_sunglasses_source()
    build_prop_source()
    build_base_source()
    build_lookdev()
    parts = build_print_export()
    create_review_rig()
    configure_collection_visibility()
    stamp_provenance()
    validate_collection_contract()

    BLEND_PATH.parent.mkdir(parents=True, exist_ok=True)
    EXPORT_DESTINATION.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix=".cobie-v2-export-",
        dir=EXPORT_DESTINATION,
    ) as raw_staging:
        staged = export_parts(parts, Path(raw_staging))
        write_build_report("BUILDING", "publishing V2 canonical export set")
        bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
        written = publish_exports(staged)
    write_build_report("PASS", written=written)

    for path in written:
        print(f"  exported {path.name} ({path.stat().st_size // 1024} KB)")
    print(f"  master: {display_path(BLEND_PATH)}")
    print(f"  refinement stage: {ACTIVE_STAGE}")
    print("  identity approval: OPEN")
    print("  physical validation: OPEN")
    print("COBIE_FIGURINE_V2_BUILD: PASS")
    return 0


def main() -> int:
    try:
        return build_and_publish()
    except Exception as exc:
        write_build_report("FAIL", str(exc))
        print(f"  FAIL [build] {exc}")
        print("  Previously published STLs were not replaced.")
        print("COBIE_FIGURINE_V2_BUILD: FAIL")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
