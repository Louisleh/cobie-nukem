#!/usr/bin/env python3
"""Create an isolated Godot project view with a truthful capture aspect ratio."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil


def rewrite_project_settings(source: str, width: int, height: int) -> str:
    replacements = {
        # Movie Maker records the project viewport rather than the requested OS
        # window. The debug host applies the game's logical 360-pixel scale at
        # runtime, while these values preserve the real evidence dimensions.
        "window/size/viewport_width": width,
        "window/size/viewport_height": height,
    }
    lines: list[str] = []
    for line in source.splitlines():
        key = line.split("=", 1)[0]
        if key in {
            "window/size/window_width_override",
            "window/size/window_height_override",
        }:
            continue
        if key in replacements:
            line = f"{key}={replacements[key]}"
        lines.append(line)
    return "\n".join(lines) + "\n"


def prepare(source_root: Path, target_root: Path, width: int, height: int) -> None:
    target_root.mkdir(parents=True, exist_ok=True)
    for entry in source_root.iterdir():
        if entry.name in {".git", "builds", "project.godot"}:
            continue
        destination = target_root / entry.name
        if destination.exists() or destination.is_symlink():
            continue
        if entry.name == ".godot":
            # Capture imports may update cache metadata. Snapshot the cache so a
            # run cannot mutate or inherit live editor state through a symlink.
            shutil.copytree(entry, destination, symlinks=False)
            continue
        os.symlink(entry, destination, target_is_directory=entry.is_dir())
    project_text = (source_root / "project.godot").read_text(encoding="utf-8")
    (target_root / "project.godot").write_text(
        rewrite_project_settings(project_text, width, height),
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_root", type=Path)
    parser.add_argument("target_root", type=Path)
    parser.add_argument("width", type=int)
    parser.add_argument("height", type=int)
    args = parser.parse_args()
    if args.width < 320 or args.height < 240:
        parser.error("capture dimensions must be at least 320x240")
    if args.target_root.exists():
        shutil.rmtree(args.target_root)
    prepare(args.source_root.resolve(), args.target_root.resolve(), args.width, args.height)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
