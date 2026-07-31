# Cobie Nukem — physical collectible

A 140 mm static resin display figurine of Cobie, produced by an
image-to-3D → Blender → STL pipeline.

Governing document: `Cobie_Nukem_AI_Physical_Collectible_PRD.docx`.
Character freeze: `references/character-brief/cobie_figurine_v1.yaml`.

## Source-of-truth hierarchy

```
blender/cobie_figurine_v1_reviewed.blend <- supervised selected-mesh source, once created
blender/cobie_figurine_v1.blend          <- source for the last successful build
  ^ built by
scripts/*.py                             <- version controlled, reviewable, deterministic
  v produces
exports/build_report.json                <- binds workflow mode, selected source, blend + five exports
validation renders + print reports       <- downstream, hash-matched evidence
  v derived
exports/*.stl                            <- disposable, regenerable
MCP conversation                         <- exploration only, never the sole record
```

## Setup

```bash
uv sync --project cobie-collectible/tools --python 3.13 --locked
```

Python **3.13** is required: `bpy` 5.2.0 publishes cp313 wheels only. This is
the one place in the repo that needs a newer interpreter than
`tools/visual_quality` (>=3.11). `tools/uv.lock` is authoritative;
`--locked` fails instead of silently changing it when the declared dependencies
and lockfile disagree.

On Linux, Blender and pymeshlab additionally need system GL libraries that are
not installed by default:

```bash
apt-get install -y libegl1 libgl1-mesa-dri libopengl0 libxkbcommon0
```

Without `libegl1` every render fails with `Couldn't open libEGL.so.1`; without
`libopengl0` pymeshlab loads no format plugins and reports "Unknown format for
load: stl". On macOS neither is needed.

## Pipeline

| Phase | Command | Gate |
|---|---|---|
| 0 Character freeze | — | `references/character-brief/cobie_figurine_v1.yaml` approved, photo pack shot |
| 1 Turnaround | `scripts/validate_turnaround.py` | `COBIE_TURNAROUND_VALIDATE: PASS` |
| 2 Mesh bakeoff | `scripts/bakeoff_render.py` | `COBIE_BAKEOFF_RENDER: PASS` + scored scorecard |
| 3 Digital V1 | `scripts/build_figurine.py`, `scripts/print_check.py`, `scripts/slicer_import_check.py` | successful build receipt, print and slicer gates PASS, and valid vendor quotes received |
| 4 Prototype | outsourced resin print | defects localised, not "restart the character" |
| 5 Finished | prime, paint, clear coat | PRD 11.3 acceptance criteria |

All commands run as:

```bash
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/<script>.py
```

Image-to-3D generation happens in a **browser**, not here. Download the GLBs
into `generated-meshes/`. Nothing in this pipeline calls an external asset
service, which keeps `docs/design/agentic-toolchain.md`'s "external asset
services disabled" rule intact. Inputs differ per generator:

| Generator | Input | Give it |
|---|---|---|
| Hunyuan3D 2.1/3.x multi-view (primary) | up to 4 views | `concepts/turnaround/{front,left,rear,right}.png` |
| TRELLIS.2 | single image only | the canonical hero render / `hero.png` |
| Stable Fast 3D | single image | `hero.png` |

TRELLIS.2's O-Voxel output is deliberately open-surface / non-manifold (a
game-engine feature, a resin defect); its docs ship hole-filling scripts for
3D-printing use. Expect its candidate to need more cleanup, not less.

## Tests

```bash
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/tests/test_collectible.py
```

43 tests, about two seconds; they do not import `bpy`. They are **not** wired
into `tools/release_validate.sh`, which invokes its Python tests with bare
`python3` — these need numpy, trimesh and scipy, so adding them there would
break CI for reasons unrelated to the figurine.

## What is and is not committed

The repository has no Git LFS, so large or regenerable artefacts are tracked by
SHA-256 rather than by content. See `.gitignore` for the reasoning per path.

One consequence to plan for: the proxy `.blend` is excluded because it is
reproducible from `scripts/build_figurine.py`. **A hand-sculpted `.blend` is
not reproducible and must be committed** — at that point this repository will
need Git LFS.

## Provisional digital prototype

With no `generated-meshes/selected.glb`, `build_figurine.py` builds a
script-authored **provisional digital prototype** grounded in the project's
game art and current character brief. It now carries the recognisable curl/ear mass,
aviators, muzzle, open jacket, chest ruff and tag, two-hand Fetch Launcher pose,
tail, rounded paws, and asymmetric assembly keys. It is still not approved for
manufacture: the owner identity approval, photo pack, turnaround, candidate
bakeoff, and physical fit test remain open.

If `selected.glb` exists, the script imports it into the review `.blend` but
fails closed before STL export. A generated shell must be separated, posed, and
keyed under supervision. The last published STLs are retained for recovery, but
the build receipt becomes non-PASS immediately, so print, render, comparison,
and slicer validation reject them as stale. A later run publishes the exact
five reviewed parts transactionally.

Current provisional results: 140.541 mm tall, 69.94 mm base, 5.008 mm plate,
centre of mass 5.98% off the base centre (limit 35%). All five canonical parts
are watertight single solids, pass executed thickness checks, and independently
import in PrusaSlicer 2.9.6 as one manifold part each. Nine exported mating
interfaces have complete radial engagement coverage, no sampled collision, and
p05–p95 gaps of 0.225–0.346 mm against the 0.20–0.35 mm contract. Exact
Manifold boolean intersections across all ten unordered part pairs are
0 mm³. This is digital engineering evidence, not a physical fit claim.

Review evidence lives in `validation-renders/prototype-v1/`; the inherited
block proxy is preserved in `validation-renders/proxy-baseline/` for the
before/candidate/difference packet.

## Notes on the checks

`print_check.py` replaces Blender's 3D Print Toolbox, which is not shipped in
the `bpy` PyPI wheel. That turned out better: these checks run headless, fail
with specific numbers, and are unit-tested against controls.

Every downstream gate first verifies `exports/build_report.json`: it must be a
PASS from the current pipeline version, name exactly five canonical STLs, and
match every export plus the Blender source by SHA-256. Its mode and selected
candidate hash must also match whether `generated-meshes/selected.glb` is
present. Each report is first invalidated as incomplete, so an exception or
interrupted rerun cannot leave old green evidence looking current.

PyMeshLab 2025.7 can import on Apple Silicon while auto-loading zero plugins.
The validator explicitly loads its bundled STL and meshing plugins when needed,
then fails loudly if decimation is still unavailable. It never converts a
missing measurement into a pass.

Thickness deserves a note. The raw inscribed-sphere measurement is dominated by
sharp convex edges, where the sphere is genuinely tiny even though there is
thick material immediately behind — on the sunglasses that artefact reports 34%
of the surface as thin when the true wall is a uniform 1.6 mm. The measurement
therefore takes the maximum over each sample's nearest neighbours: a genuinely
thin wall has thin neighbours, an edge does not. A 0.6 mm control plate is in
the test suite to prove the check still fails what it should.
