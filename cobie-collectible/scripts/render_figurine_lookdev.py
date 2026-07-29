#!/usr/bin/env python3
"""Render the deterministic V2 colour/lookdev evidence packet.

Run:
    uv run --project cobie-collectible/tools --locked \
      python cobie-collectible/scripts/render_figurine_lookdev.py

This renderer is deliberately separate from ``render_figurine.py``. The
neutral-resin packet remains the printable-geometry authority; this packet
reviews semantic colour, material separation, and cover-facing presentation.
It opens the LFS-backed V2 master, renders only LOOKDEV, and never saves the
source file.
"""

from __future__ import annotations

import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageStat

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    Failure,
    ROOT,
    TURNAROUND_VIEWS,
    VALIDATION_RENDERS,
    figurine_render_protocol,
    report,
    sha256_file,
    write_json,
)

MASTER_BLEND = ROOT / "cobie-collectible" / "blender" / "cobie_figurine_v2_master.blend"
LOOKDEV_ID = os.environ.get("COBIE_LOOKDEV_ID", "cover-v2/lookdev")
OUTPUT_DIR = VALIDATION_RENDERS / LOOKDEV_ID
REPORT_PATH = OUTPUT_DIR / "lookdev_report.json"
PRIMARY_COVER = ROOT / "assets" / "brand" / "cobie_nukem_cover.png"

TOP_LEVEL_COLLECTIONS = {
    "REFERENCE",
    "SCULPT_SOURCE",
    "LOOKDEV",
    "PRINT_EXPORT",
    "REVIEW_RIG",
}
VIEW_ORDER = ("front", "left", "rear", "right", "hero")
RENDER_PROTOCOL = figurine_render_protocol()
ORTHO_RESOLUTION = (640, 640)
PORTRAIT_RESOLUTION = (1024, 1536)
CAMERA_DISTANCE = float(RENDER_PROTOCOL["camera"]["orbit_radius_mm"])
CAMERA_Z = float(RENDER_PROTOCOL["camera"]["z_mm"])
ORTHO_SCALE = float(RENDER_PROTOCOL["camera"]["ortho_scale_mm"])
TARGET = Vector(RENDER_PROTOCOL["camera"]["target_mm"])
ENGINE = RENDER_PROTOCOL["render"]["engine"]
LOOK = RENDER_PROTOCOL["render"]["view_look"]


def _hex_rgb(value: str) -> tuple[float, float, float]:
    value = value.lstrip("#")
    if len(value) != 6:
        raise ValueError(f"invalid RGB hex value {value!r}")
    return tuple(int(value[index : index + 2], 16) / 255.0 for index in (0, 2, 4))


def _linear_channel(value: float) -> float:
    return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4


def _linear_rgba(value: str, alpha: float = 1.0) -> tuple[float, float, float, float]:
    return (*(_linear_channel(channel) for channel in _hex_rgb(value)), alpha)


# All palette values are project-original and procedural. No image texture or
# external material library is used by this renderer.
PALETTE: dict[str, dict] = {
    "MAT_FUR_APRICOT": {
        "hex": "#B96B2F",
        "variation_hex": "#E5A867",
        "metallic": 0.0,
        "roughness": 0.75,
        "procedural": "fur_colour_variation",
    },
    "MAT_FUR_ROOT": {
        "hex": "#633318",
        "variation_hex": "#8A4C25",
        "metallic": 0.0,
        "roughness": 0.82,
        "procedural": "fur_colour_variation",
    },
    "MAT_FUR_TIP": {
        "hex": "#E5A867",
        "variation_hex": "#F2C48B",
        "metallic": 0.0,
        "roughness": 0.72,
        "procedural": "fur_colour_variation",
    },
    "MAT_LEATHER_BLACK": {
        "hex": "#090A0C",
        "variation_hex": "#20242A",
        "metallic": 0.0,
        "roughness": 0.32,
        "coat_weight": 0.28,
        "coat_roughness": 0.22,
        "procedural": "leather_roughness_variation",
    },
    "MAT_LEATHER_EDGE": {
        "hex": "#292B2E",
        "variation_hex": "#45484D",
        "metallic": 0.0,
        "roughness": 0.42,
        "coat_weight": 0.16,
        "coat_roughness": 0.30,
        "procedural": "leather_roughness_variation",
    },
    "MAT_NOSE_GLOSS": {
        "hex": "#090A0A",
        "metallic": 0.0,
        "roughness": 0.18,
        "coat_weight": 0.42,
        "coat_roughness": 0.14,
    },
    "MAT_LENS_SMOKE": {
        "hex": "#050709",
        "metallic": 0.08,
        "roughness": 0.08,
        "coat_weight": 0.55,
        "coat_roughness": 0.10,
    },
    "MAT_FRAME_WARM_METAL": {
        "hex": "#8A6A35",
        "metallic": 0.85,
        "roughness": 0.25,
    },
    "MAT_METAL_AGED_SILVER": {
        "hex": "#7E837F",
        "metallic": 0.90,
        "roughness": 0.34,
    },
    "MAT_LAUNCHER_GUNMETAL": {
        "hex": "#20252A",
        "variation_hex": "#384149",
        "metallic": 0.82,
        "roughness": 0.32,
        "procedural": "metal_roughness_variation",
    },
    "MAT_LAUNCHER_BLACK": {
        "hex": "#080B0E",
        "variation_hex": "#171C21",
        "metallic": 0.35,
        "roughness": 0.50,
        "procedural": "metal_roughness_variation",
    },
    "MAT_HAZARD_GOLD": {
        "hex": "#D59A12",
        "variation_hex": "#F0BB2B",
        "metallic": 0.45,
        "roughness": 0.40,
        "procedural": "metal_roughness_variation",
    },
    "MAT_TENNIS_GREEN": {
        "hex": "#A3C82F",
        "variation_hex": "#C3DB62",
        "metallic": 0.0,
        "roughness": 0.74,
        "procedural": "fur_colour_variation",
    },
    "MAT_TENNIS_SEAM": {
        "hex": "#E7E3BB",
        "metallic": 0.0,
        "roughness": 0.78,
    },
    "MAT_CHARGE_CYAN": {
        "hex": "#39D9E7",
        "metallic": 0.18,
        "roughness": 0.24,
        "emission_strength": 0.0,
    },
    "MAT_BASE_DARK": {
        "hex": "#181D22",
        "variation_hex": "#2A333B",
        "metallic": 0.55,
        "roughness": 0.48,
        "procedural": "metal_roughness_variation",
    },
    "MAT_TEXT_DARK": {
        "hex": "#111315",
        "metallic": 0.15,
        "roughness": 0.62,
    },
}

