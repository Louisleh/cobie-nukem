# Opus 5 Rain City Pilot — Phase 0 verification, Phase 1 read-only audit, Phase 2 ownership declaration

**Mandate:** `docs/handoffs/OPUS5_RAIN_CITY_VISUAL_UPLIFT.md`
**Branch:** `hermes/world-class-369-buildout`
**HEAD:** `a89971c` (`docs: add Opus 5 Rain City uplift handoff`)
**Gameplay baseline:** `d3de4de` (`docs: record WCB-008I integration evidence`)
**HEAD vs baseline:** exactly 1 commit, documentation-only (the handoff itself, 538 lines) — satisfies the mandate's "differs only by documentation/handoff commits".
**Working tree at audit start:** clean (0 modified files).
**Status:** Phases 0–2 complete. **No production files edited.** Implementation is gated on one human decision (§5).

---

## 1. Phase 0 — toolchain verification (real results)

| Requirement | Result | Evidence |
| --- | --- | --- |
| Godot 4.7 stable | ✅ `4.7.stable.official.5b4e0cb0f` | `godot --version` |
| Export templates | ✅ `4.7.stable` present | `~/.local/share/godot/export_templates/` |
| Headless import/parse | ✅ exit 0, **0 error lines** | `godot --headless --path . --editor --quit` |
| Deterministic visual capture | ✅ **reproducible** | see §2 — real PNGs + receipts |
| **Blender** | ❌ **NOT INSTALLED** | `command -v blender` → missing |
| **Material Maker** | ❌ **NOT INSTALLED** | not on PATH |
| **GPU** | ❌ **NONE** — software rasterizer only | `/dev/dri` absent; renderer reports `Mesa llvmpipe (LLVM 20.1.2)` |
| Editor GUI | ❌ aborts (needs Vulkan `VK_KHR_surface`) | `/tmp/import2.log` — headless import is unaffected |

### 1.1 Two tool-path corrections required in this environment (not repo defects)

`tools/visual_quality/capture.sh:68` hardcodes `/opt/homebrew/bin/uv`, and `capture_tool.py:140,400` default `GODOT_BIN` to `/opt/homebrew/bin/godot`. Both are correct for the owner's Mac. Here the same tool runs unmodified via:

```bash
PATH=/root/.local/bin:$PATH GODOT_BIN=/usr/local/bin/godot \
xvfb-run -a --server-args="-screen 0 1600x1200x24" \
uv run --project tools/visual_quality python tools/visual_quality/capture_tool.py \
  --manifest tools/visual_quality/capture_manifest.json --view <VIEW> --aspect 1280x720 --run-id <ID>
```

**No repository file was modified to achieve this.**

### 1.2 Pre-existing artifact recorded before any edit

Running the **headless editor import** on Linux rewrites two tracked files:
`default_bus_layout.tres` (drops `soft_clip_db = 2.0` from the master limiter; adds a `uid`) and `project.godot` (removes 6 lines). This is a Godot-version/platform normalization side effect, **not** caused by this pass. I reverted both with `git checkout --` to restore a clean tree. **Anyone running import on Linux must avoid committing that churn.**

### 1.3 Executable-surface map (what this environment can and cannot do)

| Domain | Executable here? | Why |
| --- | --- | --- |
| Lighting / atmosphere / fog | ✅ | Authored in GDScript: `scripts/level/vancouver_waterfront_world_builder.gd::_build_environment()` + typed `ZonePresentationProfile` resources (`resources/presentation/vancouver_*.tres`) |
| Materials | ✅ | `tools/materials/build_mission_material_library.py` exists **specifically** to produce deterministic 512px exports "without requiring Material Maker to run headlessly" — numpy + Pillow, both available |
| Visual captures + receipts | ✅ | Verified — see §2 |
| Mechanical test gates | ✅ | Headless suites run |
| **Environment geometry** | ❌ | `rain_city_presentation.tscn` consumes `assets/models/environment/rain_city_run_foundry.glb`, regenerated only by Blender from `assets/source/blender/rain_city_run_foundry.blend` |
| **Native/Web performance evidence** | ❌ | llvmpipe measured **70.4 ms/frame CPU, 77.8 ms/frame GPU**. Any p50/p95/p99 here is a property of the software rasterizer, not of the game. |

---

## 2. Reproduced baseline evidence (real captures, this environment)

Both captures verified as genuine rendered content, not blank.

| View | Aspect | Image SHA-256 | Camera / staging | Pixel sanity |
| --- | --- | --- | --- | --- |
| `rain_city_downtown` | 1280×720 | `0f78753dd6db10c66fb5a1e6dbf37b3a569071c9dd7a176d0bcfb0198bb45dc7` | origin `(2.0, 2.66, 5.0)`, FOV 90, seed `2026072210`, frame 80, `position_error 0.0` | mean 52.7, std 32.3, **36,758 unique colors** |
| `vancouver_waterfront` | 1280×720 | `9c5a756a96e9ae5adbe809089bb820a7950f956a1c6ce9f7a934db959ab784ee` | origin `(0.0, 2.66, -73.0)`, FOV 90, seed `2026071613`, frame 80, `position_error 0.0` | genuine rendered content |

