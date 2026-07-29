#!/usr/bin/env python3
"""Phase 3: build the printable Cobie figurine and export per-part STL.

Run:
    uv run --project cobie-collectible/tools \
        python cobie-collectible/scripts/build_figurine.py

Two modes, chosen automatically:

  * If cobie-collectible/generated-meshes/selected.glb exists, it is imported
    and normalised for a supervised Blender review. The command then FAILS
    closed until a human has separated, posed and keyed the required parts.
    A single generated shell is never represented as a printable assembly.

  * Otherwise a game-art-grounded PROVISIONAL DIGITAL PROTOTYPE is built from
    authored primitives guided by the project-owned Fetch Launcher GLB. It is
    not identity-approved and must not be sent to manufacture. It exists to
    make the pose, silhouette, keys, print rules, exports and review renders
    concrete before the owner photo/turnaround gate closes.

House conventions from tools/blender/*.py: no argparse, module-level path
constants, factory reset, provenance stamped as scene custom properties, zero
RNG, and a greppable PASS sentinel.
"""

from __future__ import annotations

import math
import os
import sys
import tempfile
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    BASE_PEG_SPECS,
    BASE_DIAMETER_MM,
    BASE_THICKNESS_MM,
    BLEND_DIR,
    BUILD_REPORT,
    EXPORTS,
    FIGURE_HEIGHT_MM,
    FIGURINE_BLEND,
    GENERATED_MESHES,
    GLASSES_PIN_SPECS,
    HEAD_KEY_SPECS,
    NECK_CENTRE,
    NECK_DEPTH_MM,
    NECK_RADIUS_MM,
    PART_NAMES,
    PIPELINE_VERSION,
    ROOT,
    SCALE_CONTRACT,
    PROP_PIN_SPECS,
    SLICER_TESTS,
    SUNGLASSES_ARM_MM,
    UNIT_SCALE_LENGTH,
    sha256_file,
    write_json,
)

SELECTED_MESH = GENERATED_MESHES / "selected.glb"
BLEND_PATH = FIGURINE_BLEND
REVIEW_BLEND_PATH = BLEND_DIR / "cobie_figurine_v1_reviewed.blend"
FETCH_LAUNCHER_SOURCE = ROOT / "assets" / "models" / "weapons" / "fetch_launcher_viewmodel.glb"

# Voxel remesh fuses overlapping primitives into one watertight, correctly
# wound body. Doing it per part is what makes print_check's watertight,
# winding and floating-shell checks pass by construction instead of by luck.
REMESH_BODY_MM = 0.6
REMESH_DETAIL_MM = 0.3
REMESH_PROP_MM = 0.4


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for collection in (bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.meshes):
        for block in list(collection):
            collection.remove(block)

    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = UNIT_SCALE_LENGTH
    scene.unit_settings.length_unit = "MILLIMETERS"


def stamp_provenance(mode: str) -> None:
    scene = bpy.context.scene
    scene["cobie_pipeline_version"] = PIPELINE_VERSION
    scene["cobie_asset_id"] = "cobie_figurine_v1"
    scene["category"] = "physical_collectible"
    scene["scale_contract"] = SCALE_CONTRACT
    scene["units"] = "millimetres"
    scene["forward_axis"] = "-Y"
    scene["up_axis"] = "+Z"
    scene["build_mode"] = mode
    scene["license"] = "Project-original; Blender primitives or project-owned generated derivative"
    scene["assembly_clearance_target_mm"] = "0.20-0.35 measured on exported STL"
    if FETCH_LAUNCHER_SOURCE.is_file():
        scene["hero_prop_visual_reference"] = str(FETCH_LAUNCHER_SOURCE.relative_to(ROOT))
        scene["hero_prop_visual_reference_sha256"] = sha256_file(FETCH_LAUNCHER_SOURCE)
    if SELECTED_MESH.is_file():
        scene["selected_candidate_source"] = str(SELECTED_MESH.relative_to(ROOT))
        scene["selected_candidate_sha256"] = sha256_file(SELECTED_MESH)


def _new_object(name: str) -> bpy.types.Object:
    obj = bpy.context.active_object
    obj.name = name
    obj.data.name = name
    return obj


