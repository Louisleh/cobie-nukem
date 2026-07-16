"""Build the project-original Salmon Creek opening presentation kit.

Run with Blender 5.1+:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python tools/blender/build_salmon_opening_foundry.py

The export is presentation-only. Salmon Creek's existing Godot collision and
navigation remain authoritative. Blender coordinates are converted from Godot
X/Y/Z into Blender X/-Z/Y so the GLB can be instanced at the level origin.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/blender/salmon_creek_opening_foundry.blend"
OUTPUT = ROOT / "assets/models/environment/salmon_creek_opening_foundry.glb"


def godot_position(x: float, y: float, z: float) -> tuple[float, float, float]:
    return (x, -z, y)


def reset_scene() -> bpy.types.Collection:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    target = bpy.data.collections.get("Collection")
    target.name = "SALMON_OPENING_FOUNDRY"
    return target


def material(
    name: str,
    color: tuple[float, float, float, float],
    metallic: float,
    roughness: float,
    emission: float = 0.0,
) -> bpy.types.Material:
    result = bpy.data.materials.new(name)
    result.diffuse_color = color
    result.use_nodes = True
    result["cobie_surface"] = name.lower().replace(" ", "_")
    bsdf = result.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        emission_color = bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")
        emission_strength = bsdf.inputs.get("Emission Strength")
        if emission_color is not None:
            emission_color.default_value = color
        if emission_strength is not None:
            emission_strength.default_value = emission
    return result


def move_to(obj: bpy.types.Object, target: bpy.types.Collection) -> bpy.types.Object:
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    target.objects.link(obj)
    return obj


def box(
    target: bpy.types.Collection,
    name: str,
    position: tuple[float, float, float],
    size: tuple[float, float, float],
    mat: bpy.types.Material,
    bevel: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=godot_position(*position))
    obj = move_to(bpy.context.object, target)
    obj.name = name
    # Convert Godot X/Y/Z size into Blender X/Z/Y.
    obj.scale = (size[0] * 0.5, size[2] * 0.5, size[1] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new("EdgeSoftening", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    obj.data.materials.append(mat)
    return obj


def cylinder_between(
    target: bpy.types.Collection,
    name: str,
    start_godot: tuple[float, float, float],
    end_godot: tuple[float, float, float],
    radius: float,
    mat: bpy.types.Material,
    vertices: int = 10,
) -> bpy.types.Object:
    start = Vector(godot_position(*start_godot))
    end = Vector(godot_position(*end_godot))
    delta = end - start
    midpoint = (start + end) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=midpoint)
    obj = move_to(bpy.context.object, target)
    obj.name = name
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    obj.data.materials.append(mat)
    return obj


def cone(
    target: bpy.types.Collection,
    name: str,
    position: tuple[float, float, float],
    radius: float,
    height: float,
    mat: bpy.types.Material,
    vertices: int = 10,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius,
        radius2=0.05,
        depth=height,
        location=godot_position(position[0], position[1] + height * 0.5, position[2]),
    )
    obj = move_to(bpy.context.object, target)
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def build_goal(target: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    metal = mats["cream"]
    net = mats["net"]
    z = -15.5
    for x in (-5.0, 5.0):
        cylinder_between(target, f"GoalPost_{x:+.0f}", (x, 0.05, z), (x, 2.8, z), 0.075, metal, 12)
    cylinder_between(target, "GoalCrossbar", (-5.0, 2.8, z), (5.0, 2.8, z), 0.075, metal, 12)
    # Readable opaque rope grid; no transparency-heavy material on Web.
    for x in range(-5, 6):
        cylinder_between(target, f"GoalNetVertical_{x}", (x, 0.08, z + 0.08), (x, 2.7, z + 0.08), 0.012, net, 6)
    for row in range(1, 7):
        y = row * 0.4
        cylinder_between(target, f"GoalNetHorizontal_{row}", (-4.9, y, z + 0.08), (4.9, y, z + 0.08), 0.012, net, 6)


def build_fence(target: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    metal = mats["steel"]
    for side in (-12.2, 12.2):
        for z in range(-17, 19, 3):
            cylinder_between(target, f"FencePost_{side}_{z}", (side, 0.0, z), (side, 2.15, z), 0.045, metal, 8)
        for height in (0.15, 1.1, 2.05):
            cylinder_between(target, f"FenceRail_{side}_{height}", (side, height, -17), (side, height, 17), 0.025, metal, 8)
        # Alternating diagonals imply chain link without a transparent sheet.
        for z in range(-17, 17, 2):
            cylinder_between(target, f"FenceLinkA_{side}_{z}", (side, 0.18, z), (side, 2.02, z + 2), 0.009, metal, 5)
            cylinder_between(target, f"FenceLinkB_{side}_{z}", (side, 2.02, z), (side, 0.18, z + 2), 0.009, metal, 5)


def build_bleachers(target: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    steel = mats["steel"]
    cedar = mats["cedar"]
    for row in range(4):
        z = 5.4 + row * 0.72
        y = 0.34 + row * 0.42
        box(target, f"BleacherSeat_{row}", (9.5, y, z), (4.8, 0.14, 0.58), cedar, 0.035)
        box(target, f"BleacherRiser_{row}", (9.5, y * 0.5, z + 0.25), (4.5, max(0.18, y), 0.08), steel)
    for x in (7.5, 9.5, 11.5):
        cylinder_between(target, f"BleacherLeg_{x}", (x, 0.0, 5.2), (x, 1.75, 7.9), 0.05, steel, 8)


def build_scoreboard_and_lights(target: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    steel = mats["steel"]
    charcoal = mats["charcoal"]
    yellow = mats["yellow"]
    lamp = mats["lamp"]
    box(target, "ScoreboardFrame", (-10.7, 3.0, -12.5), (0.38, 5.8, 4.2), steel, 0.04)
    box(target, "ScoreboardFace", (-10.45, 3.45, -12.5), (0.12, 2.9, 3.7), charcoal, 0.03)
    for y in (2.75, 3.45, 4.15):
        box(target, f"ScoreboardStripe_{y}", (-10.36, y, -12.5), (0.04, 0.09, 3.15), yellow)
    for x in (-10.8, 10.8):
        for z in (-13.8, 12.8):
            cylinder_between(target, f"FloodlightMast_{x}_{z}", (x, 0.0, z), (x, 7.8, z), 0.105, steel, 10)
            box(target, f"FloodlightBank_{x}_{z}", (x, 7.95, z), (0.42, 0.75, 2.7), charcoal, 0.04)
            for offset in (-0.85, 0.0, 0.85):
                box(target, f"FloodlightLamp_{x}_{z}_{offset}", (x - 0.23, 7.98, z + offset), (0.035, 0.38, 0.52), lamp, 0.025)


def build_dugout_and_props(target: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    cedar = mats["cedar"]
    steel = mats["steel"]
    yellow = mats["yellow"]
    charcoal = mats["charcoal"]
    # A strong near-field landmark at the shed transition.
    for x in (-7.0, -3.2):
        box(target, f"DugoutPost_{x}", (x, 1.45, -17.4), (0.16, 2.9, 0.16), cedar, 0.025)
    box(target, "DugoutRoof", (-5.1, 2.9, -17.4), (4.2, 0.18, 2.1), charcoal, 0.05)
    box(target, "DugoutBack", (-5.1, 1.4, -18.35), (4.2, 2.8, 0.16), cedar, 0.025)
    box(target, "DugoutBench", (-5.1, 0.62, -17.65), (3.6, 0.16, 0.55), cedar, 0.035)
    for index in range(5):
        x = -9.0 + index * 1.15
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.22, radius2=0.07, depth=0.55, location=godot_position(x, 0.275, 7.5))
        cone_obj = move_to(bpy.context.object, target)
        cone_obj.name = f"SafetyCone_{index}"
        cone_obj.data.materials.append(yellow)
    for z in (-10.0, 0.0, 10.0):
        box(target, f"DrainageGrateLeft_{z}", (-9.65, 0.025, z), (1.3, 0.04, 0.45), steel, 0.015)
        box(target, f"DrainageGrateRight_{z}", (9.65, 0.025, z), (1.3, 0.04, 0.45), steel, 0.015)


def build_evergreens(target: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    cedar = mats["cedar"]
    green = mats["evergreen"]
    positions = [(-17, 12), (-18, 3), (-16.5, -8), (17, 11), (18, 1), (17, -12)]
    for index, (x, z) in enumerate(positions):
        cylinder_between(target, f"EvergreenTrunk_{index}", (x, 0, z), (x, 2.5, z), 0.20, cedar, 9)
        cone(target, f"EvergreenLower_{index}", (x, 1.2, z), 1.65, 3.9, green, 11)
        cone(target, f"EvergreenUpper_{index}", (x, 3.2, z), 1.25, 3.4, green, 11)


def consolidate_by_material(target: bpy.types.Collection) -> None:
    groups: dict[str, list[bpy.types.Object]] = {}
    for obj in list(target.objects):
        if obj.type != "MESH" or not obj.data.materials:
            continue
        groups.setdefault(obj.data.materials[0].name, []).append(obj)
    for material_name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        joined = bpy.context.object
        joined.name = "OpeningKit_" + material_name.replace(" ", "_")
        # Blender's join operator keeps one slot per source object even when
        # every slot references the same material. glTF turns those duplicate
        # slots into separate surfaces/draw calls, defeating consolidation.
        for polygon in joined.data.polygons:
            polygon.material_index = 0
        joined.data.materials.clear()
        joined.data.materials.append(bpy.data.materials[material_name])
        joined["source_part_count"] = len(objects)
        joined["presentation_only"] = True


def main() -> None:
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    target = reset_scene()
    mats = {
        "charcoal": material("Storm Charcoal", (0.025, 0.045, 0.052, 1.0), 0.35, 0.42),
        "steel": material("Rain Municipal Steel", (0.20, 0.28, 0.29, 1.0), 0.62, 0.34),
        "cream": material("Field Cream", (0.78, 0.82, 0.75, 1.0), 0.1, 0.56),
        "net": material("Goal Rope", (0.58, 0.68, 0.63, 1.0), 0.0, 0.82),
        "cedar": material("Rain Darkened Cedar", (0.19, 0.075, 0.028, 1.0), 0.0, 0.76),
        "yellow": material("Tennis Safety Yellow", (0.92, 0.48, 0.035, 1.0), 0.08, 0.38),
        "lamp": material("Floodlight Emission", (0.62, 0.82, 0.73, 1.0), 0.0, 0.22, 2.0),
        "evergreen": material("PNW Evergreen", (0.025, 0.16, 0.105, 1.0), 0.0, 0.88),
    }
    build_goal(target, mats)
    build_fence(target, mats)
    build_bleachers(target, mats)
    build_scoreboard_and_lights(target, mats)
    build_dugout_and_props(target, mats)
    build_evergreens(target, mats)
    source_parts = len([obj for obj in target.objects if obj.type == "MESH"])
    consolidate_by_material(target)
    target["cobie_asset_id"] = "salmon_creek_opening_foundry"
    target["category"] = "environment_presentation_kit"
    target["license"] = "Project-original; Blender primitives and built-in material nodes only"
    target["presentation_only"] = True
    target["source_part_count"] = source_parts
    bpy.context.scene["cobie_visual_foundry_version"] = 1
    bpy.context.scene["coordinate_contract"] = "Godot X/Y/Z -> Blender X/-Z/Y; GLB instanced at level origin"
    bpy.context.scene["gameplay_contract"] = "presentation only; Godot collision/navigation authoritative"
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE), compress=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in target.objects:
        if obj.type == "MESH":
            obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_extras=True,
    )
    print(f"COBIE_SALMON_OPENING_FOUNDRY: PASS parts={source_parts} consolidated={len(target.objects)}")


if __name__ == "__main__":
    main()
