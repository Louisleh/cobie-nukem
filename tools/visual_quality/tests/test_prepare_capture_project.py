import unittest

from prepare_capture_project import rewrite_project_settings


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


if __name__ == "__main__":
    unittest.main()
