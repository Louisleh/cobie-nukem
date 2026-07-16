from pathlib import Path
import tempfile
import unittest

from prepare_capture_project import prepare, rewrite_project_settings


class CaptureProjectSettingsTest(unittest.TestCase):
    def test_rewrites_logical_aspect_and_removes_desktop_override(self) -> None:
        source = """[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\nwindow/size/window_width_override=1280\nwindow/size/window_height_override=720\n"""
        rewritten = rewrite_project_settings(source, 1024, 768)
        self.assertIn("window/size/viewport_width=1024", rewritten)
        self.assertIn("window/size/viewport_height=768", rewritten)
        self.assertNotIn("window_width_override", rewritten)
        self.assertNotIn("window_height_override", rewritten)

    def test_preserves_ultrawide_aspect(self) -> None:
        source = "window/size/viewport_width=640\nwindow/size/viewport_height=360\n"
        rewritten = rewrite_project_settings(source, 3440, 1440)
        self.assertIn("window/size/viewport_width=3440", rewritten)

    def test_snapshots_godot_cache_without_source_state_bleed(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "source"
            target = root / "target"
            (source / ".godot").mkdir(parents=True)
            (source / ".godot" / "cache.txt").write_text("source", encoding="utf-8")
            (source / "project.godot").write_text(
                "window/size/viewport_width=640\nwindow/size/viewport_height=360\n",
                encoding="utf-8",
            )
            prepare(source, target, 1024, 768)
            target_cache = target / ".godot" / "cache.txt"
            self.assertFalse((target / ".godot").is_symlink())
            target_cache.write_text("candidate", encoding="utf-8")
            self.assertEqual("source", (source / ".godot" / "cache.txt").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
