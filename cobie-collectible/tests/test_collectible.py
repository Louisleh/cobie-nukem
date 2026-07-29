#!/usr/bin/env python3
"""Tests for the collectible pipeline.

Run:
    uv run --project cobie-collectible/tools \
        python cobie-collectible/tests/test_collectible.py

House style follows tools/visual_quality/test_capture_tool.py: unittest, direct
import of the module under test including its privates, tempfile sandboxes.

Deliberately NOT added to tools/release_validate.sh. That script invokes its
Python tests with bare `python3`, and these need numpy, trimesh and scipy, which
the CI runner does not install. Wiring them in there would break CI for reasons
unrelated to the figurine.

These tests avoid importing bpy, so they run in about a second.
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import receipt as receipt_module
from _common import CARDINAL_VIEWS, MIN_FEATURE_MM, view_seed
from print_check import check_part, measure_thickness, plate_thickness
from validate_turnaround import analyse, validate

DISTANCE = 300.0
HEIGHT = 140.0


def _make_receipt(tmp: Path, **overrides) -> dict:
    image_path = tmp / "front.png"
    Image.new("RGBA", (512, 512), (128, 128, 128, 255)).save(image_path)
    origin = receipt_module.expected_camera_origin(0.0, DISTANCE, HEIGHT)
    target = (0.0, 0.0, HEIGHT * 0.5)
    direction = tuple(t - o for t, o in zip(target, origin))
    entry = receipt_module.build(
        view="front",
        candidate_id="cand",
        render_seed=1,
        render_engine="BLENDER_EEVEE",
        resolution=(512, 512),
        camera_origin=origin,
        camera_forward=direction,
        ortho_scale=180.0,
        yaw_degrees=0.0,
        mesh_sha256="0" * 64,
        image_path=image_path,
        root=tmp,
    )
    entry.update(overrides)
    return entry


class ReceiptTest(unittest.TestCase):
    def test_clean_receipt_verifies(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            failures = receipt_module.verify(_make_receipt(tmp), distance=DISTANCE, height=HEIGHT, root=tmp)
            self.assertEqual(failures, [])

    def test_extra_field_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            entry["sneaky"] = True
            failures = receipt_module.verify(entry, distance=DISTANCE, height=HEIGHT, root=tmp)
            self.assertEqual([f.check for f in failures], ["receipt_schema"])

    def test_missing_field_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            del entry["ortho_scale"]
            failures = receipt_module.verify(entry, distance=DISTANCE, height=HEIGHT, root=tmp)
            self.assertEqual([f.check for f in failures], ["receipt_schema"])

    def test_edited_image_breaks_the_hash(self) -> None:
        """The whole point of the receipt: the image cannot change silently."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            Image.new("RGBA", (512, 512), (10, 200, 10, 255)).save(tmp / "front.png")
            failures = receipt_module.verify(entry, distance=DISTANCE, height=HEIGHT, root=tmp)
            self.assertIn("image_sha256", [f.check for f in failures])

    def test_moved_camera_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            entry["camera_origin"] = [entry["camera_origin"][0] + 5.0, *entry["camera_origin"][1:]]
            failures = receipt_module.verify(entry, distance=DISTANCE, height=HEIGHT, root=tmp)
            self.assertIn("camera_position", [f.check for f in failures])

    def test_resized_image_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            entry["requested_resolution"] = [1024, 1024]
            failures = receipt_module.verify(entry, distance=DISTANCE, height=HEIGHT, root=tmp)
            self.assertIn("dimensions", [f.check for f in failures])

    def test_yaw_positions_are_distinct_and_reproducible(self) -> None:
        origins = {view: receipt_module.expected_camera_origin(yaw, DISTANCE, HEIGHT)
                   for view, yaw in zip(CARDINAL_VIEWS, (0.0, 90.0, 180.0, 270.0))}
        self.assertEqual(len(set(tuple(round(c, 6) for c in o) for o in origins.values())), 4)
        self.assertEqual(origins["front"], receipt_module.expected_camera_origin(0.0, DISTANCE, HEIGHT))


class SeedTest(unittest.TestCase):
    def test_seeds_are_stable_and_view_specific(self) -> None:
        self.assertEqual(view_seed("front"), view_seed("front"))
        self.assertNotEqual(view_seed("front"), view_seed("rear"))


class PrintCheckTest(unittest.TestCase):
    def test_thin_plate_is_rejected(self) -> None:
        """A 0.6 mm plate must fail; this is the control for the whole check."""
        plate = trimesh.creation.box(extents=[40.0, 40.0, 0.6])
        thickness = measure_thickness(plate, samples=600)
        self.assertGreater(thickness.size, 0)
        self.assertGreater(float((thickness < MIN_FEATURE_MM).mean()), 0.5)

    def test_thick_block_passes(self) -> None:
        block = trimesh.creation.box(extents=[40.0, 40.0, 12.0])
        failures = check_part("Block", block)
        self.assertNotIn("min_thickness", [f.check for f in failures])

    def test_disconnected_bodies_are_reported(self) -> None:
        left = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right.apply_translation([50.0, 0.0, 0.0])
        combined = trimesh.util.concatenate([left, right])
        self.assertIn("floating_shells", [f.check for f in check_part("Split", combined)])

    def test_plate_thickness_ignores_the_keying_peg(self) -> None:
        """Bounding-box height overstates plate thickness once a peg exists."""
        disc = trimesh.creation.cylinder(radius=35.0, height=5.0)
        disc.apply_translation([0.0, 0.0, 2.5])
        peg = trimesh.creation.cylinder(radius=6.0, height=6.0)
        peg.apply_translation([0.0, 0.0, 7.0])
        base = trimesh.util.concatenate([disc, peg])
        self.assertAlmostEqual(plate_thickness(base, 70.0), 5.0, places=2)
        self.assertGreater(base.bounds[1][2] - base.bounds[0][2], 9.0)


def _view_image(path: Path, *, height: int = 400, width: int = 120, top: int = 40, centre: int = 256) -> None:
    canvas = np.full((512, 512, 4), 255, dtype=np.uint8)
    canvas[..., :3] = 240
    half = width // 2
    canvas[top : top + height, centre - half : centre + half, :3] = (214, 158, 96)
    canvas[top : top + 60, centre - half : centre + half, :3] = (28, 26, 28)
    Image.fromarray(canvas).save(path)


class TurnaroundTest(unittest.TestCase):
    def test_consistent_views_pass(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for view in CARDINAL_VIEWS:
                path = tmp / f"{view}.png"
                _view_image(path)
                metrics[view] = analyse(path)
            self.assertEqual(validate(metrics), [])

    def test_scale_drift_between_views_is_caught(self) -> None:
        """The failure this whole gate exists for."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for index, view in enumerate(CARDINAL_VIEWS):
                path = tmp / f"{view}.png"
                _view_image(path, height=400 if index else 300)
                metrics[view] = analyse(path)
            self.assertIn("scale_drift", [f.check for f in validate(metrics)])

    def test_off_centre_subject_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for index, view in enumerate(CARDINAL_VIEWS):
                path = tmp / f"{view}.png"
                _view_image(path, centre=256 if index else 120)
                metrics[view] = analyse(path)
            self.assertIn("centring", [f.check for f in validate(metrics)])

    def test_missing_rear_view_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for view in ("front", "left", "right"):
                path = tmp / f"{view}.png"
                _view_image(path)
                metrics[view] = analyse(path)
            self.assertIn("missing_views", [f.check for f in validate(metrics)])


if __name__ == "__main__":
    unittest.main(verbosity=2)
