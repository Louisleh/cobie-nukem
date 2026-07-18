"""Build the project-original Mount Hood Whiteout visual-foundry pilot.

The GLB is presentation-only. It deliberately contains no collision,
navigation, checkpoint, encounter, or campaign ownership.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/blender/mount_hood_foundry.blend"
OUTPUT = ROOT / "assets/models/environment/mount_hood_foundry.glb"


def gp(x: float, y: float, z: float) -> tuple[float, float, float]:
    return (x, -z, y)


def reset() -> bpy.types.Collection:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    collection = bpy.data.collections.get("Collection")
    collection.name = "MOUNT_HOOD_WHITEOUT_FOUNDRY"
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.unit_settings.system = "METRIC"
    return collection


def material(name: str, color: tuple[float, float, float, float], metallic=0.0, roughness=0.7, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def box(name, pos, size, mat, bevel=0.06, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(location=gp(*pos), rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (size[0] * 0.5, size[2] * 0.5, size[1] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("SnowSoftenedEdges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(mat)
    return obj


def cylinder(name, pos, radius, depth, mat, vertices=10):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=gp(*pos))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def sphere(name, pos, radius, mat, segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=8, radius=radius, location=gp(*pos))
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def fir(name: str, x: float, z: float, scale: float, m) -> None:
    cylinder(f"{name}_Trunk", (x, scale * 1.25, z), 0.18 * scale, 2.5 * scale, m["timber"], 8)
    for level, y in enumerate((1.5, 2.5, 3.5)):
        bpy.ops.mesh.primitive_cone_add(
            vertices=10,
            radius1=(1.6 - level * 0.22) * scale,
            radius2=0.05,
            depth=2.4 * scale,
            location=gp(x, y * scale, z),
        )
        bpy.context.object.name = f"{name}_Needles_{level}"
        bpy.context.object.data.materials.append(m["fir"])
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=1.4 * scale, radius2=0.03, depth=0.45 * scale, location=gp(x, 4.55 * scale, z))
    bpy.context.object.name = f"{name}_SnowCap"
    bpy.context.object.data.materials.append(m["powder"])


def snowman(m) -> None:
    for index, (y, radius) in enumerate(((0.65, 0.72), (1.55, 0.56), (2.30, 0.42))):
        sphere(f"SnowmanBody{index}", (-4.5, y, -3.0), radius, m["powder"])
    cylinder("SnowmanHat", (-4.5, 2.83, -3.0), 0.43, 0.42, m["charcoal"], 16)
    box("SnowmanHatBrim", (-4.5, 2.61, -3.0), (1.05, 0.10, 1.05), m["charcoal"], 0.02)
    for x in (-4.68, -4.32):
        sphere(f"SnowmanEye{x}", (x, 2.38, -2.61), 0.055, m["charcoal"], 8)
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.11, radius2=0.01, depth=0.58, location=gp(-4.5, 2.25, -2.32), rotation=(math.pi / 2.0, 0.0, 0.0))
    bpy.context.object.name = "SnowmanCarrot"
    bpy.context.object.data.materials.append(m["orange"])
    box("SnowmanScarf", (-4.5, 1.93, -3.0), (1.05, 0.16, 0.95), m["orange"], 0.03)


def lodge(m) -> None:
    box("LodgeStoneBase", (6.5, 1.05, -11.0), (10.5, 2.1, 7.5), m["stone"], 0.14)
    box("LodgeTimberUpper", (6.5, 3.5, -11.0), (10.5, 2.8, 7.5), m["timber"], 0.12)
    # Original steep alpine roof; not based on a real lodge footprint.
    for side, roll in ((-1, -0.55), (1, 0.55)):
        roof = box(f"LodgeRoof{side}", (6.5 + side * 2.1, 5.35, -11.0), (6.5, 0.35, 9.2), m["packed"], 0.05)
        roof.rotation_euler[1] = roll
    for x in (3.2, 6.5, 9.8):
        box(f"LodgeWindow{x}", (x, 3.55, -7.20), (1.5, 1.25, 0.10), m["window"], 0.03)
    box("LodgeDoor", (6.5, 1.5, -7.15), (1.6, 3.0, 0.12), m["timber"], 0.05)
    box("LodgeChimney", (9.2, 6.0, -12.0), (1.0, 3.3, 1.1), m["stone"], 0.08)


def mountain(m) -> None:
    # Layered low-poly original silhouette, fixed northward bearing.
    for index, (x, y, z, radius, depth) in enumerate((
        (0.0, 15.0, -72.0, 24.0, 32.0),
        (-12.0, 10.0, -66.0, 16.0, 21.0),
        (13.0, 9.0, -68.0, 15.0, 19.0),
    )):
        bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=radius, radius2=0.5, depth=depth, location=gp(x, y, z))
        bpy.context.object.name = f"MountHoodMass{index}"
        bpy.context.object.data.materials.append(m["rock"])
    bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=12.0, radius2=0.4, depth=13.5, location=gp(0.0, 25.5, -71.5))
    bpy.context.object.name = "MountHoodSnowCap"
    bpy.context.object.data.materials.append(m["powder"])


def lift(m) -> None:
    for index, x in enumerate((-11.5, -1.0, 10.0)):
        cylinder(f"LiftTower{index}", (x, 4.0, -24.0), 0.22, 8.0, m["steel"], 12)
        box(f"LiftCrossbar{index}", (x, 7.6, -24.0), (4.2, 0.28, 0.35), m["steel"], 0.03)
    cable = box("LiftCable", (-0.75, 7.82, -24.0), (26.0, 0.07, 0.07), m["charcoal"], 0.0)
    for index, x in enumerate((-7.0, 4.0)):
        cylinder(f"LiftChairDrop{index}", (x, 6.7, -24.0), 0.045, 2.0, m["steel"], 8)
        box(f"LiftChairSeat{index}", (x, 5.75, -24.0), (1.8, 0.16, 0.8), m["orange"], 0.04)


def consolidate(collection: bpy.types.Collection) -> int:
    groups: dict[str, list[bpy.types.Object]] = {}
    for obj in list(collection.objects):
        if obj.type == "MESH" and obj.data.materials:
            groups.setdefault(obj.data.materials[0].name, []).append(obj)
    for material_name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.convert(target="MESH")
        bpy.ops.object.join()
        objects[0].name = f"MountHood_{material_name}_Batch"
    return len(groups)


def main() -> None:
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    target = reset()
    m = {
        "powder": material("MH_FreshPowder", (0.82, 0.91, 0.96, 1.0), roughness=0.76),
        "packed": material("MH_PackedSnow", (0.58, 0.73, 0.81, 1.0), roughness=0.62),
        "asphalt": material("MH_PlowedAsphalt", (0.06, 0.09, 0.11, 1.0), roughness=0.48),
        "timber": material("MH_LodgeTimber", (0.29, 0.13, 0.05, 1.0), roughness=0.71),
        "stone": material("MH_LodgeStone", (0.31, 0.31, 0.28, 1.0), roughness=0.82),
        "steel": material("MH_LiftSteel", (0.28, 0.34, 0.36, 1.0), metallic=0.72, roughness=0.38),
        "window": material("MH_WarmWindows", (1.0, 0.47, 0.12, 1.0), roughness=0.24, emission=1.4),
        "rock": material("MH_ExposedRock", (0.19, 0.22, 0.23, 1.0), roughness=0.88),
        "fir": material("MH_FirNeedles", (0.025, 0.16, 0.13, 1.0), roughness=0.83),
        "charcoal": material("MH_Charcoal", (0.025, 0.035, 0.045, 1.0), roughness=0.75),
        "orange": material("MH_TrailOrange", (0.94, 0.28, 0.04, 1.0), roughness=0.46),
    }
    box("PlowedRoad", (0.0, -0.10, 3.5), (18.0, 0.20, 34.0), m["asphalt"], 0.02)
    for side in (-1, 1):
        for index, z in enumerate((14.0, 7.0, 0.0, -7.0)):
            box(f"Snowbank{side}_{index}", (side * 10.0, 0.65 + (index % 2) * 0.2, z), (4.4, 1.5, 7.0), m["packed"], 0.45, rotation=(0.0, 0.12 * side, 0.0))
    for index, (x, z, scale) in enumerate(((-14, 6, 1.0), (-13, -9, 1.25), (14, 5, 1.15), (15, -12, 1.35), (-17, -24, 1.5), (16, -27, 1.4))):
        fir(f"Fir{index}", x, z, scale, m)
    snowman(m)
    lodge(m)
    mountain(m)
    lift(m)
    cylinder("RoadSignPost", (-6.7, 1.4, 9.0), 0.10, 2.8, m["steel"], 10)
    box("RoadSign", (-6.7, 2.75, 9.0), (4.5, 1.3, 0.16), m["orange"], 0.05)
    box("RouteArrow", (-6.7, 2.75, 8.88), (2.5, 0.18, 0.05), m["charcoal"], 0.02)
    source_parts = len([obj for obj in target.objects if obj.type == "MESH"])
    batches = consolidate(target)
    bpy.context.scene["cobie_asset_id"] = "mount_hood_whiteout_foundry"
    bpy.context.scene["presentation_only"] = True
    bpy.context.scene["collision_owner"] = "none"
    bpy.context.scene["navigation_owner"] = "none"
    bpy.context.scene["source_parts"] = source_parts
    bpy.context.scene["material_batches"] = batches
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", use_selection=True, export_apply=True, export_materials="EXPORT", export_yup=True)
    print(f"Mount Hood foundry: parts={source_parts} batches={batches}")
    print(f"Saved {SOURCE}")
    print(f"Exported {OUTPUT}")


if __name__ == "__main__":
    main()
