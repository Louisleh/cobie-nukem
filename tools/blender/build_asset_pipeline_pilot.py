"""Build the original Cobie production-pipeline pilot with Blender 5.1.

Run with:
  /Applications/Blender.app/Contents/MacOS/Blender --background \
    --python tools/blender/build_asset_pipeline_pilot.py

The script uses Blender primitives and built-in materials only. It writes one
editable source scene, five deterministic GLB exports, and five transparent
direction/reaction frames for an original low-poly sentry experiment.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/blender/cobie_production_pilot.blend"
MODEL_DIR = ROOT / "assets/models/pilot"
SPRITE_DIR = ROOT / "assets/sprites/experiments/compliance_sentry"


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    root = bpy.data.collections.get("Collection")
    root.name = "PILOT_ROOT"


def material(name: str, color: tuple[float, float, float, float], metallic: float = 0.0, roughness: float = 0.7) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def collection(name: str) -> bpy.types.Collection:
    result = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(result)
    return result


def move_to(obj: bpy.types.Object, target: bpy.types.Collection) -> bpy.types.Object:
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    target.objects.link(obj)
    return obj


def box(target: bpy.types.Collection, name: str, location: tuple[float, float, float], scale: tuple[float, float, float], mat: bpy.types.Material | None = None, bevel: float = 0.0) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = move_to(bpy.context.object, target)
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new("EdgeSoftening", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
    if mat:
        obj.data.materials.append(mat)
    return obj


def cylinder(target: bpy.types.Collection, name: str, location: tuple[float, float, float], radius: float, depth: float, mat: bpy.types.Material | None = None, vertices: int = 12, rotation: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = move_to(bpy.context.object, target)
    obj.name = name
    if mat:
        obj.data.materials.append(mat)
    return obj


def uv_sphere(target: bpy.types.Collection, name: str, location: tuple[float, float, float], radius: float, mat: bpy.types.Material | None = None, segments: int = 16, rings: int = 8) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=radius, location=location)
    obj = move_to(bpy.context.object, target)
    obj.name = name
    if mat:
        obj.data.materials.append(mat)
    return obj


def tag_collection(target: bpy.types.Collection, asset_id: str, category: str, lod: str = "") -> None:
    target["cobie_asset_id"] = asset_id
    target["category"] = category
    target["units"] = "meters"
    target["forward_axis"] = "-Z"
    target["up_axis"] = "+Y"
    if lod:
        target["lod_contract"] = lod


def build_field_kit(mats: dict[str, bpy.types.Material]) -> bpy.types.Collection:
    target = collection("FIELD_PROP_FAMILY")
    tag_collection(target, "salmon_creek_field_kit", "environment_prop_family")
    # Bench: deliberately readable broad forms and a single collision hull.
    for index, z in enumerate((0.55, 0.83)):
        box(target, f"Bench_Slat_{index}", (0.0, 0.0, z), (1.65, 0.17, 0.09), mats["wood"], 0.025)
    for x in (-1.25, 1.25):
        box(target, f"Bench_Leg_{'L' if x < 0 else 'R'}", (x, 0.0, 0.28), (0.12, 0.28, 0.32), mats["charcoal"], 0.02)
    box(target, "Bench-colonly", (0.0, 0.0, 0.52), (1.72, 0.34, 0.46))
    # Portable safety barricade, sharing the kit palette.
    for x in (-2.1, -0.4):
        box(target, f"Barrier_Post_{x}", (x, 1.3, 0.62), (0.08, 0.08, 0.62), mats["yellow"])
        box(target, f"Barrier_Foot_{x}", (x, 1.3, 0.06), (0.33, 0.13, 0.06), mats["charcoal"])
    box(target, "Barrier_Board", (-1.25, 1.3, 0.72), (1.02, 0.09, 0.18), mats["yellow"], 0.025)
    box(target, "Barrier-colonly", (-1.25, 1.3, 0.65), (1.08, 0.16, 0.65))
    return target


def build_tunnel_module(mats: dict[str, bpy.types.Material]) -> bpy.types.Collection:
    target = collection("TUNNEL_MODULE")
    tag_collection(target, "maintenance_tunnel_module_a", "modular_structure")
    box(target, "Floor", (0.0, 0.0, 0.0), (2.5, 3.0, 0.12), mats["concrete"])
    box(target, "Wall_L", (-2.38, 0.0, 1.5), (0.12, 3.0, 1.5), mats["concrete"])
    box(target, "Wall_R", (2.38, 0.0, 1.5), (0.12, 3.0, 1.5), mats["concrete"])
    box(target, "Ceiling", (0.0, 0.0, 3.0), (2.5, 3.0, 0.12), mats["charcoal"])
    for y in (-2.7, 0.0, 2.7):
        box(target, f"Ceiling_Beam_{y}", (0.0, y, 2.82), (2.24, 0.10, 0.10), mats["yellow"])
    box(target, "Floor-colonly", (0.0, 0.0, 0.0), (2.5, 3.0, 0.12))
    box(target, "Wall_L-colonly", (-2.38, 0.0, 1.5), (0.12, 3.0, 1.5))
    box(target, "Wall_R-colonly", (2.38, 0.0, 1.5), (0.12, 3.0, 1.5))
    box(target, "Ceiling-colonly", (0.0, 0.0, 3.0), (2.5, 3.0, 0.12))
    return target


def build_lod_crate(mats: dict[str, bpy.types.Material]) -> bpy.types.Collection:
    target = collection("LOD_CRATE")
    tag_collection(target, "compliance_supply_crate_lod", "lod_test", "LOD0=0-18m;LOD1=18-35m;LOD2=35m+")
    lod0 = box(target, "LOD0_Crate", (0.0, 0.0, 0.65), (0.8, 0.65, 0.65), mats["charcoal"], 0.04)
    for x in (-0.72, 0.72):
        box(target, f"LOD0_Rail_{x}", (x, 0.0, 0.65), (0.08, 0.70, 0.72), mats["yellow"])
    lod1 = box(target, "LOD1_Crate", (2.2, 0.0, 0.65), (0.8, 0.65, 0.65), mats["charcoal"])
    lod2 = box(target, "LOD2_Crate", (4.4, 0.0, 0.65), (0.8, 0.65, 0.65), mats["charcoal"])
    for obj, level in ((lod0, 0), (lod1, 1), (lod2, 2)):
        obj["lod_level"] = level
    box(target, "Crate-colonly", (0.0, 0.0, 0.65), (0.8, 0.65, 0.65))
    return target


def build_pickup_pedestal(mats: dict[str, bpy.types.Material]) -> bpy.types.Collection:
    target = collection("PICKUP_PEDESTAL")
    tag_collection(target, "fetch_charge_pedestal", "pickup_presentation_experiment")
    cylinder(target, "Base", (0.0, 0.0, 0.18), 0.75, 0.36, mats["charcoal"], 16)
    cylinder(target, "Glow_Ring", (0.0, 0.0, 0.39), 0.55, 0.10, mats["cyan"], 24)
    uv_sphere(target, "Fetch_Charge", (0.0, 0.0, 1.05), 0.34, mats["tennis"], 20, 10)
    for angle in range(0, 360, 90):
        radians = math.radians(angle)
        cylinder(target, f"Guard_{angle}", (0.50 * math.cos(radians), 0.50 * math.sin(radians), 0.70), 0.035, 0.72, mats["yellow"], 8)
    box(target, "Pedestal-colonly", (0.0, 0.0, 0.28), (0.72, 0.72, 0.28))
    return target


def build_vancouver_beacon(mats: dict[str, bpy.types.Material]) -> bpy.types.Collection:
    target = collection("VANCOUVER_BEACON")
    tag_collection(target, "rain_city_wayfinding_beacon", "future_level_landmark")
    cylinder(target, "Foundation", (0.0, 0.0, 0.18), 1.10, 0.36, mats["concrete"], 16)
    cylinder(target, "Mast", (0.0, 0.0, 2.15), 0.18, 3.95, mats["charcoal"], 12)
    for height, radius in ((1.2, 0.78), (2.2, 0.64), (3.2, 0.48)):
        cylinder(target, f"Rain_Ring_{height}", (0.0, 0.0, height), radius, 0.12, mats["cyan"], 24)
    box(target, "Original_Wave_Mark", (0.0, -0.22, 3.85), (0.72, 0.10, 0.28), mats["yellow"], 0.04)
    cylinder(target, "Beacon-colonly", (0.0, 0.0, 2.0), 0.85, 4.0, None, 10)
    return target


def build_sentry(mats: dict[str, bpy.types.Material]) -> bpy.types.Collection:
    target = collection("DIRECTIONAL_SENTRY")
    tag_collection(target, "compliance_sentry_directional_experiment", "enemy_directional_reaction_experiment")
    body = box(target, "Sentry_Body", (0.0, 0.0, 1.25), (0.58, 0.38, 0.48), mats["charcoal"], 0.08)
    body["front_axis"] = "-Y"
    uv_sphere(target, "Sentry_Eye", (0.0, -0.42, 1.36), 0.18, mats["red"], 16, 8)
    cylinder(target, "Rotor", (0.0, 0.0, 1.92), 0.64, 0.06, mats["yellow"], 12)
    for x in (-0.72, 0.72):
        box(target, f"Claw_Arm_{x}", (x, 0.0, 0.88), (0.20, 0.14, 0.12), mats["yellow"], 0.03)
        cylinder(target, f"Thruster_{x}", (x, 0.0, 0.48), 0.18, 0.34, mats["cyan"], 12)
    return target


def select_collection(target: bpy.types.Collection) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in target.all_objects:
        if obj.type == "MESH":
            obj.select_set(True)


def export_collection(target: bpy.types.Collection, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    select_collection(target)
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_extras=True,
    )


def look_at(obj: bpy.types.Object, point: tuple[float, float, float]) -> None:
    direction = Vector(point) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_sentry(target: bpy.types.Collection, mats: dict[str, bpy.types.Material]) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 384
    scene.render.resolution_y = 384
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    camera_data = bpy.data.cameras.new("PilotCamera")
    camera = bpy.data.objects.new("PilotCamera", camera_data)
    scene.collection.objects.link(camera)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 3.25
    scene.camera = camera
    key_data = bpy.data.lights.new("Key", "AREA")
    key_data.energy = 900
    key_data.shape = "DISK"
    key_data.size = 5.0
    key = bpy.data.objects.new("Key", key_data)
    scene.collection.objects.link(key)
    key.location = (3.0, -4.0, 6.0)
    look_at(key, (0.0, 0.0, 1.0))
    fill_data = bpy.data.lights.new("Fill", "AREA")
    fill_data.energy = 450
    fill_data.size = 4.0
    fill = bpy.data.objects.new("Fill", fill_data)
    scene.collection.objects.link(fill)
    fill.location = (-4.0, 2.0, 3.0)
    look_at(fill, (0.0, 0.0, 1.0))
    for other in bpy.context.scene.objects:
        if other.type == "MESH":
            other.hide_render = other.name not in {obj.name for obj in target.all_objects}
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    directions = {
        "front": (0.0, -6.0, 2.0),
        "right": (6.0, 0.0, 2.0),
        "back": (0.0, 6.0, 2.0),
        "left": (-6.0, 0.0, 2.0),
    }
    for name, position in directions.items():
        camera.location = position
        look_at(camera, (0.0, 0.0, 1.05))
        scene.render.filepath = str(SPRITE_DIR / f"sentry_{name}.png")
        bpy.ops.render.render(write_still=True)
    body = bpy.data.objects["Sentry_Body"]
    original_rotation = body.rotation_euler.copy()
    body.rotation_euler.z = math.radians(14.0)
    body.data.materials.clear()
    body.data.materials.append(mats["hit"])
    camera.location = (0.0, -6.0, 2.0)
    look_at(camera, (0.0, 0.0, 1.05))
    scene.render.filepath = str(SPRITE_DIR / "sentry_hit_front.png")
    bpy.ops.render.render(write_still=True)
    body.rotation_euler = original_rotation
    body.data.materials.clear()
    body.data.materials.append(mats["charcoal"])


def main() -> None:
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    reset_scene()
    mats = {
        "charcoal": material("Wet Asphalt", (0.045, 0.065, 0.075, 1.0), 0.45, 0.42),
        "yellow": material("Safety Yellow", (1.0, 0.48, 0.035, 1.0), 0.15, 0.38),
        "cyan": material("Rain Cyan", (0.03, 0.62, 0.78, 1.0), 0.25, 0.28),
        "concrete": material("PNW Concrete", (0.19, 0.23, 0.24, 1.0), 0.0, 0.92),
        "wood": material("Wet Cedar", (0.24, 0.11, 0.045, 1.0), 0.0, 0.76),
        "tennis": material("Tennis Charge", (0.68, 0.95, 0.08, 1.0), 0.0, 0.35),
        "red": material("Scanner Red", (0.92, 0.025, 0.02, 1.0), 0.1, 0.25),
        "hit": material("Hit Flash", (1.0, 0.16, 0.03, 1.0), 0.0, 0.22),
    }
    field = build_field_kit(mats)
    tunnel = build_tunnel_module(mats)
    lod = build_lod_crate(mats)
    pickup = build_pickup_pedestal(mats)
    beacon = build_vancouver_beacon(mats)
    sentry = build_sentry(mats)
    bpy.context.scene["cobie_pipeline_version"] = 1
    bpy.context.scene["license"] = "Project-original; Blender primitives and built-in materials only"
    bpy.context.scene["scale_contract"] = "1 Blender unit = 1 meter"
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE), compress=True)
    exports = {
        field: MODEL_DIR / "salmon_creek_field_kit.glb",
        tunnel: MODEL_DIR / "maintenance_tunnel_module_a.glb",
        lod: MODEL_DIR / "compliance_supply_crate_lod.glb",
        pickup: MODEL_DIR / "fetch_charge_pedestal.glb",
        beacon: MODEL_DIR / "rain_city_wayfinding_beacon.glb",
    }
    for target, path in exports.items():
        export_collection(target, path)
    render_sentry(sentry, mats)
    print("COBIE_ASSET_PIPELINE_PILOT: PASS")


if __name__ == "__main__":
    main()