REQUIRED_MATERIAL_IDS = {
    "MAT_FUR_APRICOT",
    "MAT_LEATHER_BLACK",
    "MAT_NOSE_GLOSS",
    "MAT_LENS_SMOKE",
    "MAT_FRAME_WARM_METAL",
    "MAT_METAL_AGED_SILVER",
    "MAT_LAUNCHER_GUNMETAL",
    "MAT_HAZARD_GOLD",
    "MAT_TENNIS_GREEN",
    "MAT_BASE_DARK",
}
REQUIRED_MATERIAL_IDS_BY_STAGE = {
    "silhouette": {
        "MAT_FUR_APRICOT",
        "MAT_LEATHER_BLACK",
        "MAT_LENS_SMOKE",
        "MAT_LAUNCHER_GUNMETAL",
        "MAT_BASE_DARK",
    },
    "head": {
        "MAT_FUR_APRICOT",
        "MAT_LEATHER_BLACK",
        "MAT_NOSE_GLOSS",
        "MAT_LENS_SMOKE",
        "MAT_LAUNCHER_GUNMETAL",
        "MAT_BASE_DARK",
    },
    "costume": {
        "MAT_FUR_APRICOT",
        "MAT_LEATHER_BLACK",
        "MAT_NOSE_GLOSS",
        "MAT_LENS_SMOKE",
        "MAT_FRAME_WARM_METAL",
        "MAT_METAL_AGED_SILVER",
        "MAT_LAUNCHER_GUNMETAL",
        "MAT_BASE_DARK",
    },
    "launcher": REQUIRED_MATERIAL_IDS,
    "final": REQUIRED_MATERIAL_IDS,
}

# Stable, deliberately separated colours for the semantic material-ID pass.
ID_COLOURS = {
    material_id: colour
    for material_id, colour in zip(
        PALETTE,
        (
            "#E6194B",
            "#3CB44B",
            "#FFE119",
            "#4363D8",
            "#F58231",
            "#911EB4",
            "#46F0F0",
            "#F032E6",
            "#BCF60C",
            "#FABEBE",
            "#008080",
            "#E6BEFF",
            "#9A6324",
            "#FFFAC8",
            "#800000",
            "#AAFFC3",
            "#808000",
        ),
        strict=True,
    )
}

ROLE_ALIASES = {
    "fur": "MAT_FUR_APRICOT",
    "fur_main": "MAT_FUR_APRICOT",
    "fur_apricot": "MAT_FUR_APRICOT",
    "fur_root": "MAT_FUR_ROOT",
    "fur_tip": "MAT_FUR_TIP",
    "leather": "MAT_LEATHER_BLACK",
    "leather_black": "MAT_LEATHER_BLACK",
    "leather_edge": "MAT_LEATHER_EDGE",
    "nose": "MAT_NOSE_GLOSS",
    "mouth": "MAT_TEXT_DARK",
    "lens": "MAT_LENS_SMOKE",
    "lenses": "MAT_LENS_SMOKE",
    "frame": "MAT_FRAME_WARM_METAL",
    "frames": "MAT_FRAME_WARM_METAL",
    "brass": "MAT_FRAME_WARM_METAL",
    "tag": "MAT_METAL_AGED_SILVER",
    "chain": "MAT_METAL_AGED_SILVER",
    "silver": "MAT_METAL_AGED_SILVER",
    "hardware": "MAT_METAL_AGED_SILVER",
    "launcher": "MAT_LAUNCHER_GUNMETAL",
    "launcher_gunmetal": "MAT_LAUNCHER_GUNMETAL",
    "gunmetal": "MAT_LAUNCHER_GUNMETAL",
    "launcher_black": "MAT_LAUNCHER_BLACK",
    "blacksteel": "MAT_LAUNCHER_BLACK",
    "dark_metal": "MAT_LAUNCHER_BLACK",
    "hazard": "MAT_HAZARD_GOLD",
    "hazard_gold": "MAT_HAZARD_GOLD",
    "tennis": "MAT_TENNIS_GREEN",
    "tennis_ball": "MAT_TENNIS_GREEN",
    "ball": "MAT_TENNIS_GREEN",
    "tennis_seam": "MAT_TENNIS_SEAM",
    "charge": "MAT_CHARGE_CYAN",
    "charge_cyan": "MAT_CHARGE_CYAN",
    "cyan": "MAT_CHARGE_CYAN",
    "base": "MAT_BASE_DARK",
    "text": "MAT_TEXT_DARK",
    "tag_text": "MAT_TEXT_DARK",
}


