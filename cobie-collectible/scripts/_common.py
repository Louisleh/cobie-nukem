#!/usr/bin/env python3
"""Shared constants and helpers for the Cobie Nukem collectible pipeline.

House conventions mirrored from tools/blender/*.py: no argparse, paths derived
from this file's own location, determinism by construction (no RNG), and a
machine-greppable PASS sentinel printed by every entry point.
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COLLECTIBLE = ROOT / "cobie-collectible"

REFERENCES = COLLECTIBLE / "references"
CONCEPTS = COLLECTIBLE / "concepts"
GENERATED_MESHES = COLLECTIBLE / "generated-meshes"
BLEND_DIR = COLLECTIBLE / "blender"
VALIDATION_RENDERS = COLLECTIBLE / "validation-renders"
EXPORTS = COLLECTIBLE / "exports"

# Bakeoff renders are bulky and regenerable, so they stage under the repo's
# already-gitignored builds/ tree. Only hashes and the scorecard are committed.
BUILDS = ROOT / "builds" / "collectible"

PIPELINE_VERSION = 1

# --------------------------------------------------------------------------
# Scale contract
# --------------------------------------------------------------------------
# The game contract is 1 Blender unit = 1 metre (docs/BLENDER_ASSET_PIPELINE.md).
# The figurine deliberately departs from it: STL carries no units, and every
# print service interprets an STL unit as one millimetre. Authoring in
# millimetres makes the exported number literally correct and removes the most
# common way a 140 mm figure arrives as a 140 m or 0.14 mm object.
SCALE_CONTRACT = "1 Blender unit = 1 millimetre (collectible; the game uses 1 unit = 1 metre)"
UNIT_SCALE_LENGTH = 0.001

# --------------------------------------------------------------------------
# Print engineering rules (PRD section 10.9). Asserted, never eyeballed.
# --------------------------------------------------------------------------
FIGURE_HEIGHT_MM = 140.0
FIGURE_HEIGHT_RANGE_MM = (130.0, 150.0)
MIN_FEATURE_MM = 1.2
PREFERRED_FEATURE_MM = 1.5
SUNGLASSES_ARM_MM = 1.5
HOLLOW_WALL_MM = 2.0
DRAIN_HOLE_MM = 3.5
DRAIN_HOLE_RANGE_MM = (3.0, 4.0)
ASSEMBLY_CLEARANCE_MM = 0.25
ASSEMBLY_CLEARANCE_RANGE_MM = (0.20, 0.35)
BASE_THICKNESS_MM = 5.0
BASE_THICKNESS_RANGE_MM = (4.0, 6.0)
BASE_DIAMETER_MM = 70.0
BASE_DIAMETER_RANGE_MM = (60.0, 80.0)

# Balance: the projected centre of mass must sit inside the base footprint with
# this much margin, or the figure topples (FR-4, "stands unaided").
BALANCE_MARGIN_RATIO = 0.35

PART_NAMES = (
    "Cobie_Body",
    "Cobie_Head",
    "Cobie_Sunglasses",
    "Cobie_Prop_FetchLauncher",
    "Base_Keyed",
)

# --------------------------------------------------------------------------
# Canonical turnaround
# --------------------------------------------------------------------------
# Yaw is measured about +Z, 0 = facing the camera. Multi-view image-to-3D
# generators expect exactly 90-degree separation between the four cardinals.
TURNAROUND_VIEWS = {
    "front": 0.0,
    "left": 90.0,
    "rear": 180.0,
    "right": 270.0,
    "hero": 35.0,
}
CARDINAL_VIEWS = ("front", "left", "rear", "right")

# Deterministic seed base. Every render seed is a pure function of this and the
# view name, so a run is reproducible from source alone with no CLI seed.
SEED_BASE = 2026072900


def view_seed(view: str) -> int:
    """Stable per-view seed derived from the view name, never from the clock."""
    digest = hashlib.sha256(f"{SEED_BASE}:{view}".encode()).hexdigest()
    return int(digest[:8], 16)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


@dataclass(frozen=True)
class Failure:
    """One machine-readable validation failure."""

    check: str
    subject: str
    detail: str

    def as_dict(self) -> dict:
        return {"check": self.check, "subject": self.subject, "detail": self.detail}


def report(sentinel: str, failures: list[Failure], extra: dict | None = None) -> int:
    """Print the house PASS/FAIL sentinel and return a process exit code."""
    payload = dict(extra or {})
    payload["failures"] = [f.as_dict() for f in failures]
    for failure in failures:
        print(f"  FAIL [{failure.check}] {failure.subject}: {failure.detail}")
    if failures:
        print(f"{sentinel}: FAIL ({len(failures)} issue(s))")
        return 1
    print(f"{sentinel}: PASS")
    return 0
