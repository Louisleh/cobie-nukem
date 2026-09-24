import copy
import importlib.util
import json
from pathlib import Path
import signal
import struct
import tempfile
import time
import unittest
from unittest.mock import Mock, patch

SPEC = importlib.util.spec_from_file_location("probe", Path(__file__).parents[1] / "evidence/salmon_opening_probe.py")
assert SPEC is not None and SPEC.loader is not None
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)


class OpeningProbeTests(unittest.TestCase):
    def test_exact_diagnostics_and_sentinel(self):
        text = "SALMON OPENING PROBE: COMPLETE\n" + "\n".join(probe.ALLOWED)
        probe.check_log(text)
        for bad in (text + "\nSCRIPT ERROR: bad", text + "\nERROR: near match", text + "\n" + next(iter(probe.ALLOWED)), "PASS", text + "\nWARNING: ObjectDB instances leaked at exit"):
            with self.assertRaises(ValueError):
                probe.check_log(bad)

    def test_receipt_rejects_forgery_and_escaped_saves(self):
        # Synthetic headers test receipt validation, not rendered acceptance.
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            frames = []
            samples = []
            for i in range(10):
                path = home / ("frame_%04d.png" % (i * 3))
                path.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\0" * 8 + struct.pack(">II", 1280, 720))
                frames.append(path)
                samples.append({"frame": i * 3, "process_frame": i * 3 + 11,
                                "simulation_seconds": (i * 3 + 1) / 30, "physics_ticks": i * 6 + 2,
                                "elapsed_usec": i * 100000 + 1, "png_sha256": probe.digest(path)})
            data = {"frames": 30, "viewport": [1280, 720], "movie_maker": False,
                    "teleports": False, "direct_encounter_activation": False,
                    "user_data_dir": temp, "save_directory": str(home / "saves"),
                    "render_fps": 30, "sample_fps": 10, "physics_tps": 60,
                    "start_process_frame": 10, "end_process_frame": 40,
                    "start_physics_frame": 20, "end_physics_frame": 80, "samples": samples,
                    "fire_input": {"action": "fire_primary", "method": "Input.parse_input_event",
                                   "events": [{"frame": 12, "pressed": True, "button_index": 1},
                                              {"frame": 15, "pressed": False, "button_index": 1}]},
                    "primary_fire": {"weapon_id": "pawstol", "initial_ammo": 12,
                                     "final_ammo": 11, "ammo_cost": 1,
                                     "fired_events": [{"process_frame": 22, "weapon_id": "pawstol",
                                                       "ammo_after": 11}]}}
            probe.validate_receipt(data, frames, 1, (1280, 720), home)
            for key, value in (("save_directory", "/tmp/escaped"), ("end_process_frame", 39), ("physics_tps", 30), ("teleports", True), ("viewport", [640, 360])):
                bad = copy.deepcopy(data)
                bad[key] = value
                with self.assertRaises(ValueError):
                    probe.validate_receipt(bad, frames, 1, (1280, 720), home)
            for key, value in (("simulation_seconds", 0), ("png_sha256", "fake"), ("elapsed_usec", 0), ("physics_ticks", 0)):
                bad = copy.deepcopy(data)
                bad["samples"][1][key] = value
                with self.assertRaises(ValueError):
                    probe.validate_receipt(bad, frames, 1, (1280, 720), home)
            # A changed ammo count alone is not a fired-event proof.
            for mutation in (
                lambda bad: bad.pop("primary_fire"),
                lambda bad: bad["primary_fire"].update(final_ammo=11, fired_events=[]),
                lambda bad: bad["primary_fire"].update(final_ammo=12),
                lambda bad: bad["primary_fire"].update(final_ammo=10),
                lambda bad: bad["primary_fire"]["fired_events"][0].update(ammo_after=12),
                lambda bad: bad["primary_fire"]["fired_events"][0].update(process_frame=40),
                lambda bad: bad["fire_input"].update(method="Input.action_press"),
                lambda bad: bad["fire_input"]["events"][0].update(frame=120),
                lambda bad: bad["fire_input"]["events"].pop(),
            ):
                bad = copy.deepcopy(data)
                mutation(bad)
                with self.assertRaises(ValueError):
                    probe.validate_receipt(bad, frames, 1, (1280, 720), home)

    def test_budget_checks_final_bytes_time_frames_and_both_volumes(self):
        with tempfile.TemporaryDirectory() as temp:
            scratch = Path(temp)
            (scratch / "frames").mkdir()
            destination = scratch / "out"
            now = time.monotonic()
            with patch.object(probe.shutil, "disk_usage", return_value=Mock(free=10 * 1024**3)) as disk:
                probe.check_budget(scratch, destination, now, 10)
                self.assertEqual(disk.call_count, 2)
                with self.assertRaises(ValueError):
                    probe.check_budget(scratch, destination, now - 121, 10)
                for i in range(11):
                    (scratch / "frames" / ("frame_%d.png" % i)).touch()
                with self.assertRaises(ValueError):
                    probe.check_budget(scratch, destination, now, 10)
                with (scratch / "large").open("wb") as stream:
                    stream.truncate(65 * 1024**2)
                with self.assertRaises(ValueError):
                    probe.check_budget(scratch, destination, now, 20)

    def test_exited_leader_still_escalates_group(self):
        process = Mock(pid=12345, returncode=0)
        with patch.object(probe.os, "killpg") as kill, patch.object(probe.time, "sleep"):
            probe.stop_group(process)
        self.assertEqual(kill.call_args_list[0].args, (12345, signal.SIGTERM))
        self.assertEqual(kill.call_args_list[1].args, (12345, signal.SIGKILL))
        process.wait.assert_called_once_with(timeout=5)

    def test_signal_exits_through_exception_cleanup(self):
        with self.assertRaises(RuntimeError):
            probe.interrupted(signal.SIGTERM, None)


if __name__ == "__main__":
    unittest.main()
