import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import capture_tool


class CaptureToolFailureReportingTest(unittest.TestCase):
    def test_direct_adapter_failure_still_writes_structured_report(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            manifest = root / "manifest.json"
            manifest.write_text(
                json.dumps(
                    {
                        "support_states": ["supported", "unsupported"],
                        "capture_policy": {},
                        "aspects": [{"id": "320x240", "width": 320, "height": 240}],
                        "views": [
                            {
                                "id": "title",
                                "capture_support": "supported",
                                "adapter": "direct_scene_capture",
                                "scene_path": "res://missing.tscn",
                                "staging_id": "title",
                                "seed": 1,
                                "frame": 1,
                                "capture": {"quit_after": 2},
                                "filenames": {"320x240": "title_320x240.png"},
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            candidate = root / "candidates"
            with patch.object(
                capture_tool,
                "_direct_scene_capture",
                side_effect=RuntimeError("intentional adapter failure"),
            ):
                result = capture_tool.run_capture(
                    manifest,
                    root / "baselines",
                    candidate,
                    [],
                    [],
                    False,
                    "failure-case",
                    30,
                    60,
                )
            report_path = candidate / "failure-case" / "capture_report.json"
            report = json.loads(report_path.read_text(encoding="utf-8"))
            self.assertEqual(1, result)
            self.assertEqual([], report["captured"].get("title", []))
            self.assertTrue(any("RuntimeError" in item for item in report["failures"]))

    def test_native_adapter_failure_is_reused_and_reported_per_view(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            filenames = {
                "field": "field_320x240.png",
                "arena": "arena_320x240.png",
            }
            views = []
            for view_id in ["field", "arena"]:
                views.append(
                    {
                        "id": view_id,
                        "capture_support": "supported",
                        "adapter": "native_vertical_slice_capture",
                        "scene_path": "res://mission.tscn",
                        "staging_id": view_id,
                        "seed": 1,
                        "frame": 1,
                        "capture": {"source_file": f"{view_id}.png"},
                        "filenames": {"320x240": filenames[view_id]},
                    }
                )
            manifest = root / "manifest.json"
            manifest.write_text(
                json.dumps(
                    {
                        "support_states": ["supported", "unsupported"],
                        "capture_policy": {},
                        "aspects": [{"id": "320x240", "width": 320, "height": 240}],
                        "views": views,
                    }
                ),
                encoding="utf-8",
            )
            candidate = root / "candidates"
            with patch.object(
                capture_tool,
                "_native_capture_output",
                side_effect=RuntimeError("intentional native failure"),
            ) as native_capture:
                result = capture_tool.run_capture(
                    manifest,
                    root / "baselines",
                    candidate,
                    [],
                    [],
                    False,
                    "native-failure-case",
                    30,
                    60,
                )
            report = json.loads(
                (candidate / "native-failure-case" / "capture_report.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(1, result)
            self.assertEqual(1, native_capture.call_count)
            self.assertEqual(2, len(report["failures"]))
            self.assertTrue(any("native adapter unavailable" in item for item in report["failures"]))


if __name__ == "__main__":
    unittest.main()