def _set_input(node: bpy.types.Node, names: tuple[str, ...], value) -> None:
    for name in names:
        socket = node.inputs.get(name)
        if socket is not None:
            socket.default_value = value
            return


def _procedural_material(material_id: str, spec: dict) -> bpy.types.Material:
    material = bpy.data.materials.get(material_id) or bpy.data.materials.new(material_id)
    material.use_nodes = True
    material.diffuse_color = _linear_rgba(spec["hex"])
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()

    output = nodes.new("ShaderNodeOutputMaterial")
    output.name = "Lookdev_Output"
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.name = "Lookdev_Principled"
    _set_input(bsdf, ("Base Color",), _linear_rgba(spec["hex"]))
    _set_input(bsdf, ("Metallic",), float(spec.get("metallic", 0.0)))
    _set_input(bsdf, ("Roughness",), float(spec.get("roughness", 0.5)))
    _set_input(bsdf, ("Coat Weight", "Clearcoat"), float(spec.get("coat_weight", 0.0)))
    _set_input(
        bsdf,
        ("Coat Roughness", "Clearcoat Roughness"),
        float(spec.get("coat_roughness", 0.03)),
    )
    emission_colour = _linear_rgba(spec["hex"])
    _set_input(bsdf, ("Emission Color", "Emission"), emission_colour)
    _set_input(bsdf, ("Emission Strength",), float(spec.get("emission_strength", 0.0)))
    links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])

    procedural = spec.get("procedural")
    if procedural:
        texture_coordinates = nodes.new("ShaderNodeTexCoord")
        noise = nodes.new("ShaderNodeTexNoise")
        noise.inputs["Scale"].default_value = 5.0 if "fur" in procedural else 8.0
        noise.inputs["Detail"].default_value = 3.0
        noise.inputs["Roughness"].default_value = 0.65
        links.new(texture_coordinates.outputs["Generated"], noise.inputs["Vector"])

        variation = spec.get("variation_hex", spec["hex"])
        colour_ramp = nodes.new("ShaderNodeValToRGB")
        colour_ramp.color_ramp.elements[0].position = 0.18
        colour_ramp.color_ramp.elements[0].color = _linear_rgba(spec["hex"])
        colour_ramp.color_ramp.elements[1].position = 0.82
        colour_ramp.color_ramp.elements[1].color = _linear_rgba(variation)
        links.new(noise.outputs["Fac"], colour_ramp.inputs["Fac"])
        links.new(colour_ramp.outputs["Color"], bsdf.inputs["Base Color"])

        if "roughness" in procedural:
            roughness_ramp = nodes.new("ShaderNodeValToRGB")
            roughness = float(spec["roughness"])
            low = max(0.0, roughness - 0.045)
            high = min(1.0, roughness + 0.045)
            roughness_ramp.color_ramp.elements[0].color = (low, low, low, 1.0)
            roughness_ramp.color_ramp.elements[1].color = (high, high, high, 1.0)
            links.new(noise.outputs["Fac"], roughness_ramp.inputs["Fac"])
            links.new(roughness_ramp.outputs["Color"], bsdf.inputs["Roughness"])

    return material


def _emission_material(name: str, colour: str) -> bpy.types.Material:
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    emission = nodes.new("ShaderNodeEmission")
    emission.inputs["Color"].default_value = _linear_rgba(colour)
    emission.inputs["Strength"].default_value = 1.0
    links.new(emission.outputs["Emission"], output.inputs["Surface"])
    material.diffuse_color = _linear_rgba(colour)
    return material


def _normalise_role(value: str) -> str:
    return (
        value.strip()
        .lower()
        .replace("mat_", "")
        .replace("lookdev_", "")
        .replace("ld_", "")
        .replace("-", "_")
        .replace(" ", "_")
    )


def _material_id_from_value(value: object) -> str | None:
    if not isinstance(value, str) or not value.strip():
        return None
    upper = value.strip().upper()
    if upper in PALETTE:
        return upper
    normalised = _normalise_role(value)
    direct = ROLE_ALIASES.get(normalised)
    if direct is not None:
        return direct

    # Longest keywords first prevents "tennis" from consuming "tennis_seam".
    for keyword in sorted(ROLE_ALIASES, key=len, reverse=True):
        if keyword in normalised:
            return ROLE_ALIASES[keyword]
    return None


