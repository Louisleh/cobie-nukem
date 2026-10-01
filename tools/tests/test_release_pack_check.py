"""Run the production pack gate with real extraction and isolated tool failures."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


CHECK = Path(__file__).parents[1] / "check_release_pack.sh"
BASH = shutil.which("bash")
MARKERS = (
    "godot_ai_bridge", "GodotAIBridgeRuntime", "production_asset_gallery",
    "vertical_slice_capture", "assets/models/pilot", "assets/sprites/experiments",
    "docs/evidence", "cobie_production_pilot.blend", "/Users/louislehmann",
)
LARGE_CLEAN = b"ordinary clean production line\n" * 300000  # >8 MiB, many lines.


class ReleasePackCheckTests(unittest.TestCase):
    def run_gate(self, data=b"ordinary production fixture\n", replacements=None,
                 missing=None, arguments=None, filename="fixture pack.pck"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            scan_dir = root / "scan"
            bin_dir.mkdir()
            scan_dir.mkdir()
            pack = root / filename
            if data is not None:
                pack.write_bytes(data)
            for tool in ("strings", "grep", "mktemp", "rm"):
                executable = shutil.which(tool)
                self.assertIsNotNone(executable, tool)
                if tool != missing:
                    (bin_dir / tool).symlink_to(executable)
            for tool, script in (replacements or {}).items():
                path = bin_dir / tool
                if path.exists():
                    path.unlink()
                path.write_text("#!/bin/sh\n" + script)
                path.chmod(0o755)
            result = subprocess.run(
                [BASH, str(CHECK), *(arguments if arguments is not None else [filename])],
                cwd=root,
                env={**os.environ, "PATH": str(bin_dir), "TMPDIR": str(scan_dir)},
                capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(list(scan_dir.iterdir()), [], result.stdout + result.stderr)
            return result

    def assert_rejected(self, result, diagnostic):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(diagnostic, result.stderr)
        self.assertNotIn("RELEASE PACK CHECK: PASS", result.stdout)

    def test_clean_pack_and_option_like_filename_pass(self):
        for filename in ("fixture pack.pck", "-fixture.pck"):
            with self.subTest(filename=filename):
                result = self.run_gate(filename=filename)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("RELEASE PACK CHECK: PASS", result.stdout)

    def test_every_existing_forbidden_marker_is_rejected(self):
        for marker in MARKERS:
            with self.subTest(marker=marker):
                result = self.run_gate(b"ordinary prefix\n" + marker.encode() + b"\n")
                self.assert_rejected(result, "forbidden development marker")
                self.assertIn(marker, result.stderr)

    def test_early_large_match_rejects_and_large_clean_control_passes(self):
        self.assertGreater(len(LARGE_CLEAN), 8 * 1024 * 1024)
        result = self.run_gate(b"godot_ai_bridge\n" + LARGE_CLEAN)
        self.assert_rejected(result, "godot_ai_bridge")
        clean = self.run_gate(LARGE_CLEAN)
        self.assertEqual(clean.returncode, 0, clean.stdout + clean.stderr)
        self.assertIn("RELEASE PACK CHECK: PASS", clean.stdout)

    def test_late_large_match_is_rejected(self):
        result = self.run_gate(LARGE_CLEAN + b"\ncobie_production_pilot.blend\n")
        self.assert_rejected(result, "cobie_production_pilot.blend")

    def test_partial_extraction_failure_is_not_a_search_result(self):
        for output in ("partial clean output", "godot_ai_bridge"):
            with self.subTest(output=output):
                result = self.run_gate(replacements={
                    "strings": f"printf '%s\\n' '{output}'\nexit 2\n",
                })
                self.assert_rejected(result, "strings extraction failed (exit 2)")

    def test_tool_and_allocation_failures_cannot_pass(self):
        result = self.run_gate(replacements={"grep": "exit 2\n"})
        self.assert_rejected(result, "marker search failed (exit 2)")
        result = self.run_gate(replacements={"mktemp": "exit 2\n"})
        self.assert_rejected(result, "could not allocate")
        for tool in ("strings", "grep", "mktemp", "rm"):
            with self.subTest(missing=tool):
                result = self.run_gate(missing=tool)
                self.assert_rejected(result, "requires " + tool)

    def test_invalid_inputs_are_rejected(self):
        for data in (None, b""):
            with self.subTest(data=data):
                result = self.run_gate(data=data)
                self.assert_rejected(result, "readable nonempty regular file")
        result = self.run_gate(arguments=["."])
        self.assert_rejected(result, "readable nonempty regular file")
        for arguments in ([], ["fixture pack.pck", "extra"]):
            with self.subTest(arguments=arguments):
                result = self.run_gate(arguments=arguments)
                self.assert_rejected(result, "exactly one file path")


if __name__ == "__main__":
    unittest.main()
