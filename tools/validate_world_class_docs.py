#!/usr/bin/env python3
"""Validate the active World-Class Buildout documentation contract."""

from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = (
    "AGENTS.md",
    "docs/PRD.md",
    "docs/IMPLEMENTATION_PLAN.md",
    "docs/WORLD_CLASS_BUILDOUT_LOG.md",
    "docs/PHASE_ROADMAP_PRD.md",
    "docs/DECISIONS.md",
    "docs/design/README.md",
    ".agents/skills/cobie-godot-production/SKILL.md",
)
AUTHORITY_MARKERS = {
    "AGENTS.md": (
        "`docs/PRD.md` owns requirements",
        "`docs/IMPLEMENTATION_PLAN.md` owns dependency order",
        "`docs/WORLD_CLASS_BUILDOUT_LOG.md` owns current packet state",
        "`docs/PHASE_ROADMAP_PRD.md` owns release history",
    ),
    "docs/PRD.md": (
        "`docs/PRD.md` owns requirements",
        "`docs/IMPLEMENTATION_PLAN.md` owns dependency order",
        "`docs/WORLD_CLASS_BUILDOUT_LOG.md` owns current state",
        "`docs/PHASE_ROADMAP_PRD.md` owns release history",
    ),
    "docs/DECISIONS.md": ("## D-017 — One active world-class buildout document stack",),
}


def main() -> int:
    failures: list[str] = []
    texts: dict[str, str] = {}

    for relative in REQUIRED_FILES:
        path = ROOT / relative
        if not path.is_file():
            failures.append(f"missing required file: {relative}")
            continue
        text = path.read_text(encoding="utf-8")
        if not text.strip():
            failures.append(f"empty required file: {relative}")
        texts[relative] = text

    for relative, markers in AUTHORITY_MARKERS.items():
        text = texts.get(relative, "")
        for marker in markers:
            if marker not in text:
                failures.append(f"{relative}: missing authority marker {marker!r}")

    roadmap = texts.get("docs/PHASE_ROADMAP_PRD.md", "")
    if "**Status:** Active production source of truth" in roadmap:
        failures.append("docs/PHASE_ROADMAP_PRD.md still claims active source-of-truth status")
    if "### Immediate next gate" in roadmap:
        failures.append("docs/PHASE_ROADMAP_PRD.md exposes a historical gate as current")

    plan = texts.get("docs/IMPLEMENTATION_PLAN.md", "")
    for packet in range(12):
        marker = f"WCB-{packet:03d}"
        if marker not in plan:
            failures.append(f"docs/IMPLEMENTATION_PLAN.md: missing {marker}")
    if "Second-mission pipeline replication" not in plan:
        failures.append("docs/IMPLEMENTATION_PLAN.md: replication implementation packet missing")

    log = texts.get("docs/WORLD_CLASS_BUILDOUT_LOG.md", "")
    if "Chat history is not a source of truth" not in log:
        failures.append("docs/WORLD_CLASS_BUILDOUT_LOG.md: resume authority guard missing")
    if "- Integrated commit:" not in log or "- Next dependency-safe packet:" not in log:
        failures.append("docs/WORLD_CLASS_BUILDOUT_LOG.md: packet handoff fields missing")

    backtick_path = re.compile(r"`((?:docs|\.agents|tools)/[^`]+)`")
    for relative, text in texts.items():
        for raw in backtick_path.findall(text):
            target = raw.split()[0].rstrip(".,;:").split("#", 1)[0]
            if any(token in target for token in ("*", "<", ">")) or target.endswith("/"):
                continue
            if not (ROOT / target).exists():
                failures.append(f"{relative}: unresolved repository path {target}")

    if failures:
        print("WORLD-CLASS DOCS: FAIL", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("WORLD-CLASS DOCS: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
