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

import importlib.metadata
import platform
import sys
import tempfile
from itertools import combinations
from pathlib import Path

import numpy as np
import pymeshlab
import trimesh
from scipy.spatial import cKDTree

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import (
    ASSEMBLY_CLEARANCE_RANGE_MM,
    BALANCE_MARGIN_RATIO,
    BASE_PEG_SPECS,
    BASE_DIAMETER_RANGE_MM,
    BASE_THICKNESS_RANGE_MM,
    BUILD_REPORT,
    EXPORTS,
    FIGURE_HEIGHT_RANGE_MM,
    Failure,
    GLASSES_PIN_SPECS,
    HEAD_KEY_SPECS,
    MIN_FEATURE_MM,
    NECK_CENTRE,
    NECK_DEPTH_MM,
    NECK_RADIUS_MM,
    PART_NAMES,
    PROP_PIN_SPECS,
    check_build_receipt,
    portable_path,
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
ASSEMBLY_INTERSECTION_ENGINE = "manifold"
MAX_INTERSECTION_VOLUME_MM3 = 1e-4
JOINT_ANGULAR_SAMPLES = 64
JOINT_AXIAL_SAMPLES = 4
MIN_JOINT_COVERAGE = 0.98

ALL_PART_PAIRS = tuple(combinations(PART_NAMES, 2))

REPORTED_DISTRIBUTIONS = {
    "bpy": "bpy",
    "manifold3d": "manifold3d",
    "numpy": "numpy",
    "pillow": "Pillow",
    "pymeshlab": "pymeshlab",
    "rtree": "rtree",
    "scipy": "scipy",
    "trimesh": "trimesh",
}

PYMESHLAB_REQUIRED_FILTER = "meshing_decimation_quadric_edge_collapse"
PYMESHLAB_REQUIRED_PLUGINS = ("libio_base.so", "libfilter_meshing.so")


def _ensure_pymeshlab_plugins() -> None:
    """Load the STL I/O and decimation plugins when wheel auto-loading fails.

    On Apple Silicon, PyMeshLab 2025.7 can import successfully while reporting
    zero loaded plugins.  The high-level load call then fails with the
    misleading error ``Unknown format for load: stl``.  Loading the two wheel-
    bundled plugins explicitly keeps the print gate deterministic without
    weakening it.  Any genuinely missing capability still fails loudly.
    """
    if PYMESHLAB_REQUIRED_FILTER in pymeshlab.filter_list():
        return

    plugin_dir = Path(pymeshlab.__file__).resolve().parent / "PlugIns"
    load_failures: list[str] = []
    for filename in PYMESHLAB_REQUIRED_PLUGINS:
        plugin_path = plugin_dir / filename
        if not plugin_path.is_file():
            load_failures.append(f"{filename}: file missing")
            continue
        try:
            pymeshlab.load_plugin(str(plugin_path))
        except Exception as exc:
            load_failures.append(f"{filename}: {exc}")

    if PYMESHLAB_REQUIRED_FILTER not in pymeshlab.filter_list():
        detail = "; ".join(load_failures) or "plugins loaded but required filter is unavailable"
        raise RuntimeError(
            f"PyMeshLab cannot provide {PYMESHLAB_REQUIRED_FILTER}: {detail}"
        )


def _stl_paths(exports: Path) -> list[Path]:
    """Return every STL-like file, including stale files with case drift."""
    if not exports.is_dir():
        return []
    return sorted(
        (path for path in exports.iterdir() if path.is_file() and path.suffix.lower() == ".stl"),
        key=lambda path: path.name,
    )


def check_export_inventory(exports: Path = EXPORTS) -> list[Failure]:
    """Require exactly one canonical STL for every declared printable part."""
    expected = {f"{name}.stl" for name in PART_NAMES}
    observed = {path.name for path in _stl_paths(exports)}
    failures: list[Failure] = []

    for filename in sorted(expected - observed):
        failures.append(
            Failure(
                "missing_part",
                filename,
                "required STL export is missing; rebuild the complete five-part export set",
            )
        )
    for filename in sorted(observed - expected):
        failures.append(
            Failure(
                "unexpected_part",
                filename,
                "unexpected or stale STL export; remove it before validating this build",
            )
        )
    return failures


def load_parts(exports: Path = EXPORTS) -> dict[str, trimesh.Trimesh]:
    """Load canonical parts only; inventory failures are reported separately."""
    parts: dict[str, trimesh.Trimesh] = {}
    for name in PART_NAMES:
        path = exports / f"{name}.stl"
        if not path.is_file():
            continue
        mesh = trimesh.load(path, force="mesh")
        if isinstance(mesh, trimesh.Trimesh):
            parts[name] = mesh
    return parts


def environment_stamp() -> dict:
    """Record the interpreter, host platform, and validator dependency set."""
    packages: dict[str, str] = {}
    for label, distribution in REPORTED_DISTRIBUTIONS.items():
        try:
            packages[label] = importlib.metadata.version(distribution)
        except importlib.metadata.PackageNotFoundError:
            packages[label] = "not-installed"

    return {
        "platform": {
            "description": platform.platform(),
            "machine": platform.machine(),
            "release": platform.release(),
            "system": platform.system(),
        },
        "python": {
            "compiler": platform.python_compiler(),
            "executable": portable_path(sys.executable),
            "implementation": platform.python_implementation(),
            "version": platform.python_version(),
        },
        "packages": packages,
    }


def build_report_payload(metrics: dict, failures: list[Failure]) -> dict:
    return {
        "environment": environment_stamp(),
        "metrics": metrics,
        "failures": [failure.as_dict() for failure in failures],
    }


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
    _ensure_pymeshlab_plugins()
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / "in.stl"
        reduced = Path(tmp) / "out.stl"
        mesh.export(source)
        meshset = pymeshlab.MeshSet()
        meshset.load_new_mesh(str(source))
        # apply_filter is intentional: PyMeshLab binds convenience methods at
        # import time, before the macOS wheel's plugins have been loaded.
        meshset.apply_filter(
            PYMESHLAB_REQUIRED_FILTER,
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


def cylindrical_sideband_probe(
    male: trimesh.Trimesh,
    female: trimesh.Trimesh,
    *,
    centre: tuple[float, float, float],
    axis: int,
    radius: float,
    axial_min: float,
    axial_max: float,
    radial_band: float,
) -> dict:
    """Measure an exported cylindrical joint away from its end caps.

    Trimesh signed distance is positive inside a watertight target. Therefore a
    positive value is interpenetration; a negative value is open space and its
    negation is the actual surface gap. Every matching exported-mesh vertex is
    used, so the result has no sampling seed.
    """
    vertices = male.vertices
    radial_axes = tuple(index for index in range(3) if index != axis)
    centre_array = np.asarray(centre, dtype=np.float64)
    offset = vertices[:, radial_axes] - centre_array[list(radial_axes)]
    radial_distance = np.linalg.norm(offset, axis=1)
    mask = (
        (vertices[:, axis] > axial_min)
        & (vertices[:, axis] < axial_max)
        & (np.abs(radial_distance - radius) < radial_band)
    )
    points = vertices[mask]
    if len(points) == 0:
        return {
            "sample_count": 0,
            "inside_count": 0,
            "max_interpenetration_mm": 0.0,
            "min_sampled_gap_mm": None,
            "gap_p05_mm": None,
            "gap_p50_mm": None,
            "gap_p95_mm": None,
            "max_sampled_gap_mm": None,
        }

    signed = trimesh.proximity.ProximityQuery(female).signed_distance(points)
    outside = signed <= 0.0
    gaps = -signed[outside]
    return {
        "sample_count": int(len(points)),
        "inside_count": int((signed > 1e-4).sum()),
        "max_interpenetration_mm": round(max(float(signed.max()), 0.0), 6),
        "min_sampled_gap_mm": (
            round(float(gaps.min()), 6) if outside.any() else 0.0
        ),
        "gap_p05_mm": (
            round(float(np.percentile(gaps, 5)), 6) if outside.any() else 0.0
        ),
        "gap_p50_mm": (
            round(float(np.percentile(gaps, 50)), 6) if outside.any() else 0.0
        ),
        "gap_p95_mm": (
            round(float(np.percentile(gaps, 95)), 6) if outside.any() else 0.0
        ),
        "max_sampled_gap_mm": (
            round(float(gaps.max()), 6) if outside.any() else 0.0
        ),
    }


def _first_ray_hits(
    mesh: trimesh.Trimesh,
    origins: np.ndarray,
    directions: np.ndarray,
) -> np.ndarray:
    """Return the first positive hit distance for each ray, or NaN."""
    result = np.full(len(origins), np.nan, dtype=np.float64)
    locations, ray_indices, _ = mesh.ray.intersects_location(
        origins,
        directions,
        multiple_hits=True,
    )
    if len(locations) == 0:
        return result
    distances = np.einsum(
        "ij,ij->i",
        locations - origins[ray_indices],
        directions[ray_indices],
    )
    for ray_index, distance in zip(ray_indices, distances):
        if distance <= 1e-5:
            continue
        if np.isnan(result[ray_index]) or distance < result[ray_index]:
            result[ray_index] = distance
    return result


def cylindrical_radial_clearance_probe(
    male: trimesh.Trimesh,
    female: trimesh.Trimesh,
    *,
    centre: tuple[float, float, float],
    axis: int,
    axial_min: float,
    axial_max: float,
    axial_samples: int = JOINT_AXIAL_SAMPLES,
    angular_samples: int = JOINT_ANGULAR_SAMPLES,
) -> dict:
    """Measure complete exported mating rings with deterministic radial rays.

    Each ray starts on the joint axis, exits the exported male, then reaches
    the first exported female cavity wall. Missing wall directions are exposed
    joint sectors, not valid clearance samples. This avoids letting one local
    nearest point conceal a socket that is loose or open around most of its
    circumference.
    """
    radial_axes = tuple(index for index in range(3) if index != axis)
    axial_values = np.linspace(axial_min, axial_max, axial_samples)
    angles = np.linspace(0.0, 2.0 * np.pi, angular_samples, endpoint=False)
    origins: list[np.ndarray] = []
    directions: list[np.ndarray] = []
    for axial_value in axial_values:
        for angle in angles:
            origin = np.asarray(centre, dtype=np.float64).copy()
            origin[axis] = axial_value
            direction = np.zeros(3, dtype=np.float64)
            direction[radial_axes[0]] = np.cos(angle)
            direction[radial_axes[1]] = np.sin(angle)
            origins.append(origin)
            directions.append(direction)
    origin_array = np.asarray(origins)
    direction_array = np.asarray(directions)

    male_hits = _first_ray_hits(male, origin_array, direction_array)
    female_hits = _first_ray_hits(female, origin_array, direction_array)
    valid = np.isfinite(male_hits) & np.isfinite(female_hits)
    gaps = female_hits[valid] - male_hits[valid]
    collisions = gaps < -1e-4
    clear_gaps = gaps[~collisions]
    female_origin_signed = trimesh.proximity.ProximityQuery(female).signed_distance(origin_array)
    female_origin_inside = female_origin_signed > 1e-4

    expected = len(origin_array)
    result = {
        "sample_count": int(valid.sum()),
        "expected_sample_count": expected,
        "coverage_ratio": round(float(valid.mean()), 6),
        "missing_male_rays": int((~np.isfinite(male_hits)).sum()),
        "missing_female_rays": int((~np.isfinite(female_hits)).sum()),
        "inside_count": int(collisions.sum() + female_origin_inside.sum()),
        "female_origin_inside_count": int(female_origin_inside.sum()),
        "max_interpenetration_mm": (
            round(float(-gaps[collisions].min()), 6) if collisions.any() else 0.0
        ),
        "min_sampled_gap_mm": None,
        "gap_p05_mm": None,
        "gap_p50_mm": None,
        "gap_p95_mm": None,
        "max_sampled_gap_mm": None,
    }
    if clear_gaps.size:
        result.update(
            {
                "min_sampled_gap_mm": round(float(clear_gaps.min()), 6),
                "gap_p05_mm": round(float(np.percentile(clear_gaps, 5)), 6),
                "gap_p50_mm": round(float(np.percentile(clear_gaps, 50)), 6),
                "gap_p95_mm": round(float(np.percentile(clear_gaps, 95)), 6),
                "max_sampled_gap_mm": round(float(clear_gaps.max()), 6),
            }
        )
    return result


def _joint_probe_specs() -> list[dict]:
    specs: list[dict] = []
    for index, (x, y, radius, height) in enumerate(BASE_PEG_SPECS):
        specs.append(
            {
                "name": f"base_key_{index}",
                "male": "Base_Keyed",
                "female": "Cobie_Body",
                "centre": (x, y, 0.0),
                "axis": 2,
                "axial_min": 7.5 if index == 0 else 7.0,
                "axial_max": 9.5 if index == 0 else 9.0,
            }
        )
    specs.append(
        {
            "name": "neck_recess",
            "male": "Cobie_Body",
            "female": "Cobie_Head",
            "centre": NECK_CENTRE,
            "axis": 2,
            "axial_min": 101.5,
            "axial_max": 102.8,
        }
    )
    for index, (x, y, radius, height) in enumerate(HEAD_KEY_SPECS):
        specs.append(
            {
                "name": f"head_key_{index}",
                "male": "Cobie_Body",
                "female": "Cobie_Head",
                "centre": (x, y, 0.0),
                "axis": 2,
                "axial_min": 107.0,
                "axial_max": 111.0,
            }
        )
    for index, (x, y, z, radius, depth) in enumerate(GLASSES_PIN_SPECS):
        specs.append(
            {
                "name": f"glasses_pin_{index}",
                "male": "Cobie_Sunglasses",
                "female": "Cobie_Head",
                "centre": (x, y, z),
                "axis": 1,
                "axial_min": -5.8,
                "axial_max": -4.2,
            }
        )
    for index, (x, y, z, radius, depth) in enumerate(PROP_PIN_SPECS):
        specs.append(
            {
                "name": f"launcher_pin_{index}",
                "male": "Cobie_Prop_FetchLauncher",
                "female": "Cobie_Body",
                "centre": (x, y, z),
                "axis": 1,
                "axial_min": -9.5,
                "axial_max": -8.5,
            }
        )
    return specs


def evaluate_joint_clearance(name: str, result: dict) -> list[Failure]:
    """Apply coverage, collision, and robust distribution gates to one joint."""
    failures: list[Failure] = []
    minimum, maximum = ASSEMBLY_CLEARANCE_RANGE_MM
    if result["sample_count"] == 0:
        return [
            Failure(
                "joint_unmeasured",
                name,
                "no complete exported male/socket ray pair matched the engagement band",
            )
        ]
    if result["coverage_ratio"] < MIN_JOINT_COVERAGE:
        failures.append(
            Failure(
                "joint_coverage",
                name,
                f"only {result['coverage_ratio']:.1%} of the intended mating rings have "
                "both a male wall and surrounding female socket",
            )
        )
    if result["inside_count"] > 0:
        failures.append(
            Failure(
                "joint_collision",
                name,
                f"{result['inside_count']} radial samples enter the mating part "
                f"(max {result['max_interpenetration_mm']:.3f} mm)",
            )
        )
        return failures

    lower_gap = result["gap_p05_mm"]
    upper_gap = result["gap_p95_mm"]
    if (
        lower_gap is None
        or upper_gap is None
        or lower_gap < minimum
        or upper_gap > maximum
    ):
        failures.append(
            Failure(
                "joint_clearance",
                name,
                f"exported radial p05/p95 gaps are {lower_gap}/{upper_gap} mm; "
                f"required distribution is {minimum:.2f}-{maximum:.2f} mm",
            )
        )
    return failures


def check_joint_clearances(parts: dict[str, trimesh.Trimesh]) -> tuple[list[Failure], dict]:
    failures: list[Failure] = []
    metrics: dict[str, dict] = {}
    for spec in _joint_probe_specs():
        male = parts.get(spec["male"])
        female = parts.get(spec["female"])
        if male is None or female is None:
            continue
        kwargs = {
            key: spec[key]
            for key in ("centre", "axis", "axial_min", "axial_max")
        }
        result = cylindrical_radial_clearance_probe(male, female, **kwargs)
        metrics[spec["name"]] = result
        failures.extend(evaluate_joint_clearance(spec["name"], result))
    return failures, metrics


def check_interpart_overlaps(
    parts: dict[str, trimesh.Trimesh],
    *,
    pairs: tuple[tuple[str, str], ...] = ALL_PART_PAIRS,
) -> tuple[list[Failure], dict]:
    """Reject any exact solid-volume collision across all printable part pairs.

    A surface sampler can miss a small but real corner collision. Manifold's
    deterministic boolean intersection cannot: disjoint AABBs are culled, and
    every remaining pair is intersected as closed volumes.
    """
    failures: list[Failure] = []
    metrics: dict[str, dict] = {}
    for left_name, right_name in pairs:
        if left_name not in parts or right_name not in parts:
            continue
        pair_name = f"{left_name}<->{right_name}"
        left = parts[left_name]
        right = parts[right_name]
        lower = np.maximum(left.bounds[0], right.bounds[0])
        upper = np.minimum(left.bounds[1], right.bounds[1])
        overlap_extents = upper - lower
        pair_metrics = {
            "engine": ASSEMBLY_INTERSECTION_ENGINE,
            "aabb_overlap_extents_mm": [
                round(max(float(value), 0.0), 6) for value in overlap_extents
            ],
            "intersection_faces": 0,
            "intersection_volume_mm3": 0.0,
            "maximum_allowed_volume_mm3": MAX_INTERSECTION_VOLUME_MM3,
            "status": "AABB_DISJOINT_OR_TOUCHING",
        }
        metrics[pair_name] = pair_metrics

        invalid_inputs = [
            name
            for name, mesh in ((left_name, left), (right_name, right))
            if not mesh.is_volume
        ]
        if invalid_inputs:
            pair_metrics["status"] = "UNMEASURED_NON_VOLUME_INPUT"
            failures.append(
                Failure(
                    "interpart_overlap_unmeasured",
                    pair_name,
                    "exact boolean requires closed positive-volume inputs; invalid="
                    + ", ".join(invalid_inputs),
                )
            )
            continue
        if np.any(overlap_extents <= 0.0):
            continue

        try:
            intersection = trimesh.boolean.intersection(
                [left, right],
                engine=ASSEMBLY_INTERSECTION_ENGINE,
                check_volume=True,
            )
        except Exception as exc:
            pair_metrics["status"] = "UNMEASURED_BOOLEAN_ERROR"
            pair_metrics["error"] = f"{type(exc).__name__}: {exc}"
            failures.append(
                Failure(
                    "interpart_overlap_unmeasured",
                    pair_name,
                    f"exact {ASSEMBLY_INTERSECTION_ENGINE} boolean failed: "
                    f"{type(exc).__name__}: {exc}",
                )
            )
            continue
        if not isinstance(intersection, trimesh.Trimesh):
            pair_metrics["status"] = "UNMEASURED_BOOLEAN_RESULT"
            failures.append(
                Failure(
                    "interpart_overlap_unmeasured",
                    pair_name,
                    f"exact boolean returned {type(intersection).__name__}, not a mesh",
                )
            )
            continue

        intersection_faces = int(intersection.faces.shape[0])
        pair_metrics["intersection_faces"] = intersection_faces
        if intersection_faces == 0:
            pair_metrics["status"] = "CLEAR"
            continue
        if not intersection.is_volume:
            pair_metrics["status"] = "UNMEASURED_NON_VOLUME_RESULT"
            failures.append(
                Failure(
                    "interpart_overlap_unmeasured",
                    pair_name,
                    "exact boolean returned faces that do not form a closed volume",
                )
            )
            continue

        intersection_volume = abs(float(intersection.volume))
        if not np.isfinite(intersection_volume):
            pair_metrics["status"] = "UNMEASURED_NON_FINITE_VOLUME"
            failures.append(
                Failure(
                    "interpart_overlap_unmeasured",
                    pair_name,
                    f"exact boolean returned non-finite volume {intersection_volume!r}",
                )
            )
            continue
        pair_metrics["intersection_volume_mm3"] = round(intersection_volume, 9)
        pair_metrics["status"] = (
            "OVERLAP"
            if intersection_volume > MAX_INTERSECTION_VOLUME_MM3
            else "CLEAR_WITHIN_NUMERIC_TOLERANCE"
        )
        if intersection_volume > MAX_INTERSECTION_VOLUME_MM3:
            failures.append(
                Failure(
                    "interpart_overlap",
                    pair_name,
                    f"exact assembled-volume intersection is {intersection_volume:.6f} mm^3 "
                    f"(numeric tolerance {MAX_INTERSECTION_VOLUME_MM3:.6f} mm^3)",
                )
            )
    return failures, metrics


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


def _run() -> int:
    parts = load_parts()
    receipt_failures, build_receipt = check_build_receipt()
    failures = [*receipt_failures, *check_export_inventory()]
    for name, mesh in sorted(parts.items()):
        failures.extend(check_part(name, mesh))

    assembly_failures, metrics = check_assembly(parts)
    failures.extend(assembly_failures)

    canonical = set(parts) == set(PART_NAMES)
    topology_ready = canonical and all(
        mesh.is_watertight and mesh.is_winding_consistent and mesh.volume > 0
        for mesh in parts.values()
    )
    if topology_ready:
        joint_failures, joint_metrics = check_joint_clearances(parts)
        overlap_failures, overlap_metrics = check_interpart_overlaps(parts)
        failures.extend(joint_failures)
        failures.extend(overlap_failures)
        metrics["joint_clearances"] = joint_metrics
        metrics["interpart_overlaps"] = overlap_metrics
    else:
        metrics["joint_clearances"] = {"status": "skipped; canonical watertight parts required"}
        metrics["interpart_overlaps"] = {"status": "skipped; canonical watertight parts required"}

    metrics["clearance_contract_mm"] = list(ASSEMBLY_CLEARANCE_RANGE_MM)
    stl_paths = _stl_paths(EXPORTS)
    metrics["expected_stl_files"] = [f"{name}.stl" for name in PART_NAMES]
    metrics["observed_stl_files"] = [path.name for path in stl_paths]
    metrics["export_hashes"] = {path.name: sha256_file(path) for path in stl_paths}
    metrics["build_receipt"] = {
        "path": portable_path(BUILD_REPORT),
        "sha256": sha256_file(BUILD_REPORT) if BUILD_REPORT.is_file() else None,
        "status": build_receipt.get("status"),
        "pipeline_version": build_receipt.get("pipeline_version"),
        "source_blend_sha256": build_receipt.get("source_blend_sha256"),
    }
    write_json(EXPORTS / "print_check_report.json", build_report_payload(metrics, failures))

    for key in ("assembly_height_mm", "base_diameter_mm", "base_thickness_mm", "balance_margin_ratio"):
        if key in metrics:
            print(f"  {key}: {metrics[key]}")
    return report("COBIE_FIGURINE_PRINT_CHECK", failures, metrics)


def main() -> int:
    output = EXPORTS / "print_check_report.json"
    incomplete = Failure(
        "validation_incomplete",
        str(output),
        "print validation started but has not completed",
    )
    write_json(output, build_report_payload({}, [incomplete]))
    try:
        return _run()
    except Exception as exc:
        failure = Failure("validation_exception", str(output), f"{type(exc).__name__}: {exc}")
        write_json(output, build_report_payload({}, [failure]))
        return report("COBIE_FIGURINE_PRINT_CHECK", [failure])


if __name__ == "__main__":
    raise SystemExit(main())
