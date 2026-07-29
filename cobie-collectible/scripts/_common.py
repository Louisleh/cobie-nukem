#!/usr/bin/env python3
"""Shared constants and helpers for the Cobie Nukem collectible pipeline.

House conventions mirrored from tools/blender/*.py: no argparse, paths derived
from this file's own location, determinism by construction (no RNG), and a
machine-greppable PASS sentinel printed by every entry point.
"""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
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
SLICER_TESTS = COLLECTIBLE / "slicer-tests"
BUILD_REPORT = EXPORTS / "build_report.json"
FIGURINE_BLEND = BLEND_DIR / "cobie_figurine_v1.blend"

# Bakeoff renders are bulky and regenerable, so they stage under the repo's
# already-gitignored builds/ tree. Only hashes and the scorecard are committed.
BUILDS = ROOT / "builds" / "collectible"

PIPELINE_VERSION = 3

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

# Canonical printable joint geometry. Kept here so the builder and the
# exported-STL validator measure the same interfaces without importing bpy.
# Base/head entries: (x, y, radius, height).
BASE_PEG_SPECS = (
    (-9.5, -6.5, 5.0, 6.0),
    (9.5, -1.0, 3.4, 5.5),
)
HEAD_KEY_SPECS = (
    (0.0, -0.5, 6.2, 11.0),
    (10.0, -0.5, 2.0, 9.0),
)
# Glasses/prop entries: (x, y, z, radius, depth), with depth along Y.
GLASSES_PIN_SPECS = (
    (-12.0, -8.5, 121.5, 1.8, 10.0),
    (12.0, -8.5, 121.5, 1.8, 10.0),
)
PROP_PIN_SPECS = (
    (-4.0, -12.0, 68.0, 2.3, 8.0),
    (5.0, -12.0, 65.0, 2.1, 8.0),
)
NECK_CENTRE = (0.0, -0.5, 98.0)
NECK_RADIUS_MM = 9.5
NECK_DEPTH_MM = 14.0

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


def figurine_render_protocol() -> dict:
    """Return the complete, JSON-safe neutral-resin review contract."""
    return {
        "version": 1,
        "render": {
            "engine": "BLENDER_EEVEE",
            "resolution_px": [640, 640],
            "resolution_percentage": 100,
            "file_format": "PNG",
            "color_mode": "RGB",
            "color_depth_bits": 8,
            "film_transparent": False,
            "view_look": "AgX - Medium High Contrast",
            "use_compositing": False,
            "use_sequencer": False,
        },
        "camera": {
            "projection": "ORTHO",
            "orbit_radius_mm": 360.0,
            "z_mm": 82.0,
            "target_mm": [0.0, 0.0, 70.0],
            "ortho_scale_mm": 166.0,
        },
        "views_yaw_degrees": dict(TURNAROUND_VIEWS),
        "world": {
            "background_rgba": [0.055, 0.065, 0.08, 1.0],
            "strength": 0.32,
        },
        "floor": {
            "size_mm": 260.0,
            "location_mm": [0.0, 0.0, -0.25],
            "material": {
                "rgba": [0.10, 0.12, 0.15, 1.0],
                "roughness": 0.9,
                "metallic": 0.0,
            },
        },
        "materials": {
            "figure": {
                "rgba": [0.48, 0.50, 0.52, 1.0],
                "roughness": 0.78,
                "metallic": 0.0,
            },
            "base": {
                "rgba": [0.26, 0.28, 0.31, 1.0],
                "roughness": 0.82,
                "metallic": 0.0,
            },
            "smooth_shading": {
                "Base_Keyed": False,
                "other_parts": True,
            },
        },
        "lights": [
            {
                "name": "Review_Key",
                "type": "SUN",
                "location_mm": [-105.0, -145.0, 205.0],
                "energy": 3.8,
                "angle_radians": 0.16,
            },
            {
                "name": "Review_Fill",
                "type": "SUN",
                "location_mm": [130.0, -95.0, 120.0],
                "energy": 1.45,
                "angle_radians": 0.32,
            },
            {
                "name": "Review_Rim",
                "type": "SUN",
                "location_mm": [40.0, 130.0, 185.0],
                "energy": 2.35,
                "angle_radians": 0.22,
            },
        ],
    }


def view_seed(view: str) -> int:
    """Stable per-view seed derived from the view name, never from the clock."""
    digest = hashlib.sha256(f"{SEED_BASE}:{view}".encode()).hexdigest()
    return int(digest[:8], 16)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def portable_path(path: str | Path, *, root: Path = ROOT) -> str:
    """Describe a local artifact without publishing a machine-specific root."""
    resolved = Path(path).resolve()
    try:
        return resolved.relative_to(root.resolve()).as_posix()
    except ValueError:
        for index, component in enumerate(resolved.parts):
            if component.endswith(".app"):
                return "/".join(resolved.parts[index:])
        return resolved.name


