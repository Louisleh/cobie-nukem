#!/usr/bin/env python3
"""Phase 3 gate: is the geometry actually printable?

Run:
    uv run --project cobie-collectible/tools \
        python cobie-collectible/scripts/print_check.py

Validates every STL in cobie-collectible/exports/ against the print rules in
PRD section 10.9, then checks the assembly as a whole.

The PRD names Blender's 3D Print Toolbox for this. That addon is not shipped in
the `bpy` PyPI wheel, so the checks are implemented directly on trimesh and
pymeshlab instead. That turned out to be the better outcome: these run in CI,
fail with specific numbers, and are unit-testable, none of which is true of a
GUI addon.
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import numpy as np
import pymeshlab
import trimesh
from scipy.spatial import cKDTree

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    ASSEMBLY_CLEARANCE_RANGE_MM,
    BALANCE_MARGIN_RATIO,
    BASE_DIAMETER_RANGE_MM,
    BASE_THICKNESS_RANGE_MM,
    EXPORTS,
    FIGURE_HEIGHT_RANGE_MM,
    Failure,
    MIN_FEATURE_MM,
    report,
    sha256_file,
    write_json,
)

THICKNESS_SAMPLES = 1500
THICKNESS_FACE_BUDGET = 4000
THICKNESS_NEIGHBOURS = 12
# A handful of thin samples is measurement noise on a stylised sculpt; a
# sustained fraction is a real wall that will snap during support removal.
MAX_THIN_FRACTION = 0.02
MIN_TRIANGLES = 500


def load_parts() -> dict[str, trimesh.Trimesh]:
    parts: dict[str, trimesh.Trimesh] = {}
    for path in sorted(EXPORTS.glob("*.stl")):
        mesh = trimesh.load(path, force="mesh")
        if isinstance(mesh, trimesh.Trimesh):
            parts[path.stem] = mesh
    return parts


def _decimate(mesh: trimesh.Trimesh, face_budget: int = THICKNESS_FACE_BUDGET) -> trimesh.Trimesh:
    """Reduce face count before the thickness query.

    Wall thickness is a low-frequency property, but trimesh's pure-Python ray
    engine is O(faces) per ray. On the ~85k-face voxel remesh the full query
    takes many minutes, which in practice means the check does not get run.
    Decimating to a few thousand faces changes measured thickness by well under
    0.1 mm and brings the query under a second.
    """
    if mesh.faces.shape[0] <= face_budget:
        return mesh
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / "in.stl"
        reduced = Path(tmp) / "out.stl"
        mesh.export(source)
        meshset = pymeshlab.MeshSet()
        meshset.load_new_mesh(str(source))
        meshset.meshing_decimation_quadric_edge_collapse(
            targetfacenum=face_budget, preservetopology=True, planarquadric=True
        )
        meshset.save_current_mesh(str(reduced))
        return trimesh.load(reduced, force="mesh")


def measure_thickness(mesh: trimesh.Trimesh, samples: int = THICKNESS_SAMPLES) -> np.ndarray:
    """Local wall thickness at points sampled over the surface.

    Uses the inscribed-sphere method: at each surface point, the diameter of the
    largest sphere that fits inside the solid while touching that point. This is
    what actually predicts breakage, unlike a bounding-box or volume proxy.

    The raw per-point value is then replaced by the maximum over each point's
    nearest neighbours. Without that step the measurement is dominated by sharp
    convex edges, where the inscribed sphere is genuinely tiny even though there
    is thick material immediately behind -- on the sunglasses that artefact
    reports 34% of the surface as thin when the true wall is a uniform 1.6 mm.
    A genuinely thin wall has thin neighbours; an edge does not.
    """
    if mesh.faces.shape[0] == 0:
        return np.array([])

    probe = _decimate(mesh)
    # Deterministic sampling: seed the global RNG trimesh draws from, so a rerun
    # on unchanged geometry produces an unchanged report.
    np.random.seed(0)
    points, face_index = trimesh.sample.sample_surface(probe, samples)
    normals = probe.face_normals[face_index]
    # Deliberately not wrapped in try/except. If thickness cannot be measured
    # the correct outcome is a loud failure, not a quiet PASS on a check that
    # never ran -- which is what an earlier version of this file did.
    raw = trimesh.proximity.thickness(mesh=probe, points=points, normals=normals, exterior=False)
    raw = np.nan_to_num(np.asarray(raw, dtype=np.float64), nan=0.0, posinf=0.0, neginf=0.0)

    neighbours = min(THICKNESS_NEIGHBOURS, len(points))
    _, indices = cKDTree(points).query(points, k=neighbours)
    return raw[indices].max(axis=1)


def check_part(name: str, mesh: trimesh.Trimesh) -> list[Failure]:
    failures: list[Failure] = []

    if mesh.faces.shape[0] < MIN_TRIANGLES:
        failures.append(
            Failure("triangle_count", name, f"{mesh.faces.shape[0]} triangles is too coarse for a detail resin print")
        )

    if not mesh.is_watertight:
        failures.append(
            Failure("watertight", name, "mesh is not watertight; slicers cannot resolve inside from outside")
        )

    if not mesh.is_winding_consistent:
        failures.append(Failure("winding", name, "face winding is inconsistent; normals point both ways"))

    if mesh.volume <= 0:
        failures.append(Failure("volume", name, f"volume is {mesh.volume:.3f}; normals are probably inverted"))

    degenerate = int((~mesh.nondegenerate_faces()).sum())
    if degenerate:
        failures.append(Failure("degenerate_faces", name, f"{degenerate} zero-area face(s)"))

    bodies = mesh.body_count
    if bodies > 1:
        failures.append(
            Failure(
                "floating_shells",
                name,
                f"{bodies} disconnected bodies; a part must be one solid or the slicer prints orphan fragments",
            )
        )

    thickness = measure_thickness(mesh)
    if thickness.size == 0:
        failures.append(
            Failure("min_thickness", name, "thickness could not be measured; treat this as unvalidated, not as passing")
        )
        return failures

    thin = float((thickness < MIN_FEATURE_MM).mean())
    if thin > MAX_THIN_FRACTION:
        failures.append(
            Failure(
                "min_thickness",
                name,
                f"{thin:.1%} of the surface is thinner than {MIN_FEATURE_MM} mm "
                f"(min {thickness.min():.2f} mm); it will break during support removal",
            )
        )

    return failures


PLATE_FOOTPRINT_RATIO = 0.5


def plate_thickness(base: trimesh.Trimesh, diameter: float) -> float:
    """Thickness of the base plate itself, ignoring the keying peg.

    The peg deliberately protrudes above the plate, so the part's bounding-box
    height overstates plate thickness. Measure instead the z-band over which
    the cross-section is still most of the full footprint: that band is the
    plate, and everything above it is keying hardware.
    """
    vertices = base.vertices
    radial = np.linalg.norm(vertices[:, :2] - base.bounds.mean(axis=0)[:2], axis=1)
    plate_vertices = vertices[radial > (diameter / 2.0) * PLATE_FOOTPRINT_RATIO]
    if plate_vertices.size == 0:
        return float(base.bounds[1][2] - base.bounds[0][2])
    return float(plate_vertices[:, 2].max() - plate_vertices[:, 2].min())


def check_assembly(parts: dict[str, trimesh.Trimesh]) -> tuple[list[Failure], dict]:
    failures: list[Failure] = []
    if not parts:
        return [Failure("no_parts", "exports/", "no STL files found")], {}

    combined = trimesh.util.concatenate(list(parts.values()))
    lo, hi = combined.bounds
    height = float(hi[2] - lo[2])

    if not FIGURE_HEIGHT_RANGE_MM[0] <= height <= FIGURE_HEIGHT_RANGE_MM[1]:
        failures.append(
            Failure(
                "figure_height",
                "assembly",
                f"{height:.1f} mm is outside the {FIGURE_HEIGHT_RANGE_MM[0]:.0f}-"
                f"{FIGURE_HEIGHT_RANGE_MM[1]:.0f} mm V1 envelope. If this reads as "
                "metres or as a fraction, the unit scale is wrong",
            )
        )

    base = parts.get("Base_Keyed")
    metrics: dict = {
        "assembly_height_mm": round(height, 3),
        "part_count": len(parts),
        "parts": {
            name: {
                "triangles": int(mesh.faces.shape[0]),
                "volume_mm3": round(float(mesh.volume), 3),
                "watertight": bool(mesh.is_watertight),
                "bodies": int(mesh.body_count),
            }
            for name, mesh in parts.items()
        },
    }

    if base is None:
        failures.append(Failure("base_missing", "assembly", "no Base_Keyed.stl; the figure has nothing to stand on"))
        return failures, metrics

    base_lo, base_hi = base.bounds
    base_diameter = float(max(base_hi[0] - base_lo[0], base_hi[1] - base_lo[1]))
    base_thickness = plate_thickness(base, base_diameter)
    metrics["base_thickness_mm"] = round(base_thickness, 3)
    metrics["base_diameter_mm"] = round(base_diameter, 3)

    if not BASE_THICKNESS_RANGE_MM[0] <= base_thickness <= BASE_THICKNESS_RANGE_MM[1]:
        failures.append(
            Failure("base_thickness", "Base_Keyed", f"{base_thickness:.2f} mm outside {BASE_THICKNESS_RANGE_MM} mm")
        )
    if not BASE_DIAMETER_RANGE_MM[0] <= base_diameter <= BASE_DIAMETER_RANGE_MM[1]:
        failures.append(
            Failure("base_diameter", "Base_Keyed", f"{base_diameter:.1f} mm outside {BASE_DIAMETER_RANGE_MM} mm")
        )

    # FR-4, "stands unaided on a level shelf". The centre of mass, projected
    # straight down, must land well inside the base footprint. A figure whose
    # mass sits near the rim topples the first time a door closes.
    centre = combined.center_mass
    base_centre = (base_lo[:2] + base_hi[:2]) / 2.0
    radius = base_diameter / 2.0
    offset = float(np.linalg.norm(centre[:2] - base_centre))
    margin = offset / radius if radius else float("inf")
    metrics["balance_offset_mm"] = round(offset, 3)
    metrics["balance_margin_ratio"] = round(margin, 4)

    if margin > BALANCE_MARGIN_RATIO:
        failures.append(
            Failure(
                "balance",
                "assembly",
                f"centre of mass sits {offset:.1f} mm off the base centre "
                f"({margin:.0%} of the base radius, limit {BALANCE_MARGIN_RATIO:.0%}); "
                "the figure will not stand reliably",
            )
        )

    return failures, metrics


def main() -> int:
    parts = load_parts()
    failures: list[Failure] = []
    for name, mesh in sorted(parts.items()):
        failures.extend(check_part(name, mesh))

    assembly_failures, metrics = check_assembly(parts)
    failures.extend(assembly_failures)

    metrics["clearance_contract_mm"] = list(ASSEMBLY_CLEARANCE_RANGE_MM)
    metrics["export_hashes"] = {path.name: sha256_file(path) for path in sorted(EXPORTS.glob("*.stl"))}
    write_json(EXPORTS / "print_check_report.json", {"metrics": metrics, "failures": [f.as_dict() for f in failures]})

    for key in ("assembly_height_mm", "base_diameter_mm", "base_thickness_mm", "balance_margin_ratio"):
        if key in metrics:
            print(f"  {key}: {metrics[key]}")
    return report("COBIE_FIGURINE_PRINT_CHECK", failures, metrics)


if __name__ == "__main__":
    raise SystemExit(main())
