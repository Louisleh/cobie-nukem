#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import tomllib


EXPECTED = {
    "spark-gameplay-worker": "workspace-write",
    "spark-test-engineer": "workspace-write",
    "spark-content-author": "workspace-write",
    "spark-performance-auditor": "read-only",
    "spark-ui-accessibility-worker": "workspace-write",
    "spark-code-reviewer": "read-only",
}
MODEL = "gpt-5.3-codex-spark"
REQUIRED_GUARDRAILS = (
    "do not spawn",
    "merge",
    "deploy",
    "buildinfo",
    "physical-device",
)


def validate(root: Path) -> list[str]:
    failures: list[str] = []
    agents_dir = root / ".codex" / "agents"
    for name, sandbox in EXPECTED.items():
        path = agents_dir / f"{name}.toml"
        if not path.is_file():
            failures.append(f"missing agent profile: {path.relative_to(root)}")
            continue
        try:
            data = tomllib.loads(path.read_text(encoding="utf-8"))
        except (OSError, tomllib.TOMLDecodeError) as exc:
            failures.append(f"invalid TOML {path.relative_to(root)}: {exc}")
            continue
        if data.get("name") != name:
            failures.append(f"{path.name}: name must be {name!r}")
        if data.get("model") != MODEL:
            failures.append(f"{path.name}: model must be {MODEL!r}")
        if data.get("sandbox_mode") != sandbox:
            failures.append(f"{path.name}: sandbox_mode must be {sandbox!r}")
        instructions = str(data.get("developer_instructions", "")).lower()
        for phrase in REQUIRED_GUARDRAILS:
            if phrase not in instructions:
                failures.append(f"{path.name}: missing guardrail phrase {phrase!r}")
    skill = root / ".agents" / "skills" / "cobie-spark-orchestration" / "SKILL.md"
    if not skill.is_file():
        failures.append("missing cobie-spark-orchestration skill")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Cobie Spark agent configuration.")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    failures = validate(root)
    payload = {"model": MODEL, "profiles": len(EXPECTED), "failures": failures}
    if args.json:
        print(json.dumps(payload, indent=2))
    elif failures:
        print("SPARK SETUP: FAIL")
        for failure in failures:
            print(f"- {failure}")
    else:
        print(f"SPARK SETUP: PASS ({len(EXPECTED)} profiles pinned to {MODEL})")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