def _object_material_ids(obj: bpy.types.Object) -> list[str]:
    existing = [
        _material_id_from_value(slot.material.name)
        for slot in obj.material_slots
        if slot.material is not None
    ]
    if existing and all(material_id is not None for material_id in existing):
        return [material_id for material_id in existing if material_id is not None]

    for property_name in (
        "lookdev_material_id",
        "material_id",
        "semantic_role",
        "role",
        "cobie_zone",
        "cobie_role",
    ):
        material_id = _material_id_from_value(obj.get(property_name))
        if material_id is not None:
            return [material_id]

    material_id = _material_id_from_value(obj.name)
    return [material_id] if material_id is not None else []


def _assign_materials(
    objects: list[bpy.types.Object],
    materials: dict[str, bpy.types.Material],
    required_material_ids: set[str],
) -> tuple[dict[str, list[str]], list[Failure]]:
    assignments: dict[str, list[str]] = {}
    failures: list[Failure] = []
    for obj in objects:
        # A master may instance one sculpt mesh into several semantic lookdev
        # roles. Keep material assignment local to the rendered object.
        if obj.data.users > 1:
            obj.data = obj.data.copy()
        material_ids = _object_material_ids(obj)
        if not material_ids:
            failures.append(
                Failure(
                    "lookdev_material_role",
                    obj.name,
                    "mesh needs an approved material slot name or semantic role",
                )
            )
            continue

        if len(material_ids) == len(obj.material_slots) and len(material_ids) > 0:
            for index, material_id in enumerate(material_ids):
                obj.material_slots[index].material = materials[material_id]
        else:
            obj.data.materials.clear()
            obj.data.materials.append(materials[material_ids[0]])
            for polygon in obj.data.polygons:
                polygon.material_index = 0
        assignments[obj.name] = material_ids

    used = {material_id for values in assignments.values() for material_id in values}
    for missing in sorted(required_material_ids - used):
        failures.append(
            Failure(
                "required_material_zone",
                missing,
                "required cover-facing material is absent from LOOKDEV",
            )
        )
    return assignments, failures


def _aim_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def _set_resolution(width: int, height: int) -> None:
    scene = bpy.context.scene
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100


def _place_ortho(
    camera: bpy.types.Object,
    yaw_degrees: float,
    *,
    target: Vector = TARGET,
    distance: float = CAMERA_DISTANCE,
    z: float = CAMERA_Z,
    ortho_scale: float = ORTHO_SCALE,
) -> None:
    yaw = math.radians(yaw_degrees)
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = ortho_scale
    camera.location = (
        math.sin(yaw) * distance,
        -math.cos(yaw) * distance,
        z,
    )
    _aim_at(camera, target)
    bpy.context.view_layer.update()


def _render(path: Path) -> None:
    scene = bpy.context.scene
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def _image_failure(name: str, path: Path, expected_size: tuple[int, int]) -> Failure | None:
    if not path.is_file():
        return Failure("lookdev_render_missing", name, f"{path.name} was not written")
    with Image.open(path) as handle:
        image = handle.convert("RGB")
        if image.size != expected_size:
            return Failure(
                "lookdev_render_dimensions",
                name,
                f"rendered {image.size}, expected {expected_size}",
            )
        deviation = ImageStat.Stat(image.convert("L")).stddev[0]
        if deviation < 5.0:
            return Failure(
                "lookdev_render_blank",
                name,
                f"luminance standard deviation {deviation:.2f} is effectively blank",
            )
    return None


