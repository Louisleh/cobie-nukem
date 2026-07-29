#!/usr/bin/env python3
"""Phase 3: build the printable Cobie figurine and export per-part STL.

Run:
    uv run --project cobie-collectible/tools \
        python cobie-collectible/scripts/build_figurine.py

Two modes, chosen automatically:

  * If cobie-collectible/generated-meshes/selected.glb exists, it is imported,
    normalised to the height contract, and split into named parts. This is the
    real Phase 3 path once the Phase 2 bakeoff has picked a winner.

  * Otherwise a proportioned PROXY is built from primitives, following the
    frozen character brief. The proxy is not the deliverable and will not be
    printed. It exists so the print rules, base keying, balance maths, export
    and validation are exercised and testable before any generated mesh
    arrives -- rather than discovering the pipeline is broken at the moment a
    real candidate lands.

House conventions from tools/blender/*.py: no argparse, module-level path
constants, factory reset, provenance stamped as scene custom properties, zero
RNG, and a greppable PASS sentinel.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    ASSEMBLY_CLEARANCE_MM,
    BASE_DIAMETER_MM,
    BASE_THICKNESS_MM,
    BLEND_DIR,
    EXPORTS,
    FIGURE_HEIGHT_MM,
    GENERATED_MESHES,
    PIPELINE_VERSION,
    SCALE_CONTRACT,
    SUNGLASSES_ARM_MM,
    UNIT_SCALE_LENGTH,
)

SELECTED_MESH = GENERATED_MESHES / "selected.glb"
BLEND_PATH = BLEND_DIR / "cobie_figurine_v1.blend"

# Voxel remesh fuses overlapping primitives into one watertight, correctly
# wound body. Doing it per part is what makes print_check's watertight,
# winding and floating-shell checks pass by construction instead of by luck.
REMESH_BODY_MM = 0.7
REMESH_DETAIL_MM = 0.35


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
# Proxy construction, following references/character-brief/cobie_figurine_v1.yaml
# ---------------------------------------------------------------------------
# Vertical budget, in millimetres from the shelf:
#   0.0 -   5.0  base
#   5.0 -  46.0  hind legs
#  46.0 -  99.0  torso and jacket
#  99.0 - 136.5  head
# 136.5 - 140.0  crown curl
BASE_TOP = BASE_THICKNESS_MM
HEAD_CENTRE_Z = 118.0
HEAD_RADIUS = 18.5
PEG_RADIUS = 6.0
PEG_HEIGHT = 6.0


def build_base() -> bpy.types.Object:
    parts = [
        cylinder("base_disc", BASE_DIAMETER_MM / 2.0, BASE_THICKNESS_MM, (0.0, 0.0, BASE_THICKNESS_MM / 2.0)),
        # Keyed peg. The matching socket is cut into the body with an explicit
        # clearance so the two parts assemble without forced bending (FR-4).
        cylinder("base_peg", PEG_RADIUS, PEG_HEIGHT, (0.0, 0.0, BASE_TOP + PEG_HEIGHT / 2.0 - 0.5)),
    ]
    return join_and_solidify("Base_Keyed", parts, REMESH_BODY_MM)


def build_body() -> bpy.types.Object:
    parts: list[bpy.types.Object] = []

    # Hind legs, planted, weight on the back paw.
    for side in (-1, 1):
        parts.append(sphere(f"thigh_{side}", 11.0, (side * 9.0, 2.0, 60.0), scale=(1.0, 1.2, 1.5)))
        parts.append(cylinder(f"shin_{side}", 6.5, 30.0, (side * 9.5, 0.0, 32.0)))
        parts.append(sphere(f"paw_{side}", 8.0, (side * 9.5, -3.0, BASE_TOP + 6.0), scale=(1.0, 1.5, 0.75)))

    # Torso and the open leather jacket over it.
    parts.append(sphere("torso", 20.0, (0.0, 0.0, 76.0), scale=(1.0, 0.78, 1.25)))
    parts.append(sphere("chest_ruff", 15.0, (0.0, -11.0, 84.0), scale=(1.0, 0.6, 0.9)))
    parts.append(cube("jacket_back", (36.0, 6.0, 44.0), (0.0, 9.5, 78.0)))
    for side in (-1, 1):
        parts.append(cube("jacket_lapel", (9.0, 5.0, 26.0), (side * 12.0, -11.0, 84.0), rotation=(0.0, side * 0.18, 0.0)))
        # Sleeves reach mid-foreleg; the launcher is held across the body.
        parts.append(cylinder(f"upper_arm_{side}", 7.0, 26.0, (side * 20.0, -2.0, 82.0), rotation=(0.35, 0.0, side * 0.30)))
        parts.append(cylinder(f"forearm_{side}", 6.0, 24.0, (side * 15.0, -14.0, 68.0), rotation=(1.30, 0.0, side * 0.25)))
        parts.append(sphere(f"grip_paw_{side}", 7.0, (side * 8.0, -21.0, 62.0)))

    parts.append(cylinder("neck", 10.0, 14.0, (0.0, -1.0, 98.0)))

    # Chain collar and the COBIE dog tag. The tag is the one prop that
    # identifies him with zero ambiguity, so it is authored thick enough to
    # survive printing rather than left as a surface detail.
    parts.append(torus("collar_chain", 11.0, 1.8, (0.0, -1.0, 95.0)))
    parts.append(cube("dog_tag", (9.0, 2.2, 12.0), (0.0, -11.5, 87.0)))

    return join_and_solidify("Cobie_Body", parts, REMESH_BODY_MM)


def build_head() -> bpy.types.Object:
    parts = [
        # Moderately oversized head, per the V1 product definition.
        sphere("skull", HEAD_RADIUS, (0.0, 0.0, HEAD_CENTRE_Z), scale=(1.0, 1.05, 1.0)),
        sphere("crown_curl", 11.0, (0.0, 2.0, HEAD_CENTRE_Z + 12.0)),
        # Short blunt muzzle blended into the beard furnishings.
        sphere("muzzle", 10.0, (0.0, -15.0, HEAD_CENTRE_Z - 5.0), scale=(1.0, 1.25, 0.85)),
        sphere("nose", 4.2, (0.0, -25.0, HEAD_CENTRE_Z - 3.0)),
    ]
    # Floppy drop ears reading as one continuous curled mass, hanging to jaw
    # level. Kept fused to the skull so they are not a snap-off feature.
    for side in (-1, 1):
        parts.append(sphere(f"ear_top_{side}", 10.0, (side * 16.0, 1.0, HEAD_CENTRE_Z + 2.0), scale=(0.65, 1.0, 1.0)))
        parts.append(sphere(f"ear_low_{side}", 9.0, (side * 17.0, 0.0, HEAD_CENTRE_Z - 12.0), scale=(0.6, 1.0, 1.2)))
    return join_and_solidify("Cobie_Head", parts, REMESH_BODY_MM)


def build_sunglasses() -> bpy.types.Object:
    """Aviators, authored at printable thickness rather than thinned to scale.

    Every element is at least SUNGLASSES_ARM_MM thick by construction, and the
    arms are fused into the head contact points. Visually thin parts are the
    single most common thing to snap during support removal.
    """
    thickness = max(SUNGLASSES_ARM_MM, 1.6)
    z = HEAD_CENTRE_Z - 1.0
    parts = [cube("bridge", (7.0, thickness, 2.4), (0.0, -16.5, z + 2.0))]
    for side in (-1, 1):
        parts.append(
            cylinder(f"lens_{side}", 7.4, thickness, (side * 8.2, -16.2, z), rotation=(math.pi / 2.0, 0.0, 0.0))
        )
        parts.append(
            cube("arm", (thickness, 20.0, 2.6), (side * 14.0, -8.0, z + 2.5), rotation=(0.0, 0.0, side * 0.22))
        )
    return join_and_solidify("Cobie_Sunglasses", parts, REMESH_DETAIL_MM)


def build_prop() -> bpy.types.Object:
    """Fetch Launcher, simplified to the silhouette that survives at 140 mm.

    Follows the runtime viewmodel design in tools/blender/build_cobie_weapon_foundry.py:
    gold drum magazine, caged barrel, cyan charge ring, loaded tennis ball.
    """
    parts = [
        cylinder("receiver", 6.5, 26.0, (0.0, -20.0, 64.0), rotation=(0.0, math.pi / 2.0, 0.0)),
        cylinder("drum", 9.0, 7.0, (-4.0, -20.0, 70.0), rotation=(0.0, math.pi / 2.0, 0.0)),
        sphere("tennis_ball", 5.6, (-4.0, -20.0, 76.5)),
        cylinder("barrel", 5.2, 30.0, (16.0, -20.0, 62.0), rotation=(0.0, math.pi / 2.0, 0.0)),
        cylinder("muzzle", 6.0, 4.0, (30.0, -20.0, 62.0), rotation=(0.0, math.pi / 2.0, 0.0)),
        cube("carry_handle", (16.0, 4.0, 3.0), (4.0, -20.0, 72.0)),
    ]
    for index in range(3):
        parts.append(
            torus(f"cage_{index}", 6.4, 1.4, (8.0 + index * 8.0, -20.0, 62.0), rotation=(0.0, math.pi / 2.0, 0.0))
        )
    return join_and_solidify("Cobie_Prop_FetchLauncher", parts, REMESH_DETAIL_MM)


def cut_assembly_socket(body: bpy.types.Object) -> None:
    """Cut the keyed socket into the body with an explicit assembly clearance."""
    cutter = cylinder(
        "socket_cutter",
        PEG_RADIUS + ASSEMBLY_CLEARANCE_MM,
        PEG_HEIGHT + 1.0,
        (0.0, 0.0, BASE_TOP + PEG_HEIGHT / 2.0 - 0.5),
    )
    modifier = body.modifiers.new("Socket", "BOOLEAN")
    modifier.operation = "DIFFERENCE"
    modifier.object = cutter
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.data.objects.remove(cutter, do_unlink=True)

    # A boolean against an already-remeshed solid reliably leaves non-manifold
    # edges along the cut. Remesh once more so the part that reaches the slicer
    # is watertight by construction rather than by hope.
    remesh(body, REMESH_BODY_MM)


def import_selected() -> list[bpy.types.Object]:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(SELECTED_MESH))
    imported = [obj for obj in bpy.data.objects if obj not in before and obj.type == "MESH"]

    # Normalise to the height contract. Generators emit arbitrary scales, and an
    # unnormalised import is the classic route to a 0.14 mm figurine.
    if imported:
        zs = [(obj.matrix_world @ corner.to_4d().to_3d()).z for obj in imported for corner in
              [__import__("mathutils").Vector(c) for c in obj.bound_box]]
        span = max(zs) - min(zs)
        if span > 0:
            factor = FIGURE_HEIGHT_MM / span
            for obj in imported:
                obj.scale = tuple(component * factor for component in obj.scale)
                obj.location = tuple(component * factor for component in obj.location)
            bpy.context.view_layer.update()
    return imported


def export_parts(parts: list[bpy.types.Object]) -> list[Path]:
    EXPORTS.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for part in parts:
        bpy.ops.object.select_all(action="DESELECT")
        part.select_set(True)
        bpy.context.view_layer.objects.active = part
        path = EXPORTS / f"{part.name}.stl"
        # global_scale 1.0 with a millimetre authoring contract means the number
        # in the STL is already the number the print service will read.
        bpy.ops.wm.stl_export(filepath=str(path), export_selected_objects=True, global_scale=1.0, apply_modifiers=True)
        written.append(path)
    return written


def main() -> int:
    reset_scene()

    if SELECTED_MESH.is_file():
        mode = "selected_candidate"
        imported = import_selected()
        if not imported:
            print(f"  FAIL [import] {SELECTED_MESH}: no mesh objects imported")
            print("COBIE_FIGURINE_BUILD: FAIL")
            return 1
        body = join_and_solidify("Cobie_Body", imported, REMESH_BODY_MM)
        parts = [body, build_base()]
        print(f"  imported {SELECTED_MESH.name}, normalised to {FIGURE_HEIGHT_MM:.0f} mm")
        print("  NOTE: part separation of a generated mesh is a supervised step.")
        print("        Split head/sunglasses/prop in Blender, or run a part-aware pass, before printing.")
    else:
        mode = "proxy"
        parts = [build_body(), build_head(), build_sunglasses(), build_prop(), build_base()]
        cut_assembly_socket(parts[0])
        print("  no selected.glb found; built the proportioned PROXY")
        print("  the proxy validates the pipeline and is NOT the deliverable")

    stamp_provenance(mode)

    BLEND_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))

    written = export_parts(parts)
    for path in written:
        print(f"  exported {path.name} ({path.stat().st_size // 1024} KB)")

    print(f"  blend: {BLEND_PATH.relative_to(BLEND_DIR.parents[1])}")
    print("COBIE_FIGURINE_BUILD: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
