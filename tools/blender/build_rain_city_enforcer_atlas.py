"""Render the project-original Umbrella Shield Enforcer as an 8x4 atlas.

Rows follow EnemyPresentationProfile: idle, locomotion A, locomotion B, and
alert/open/attack/hurt/stagger/shield-break/death/brace reactions. The script
authors the character from Blender primitives so every frame shares exact
proportions, materials, lighting, and camera framing.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/blender/rain_city_umbrella_enforcer.blend"
FRAME_DIR = ROOT / "builds/generated/rain_city_umbrella_enforcer"


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            datablocks.remove(block)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 256
    scene.render.resolution_y = 256
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.image_settings.color_depth = "8"
    scene.render.filter_size = 1.1
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.world.color = (0.025, 0.035, 0.045)


def material(name: str, color: tuple[float, float, float, float], metallic=0.0, roughness=0.55, emission=0.0):
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


def parent(obj, root, name: str):
    obj.name = name
    obj.parent = root
    return obj


def cube(root, name, location, scale, mat, bevel=0.05):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = parent(bpy.context.object, root, name)
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("AuthoredEdge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(mat)
    return obj


def cylinder(root, name, location, radius, depth, mat, vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = parent(bpy.context.object, root, name)
    obj.data.materials.append(mat)
    return obj


def sphere(root, name, location, scale, mat, segments=20, rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = parent(bpy.context.object, root, name)
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def add_lighting_and_camera() -> None:
    bpy.ops.object.camera_add(location=(0.0, -8.5, 2.0))
    camera = bpy.context.object
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 3.65
    camera.rotation_euler = (math.radians(88.0), 0.0, 0.0)
    direction = Vector((0.0, 0.0, 1.35)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = camera

    for location, energy, size, color in (
        ((-3.8, -4.5, 6.0), 950.0, 4.0, (1.0, 0.79, 0.60)),
        ((4.5, -1.0, 3.5), 720.0, 3.0, (0.34, 0.72, 1.0)),
        ((0.0, 3.0, 5.0), 560.0, 2.5, (0.20, 0.42, 0.65)),
    ):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        light.rotation_euler = (Vector((0.0, 0.0, 1.2)) - light.location).to_track_quat("-Z", "Y").to_euler()


def build_character():
    mats = {
        "coat": material("RC_ComplianceRaincoat", (0.92, 0.42, 0.035, 1.0), 0.06, 0.47),
        "navy": material("RC_ShieldNavy", (0.025, 0.075, 0.11, 1.0), 0.24, 0.28),
        "steel": material("RC_MunicipalSteel", (0.20, 0.28, 0.31, 1.0), 0.64, 0.30),
        "rubber": material("RC_Rubber", (0.012, 0.018, 0.021, 1.0), 0.0, 0.88),
        "visor": material("RC_ThreatVisor", (0.96, 0.08, 0.025, 1.0), 0.25, 0.16, 3.4),
        "cyan": material("RC_ShieldCharge", (0.03, 0.72, 1.0, 1.0), 0.12, 0.18, 2.8),
        "paper": material("RC_CitationPaper", (0.92, 0.89, 0.72, 1.0), 0.0, 0.78),
    }
    root = bpy.data.objects.new("UmbrellaEnforcerRoot", None)
    bpy.context.collection.objects.link(root)
    root["cobie_asset_id"] = "umbrella_shield_enforcer"
    root["direction_count"] = 8
    root["presentation_rows"] = 4

    torso = cylinder(root, "RaincoatTorso", (0.0, 0.0, 1.35), 0.49, 1.05, mats["coat"], 12)
    torso.scale.y = 0.78
    belt = cylinder(root, "MunicipalBelt", (0.0, 0.0, 1.04), 0.51, 0.13, mats["rubber"], 12)
    belt.scale.y = 0.80
    head = sphere(root, "Helmet", (0.0, -0.01, 2.08), (0.42, 0.36, 0.42), mats["steel"])
    visor = cube(root, "ThreatVisor", (0.0, -0.34, 2.12), (0.28, 0.045, 0.10), mats["visor"], 0.04)
    badge = cube(root, "CitationBadge", (0.0, -0.405, 1.47), (0.17, 0.035, 0.22), mats["paper"], 0.035)
    for index, x in enumerate((-0.22, 0.22)):
        leg = cylinder(root, f"BootLeg{index}", (x, 0.0, 0.55), 0.14, 0.88, mats["rubber"], 10)
        boot = cube(root, f"Boot{index}", (x, -0.11, 0.17), (0.19, 0.30, 0.15), mats["rubber"], 0.06)
        leg["base_x"] = x
        boot["base_x"] = x
    for index, x in enumerate((-0.57, 0.57)):
        arm = cylinder(root, f"RaincoatArm{index}", (x, -0.02, 1.47), 0.13, 0.86, mats["coat"], 10)
        arm.rotation_euler.y = math.radians(-13.0 if x < 0 else 13.0)

    pole = cylinder(root, "UmbrellaPole", (0.0, -0.60, 1.26), 0.045, 1.65, mats["steel"], 10)
    pole.rotation_euler.x = math.radians(7.0)
    shield_root = bpy.data.objects.new("ShieldRoot", None)
    bpy.context.collection.objects.link(shield_root)
    shield_root.parent = root
    shield_root.location = (0.0, -0.76, 1.48)
    canopy = sphere(shield_root, "ArmouredUmbrella", (0.0, 0.0, 0.0), (1.02, 0.14, 0.78), mats["navy"], 24, 14)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.79, minor_radius=0.035, major_segments=24, minor_segments=6, location=(0.0, 0.0, 0.0), rotation=(math.pi / 2.0, 0.0, 0.0))
    rim = parent(bpy.context.object, shield_root, "ShieldChargeRim")
    rim.scale.x = 1.25
    rim.data.materials.append(mats["cyan"])
    for x in (-0.55, 0.0, 0.55):
        rib = cube(shield_root, f"ShieldRib{x}", (x, -0.14, 0.0), (0.025, 0.025, 0.62), mats["steel"], 0.01)
        rib.rotation_euler.y = math.radians(x * 17.0)

    citation_roll = cylinder(root, "CitationRoll", (0.40, -0.34, 1.10), 0.13, 0.48, mats["paper"], 14)
    citation_roll.rotation_euler.x = math.radians(90.0)
    return root, shield_root, mats


def reset_pose(root, shield_root) -> None:
    root.rotation_euler = (0.0, 0.0, 0.0)
    root.location = (0.0, 0.0, 0.0)
    root.scale = (1.0, 1.0, 1.0)
    shield_root.location = (0.0, -0.76, 1.48)
    shield_root.rotation_euler = (0.0, 0.0, 0.0)
    shield_root.scale = (1.0, 1.0, 1.0)
    shield_root.hide_render = False
    for obj in root.children_recursive:
        obj.hide_render = False
        if obj.name.startswith("BootLeg") or obj.name.startswith("Boot"):
            obj.rotation_euler.x = 0.0


def apply_locomotion(root, shield_root, alternate: bool) -> None:
    stride = -1.0 if alternate else 1.0
    root.location.z = 0.035 if alternate else 0.0
    for obj in root.children_recursive:
        if obj.name in ("BootLeg0", "Boot0"):
            obj.rotation_euler.x = math.radians(12.0 * stride)
        elif obj.name in ("BootLeg1", "Boot1"):
            obj.rotation_euler.x = math.radians(-12.0 * stride)
        elif obj.name.startswith("RaincoatArm"):
            obj.rotation_euler.x = math.radians((-9.0 if obj.name.endswith("0") else 9.0) * stride)


def apply_reaction(root, shield_root, column: int) -> None:
    if column == 0:  # alert
        root.scale = (1.04, 1.04, 1.04)
        root.location.z = 0.04
    elif column == 1:  # shield opens for the firing window
        shield_root.location.x = 0.82
        shield_root.rotation_euler.z = math.radians(-28.0)
    elif column == 2:  # attack
        shield_root.location.x = 0.72
        shield_root.rotation_euler.z = math.radians(-38.0)
        root.rotation_euler.x = math.radians(-7.0)
    elif column == 3:  # hurt
        root.rotation_euler.y = math.radians(14.0)
        root.location.x = 0.10
    elif column == 4:  # stagger
        root.rotation_euler.x = math.radians(18.0)
        root.location.y = 0.10
    elif column == 5:  # shield break
        shield_root.rotation_euler.z = math.radians(74.0)
        shield_root.location = (1.05, -0.25, 0.72)
        shield_root.scale = (0.82, 0.82, 0.82)
    elif column == 6:  # grounded defeat
        root.rotation_euler.y = math.radians(74.0)
        root.location = (0.28, 0.12, -0.48)
        shield_root.rotation_euler.z = math.radians(80.0)
        shield_root.location.x = 0.92
    else:  # full brace / phase accent
        shield_root.scale = (1.10, 1.10, 1.10)
        root.location.z = -0.04


def render_frames(root, shield_root) -> None:
    FRAME_DIR.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    for row in range(4):
        for column in range(8):
            reset_pose(root, shield_root)
            if row == 1:
                apply_locomotion(root, shield_root, False)
            elif row == 2:
                apply_locomotion(root, shield_root, True)
            elif row == 3:
                apply_reaction(root, shield_root, column)
            if row < 3:
                root.rotation_euler.z = math.radians(column * 45.0)
            scene.render.filepath = str(FRAME_DIR / f"frame_{row}_{column}.png")
            bpy.ops.render.render(write_still=True)


def main() -> None:
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    reset_scene()
    add_lighting_and_camera()
    root, shield_root, _mats = build_character()
    bpy.context.scene["cobie_asset_id"] = "umbrella_shield_enforcer_atlas"
    bpy.context.scene["atlas_contract"] = "8x4"
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    render_frames(root, shield_root)
    print(f"Saved source {SOURCE}")
    print(f"Rendered 32 frames to {FRAME_DIR}")


if __name__ == "__main__":
    main()
