# Cobie Nukem — physical collectible

A 140 mm static resin display figurine of Cobie, produced by an
image-to-3D → Blender → STL pipeline.

Governing document: `Cobie_Nukem_AI_Physical_Collectible_PRD.docx`.
Character freeze: `references/character-brief/cobie_figurine_v1.yaml`.

## Source-of-truth hierarchy

```
blender/cobie_figurine_v1.blend    <- authoritative once it contains sculpting
  ^ built by
scripts/*.py                       <- version controlled, reviewable, deterministic
  v produces
validation renders + print reports <- evidence
  v derived
exports/*.stl                      <- disposable, regenerable
MCP conversation                   <- exploration only, never the sole record
```

## Setup

```bash
uv venv --python 3.13 cobie-collectible/tools/.venv
uv pip install --python cobie-collectible/tools/.venv/bin/python \
  bpy==5.2.0 trimesh==4.12.2 pymeshlab==2025.7.post1 \
  numpy==2.5.1 pillow==12.3.0 scipy==1.16.3 rtree==1.4.1
```

Python **3.13** is required: `bpy` 5.2.0 publishes cp313 wheels only. This is
the one place in the repo that needs a newer interpreter than
`tools/visual_quality` (>=3.11).

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
| 3 Digital V1 | `scripts/build_figurine.py` then `scripts/print_check.py` | `COBIE_FIGURINE_PRINT_CHECK: PASS` + slicer import |
| 4 Prototype | outsourced resin print | defects localised, not "restart the character" |
| 5 Finished | prime, paint, clear coat | PRD 11.3 acceptance criteria |

All commands run as:

```bash
uv run --project cobie-collectible/tools python cobie-collectible/scripts/<script>.py
```

Image-to-3D generation happens in a **browser**, not here — Hunyuan3D 2.1
multi-view, TRELLIS, Stable Fast 3D. Download the GLBs into `generated-meshes/`.
Nothing in this pipeline calls an external asset service, which keeps
`docs/design/agentic-toolchain.md`'s "external asset services disabled" rule
intact.

## Tests

```bash
uv run --project cobie-collectible/tools python cobie-collectible/tests/test_collectible.py
```

16 tests, about two seconds; they do not import `bpy`. They are **not** wired
into `tools/release_validate.sh`, which invokes its Python tests with bare
`python3` — these need numpy, trimesh and scipy, so adding them there would
break CI for reasons unrelated to the figurine.

## What is and is not committed

The repository has no Git LFS and `.git` is already ~97 MB, so large or
regenerable artefacts are tracked by SHA-256 rather than by content. See
`.gitignore` for the reasoning per path.

One consequence to plan for: the proxy `.blend` is excluded because it is
reproducible from `scripts/build_figurine.py`. **A hand-sculpted `.blend` is
not reproducible and must be committed** — at that point this repository will
need Git LFS.

## Proxy mode

With no `generated-meshes/selected.glb`, `build_figurine.py` builds a
proportioned **proxy** from primitives following the frozen brief. The proxy is
not the deliverable and will not be printed. It exists so the print rules, base
keying, balance maths, export and validation are exercised and testable before
any generated mesh arrives, rather than discovering the pipeline is broken at
the moment a real candidate lands.

Current proxy results: 140.9 mm tall, 70 mm base, 5.0 mm plate, centre of mass
7.2% off the base centre (limit 35%), all five parts watertight and single-body.

## Notes on the checks

`print_check.py` replaces Blender's 3D Print Toolbox, which is not shipped in
the `bpy` PyPI wheel. That turned out better: these checks run headless, fail
with specific numbers, and are unit-tested against controls.

Thickness deserves a note. The raw inscribed-sphere measurement is dominated by
sharp convex edges, where the sphere is genuinely tiny even though there is
thick material immediately behind — on the sunglasses that artefact reports 34%
of the surface as thin when the true wall is a uniform 1.6 mm. The measurement
therefore takes the maximum over each sample's nearest neighbours: a genuinely
thin wall has thin neighbours, an edge does not. A 0.6 mm control plate is in
the test suite to prove the check still fails what it should.