def sphere(name: str, radius: float, location, scale=(1.0, 1.0, 1.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location, segments=32, ring_count=16)
    obj = _new_object(name)
    obj.scale = scale
    return obj


def cylinder(name: str, radius: float, depth: float, location, rotation=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=location, rotation=rotation, vertices=32)
    return _new_object(name)


def cube(name: str, size, location, rotation=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    obj = _new_object(name)
    obj.scale = size
    return obj


def torus(name: str, major: float, minor: float, location, rotation=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major, minor_radius=minor, location=location, rotation=rotation,
        major_segments=24, minor_segments=10,
    )
    return _new_object(name)


def capsule(
    name: str,
    radius: float,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
) -> list[bpy.types.Object]:
    """Three overlapping primitives forming a printable rounded limb/roll."""
    a = Vector(start)
    b = Vector(end)
    direction = b - a
    if direction.length == 0.0:
        return [sphere(f"{name}_cap", radius, start)]
    middle = (a + b) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=direction.length, location=middle)
    shaft = _new_object(f"{name}_shaft")
    shaft.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return [
        shaft,
        sphere(f"{name}_start", radius, start),
        sphere(f"{name}_end", radius, end),
    ]


def prism(
    name: str,
    points_xz: list[tuple[float, float]],
    centre_y: float,
    depth: float,
) -> bpy.types.Object:
    """Extrude an authored X/Z outline along Y without a fragile modifier."""
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
    bpy.context.collection.objects.link(obj)
    return obj


def text_relief(
    name: str,
    body: str,
    location: tuple[float, float, float],
    size: float,
) -> bpy.types.Object:
    """Raised block lettering thick enough to survive the body remesh."""
    bpy.ops.object.text_add(location=location, rotation=(math.pi / 2.0, 0.0, 0.0))
    obj = bpy.context.active_object
    obj.name = name
    obj.data.body = body
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    obj.data.size = size
    obj.data.extrude = 0.8
    obj.data.bevel_depth = 0.12
    obj.data.space_character = 0.92
    bpy.ops.object.convert(target="MESH")
    obj.data.name = name
    return obj


def expanded_mating_cutter(
    source: bpy.types.Object,
    name: str,
    clearance: float,
) -> bpy.types.Object:
    """Copy a finished male part and expand its surface into a female cutter."""
    cutter = source.copy()
    cutter.data = source.data.copy()
    cutter.name = name
    cutter.data.name = name
    bpy.context.collection.objects.link(cutter)
    bpy.ops.object.select_all(action="DESELECT")
    cutter.select_set(True)
    bpy.context.view_layer.objects.active = cutter
    modifier = cutter.modifiers.new("MatingClearance", "DISPLACE")
    modifier.direction = "NORMAL"
    modifier.mid_level = 0.0
    modifier.strength = clearance
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    # Concave details can self-intersect after a normal displacement. Heal the
    # expanded copy before it reaches the exact Boolean solver.
    remesh(cutter, min(REMESH_DETAIL_MM, clearance * 0.5))
    return cutter


def join_and_solidify(name: str, parts: list[bpy.types.Object], voxel_size: float) -> bpy.types.Object:
    """Join overlapping primitives, then voxel remesh into one clean solid.

    Transforms are applied to every part first. Without that, join() bakes the
    other objects into the active object's local space -- which is
    anisotropically scaled -- and the voxel remesh then runs in distorted units
    and fails to fuse overlapping shapes into one body.
    """
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        bpy.ops.object.select_all(action="DESELECT")
        part.select_set(True)
        bpy.context.view_layer.objects.active = part
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    target = parts[0]
    bpy.context.view_layer.objects.active = target
    if len(parts) > 1:
        bpy.ops.object.join()
    target.name = name
    target.data.name = name

    remesh(target, voxel_size)
    return target


def cut_sockets(target: bpy.types.Object, cutters: list[bpy.types.Object], voxel_size: float) -> None:
    """Boolean a group of supervised assembly sockets, then heal once."""
    for cutter in cutters:
        bpy.ops.object.select_all(action="DESELECT")
        target.select_set(True)
        bpy.context.view_layer.objects.active = target
        modifier = target.modifiers.new(f"Socket_{cutter.name}", "BOOLEAN")
        modifier.operation = "DIFFERENCE"
        modifier.solver = "EXACT"
        modifier.object = cutter
        modifier_name = modifier.name
        bpy.ops.object.modifier_apply(modifier=modifier_name)
        bpy.data.objects.remove(cutter, do_unlink=True)
        if len(target.data.polygons) < 500:
            raise RuntimeError(
                f"socket Boolean {modifier_name} collapsed {target.name} "
                f"to {len(target.data.polygons)} faces"
            )
    remesh(target, voxel_size)


def remesh(obj: bpy.types.Object, voxel_size: float) -> None:
    """Voxel remesh, then remove the degenerate faces it leaves behind.

    Voxel remesh produces a closed surface but emits a small number of
    zero-area triangles. Those are not holes -- they are worse: each one makes
    its edges incident to three faces, so the mesh reads as non-manifold and a
    slicer cannot decide which side is solid. Dissolving them is what makes
    watertightness hold rather than nearly hold.
    """
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    modifier = obj.modifiers.new("Remesh", "REMESH")
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


# ---------------------------------------------------------------------------
# Provisional digital prototype, following the current unapproved default brief.
# ---------------------------------------------------------------------------
# Vertical budget, in millimetres from the shelf:
#   0.0 -   5.0  base
#   5.0 -  46.0  hind legs
#  46.0 -  99.0  torso and jacket
#  99.0 - 136.5  head
# 136.5 - 140.0  crown curl
BASE_TOP = BASE_THICKNESS_MM
HEAD_CENTRE_Z = 117.0
HEAD_RADIUS = 18.0

# Cutter dimensions compensate for the final 0.6 mm body/head voxel remesh.
# The exported-STL gate measures the actual result against the 0.20–0.35 mm
# contract; these are authoring values, not claimed finished clearances.
BASE_SOCKET_CLEARANCES_MM = (0.25, 0.32)
HEAD_SOCKET_CLEARANCES_MM = (0.27, 0.26)
NECK_SOCKET_CLEARANCE_MM = 0.28
GLASSES_ENVELOPE_CLEARANCE_MM = 0.27
PROP_BULK_CLEARANCE_MM = 0.55
PROP_SOCKET_CLEARANCES_MM = (0.31, 0.30)


def build_base() -> bpy.types.Object:
    parts = [
        cylinder("base_disc", BASE_DIAMETER_MM / 2.0, BASE_THICKNESS_MM, (0.0, 0.0, BASE_THICKNESS_MM / 2.0))
    ]
    for index, (x, y, radius, height) in enumerate(BASE_PEG_SPECS):
        parts.append(
            cylinder(
                f"base_key_{index}",
                radius,
                height,
                (x, y, BASE_TOP + height / 2.0 - 0.45),
            )
        )
    return join_and_solidify("Base_Keyed", parts, REMESH_BODY_MM)


def build_body() -> bpy.types.Object:
    parts: list[bpy.types.Object] = []

    # A planted but asymmetrical stance: the right paw carries the weight while
    # the left sits slightly forward. Rounded limbs replace the old rectangular
    # mannequin silhouette.
    leg_specs = (
        (-1, -9.5, -2.0, -5.0),
        (1, 9.5, 2.0, 0.5),
    )
    for side, x, knee_y, paw_y in leg_specs:
        parts.append(sphere(f"thigh_{side}", 10.0, (x, 1.5, 55.0), scale=(0.9, 0.78, 1.18)))
        parts.extend(capsule(f"shin_{side}", 5.8, (x, knee_y, 47.0), (x, paw_y, 18.0)))
        parts.append(sphere(f"paw_{side}", 7.5, (x, paw_y - 2.0, 10.8), scale=(1.05, 1.45, 0.72)))
        for toe in (-1, 0, 1):
            parts.append(
                sphere(
                    f"paw_toe_{side}_{toe}",
                    2.25,
                    (x + toe * 3.0, paw_y - 10.0, 9.0),
                    scale=(1.0, 1.15, 0.72),
                )
            )

    # Torso, jacket body and shoulders are all rounded masses. The raised
    # lapels leave a clear open V with chest ruff between them.
    parts.append(sphere("torso", 19.5, (0.0, 1.0, 76.0), scale=(1.02, 0.75, 1.27)))
    parts.append(sphere("jacket_core", 19.0, (0.0, 3.0, 78.5), scale=(1.15, 0.82, 1.08)))
    parts.append(sphere("chest_ruff", 12.0, (0.0, -12.5, 83.5), scale=(1.0, 0.62, 1.08)))
    for x, z in ((-7.0, 90.0), (0.0, 91.5), (7.0, 90.0), (-6.0, 82.5), (1.0, 81.5)):
        parts.append(sphere(f"chest_curl_{x}_{z}", 3.6, (x, -18.0, z), scale=(1.0, 0.7, 1.0)))

    for side in (-1, 1):
        parts.append(sphere(f"shoulder_{side}", 10.0, (side * 16.0, 0.0, 88.0), scale=(1.0, 0.8, 0.72)))
        parts.extend(
            capsule(
                f"lapel_{side}",
                4.1,
                (side * 15.0, -12.0, 92.0),
                (side * 7.0, -15.5, 74.0),
            )
        )

    arm_paths = {
        -1: ((-17.0, -3.0, 86.0), (-20.0, -12.0, 75.0), (-7.0, -19.0, 68.0)),
        1: ((17.0, -3.0, 86.0), (20.0, -10.0, 74.0), (10.5, -19.0, 62.0)),
    }
    for side, (shoulder, elbow, hand) in arm_paths.items():
        parts.extend(capsule(f"upper_arm_{side}", 6.4, shoulder, elbow))
        parts.extend(capsule(f"forearm_{side}", 5.6, elbow, hand))
        parts.append(sphere(f"grip_paw_{side}", 6.3, hand, scale=(1.0, 0.88, 1.0)))
        for toe in (-1, 0, 1):
            parts.append(
                sphere(
                    f"grip_toe_{side}_{toe}",
                    2.1,
                    (hand[0] + toe * 2.5, hand[1] - 3.5, hand[2] - 1.0),
                )
            )

    # Thick curled tail stays fused close to the rear silhouette rather than
    # becoming a fragile cantilever.
    parts.extend(capsule("tail_root", 4.8, (11.0, 11.0, 61.0), (19.0, 15.0, 68.0)))
    parts.extend(capsule("tail_tip", 4.5, (19.0, 15.0, 68.0), (16.0, 14.0, 77.0)))

    parts.append(cylinder("neck", 9.5, 14.0, (0.0, -0.5, 98.0)))
    for index, (x, y, radius, height) in enumerate(HEAD_KEY_SPECS):
        parts.append(cylinder(f"head_key_{index}", radius, height, (x, y, 104.0 + height / 2.0)))

    # Chain collar and the COBIE dog tag. The tag is the one prop that
    # identifies him with zero ambiguity, so it is authored thick enough to
    # survive printing rather than left as a surface detail.
    parts.append(torus("collar_chain", 11.5, 1.8, (0.0, -0.5, 95.0)))
    parts.append(cube("dog_tag", (12.0, 2.8, 10.0), (0.0, -17.0, 85.0)))
    parts.append(text_relief("dog_tag_text", "COBIE", (0.0, -18.55, 85.0), 3.2))

    return join_and_solidify("Cobie_Body", parts, REMESH_BODY_MM)


def build_head() -> bpy.types.Object:
    parts = [
        # Moderately oversized head, per the V1 product definition.
        sphere("skull", HEAD_RADIUS, (0.0, 0.0, HEAD_CENTRE_Z), scale=(1.04, 0.96, 1.0)),
        # Short blunt muzzle blended into the beard furnishings.
        sphere("muzzle_left", 8.0, (-4.8, -14.8, 112.5), scale=(1.0, 0.9, 0.74)),
        sphere("muzzle_right", 8.0, (4.8, -14.8, 112.5), scale=(1.0, 0.9, 0.74)),
        sphere("beard", 7.4, (0.0, -14.0, 105.8), scale=(1.15, 0.82, 1.0)),
        sphere("nose", 4.8, (0.0, -21.4, 114.0), scale=(1.14, 0.72, 0.82)),
        # A concealed collar skirt gives the neck socket a complete load-
        # bearing wall instead of relying on the narrowing bottom of a sphere.
        cylinder("head_neck_collar", 12.5, 5.0, (0.0, -0.5, 103.5)),
    ]

    # Deterministic crown and muzzle curls: broad enough to print, sparse enough
    # that the head still reads as one clean mass from shelf distance.
    crown_curls = (
        (-11.0, -1.0, 132.0, 5.0),
        (-5.5, 1.0, 135.0, 5.0),
        (0.0, 0.0, 136.0, 4.6),
        (5.5, 1.0, 135.0, 5.0),
        (11.0, -1.0, 132.0, 5.0),
        (-8.5, -8.0, 129.5, 4.2),
        (0.0, -9.0, 131.5, 4.4),
        (8.5, -8.0, 129.5, 4.2),
    )
    for index, (x, y, z, radius) in enumerate(crown_curls):
        parts.append(sphere(f"crown_curl_{index}", radius, (x, y, z), scale=(1.0, 0.85, 1.0)))
    for index, (x, z) in enumerate(((-8.0, 111.0), (-4.0, 107.5), (4.0, 107.5), (8.0, 111.0))):
        parts.append(sphere(f"muzzle_curl_{index}", 3.2, (x, -19.0, z), scale=(1.0, 0.75, 1.0)))

    # Floppy ears are chains of overlapping rounded masses, producing a real
    # continuous curled silhouette rather than two detached oval flaps.
    for side in (-1, 1):
        parts.extend(capsule(f"ear_mass_{side}", 7.8, (side * 15.0, 0.5, 122.0), (side * 17.0, 0.0, 105.0)))
        for index, z in enumerate((122.0, 116.0, 110.0, 104.0)):
            parts.append(
                sphere(
                    f"ear_curl_{side}_{index}",
                    4.0,
                    (side * 19.0, -4.0 + (index % 2) * 2.5, z),
                    scale=(0.85, 1.0, 1.0),
                )
            )

    return join_and_solidify("Cobie_Head", parts, REMESH_BODY_MM)


def build_sunglasses() -> bpy.types.Object:
    """Aviators, authored at printable thickness rather than thinned to scale.

    Every element is at least SUNGLASSES_ARM_MM thick by construction, and the
    arms are fused into the head contact points. Visually thin parts are the
    single most common thing to snap during support removal.
    """
    thickness = max(SUNGLASSES_ARM_MM, 1.8)
    lens_z = 120.0
    parts: list[bpy.types.Object] = [
        cube("aviator_top_bridge", (8.0, thickness, 1.8), (0.0, -20.0, lens_z + 3.4)),
        cube("aviator_lower_bridge", (5.0, thickness, 1.5), (0.0, -20.1, lens_z + 0.8)),
    ]
    outline = (
        (-6.4, 3.6),
        (4.8, 3.6),
        (6.2, 1.5),
        (4.6, -4.5),
        (0.8, -6.0),
        (-4.6, -4.8),
        (-6.4, -1.2),
    )
    for side in (-1, 1):
        centre_x = side * 7.8
        points = [(centre_x + side * x, lens_z + z) for x, z in outline]
        parts.append(prism(f"aviator_lens_{side}", points, -20.0, thickness))
        parts.extend(
            capsule(
                f"aviator_arm_{side}",
                1.1,
                (side * 13.2, -19.4, lens_z + 2.0),
                (side * 14.5, -7.5, lens_z + 2.0),
            )
        )
    for index, (x, y, z, radius, depth) in enumerate(GLASSES_PIN_SPECS):
        parts.append(
            cylinder(
                f"glasses_pin_{index}",
                radius,
                depth,
                (x, y, z),
                rotation=(math.pi / 2.0, 0.0, 0.0),
            )
        )
    return join_and_solidify("Cobie_Sunglasses", parts, REMESH_DETAIL_MM)


def launcher_parts(
    prefix: str,
    clearance: float = 0.0,
    *,
    include_pins: bool,
) -> list[bpy.types.Object]:
    """Author the launcher or its remesh-compensated body-contact envelope."""
    c = clearance
    parts: list[bpy.types.Object] = [
        cube(f"{prefix}_receiver", (18.0 + 2 * c, 13.0 + 2 * c, 13.0 + 2 * c), (-7.0, -20.0, 68.5)),
        cylinder(
            f"{prefix}_drum",
            8.2 + c,
            8.0 + 2 * c,
            (-8.0, -21.0, 68.0),
            rotation=(math.pi / 2.0, 0.0, 0.0),
        ),
        sphere(f"{prefix}_loaded_ball", 5.2 + c, (-8.0, -25.0, 72.5)),
        cylinder(
            f"{prefix}_barrel",
            5.0 + c,
            34.0 + 2 * c,
            (13.0, -20.0, 66.0),
            rotation=(0.0, math.pi / 2.0, 0.0),
        ),
        cylinder(
            f"{prefix}_muzzle",
            6.5 + c,
            5.0 + 2 * c,
            (30.0, -20.0, 66.0),
            rotation=(0.0, math.pi / 2.0, 0.0),
        ),
        torus(
            f"{prefix}_charge_ring",
            6.25,
            1.35 + c,
            (26.5, -20.0, 66.0),
            rotation=(0.0, math.pi / 2.0, 0.0),
        ),
        cube(f"{prefix}_charge_meter", (2.0 + 2 * c, 4.0 + 2 * c, 8.0 + 2 * c), (-1.0, -27.0, 70.0)),
    ]
    for index, x in enumerate((3.0, 11.0, 19.0)):
        parts.append(
            torus(
                f"{prefix}_cage_{index}",
                6.2,
                1.3 + c,
                (x, -20.0, 66.0),
                rotation=(0.0, math.pi / 2.0, 0.0),
            )
        )
    parts.extend(capsule(f"{prefix}_handle", 2.3 + c, (-13.0, -20.0, 77.0), (2.0, -20.0, 77.0)))
    parts.extend(capsule(f"{prefix}_grip", 4.0 + c, (-10.0, -18.0, 64.0), (-13.0, -16.0, 54.0)))
    parts.extend(capsule(f"{prefix}_spine", 3.2 + c, (-11.0, -20.0, 66.0), (28.0, -20.0, 66.0)))

    parts.append(
        sphere(f"{prefix}_badge_pad", 2.0 + c, (-3.0, -26.4, 68.0), scale=(1.0, 0.65, 1.0))
    )
    for index, (x, z) in enumerate(((-4.3, 70.0), (-3.2, 70.7), (-2.0, 70.5), (-1.2, 69.5))):
        parts.append(
            sphere(f"{prefix}_badge_toe_{index}", 0.95 + c, (x, -26.5, z), scale=(1.0, 0.7, 1.0))
        )

    if include_pins:
        for index, (x, y, z, radius, depth) in enumerate(PROP_PIN_SPECS):
            parts.append(
                cylinder(
                    f"{prefix}_pin_{index}",
                    radius,
                    depth,
                    (x, y, z),
                    rotation=(math.pi / 2.0, 0.0, 0.0),
                )
            )
    return parts


def build_prop() -> bpy.types.Object:
    """Build a print-strength interpretation of the production launcher.

    The project-owned GLB is the visual feature reference. Its receiver, drum,
    loaded ball, caged barrel, charge ring, handle, grip and paw badge are
    rebuilt as overlapping solids because a direct 18-shell 0.3 mm voxel union
    exceeded the 16 GB target Mac's safe authoring budget. Every visible element
    remains above the print floor and the reference path/hash is stamped.
    """
    if not FETCH_LAUNCHER_SOURCE.is_file():
        raise FileNotFoundError(f"project-owned Fetch Launcher source is missing: {FETCH_LAUNCHER_SOURCE}")
    return join_and_solidify(
        "Cobie_Prop_FetchLauncher",
        launcher_parts("launcher", include_pins=True),
        REMESH_PROP_MM,
    )


def build_launcher_mating_envelope() -> bpy.types.Object:
    """Create the prop bulk envelope without registration pins."""
    return join_and_solidify(
        "launcher_mating_envelope",
        launcher_parts(
            "launcher_mating",
            PROP_BULK_CLEARANCE_MM,
            include_pins=False,
        ),
        REMESH_PROP_MM,
    )


def cut_head_assembly_sockets(head: bpy.types.Object, glasses: bpy.types.Object) -> None:
    """Cut a neck recess, orientation keys, and the complete glasses envelope."""
    cutters: list[bpy.types.Object] = [
        cylinder(
            "neck_recess",
            NECK_RADIUS_MM + NECK_SOCKET_CLEARANCE_MM,
            NECK_DEPTH_MM + 3.0,
            NECK_CENTRE,
        ),
        expanded_mating_cutter(
            glasses,
            "glasses_mating_envelope",
            GLASSES_ENVELOPE_CLEARANCE_MM,
        ),
    ]
    for index, (x, y, radius, _height) in enumerate(HEAD_KEY_SPECS):
        cutters.append(
            cylinder(
                f"head_socket_{index}",
                radius + HEAD_SOCKET_CLEARANCES_MM[index],
                13.0,
                (x, y, 109.5),
            )
        )
    cut_sockets(head, cutters, REMESH_DETAIL_MM)


def cut_body_assembly_sockets(body: bpy.types.Object) -> None:
    """Cut base keys plus the complete launcher/grip mating envelope."""
    cutters: list[bpy.types.Object] = []
    for index, (x, y, radius, height) in enumerate(BASE_PEG_SPECS):
        cutters.append(
            cylinder(
                f"base_socket_{index}",
                radius + BASE_SOCKET_CLEARANCES_MM[index],
                height + 1.5,
                (x, y, BASE_TOP + height / 2.0 - 0.2),
            )
        )
    cutters.append(build_launcher_mating_envelope())
    for index, (x, y, z, radius, depth) in enumerate(PROP_PIN_SPECS):
        cutters.append(
            cylinder(
                f"launcher_socket_{index}",
                radius + PROP_SOCKET_CLEARANCES_MM[index],
                depth + 2.0,
                (x, y + 0.5, z),
                rotation=(math.pi / 2.0, 0.0, 0.0),
            )
        )
    cut_sockets(body, cutters, REMESH_BODY_MM)


def import_selected() -> list[bpy.types.Object]:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(SELECTED_MESH))
    imported = [obj for obj in bpy.data.objects if obj not in before and obj.type == "MESH"]

    # Normalise the candidate itself into the 135 mm envelope above the 5 mm
    # base. Generators emit arbitrary scale and origin; both are corrected for
    # review before any supervised part work begins.
    if imported:
        corners = [obj.matrix_world @ Vector(corner) for obj in imported for corner in obj.bound_box]
        lowest = min(corner.z for corner in corners)
        highest = max(corner.z for corner in corners)
        centre_x = (min(corner.x for corner in corners) + max(corner.x for corner in corners)) * 0.5
        centre_y = (min(corner.y for corner in corners) + max(corner.y for corner in corners)) * 0.5
        span = highest - lowest
        if span > 0:
            factor = (FIGURE_HEIGHT_MM - BASE_TOP) / span
            transform = (
                Matrix.Translation(
                    Vector((-centre_x * factor, -centre_y * factor, BASE_TOP - lowest * factor))
                )
                @ Matrix.Scale(factor, 4)
            )
            for obj in imported:
                world = obj.matrix_world.copy()
                obj.parent = None
                obj.matrix_world = transform @ world
            bpy.context.view_layer.update()
    return imported


