"""Execute the architecture gate with a controlled tool PATH and real searches."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


CHECK = Path(__file__).parents[1] / "architecture_check.sh"
BASH = shutil.which("bash")


class ArchitectureCheckTests(unittest.TestCase):
    def run_gate(self, timer=False, broken_tool=None, with_rg=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for folder in ("tools", "docs", "scripts/core", "bin"):
                (root / folder).mkdir(parents=True)
            shutil.copyfile(CHECK, root / "tools/architecture_check.sh")
            (root / "docs/ASSET_MANIFEST.md").write_text("")
            (root / "scripts/core/build_info.gd").write_text("# fixture\n")
            if timer:
                (root / "scripts/actor.gd").write_text(
                    "func unsafe():\n    await get_tree().create_timer(1).timeout\n"
                )
            # Git inventory is empty; exercise the real gate's script search.
            git = root / "bin/git"
            git.write_text("#!/bin/sh\nexit 0\n")
            git.chmod(0o755)
            for tool in ("dirname", "grep", "sed", "find", "sort", "wc", "tr", "mktemp", "cat", "rm"):
                executable = shutil.which(tool)
                self.assertIsNotNone(executable, tool)
                (root / "bin" / tool).symlink_to(executable)
            if with_rg:
                (root / "bin/rg").symlink_to(shutil.which("rg"))
            if broken_tool:
                tool = root / "bin" / broken_tool
                if tool.exists():
                    tool.unlink()
                tool.write_text("#!/bin/sh\nexit 2\n")
                tool.chmod(0o755)
            return subprocess.run(
                [BASH, str(root / "tools/architecture_check.sh")],
                env={**os.environ, "PATH": str(root / "bin")},
                capture_output=True, text=True, timeout=15,
            )

    def test_no_ripgrep_clean_search_passes(self):
        result = self.run_gate()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("ARCHITECTURE CHECK: PASS", result.stdout)

    def test_no_ripgrep_prohibited_callback_is_rejected(self):
        result = self.run_gate(timer=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("actor.gd", result.stdout)
        self.assertIn("unowned SceneTreeTimer", result.stdout)
        self.assertNotIn("ARCHITECTURE CHECK: PASS", result.stdout)

    @unittest.skipUnless(shutil.which("rg"), "ripgrep unavailable; fallback is tested")
    def test_ripgrep_prohibited_callback_is_rejected(self):
        result = self.run_gate(timer=True, with_rg=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("actor.gd", result.stdout)
        self.assertIn("unowned SceneTreeTimer", result.stdout)
        self.assertNotIn("ARCHITECTURE CHECK: PASS", result.stdout)

    def test_ripgrep_execution_failure_cannot_pass(self):
        result = self.run_gate(broken_tool="rg")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("search failed (exit 2)", result.stdout)
        self.assertNotIn("ARCHITECTURE CHECK: PASS", result.stdout)

    def test_fallback_execution_failure_cannot_pass(self):
        result = self.run_gate(broken_tool="grep")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("search failed (exit 2)", result.stdout)
        self.assertNotIn("ARCHITECTURE CHECK: PASS", result.stdout)


if __name__ == "__main__":
    unittest.main()
