import json
import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from PIL import Image

import compare_captures


def _write_png(path: Path, color=(0, 0, 0, 255), size=(1280, 720)):
    image = Image.new("RGBA", size, color)
    image.save(path, format="PNG")


def _manifest_for_view(base_path: Path, size: int = 1280) -> Path:
    manifest_path = base_path / "manifest.json"
    manifest_path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "support_states": ["supported", "unsupported"],
                "aspects": [
                    {"id": "1280x720", "width": 1280, "height": 720},
                    {"id": "1680x1050", "width": 1680, "height": 1050},
                    {"id": "1024x768", "width": 1024, "height": 768},
                    {"id": "3440x1440", "width": 3440, "height": 1440},
                ],
                "views": [
                    {
                        "id": "salmon_sports_field",
                        "scene_path": "res://scenes/levels/episode_1_level_1.tscn",
                        "staging_id": "forbidden_field",
                        "capture_support": "supported",
                        "adapter": "native_vertical_slice_capture",
                        "seed": 1,
                        "frame": 25,
                        "capture": {"source_file": "01-forbidden-field.png"},
                        "filenames": {
                            "1280x720": "salmon_sports_field_1280x720.png",
                            "1680x1050": "salmon_sports_field_1680x1050.png",
                            "1024x768": "salmon_sports_field_1024x768.png",
                            "3440x1440": "salmon_sports_field_3440x1440.png",
                        },
                    }
                ],
            }
        ),
        encoding="utf-8",
    )
    return manifest_path


class CompareCapturesTests(unittest.TestCase):
    def _write_baseline_and_candidate(self, root: Path, changed=False):
        baseline = root / "baseline"
        candidate = root / "candidate"
        baseline.mkdir()
        candidate.mkdir()
        filenames = {
            "1280x720": "salmon_sports_field_1280x720.png",
            "1680x1050": "salmon_sports_field_1680x1050.png",
            "1024x768": "salmon_sports_field_1024x768.png",
            "3440x1440": "salmon_sports_field_3440x1440.png",
        }
        image_sizes = {
            "1280x720": (1280, 720),
            "1680x1050": (1680, 1050),
            "1024x768": (1024, 768),
            "3440x1440": (3440, 1440),
        }
        for aspect, filename in filenames.items():
            width, height = image_sizes[aspect]
            # A small two-value split avoids producing an invalid solid-color
            # canonical frame while keeping synthetic metrics deterministic.
            baseline_image = Image.new("RGBA", (width, height), (16, 32, 48, 255))
            baseline_image.paste((32, 48, 64, 255), (width // 2, 0, width, height))
            baseline_image.save(baseline / filename, format="PNG")
            if changed and aspect == "1280x720":
                changed_image = Image.new("RGBA", (width, height), (180, 190, 200, 255))
                changed_image.paste((210, 220, 230, 255), (width // 2, 0, width, height))
                changed_image.save(candidate / filename, format="PNG")
            else:
                candidate_image = baseline_image.copy()
                candidate_image.save(candidate / filename, format="PNG")
        return baseline, candidate

    def test_identical_returns_pass(self):
        with tempfile.TemporaryDirectory() as raw:
            temp_root = Path(raw)
            manifest = _manifest_for_view(temp_root)
            baseline, candidate = self._write_baseline_and_candidate(temp_root, changed=False)
            out = temp_root / "out"
            report = compare_captures.compare_captures(manifest, baseline, candidate, out)
            self.assertEqual(report["exit_code"], 0)
            self.assertEqual(report["hard_failures"], [])

    def test_changed_image_warns_but_passes(self):
        with tempfile.TemporaryDirectory() as raw:
            temp_root = Path(raw)
            manifest = _manifest_for_view(temp_root)
            baseline, candidate = self._write_baseline_and_candidate(temp_root, changed=True)
            out = temp_root / "out"
            report = compare_captures.compare_captures(manifest, baseline, candidate, out)
            self.assertEqual(report["exit_code"], 0)
            self.assertTrue(any("delta_mae" == entry.get("type") for entry in report["warnings"]))

    def test_wrong_dimension_is_hard_failure(self):
        with tempfile.TemporaryDirectory() as raw:
            temp_root = Path(raw)
            manifest = _manifest_for_view(temp_root)
            baseline, candidate = self._write_baseline_and_candidate(temp_root, changed=False)
            _write_png(
                candidate / "salmon_sports_field_1280x720.png",
                color=(16, 32, 48, 255),
                size=(800, 450),
            )
            out = temp_root / "out"
            report = compare_captures.compare_captures(manifest, baseline, candidate, out)
            self.assertEqual(report["exit_code"], 1)
            self.assertTrue(any("wrong candidate dimensions" in failure for failure in report["hard_failures"]))

    def test_blank_image_is_hard_failure(self):
        with tempfile.TemporaryDirectory() as raw:
            temp_root = Path(raw)
            manifest = _manifest_for_view(temp_root)
            baseline, candidate = self._write_baseline_and_candidate(temp_root, changed=False)
            _write_png(
                candidate / "salmon_sports_field_1280x720.png",
                color=(0, 0, 0, 255),
                size=(1280, 720),
            )
            out = temp_root / "out"
            report = compare_captures.compare_captures(manifest, baseline, candidate, out)
            self.assertEqual(report["exit_code"], 1)
            self.assertTrue(any("blank image" in failure for failure in report["hard_failures"]))

    def test_transparent_image_is_hard_failure(self):
        with tempfile.TemporaryDirectory() as raw:
            temp_root = Path(raw)
            manifest = _manifest_for_view(temp_root)
            baseline, candidate = self._write_baseline_and_candidate(temp_root, changed=False)
            _write_png(
                candidate / "salmon_sports_field_1280x720.png",
                color=(0, 0, 0, 0),
                size=(1280, 720),
            )
            out = temp_root / "out"
            report = compare_captures.compare_captures(manifest, baseline, candidate, out)
            self.assertEqual(report["exit_code"], 1)
            self.assertTrue(any("mostly transparent" in failure for failure in report["hard_failures"]))