def export_parts(parts: list[bpy.types.Object], destination: Path) -> list[Path]:
    destination.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for part in parts:
        bpy.ops.object.select_all(action="DESELECT")
        part.select_set(True)
        bpy.context.view_layer.objects.active = part
        path = destination / f"{part.name}.stl"
        # global_scale 1.0 with a millimetre authoring contract means the number
        # in the STL is already the number the print service will read.
        bpy.ops.wm.stl_export(filepath=str(path), export_selected_objects=True, global_scale=1.0, apply_modifiers=True)
        written.append(path)
    return written


def write_build_report(
    status: str,
    mode: str,
    detail: str = "",
    *,
    written: list[Path] | None = None,
    source_blend: Path | None = None,
    review_blend: Path | None = None,
) -> None:
    payload: dict = {
        "status": status,
        "mode": mode,
        "pipeline_version": PIPELINE_VERSION,
        "detail": detail,
        "selected_candidate_sha256": sha256_file(SELECTED_MESH) if SELECTED_MESH.is_file() else None,
        "exports": {},
    }
    if source_blend is not None and source_blend.is_file():
        payload["source_blend"] = str(source_blend.relative_to(ROOT))
        payload["source_blend_sha256"] = sha256_file(source_blend)
    if review_blend is not None and review_blend.is_file():
        payload["review_blend"] = str(review_blend.relative_to(ROOT))
        payload["review_blend_sha256"] = sha256_file(review_blend)
    if written:
        payload["exports"] = {path.name: sha256_file(path) for path in written}
    write_json(BUILD_REPORT, payload)


