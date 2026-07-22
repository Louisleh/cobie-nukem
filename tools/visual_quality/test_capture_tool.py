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
            capture_project = output_root / "project-1280x720"
            capture_project.mkdir(parents=True)
            (capture_project / "project.godot").write_text("[application]\n", encoding="utf-8")
            expected_frame = output_root / "route-1280x720/capture00000001.png"
            seen_env = {}

            def fake_run(command, env):
                seen_env.update(env)
                expected_frame.parent.mkdir(parents=True, exist_ok=True)
                expected_frame.touch()

            with patch.object(capture_tool, "_run_capture_process", side_effect=fake_run):
                frame = capture_tool._direct_scene_capture(
                    output_root,
                    {
                        "id": "route",
                        "scene_path": "res://scenes/levels/episode_1_vancouver_waterfront.tscn",
                        "staging_id": "rain_city_downtown",
                        "seed": 7,
                        "frame": 1,
                        "capture": {"quit_after": 2},
                    },
                    {"id": "1280x720", "width": 1280, "height": 720},
                    30,
                    60,
                )

            self.assertEqual(frame, expected_frame)
            isolated_home = output_root / "route-1280x720/user-data/home"
            self.assertEqual(seen_env.get("HOME"), str(isolated_home))
            self.assertEqual(seen_env.get("CFFIXED_USER_HOME"), str(isolated_home))

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
