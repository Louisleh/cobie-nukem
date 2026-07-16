#!/usr/bin/env python3
"""Verify the local, free Cobie visual-production toolchain without mutating it."""

from __future__ import annotations

import argparse
import json
import plistlib
import shutil
import subprocess
import sys
from pathlib import Path


def run_text(command: list[str]) -> str:
    result = subprocess.run(command, check=False, capture_output=True, text=True)
    if result.returncode != 0:
        return ""
    return (result.stdout or result.stderr).strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", default=".")
    args = parser.parse_args()
    root = Path(args.project_root).resolve()
    failures: list[str] = []

    required_paths = [
        root / "project.godot",
        root / "tools" / "release_validate.sh",
        root / "docs" / "ASSET_MANIFEST.md",
        root / "docs" / "BLENDER_ASSET_PIPELINE.md",
    ]
    for path in required_paths:
        if not path.exists():
            failures.append(f"missing project contract: {path}")

    godot = shutil.which("godot") or shutil.which("/opt/homebrew/bin/godot")
    blender = shutil.which("blender") or shutil.which("/opt/homebrew/bin/blender")
    codex = shutil.which("codex")
    if not godot:
        failures.append("Godot executable not found")
    if not blender and not Path("/Applications/Blender.app").exists():
        failures.append("Blender executable/application not found")
    if not codex:
        failures.append("Codex CLI not found; MCP configuration cannot be verified")

    material_info = Path("/Applications/Material Maker.app/Contents/Info.plist")
    material_version = "missing"
    if material_info.exists():
        with material_info.open("rb") as handle:
            material_version = str(plistlib.load(handle).get("CFBundleShortVersionString", "unknown"))
    else:
        failures.append("Material Maker application not found")

    mcp_status: dict[str, str] = {}
    if codex:
        for server in ("chrome-devtools", "context7", "godot-cobie", "blender"):
            output = run_text([codex, "mcp", "get", server])
            mcp_status[server] = "configured" if output else "missing"
            if not output:
                failures.append(f"Codex MCP not configured: {server}")

    result = {
        "project_root": str(root),
        "godot": run_text([godot, "--version"]) if godot else "missing",
        "blender": run_text([blender, "--version"]).splitlines()[0] if blender else ("app-present" if Path("/Applications/Blender.app").exists() else "missing"),
        "material_maker": material_version,
        "mcp": mcp_status,
        "status": "PASS" if not failures else "FAIL",
        "failures": failures,
        "note": "Newly configured MCP servers require a fresh Codex task before their tools are callable.",
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
