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

import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import receipt as receipt_module
from _common import (
    CARDINAL_VIEWS,
    MIN_FEATURE_MM,
    PART_NAMES,
    PIPELINE_VERSION,
    TURNAROUND_VIEWS,
    candidate_count_failures,
    check_build_receipt,
    portable_path,
    sha256_file,
    view_seed,
    write_json,
)
from print_check import (
    _decimate,
    build_report_payload,
    check_export_inventory,
    check_interpart_overlaps,
    check_part,
    cylindrical_radial_clearance_probe,
    cylindrical_sideband_probe,
    evaluate_joint_clearance,
    measure_thickness,
    plate_thickness,
)
from slicer_import_check import parse_info_output, validate_info
from validate_turnaround import analyse, validate

DISTANCE = 300.0
HEIGHT = 140.0
ALL_TURNAROUND_VIEWS = tuple(TURNAROUND_VIEWS)


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
            failures = receipt_module.verify(
                _make_receipt(tmp),
                distance=DISTANCE,
                height=HEIGHT,
                ortho_scale=180.0,
                root=tmp,
            )
            self.assertEqual(failures, [])

    def test_extra_field_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            entry["sneaky"] = True
            failures = receipt_module.verify(
                entry, distance=DISTANCE, height=HEIGHT, ortho_scale=180.0, root=tmp
            )
            self.assertEqual([f.check for f in failures], ["receipt_schema"])

    def test_missing_field_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            del entry["ortho_scale"]
            failures = receipt_module.verify(
                entry, distance=DISTANCE, height=HEIGHT, ortho_scale=180.0, root=tmp
            )
            self.assertEqual([f.check for f in failures], ["receipt_schema"])

    def test_edited_image_breaks_the_hash(self) -> None:
        """The whole point of the receipt: the image cannot change silently."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            Image.new("RGBA", (512, 512), (10, 200, 10, 255)).save(tmp / "front.png")
            failures = receipt_module.verify(
                entry, distance=DISTANCE, height=HEIGHT, ortho_scale=180.0, root=tmp
            )
            self.assertIn("image_sha256", [f.check for f in failures])

    def test_moved_camera_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            entry["camera_origin"] = [entry["camera_origin"][0] + 5.0, *entry["camera_origin"][1:]]
            failures = receipt_module.verify(
                entry, distance=DISTANCE, height=HEIGHT, ortho_scale=180.0, root=tmp
            )
            self.assertIn("camera_position", [f.check for f in failures])

    def test_resized_image_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp)
            entry["requested_resolution"] = [1024, 1024]
            failures = receipt_module.verify(
                entry, distance=DISTANCE, height=HEIGHT, ortho_scale=180.0, root=tmp
            )
            self.assertIn("dimensions", [f.check for f in failures])

    def test_changed_ortho_scale_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            entry = _make_receipt(tmp, ortho_scale=999.0)
            failures = receipt_module.verify(
                entry, distance=DISTANCE, height=HEIGHT, ortho_scale=180.0, root=tmp
            )
            self.assertIn("ortho_scale", [failure.check for failure in failures])

    def test_yaw_positions_are_distinct_and_reproducible(self) -> None:
        origins = {view: receipt_module.expected_camera_origin(yaw, DISTANCE, HEIGHT)
                   for view, yaw in zip(CARDINAL_VIEWS, (0.0, 90.0, 180.0, 270.0))}
        self.assertEqual(len(set(tuple(round(c, 6) for c in o) for o in origins.values())), 4)
        self.assertEqual(origins["front"], receipt_module.expected_camera_origin(0.0, DISTANCE, HEIGHT))


class SeedTest(unittest.TestCase):
    def test_seeds_are_stable_and_view_specific(self) -> None:
        self.assertEqual(view_seed("front"), view_seed("front"))
        self.assertNotEqual(view_seed("front"), view_seed("rear"))


class PortablePathTest(unittest.TestCase):
    def test_repo_path_is_relative(self) -> None:
        root = Path("/workspace/project")
        self.assertEqual(
            portable_path(root / "reports" / "result.json", root=root),
            "reports/result.json",
        )

    def test_macos_bundle_path_drops_machine_root(self) -> None:
        self.assertEqual(
            portable_path(
                "/Applications/PrusaSlicer.app/Contents/MacOS/PrusaSlicer",
                root=Path("/workspace/project"),
            ),
            "PrusaSlicer.app/Contents/MacOS/PrusaSlicer",
        )


class BakeoffGateTest(unittest.TestCase):
    def test_fewer_than_three_candidates_is_a_failure(self) -> None:
        failures = candidate_count_failures(2)
        self.assertEqual([failure.check for failure in failures], ["candidate_count"])
        self.assertEqual(candidate_count_failures(3), [])


class PrintCheckTest(unittest.TestCase):
    @staticmethod
    def _touch_export_set(directory: Path, names: tuple[str, ...]) -> None:
        for name in names:
            (directory / f"{name}.stl").touch()

    def test_exact_export_inventory_passes(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            self._touch_export_set(tmp, PART_NAMES)
            self.assertEqual(check_export_inventory(tmp), [])

    def test_incomplete_export_inventory_cannot_pass(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            missing = "Cobie_Sunglasses"
            self._touch_export_set(tmp, tuple(name for name in PART_NAMES if name != missing))
            failures = check_export_inventory(tmp)
            self.assertEqual(
                [(failure.check, failure.subject) for failure in failures],
                [("missing_part", f"{missing}.stl")],
            )

    def test_mixed_stale_export_inventory_cannot_pass_at_five_files(self) -> None:
        """Four current parts plus one stale filename must not satisfy the gate."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            missing = "Cobie_Head"
            current = tuple(name for name in PART_NAMES if name != missing)
            self._touch_export_set(tmp, current)
            (tmp / "Cobie_Head_previous.stl").touch()

            self.assertEqual(len(list(tmp.glob("*.stl"))), len(PART_NAMES))
            failures = check_export_inventory(tmp)
            self.assertEqual(
                {(failure.check, failure.subject) for failure in failures},
                {
                    ("missing_part", "Cobie_Head.stl"),
                    ("unexpected_part", "Cobie_Head_previous.stl"),
                },
            )

    def test_report_payload_records_reproducibility_environment(self) -> None:
        payload = build_report_payload({}, [])
        self.assertIn("description", payload["environment"]["platform"])
        self.assertIn("version", payload["environment"]["python"])
        self.assertEqual(
            set(payload["environment"]["packages"]),
            {
                "bpy",
                "manifold3d",
                "numpy",
                "pillow",
                "pymeshlab",
                "rtree",
                "scipy",
                "trimesh",
            },
        )

    def _build_receipt_fixture(self, tmp: Path) -> tuple[Path, Path, Path]:
        exports = tmp / "exports"
        exports.mkdir()
        for name in PART_NAMES:
            (exports / f"{name}.stl").write_bytes(f"{name}\n".encode())
        blend = tmp / "model.blend"
        blend.write_bytes(b"blend")
        receipt = exports / "build_report.json"
        write_json(
            receipt,
            {
                "status": "PASS",
                "mode": "provisional_game_art_prototype",
                "pipeline_version": PIPELINE_VERSION,
                "selected_candidate_sha256": None,
                "source_blend": str(blend),
                "source_blend_sha256": sha256_file(blend),
                "exports": {
                    f"{name}.stl": sha256_file(exports / f"{name}.stl")
                    for name in PART_NAMES
                },
            },
        )
        return exports, blend, receipt

    def test_build_receipt_binds_all_export_and_blend_hashes(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            exports, blend, receipt = self._build_receipt_fixture(Path(raw))
            failures, _ = check_build_receipt(
                exports=exports,
                receipt_path=receipt,
                blend_path=blend,
            )
            self.assertEqual(failures, [])
            (exports / "Cobie_Head.stl").write_bytes(b"tampered")
            failures, _ = check_build_receipt(
                exports=exports,
                receipt_path=receipt,
                blend_path=blend,
            )
            self.assertIn("build_receipt_hash", [failure.check for failure in failures])

    def test_selected_candidate_appearing_invalidates_provisional_receipt(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            exports, blend, receipt = self._build_receipt_fixture(tmp)
            selected = tmp / "selected.glb"
            selected.write_bytes(b"new candidate")
            failures, _ = check_build_receipt(
                exports=exports,
                receipt_path=receipt,
                blend_path=blend,
                selected_mesh=selected,
            )
            checks = [failure.check for failure in failures]
            self.assertIn("build_receipt_mode", checks)
            self.assertIn("build_receipt_selected_hash", checks)

    def test_reviewed_candidate_receipt_binds_selected_mesh_hash(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            exports, blend, receipt = self._build_receipt_fixture(tmp)
            selected = tmp / "selected.glb"
            selected.write_bytes(b"reviewed candidate")
            payload = json.loads(receipt.read_text())
            payload["mode"] = "selected_candidate_reviewed"
            payload["selected_candidate_sha256"] = sha256_file(selected)
            write_json(receipt, payload)
            failures, _ = check_build_receipt(
                exports=exports,
                receipt_path=receipt,
                blend_path=blend,
                selected_mesh=selected,
            )
            self.assertEqual(failures, [])
            selected.write_bytes(b"changed candidate")
            failures, _ = check_build_receipt(
                exports=exports,
                receipt_path=receipt,
                blend_path=blend,
                selected_mesh=selected,
            )
            self.assertIn(
                "build_receipt_selected_hash",
                [failure.check for failure in failures],
            )

    def test_build_receipt_rejects_missing_extra_and_symlink_exports(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            exports, blend, receipt = self._build_receipt_fixture(Path(raw))
            (exports / "Cobie_Head.stl").unlink()
            (exports / "Cobie_Head.stl").symlink_to(exports / "Cobie_Body.stl")
            (exports / "stale.STL").write_bytes(b"case drift")
            failures, _ = check_build_receipt(
                exports=exports,
                receipt_path=receipt,
                blend_path=blend,
            )
            checks = [failure.check for failure in failures]
            self.assertIn("build_receipt_disk_inventory", checks)
            self.assertIn("build_receipt_export_missing", checks)

    def test_build_receipt_rejects_non_object_json(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            exports, blend, receipt = self._build_receipt_fixture(Path(raw))
            receipt.write_text("[]\n")
            failures, _ = check_build_receipt(
                exports=exports,
                receipt_path=receipt,
                blend_path=blend,
            )
            self.assertEqual([failure.check for failure in failures], ["build_receipt_invalid"])

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

    def test_high_face_mesh_decimates_with_wheel_plugins(self) -> None:
        """The macOS wheel may import with zero plugins; the gate must recover."""
        sphere = trimesh.creation.icosphere(subdivisions=5, radius=20.0)
        reduced = _decimate(sphere, face_budget=4000)
        self.assertGreater(reduced.faces.shape[0], 0)
        self.assertLess(reduced.faces.shape[0], sphere.faces.shape[0])
        self.assertLessEqual(reduced.faces.shape[0], 4000)

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

    def test_cylindrical_clearance_is_measured_on_exported_surfaces(self) -> None:
        male = trimesh.creation.cylinder(radius=5.0, height=8.0, sections=64).subdivide()
        female = trimesh.creation.annulus(r_min=5.25, r_max=8.0, height=10.0, sections=64)
        result = cylindrical_sideband_probe(
            male,
            female,
            centre=(0.0, 0.0, 0.0),
            axis=2,
            radius=5.0,
            axial_min=-1.0,
            axial_max=1.0,
            radial_band=0.2,
        )
        self.assertGreater(result["sample_count"], 0)
        self.assertEqual(result["inside_count"], 0)
        self.assertAlmostEqual(result["min_sampled_gap_mm"], 0.25, delta=0.02)

    def test_radial_clearance_measures_complete_uniform_socket(self) -> None:
        male = trimesh.creation.cylinder(radius=5.0, height=8.0, sections=128)
        female = trimesh.creation.annulus(r_min=5.25, r_max=8.0, height=10.0, sections=128)
        result = cylindrical_radial_clearance_probe(
            male,
            female,
            centre=(0.0, 0.0, 0.0),
            axis=2,
            axial_min=-2.0,
            axial_max=2.0,
        )
        self.assertEqual(result["coverage_ratio"], 1.0)
        self.assertAlmostEqual(result["gap_p05_mm"], 0.25, delta=0.01)
        self.assertAlmostEqual(result["gap_p95_mm"], 0.25, delta=0.01)
        self.assertEqual(evaluate_joint_clearance("uniform", result), [])

    def test_local_good_point_cannot_hide_mostly_loose_socket(self) -> None:
        result = {
            "sample_count": 256,
            "coverage_ratio": 1.0,
            "inside_count": 0,
            "max_interpenetration_mm": 0.0,
            "gap_p05_mm": 0.25,
            "gap_p95_mm": 0.60,
        }
        failures = evaluate_joint_clearance("loose", result)
        self.assertEqual([failure.check for failure in failures], ["joint_clearance"])

    def test_interpart_overlap_is_rejected(self) -> None:
        left = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right.apply_translation([4.0, 0.0, 0.0])
        failures, metrics = check_interpart_overlaps(
            {"left": left, "right": right},
            pairs=(("left", "right"),),
        )
        self.assertIn("interpart_overlap", [failure.check for failure in failures])
        self.assertIn("left<->right", metrics)

    def test_all_ten_pairs_include_previously_omitted_head_prop_collision(self) -> None:
        parts = {}
        for index, name in enumerate(PART_NAMES):
            mesh = trimesh.creation.box(extents=[2.0, 2.0, 2.0])
            mesh.apply_translation([index * 10.0, 0.0, 0.0])
            parts[name] = mesh
        parts["Cobie_Prop_FetchLauncher"] = parts["Cobie_Head"].copy()
        failures, metrics = check_interpart_overlaps(parts)
        self.assertEqual(len(metrics), 10)
        self.assertIn(
            "Cobie_Head<->Cobie_Prop_FetchLauncher",
            [failure.subject for failure in failures],
        )

    def test_localized_corner_overlap_cannot_hide_from_exact_boolean(self) -> None:
        left = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right.apply_translation([9.6, 9.6, 9.6])
        failures, metrics = check_interpart_overlaps(
            {"left": left, "right": right},
            pairs=(("left", "right"),),
        )
        self.assertIn("interpart_overlap", [failure.check for failure in failures])
        self.assertAlmostEqual(
            metrics["left<->right"]["intersection_volume_mm3"],
            0.064,
            places=6,
        )

    def test_exact_face_contact_has_zero_volume_and_passes(self) -> None:
        left = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        right.apply_translation([10.0, 0.0, 0.0])
        failures, metrics = check_interpart_overlaps(
            {"left": left, "right": right},
            pairs=(("left", "right"),),
        )
        self.assertEqual(failures, [])
        self.assertEqual(metrics["left<->right"]["intersection_volume_mm3"], 0.0)

    def test_non_volume_input_fails_overlap_measurement_loudly(self) -> None:
        solid = trimesh.creation.box(extents=[10.0, 10.0, 10.0])
        open_mesh = solid.copy()
        open_mesh.update_faces(np.arange(len(open_mesh.faces) - 1))
        failures, _ = check_interpart_overlaps(
            {"solid": solid, "open": open_mesh},
            pairs=(("solid", "open"),),
        )
        self.assertIn(
            "interpart_overlap_unmeasured",
            [failure.check for failure in failures],
        )


class SlicerImportTest(unittest.TestCase):
    def test_prusaslicer_info_parser_and_gate(self) -> None:
        output = """[Cobie_Head.stl]
size_x = 49.4
size_y = 42.0
size_z = 43.2
number_of_facets = 54240
manifold = yes
number_of_parts =  1
"""
        values = parse_info_output(output)
        self.assertEqual(values["number_of_parts"], "1")
        self.assertEqual(validate_info("Cobie_Head.stl", values), [])

    def test_non_finite_slicer_dimension_is_rejected(self) -> None:
        values = {
            "size_x": "nan",
            "size_y": "42.0",
            "size_z": "43.2",
            "number_of_facets": "54240",
            "manifold": "yes",
            "number_of_parts": "1",
        }
        self.assertIn(
            "slicer_dimensions",
            [failure.check for failure in validate_info("Cobie_Head.stl", values)],
        )


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
            for view in ALL_TURNAROUND_VIEWS:
                path = tmp / f"{view}.png"
                _view_image(path)
                metrics[view] = analyse(path)
            self.assertEqual(validate(metrics), [])

    def test_scale_drift_between_views_is_caught(self) -> None:
        """The failure this whole gate exists for."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for index, view in enumerate(ALL_TURNAROUND_VIEWS):
                path = tmp / f"{view}.png"
                _view_image(path, height=400 if index else 300)
                metrics[view] = analyse(path)
            self.assertIn("scale_drift", [f.check for f in validate(metrics)])

    def test_hero_scale_drift_is_caught(self) -> None:
        """The three-quarter view is a geometry input, not a loose mood image."""
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for view in CARDINAL_VIEWS + ("hero",):
                path = tmp / f"{view}.png"
                _view_image(path, height=300 if view == "hero" else 400)
                metrics[view] = analyse(path)
            self.assertIn("scale_drift", [f.check for f in validate(metrics)])

    def test_mixed_image_dimensions_are_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for view in ALL_TURNAROUND_VIEWS:
                path = tmp / f"{view}.png"
                _view_image(path)
                if view == "hero":
                    with Image.open(path) as handle:
                        handle.resize((1024, 1024)).save(path)
                metrics[view] = analyse(path)
            self.assertIn("image_dimensions", [failure.check for failure in validate(metrics)])

    def test_off_centre_subject_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for index, view in enumerate(ALL_TURNAROUND_VIEWS):
                path = tmp / f"{view}.png"
                _view_image(path, centre=256 if index else 120)
                metrics[view] = analyse(path)
            self.assertIn("centring", [f.check for f in validate(metrics)])

    def test_missing_rear_view_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for view in ("front", "left", "right", "hero"):
                path = tmp / f"{view}.png"
                _view_image(path)
                metrics[view] = analyse(path)
            self.assertIn("missing_views", [f.check for f in validate(metrics)])

    def test_missing_hero_view_is_caught(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            metrics = {}
            for view in CARDINAL_VIEWS:
                path = tmp / f"{view}.png"
                _view_image(path)
                metrics[view] = analyse(path)
            self.assertIn("missing_views", [f.check for f in validate(metrics)])


if __name__ == "__main__":
    unittest.main(verbosity=2)
