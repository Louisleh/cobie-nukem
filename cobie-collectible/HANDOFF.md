# Cobie Nukem physical collectible — handoff

**Written:** 2026-07-29
**Branch:** `claude/cobie-nukem-phase12-pass-igt54i`
**PR:** [Louisleh/cobie-nukem#65](https://github.com/Louisleh/cobie-nukem/pull/65) (draft)
**Repo:** `Louisleh/cobie-nukem`
**Audience:** Codex, or any agent picking this up cold.

Read this file, then `README.md`, then
`references/character-brief/cobie_figurine_v1.yaml`. That is enough to continue
without re-deriving anything.

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
| 2 Mesh bakeoff | **Tooling done and proven, no candidates yet** | `scripts/bakeoff_render.py` |
| 3 Digital V1 | **Tooling done, runs green on a proxy** | `scripts/build_figurine.py`, `scripts/print_check.py` |
| 4 Resin prototype | Not started | — |
| 5 Finished collectible | Not started | — |

**Nothing has been printed. No image-to-3D generation has been run. No
photographs exist yet.** What exists is the full software pipeline, proven
end-to-end against a proxy and against stand-in meshes.

### The two hard blockers, both owner-side

1. **Photographs of the real Cobie.** 18–24 frames. Shot list is in the brief
   under `photo_shot_list`. Nothing in Phase 1 can start without them.
2. **Turnaround generation.** Needs an image-gen subscription. Prompts are
   written verbatim in `references/turnaround-prompts.md`.

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
│   │   └── cobie_figurine_v1.yaml  THE FREEZE. Identity, pose, print rules, photo shot list.
│   ├── turnaround-prompts.md       verbatim ImageGen prompts for the 5 views
│   ├── photos/                     (empty, gitignored) owner's photo pack goes here
│   └── game-art/                   (empty) optional local copies of hero refs
│
├── scripts/
│   ├── _common.py                  paths, print constants, scale contract, seeds, Failure/report
│   ├── receipt.py                  render provenance: re-derives pose, re-hashes images
│   ├── validate_turnaround.py      PHASE 1 GATE
│   ├── bakeoff_render.py           PHASE 2: clay renders + distinctness
│   ├── build_figurine.py           PHASE 3: geometry, parts, base, STL export
│   └── print_check.py              PHASE 3 GATE: manifold/thickness/balance
│
├── tests/
│   └── test_collectible.py         16 tests, ~2s, no bpy import
│
├── tools/
│   └── pyproject.toml              pinned deps, requires-python >=3.13
│
├── blender/                        (gitignored) cobie_figurine_v1.blend
├── generated-meshes/               (gitignored) downloaded candidate GLBs
├── exports/                        (gitignored STLs) + print_check_report.json (committed)
├── concepts/turnaround/            (gitignored) the 5 generated views
├── validation-renders/             small committed review sheets
├── slicer-tests/  print-quotes/    empty, for phase 4
```

Also changed outside this directory:
- `docs/DECISIONS.md` — added **D-013** recording the four binding decisions.
- `.github/workflows/ci.yml` — added a Pillow/numpy install step (see §7).

---

## 4. Environment — verified, not assumed

This matters because the plan originally assumed almost none of it was
possible here. I measured each one.

| Capability | Result |
|---|---|
| `bpy` 5.2.0 LTS headless | ✅ **requires CPython 3.13** — cp313 wheels only |
| Mesh ops, voxel remesh, STL export | ✅ |
| EEVEE render | ✅ **only after** installing GL libs (below) |
| trimesh / pymeshlab / scipy / rtree | ✅ |
| **Cycles** | ❌ absent from the pip wheel — EEVEE only |
| **Blender 3D Print Toolbox** | ❌ absent — reimplemented in `print_check.py` |
| **3MF export** | ❌ absent — STL only |
| GPU | ❌ none. Mesa llvmpipe software GL. |
| Render cost | ⚠️ ~26 s at 512 px, ~117 s at 1024 px |

Required system packages on Linux (not needed on macOS):

```bash
apt-get install -y libegl1 libgl1-mesa-dri libopengl0 libxkbcommon0
```

Without `libegl1`, every render dies with `Couldn't open libEGL.so.1`.
Without `libopengl0`, pymeshlab silently loads **zero** format plugins and then
reports the misleading `Unknown format for load: stl`.

Setup:

```bash
uv venv --python 3.13 cobie-collectible/tools/.venv
uv pip install --python cobie-collectible/tools/.venv/bin/python \
  bpy==5.2.0 trimesh==4.12.2 pymeshlab==2025.7.post1 \
  numpy==2.5.1 pillow==12.3.0 scipy==1.16.3 rtree==1.4.1
```

Run anything as:

```bash
uv run --project cobie-collectible/tools python cobie-collectible/scripts/<script>.py
```

---

## 5. Binding decisions (docs/DECISIONS.md D-013)

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
across the four cardinals, vertical alignment of top and bottom edges, horizontal
centring, foreground coverage, background uniformity, and palette drift.

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

Two modes. With `generated-meshes/selected.glb` it imports, normalises to 140 mm
and splits parts. Without it, it builds a **proportioned proxy from primitives**
following the brief.

The proxy is **not the deliverable and will not be printed.** It exists so the
print rules, base keying, balance maths, export and validation are exercised
before any generated mesh arrives.

Non-obvious: `join_and_solidify()` applies transforms on every primitive
*before* joining. Skipping that bakes the others into the active object's
anisotropically-scaled local space and the voxel remesh then produces garbage.
`remesh()` also dissolves degenerate faces — voxel remesh emits zero-area
triangles whose edges touch three faces, making the mesh non-manifold while
reporting zero holes.

### `print_check.py` — Phase 3 gate

Replaces the absent 3D Print Toolbox: watertight, winding, degenerate faces,
floating shells, triangle count, wall thickness, base diameter/thickness, and a
**centre-of-mass-over-footprint balance test** for FR-4 "stands unaided".

Two things to understand before touching it:

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

---

## 7. CI status — read this before debugging

**PR #65 CI is currently RED, and the failure is pre-existing and unrelated to
this work.**

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

**Fix applied on this branch:** a step in `ci.yml` installing
`pillow==10.4.0` and `numpy==2.1.2` (versions matched to
`tools/visual_quality/pyproject.toml`) before validation, plus a recorded
version stamp. This should turn #65 green. **If CI is still red after that,
re-verify before assuming it is the collectible code.**

Separately, there is a known **non-deterministic ObjectDB leak** in
`tests/unit/mission_presentation_test.gd`. It predates this work and was
reproduced as flaky earlier in the project (5 clean local runs). If CI fails
there, re-run before investigating.

---

## 8. Verification — what has actually been proven

Everything below was run, not assumed.

```bash
# 16 tests, ~2s, no bpy
uv run --project cobie-collectible/tools python cobie-collectible/tests/test_collectible.py

# builds proxy, exports 5 STLs
uv run --project cobie-collectible/tools python cobie-collectible/scripts/build_figurine.py
# -> COBIE_FIGURINE_BUILD: PASS

# validates them, ~24s
uv run --project cobie-collectible/tools python cobie-collectible/scripts/print_check.py
# -> COBIE_FIGURINE_PRINT_CHECK: PASS

# repo gates, all green and unchanged
bash tools/asset_ip_scan.sh
bash tools/architecture_check.sh
python3 tools/validate_world_class_docs.py
bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit
```

**Proxy results:** 140.9 mm tall, 70 mm base, 5.0 mm plate, centre of mass 7.2%
off centre against a 35% limit, all five parts watertight and single-body.

**Bakeoff proven** on three stand-in GLBs (two weapon viewmodels plus a
deliberate duplicate): 15 renders, every receipt verified, and the duplicate
caught at IoU 1.0000 while the two genuinely different meshes passed. Those
stand-ins were removed afterwards.

Three real defects were caught by these checks *in their own subject* and
fixed — the sunglasses splitting into 5 bodies, the boolean leaving the body
non-manifold with zero holes, and the base thickness measurement counting the
peg. See §6.

---

## 9. Next actions, in order

1. **Owner: approve or amend `cobie_figurine_v1.yaml`.** Especially pose,
   +12% head scale, and the Fetch Launcher choice.
2. **Owner: shoot the 18–24 photo pack** into `references/photos/`.
3. Generate the five turnaround views into `concepts/turnaround/` using the
   verbatim prompts. **Check `rear.png` first** — if sunglasses are visible,
   regenerate.
4. Run `validate_turnaround.py` until PASS, then work the printed human
   checklist honestly.
5. Generate ≥3 candidates in a browser — Hunyuan3D 2.1 multi-view (primary),
   TRELLIS, Stable Fast 3D. Consider one **Hunyuan3D-Part / PartCrafter** run;
   part-aware decomposition maps directly onto FR-5 and the print split, and
   postdates the PRD.
6. Drop GLBs in `generated-meshes/`, run `bakeoff_render.py`, fill in
   `scorecard.md`, pick a winner, copy it to `selected.glb`.
7. Run `build_figurine.py` then `print_check.py`. **Part separation of a
   generated mesh is a supervised step** — the script says so and does not
   pretend to automate it.
8. Quote across Craftcloud / JLC3DP / PCBWay. Order the variant with the lowest
   **learning** risk, not the lowest price. Do not buy a printer for V1.

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
- **No Git LFS, `.git` is ~97 MB.** The 3.5 MB `.blend`, 12 MB of STLs and the
  1.4 GB venv are gitignored and tracked by SHA-256. **When the `.blend` gains
  manual sculpting it stops being reproducible and must be committed — at that
  point this repo needs LFS.** Plan for it.
- **Do not add collectible tests to `release_validate.sh`** (bare `python3`).
- **Do not reference not-yet-existing `docs/`, `tools/` or `.agents/` paths**
  from authority docs — `tools/validate_world_class_docs.py` fails on
  unresolved backticked repo paths. Paths under `cobie-collectible/` are not
  matched by that checker and are safe.
- **Anything landing under `assets/`** needs a `docs/ASSET_MANIFEST.md` row with
  a SHA-256 or `tools/asset_ip_scan.sh` fails. Nothing currently does.
- **Do not score candidates from textured previews.** PRD §8.2.
