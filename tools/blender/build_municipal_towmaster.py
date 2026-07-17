"""Build the project-original Municipal Towmaster convoy vehicle.

The GLB is presentation-only. Citation module WorldInteractions, collision,
movement, phase gating, and damage stay authoritative in Godot.
"""

from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/blender/municipal_towmaster.blend"
OUTPUT = ROOT / "assets/models/set_pieces/municipal_towmaster.glb"


def gp(x: float, y: float, z: float):
    return (x, -z, y)


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)
    collection = bpy.context.collection
    collection.name = "MUNICIPAL_TOWMASTER"
    return collection


def material(name, color, metallic, roughness, emission=0.0):
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


def box(name, pos, size, mat, bevel=0.05):
    bpy.ops.mesh.primitive_cube_add(location=gp(*pos))
    obj = bpy.context.object
    obj.name = name
    obj.scale = (size[0] * 0.5, size[2] * 0.5, size[1] * 0.5)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("TowmasterEdge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(mat)
    return obj


def cylinder(name, pos, radius, depth, mat, rotation=(0.0, 0.0, 0.0), vertices=14):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=gp(*pos), rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def consolidate():
    groups = {}
    for obj in list(bpy.context.collection.objects):
        if obj.type == "MESH" and obj.data.materials:
            groups.setdefault(obj.data.materials[0].name, []).append(obj)
    for mat_name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.convert(target="MESH")
        bpy.ops.object.join()
        objects[0].name = f"Towmaster_{mat_name}_Batch"
    return len(groups)


def main():
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    reset()
    mats = {
        "body": material("Towmaster_Navy", (0.025, 0.07, 0.09, 1.0), 0.65, 0.25),
        "panel": material("Towmaster_ComplianceGold", (0.92, 0.43, 0.035, 1.0), 0.35, 0.30),
        "glass": material("Towmaster_Glass", (0.035, 0.25, 0.33, 1.0), 0.42, 0.16),
        "rubber": material("Towmaster_Rubber", (0.012, 0.018, 0.02, 1.0), 0.0, 0.90),
        "paper": material("Towmaster_TicketPaper", (0.92, 0.86, 0.67, 1.0), 0.0, 0.72),
        "signal": material("Towmaster_Warning", (1.0, 0.11, 0.025, 1.0), 0.12, 0.20, 3.0),
    }
    box("ArmouredChassis", (0, 0.72, 0.0), (3.5, 0.70, 5.1), mats["body"], 0.16)
    box("Cabin", (0, 1.48, -1.15), (3.0, 1.38, 2.25), mats["panel"], 0.20)
    box("CabinGlass", (0, 1.62, -2.30), (2.25, 0.72, 0.10), mats["glass"], 0.05)
    box("RearCitationVault", (0, 1.45, 1.20), (3.05, 1.40, 2.55), mats["body"], 0.16)
    box("CitationOutput", (0, 1.62, 2.51), (2.25, 0.52, 0.12), mats["paper"], 0.04)
    for x in (-1.18, 1.18):
        for z in (-1.45, 1.35):
            cylinder(f"Wheel_{x}_{z}", (x, 0.48, z), 0.47, 0.34, mats["rubber"], rotation=(0.0, 1.5708, 0.0), vertices=16)
            cylinder(f"Hub_{x}_{z}", (x, 0.48, z), 0.18, 0.37, mats["panel"], rotation=(0.0, 1.5708, 0.0), vertices=14)
    box("FrontBumper", (0, 0.62, -2.63), (3.65, 0.34, 0.22), mats["panel"], 0.07)
    box("TowFork", (0, 0.42, 2.85), (1.65, 0.22, 1.0), mats["panel"], 0.08)
    box("RoofBar", (0, 2.28, -0.72), (2.28, 0.16, 0.24), mats["body"], 0.04)
    for x in (-0.78, 0.0, 0.78):
        box(f"WarningLamp{x}", (x, 2.39, -0.72), (0.40, 0.18, 0.28), mats["signal"], 0.06)
    for index, x in enumerate((-0.78, -0.26, 0.26, 0.78)):
        box(f"CitationStrip{index}", (x, 1.58, 2.59), (0.38, 0.33, 0.035), mats["paper"], 0.01)
    batch_count = consolidate()
    bpy.context.scene["cobie_asset_id"] = "municipal_towmaster"
    bpy.context.scene["presentation_only"] = True
    bpy.context.scene["material_batches"] = batch_count
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT), export_format="GLB", use_selection=True, export_apply=True, export_materials="EXPORT", export_yup=True)
    print(f"Municipal Towmaster: {batch_count} Web-safe material batches")
    print(f"Saved {SOURCE}")
    print(f"Exported {OUTPUT}")


if __name__ == "__main__":
    main()