def publish_exports(staged: list[Path]) -> list[Path]:
    """Publish a complete canonical set only after every staged export exists."""
    expected = {f"{name}.stl" for name in PART_NAMES}
    observed = {path.name for path in staged if path.is_file()}
    if observed != expected:
        raise RuntimeError(f"staged export inventory mismatch: expected={sorted(expected)} observed={sorted(observed)}")

    EXPORTS.mkdir(parents=True, exist_ok=True)
    published: list[Path] = []
    with tempfile.TemporaryDirectory(prefix=".cobie-backup-", dir=EXPORTS) as raw_backup:
        backup = Path(raw_backup)
        invalid_directories = [
            path
            for path in EXPORTS.iterdir()
            if path.suffix.lower() == ".stl" and path.is_dir() and not path.is_symlink()
        ]
        if invalid_directories:
            raise RuntimeError(
                "refusing to publish over STL-named directories: "
                + ", ".join(path.name for path in invalid_directories)
            )
        previous = [
            path
            for path in EXPORTS.iterdir()
            if path.suffix.lower() == ".stl"
        ]
        backed_up: list[tuple[Path, Path]] = []
        try:
            for path in previous:
                backup_path = backup / path.name
                os.replace(path, backup_path)
                backed_up.append((backup_path, path))
            for source in staged:
                destination = EXPORTS / source.name
                os.replace(source, destination)
                published.append(destination)
        except Exception:
            for path in published:
                path.unlink(missing_ok=True)
            for backup_path, original_path in backed_up:
                if backup_path.exists():
                    os.replace(backup_path, original_path)
            raise

    # A new geometry set invalidates downstream evidence until those gates run
    # against the new hashes.
    for report_path in (
        EXPORTS / "print_check_report.json",
        SLICER_TESTS / "prusaslicer_import_report.json",
    ):
        if report_path.is_file():
            report_path.unlink()
    return published


