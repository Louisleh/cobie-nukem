"""Build the project-original Rain City Run presentation foundry.

The resulting GLB is presentation-only: Godot's authored gameplay-layout scene
owns collision, navigation, checkpoints, hazards, and progression. Coordinates
are authored in Godot space and converted to Blender's Y-up glTF convention.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/blender/rain_city_run_foundry.blend"
OUTPUT = ROOT / "assets/models/environment/rain_city_run_foundry.glb"


def gp(x: float, y: float, z: float) -> tuple[float, float, float]:
    return (x, -z, y)


def reset() -> bpy.types.Collection:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    collection = bpy.data.collections.get("Collection")
    collection.name = "RAIN_CITY_RUN_FOUNDRY"
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.unit_settings.system = "METRIC"
    return collection


def material(name: str, color: tuple[float, float, float, float], metallic: float, roughness: float, emission: float = 0.0) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    mat["cobie_surface"] = name.lower()
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = color
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def box(target, name, pos, size, mat, bevel=0.04, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(location=gp(*pos), rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (size[0] * 0.5, size[2] * 0.5, size[1] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("RainSoftenedEdges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(mat)
    return obj


def cylinder_between(target, name, start, end, radius, mat, vertices=10):
    a = Vector(gp(*start))
    b = Vector(gp(*end))
    delta = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=(a + b) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    obj.data.materials.append(mat)
    return obj


def ridgeline(target, name, z, depth, profile, mat):
    """Build one opaque, lightly extruded mountain profile in Godot space."""
    front_z = z + depth * 0.5
    back_z = z - depth * 0.5
    outline = [(profile[0][0], 0.0), (profile[-1][0], 0.0), *reversed(profile)]
    front = [gp(x, y, front_z) for x, y in outline]
    back = [gp(x, y, back_z) for x, y in outline]
    edge_count = len(outline)
    faces = [tuple(range(edge_count)), tuple(reversed(range(edge_count, edge_count * 2)))]
    for index in range(edge_count):
        following = (index + 1) % edge_count
        faces.append((index, following, following + edge_count, index + edge_count))
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(front + back, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    target.objects.link(obj)
    return obj


def facade(target, name, pos, size, wall, glass, warm, floors=4, columns=4):
    box(target, f"{name}_Mass", pos, size, wall, 0.10)
    front_x = pos[0] + (size[0] * 0.5 + 0.03 if pos[0] < 0 else -(size[0] * 0.5 + 0.03))
    for floor in range(floors):
        y = pos[1] - size[1] * 0.38 + floor * (size[1] * 0.76 / max(1, floors - 1))
        for column in range(columns):
            z = pos[2] - size[2] * 0.38 + column * (size[2] * 0.76 / max(1, columns - 1))
            window_mat = warm if (floor + column) % 5 == 0 else glass
            box(target, f"{name}_Window_{floor}_{column}", (front_x, y, z), (0.07, size[1] / (floors * 1.7), size[2] / (columns * 1.6)), window_mat, 0.015)


def build_downtown(target, m):
    for index, z in enumerate((-9.0, 0.0, 9.0)):
        facade(target, f"WestTower{index}", (-8.4, 5.0 + index, z), (5.1, 10.0 + index * 2.0, 7.0), m["brick"], m["glass"], m["warm"], 5, 4)
        facade(target, f"EastTower{index}", (8.4, 4.0 + index * 0.6, z - 3.0), (5.0, 8.0 + index, 7.0), m["concrete"], m["glass"], m["warm"], 4, 4)
    for level in range(3):
        y = 2.0 + level * 1.8
        box(target, f"FireEscapeLanding{level}", (-5.75, y, -7.0), (1.8, 0.13, 1.5), m["steel"], 0.015)
        cylinder_between(target, f"FireEscapeBrace{level}", (-5.75, y, -7.0), (-7.0, y - 1.3, -5.5), 0.045, m["steel"])
    box(target, "RainShelter", (4.8, 2.0, 7.0), (5.4, 0.18, 2.5), m["yellow"], 0.04)


def build_slice(target, m):
    box(target, "SliceBrickMass", (-8.7, 2.15, -37.0), (6.6, 4.3, 15.5), m["brick"], 0.14)
    box(target, "SliceShopfront", (-5.35, 1.45, -37.0), (0.14, 2.7, 11.5), m["glass"], 0.03)
    for z in (-41.0, -37.0, -33.0):
        cylinder_between(target, f"SliceMullion{z}", (-5.2, 0.15, z), (-5.2, 2.8, z), 0.055, m["steel"])
    box(target, "SliceAwning", (-4.75, 2.75, -37.0), (1.5, 0.18, 12.5), m["orange"], 0.05)
    box(target, "SliceSignCan", (-4.6, 3.55, -37.0), (0.24, 1.0, 7.2), m["charcoal"], 0.05)
    for offset in (-2.4, -1.2, 0.0, 1.2, 2.4):
        box(target, f"SliceSignLamp{offset}", (-4.45, 3.55, -37.0 + offset), (0.08, 0.38, 0.55), m["warm"], 0.03)
    box(target, "SliceDeliveryWindow", (-5.17, 1.25, -43.0), (0.08, 1.6, 2.8), m["warm"], 0.04)
    cylinder_between(target, "ScooterFrame", (4.2, 0.45, -34.0), (5.4, 0.7, -34.0), 0.12, m["yellow"])
    for x in (4.25, 5.35):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.34, minor_radius=0.07, major_segments=16, minor_segments=6, location=gp(x, 0.35, -34.0), rotation=(math.pi / 2.0, 0.0, 0.0))
        bpy.context.object.data.materials.append(m["rubber"])


def build_seawall(target, m):
    for z in (-66.0, -74.0, -82.0, -88.0):
        box(target, f"SeawallBenchSeat{z}", (8.5, 0.58, z), (2.6, 0.16, 0.75), m["wood"], 0.04)
        for x in (7.55, 9.45):
            cylinder_between(target, f"SeawallBenchLeg{x}_{z}", (x, 0.05, z), (x, 0.56, z), 0.055, m["steel"])
    for z in (-69.0, -81.0):
        for x in (-12.0, -7.0):
            cylinder_between(target, f"CanopyPost{x}_{z}", (x, 0.0, z), (x, 4.8, z), 0.10, m["steel"])
        box(target, f"CanopyRoof{z}", (-9.5, 4.75, z), (5.4, 0.12, 4.6), m["glass"], 0.03)
    for z in range(-92, -56, 3):
        cylinder_between(target, f"HarbourRailPost{z}", (15.4, 0.05, z), (15.4, 1.25, z), 0.045, m["steel"])
    for y in (0.42, 1.1):
        cylinder_between(target, f"HarbourRail{y}", (15.4, y, -92), (15.4, y, -56), 0.055, m["steel"])


def build_terminal(target, m):
    for x in (-11.5, 11.5):
        for z in (-123.0, -115.0, -107.0, -99.0):
            cylinder_between(target, f"TerminalColumn{x}_{z}", (x, 0.0, z), (x, 6.2, z), 0.18, m["steel"], 12)
    for z in (-123.0, -115.0, -107.0, -99.0):
        cylinder_between(target, f"TerminalRoofTruss{z}", (-11.5, 6.2, z), (11.5, 6.2, z), 0.16, m["yellow"], 10)
    box(target, "TerminalControlGlass", (-5.9, 3.3, -116.0), (0.14, 2.7, 6.0), m["glass"], 0.03)
    for z in (-104.0, -112.0, -120.0):
        box(target, f"CargoMachineBody{z}", (5.7, 1.4, z), (3.3, 2.6, 2.5), m["steel"], 0.14)
        cylinder_between(target, f"CargoMachineRoller{z}", (4.1, 0.5, z), (7.3, 0.5, z), 0.22, m["rubber"], 12)
        box(target, f"CargoMachineLamp{z}", (4.0, 2.2, z), (0.10, 0.38, 0.38), m["cyan"], 0.03)


def build_pier(target, m):
    for x in (-13.0, 12.0):
        cylinder_between(target, f"CraneMast{x}", (x, 0.0, -167.0), (x, 11.0, -167.0), 0.32, m["yellow"], 12)
        cylinder_between(target, f"CraneArm{x}", (x, 10.5, -167.0), (x + 7.0, 10.5, -167.0), 0.26, m["yellow"], 12)
        cylinder_between(target, f"CraneCable{x}", (x + 6.0, 10.4, -167.0), (x + 6.0, 2.4, -167.0), 0.035, m["steel"], 8)
    for x in (-13.0, -6.0, 5.0, 12.0):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.36, depth=1.3, location=gp(x, 0.65, -169.0))
        bpy.context.object.data.materials.append(m["yellow"])
    box(target, "DepartureControlShell", (0.0, 1.7, -174.0), (3.5, 3.4, 1.6), m["charcoal"], 0.16)
    box(target, "DepartureControlScreen", (0.0, 1.9, -173.16), (2.2, 1.2, 0.08), m["cyan"], 0.03)


def build_harbour_backdrop(target, m):
    """Author a broad original harbour skyline and north-shore silhouette."""
    # The old shallow strip disappeared into the sky gradient from the seawall.
    # This low-poly layer stays presentation-only and reuses existing batches.
    skyline = (
        (-54.0, 18.0, 6.0, -218.0),
        (-44.0, 27.0, 5.0, -214.0),
        (-34.0, 21.0, 7.0, -220.0),
        (-23.0, 34.0, 5.0, -211.0),
        (-12.0, 24.0, 7.0, -216.0),
        (0.0, 31.0, 6.0, -212.0),
        (12.0, 20.0, 6.0, -219.0),
        (23.0, 29.0, 6.0, -214.0),
        (35.0, 19.0, 8.0, -220.0),
        (47.0, 26.0, 6.0, -215.0),
        (56.0, 16.0, 6.0, -219.0),
    )
    for index, (x, height, width, z) in enumerate(skyline):
        box(target, f"SkylineTower{index}", (x, height * 0.5, z), (width, height, 3.5), m["skyline"], 0.08)
        for floor in range(2, int(height), 5):
            light = m["warm"] if (index + floor) % 3 == 0 else m["cyan"]
            box(target, f"SkylineLight{index}_{floor}", (x, float(floor), z + 1.8), (width * 0.46, 0.34, 0.08), light, 0.01)

    # A fictional rain-line beacon gives the waterfront one readable vertical
    # punctuation mark without reproducing a real building or city logo.
    cylinder_between(target, "RainlineBeaconMast", (-23.0, 0.0, -208.0), (-23.0, 43.0, -208.0), 0.48, m["skyline"], 10)
    cylinder_between(target, "RainlineBeaconLight", (-23.0, 31.0, -208.0), (-23.0, 40.5, -208.0), 0.78, m["cyan"], 10)
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=2.4, radius2=0.35, depth=4.5, location=gp(-23.0, 45.25, -208.0))
    bpy.context.object.name = "RainlineBeaconCrown"
    bpy.context.object.data.materials.append(m["yellow"])

    far_ridge = (
        (-170.0, 0.0), (-150.0, 24.0), (-132.0, 38.0), (-112.0, 29.0),
        (-94.0, 54.0), (-76.0, 42.0), (-58.0, 69.0), (-37.0, 47.0),
        (-16.0, 62.0), (4.0, 43.0), (24.0, 76.0), (45.0, 55.0),
        (66.0, 70.0), (88.0, 39.0), (108.0, 57.0), (132.0, 31.0),
        (154.0, 20.0), (174.0, 0.0),
    )
    near_ridge = (
        (-150.0, 0.0), (-128.0, 18.0), (-108.0, 35.0), (-88.0, 23.0),
        (-66.0, 46.0), (-42.0, 31.0), (-20.0, 49.0), (2.0, 28.0),
        (24.0, 51.0), (48.0, 34.0), (72.0, 45.0), (96.0, 26.0),
        (122.0, 38.0), (150.0, 0.0),
    )
    ridgeline(target, "NorthShoreFarSilhouette", -278.0, 16.0, far_ridge, m["mountain"])
    ridgeline(target, "NorthShoreNearSilhouette", -248.0, 12.0, near_ridge, m["mountain"])


def consolidate_by_material(target: bpy.types.Collection) -> int:
    groups: dict[str, list[bpy.types.Object]] = {}
    for obj in list(target.objects):
        if obj.type != "MESH" or not obj.data.materials:
            continue
        groups.setdefault(obj.data.materials[0].name, []).append(obj)
    count = 0
    for material_name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.convert(target="MESH")
        bpy.ops.object.join()
        objects[0].name = f"RainCity_{material_name}_Batch"
        count += 1
    return count


def main() -> None:
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    target = reset()
    mats = {
        "charcoal": material("RC_Charcoal", (0.035, 0.055, 0.065, 1.0), 0.15, 0.63),
        "concrete": material("RC_WetConcrete", (0.22, 0.29, 0.31, 1.0), 0.02, 0.48),
        "brick": material("RC_RainBrick", (0.30, 0.12, 0.10, 1.0), 0.0, 0.64),
        "glass": material("RC_GlassPanels", (0.09, 0.26, 0.31, 1.0), 0.42, 0.20),
        "steel": material("RC_HarbourSteel", (0.24, 0.31, 0.32, 1.0), 0.74, 0.31),
        "yellow": material("RC_ComplianceYellow", (0.93, 0.52, 0.06, 1.0), 0.32, 0.34),
        "orange": material("RC_SliceOrange", (0.82, 0.19, 0.06, 1.0), 0.06, 0.46),
        "wood": material("RC_RainWood", (0.28, 0.15, 0.07, 1.0), 0.0, 0.72),
        "rubber": material("RC_Rubber", (0.015, 0.02, 0.022, 1.0), 0.0, 0.89),
        "warm": material("RC_WarmLight", (1.0, 0.48, 0.12, 1.0), 0.08, 0.25, 1.2),
        "cyan": material("RC_WayfindingCyan", (0.03, 0.78, 0.82, 1.0), 0.18, 0.22, 1.1),
        "skyline": material("RC_Skyline", (0.055, 0.11, 0.14, 1.0), 0.0, 0.86),
        "mountain": material("RC_Mountain", (0.10, 0.18, 0.20, 1.0), 0.0, 0.91),
    }
    build_downtown(target, mats)
    build_slice(target, mats)
    build_seawall(target, mats)
    build_terminal(target, mats)
    build_pier(target, mats)
    build_harbour_backdrop(target, mats)
    source_parts = len([obj for obj in target.objects if obj.type == "MESH"])
    batches = consolidate_by_material(target)
    bpy.context.scene["cobie_asset_id"] = "rain_city_run_foundry"
    bpy.context.scene["presentation_only"] = True
    bpy.context.scene["source_parts"] = source_parts
    bpy.context.scene["material_batches"] = batches
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", use_selection=True, export_apply=True, export_materials="EXPORT", export_yup=True)
    print(f"Rain City foundry: parts={source_parts} batches={batches}")
    print(f"Saved {SOURCE}")
    print(f"Exported {OUTPUT}")


if __name__ == "__main__":
    main()
