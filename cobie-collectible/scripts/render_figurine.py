#!/usr/bin/env python3
"""Render a deterministic five-view review packet from the current .blend.

Run:
    COBIE_RENDER_ID=proxy-baseline \
      uv run --project cobie-collectible/tools --locked \
      python cobie-collectible/scripts/render_figurine.py

The render is deliberately neutral resin under broad studio lighting. It is a
geometry review, not a beauty render: silhouette, assembly seams, weak details,
and the rear surface must remain visible. The environment variable selects the
output folder without introducing a command-line parser into the Blender
authoring scripts.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from PIL import Image, ImageDraw, ImageStat

sys.path.insert(0, str(Path(__file__).resolve().parent))

import receipt as receipt_module
from _common import (
    BUILD_REPORT,
    FIGURINE_BLEND,
    Failure,
    PART_NAMES,
    ROOT,
    VALIDATION_RENDERS,
    check_build_receipt,
    figurine_render_protocol,
    report,
    sha256_file,
    write_json,
)

BLEND_PATH = FIGURINE_BLEND
RENDER_ID = os.environ.get("COBIE_RENDER_ID", "prototype-current")
OUTPUT_DIR = VALIDATION_RENDERS / RENDER_ID
RENDER_PROTOCOL = figurine_render_protocol()
RENDER_SETTINGS = RENDER_PROTOCOL["render"]
CAMERA_SETTINGS = RENDER_PROTOCOL["camera"]
VIEW_YAWS = RENDER_PROTOCOL["views_yaw_degrees"]
RESOLUTION = tuple(RENDER_SETTINGS["resolution_px"])
ORTHO_SCALE = CAMERA_SETTINGS["ortho_scale_mm"]
CAMERA_DISTANCE = CAMERA_SETTINGS["orbit_radius_mm"]
CAMERA_Z = CAMERA_SETTINGS["z_mm"]
TARGET = Vector(CAMERA_SETTINGS["target_mm"])
VIEW_ORDER = ("front", "left", "rear", "right", "hero")


def material(name: str, colour: tuple[float, float, float, float], roughness: float) -> bpy.types.Material:
    existing = bpy.data.materials.get(name)
    if existing is not None:
        return existing
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    bsdf = result.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = colour
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = 0.0
    return result


def aim_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def prepare_scene() -> tuple[bpy.types.Object, list[Failure]]:
    failures: list[Failure] = []
    bpy.ops.wm.open_mainfile(filepath=str(BLEND_PATH))
    scene = bpy.context.scene
    scene.render.engine = RENDER_SETTINGS["engine"]
    scene.render.resolution_x, scene.render.resolution_y = RESOLUTION
    scene.render.resolution_percentage = RENDER_SETTINGS["resolution_percentage"]
    scene.render.image_settings.file_format = RENDER_SETTINGS["file_format"]
    scene.render.image_settings.color_mode = RENDER_SETTINGS["color_mode"]
    scene.render.image_settings.color_depth = str(RENDER_SETTINGS["color_depth_bits"])
    scene.render.film_transparent = RENDER_SETTINGS["film_transparent"]
    scene.view_settings.look = RENDER_SETTINGS["view_look"]
    scene.render.filepath = ""
    scene.use_nodes = False
    scene.render.use_compositing = RENDER_SETTINGS["use_compositing"]
    scene.render.use_sequencer = RENDER_SETTINGS["use_sequencer"]

    # Remove all source cameras/lights and any stale review rig. The geometry
    # is rendered only under the authored protocol below.
    for obj in list(scene.objects):
        if obj.name.startswith("Review_") or obj.type in {"CAMERA", "LIGHT"}:
            bpy.data.objects.remove(obj, do_unlink=True)

    material_settings = RENDER_PROTOCOL["materials"]
    resin = material(
        "Review_Resin",
        tuple(material_settings["figure"]["rgba"]),
        material_settings["figure"]["roughness"],
    )
    base_resin = material(
        "Review_Base",
        tuple(material_settings["base"]["rgba"]),
        material_settings["base"]["roughness"],
    )
    renderable_types = {"MESH", "CURVE", "SURFACE", "META", "FONT", "VOLUME", "POINTCLOUD"}
    source_renderables = {
        obj.name: obj.type
        for obj in scene.objects
        if obj.type in renderable_types and not obj.name.startswith("Review_")
    }
    expected_mesh_names = set(PART_NAMES)
    for unexpected in sorted(set(source_renderables) - expected_mesh_names):
        failures.append(
            Failure(
                "unexpected_part",
                unexpected,
                f"unexpected renderable {source_renderables[unexpected]} is present in the source .blend",
            )
        )

    review_collection = bpy.data.collections.new("Review_Source")
    scene.collection.children.link(review_collection)
    for name in PART_NAMES:
        obj = scene.objects.get(name)
        if obj is None or obj.type != "MESH":
            failures.append(Failure("missing_part", name, "named mesh is absent from the current .blend"))
            continue
        obj.hide_render = False
        obj.hide_set(False)
        for collection in obj.users_collection:
            collection.hide_render = False
            collection.hide_viewport = False
        if review_collection.objects.get(obj.name) is None:
            review_collection.objects.link(obj)
        obj.data.materials.clear()
        obj.data.materials.append(base_resin if name == "Base_Keyed" else resin)
        # Smooth shading reveals the intended sculpted contour while the
        # neutral material keeps surface defects and seams legible.
        shading = material_settings["smooth_shading"]
        use_smooth = shading["Base_Keyed"] if name == "Base_Keyed" else shading["other_parts"]
        for polygon in obj.data.polygons:
            polygon.use_smooth = use_smooth

    world = scene.world or bpy.data.worlds.new("Review_World")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    if background is not None:
        world_settings = RENDER_PROTOCOL["world"]
        background.inputs["Color"].default_value = tuple(world_settings["background_rgba"])
        background.inputs["Strength"].default_value = world_settings["strength"]

    # A matte floor makes the base contact and balance direction readable.
    floor_settings = RENDER_PROTOCOL["floor"]
    bpy.ops.mesh.primitive_plane_add(
        size=floor_settings["size_mm"],
        location=tuple(floor_settings["location_mm"]),
    )
    floor = bpy.context.active_object
    floor.name = "Review_Floor"
    for collection in list(floor.users_collection):
        collection.objects.unlink(floor)
    review_collection.objects.link(floor)
    floor_material = floor_settings["material"]
    floor.data.materials.append(
        material(
            "Review_Floor_Mat",
            tuple(floor_material["rgba"]),
            floor_material["roughness"],
        )
    )

    camera_data = bpy.data.cameras.new("Review_Camera")
    camera_data.type = CAMERA_SETTINGS["projection"]
    camera_data.ortho_scale = ORTHO_SCALE
    camera = bpy.data.objects.new("Review_Camera", camera_data)
    review_collection.objects.link(camera)
    scene.camera = camera

    # Three broad sources: key defines form, fill prevents black recesses, rim
    # separates the rear ear/jacket silhouette from the background.
    # Sun sources are intentional here. The collectible's millimetre scene
    # scale makes inverse-square area-light energy needlessly machine/renderer
    # sensitive; directional energy stays stable across bpy and Blender.app.
    for light_settings in RENDER_PROTOCOL["lights"]:
        name = light_settings["name"]
        light_data = bpy.data.lights.new(name, light_settings["type"])
        light_data.energy = light_settings["energy"]
        light_data.angle = light_settings["angle_radians"]
        light = bpy.data.objects.new(name, light_data)
        light.location = tuple(light_settings["location_mm"])
        aim_at(light, TARGET)
        review_collection.objects.link(light)

    return camera, failures


def place_camera(camera: bpy.types.Object, yaw_degrees: float) -> None:
    import math

    yaw = math.radians(yaw_degrees)
    camera.location = (
        math.sin(yaw) * CAMERA_DISTANCE,
        -math.cos(yaw) * CAMERA_DISTANCE,
        CAMERA_Z,
    )
    aim_at(camera, TARGET)
    bpy.context.view_layer.update()


def image_failure(view: str, path: Path) -> Failure | None:
    with Image.open(path) as handle:
        image = handle.convert("RGB")
        if image.size != RESOLUTION:
            return Failure("dimensions", view, f"rendered {image.size}, expected {RESOLUTION}")
        luminance = ImageStat.Stat(image.convert("L")).stddev[0]
        if luminance < 6.0:
            return Failure("blank_render", view, f"luminance stddev {luminance:.2f} is effectively blank")
    return None


def make_contact_sheet(paths: dict[str, Path]) -> Path:
    tile_width, tile_height = RESOLUTION
    label_height = 34
    sheet = Image.new("RGB", (tile_width * 3, (tile_height + label_height) * 2), (20, 23, 28))
    draw = ImageDraw.Draw(sheet)
    for index, view in enumerate(VIEW_ORDER):
        row, column = divmod(index, 3)
        with Image.open(paths[view]) as handle:
            tile = handle.convert("RGB")
        x = column * tile_width
        y = row * (tile_height + label_height)
        sheet.paste(tile, (x, y))
        draw.text((x + 14, y + tile_height + 8), view.upper(), fill=(230, 232, 235))
    # The sixth tile is an explicit truth label, not an implied approval.
    x = 2 * tile_width
    y = tile_height + label_height
    draw.multiline_text(
        (x + 34, y + 70),
        "PROVISIONAL DIGITAL PROTOTYPE\n"
        "Neutral resin geometry review\n"
        "Identity approval + photo pack OPEN\n"
        "No physical print claim",
        fill=(230, 232, 235),
        spacing=13,
    )
    path = OUTPUT_DIR / "contact_sheet.png"
    sheet.save(path)
    return path


def _run() -> int:
    receipt_failures, build_receipt = check_build_receipt()
    if receipt_failures:
        payload = {
            "render_id": RENDER_ID,
            "source_blend": str(BLEND_PATH.relative_to(ROOT)),
            "source_blend_sha256": sha256_file(BLEND_PATH) if BLEND_PATH.is_file() else None,
            "build_receipt": {
                "path": str(BUILD_REPORT.relative_to(ROOT)),
                "sha256": sha256_file(BUILD_REPORT) if BUILD_REPORT.is_file() else None,
                "status": build_receipt.get("status"),
                "pipeline_version": build_receipt.get("pipeline_version"),
            },
            "resolution": list(RESOLUTION),
            "ortho_scale_mm": ORTHO_SCALE,
            "protocol": RENDER_PROTOCOL,
            "views": {},
            "contact_sheet": None,
            "failures": [failure.as_dict() for failure in receipt_failures],
        }
        write_json(OUTPUT_DIR / "render_report.json", payload)
        return report("COBIE_FIGURINE_RENDER", receipt_failures)

    camera, failures = prepare_scene()
    if failures:
        payload = {
            "render_id": RENDER_ID,
            "source_blend": str(BLEND_PATH.relative_to(ROOT)),
            "source_blend_sha256": sha256_file(BLEND_PATH),
            "build_receipt": {
                "path": str(BUILD_REPORT.relative_to(ROOT)),
                "sha256": sha256_file(BUILD_REPORT),
                "status": build_receipt.get("status"),
                "pipeline_version": build_receipt.get("pipeline_version"),
            },
            "resolution": list(RESOLUTION),
            "ortho_scale_mm": ORTHO_SCALE,
            "protocol": RENDER_PROTOCOL,
            "views": {},
            "contact_sheet": None,
            "failures": [failure.as_dict() for failure in failures],
        }
        write_json(OUTPUT_DIR / "render_report.json", payload)
        return report("COBIE_FIGURINE_RENDER", failures)
    paths: dict[str, Path] = {}
    for view in VIEW_ORDER:
        place_camera(camera, VIEW_YAWS[view])
        path = OUTPUT_DIR / f"{view}.png"
        bpy.context.scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths[view] = path
        failure = image_failure(view, path)
        if failure is not None:
            failures.append(failure)

    contact_sheet = make_contact_sheet(paths)
    payload = {
        "render_id": RENDER_ID,
        "source_blend": str(BLEND_PATH.relative_to(ROOT)),
        "source_blend_sha256": sha256_file(BLEND_PATH),
        "build_receipt": {
            "path": str(BUILD_REPORT.relative_to(ROOT)),
            "sha256": sha256_file(BUILD_REPORT),
            "status": build_receipt.get("status"),
            "pipeline_version": build_receipt.get("pipeline_version"),
        },
        "environment": {
            **receipt_module.environment_stamp(),
            "blender": bpy.app.version_string,
            "render_engine": bpy.context.scene.render.engine,
        },
        "resolution": list(RESOLUTION),
        "ortho_scale_mm": ORTHO_SCALE,
        "protocol": RENDER_PROTOCOL,
        "views": {
            view: {
                "yaw_degrees": VIEW_YAWS[view],
                "path": str(path.relative_to(ROOT)),
                "sha256": sha256_file(path),
            }
            for view, path in paths.items()
        },
        "contact_sheet": {
            "path": str(contact_sheet.relative_to(ROOT)),
            "sha256": sha256_file(contact_sheet),
        },
        "failures": [failure.as_dict() for failure in failures],
    }
    write_json(OUTPUT_DIR / "render_report.json", payload)
    print(f"  review packet: {OUTPUT_DIR.relative_to(ROOT)}")
    return report("COBIE_FIGURINE_RENDER", failures, {"views": len(paths)})


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUTPUT_DIR / "render_report.json"
    incomplete = Failure(
        "render_incomplete",
        str(output),
        "render packet started but has not completed",
    )
    write_json(
        output,
        {
            "render_id": RENDER_ID,
            "resolution": list(RESOLUTION),
            "ortho_scale_mm": ORTHO_SCALE,
            "protocol": RENDER_PROTOCOL,
            "views": {},
            "contact_sheet": None,
            "failures": [incomplete.as_dict()],
        },
    )
    try:
        return _run()
    except Exception as exc:
        failure = Failure("render_exception", str(output), f"{type(exc).__name__}: {exc}")
        write_json(
            output,
            {
                "render_id": RENDER_ID,
                "resolution": list(RESOLUTION),
                "ortho_scale_mm": ORTHO_SCALE,
                "protocol": RENDER_PROTOCOL,
                "views": {},
                "contact_sheet": None,
                "failures": [failure.as_dict()],
            },
        )
        return report("COBIE_FIGURINE_RENDER", [failure])


if __name__ == "__main__":
    raise SystemExit(main())
