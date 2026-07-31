# Cobie Nukem — physical collectible

A 140 mm static resin display figurine of Cobie, produced by an
image-to-3D → Blender → STL pipeline.

Governing document: `Cobie_Nukem_AI_Physical_Collectible_PRD.docx`.
Character freeze: `references/character-brief/cobie_figurine_v1.yaml`.

## Source-of-truth hierarchy

```
blender/cobie_figurine_v2_master.blend  <- current cover-refinement master (Git LFS)
  ^ built by
scripts/build_figurine_v2.py            <- deterministic authored geometry and stage contract
  v produces
exports/build_report.json               <- binds generator, master, stage + five exports
validation renders + print reports      <- downstream, hash-matched evidence
  v derived
exports/*.stl                           <- disposable, regenerable

blender/cobie_figurine_v1_reviewed.blend <- future supervised identity source, once created
blender/cobie_figurine_v1.blend          <- local/regenerable pre-gate prototype
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

49 tests, about two seconds; they do not import `bpy`. They are **not** wired
into `tools/release_validate.sh`, which invokes its Python tests with bare
`python3` — these need numpy, trimesh and scipy, so adding them there would
break CI for reasons unrelated to the figurine.

## What is and is not committed

Git LFS is enabled for `cobie-collectible/blender/*.blend` and
`cobie-collectible/generated-meshes/selected.glb`. The V2 master is committed
through LFS; derived STLs remain gitignored and are bound to their generator
and master by SHA-256 in the build receipt. The selected identity GLB and
future supervised review blend must also be committed through LFS before
irreplaceable manual work begins.

## Cover-driven V2 refinement

The current branch contains a seven-iteration, checkpointed refinement of the
pre-gate figure toward the selected game-cover direction. The primary
geometry/pose reference is `assets/brand/cobie_nukem_cover.png`; the dual-
blaster cover in `references/game-art/` is secondary material and hard-surface
reference only. Its second blaster, open mouth/tongue, and background are
explicitly excluded.

The cumulative Blender stages are `silhouette`, `head`, `costume`, `launcher`,
and `final`. Each run rebuilds the master, validates its collection and
five-part contracts, exports and checks the print geometry, imports it through
PrusaSlicer, renders neutral and colour evidence, and scores an explicit
rating packet:

```bash
COBIE_ITERATION_ID=I07 COBIE_V2_STAGE=final \
  bash cobie-collectible/scripts/run_refinement_iteration.sh

COBIE_ITERATION_ID=I07 \
  uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/score_refinement.py
```

Set `BLENDER_BIN` when Blender is neither the standard macOS app bundle nor
available as `blender` on `PATH`.

Iteration I07 is the current **provisional** checkpoint at **81/100** on an
independent recalibrated scale. It improves the same reviewer's I06 baseline
from 66, but does not meet the 85-point/every-category-at-least-4 target:
head-and-fur identity remains 3/5. I07 rebuilds the projecting snout, drop ears,
crown locks and jacket hierarchy; exposes the tag and surface-derived seams;
and fixes three buried/material-assignment defects. The neutral packet is
rendered from `PRINT_EXPORT`; the colour packet is rendered from `LOOKDEV`.

Current I07 engineering results: 139.725 mm tall, 69.945 mm base, 5.000 mm
plate, and centre of mass 8.41% off the base centre (limit 35%). All five
canonical parts are watertight single solids and pass the executed thickness
checks. All nine mating-interface probes have complete radial engagement and
no sampled collision; their p05–p95 gaps span 0.232–0.336 mm. Exact Manifold
boolean intersections are 0 mm³ across all ten unordered part pairs, and
PrusaSlicer 2.9.6 reports every STL as one manifold part.

The current evidence is in `validation-renders/cover-v2/I07-neutral/` and
`validation-renders/cover-v2/I07-lookdev/`; the score and full iteration trail
are in `refinement/cover-v2/`. These are digital geometry and look-development
results. The earlier I06 review is retained as historical evidence but is
superseded as the current acceptance claim. Identity approval, the real-Cobie
photo pack, a physical prototype, and manufacture approval all remain false.

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
