#!/usr/bin/env python3
import os
from contextlib import redirect_stdout
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
import capture_tool


class CaptureUserDataIsolationTest(unittest.TestCase):
    def test_isolated_env_cannot_read_or_mutate_production_user_data(self) -> None:
        with tempfile.TemporaryDirectory(prefix="capture-isolation-test-") as temp:
            root = Path(temp)
            production_home = root / "production-home"
            production_data = production_home / "Library/Application Support/Godot/app_userdata/Cobie Nukem"
            production_data.mkdir(parents=True)
            production_marker = production_data / "checkpoint.json"
            production_marker.write_text("production-checkpoint", encoding="utf-8")

            with patch.dict(
                os.environ,
                {"HOME": str(production_home), "CFFIXED_USER_HOME": str(production_home)},
            ):
                isolated_root = root / "capture-user-data"
                env = capture_tool._isolated_capture_env(isolated_root)
                probe = """
import os
from pathlib import Path
home = Path(os.environ['HOME'])
assert os.environ['CFFIXED_USER_HOME'] == str(home)
user_data = home / 'Library/Application Support/Godot/app_userdata/Cobie Nukem'
if (user_data / 'checkpoint.json').exists():
    raise SystemExit('capture inherited production checkpoint')
user_data.mkdir(parents=True, exist_ok=True)
(user_data / 'capture-probe.txt').write_text('isolated', encoding='utf-8')
"""
                subprocess.check_call([sys.executable, "-c", probe], env=env)

            self.assertEqual(production_marker.read_text(encoding="utf-8"), "production-checkpoint")
            isolated_probe = (
                isolated_root
                / "home/Library/Application Support/Godot/app_userdata/Cobie Nukem/capture-probe.txt"
            )
            self.assertEqual(isolated_probe.read_text(encoding="utf-8"), "isolated")

    def test_direct_capture_launch_receives_isolated_env(self) -> None:
        with tempfile.TemporaryDirectory(prefix="direct-capture-env-test-") as temp:
            output_root = Path(temp)
            capture_project = output_root / "project-1680x1050"
            capture_project.mkdir(parents=True)
            (capture_project / "project.godot").write_text("[application]\n", encoding="utf-8")
            expected_frame = output_root / "route-1680x1050/capture00000001.png"
            seen_env = {}
            seen_command = []

            def fake_run(command, env):
                seen_command.extend(command)
                seen_env.update(env)
                expected_frame.parent.mkdir(parents=True, exist_ok=True)
                expected_frame.touch()

            with patch.object(capture_tool, "_run_capture_process", side_effect=fake_run):
                frame, receipt = capture_tool._direct_scene_capture(
                    output_root,
                    {
                        "id": "route",
                        "scene_path": "res://scenes/levels/episode_1_vancouver_waterfront.tscn",
                        "staging_id": "rain_city_downtown",
                        "seed": 7,
                        "frame": 1,
                        "capture": {"quit_after": 2},
                    },
                    {"id": "1680x1050", "width": 1680, "height": 1050},
                    30,
                    60,
                )

            self.assertEqual(frame, expected_frame)
            self.assertIsNone(receipt)
            isolated_home = output_root / "route-1680x1050/user-data/home"
            self.assertEqual(seen_env.get("HOME"), str(isolated_home))
            self.assertEqual(seen_env.get("CFFIXED_USER_HOME"), str(isolated_home))
            resolution_index = seen_command.index("--resolution")
            self.assertEqual(
                seen_command[resolution_index + 1],
                capture_tool._DIRECT_CAPTURE_BOOTSTRAP_RESOLUTION,
            )
            self.assertIn("--capture-size=1680x1050", seen_command)

    def test_camera_pose_receipt_is_required_and_validated(self) -> None:
        import hashlib
        import json
        from PIL import Image

        with tempfile.TemporaryDirectory(prefix="capture-pose-receipt-test-") as temp:
            receipt_image = Path(temp) / "receipt.png"
            Image.new("RGB", (1680, 1050), "#203040").save(receipt_image)
            receipt_sha256 = hashlib.sha256(receipt_image.read_bytes()).hexdigest()
            view = {
                "id": "rain_city_slice",
                "staging_id": "rain_city_slice",
                "require_camera_pose_receipt": True,
                "frame": 80,
                "seed": 2026072211,
                "expected_camera_pose": {
                    "player_origin": [2.5, 1.1, -37.0],
                    "camera_origin": [2.5, 2.66, -37.0],
                    "look_target": [-4.3, 3.35, -37.0],
                    "camera_fov": 90.0,
                },
            }
            receipt_data = {
                "staging_id": "rain_city_slice",
                "capture_frame": 80,
                "script_frame": 80,
                "capture_seed": 2026072211,
                "capture_window_size": [1680, 1050],
                "receipt_image_size": [1680, 1050],
                "capture_window_borderless": True,
                "player_origin": [2.5, 1.1, -37.0],
                "camera_origin": [2.5, 2.66, -37.0],
                "camera_forward": [-0.9948912859, 0.1009522080, 0.0],
                "camera_fov": 90.0,
                "position_error": 0.0,
                "camera_position_error": 0.0,
                "direction_dot": 1.0,
                "active_camera_under_player": True,
                "receipt_image_sha256": receipt_sha256,
            }

            def output_for(data):
                return "CAPTURE_CAMERA_POSE " + json.dumps(data, separators=(",", ":")) + "\n"

            valid_output = output_for(receipt_data)
            receipt = capture_tool._camera_pose_receipt(
                valid_output, view, receipt_image, (1680, 1050)
            )
            self.assertIsNotNone(receipt)
            assert receipt is not None
            self.assertEqual(receipt["staging_id"], "rain_city_slice")
            self.assertLessEqual(receipt["validated_position_error"], 0.01)
            self.assertLessEqual(receipt["validated_camera_position_error"], 0.01)
            self.assertGreaterEqual(receipt["validated_direction_dot"], 0.999)

            invalid_outputs = [
                "",
                valid_output + valid_output,
                valid_output.replace('"rain_city_slice"', '"rain_city_terminal"', 1),
                valid_output.replace('"capture_frame":80', '"capture_frame":79'),
                valid_output.replace('"script_frame":80', '"script_frame":79'),
                valid_output.replace('"capture_seed":2026072211', '"capture_seed":1'),
                valid_output.replace('"capture_window_size":[1680,1050]', '"capture_window_size":[1484,928]'),
                valid_output.replace('"receipt_image_size":[1680,1050]', '"receipt_image_size":[1484,928]'),
                valid_output.replace('"capture_window_borderless":true', '"capture_window_borderless":false'),
                valid_output.replace('"player_origin":[2.5', '"player_origin":[3.5'),
                valid_output.replace('"camera_origin":[2.5,2.66', '"camera_origin":[2.5,102.66'),
                valid_output.replace('"camera_forward":[-0.9948912859', '"camera_forward":[0.5'),
                valid_output.replace('"camera_fov":90.0', '"camera_fov":70.0'),
                valid_output.replace('"active_camera_under_player":true', '"active_camera_under_player":false'),
                valid_output.replace('"player_origin":[2.5', '"player_origin":[NaN'),
                valid_output.replace(receipt_sha256, "0" * 64),
                output_for({**receipt_data, "aspect": "forged"}),
            ]
            for output in invalid_outputs:
                with self.subTest(output=output):
                    with self.assertRaises(RuntimeError):
                        capture_tool._camera_pose_receipt(
                            output, view, receipt_image, (1680, 1050)
                        )

            with self.assertRaises(RuntimeError):
                capture_tool._camera_pose_receipt(
                    valid_output, view, Path(temp) / "missing.png", (1680, 1050)
                )
            with self.assertRaises(RuntimeError):
                capture_tool._camera_pose_receipt(valid_output, view, receipt_image, (3440, 1440))
            wrong_size_image = Path(temp) / "wrong-size.png"
            Image.new("RGB", (1484, 928), "#203040").save(wrong_size_image)
            wrong_size_data = {
                **receipt_data,
                "receipt_image_sha256": hashlib.sha256(wrong_size_image.read_bytes()).hexdigest(),
            }
            with self.assertRaises(RuntimeError):
                capture_tool._camera_pose_receipt(
                    output_for(wrong_size_data), view, wrong_size_image, (1680, 1050)
                )

    def test_scene_edge_iou_rejects_duplicate_captures(self) -> None:
        from PIL import Image, ImageDraw

        with tempfile.TemporaryDirectory(prefix="capture-distinctness-test-") as temp:
            root = Path(temp)
            first_path = root / "first.png"
            duplicate_path = root / "duplicate.png"
            shifted_path = root / "shifted.png"
            distinct_path = root / "distinct.png"
            blank_path = root / "blank.png"
            rain_a_path = root / "rain-a.png"
            rain_b_path = root / "rain-b.png"
            first = Image.new("RGB", (320, 180), "#203040")
            ImageDraw.Draw(first).rectangle((20, 30, 120, 120), fill="#f0b040")
            first.save(first_path)
            first.save(duplicate_path)
            shifted = Image.new("RGB", (320, 180), "#203040")
            ImageDraw.Draw(shifted).rectangle((21, 30, 121, 120), fill="#f0b040")
            shifted.save(shifted_path)
            distinct = Image.new("RGB", (320, 180), "#203040")
            ImageDraw.Draw(distinct).ellipse((190, 35, 290, 135), fill="#40b0f0")
            distinct.save(distinct_path)
            Image.new("RGB", (320, 180), "#000000").save(blank_path)
            for path, offset in ((rain_a_path, 0), (rain_b_path, 5)):
                rain = first.copy()
                rain_draw = ImageDraw.Draw(rain)
                for x in range(10 + offset, 320, 18):
                    rain_draw.line((x, 24, x + 3, 125), fill="#9ab0c0", width=1)
                rain.save(path)

            self.assertEqual(capture_tool._scene_edge_iou(first_path, duplicate_path), 1.0)
            self.assertGreaterEqual(capture_tool._scene_edge_iou(first_path, shifted_path), 0.80)
            self.assertLess(capture_tool._scene_edge_iou(first_path, distinct_path), 0.80)
            blank_metrics = capture_tool._scene_edge_metrics(first_path, blank_path)
            self.assertEqual(blank_metrics["second_edge_fraction"], 0.0)
            distinct_metrics = capture_tool._scene_edge_metrics(first_path, distinct_path)
            self.assertGreater(distinct_metrics["low_frequency_mae"], 0.055)
            rain_metrics = capture_tool._scene_edge_metrics(rain_a_path, rain_b_path)
            self.assertLessEqual(rain_metrics["low_frequency_mae"], 0.055)

    def test_run_capture_binds_pose_receipts_to_copied_images(self) -> None:
        import hashlib
        import json
        from PIL import Image

        with tempfile.TemporaryDirectory(prefix="capture-receipt-binding-test-") as temp:
            root = Path(temp)
            view = {
                "id": "route",
                "scene_path": "res://test.tscn",
                "staging_id": "route_stage",
                "capture_support": "supported",
                "adapter": "direct_scene_capture",
                "frame": 80,
                "seed": 7,
                "capture": {"quit_after": 90},
                "filenames": {
                    "320x180": "route_320x180.png",
                    "640x360": "route_640x360.png",
                },
            }
            manifest = {
                "capture_policy": {"overwrite_baseline_without_approve": False},
                "support_states": ["supported", "unsupported"],
                "aspects": [
                    {"id": "320x180", "width": 320, "height": 180},
                    {"id": "640x360", "width": 640, "height": 360},
                ],
                "views": [view],
            }
            manifest_path = root / "manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            def fake_direct_capture(output_root, selected_view, aspect, render_fps, physics_tps):
                del selected_view, render_fps, physics_tps
                source = output_root / f"source-{aspect['id']}.png"
                Image.new("RGB", (aspect["width"], aspect["height"]), "#203040").save(source)
                return source, {
                    "staging_id": "route_stage",
                    "capture_frame": 80,
                    "script_frame": 80,
                    "capture_seed": 7,
                    "player_origin": [1.0, 2.0, 3.0],
                    "camera_origin": [1.0, 3.0, 3.0],
                    "camera_forward": [0.0, 0.0, -1.0],
                    "active_camera_under_player": True,
                    "validated_position_error": 0.0,
                    "validated_direction_dot": 1.0,
                }

            candidate = root / "candidate"
            with patch.object(capture_tool, "_direct_scene_capture", side_effect=fake_direct_capture):
                result = capture_tool.run_capture(
                    manifest_path=manifest_path,
                    baseline_root=root / "baseline",
                    candidate_root=candidate,
                    selected_views=["route"],
                    selected_aspects=["320x180", "640x360"],
                    approve=False,
                    run_id="receipt-binding",
                    render_fps=30,
                    physics_tps=60,
                )
            self.assertEqual(result, 0)
            report = json.loads(
                (candidate / "receipt-binding/capture_report.json").read_text(encoding="utf-8")
            )
            receipts = report["camera_pose_receipts"]["route"]
            self.assertEqual([receipt["aspect"] for receipt in receipts], ["320x180", "640x360"])
            for receipt in receipts:
                image_path = Path(receipt["image_path"])
                self.assertTrue(image_path.is_file())
                self.assertEqual(receipt["image_sha256"], hashlib.sha256(image_path.read_bytes()).hexdigest())
            self.assertFalse(report["approval_requested"])
            self.assertFalse(report["approved"])

    def test_partial_distinctness_aspects_never_overwrite_baseline(self) -> None:
        import json
        from PIL import Image, ImageDraw

        with tempfile.TemporaryDirectory(prefix="capture-partial-aspect-test-") as temp:
            root = Path(temp)
            sources = {}
            for view_id, shape in (("route_a", "rectangle"), ("route_b", "ellipse")):
                source = root / f"{view_id}.png"
                image = Image.new("RGB", (320, 180), "#203040")
                draw = ImageDraw.Draw(image)
                if shape == "rectangle":
                    draw.rectangle((20, 30, 120, 120), fill="#f0b040")
                else:
                    draw.ellipse((190, 35, 290, 135), fill="#40b0f0")
                image.save(source)
                sources[view_id] = source
            views = [
                {
                    "id": view_id,
                    "scene_path": "res://test.tscn",
                    "staging_id": view_id,
                    "capture_support": "supported",
                    "adapter": "direct_scene_capture",
                    "distinctness_group": "approval_guard",
                    "distinctness_edge_iou_max": 0.80,
                    "distinctness_min_edge_fraction": 0.002,
                    "frame": 1,
                    "seed": 1,
                    "capture": {"quit_after": 2},
                    "filenames": {
                        "320x180": f"{view_id}_320x180.png",
                        "640x360": f"{view_id}_640x360.png",
                    },
                }
                for view_id in ("route_a", "route_b")
            ]
            manifest = {
                "capture_policy": {"overwrite_baseline_without_approve": False},
                "support_states": ["supported", "unsupported"],
                "aspects": [
                    {"id": "320x180", "width": 320, "height": 180},
                    {"id": "640x360", "width": 640, "height": 360},
                ],
                "views": views,
            }
            manifest_path = root / "manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            baseline = root / "baseline"
            candidate = root / "candidate"

            def fake_direct_capture(output_root, view, aspect, render_fps, physics_tps):
                del output_root, aspect, render_fps, physics_tps
                return sources[view["id"]], None

            with patch.object(capture_tool, "_direct_scene_capture", side_effect=fake_direct_capture):
                result = capture_tool.run_capture(
                    manifest_path=manifest_path,
                    baseline_root=baseline,
                    candidate_root=candidate,
                    selected_views=["route_a", "route_b"],
                    selected_aspects=["320x180"],
                    approve=True,
                    run_id="partial-aspect",
                    render_fps=30,
                    physics_tps=60,
                )
            self.assertEqual(result, 1)
            self.assertEqual(list(baseline.iterdir()), [])
            report = json.loads((candidate / "partial-aspect/capture_report.json").read_text(encoding="utf-8"))
            completeness = report["distinctness_group_completeness"][0]
            self.assertFalse(completeness["complete"])
            self.assertEqual(completeness["selected_aspects"], ["320x180"])
            self.assertEqual(completeness["required_aspects"], ["320x180", "640x360"])
            self.assertTrue(any("complete distinctness group" in failure for failure in report["failures"]))

    def test_baseline_promotion_rolls_back_on_swap_failure(self) -> None:
        with tempfile.TemporaryDirectory(prefix="capture-baseline-rollback-test-") as temp:
            root = Path(temp)
            baseline = root / "baseline"
            baseline.mkdir()
            (baseline / "existing.png").write_bytes(b"existing-baseline")
            candidate = root / "candidate.png"
            candidate.write_bytes(b"candidate-image")
            real_replace = capture_tool.os.replace
            replace_calls = 0

            def fail_second_replace(source, target):
                nonlocal replace_calls
                replace_calls += 1
                if replace_calls == 2:
                    raise OSError("injected promotion failure")
                return real_replace(source, target)

            with patch.object(capture_tool.os, "replace", side_effect=fail_second_replace):
                with self.assertRaises(OSError):
                    capture_tool._promote_baseline_transactionally(
                        {"route": [str(candidate)]},
                        baseline,
                    )
            self.assertEqual((baseline / "existing.png").read_bytes(), b"existing-baseline")
            self.assertFalse((baseline / "candidate.png").exists())
            self.assertEqual(replace_calls, 3)

    def test_baseline_backup_survives_failed_rollback(self) -> None:
        with tempfile.TemporaryDirectory(prefix="capture-baseline-retention-test-") as temp:
            root = Path(temp)
            baseline = root / "baseline"
            baseline.mkdir()
            (baseline / "existing.png").write_bytes(b"existing-baseline")
            candidate = root / "candidate.png"
            candidate.write_bytes(b"candidate-image")
            real_replace = capture_tool.os.replace
            replace_calls = 0

            def fail_promotion_and_restore(source, target):
                nonlocal replace_calls
                replace_calls += 1
                if replace_calls in (2, 3):
                    raise OSError("injected swap failure")
                return real_replace(source, target)

            with patch.object(capture_tool.os, "replace", side_effect=fail_promotion_and_restore):
                with self.assertRaisesRegex(RuntimeError, "backup retained"):
                    capture_tool._promote_baseline_transactionally(
                        {"route": [str(candidate)]},
                        baseline,
                    )
            retained_backups = list(root.glob(".baseline-backup-*"))
            self.assertEqual(len(retained_backups), 1)
            self.assertEqual(
                (retained_backups[0] / "existing.png").read_bytes(),
                b"existing-baseline",
            )
            self.assertFalse((retained_backups[0] / "candidate.png").exists())
            self.assertEqual(replace_calls, 3)

    def test_failed_distinctness_never_overwrites_baseline(self) -> None:
        import json
        from PIL import Image, ImageDraw

        with tempfile.TemporaryDirectory(prefix="capture-approval-test-") as temp:
            root = Path(temp)
            source = root / "source.png"
            image = Image.new("RGB", (320, 180), "#203040")
            ImageDraw.Draw(image).rectangle((20, 30, 120, 120), fill="#f0b040")
            image.save(source)
            views = []
            for view_id in ("route_a", "route_b"):
                views.append(
                    {
                        "id": view_id,
                        "scene_path": "res://test.tscn",
                        "staging_id": view_id,
                        "capture_support": "supported",
                        "adapter": "direct_scene_capture",
                        "distinctness_group": "approval_guard",
                        "distinctness_edge_iou_max": 0.80,
                        "distinctness_min_edge_fraction": 0.002,
                        "frame": 1,
                        "seed": 1,
                        "capture": {"quit_after": 2},
                        "filenames": {"320x180": f"{view_id}_320x180.png"},
                    }
                )
            manifest = {
                "capture_policy": {"overwrite_baseline_without_approve": False},
                "support_states": ["supported", "unsupported"],
                "aspects": [{"id": "320x180", "width": 320, "height": 180}],
                "views": views,
            }
            manifest_path = root / "manifest.json"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            baseline = root / "baseline"
            candidate = root / "candidate"
            with patch.object(capture_tool, "_direct_scene_capture", return_value=(source, None)):
                result = capture_tool.run_capture(
                    manifest_path=manifest_path,
                    baseline_root=baseline,
                    candidate_root=candidate,
                    selected_views=["route_a", "route_b"],
                    selected_aspects=["320x180"],
                    approve=True,
                    run_id="failed-approval",
                    render_fps=30,
                    physics_tps=60,
                )
            self.assertEqual(result, 1)
            self.assertEqual(list(baseline.iterdir()), [])
            report = json.loads((candidate / "failed-approval/capture_report.json").read_text(encoding="utf-8"))
            self.assertTrue(report["approval_requested"])
            self.assertFalse(report["approved"])
            self.assertTrue(report["failures"])

    def test_native_capture_launch_receives_isolated_env(self) -> None:
        with tempfile.TemporaryDirectory(prefix="native-capture-env-test-") as temp:
            seen_env = {}

            def fake_run(command, env):
                seen_env.update(env)

            with patch.object(capture_tool, "_run_capture_process", side_effect=fake_run):
                output = capture_tool._native_capture_output(Path(temp), "run", 1280, 720, 30, 60)

            isolated_home = output / "user-data/home"
            self.assertEqual(seen_env.get("HOME"), str(isolated_home))
            self.assertEqual(seen_env.get("CFFIXED_USER_HOME"), str(isolated_home))

    def test_capture_process_rejects_unexpected_engine_errors(self) -> None:
        allowed = "\n".join(capture_tool._ALLOWED_CAPTURE_DIAGNOSTICS) + "\n"
        allowed_result = subprocess.CompletedProcess(["godot"], 0, stdout=allowed)
        with redirect_stdout(io.StringIO()):
            with patch.object(capture_tool.subprocess, "run", return_value=allowed_result):
                capture_tool._run_capture_process(["godot"], {})

        fatal_outputs = (
            "ERROR: Function blocked during in/out signal.\n",
            "SCRIPT ERROR: Invalid access to property or key.\n",
            "WARNING: ObjectDB instances leaked at exit.\n",
            "WARNING: ObjectDB instances were leaked at exit.\n",
            "WARNING: 2 resources still in use at exit.\n",
            "WARNING: 1 orphan node detected.\n",
            "WARNING: 1 orphan StringName detected.\n",
            allowed.splitlines()[0] + "\n" + allowed.splitlines()[0] + "\n",
            "ERROR: 2 shaders of type ParticlesShaderGLES3 were never freed\n",
        )
        for output in fatal_outputs:
            with self.subTest(output=output):
                result = subprocess.CompletedProcess(["godot"], 0, stdout=output)
                with redirect_stdout(io.StringIO()):
                    with patch.object(capture_tool.subprocess, "run", return_value=result):
                        with self.assertRaises(RuntimeError):
                            capture_tool._run_capture_process(["godot"], {})


if __name__ == "__main__":
    unittest.main()