def reviewed_parts() -> list[bpy.types.Object]:
    bpy.ops.wm.open_mainfile(filepath=str(REVIEW_BLEND_PATH))
    expected_hash = sha256_file(SELECTED_MESH)
    recorded_hash = bpy.context.scene.get("selected_candidate_sha256")
    if recorded_hash != expected_hash:
        raise RuntimeError(
            "review blend belongs to a different selected.glb; archive or remove "
            f"{REVIEW_BLEND_PATH.name} before importing the new candidate"
        )

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    by_name = {obj.name: obj for obj in meshes}
    expected = set(PART_NAMES)
    observed = set(by_name)
    if observed != expected:
        raise RuntimeError(
            "reviewed blend must contain exactly the five canonical mesh objects; "
            f"missing={sorted(expected - observed)} unexpected={sorted(observed - expected)}"
        )
    return [by_name[name] for name in PART_NAMES]


def prepare_selected_review() -> int:
    mode = "selected_candidate_review_only"
    reset_scene()
    imported = import_selected()
    if not imported:
        raise RuntimeError(f"{SELECTED_MESH}: no mesh objects imported")

    # Preserve the source candidate's topology and object structure for the
    # supervised review. A pre-review voxel union can destroy fine identity
    # detail, erase useful part boundaries, and exceed the target Mac's memory
    # budget. The base is only a scale/stance reference.
    build_base()
    stamp_provenance(mode)
    BLEND_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(REVIEW_BLEND_PATH))
    detail = (
        "supervised split required: separate, pose and key exactly "
        + ", ".join(PART_NAMES)
    )
    write_build_report("FAIL", mode, detail, review_blend=REVIEW_BLEND_PATH)
    print(f"  imported {SELECTED_MESH.name} into {REVIEW_BLEND_PATH.name}")
    print("  FAIL [supervised_split] selected candidate is not yet a reviewed five-part assembly")
    print(f"  Edit and save {REVIEW_BLEND_PATH}; rerun this script to validate/export it.")
    print("  Existing STLs were retained but the FAIL build receipt prevents a false current pass.")
    print("COBIE_FIGURINE_BUILD: FAIL (supervised split required)")
    return 1


