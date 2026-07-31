#!/usr/bin/env python3
"""Phase 1 gate: does the five-view turnaround describe ONE character?

Run:
    uv run --project cobie-collectible/tools \
        python cobie-collectible/scripts/validate_turnaround.py

Reads cobie-collectible/concepts/turnaround/{front,left,rear,right,hero}.png.

Why this exists
---------------
Multi-view image-to-3D generators are unforgiving about scale drift, vertical
misalignment and inconsistent framing between input views. When the inputs
disagree the generator resolves the contradiction by inventing geometry, which
is the PRD's top-ranked risk (identity drift) arriving through the back door.
That failure is invisible in the images, obvious in the mesh, and expensive
once a print has been paid for.

What this can and cannot check
------------------------------
Checked deterministically: framing geometry (height, width, centring, vertical
alignment, scale) and palette consistency. These are exactly the failures that
break generators, and they are the ones humans skim past.

NOT checked: whether the character is recognisably Cobie. No heuristic in this
file is a feature detector, and pretending otherwise would be worse than
useless. Identity remains a human gate -- see the checklist this prints.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _common import CONCEPTS, Failure, TURNAROUND_VIEWS, report, sha256_file, write_json

TURNAROUND_DIR = CONCEPTS / "turnaround"

# Tolerances, as fractions of image height unless noted.
MAX_HEIGHT_SPREAD = 0.04
MAX_VERTICAL_OFFSET = 0.03
MAX_CENTRE_OFFSET = 0.05
MIN_COVERAGE = 0.08
MAX_COVERAGE = 0.85
MAX_BACKGROUND_STD = 12.0
MAX_PALETTE_DRIFT = 0.12

# Identity palette from docs/PRD.md 15.1 and docs/ART_BIBLE.md, in RGB.
PALETTE = {
    "apricot_fur": (214, 158, 96),
    "leather_black": (28, 26, 28),
}
PALETTE_TOLERANCE = 78.0


def _load(path: Path) -> np.ndarray:
    with Image.open(path) as handle:
        return np.array(handle.convert("RGBA"), dtype=np.uint8)


def _foreground_mask(image: np.ndarray) -> np.ndarray:
    """Separate subject from background.

    Prefers a real alpha channel. Falls back to flood-tolerance against the
    median corner colour, which is what a plain-background render gives us.
    """
    alpha = image[..., 3]
    if alpha.min() < 250:
        return alpha > 127

    corners = np.concatenate(
        [
            image[:16, :16, :3].reshape(-1, 3),
            image[:16, -16:, :3].reshape(-1, 3),
            image[-16:, :16, :3].reshape(-1, 3),
            image[-16:, -16:, :3].reshape(-1, 3),
        ]
    ).astype(np.float64)
    background = np.median(corners, axis=0)
    distance = np.linalg.norm(image[..., :3].astype(np.float64) - background, axis=-1)
    return distance > 40.0


def _bbox(mask: np.ndarray) -> tuple[int, int, int, int] | None:
    rows = np.flatnonzero(mask.any(axis=1))
    cols = np.flatnonzero(mask.any(axis=0))
    if rows.size == 0 or cols.size == 0:
        return None
    return int(rows[0]), int(rows[-1]), int(cols[0]), int(cols[-1])


def _background_std(image: np.ndarray, mask: np.ndarray) -> float:
    background = image[..., :3][~mask]
    if background.size == 0:
        return 0.0
    return float(background.astype(np.float64).std(axis=0).mean())


def _palette_fractions(image: np.ndarray, mask: np.ndarray) -> dict[str, float]:
    subject = image[..., :3][mask].astype(np.float64)
    if subject.size == 0:
        return {name: 0.0 for name in PALETTE}
    fractions = {}
    for name, rgb in PALETTE.items():
        distance = np.linalg.norm(subject - np.array(rgb, dtype=np.float64), axis=-1)
        fractions[name] = float((distance < PALETTE_TOLERANCE).mean())
    return fractions


def analyse(path: Path) -> dict:
    image = _load(path)
    height, width = image.shape[:2]
    mask = _foreground_mask(image)
    box = _bbox(mask)
    if box is None:
        return {"empty": True, "path": str(path)}
    top, bottom, left, right = box
    return {
        "empty": False,
        "path": str(path),
        "image_size": [width, height],
        "coverage": float(mask.mean()),
        "subject_height": (bottom - top + 1) / height,
        "subject_width": (right - left + 1) / width,
        "top": top / height,
        "bottom": bottom / height,
        "centre_x": ((left + right) / 2.0) / width,
        "background_std": _background_std(image, mask),
        "palette": _palette_fractions(image, mask),
        "sha256": sha256_file(path),
    }


def validate(metrics: dict[str, dict]) -> list[Failure]:
    failures: list[Failure] = []

    for view, data in metrics.items():
        if data.get("empty"):
            failures.append(Failure("empty_view", view, "no subject detected against the background"))
            continue
        if not MIN_COVERAGE <= data["coverage"] <= MAX_COVERAGE:
            failures.append(
                Failure(
                    "coverage",
                    view,
                    f"subject fills {data['coverage']:.1%} of frame, outside "
                    f"{MIN_COVERAGE:.0%}-{MAX_COVERAGE:.0%}",
                )
            )
        if data["background_std"] > MAX_BACKGROUND_STD:
            failures.append(
                Failure(
                    "background",
                    view,
                    f"background std {data['background_std']:.1f} exceeds {MAX_BACKGROUND_STD}; "
                    "generators need a plain, uncluttered backdrop",
                )
            )
        if abs(data["centre_x"] - 0.5) > MAX_CENTRE_OFFSET:
            failures.append(
                Failure("centring", view, f"subject centre at x={data['centre_x']:.3f}, expected 0.5")
            )

    usable = {view: data for view, data in metrics.items() if not data.get("empty")}
    required_views = set(TURNAROUND_VIEWS)
    if len(usable) < len(required_views) or set(usable) != required_views:
        missing = sorted(required_views - set(usable))
        failures.append(
            Failure(
                "missing_views",
                ",".join(missing),
                "front, left, rear, right and neutral three-quarter hero are all required for multi-view generation",
            )
        )
        return failures

    # Cross-view consistency. This is the part that actually matters: all five
    # generator inputs must read as one object photographed from five angles.
    sizes = {view: tuple(data["image_size"]) for view, data in usable.items()}
    if len(set(sizes.values())) != 1:
        failures.append(
            Failure(
                "image_dimensions",
                "turnaround",
                "all geometry inputs must use identical pixel dimensions; "
                + ", ".join(f"{view}={size[0]}x{size[1]}" for view, size in sorted(sizes.items())),
            )
        )

    heights = {view: data["subject_height"] for view, data in usable.items()}
    spread = max(heights.values()) - min(heights.values())
    if spread > MAX_HEIGHT_SPREAD:
        tallest = max(heights, key=heights.get)
        shortest = min(heights, key=heights.get)
        failures.append(
            Failure(
                "scale_drift",
                f"{tallest} vs {shortest}",
                f"subject height differs by {spread:.1%} across views (max {MAX_HEIGHT_SPREAD:.0%}); "
                "the generator will read this as a shape change, not a scale change",
            )
        )

    for edge in ("top", "bottom"):
        values = {view: data[edge] for view, data in usable.items()}
        offset = max(values.values()) - min(values.values())
        if offset > MAX_VERTICAL_OFFSET:
            failures.append(
                Failure(
                    "vertical_alignment",
                    edge,
                    f"{edge} of subject varies by {offset:.1%} across views (max {MAX_VERTICAL_OFFSET:.0%}); "
                    "views must sit on a common baseline",
                )
            )

    for name in PALETTE:
        values = {view: data["palette"][name] for view, data in usable.items()}
        drift = max(values.values()) - min(values.values())
        if drift > MAX_PALETTE_DRIFT:
            failures.append(
                Failure(
                    "palette_drift",
                    name,
                    f"{name} covers between {min(values.values()):.1%} and {max(values.values()):.1%} "
                    f"of the subject across views (max spread {MAX_PALETTE_DRIFT:.0%}); "
                    "lighting or costume is changing between views",
                )
            )

    return failures


HUMAN_CHECKLIST = """
Automated checks cannot judge identity. Before proceeding to Phase 2, confirm
by eye on every view:
  [ ] All five views show the identical neutral A-pose with empty paws.
  [ ] No turnaround view contains the Fetch Launcher or another handheld prop.
  [ ] Aviators have the same shape and gold/brass frame wherever visible.
  [ ] COBIE tag placement is consistent; front/hero show it at the sternum.
  [ ] Black leather jacket, open, same lapel geometry, chest ruff showing.
  [ ] Apricot curly coat matching the canonical hero render's sculpted clumps.
  [ ] Side and rear views show the ear flaps as DISTINCT hanging volumes,
      separated from the skull curls -- not a bob of crown fur. This is the
      known failure mode; reject on it without hesitation.
  [ ] Tail present and consistent in both profiles and the rear view
      (relaxed upward curve, curl plume, below the jacket hem).
  [ ] Black nose, short blunt muzzle.
  [ ] The REAR view is genuinely a rear view, not a mirrored front -- no
      glasses, no facial features visible.
  [ ] No view contradicts another about what is behind or beneath Cobie.
Reject and regenerate now. Every later gate costs more than this one.
"""


def main() -> int:
    if not TURNAROUND_DIR.is_dir():
        print(f"  FAIL [missing_input] {TURNAROUND_DIR}: directory does not exist")
        print("  Generate the turnaround first; see cobie-collectible/references/turnaround-prompts.md")
        print("COBIE_TURNAROUND_VALIDATE: FAIL (no input)")
        return 1

    metrics: dict[str, dict] = {}
    for view in TURNAROUND_VIEWS:
        path = TURNAROUND_DIR / f"{view}.png"
        if path.is_file():
            metrics[view] = analyse(path)

    if not metrics:
        print(f"  FAIL [missing_input] {TURNAROUND_DIR}: no view images found")
        print("COBIE_TURNAROUND_VALIDATE: FAIL (no input)")
        return 1

    failures = validate(metrics)
    write_json(TURNAROUND_DIR / "turnaround_report.json", {"metrics": metrics, "failures": [f.as_dict() for f in failures]})
    code = report("COBIE_TURNAROUND_VALIDATE", failures, {"views": sorted(metrics)})
    if code == 0:
        print(HUMAN_CHECKLIST)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
