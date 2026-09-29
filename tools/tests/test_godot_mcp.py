"""Focused regressions for the optional, pinned Godot MCP launcher."""
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("godot_mcp", Path(__file__).parents[1] / "godot_mcp.py")
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GodotMCPTests(unittest.TestCase):
    def test_environment_does_not_forward_credentials(self):
        with patch.dict(os.environ, {"PATH": "/bin", "PRIVATE_TOKEN": "fixture", "PYTHONPATH": "/bad"}, clear=True):
            self.assertEqual(MODULE.safe_env(), {"PATH": "/bin"})

    def test_clean_log(self):
        MODULE.scan_errors("Godot 4.7\nready\n")

    def test_error_and_leak_logs_fail_closed(self):
        for line in ["ERROR: failed", "SCRIPT ERROR: assertion", "Parse Error: type", "ObjectDB instances leaked", "resources still in use", "Orphan StringName"]:
            with self.subTest(line=line), self.assertRaises(RuntimeError):
                MODULE.scan_errors(line)

    def test_wrong_revision_rejected(self):
        with patch.object(MODULE.subprocess, "check_output", return_value="bad"):
            with self.assertRaisesRegex(RuntimeError, "must be clean"):
                MODULE.verified_checkout(Path("/fixture"))

    def test_dirty_checkout_rejected(self):
        with patch.object(MODULE.subprocess, "check_output", side_effect=[MODULE.REVISION, " M src/index.ts"]):
            with self.assertRaisesRegex(RuntimeError, "must be clean"):
                MODULE.verified_checkout(Path("/fixture"))

    def test_missing_build_rejected(self):
        with tempfile.TemporaryDirectory() as root, patch.object(MODULE.subprocess, "check_output", side_effect=[MODULE.REVISION, ""]):
            with self.assertRaisesRegex(RuntimeError, "build missing"):
                MODULE.verified_checkout(Path(root))

    def test_missing_dependencies_rejected(self):
        with tempfile.TemporaryDirectory() as root, patch.object(MODULE.subprocess, "check_output", side_effect=[MODULE.REVISION, ""]):
            path = Path(root)
            (path / "dist").mkdir()
            (path / "dist/index.js").write_text("fixture")
            with self.assertRaisesRegex(RuntimeError, "npm ci"):
                MODULE.verified_checkout(path)

    def test_clean_installed_checkout_passes(self):
        with tempfile.TemporaryDirectory() as root, patch.object(MODULE.subprocess, "check_output", side_effect=[MODULE.REVISION, ""]):
            path = Path(root)
            for name in ["dist/index.js", "node_modules/@modelcontextprotocol/sdk/package.json"]:
                target = path / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("fixture")
            self.assertEqual(MODULE.verified_checkout(path), path.resolve())


if __name__ == "__main__":
    unittest.main()