def _configure_scene() -> tuple[bpy.types.Object, bpy.types.Object, list[Failure]]:
    scene = bpy.context.scene
    failures: list[Failure] = []
    observed_top_level = {collection.name for collection in scene.collection.children}
    if observed_top_level != TOP_LEVEL_COLLECTIONS:
        failures.append(
            Failure(
                "master_collections",
                str(MASTER_BLEND.relative_to(ROOT)),
                f"expected={sorted(TOP_LEVEL_COLLECTIONS)} observed={sorted(observed_top_level)}",
            )
        )

    lookdev_collection = bpy.data.collections.get("LOOKDEV")
    if lookdev_collection is None:
        failures.append(Failure("lookdev_collection", "LOOKDEV", "collection is missing"))
        return None, None, failures  # type: ignore[return-value]

    lookdev_objects = [obj for obj in lookdev_collection.all_objects if obj.type == "MESH"]
    if not lookdev_objects:
        failures.append(
            Failure(
                "lookdev_empty",
                "LOOKDEV",
                "no semantic mesh content exists; refinement must populate LOOKDEV first",
            )
        )
        return None, None, failures  # type: ignore[return-value]

    if bpy.data.images:
        failures.append(
            Failure(
                "external_texture",
                "master",
                "lookdev master must not contain embedded or externally linked image datablocks",
            )
        )
    for material in bpy.data.materials:
        if not material.use_nodes or material.node_tree is None:
            continue
        if any(
            node.bl_idname in {"ShaderNodeTexImage", "ShaderNodeTexEnvironment"}
            for node in material.node_tree.nodes
        ):
            failures.append(
                Failure(
                    "external_texture_node",
                    material.name,
                    "image and environment texture nodes are prohibited in deterministic lookdev",
                )
            )

    for collection in scene.collection.children:
        collection.hide_render = collection.name != "LOOKDEV"
        collection.hide_viewport = False
    for child in lookdev_collection.children_recursive:
        child.hide_render = False
        child.hide_viewport = False
    for obj in lookdev_objects:
        obj.hide_render = False
        obj.hide_set(False)

    # Source rig data are removed only from the opened in-memory copy. The
    # master is never saved, so this cannot mutate the LFS source.
    for obj in list(scene.objects):
        if obj.type in {"CAMERA", "LIGHT"}:
            bpy.data.objects.remove(obj, do_unlink=True)

    rig_collection = bpy.data.collections.new("__LOOKDEV_RENDER_RIG")
    scene.collection.children.link(rig_collection)

    camera_data = bpy.data.cameras.new("Lookdev_Camera_Data")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = ORTHO_SCALE
    camera = bpy.data.objects.new("Lookdev_Camera", camera_data)
    rig_collection.objects.link(camera)
    scene.camera = camera

    floor_material = _procedural_material("MAT_BASE_DARK", PALETTE["MAT_BASE_DARK"])
    bpy.ops.mesh.primitive_plane_add(
        size=260.0,
        location=(0.0, 0.0, -0.25),
    )
    floor = bpy.context.active_object
    floor.name = "Lookdev_Floor"
    for collection in list(floor.users_collection):
        collection.objects.unlink(floor)
    rig_collection.objects.link(floor)
    floor.data.materials.append(floor_material)

    scene.render.engine = ENGINE
    _set_resolution(*ORTHO_RESOLUTION)
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.render.use_compositing = False
    scene.render.use_sequencer = False
    scene.use_nodes = False
    scene.view_settings.look = LOOK

    world = scene.world or bpy.data.worlds.new("Lookdev_World")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    if background is not None:
        background.inputs["Color"].default_value = _linear_rgba("#111824")
        background.inputs["Strength"].default_value = 0.28

    return camera, floor, failures


def _clear_lights() -> None:
    for obj in list(bpy.context.scene.objects):
        if obj.type == "LIGHT":
            bpy.data.objects.remove(obj, do_unlink=True)


def _install_lights(
    *,
    presentation: bool,
) -> list[dict]:
    _clear_lights()
    rig = bpy.data.collections["__LOOKDEV_RENDER_RIG"]
    if presentation:
        settings = (
            ("Lookdev_Key_Warm", (-110.0, -150.0, 205.0), 4.4, 0.14, "#FFD2A3"),
            ("Lookdev_Fill_Neutral", (135.0, -90.0, 125.0), 1.25, 0.30, "#DCE7F2"),
            ("Lookdev_Rim_Cool", (50.0, 135.0, 190.0), 2.75, 0.18, "#80A9D6"),
        )
    else:
        settings = tuple(
            (
                str(entry["name"]).replace("Review_", "Lookdev_Proof_"),
                tuple(entry["location_mm"]),
                float(entry["energy"]),
                float(entry["angle_radians"]),
                "#FFFFFF",
            )
            for entry in RENDER_PROTOCOL["lights"]
        )

    report_settings: list[dict] = []
    for name, location, energy, angle, colour in settings:
        light_data = bpy.data.lights.new(f"{name}_Data", "SUN")
        light_data.energy = energy
        light_data.angle = angle
        light_data.color = _linear_rgba(colour)[:3]
        light = bpy.data.objects.new(name, light_data)
        light.location = location
        _aim_at(light, TARGET)
        rig.objects.link(light)
        report_settings.append(
            {
                "name": name,
                "type": "SUN",
                "location_mm": list(location),
                "energy": energy,
                "angle_radians": angle,
                "colour_hex": colour,
            }
        )
    return report_settings


def _set_charge_emission(material: bpy.types.Material, strength: float) -> None:
    if not material.use_nodes or material.node_tree is None:
        return
    bsdf = material.node_tree.nodes.get("Lookdev_Principled")
    if bsdf is not None:
        _set_input(bsdf, ("Emission Strength",), strength)


def _make_palette_strip(path: Path) -> None:
    width = 1520
    swatch_height = 72
    label_width = 360
    image = Image.new("RGB", (width, swatch_height * len(PALETTE)), "#101318")
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default(size=18)
    for index, (material_id, spec) in enumerate(PALETTE.items()):
        y = index * swatch_height
        draw.rectangle((0, y, label_width, y + swatch_height), fill="#171B21")
        draw.rectangle((label_width, y, width, y + swatch_height), fill=spec["hex"])
        draw.text((18, y + 16), material_id, fill="#F2F4F6", font=font)
        draw.text((18, y + 42), spec["hex"], fill="#AAB2BA", font=font)
    image.save(path)


def _make_contact_sheet(paths: dict[str, Path], path: Path) -> None:
    tile_width, tile_height = ORTHO_RESOLUTION
    label_height = 34
    sheet = Image.new(
        "RGB",
        (tile_width * 3, (tile_height + label_height) * 2),
        (20, 23, 28),
    )
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=18)
    for index, view in enumerate(VIEW_ORDER):
        row, column = divmod(index, 3)
        with Image.open(paths[view]) as handle:
            tile = handle.convert("RGB")
        x = column * tile_width
        y = row * (tile_height + label_height)
        sheet.paste(tile, (x, y))
        draw.text((x + 14, y + tile_height + 8), view.upper(), fill="#E6E8EB", font=font)
    x = 2 * tile_width
    y = tile_height + label_height
    draw.multiline_text(
        (x + 34, y + 70),
        "COVER REFINEMENT V2 — LOOKDEV\n"
        "Colour/material review, not print proof\n"
        "Identity approval: FALSE\n"
        "Physical prototype approval: FALSE",
        fill="#E6E8EB",
        spacing=13,
        font=font,
    )
    sheet.save(path)


