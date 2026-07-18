"""Build deterministic Web-safe Rain City and Mount Hood material libraries.

The editable Material Maker graphs remain the semantic authoring records. This
script makes reproducible 512px preview/runtime exports for CI and local builds
without requiring Material Maker to run headlessly.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SIZE = 512


FAMILIES = {
    "rain_city": {
        "wet_asphalt": ((12, 20, 24), (55, 68, 72), 0.28, 0.02, "noise"),
        "rain_brick": ((44, 18, 17), (118, 55, 43), 0.58, 0.00, "brick"),
        "glass_panels": ((16, 54, 66), (78, 124, 132), 0.18, 0.38, "panels"),
        "seawall_concrete": ((58, 67, 70), (126, 136, 135), 0.50, 0.00, "concrete"),
        "harbour_steel": ((42, 55, 58), (104, 121, 120), 0.36, 0.70, "metal"),
        "painted_municipal_metal": ((42, 47, 43), (188, 129, 34), 0.40, 0.42, "paint"),
        "terminal_floor": ((36, 48, 51), (88, 101, 101), 0.46, 0.08, "panels"),
        "slice_tile": ((98, 35, 22), (224, 130, 58), 0.42, 0.00, "tile"),
        "wet_wood": ((37, 20, 10), (105, 62, 28), 0.56, 0.00, "wood"),
        "route_decals": ((22, 31, 34), (236, 191, 69), 0.40, 0.00, "stripes"),
    },
    "mount_hood": {
        "fresh_powder": ((176, 202, 218), (246, 250, 250), 0.72, 0.00, "snow"),
        "packed_snow": ((133, 169, 187), (224, 238, 241), 0.60, 0.00, "ridges"),
        "icy_slush": ((55, 79, 91), (152, 183, 193), 0.24, 0.00, "noise"),
        "exposed_rock": ((40, 46, 49), (102, 111, 110), 0.78, 0.00, "rock"),
        "plowed_asphalt": ((19, 27, 30), (67, 78, 79), 0.42, 0.02, "stripes"),
        "lodge_timber": ((47, 23, 10), (132, 74, 31), 0.66, 0.00, "wood"),
        "lodge_stone": ((54, 54, 50), (128, 122, 107), 0.76, 0.00, "stone"),
        "lift_steel": ((48, 58, 62), (128, 139, 137), 0.42, 0.68, "metal"),
        "frosted_glass": ((89, 133, 151), (190, 219, 225), 0.28, 0.18, "frost"),
        "warm_windows": ((122, 49, 14), (255, 184, 72), 0.26, 0.04, "panels"),
    },
}


def _height(pattern: str, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:SIZE, 0:SIZE]
    base = rng.random((SIZE, SIZE), dtype=np.float32)
    for step, weight in ((2, 0.28), (8, 0.24), (24, 0.18), (64, 0.12)):
        cells = max(2, (SIZE + step - 1) // step)
        coarse = rng.random((cells, cells), dtype=np.float32)
        coarse = np.repeat(np.repeat(coarse, step, axis=0), step, axis=1)[:SIZE, :SIZE]
        base += coarse * weight
    if pattern == "brick":
        mortar = ((y % 48) < 4) | (((x + ((y // 48) % 2) * 32) % 64) < 4)
        base = base * 0.35 + 0.55
        base[mortar] = 0.08
    elif pattern in {"panels", "tile"}:
        grid = ((x % 96) < 4) | ((y % 96) < 4)
        base = base * 0.25 + 0.60
        base[grid] = 0.12
    elif pattern == "wood":
        base = 0.48 + 0.22 * np.sin(x / 9.0 + np.sin(y / 31.0)) + base * 0.10
    elif pattern == "stripes":
        base = 0.28 + base * 0.18
        base[((x + y) % 160) < 16] = 0.90
    elif pattern == "snow":
        base = 0.76 + base * 0.16
    elif pattern == "ridges":
        base = 0.58 + 0.18 * np.sin((x + y) / 28.0) + base * 0.08
    elif pattern in {"rock", "stone"}:
        base = np.power(base, 1.8)
    elif pattern == "metal":
        base = 0.50 + 0.16 * np.sin(y / 7.0) + base * 0.10
    elif pattern == "paint":
        base = 0.66 + base * 0.14
        base[rng.random((SIZE, SIZE)) > 0.992] = 0.12
    elif pattern == "frost":
        base = 0.62 + np.abs(np.sin(x / 37.0) * np.cos(y / 29.0)) * 0.25
    elif pattern == "concrete":
        base = 0.45 + base * 0.32
    return np.clip(base, 0.0, 1.0)


def _normal(height: np.ndarray, strength: float = 2.2) -> np.ndarray:
    gy, gx = np.gradient(height)
    nx = -gx * strength
    ny = -gy * strength
    nz = np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.stack(((nx / length + 1) * 0.5, (ny / length + 1) * 0.5, nz / length), axis=-1)
    return np.uint8(np.clip(rgb * 255, 0, 255))


def _ptex(name: str, low: tuple[int, int, int], high: tuple[int, int, int], rough: float, metal: float) -> dict:
    return {
        "type": "graph", "name": name, "label": name.replace("_", " ").title(),
        "connections": [
            {"from": "surface_pattern", "from_port": 0, "to": "surface_color", "to_port": 0},
            {"from": "surface_color", "from_port": 0, "to": "Material", "to_port": 0},
            {"from": "surface_pattern", "from_port": 0, "to": "surface_normal", "to_port": 0},
            {"from": "surface_normal", "from_port": 0, "to": "Material", "to_port": 4},
        ],
        "nodes": [
            {"name": "surface_pattern", "type": "pattern", "node_position": {"x": -420, "y": 160}, "parameters": {"mix": 4, "x_scale": 96, "x_wave": 2, "y_scale": 96, "y_wave": 2}},
            {"name": "surface_color", "type": "colorize", "node_position": {"x": -130, "y": 70}, "parameters": {"gradient": {"type": "Gradient", "interpolation": 1, "points": [{"pos": 0.1, "r": low[0] / 255, "g": low[1] / 255, "b": low[2] / 255, "a": 1}, {"pos": 0.9, "r": high[0] / 255, "g": high[1] / 255, "b": high[2] / 255, "a": 1}]}}},
            {"name": "surface_normal", "type": "normal_map", "node_position": {"x": 130, "y": 260}, "parameters": {"amount": 0.22, "param0": 11, "param1": 0.99, "param2": 0, "param3": 0, "param4": 1, "size": 2}},
            {"name": "Material", "type": "material", "node_position": {"x": 450, "y": 110}, "parameters": {"albedo_color": {"type": "Color", "r": low[0] / 255, "g": low[1] / 255, "b": low[2] / 255, "a": 1}, "ao_light_affect": 1, "depth_scale": 1, "emission_energy": 1, "metallic": metal, "normal_scale": 0.35, "resolution": 1, "roughness": rough, "size": 11, "subsurf_scatter_strength": 0}},
        ], "parameters": {}, "node_position": {"x": 0, "y": 0},
    }


def build() -> None:
    source_dir = ROOT / "assets/source/material_maker"
    for mission_index, (mission, families) in enumerate(FAMILIES.items()):
        texture_dir = ROOT / "assets/textures/materials" / mission
        material_dir = ROOT / "assets/materials" / mission
        texture_dir.mkdir(parents=True, exist_ok=True)
        material_dir.mkdir(parents=True, exist_ok=True)
        for index, (name, (low, high, rough, metal, pattern)) in enumerate(families.items()):
            height = _height(pattern, mission_index * 100 + index + 1)
            low_arr = np.array(low, dtype=np.float32)
            high_arr = np.array(high, dtype=np.float32)
            albedo = low_arr + (high_arr - low_arr) * height[..., None]
            orm = np.zeros((SIZE, SIZE, 3), dtype=np.uint8)
            orm[..., 0] = np.uint8(np.clip((0.78 + height * 0.20) * 255, 0, 255))
            orm[..., 1] = np.uint8(np.clip((rough + (height - 0.5) * 0.10) * 255, 0, 255))
            orm[..., 2] = np.uint8(np.clip(metal * 255, 0, 255))
            Image.fromarray(np.uint8(np.clip(albedo, 0, 255))).save(texture_dir / f"{name}_albedo.png", optimize=True)
            Image.fromarray(_normal(height)).save(texture_dir / f"{name}_normal.png", optimize=True)
            Image.fromarray(orm).save(texture_dir / f"{name}_orm.png", optimize=True)
            graph_path = source_dir / f"{mission}_{name}.ptex"
            graph_path.write_text(json.dumps(_ptex(f"{mission}_{name}", low, high, rough, metal), indent=2) + "\n")
            tres = f'''[gd_resource type="StandardMaterial3D" load_steps=4 format=3]\n\n[ext_resource type="Texture2D" path="res://assets/textures/materials/{mission}/{name}_albedo.png" id="1"]\n[ext_resource type="Texture2D" path="res://assets/textures/materials/{mission}/{name}_normal.png" id="2"]\n[ext_resource type="Texture2D" path="res://assets/textures/materials/{mission}/{name}_orm.png" id="3"]\n\n[resource]\nresource_name = "{mission}_{name}"\nalbedo_texture = ExtResource("1")\nnormal_enabled = true\nnormal_scale = 0.35\nnormal_texture = ExtResource("2")\nao_enabled = true\nroughness = 1.0\nmetallic = 1.0\norm_texture = ExtResource("3")\ntexture_filter = 1\nuv1_scale = Vector3(4, 4, 4)\n'''
            (material_dir / f"{name}.tres").write_text(tres)
    print("Built mission material library:", sum(len(v) for v in FAMILIES.values()), "families")


if __name__ == "__main__":
    build()