def build_and_publish() -> int:
    if SELECTED_MESH.is_file() and REVIEW_BLEND_PATH.is_file():
        mode = "selected_candidate_reviewed"
        parts = reviewed_parts()
        print(f"  loaded reviewed five-part assembly from {REVIEW_BLEND_PATH.name}")
    elif SELECTED_MESH.is_file():
        return prepare_selected_review()
    else:
        mode = "provisional_game_art_prototype"
        reset_scene()
        body = build_body()
        head = build_head()
        glasses = build_sunglasses()
        prop = build_prop()
        base = build_base()
        cut_head_assembly_sockets(head, glasses)
        cut_body_assembly_sockets(body)
        parts = [body, head, glasses, prop, base]
        print("  no selected.glb found; built the PROVISIONAL DIGITAL PROTOTYPE")
        print("  this starts pose/silhouette engineering; identity approval remains OPEN")
        print("  do not manufacture this model before the photo/turnaround and owner-review gates")

    stamp_provenance(mode)
    BLEND_DIR.mkdir(parents=True, exist_ok=True)
    EXPORTS.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".cobie-export-", dir=EXPORTS) as raw_staging:
        staged = export_parts(parts, Path(raw_staging))
        # Fail closed before replacing any current export. If the process is
        # interrupted during the source save or publication, no old PASS
        # receipt remains.
        write_build_report("BUILDING", mode, "publishing canonical export set")
        bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
        written = publish_exports(staged)
    write_build_report("PASS", mode, written=written, source_blend=BLEND_PATH)
    for path in written:
        print(f"  exported {path.name} ({path.stat().st_size // 1024} KB)")

    print(f"  blend: {BLEND_PATH.relative_to(BLEND_DIR.parents[1])}")
    print("COBIE_FIGURINE_BUILD: PASS")
    return 0


def main() -> int:
    mode = "selected_candidate" if SELECTED_MESH.is_file() else "provisional_game_art_prototype"
    try:
        return build_and_publish()
    except Exception as exc:
        write_build_report("FAIL", mode, str(exc))
        print(f"  FAIL [build] {exc}")
        print("  Previously published STLs were not replaced.")
        print("COBIE_FIGURINE_BUILD: FAIL")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