def write_json(path: Path, payload: dict) -> None:
    """Atomically replace a JSON artifact in its destination directory."""
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, raw_temporary = tempfile.mkstemp(
        prefix=f".{path.name}.",
        suffix=".tmp",
        dir=path.parent,
        text=True,
    )
    temporary = Path(raw_temporary)
    try:
        with os.fdopen(handle, "w") as stream:
            stream.write(json.dumps(payload, indent=2, sort_keys=True) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise


def check_build_receipt(
    *,
    exports: Path = EXPORTS,
    receipt_path: Path = BUILD_REPORT,
    blend_path: Path = FIGURINE_BLEND,
    selected_mesh: Path = GENERATED_MESHES / "selected.glb",
) -> tuple[list["Failure"], dict]:
    """Bind downstream evidence to one successful source/export transaction.

    A canonical-looking STL directory is not sufficient: a failed rebuild may
    intentionally retain the last known-good files. The PASS receipt proves
    that the five current file hashes and the current Blender source were
    published together by this pipeline version.
    """
    subject = str(receipt_path)
    if not receipt_path.is_file():
        return [
            Failure(
                "build_receipt_missing",
                subject,
                "run build_figurine.py successfully before validating downstream artifacts",
            )
        ], {}

    try:
        payload = json.loads(receipt_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return [
            Failure("build_receipt_invalid", subject, f"cannot parse receipt: {exc}")
        ], {}
    if not isinstance(payload, dict):
        return [
            Failure("build_receipt_invalid", subject, "receipt root must be a JSON object")
        ], {}

    failures: list[Failure] = []
    if payload.get("status") != "PASS":
        failures.append(
            Failure(
                "build_receipt_status",
                subject,
                f"latest build status is {payload.get('status')!r}, not 'PASS'",
            )
        )
    if payload.get("pipeline_version") != PIPELINE_VERSION:
        failures.append(
            Failure(
                "build_receipt_version",
                subject,
                f"receipt version {payload.get('pipeline_version')!r} != current {PIPELINE_VERSION}",
            )
        )

    mode = payload.get("mode")
    selected_present = selected_mesh.exists() or selected_mesh.is_symlink()
    recorded_selected_hash = payload.get("selected_candidate_sha256")
    if selected_present:
        if selected_mesh.is_symlink() or not selected_mesh.is_file():
            failures.append(
                Failure(
                    "build_receipt_selected_source",
                    str(selected_mesh),
                    "selected candidate must be a regular non-symlink file",
                )
            )
        else:
            actual_selected_hash = sha256_file(selected_mesh)
            if mode != "selected_candidate_reviewed":
                failures.append(
                    Failure(
                        "build_receipt_mode",
                        subject,
                        "selected.glb now exists, but the successful receipt is not from "
                        "the supervised selected-candidate workflow",
                    )
                )
            if recorded_selected_hash != actual_selected_hash:
                failures.append(
                    Failure(
                        "build_receipt_selected_hash",
                        str(selected_mesh),
                        "selected.glb does not match the candidate bound to the build receipt",
                    )
                )
    else:
        if mode != "provisional_game_art_prototype":
            failures.append(
                Failure(
                    "build_receipt_mode",
                    subject,
                    "without selected.glb, a successful receipt must identify the "
                    "provisional game-art prototype workflow",
                )
            )
        if recorded_selected_hash is not None:
            failures.append(
                Failure(
                    "build_receipt_selected_hash",
                    subject,
                    "receipt records a selected candidate, but selected.glb is absent",
                )
            )

    expected_names = {f"{name}.stl" for name in PART_NAMES}
    disk_entries = (
        [path for path in exports.iterdir() if path.suffix.lower() == ".stl"]
        if exports.is_dir()
        else []
    )
    disk_names = {path.name for path in disk_entries}
    if disk_names != expected_names:
        failures.append(
            Failure(
                "build_receipt_disk_inventory",
                str(exports),
                "on-disk export inventory drifted; "
                f"missing={sorted(expected_names - disk_names)} "
                f"unexpected={sorted(disk_names - expected_names)}",
            )
        )
    recorded_exports = payload.get("exports")
    if not isinstance(recorded_exports, dict):
        failures.append(
            Failure("build_receipt_exports", subject, "receipt exports field is not an object")
        )
        recorded_exports = {}
    recorded_names = set(recorded_exports)
    if recorded_names != expected_names:
        failures.append(
            Failure(
                "build_receipt_exports",
                subject,
                "receipt export inventory drifted; "
                f"missing={sorted(expected_names - recorded_names)} "
                f"unexpected={sorted(recorded_names - expected_names)}",
            )
        )
    for filename in sorted(expected_names & recorded_names):
        path = exports / filename
        if path.is_symlink() or not path.is_file():
            failures.append(
                Failure(
                    "build_receipt_export_missing",
                    filename,
                    "canonical export is missing or is not a regular non-symlink file",
                )
            )
            continue
        actual = sha256_file(path)
        if recorded_exports[filename] != actual:
            failures.append(
                Failure(
                    "build_receipt_hash",
                    filename,
                    f"receipt {str(recorded_exports[filename])[:12]} != disk {actual[:12]}",
                )
            )

    try:
        expected_source = str(blend_path.relative_to(ROOT))
    except ValueError:
        expected_source = str(blend_path)
    if payload.get("source_blend") != expected_source:
        failures.append(
            Failure(
                "build_receipt_source",
                subject,
                f"source_blend {payload.get('source_blend')!r} != {expected_source!r}",
            )
        )
    if blend_path.is_symlink() or not blend_path.is_file():
        failures.append(
            Failure("build_receipt_source", expected_source, "source Blender file is missing")
        )
    elif payload.get("source_blend_sha256") != sha256_file(blend_path):
        failures.append(
            Failure(
                "build_receipt_source_hash",
                expected_source,
                "current Blender source hash does not match the successful build receipt",
            )
        )
    return failures, payload


@dataclass(frozen=True)
class Failure:
    """One machine-readable validation failure."""

    check: str
    subject: str
    detail: str

    def as_dict(self) -> dict:
        return {"check": self.check, "subject": self.subject, "detail": self.detail}


def candidate_count_failures(candidate_count: int, minimum: int = 3) -> list[Failure]:
    """Require a real multi-generator bakeoff, not a one-candidate ceremony."""
    if candidate_count >= minimum:
        return []
    return [
        Failure(
            "candidate_count",
            str(candidate_count),
            f"at least {minimum} distinct generated candidates are required before scoring",
        )
    ]


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
