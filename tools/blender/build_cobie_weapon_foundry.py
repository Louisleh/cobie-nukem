"""Build original Cobie weapon viewmodels and deterministic GLB exports.

The meshes are presentation-only. Gameplay rays/projectiles remain owned by Godot.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/blender/cobie_weapon_foundry.blend"
EXPORT_DIR = ROOT / "assets/models/weapons"


def reset() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    # The 5.1 macOS build exposes the Eevee backend as BLENDER_EEVEE.
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.unit_settings.system = "METRIC"


def material(name: str, color: tuple[float, float, float, float], metallic: float, roughness: float, emission: float = 0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


MATS = {}


def setup_materials() -> None:
    MATS.update(
        metal=material("CN_Gunmetal", (0.045, 0.055, 0.065, 1.0), 0.82, 0.23),
        steel=material("CN_BrushedSteel", (0.23, 0.27, 0.29, 1.0), 0.9, 0.18),
        gold=material("CN_HazardGold", (0.76, 0.39, 0.045, 1.0), 0.62, 0.25),
        leather=material("CN_Leather", (0.095, 0.045, 0.025, 1.0), 0.08, 0.72),
        fur=material("CN_CobieFur", (0.46, 0.22, 0.075, 1.0), 0.02, 0.9),
        rubber=material("CN_Rubber", (0.018, 0.022, 0.024, 1.0), 0.05, 0.85),
        tennis=material("CN_TennisBall", (0.62, 0.93, 0.08, 1.0), 0.02, 0.58, 0.22),
        cyan=material("CN_ChargeCyan", (0.04, 0.72, 0.78, 1.0), 0.25, 0.24, 1.3),
    )


def link_to(obj: bpy.types.Object, collection: bpy.types.Collection) -> bpy.types.Object:
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def box(collection, name, loc, scale, mat, rotation=(0.0, 0.0, 0.0), bevel=0.045):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (scale[0] * 0.5, scale[1] * 0.5, scale[2] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        mod = obj.modifiers.new("EdgeSoftening", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(mat)
    return link_to(obj, collection)


def cylinder(collection, name, loc, radius, depth, mat, rotation=(math.pi / 2.0, 0.0, 0.0), vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("RimSoftening", "BEVEL")
    bevel.width = min(radius * 0.12, 0.025)
    bevel.segments = 2
    return link_to(obj, collection)


def torus(collection, name, loc, major, minor, mat, rotation=(math.pi / 2.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=20, minor_segments=8, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return link_to(obj, collection)


def sphere(collection, name, loc, radius, mat):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=radius, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return link_to(obj, collection)


def paw_badge(collection, origin):
    sphere(collection, "PawBadgePad", origin, 0.055, MATS["gold"])
    for idx, offset in enumerate(((-0.045, -0.02, 0.055), (-0.015, -0.02, 0.078), (0.02, -0.02, 0.078), (0.05, -0.02, 0.052))):
        sphere(collection, f"PawBadgeToe{idx}", (origin[0] + offset[0], origin[1] + offset[1], origin[2] + offset[2]), 0.022, MATS["gold"])


def cobie_grip(collection, origin=(0.0, 0.30, -0.30)):
    """Add a readable leather sleeve and fur paw so the weapon never floats."""
    box(collection, "CobieLeatherSleeve", (origin[0], origin[1] + 0.22, origin[2] - 0.30), (0.38, 0.50, 0.48), MATS["leather"], rotation=(math.radians(-10), 0.0, 0.0), bevel=0.09)
    sphere(collection, "CobieGripPaw", (origin[0], origin[1] - 0.02, origin[2] + 0.02), 0.20, MATS["fur"])
    for idx, x in enumerate((-0.10, -0.035, 0.035, 0.10)):
        sphere(collection, f"CobieGripToe{idx}", (origin[0] + x, origin[1] - 0.16, origin[2] + 0.05), 0.065, MATS["fur"])


def build_pawstol() -> bpy.types.Collection:
    c = bpy.data.collections.new("PawstolViewmodel")
    bpy.context.scene.collection.children.link(c)
    box(c, "PawstolReceiver", (0.0, 0.0, 0.0), (0.34, 0.72, 0.24), MATS["metal"], bevel=0.055)
    box(c, "PawstolSlide", (0.0, -0.10, 0.13), (0.30, 0.58, 0.10), MATS["steel"], bevel=0.025)
    cylinder(c, "PawstolBarrel", (0.0, -0.55, 0.035), 0.075, 0.62, MATS["gold"])
    cylinder(c, "PawstolMuzzle", (0.0, -0.88, 0.035), 0.11, 0.07, MATS["steel"])
    box(c, "PawstolGrip", (0.0, 0.22, -0.27), (0.24, 0.38, 0.58), MATS["leather"], rotation=(math.radians(-16), 0.0, 0.0), bevel=0.055)
    torus(c, "PawstolTriggerGuard", (0.0, 0.02, -0.18), 0.11, 0.025, MATS["gold"], rotation=(math.pi / 2.0, 0.0, 0.0))
    box(c, "PawstolRearSight", (0.0, 0.22, 0.21), (0.18, 0.05, 0.08), MATS["gold"], bevel=0.012)
    box(c, "PawstolFrontSight", (0.0, -0.46, 0.21), (0.06, 0.04, 0.08), MATS["gold"], bevel=0.01)
    paw_badge(c, (0.18, 0.04, 0.02))
    cobie_grip(c, (0.0, 0.28, -0.28))
    return c


def build_barkshot() -> bpy.types.Collection:
    c = bpy.data.collections.new("BarkshotViewmodel")
    bpy.context.scene.collection.children.link(c)
    box(c, "BarkshotReceiver", (0.0, 0.0, 0.02), (0.46, 0.72, 0.34), MATS["metal"], bevel=0.07)
    box(c, "BarkshotTopRail", (0.0, -0.12, 0.23), (0.32, 0.74, 0.08), MATS["gold"], bevel=0.018)
    for idx, x in enumerate((-0.13, 0.13)):
        cylinder(c, f"BarkshotBarrel{idx}", (x, -0.72, 0.08), 0.09, 1.15, MATS["steel"])
        cylinder(c, f"BarkshotMuzzle{idx}", (x, -1.31, 0.08), 0.125, 0.08, MATS["gold"])
    box(c, "BarkshotPump", (0.0, -0.73, -0.12), (0.50, 0.42, 0.22), MATS["leather"], bevel=0.06)
    for x in (-0.16, -0.08, 0.0, 0.08, 0.16):
        box(c, "PumpRib", (x, -0.73, -0.235), (0.025, 0.37, 0.05), MATS["gold"], bevel=0.006)
    box(c, "BarkshotGrip", (0.0, 0.28, -0.30), (0.29, 0.42, 0.62), MATS["rubber"], rotation=(math.radians(-13), 0.0, 0.0), bevel=0.06)
    for idx, x in enumerate((-0.20, 0.20)):
        cylinder(c, f"SideShell{idx}", (x, 0.05, 0.02), 0.045, 0.26, MATS["gold"], rotation=(0.0, 0.0, 0.0), vertices=12)
    paw_badge(c, (0.25, 0.10, 0.05))
    cobie_grip(c, (0.0, 0.31, -0.31))
    return c


def build_fetch_launcher() -> bpy.types.Collection:
    c = bpy.data.collections.new("FetchLauncherViewmodel")
    bpy.context.scene.collection.children.link(c)
    box(c, "FetchReceiver", (0.0, 0.02, 0.0), (0.55, 0.72, 0.46), MATS["metal"], bevel=0.09)
    cylinder(c, "FetchDrum", (0.0, -0.24, 0.03), 0.27, 0.42, MATS["gold"])
    sphere(c, "LoadedTennisBall", (0.0, -0.29, 0.08), 0.17, MATS["tennis"])
    cylinder(c, "FetchBarrel", (0.0, -0.78, 0.04), 0.16, 0.92, MATS["steel"])
    for y in (-0.48, -0.72, -0.96, -1.18):
        torus(c, "FetchBarrelCage", (0.0, y, 0.04), 0.205, 0.027, MATS["gold"])
    cylinder(c, "FetchMuzzle", (0.0, -1.29, 0.04), 0.24, 0.10, MATS["metal"])
    torus(c, "FetchMuzzleGlow", (0.0, -1.35, 0.04), 0.165, 0.028, MATS["cyan"])
    box(c, "FetchGrip", (0.0, 0.28, -0.34), (0.32, 0.46, 0.68), MATS["leather"], rotation=(math.radians(-12), 0.0, 0.0), bevel=0.065)
    box(c, "FetchCarryHandle", (0.0, -0.02, 0.36), (0.38, 0.48, 0.08), MATS["gold"], bevel=0.03)
    box(c, "FetchChargeMeter", (0.29, -0.03, 0.10), (0.05, 0.36, 0.18), MATS["cyan"], bevel=0.02)
    paw_badge(c, (0.31, 0.14, -0.08))
    cobie_grip(c, (0.0, 0.31, -0.34))
    return c


def export_collection(collection: bpy.types.Collection, filename: str) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(collection.all_objects))
    bpy.ops.export_scene.gltf(
        filepath=str(EXPORT_DIR / filename),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_materials="EXPORT",
        export_yup=True,
    )


def main() -> None:
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    reset()
    setup_materials()
    collections = {
        "pawstol_viewmodel.glb": build_pawstol(),
        "barkshot_viewmodel.glb": build_barkshot(),
        "fetch_launcher_viewmodel.glb": build_fetch_launcher(),
    }
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    for filename, collection in collections.items():
        export_collection(collection, filename)
    print(f"Saved {SOURCE}")
    print(f"Exported {len(collections)} weapon viewmodels to {EXPORT_DIR}")


if __name__ == "__main__":
    main()