Paths: `builds/visual-quality/candidates/opus5_phase0_probe{,_wf}/`.
Receipts bind dimensions, player/camera pose, active-camera ancestry, FOV, seed and image hash — the mandate's receipt contract is intact and reproducible here.

---

## 3. Phase 1 — ranked diagnosis (evidence → root cause → smallest intervention)

Each finding cites the captures above and named source. Ranked by visible upside ÷ integration risk.

### F1 — No key-light direction; the frame is flat sky-ambient *(highest impact)*
- **Evidence:** In both captures, alley walls, ground, terminal massing and benches show almost no light/shadow modelling; adjacent faces at different orientations share nearly the same value. Whole-frame mean 52.7/255 with std 32.3 — a narrow, dark band.
- **Root cause:** `_build_environment()` sets `ambient_light_source = AMBIENT_SOURCE_SKY`, `ambient_light_energy = 0.55` against a single `DirectionalLight3D` at `energy = 1.05`, colour `#c5d7d6`, rotation `(-52°, -28°, 0)`. Sky ambient is close in value to the key, so the key contributes little modelling. The art bible requires "light establishes direction before mood."
- **Smallest intervention:** retune the existing key/ambient **ratio** (raise key energy, lower ambient energy, warm/cool split key vs. fill) — **no new lights, no new nodes**.
- **Upside:** high — restores form, depth and route legibility everywhere at once.
- **Risk:** low. Parameter-only; zero added draw calls.
- **Verification:** re-capture identical staging; compare value histograms.

### F2 — Everything occupies one value band; sky is the brightest region *(high)*
- **Evidence:** Waterfront capture — sky, water, mountains and promenade are near-identical mid-slate; the water/sky horizon is nearly invisible. The brightest area of both frames is the upper sky, pulling the eye away from the route.
- **Root cause:** `fog_light_color #708992` + `fog_aerial_perspective 0.72` + sky-dominant ambient compress foreground/midground/background toward one value. Art bible requires threats "at least one clear value step away from their background."
- **Smallest intervention:** tune fog density/aerial-perspective and sky horizon value so background recedes and the combat plane holds the highest local contrast.
- **Upside:** high — creates the mandated foreground / combat-plane / landmark / skyline / weather separation.
- **Risk:** low (parameter-only). Must re-verify enemy separation at combat distance.

### F3 — "Rain city" reads dry; no wetness or puddle contrast *(high identity impact)*
- **Evidence:** Downtown ground and waterfront promenade are flat matte grey. Rain streaks are present but extremely sparse (a few thin lines in the waterfront capture). No puddles, no darkened wet albedo, no selective specular.
- **Root cause:** the `wet_asphalt` family exists (`assets/materials/rain_city/wet_asphalt.tres`, generated by `build_mission_material_library.py`) but its runtime read is dry; wetness is not expressed as the art bible's "selective darker albedo and lower roughness."
- **Smallest intervention:** adjust the generated material family's albedo/roughness response (deterministic Python regeneration) and/or the applier's parameters. **Puddles/markings stay decals — do not bake into tiling base.**
- **Upside:** high — this is the single strongest "unmistakably Rain City" signal.
- **Risk:** medium — touches manifested assets; requires provenance + hash updates.

### F4 — Repeated flat slabs and generic corridor massing *(mandate explicitly names this)*
- **Evidence:** Downtown alley = two flat wall planes + one flat ground plane; brick appears as flat coloured rectangles pasted on grey with no depth. Waterfront benches/planters are untextured boxes. Distant mountains are flat triangles.
- **Root cause:** foundry-generated modular massing with low surface variation.
- **Smallest intervention:** **BLOCKED — requires Blender** to regenerate `rain_city_run_foundry.glb`. Out of scope for this environment.
- **Disposition:** documented, deferred to a Blender-capable session.

### F5 — Warm-accent density is far too low *(medium, cheap)*
- **Evidence:** Warm elements that *do* exist work well — the amber terminal structure and the orange "NO FETCHING FROM THE HARBOUR" sign are the only things that pull the eye correctly. They are scarce.
- **Root cause:** warm shelter/storefront/checkpoint pockets are under-placed relative to the art bible's hierarchy.
- **Smallest intervention:** raise emissive/warm-pocket presence within the existing `lighting_budget` in the zone presentation profiles.
- **Risk:** low–medium; must respect per-zone `lighting_budget`.

### F6 — Weapon silhouette readability is background-dependent *(medium)*
- **Evidence:** The Pawstol viewmodel is dark-on-dark and hard to read against the downtown alley ground, but reads clearly against the lighter waterfront promenade.
- **Root cause:** no consistent viewmodel rim/fill separation.
- **Disposition:** real, but belongs to weapon-feel ownership; **include only if the selected pilot covers it.** Recommend deferring to keep this pilot single-concern.

