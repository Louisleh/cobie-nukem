# Cobie Nukem physical collectible — handoff

**Written:** 2026-07-29; updated after the cover-refinement loop
**Working branch:** `codex/cobie-cover-refinement`, stacked on the baseline
checkpoint from `claude/cobie-nukem-phase12-pass-igt54i`
**Working PR:** [Louisleh/cobie-nukem#66](https://github.com/Louisleh/cobie-nukem/pull/66) (draft)
**Upstream baseline PR:** [Louisleh/cobie-nukem#65](https://github.com/Louisleh/cobie-nukem/pull/65) (draft)
**Repo:** `Louisleh/cobie-nukem`
**Audience:** Codex, or any agent picking this up cold.

Read this file, then `README.md`, then
`references/character-brief/cobie_figurine_v1.yaml`. That is enough to continue
without re-deriving anything.

---

## 2026-07-29 cover-refinement checkpoint

The cover-driven pre-gate refinement is complete at iteration **I06**. Its
reviewer-authored visual ratings produce **85/100**, with every category at
least 4/5; the scorer machine-validates their provenance, completeness, and
math. The accepted figure now has the primary cover's wide asymmetric stance and closed
expression, printable layered fur, constructed black leather jacket, warm-
metal aviators, collar tag, and one black/gold/cyan Fetch Launcher with a
visible tennis-ball chamber.

The canonical master is
`blender/cobie_figurine_v2_master.blend`, committed through Git LFS and
rebuildable from `scripts/build_figurine_v2.py`. Its exact top-level
collections are `REFERENCE`, `SCULPT_SOURCE`, `LOOKDEV`, `PRINT_EXPORT`, and
`REVIEW_RIG`. `PRINT_EXPORT` contains exactly the five canonical removable
parts. The master validator rejects collection drift, embedded image
datablocks, unapproved flags, missing semantic material zones, and stale
provenance.

Accepted evidence:

- `validation-renders/cover-v2/I06-neutral/` — five neutral views rendered
  only from `PRINT_EXPORT`, plus comparison evidence.
- `validation-renders/cover-v2/I06-lookdev/` — locked-colour views,
  silhouettes, material ID, close-ups, portrait, palette, and review board.
- `refinement/cover-v2/ratings/I06_report.json` — scorecard and target gate.
- `exports/print_check_report.json` and
  `slicer-tests/prusaslicer_import_report.json` — current geometry and
  independent parser gates.

Current engineering evidence: 139.747 mm overall height, 69.945 mm base,
5.000 mm base plate, 7.70% balance-margin ratio, complete coverage with no
sampled collision at all nine joint probes, 0.232–0.336 mm p05–p95 interface
gaps, and 0 mm³ exact intersection across all ten unordered part pairs. All
five STLs are watertight single solids and PrusaSlicer 2.9.6 reports one
manifold part for each.

Reproduce the accepted iteration with:

```bash
COBIE_ITERATION_ID=I06 COBIE_V2_STAGE=final \
  bash cobie-collectible/scripts/run_refinement_iteration.sh

COBIE_ITERATION_ID=I06 \
  uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/score_refinement.py
```

This checkpoint does **not** clear the human or physical gates:
`identity_approved`, `physical_validation_complete`, and manufacture approval
remain false. No image-to-3D identity generation has been run and nothing has
been printed. The real-Cobie photo pack and owner identity approval are still
required before this can become Digital V1.

---

## 1. What this is

A sub-project that turns Cobie from 2D reference art into a **140 mm static
resin display figurine**, printed by an outsourced service and hand-painted.

Governing document: `Cobie_Nukem_AI_Physical_Collectible_PRD.docx` (owner's
file, not in the repo). Its three governing decisions, which the code follows:

1. **Image-to-3D, not text-to-CAD.**
2. **Blender is the production environment and source of truth, not the
   creative start.**
3. **Open-source does not mean local execution.** The strong generators want
   NVIDIA VRAM a 16 GB M4 Mac mini does not have.

V1 is deliberately narrow: one static pose, neutral grey resin, separate keyed
base, parts split for printing. **No articulation, no bobble mechanism, no
photoreal fur, no full-colour printing, no second pose** until a physical print
is validated.

---

## 2. Current state — what is done and what is not

| Phase | State | Evidence |
|---|---|---|
| 0 Character freeze | **Written, awaiting owner approval + photos** | `references/character-brief/cobie_figurine_v1.yaml` |
| 1 Turnaround | **Tooling done, no images yet** | `scripts/validate_turnaround.py`, `references/turnaround-prompts.md` |
| 2 Mesh bakeoff | **Tooling implemented and locally tested; no real candidates or retained bakeoff packet** | `scripts/bakeoff_render.py` |
| Pre-gate engineering prototype | **Built; local print and slicer checks green** | `validation-renders/prototype-v1/`, `exports/print_check_report.json`, `slicer-tests/prusaslicer_import_report.json` |
| Cover-driven pre-gate refinement | **I06 accepted at 85/100; all refinement engineering/evidence gates green** | `validation-renders/cover-v2/I06-neutral/`, `validation-renders/cover-v2/I06-lookdev/`, `refinement/cover-v2/ratings/I06_report.json` |
| 3 Digital V1 | **Not started; Phases 0–2 have not cleared** | No selected identity mesh, clean production `.blend`, quotes, or Phase 3 exit |
| 4 Resin prototype | Not started | — |
| 5 Finished collectible | Not started | — |

**Nothing has been printed. No image-to-3D identity generation has been run.
No photographs exist yet.** The script-authored V2 model is an accepted
cover-fidelity and assembly prototype, not an identity-approved Digital V1. It
advances pose, print engineering, material hierarchy, game-art fidelity, and
review evidence without pretending to satisfy the still-open owner and photo
gates.

### The two hard blockers, both owner-side

1. **Approve or amend the character freeze.** Pose, expression, head ratio,
   clothing, aviators, collar/tag, hero prop, base treatment, palette, realism,
   and exaggeration must stop moving before identity generation.
2. **Photographs of the real Cobie.** 18–24 frames. Shot list is in the brief
   under `photo_shot_list`. Nothing in Phase 1 can start without them.

Turnaround generation is the first downstream action after those owner gates.
The prompts are ready in `references/turnaround-prompts.md`.

---

## 3. Every file, and why it exists

```
cobie-collectible/
├── HANDOFF.md                      ← this file
├── README.md                       setup, pipeline table, what is/isn't committed
├── .gdignore                       MANDATORY. Keeps Godot from importing this tree.
├── .gitignore                      why each large/derived path is excluded
│
├── references/
│   ├── character-brief/
│   │   ├── cobie_figurine_v1.yaml  THE FREEZE. Identity, pose, print rules, photo shot list.
│   │   └── cobie_figurine_v1_digital_prototype.yaml
│   │                                  explicit provisional scope and open human gates
│   ├── turnaround-prompts.md       verbatim ImageGen prompts for the 5 views
│   ├── photos/                     (empty, gitignored) owner's photo pack goes here
│   └── game-art/                   secondary cover reference + provenance README
│
├── scripts/
│   ├── _common.py                  paths, print constants, scale contract, seeds, Failure/report
│   ├── receipt.py                  render provenance: re-derives pose, re-hashes images
│   ├── validate_turnaround.py      PHASE 1 GATE
│   ├── bakeoff_render.py           PHASE 2: clay renders + distinctness
│   ├── build_figurine.py           PHASE 3: geometry, parts, base, STL export
│   ├── build_figurine_v2.py        cumulative cover-refinement geometry stages
│   ├── print_check.py              PHASE 3 GATE: manifold/thickness/balance
│   ├── slicer_import_check.py      independent PrusaSlicer import gate
│   ├── render_figurine.py          deterministic five-view review packet
│   ├── render_figurine_lookdev.py  deterministic colour/material evidence
│   ├── run_refinement_iteration.sh complete per-iteration gate runner
│   ├── score_refinement.py         scorecard, provenance and target gate
│   ├── validate_refinement_master.py
│   │                                  V2 collection/part/material/flag contract
│   └── compare_figurine_renders.py before/candidate/difference evidence
│
├── tests/
│   └── test_collectible.py         49 tests, ~2s, no bpy import
│
├── tools/
│   ├── pyproject.toml              pinned deps, requires-python >=3.13
│   └── uv.lock                     authoritative cross-platform dependency lock
│
├── blender/
│   └── cobie_figurine_v2_master.blend
│                                      Git-LFS cover-refinement master
├── generated-meshes/               downloaded candidates; selected.glb uses LFS
├── exports/                        build_report.json + print report + gitignored STLs
├── concepts/turnaround/            (gitignored) the 5 generated views
├── refinement/cover-v2/            art brief, scorecard, ratings, iteration log
├── validation-renders/             committed neutral + lookdev review evidence
├── slicer-tests/                   committed PrusaSlicer evidence
└── print-quotes/                   empty; valid quotes are a Phase 3 exit gate
```

Also changed outside this directory:
- `docs/DECISIONS.md` — added **D-020** recording the four binding decisions.
- `.github/workflows/ci.yml` — added a Pillow/numpy install step (see §7).

---

## 4. Environment — verified, not assumed

This matters because the plan originally assumed almost none of it was
possible here. I measured each one.

| Capability | Result |
|---|---|
| Native Blender 5.2.0 LTS | ✅ `/Applications/Blender.app`, matches the locked `bpy` runtime |
| `bpy` 5.2.0 LTS headless | ✅ **requires CPython 3.13** — cp313 wheels only |
| Mesh ops, voxel remesh, STL export | ✅ |
| EEVEE render | ✅ **only after** installing GL libs (below) |
| trimesh / Manifold3D / pymeshlab / scipy / rtree | ✅ |
| **Cycles** | ❌ absent from the pip wheel — EEVEE only |
| **Blender 3D Print Toolbox** | ❌ absent — reimplemented in `print_check.py` |
| **3MF export** | ❌ absent — STL only |
| PrusaSlicer 2.9.6 independent import | ✅ all five canonical STLs |
| Apple Silicon render | ✅ five 640 px views plus sheet in ~8 s |

Required system packages on Linux (not needed on macOS):

```bash
apt-get install -y libegl1 libgl1-mesa-dri libopengl0 libxkbcommon0
```

Without `libegl1`, every render dies with `Couldn't open libEGL.so.1`.
Without `libopengl0`, pymeshlab silently loads **zero** format plugins and then
reports the misleading `Unknown format for load: stl`.

Setup from the authoritative lock:

```bash
uv sync --project cobie-collectible/tools --python 3.13 --locked
brew install --cask prusaslicer
```

Run anything as:

```bash
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/<script>.py
```

---

## 5. Binding decisions (docs/DECISIONS.md D-020)

**Change these only deliberately — code depends on each.**

1. **1 Blender unit = 1 millimetre**, departing from the game's 1 unit = 1 m.
   STL carries no units and every print service reads a unit as a millimetre.
   Stamped into the `.blend` as `scale_contract`. See `_common.py`.
2. **Generation never goes through an MCP.** Image-to-3D runs as hosted browser
   demos; GLBs arrive as files. This preserves
   `docs/design/agentic-toolchain.md`'s rule that Poly Haven / Sketchfab /
   Hyper3D / **Hunyuan** stay disabled in the Blender MCP. BlenderMCP is
   optional, local, scoped to `cobie-collectible/`, and scripts stay
   authoritative.
3. **Python 3.13 for this sub-project only.** `tools/visual_quality` stays ≥3.11.
4. **Collectible tests are NOT in `tools/release_validate.sh`.** That script runs
   its Python tests under bare `python3`; these need numpy/trimesh/scipy.

---

## 6. How each script works, and the non-obvious parts

### `validate_turnaround.py` — the gate that decides the project

Checks the five view images for **framing geometry**: subject height spread
across all five geometry inputs, vertical alignment of top and bottom edges,
horizontal centring, foreground coverage, background uniformity, and palette
drift. The neutral three-quarter `hero.png` is mandatory, not a loose mood
image.

Every canonical view is prop-free and uses the same neutral A-pose. The final
two-hand launcher composition is generated separately as a Blender posing
reference and never fed into the identity-mesh multi-view set.

It is explicit that it **cannot judge identity**, and prints a human checklist
instead of pretending a heuristic is a feature detector. Do not "improve" it by
adding a fake aviator detector.

Why it matters more than anything downstream: multi-view generators resolve
disagreement between input views by *inventing geometry*. A front view framed
4% larger than the side view reads as a shape change, not a scale change. That
failure is invisible in the images, obvious in the mesh, and expensive after a
print. **The rear view is where this usually fails** — generators are biased
toward faces and will hand back a mirrored front.

### `receipt.py` — provenance

Modelled on `tools/visual_quality/capture_tool.py`. The renderer's self-report
is never trusted: camera origin is re-derived from yaw, aim is re-checked by dot
product, three independent dimension sources must agree, and the image is
re-hashed from disk. The field set is **exact** — extra or missing keys are a
hard failure, because silent schema drift is how provenance stops meaning
anything.

### `bakeoff_render.py` — Phase 2

Renders every `generated-meshes/*.glb` from five identical ortho cameras under
one neutral clay material, normalising each candidate to the same height first.

**Texture is deliberately not rendered and not scored** (PRD §8.2): V1 prints in
neutral resin, and a convincing texture hides unmanufacturable geometry.

The **distinctness gate** refuses a bakeoff where two candidates are the same
mesh under different filenames — it requires the silhouette IoU to exceed the
threshold from *every* view before flagging, since two different characters can
share a front silhouette.

### `build_figurine.py` — Phase 3

Two fail-safe modes. With `generated-meshes/selected.glb` it imports and
normalises the shell into `blender/cobie_figurine_v1_reviewed.blend` and exits
**FAIL** until Body, Head, Sunglasses, Fetch Launcher, and Base have genuinely
been separated, posed, and keyed. Existing STLs are retained for recovery, but
the non-PASS build receipt makes every downstream gate reject them. A reviewed
five-part rerun stages all exports, marks the receipt BUILDING before touching
the source or published set, and rolls the old set back if publication fails.
Without a selected mesh, the script builds the game-art-grounded **provisional
digital prototype** now shown in `validation-renders/prototype-v1/`.

The prototype is **not identity-approved and will not be printed yet.** It
exists to advance silhouette and assembly engineering while the owner/photo
gates remain open. Compared with the inherited block proxy it adds the
continuous curled ear/crown mass, differentiated muzzle and beard, aviators,
open-jacket/chest-ruff silhouette, COBIE tag relief, planted paws, tail,
two-hand launcher pose, asymmetric base keys, dual head keys, and separate
glasses/launcher pins.

Non-obvious: `join_and_solidify()` applies transforms on every primitive
*before* joining. Skipping that bakes the others into the active object's
anisotropically-scaled local space and the voxel remesh then produces garbage.
`remesh()` also dissolves degenerate faces — voxel remesh emits zero-area
triangles whose edges touch three faces, making the mesh non-manifold while
reporting zero holes.

### `print_check.py` — Phase 3 gate

Replaces the absent 3D Print Toolbox: watertight, winding, degenerate faces,
floating shells, triangle count, wall thickness, base diameter/thickness, and a
**centre-of-mass-over-footprint balance test** for FR-4 "stands unaided". It
also measures complete angular rings through the declared engagement band of
all nine keyed interfaces, gates their p05–p95 exported clearances, and queries
exact Manifold boolean intersections across all ten unordered part pairs.

Five things to understand before touching it:

- **`plate_thickness()` exists because the bounding box lies.** The keying peg
  protrudes above the plate, so bbox height reported 10.5 mm for a 5 mm plate.
  It now measures only the z-band where the cross-section is most of the full
  footprint.
- **Thickness uses a neighbourhood maximum, not the raw value.** The raw
  inscribed-sphere measurement is dominated by sharp convex edges, where the
  sphere is genuinely tiny even though thick material sits immediately behind.
  It reported **34% of the sunglasses as thin when the wall is a uniform
  1.6 mm**. Taking the max over each sample's nearest neighbours fixes it: a
  genuinely thin wall has thin neighbours, an edge does not. A **0.6 mm control
  plate** in the test suite proves the check still fails what it should — keep
  that test.
- **`measure_thickness` deliberately does not catch exceptions.** An earlier
  version did, returned empty, and `print_check` reported PASS on a check that
  never ran. Do not re-add the try/except.
- **Apple Silicon PyMeshLab plugin loading is explicit.** The 2025.7 wheel can
  import while loading zero plugins. `_ensure_pymeshlab_plugins()` loads the
  wheel-bundled STL and meshing plugins, then fails loudly if the required
  decimator is still unavailable.
- **Assembly overlap is an exact all-pairs boolean.** The earlier 1,200-point
  surface sampler could miss a 0.4 mm corner intrusion. The gate now AABB-culls
  obvious misses, checks every remaining pair with pinned Manifold3D, and fails
  loudly if a closed-volume intersection cannot be measured.

### `slicer_import_check.py` — independent Phase 3 parser gate

Runs PrusaSlicer's own `--info` parser against exactly the five canonical
exports and records its version, STL hashes, dimensions, facets, manifold
status, and connected-part count. It does not claim vendor-specific supports,
hollowing, drain placement, or a successful physical print.

`build_figurine.py`, `print_check.py`, `slicer_import_check.py`, and
`render_figurine.py` share one fail-closed receipt chain. A successful build
receipt binds the current Blender source and exact five STL hashes. Validators
atomically replace their reports with an incomplete marker before doing work,
then publish PASS only after all current hashes and checks agree.

---

## 7. CI status — read this before debugging

**The upstream PR #65 baseline is green as of this update.** PR #66 contains
the V2 refinement and must be green at its final pushed commit before this
handoff is treated as published. The earlier upstream failure was pre-existing
and unrelated to the collectible:

```
ModuleNotFoundError: No module named 'PIL'
  tools/visual_quality/test_capture_tool.py — 5 tests error
```

Proof it is not from this change:
- `git diff --stat main..HEAD -- tools/ .github/` was **empty** at the time of
  the failing run — the diff touched neither.
- `.github/workflows/ci.yml` installed **no Python packages at all**, so that
  test has never had Pillow available on CI.
- `tools/release_validate.sh:67` invokes it with bare `python3`.

**Fix applied on the upstream branch:** a step in `ci.yml` installing
`pillow==10.4.0` and `numpy==2.1.2` (versions matched to
`tools/visual_quality/pyproject.toml`) before validation, plus a recorded
version stamp. If a future run is red, re-verify the failing subject before
assuming it is the collectible code.

Separately, there is a known **non-deterministic ObjectDB leak** in
`tests/unit/mission_presentation_test.gd`. It predates this work and was
reproduced as flaky earlier in the project (5 clean local runs). If CI fails
there, re-run before investigating.

---

## 8. Verification — what has actually been proven

Everything below was run, not assumed.

```bash
# 49 tests, ~2s, no bpy
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/tests/test_collectible.py

# builds provisional prototype, exports 5 canonical STLs
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/build_figurine.py
# -> COBIE_FIGURINE_BUILD: PASS

# executes manifold, topology, thickness, inventory and balance gates
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/print_check.py
# -> COBIE_FIGURINE_PRINT_CHECK: PASS

# independent third-party parser gate
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/slicer_import_check.py
# -> COBIE_FIGURINE_SLICER_IMPORT: PASS

# five-view neutral-resin packet and before/candidate/difference review
COBIE_RENDER_ID=prototype-v1 uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/render_figurine.py
uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/compare_figurine_renders.py

# complete accepted cover-refinement rebuild and evidence loop
COBIE_ITERATION_ID=I06 COBIE_V2_STAGE=final \
  bash cobie-collectible/scripts/run_refinement_iteration.sh

# verifies the master independently and scores its bound evidence
/Applications/Blender.app/Contents/MacOS/Blender --background \
  --python cobie-collectible/scripts/validate_refinement_master.py
COBIE_ITERATION_ID=I06 \
  uv run --project cobie-collectible/tools --locked \
  python cobie-collectible/scripts/score_refinement.py
```

**Provisional prototype results:** 140.541 mm tall, 69.94 mm base, 5.008 mm
plate, centre of mass 5.98% off centre against a 35% limit. All five parts are
watertight single bodies, executed thickness checks pass, and PrusaSlicer
reports each as one manifold part. The nine exported mating interfaces have
100% measured ring coverage, zero sampled collision, and p05–p95 gaps spanning
0.225–0.346 mm against the 0.20–0.35 mm contract. Exact Manifold boolean
intersections are 0 mm³ across all ten unordered part pairs. These are
engineering results only; they do not clear Phase 3 while identity, generation,
supervised sculpting, quoting, physical fit, and human recognition remain open.

An exploratory three-stand-in bakeoff exercised the render-receipt and
distinctness paths, but its output was intentionally removed and is **not
retained evidence**. Do not cite it as a current Phase 2 PASS. The real
three-candidate bakeoff and its capture report remain open.

Three real defects were caught by these checks *in their own subject* and
fixed — the sunglasses splitting into 5 bodies, the boolean leaving the body
non-manifold with zero holes, and the base thickness measurement counting the
peg. See §6.

---

## 9. Next actions, in order

The cover-fidelity loop itself is complete; do not keep changing the accepted
I06 merely to raise an ungrounded score. Continue from these remaining gates:

1. **Owner: approve or amend `cobie_figurine_v1.yaml` and the I06 broad
   design.** Especially the closed expression, wide stance, +12% head scale,
   leather jacket, aviators, and single Fetch Launcher.
2. **Owner: shoot the 18–24 photo pack** into `references/photos/`.
3. Generate the five turnaround views into `concepts/turnaround/` using the
   verbatim prompts. All five must use the same neutral empty-paw A-pose.
   **Check `rear.png` first** — if sunglasses are visible, regenerate.
4. Run `validate_turnaround.py` until PASS, then work the printed human
   checklist honestly.
5. Generate the separate Fetch Launcher pose reference outside the turnaround
   directory. Use it only for later supervised Blender posing.
6. Use `validation-renders/cover-v2/I06-lookdev/` and
   `validation-renders/cover-v2/I06-neutral/` to confirm or amend the broad
   silhouette, pose, jacket, aviators, launcher, and palette before spending
   generation credits. Do not treat them as identity approval.
7. Generate ≥3 candidates in a browser — Hunyuan3D 2.1 multi-view (primary),
   TRELLIS, Stable Fast 3D. Consider one **Hunyuan3D-Part / PartCrafter** run;
   part-aware decomposition maps directly onto FR-5 and the print split, and
   postdates the PRD.
8. Drop GLBs in `generated-meshes/`, run `bakeoff_render.py`, fill in
   `scorecard.md`, and pick a winner.
9. Copy the winner to `selected.glb` only after confirming Git LFS is active
   and the pointer/object round-trip succeeds. `.gitattributes` already tracks
   that path and all collectible `.blend` files. Do not begin irreplaceable
   manual sculpting with the only copy outside versioned storage.
10. Supervise the selected mesh's separation and keying; `build_figurine.py`
   intentionally fails closed before export while it remains one shell. Then
   run `print_check.py` and `slicer_import_check.py`.
11. Quote across Craftcloud / JLC3DP / PCBWay. Phase 3 does not exit until
   valid quotes exist. Choose the variant with the lowest
   **learning** risk, not the lowest price. Do not buy a printer for V1.
12. Perform a physical fit/clearance coupon or low-cost prototype before the
   finished order; the digital clearance contract is not a tactile fit test.

---

## 10. Open assumptions

I asked the owner and did not get answers, so these are defaults. Each is cheap
to change now and expensive later:

1. **Home:** this repo, not a separate one.
2. **Photos:** the owner shoots them. (Alternative was game-art-only, which
   risks the PRD's top failure mode: a generic apricot doodle in sunglasses.)
3. **Hero prop:** Fetch Launcher in the **3D-viewmodel** design — gold drum,
   caged barrel, cyan charge ring. Chosen over the poster design because it is
   the only version with real geometry to dimension against, and its clear
   barrel would be a resin fragility risk. Fallback: a golden tennis ball.

---

## 11. Traps

- **Never remove `.gdignore`.** Godot scans the project root; it would import
  and pack this tree.
- **Git LFS is required.** The V2 master is already tracked, and
  `.gitattributes` covers collectible `.blend` files plus
  `generated-meshes/selected.glb`. Verify `git lfs pull` from a fresh clone
  before treating an irreplaceable manual sculpt or selected identity mesh as
  archived. Derived STLs remain gitignored and receipt-bound.
- **Do not add collectible tests to `release_validate.sh`** (bare `python3`).
- **Do not reference not-yet-existing `docs/`, `tools/` or `.agents/` paths**
  from authority docs — `tools/validate_world_class_docs.py` fails on
  unresolved backticked repo paths. Paths under `cobie-collectible/` are not
  matched by that checker and are safe.
- **Anything landing under `assets/`** needs a `docs/ASSET_MANIFEST.md` row with
  a SHA-256 or `tools/asset_ip_scan.sh` fails. Nothing currently does.
- **Do not score candidates from textured previews.** PRD §8.2.