def _fit_tile(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps.contain(image.convert("RGB"), size, method=Image.Resampling.LANCZOS)


def _make_review_board(paths: dict[str, Path], path: Path) -> None:
    tile = 420
    label_height = 34
    footer_height = 72
    board = Image.new("RGB", (tile * 3, (tile + label_height) * 2 + footer_height), "#101318")
    draw = ImageDraw.Draw(board)
    font = ImageFont.load_default(size=17)
    panels = (
        ("PRIMARY COVER REFERENCE", PRIMARY_COVER),
        ("PRESENTATION PORTRAIT", paths["presentation"]),
        ("LOCKED HERO COLOUR", paths["hero"]),
        ("BLACK SILHOUETTE", paths["silhouette_hero"]),
        ("HEAD / GLASSES", paths["closeup_head"]),
        ("JACKET / LAUNCHER", paths["closeup_jacket"]),
    )
    for index, (label, source) in enumerate(panels):
        row, column = divmod(index, 3)
        x = column * tile
        y = row * (tile + label_height)
        with Image.open(source) as handle:
            fitted = _fit_tile(handle, (tile, tile))
        offset_x = x + (tile - fitted.width) // 2
        offset_y = y + (tile - fitted.height) // 2
        board.paste(fitted, (offset_x, offset_y))
        draw.text((x + 12, y + tile + 8), label, fill="#E6E8EB", font=font)
    draw.text(
        (18, board.height - footer_height + 20),
        "Automated packet: source-bound. Human identity and physical manufacture gates remain open.",
        fill="#B7C0C9",
        font=font,
    )
    board.save(path)


def _record_image(
    images: dict[str, dict],
    failures: list[Failure],
    name: str,
    path: Path,
    expected_size: tuple[int, int],
) -> None:
    failure = _image_failure(name, path, expected_size)
    if failure is not None:
        failures.append(failure)
        return
    images[name] = {
        "path": str(path.relative_to(ROOT)),
        "sha256": sha256_file(path),
        "size_px": list(expected_size),
    }


def _run() -> int:
    failures: list[Failure] = []
    images: dict[str, dict] = {}
    if not MASTER_BLEND.is_file():
        failures.append(
            Failure(
                "master_missing",
                str(MASTER_BLEND.relative_to(ROOT)),
                "V2 refinement master is missing",
            )
        )
        write_json(
            REPORT_PATH,
            {
                "status": "FAIL",
                "source_master": str(MASTER_BLEND.relative_to(ROOT)),
                "identity_approved": False,
                "physical_prototype_approved": False,
                "failures": [failure.as_dict() for failure in failures],
            },
        )
        return report("COBIE_FIGURINE_LOOKDEV", failures)

    source_hash_before = sha256_file(MASTER_BLEND)
    bpy.ops.wm.open_mainfile(filepath=str(MASTER_BLEND))
    camera, floor, scene_failures = _configure_scene()
    failures.extend(scene_failures)
    if failures:
        source_hash_after = sha256_file(MASTER_BLEND)
        write_json(
            REPORT_PATH,
            {
                "status": "FAIL",
                "source_master": str(MASTER_BLEND.relative_to(ROOT)),
                "source_sha256_before": source_hash_before,
                "source_sha256_after": source_hash_after,
                "source_unchanged": source_hash_before == source_hash_after,
                "identity_approved": False,
                "physical_prototype_approved": False,
                "failures": [failure.as_dict() for failure in failures],
            },
        )
        return report("COBIE_FIGURINE_LOOKDEV", failures)

    lookdev_collection = bpy.data.collections["LOOKDEV"]
    lookdev_objects = [obj for obj in lookdev_collection.all_objects if obj.type == "MESH"]
    refinement_stage = bpy.context.scene.get("refinement_stage")
    required_material_ids = REQUIRED_MATERIAL_IDS_BY_STAGE.get(refinement_stage)
    if required_material_ids is None:
        failures.append(
            Failure(
                "refinement_stage",
                str(refinement_stage),
                f"expected one of {sorted(REQUIRED_MATERIAL_IDS_BY_STAGE)}",
            )
        )
        required_material_ids = REQUIRED_MATERIAL_IDS
    materials = {
        material_id: _procedural_material(material_id, spec)
        for material_id, spec in PALETTE.items()
    }
    assignments, material_failures = _assign_materials(
        lookdev_objects,
        materials,
        required_material_ids,
    )
    failures.extend(material_failures)
    if failures:
        source_hash_after = sha256_file(MASTER_BLEND)
        write_json(
            REPORT_PATH,
            {
                "status": "FAIL",
                "source_master": str(MASTER_BLEND.relative_to(ROOT)),
                "source_sha256_before": source_hash_before,
                "source_sha256_after": source_hash_after,
                "source_unchanged": source_hash_before == source_hash_after,
                "materials": {
                    "palette": PALETTE,
                    "assignments": assignments,
                },
                "identity_approved": False,
                "physical_prototype_approved": False,
                "failures": [failure.as_dict() for failure in failures],
            },
        )
        return report("COBIE_FIGURINE_LOOKDEV", failures)

    proof_lights = _install_lights(presentation=False)
    _set_charge_emission(materials["MAT_CHARGE_CYAN"], 0.0)
    _set_resolution(*ORTHO_RESOLUTION)

    colour_paths: dict[str, Path] = {}
    for view in VIEW_ORDER:
        _place_ortho(camera, TURNAROUND_VIEWS[view])
        path = OUTPUT_DIR / f"colour_{view}.png"
        _render(path)
        colour_paths[view] = path
        _record_image(images, failures, view, path, ORTHO_RESOLUTION)

    closeup_specs = {
        "closeup_head": (0.0, Vector((0.0, -5.0, 118.0)), 58.0),
        "closeup_jacket": (20.0, Vector((0.0, -4.0, 82.0)), 70.0),
        "closeup_launcher": (35.0, Vector((7.0, -17.0, 68.0)), 78.0),
    }
    closeup_paths: dict[str, Path] = {}
    for name, (yaw, target, scale) in closeup_specs.items():
        _place_ortho(camera, yaw, target=target, z=target.z + 8.0, ortho_scale=scale)
        path = OUTPUT_DIR / f"{name}.png"
        _render(path)
        closeup_paths[name] = path
        _record_image(images, failures, name, path, ORTHO_RESOLUTION)

    # Black silhouette evidence uses a layer override and hides the floor so
    # the mask communicates the character/prop shape only.
    silhouette_material = _emission_material("SILHOUETTE_BLACK", "#000000")
    view_layer = bpy.context.view_layer
    view_layer.material_override = silhouette_material
    floor.hide_render = True
    world_background = bpy.context.scene.world.node_tree.nodes.get("Background")
    if world_background is not None:
        world_background.inputs["Color"].default_value = _linear_rgba("#F2F2F0")
        world_background.inputs["Strength"].default_value = 1.0
    silhouette_paths: dict[str, Path] = {}
    for view in ("front", "hero"):
        _place_ortho(camera, TURNAROUND_VIEWS[view])
        path = OUTPUT_DIR / f"silhouette_{view}.png"
        _render(path)
        silhouette_paths[view] = path
        _record_image(images, failures, f"silhouette_{view}", path, ORTHO_RESOLUTION)
    view_layer.material_override = None
    floor.hide_render = False
    if world_background is not None:
        world_background.inputs["Color"].default_value = _linear_rgba("#111824")
        world_background.inputs["Strength"].default_value = 0.28

    # The portrait intentionally uses a different camera/light protocol and is
    # therefore presentation evidence, never a geometry-comparison input.
    presentation_lights = _install_lights(presentation=True)
    _set_charge_emission(materials["MAT_CHARGE_CYAN"], 1.6)
    _set_resolution(*PORTRAIT_RESOLUTION)
    camera.data.type = "PERSP"
    camera.data.lens = 65.0
    camera.data.sensor_width = 36.0
    presentation_yaw = math.radians(25.0)
    presentation_distance = 440.0
    camera.location = (
        math.sin(presentation_yaw) * presentation_distance,
        -math.cos(presentation_yaw) * presentation_distance,
        94.0,
    )
    presentation_target = Vector((0.0, -2.0, 70.0))
    _aim_at(camera, presentation_target)
    presentation_path = OUTPUT_DIR / "presentation_portrait.png"
    _render(presentation_path)
    _record_image(images, failures, "presentation", presentation_path, PORTRAIT_RESOLUTION)

    # Material-ID evidence is rendered last. Replacing slots is safe because
    # the master remains read-only and no subsequent beauty render depends on
    # the material state.
    _install_lights(presentation=False)
    _set_resolution(*ORTHO_RESOLUTION)
    floor.hide_render = True
    id_materials = {
        material_id: _emission_material(f"ID_{material_id}", ID_COLOURS[material_id])
        for material_id in PALETTE
    }
    for obj in lookdev_objects:
        material_ids = assignments[obj.name]
        for index, material_id in enumerate(material_ids):
            if index < len(obj.material_slots):
                obj.material_slots[index].material = id_materials[material_id]
    if world_background is not None:
        world_background.inputs["Color"].default_value = _linear_rgba("#000000")
        world_background.inputs["Strength"].default_value = 0.0
    _place_ortho(camera, TURNAROUND_VIEWS["hero"])
    material_id_path = OUTPUT_DIR / "material_id.png"
    _render(material_id_path)
    _record_image(images, failures, "material_id", material_id_path, ORTHO_RESOLUTION)

    palette_strip_path = OUTPUT_DIR / "palette_strip.png"
    _make_palette_strip(palette_strip_path)
    _record_image(
        images,
        failures,
        "palette_strip",
        palette_strip_path,
        (1520, 72 * len(PALETTE)),
    )

    contact_sheet_path = OUTPUT_DIR / "colour_contact_sheet.png"
    _make_contact_sheet(colour_paths, contact_sheet_path)
    _record_image(
        images,
        failures,
        "colour_contact_sheet",
        contact_sheet_path,
        (ORTHO_RESOLUTION[0] * 3, (ORTHO_RESOLUTION[1] + 34) * 2),
    )

    board_sources = {
        **colour_paths,
        **closeup_paths,
        **silhouette_paths,
        "presentation": presentation_path,
        "silhouette_hero": silhouette_paths["hero"],
    }
    review_board_path = OUTPUT_DIR / "review_board.png"
    _make_review_board(board_sources, review_board_path)
    _record_image(
        images,
        failures,
        "review_board",
        review_board_path,
        (420 * 3, (420 + 34) * 2 + 72),
    )

    source_hash_after = sha256_file(MASTER_BLEND)
    if source_hash_before != source_hash_after:
        failures.append(
            Failure(
                "source_mutation",
                str(MASTER_BLEND.relative_to(ROOT)),
                "master hash changed during lookdev rendering",
            )
        )

    payload = {
        "schema_version": 1,
        "status": "PASS" if not failures else "FAIL",
        "packet_type": "lookdev_colour_evidence",
        "render_id": LOOKDEV_ID,
        "source_master": str(MASTER_BLEND.relative_to(ROOT)),
        "source_sha256_before": source_hash_before,
        "source_sha256_after": source_hash_after,
        "source_unchanged": source_hash_before == source_hash_after,
        "environment": {
            "blender": bpy.app.version_string,
            "render_engine": ENGINE,
            "view_look": LOOK,
        },
        "collections": {
            "required_top_level": sorted(TOP_LEVEL_COLLECTIONS),
            "rendered": "LOOKDEV",
            "excluded": ["REFERENCE", "SCULPT_SOURCE", "PRINT_EXPORT", "REVIEW_RIG"],
        },
        "materials": {
            "palette": PALETTE,
            "required_material_ids": sorted(required_material_ids),
            "assignments": assignments,
            "material_id_colours": ID_COLOURS,
            "external_textures": [],
            "shader_displacement": False,
        },
        "cameras": {
            "locked_orthographic": {
                "resolution_px": list(ORTHO_RESOLUTION),
                "projection": "ORTHO",
                "orbit_radius_mm": CAMERA_DISTANCE,
                "z_mm": CAMERA_Z,
                "target_mm": list(TARGET),
                "ortho_scale_mm": ORTHO_SCALE,
                "views_yaw_degrees": dict(TURNAROUND_VIEWS),
            },
            "closeups": {
                name: {
                    "yaw_degrees": yaw,
                    "target_mm": list(target),
                    "ortho_scale_mm": scale,
                }
                for name, (yaw, target, scale) in closeup_specs.items()
            },
            "presentation": {
                "resolution_px": list(PORTRAIT_RESOLUTION),
                "projection": "PERSP",
                "lens_mm": 65.0,
                "sensor_width_mm": 36.0,
                "yaw_degrees": 25.0,
                "distance_mm": presentation_distance,
                "target_mm": list(presentation_target),
            },
        },
        "lights": {
            "colour_proof": proof_lights,
            "presentation": presentation_lights,
        },
        "images": images,
        "identity_approved": False,
        "physical_prototype_approved": False,
        "manufacturing_authorized": False,
        "failures": [failure.as_dict() for failure in failures],
    }
    write_json(REPORT_PATH, payload)
    return report(
        "COBIE_FIGURINE_LOOKDEV",
        failures,
        {"images": len(images), "materials": len(assignments)},
    )


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_json(
        REPORT_PATH,
        {
            "schema_version": 1,
            "status": "FAIL",
            "packet_type": "lookdev_colour_evidence",
            "render_id": LOOKDEV_ID,
            "source_master": str(MASTER_BLEND.relative_to(ROOT)),
            "identity_approved": False,
            "physical_prototype_approved": False,
            "manufacturing_authorized": False,
            "failures": [
                Failure(
                    "lookdev_incomplete",
                    str(REPORT_PATH.relative_to(ROOT)),
                    "lookdev packet started but has not completed",
                ).as_dict()
            ],
        },
    )
    try:
        return _run()
    except Exception as exc:
        source_hash = sha256_file(MASTER_BLEND) if MASTER_BLEND.is_file() else None
        failure = Failure(
            "lookdev_exception",
            str(REPORT_PATH.relative_to(ROOT)),
            f"{type(exc).__name__}: {exc}",
        )
        write_json(
            REPORT_PATH,
            {
                "schema_version": 1,
                "status": "FAIL",
                "packet_type": "lookdev_colour_evidence",
                "render_id": LOOKDEV_ID,
                "source_master": str(MASTER_BLEND.relative_to(ROOT)),
                "source_sha256_before": source_hash,
                "source_sha256_after": source_hash,
                "source_unchanged": True,
                "identity_approved": False,
                "physical_prototype_approved": False,
                "manufacturing_authorized": False,
                "failures": [failure.as_dict()],
            },
        )
        return report("COBIE_FIGURINE_LOOKDEV", [failure])


if __name__ == "__main__":
    raise SystemExit(main())