### F7 — HUD hierarchy is a strength; do not regress it
- **Evidence:** Cobie portrait + gold ring, health/armor/ammo, and objective line are the clearest, most confident elements in both frames.
- **Disposition:** protect. Any atmosphere change must not reduce HUD contrast.

---

## 4. Phase 2 — pilot selection and ownership declaration

### 4.1 Selected pilot
**Rain City atmosphere and material-contrast pass for the Downtown → waterfront arrival** — the mandate's default pilot, retained. F1–F3 and F5 all live inside it, and all are executable here without Blender.

### 4.2 Acceptance condition (one sentence)
The Downtown→waterfront arrival reads with a clear key-light direction, separated foreground/combat-plane/landmark/skyline depth, and a visibly wet Rain City surface identity — at identical capture staging, with no HUD/enemy readability regression and no change to collision, navigation, route, progression, encounters, checkpoints, or boss ownership.

### 4.3 Change class — deliberately constrained
**Parameter-and-material retune only.** No new lights, nodes, particles, meshes, or draw calls. This is chosen specifically so that performance impact is *structurally* neutral (no added rendering work), which is the only defensible position while GPU measurement is unavailable.

### 4.4 Owned paths (only what is required)
- `scripts/level/vancouver_waterfront_world_builder.gd` — `_build_environment()` key/ambient/fog parameters only
- `resources/presentation/vancouver_downtown_presentation.tres`, `vancouver_waterfront_presentation.tres` — fog/lighting-budget fields
- `tools/materials/build_mission_material_library.py` + `assets/materials/rain_city/*` — wetness response, regenerated deterministically
- `docs/ASSET_MANIFEST.md` — provenance/hashes for regenerated materials
- `docs/art-briefs/rain_city_run.yaml`, `docs/WORLD_CLASS_BUILDOUT_LOG.md` — factual packet state
- focused contract tests for the above

### 4.5 Frozen paths (must not change)
`assets/source/blender/**`, `assets/models/environment/rain_city_run_foundry.glb`, `scenes/levels/vancouver/rain_city_gameplay_layout.tscn`, all collision/navigation, `scripts/level/rain_city_mission_assembly.gd` route/objective/encounter logic, **all WCB-007 Towmaster boss paths**, Salmon Creek, Mount Hood, Moon, Ventura, and every approved baseline under `builds/visual-quality/baseline*`.

### 4.6 Verification plan
Focused: `enemy_contract_tests`, `ui_scene_test`, Rain City route/content/mission-host suites, `world_interaction_test`, `asset_ip_scan.sh`, content validator, then `QA_EXPORTS=0 bash tools/release_validate.sh`.
Visual: re-capture `rain_city_downtown` + `vancouver_waterfront` at identical staging/seed/pose, plus 1680×1050, 1024×768 and 3440×1440; before/candidate/difference images; reduced-motion and reduced-flash variants.

### 4.7 Rollback boundary
Every owned change is parameter-level and revertable with `git checkout --` on the listed paths; regenerated materials are reproducible from the deterministic script. No baseline is approved, nothing is pushed.

---

## 5. Blocking human decision (why implementation has not started)

Mandate §9 makes **"native/Web performance and object/resource evidence show no unexplained regression"** an acceptance condition, and §11 stops on *"required toolchain unavailable and no verified equivalent exists"* and *"a human-only judgment is required to continue safely."*

**This environment cannot produce valid performance evidence.** There is no GPU; llvmpipe renders at ~70–78 ms/frame regardless of content, so p50/p95/p99 here measures the software rasterizer, not the change. There is no verified equivalent.

I will not substitute plausible numbers for missing evidence. Two safe options:

- **Option A — proceed with the constrained pilot (recommended).** Implement §4.3's parameter-and-material retune, which adds *zero* rendering work by construction, and deliver full before/candidate visual evidence at all four aspect classes plus mechanical gates. Performance is argued structurally (unchanged draw calls / node counts, verifiable from capture and profile counters) and explicitly flagged as **requiring confirmation on the owner's Mac**. Nothing is pushed or approved.
- **Option B — stop here.** Deliver this audit as the packet; run the visual/performance pilot in a Blender- and GPU-capable session so F4 (geometry) is also in scope and §9 can be satisfied in full.

**Recommendation: Option A**, because F1–F3 are the dominant visual defects, are fixable without Blender, and are exactly the class of change whose performance cost is provably neutral — while F4 is honestly deferred.

---

## 6. Human questions still open (no automation may answer these)

1. Does the retuned lighting read as *Rain City* rather than "generic dark blue level"?
2. Is the wet-surface treatment convincing without becoming a universal mirror?
3. Do enemies still separate from the background at real combat distance, on a real display?
4. Is the atmosphere comfortable — motion, photosensitivity, and tablet glare?
5. Is the humour/environmental-story density improved or merely lit differently?
6. Should F6 (weapon rim separation) join this pilot or stay a separate feel pass?
