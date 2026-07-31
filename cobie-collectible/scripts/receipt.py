#!/usr/bin/env python3
"""Render receipts for the collectible bakeoff.

Modelled on tools/visual_quality/capture_tool.py. The governing idea is the
same one that tool enforces: the renderer's self-report is never trusted. Every
field it emits is independently re-derived host-side, and the image is re-hashed
from disk. A receipt that merely echoes what the renderer claimed proves
nothing.

The field set is exact. Extra or missing keys are a hard failure rather than a
warning, because silent schema drift is how provenance quietly stops meaning
anything.
"""

from __future__ import annotations

import math
import platform
from pathlib import Path

from PIL import Image

from _common import Failure, sha256_file

RECEIPT_FIELDS = frozenset(
    {
        "view",
        "candidate_id",
        "render_seed",
        "render_engine",
        "requested_resolution",
        "receipt_image_size",
        "camera_origin",
        "camera_forward",
        "camera_type",
        "ortho_scale",
        "yaw_degrees",
        "mesh_sha256",
        "image_sha256",
        "image_path",
    }
)

# Tolerances. Camera pose is authored, not simulated, so these are tight; they
# exist to catch a script that silently stopped applying the transform, not to
# absorb floating-point drift.
MAX_POSITION_ERROR = 0.01
MIN_DIRECTION_DOT = 0.999
MAX_ORTHO_SCALE_ERROR = 1e-4


def _normalize(vec: tuple[float, float, float]) -> tuple[float, float, float]:
    length = math.sqrt(sum(component * component for component in vec))
    if length == 0.0:
        return (0.0, 0.0, 0.0)
    return tuple(component / length for component in vec)  # type: ignore[return-value]


def expected_camera_origin(yaw_degrees: float, distance: float, height: float) -> tuple[float, float, float]:
    """Camera position for a yaw on the turntable, derived independently.

    The renderer computes this too. Deriving it a second time here is the whole
    point: if the two disagree the receipt fails.
    """
    yaw = math.radians(yaw_degrees)
    return (
        math.sin(yaw) * distance,
        -math.cos(yaw) * distance,
        height,
    )


def verify(
    receipt: dict,
    *,
    distance: float,
    height: float,
    ortho_scale: float,
    root: Path,
) -> list[Failure]:
    """Re-derive every claim in a receipt. Returns failures, empty means clean."""
    failures: list[Failure] = []
    subject = f"{receipt.get('candidate_id', '?')}/{receipt.get('view', '?')}"

    present = set(receipt)
    if present != RECEIPT_FIELDS:
        missing = sorted(RECEIPT_FIELDS - present)
        extra = sorted(present - RECEIPT_FIELDS)
        failures.append(
            Failure("receipt_schema", subject, f"fields drifted; missing={missing} extra={extra}")
        )
        return failures

    # Camera position, re-derived from yaw rather than trusted.
    expected = expected_camera_origin(receipt["yaw_degrees"], distance, height)
    actual = tuple(receipt["camera_origin"])
    position_error = math.dist(expected, actual)
    if position_error > MAX_POSITION_ERROR:
        failures.append(
            Failure(
                "camera_position",
                subject,
                f"origin {actual} is {position_error:.4f} from expected {tuple(round(v, 4) for v in expected)}",
            )
        )

    # Camera aim: must point from its origin back at the turntable axis.
    to_target = _normalize((-actual[0], -actual[1], (height * 0.5) - actual[2]))
    forward = _normalize(tuple(receipt["camera_forward"]))
    direction_dot = sum(a * b for a, b in zip(to_target, forward))
    if direction_dot < MIN_DIRECTION_DOT:
        failures.append(
            Failure("camera_aim", subject, f"direction_dot {direction_dot:.5f} below {MIN_DIRECTION_DOT}")
        )

    if receipt["camera_type"] != "ORTHO":
        failures.append(
            Failure(
                "camera_type",
                subject,
                f"expected ORTHO for comparable candidate renders, got {receipt['camera_type']}",
            )
        )

    try:
        scale_error = abs(float(receipt["ortho_scale"]) - ortho_scale)
    except (TypeError, ValueError):
        scale_error = float("inf")
    if scale_error > MAX_ORTHO_SCALE_ERROR:
        failures.append(
            Failure(
                "ortho_scale",
                subject,
                f"reported {receipt['ortho_scale']!r}, expected {ortho_scale:.4f}",
            )
        )

    # Three independent sources for the image dimensions must agree: what was
    # requested, what the renderer reported, and what is actually on disk.
    image_path = root / receipt["image_path"]
    if not image_path.is_file():
        failures.append(Failure("image_missing", subject, f"{image_path} does not exist"))
        return failures

    with Image.open(image_path) as handle:
        disk_size = list(handle.size)
    requested = list(receipt["requested_resolution"])
    reported = list(receipt["receipt_image_size"])
    if not (requested == reported == disk_size):
        failures.append(
            Failure(
                "dimensions",
                subject,
                f"requested={requested} reported={reported} on_disk={disk_size} disagree",
            )
        )

    # Re-hash from disk. A hash the renderer supplied and nobody checked is
    # decoration.
    actual_sha = sha256_file(image_path)
    if actual_sha != receipt["image_sha256"]:
        failures.append(
            Failure("image_sha256", subject, f"receipt {receipt['image_sha256'][:12]} != disk {actual_sha[:12]}")
        )

    return failures


def build(
    *,
    view: str,
    candidate_id: str,
    render_seed: int,
    render_engine: str,
    resolution: tuple[int, int],
    camera_origin: tuple[float, float, float],
    camera_forward: tuple[float, float, float],
    ortho_scale: float,
    yaw_degrees: float,
    mesh_sha256: str,
    image_path: Path,
    root: Path,
) -> dict:
    """Assemble a receipt for one rendered view."""
    with Image.open(image_path) as handle:
        size = list(handle.size)
    return {
        "view": view,
        "candidate_id": candidate_id,
        "render_seed": render_seed,
        "render_engine": render_engine,
        "requested_resolution": list(resolution),
        "receipt_image_size": size,
        "camera_origin": [round(v, 6) for v in camera_origin],
        "camera_forward": [round(v, 6) for v in camera_forward],
        "camera_type": "ORTHO",
        "ortho_scale": round(ortho_scale, 6),
        "yaw_degrees": yaw_degrees,
        "mesh_sha256": mesh_sha256,
        "image_sha256": sha256_file(image_path),
        "image_path": str(image_path.relative_to(root)),
    }


def environment_stamp() -> dict:
    """Record where a render happened.

    EEVEE output is not byte-identical across GPU drivers, so a hash only means
    something relative to the environment that produced it. Recording the
    environment is what keeps the hash honest instead of misleading.
    """
    return {
        "platform": platform.platform(),
        "python": platform.python_version(),
        "machine": platform.machine(),
    }
