# WCB-008L — Rain City 90-Second Production Gauntlet

**Frozen:** 2026-08-03 PDT  
**Integration branch:** `hermes/world-class-369-buildout`  
**Source commit:** `854d552`  
**Root owner:** GPT-5.6-sol/high through Hermes  
**Bounded workers and critics:** explicitly pinned `gpt-5.3-codex-spark`

## Goal

Make one reproducible 90-second Rain City gameplay slice feel materially more authored, cohesive, tactile, readable, and unmistakably Cobie without changing route topology, collision/navigation ownership, progression, enemy/weapon breadth, damage balance, boss ownership, release identity, or the high-resolution retro 2.5D production model.

The slice must improve the complete player-facing frame rather than optimize one screenshot:

1. authored Downtown-to-waterfront environment composition and story density;
2. selective wet-surface/material/light hierarchy;
3. Pawstol silhouette and synchronized firing feedback;
4. one existing Rain City enemy's consistent 3D-authored directional presentation;
5. sequence-specific audio timing and variation;
6. actual moving gameplay evidence plus matched stills, performance, cleanup, and Web checks.

This is a production experiment inside WCB-008L, not a new roadmap or runtime-3D pivot. WCB-008K remains honestly open for its rejected continuous Salmon Creek evidence continuation; its accepted production paths are frozen and no concurrent WCB-008K writer may run. Owner direction authorizes WCB-008L to proceed because the remaining WCB-008K evidence work is independent and does not transfer gameplay or presentation ownership.

## Product and identity constraints

- Preserve Godot 4.7, Compatibility renderer, GDScript, macOS primary and Web secondary targets.
- Preserve authored low-poly 3D environments plus directional billboard characters.
- Runtime full 3D may exist only in a debug A/B comparison for the selected existing enemy; production keeps the directional atlas unless a later owner decision changes the PRD.
- No protected shooter layouts, assets, dialogue, trade dress, logos, weapon silhouettes, or performances.
- External assets require one specific owner-authorized source, compatible license, editable/reproducible source, and same-change manifest entry. Project-original Blender/Material Maker sources are preferred.
- Presentation never acquires gameplay collision or navigation ownership.
- No new mission, weapon, enemy family/variant, economy, collectible, online service, dependency, autoload, telemetry, BETA removal, baseline promotion, deployment, or release stamp.
- Automated evidence cannot close human taste, humor, feel, fairness, audio-mix, comfort, photosensitivity, target-Mac playthrough, iPad, browser, or controller gates.

## Canonical experiment boundary

- **Production scene:** `res://scenes/levels/episode_1_vancouver_waterfront.tscn`.
- **Route:** production spawn through Downtown Alley, Rain City Slice, and the waterfront arrival; no post-start player transform write in continuous evidence.
- **Canonical still views:** `rain_city_downtown`, `rain_city_slice`, `vancouver_waterfront`.
- **Supporting regression views:** `rain_city_terminal`, `rain_city_harbour`.
- **Aspects:** 1280×720, 1680×1050, 1024×768, 3440×1440.
- **Motion evidence:** exactly 90.0 seconds at 30 rendered FPS / 60 physics TPS: 2,700 rendered frames and 5,400 physics ticks, or a fail-closed receipt proving why the exact target could not be produced. A candidate may not relabel 900 frames (30 seconds), staged output, or any shorter run as 90 seconds.
- **Determinism:** fixed seed; fixed quality profile; source/script hashes; fresh isolated user data; actual InputMap actions for post-start movement, look, fire, reload, use, and run.
- **Keyframes:** opening, first environmental reveal, first contact, weapon-feedback beat, enemy-readability beat, and waterfront route cue. Every keyframe binds frame/time, dimensions, source/script hashes, and image SHA-256.

## Rubric — 100 points

### A. Composition, place identity, and authored density — 25

- Route and dominant landmark read before decorative detail.
- At least three existing slab/box clusters in the canonical slice gain coherent authored silhouette, depth, maintenance/municipal story, or framing without changing collision/navigation.
- Downtown, Slice, and waterfront remain distinguishable without labels.
- Added detail does not create false interaction affordances or conceal threats/recovery lanes.

### B. Materials, wetness, lighting, and platform fit — 20

- Wetness is selective: plausible darker albedo/lower roughness and localized reflection response, never universal mirror gloss.
- Key/fill/emissive/fog hierarchy separates foreground, combat plane, landmark, and background.
- Required Rain City material families remain manifested and visibly distinct.
- 1024×768 and Web quality preserve route/enemy/HUD readability; performance stays within the frozen budget.

### C. Pawstol and combat presentation — 20

- Pawstol silhouette remains readable against both dark Downtown and brighter waterfront values.
- Fire, recoil/viewmodel motion, muzzle/impact, target reaction, audio transient, and HUD confirmation form one timed event while authoritative aim/damage/cadence stay unchanged.
- Miss/world/enemy/kill feedback remains distinct and bounded.
- Reduced-motion/reduced-flash settings remain effective and temporary nodes/voices return to baseline.

### D. Existing-enemy 3D-authored directional pilot — 15

- Exactly one existing Rain City enemy is selected; no family or gameplay role is added.
- Editable Blender source deterministically produces a fixed 8×4 atlas, consistent camera/light/padding/feet baseline, and the existing reaction/state vocabulary.
- Manifest records cell size, opaque height, intended world height, direction order, pixel-size calculation, source/runtime hashes, tool version, and license/provenance.
- A debug-only runtime-3D render of the same source may support matched A/B evidence; it may not silently replace production.
- Production atlas must be coherent across directions, readable at combat distance, and no more expensive than the declared Web/native sprite budgets.

### E. Audio, motion evidence, engineering, and honesty — 20

- Existing audio architecture gains sequence-specific variation/timing only where evidence shows a gap; no synthetic count target substitutes for mix quality.
- One truthful 90-second automated moving run exists or the packet remains blocked with the exact fail-closed reason.
- Canonical still Cartesian product is complete and receipt-verified.
- Focused tests, full core tests, architecture/docs/IP/content checks, native performance, and warranted Web/macOS exports pass with no attributable parser/runtime errors, leaks, orphan nodes, or unbounded growth.
- Evidence classes and remaining human/device gates are explicit.

## Acceptance and stop rules

A milestone may integrate only when:

1. its dependency milestone is committed and pushed;
2. owned/frozen paths were mechanically checked;
3. the root owner reviewed the complete diff and raw test output;
4. focused mechanical gates pass without attributable engine errors/leaks;
5. visual work has matched baseline/candidate evidence and root pixel inspection;
6. a fresh Spark critic inspects the real artifacts, not the writer summary;
7. no rubric category introduced by that milestone falls below 60%; and
8. the candidate is a clear bounded improvement or is rejected/rolled back.

Final production-candidate acceptance requires at least 82/100, no category below 70%, no hard gate failure, and an explicit human-review packet. The BETA label remains.

Stop rather than widen scope for protected/unclear assets, missing editable source, route/collision/navigation need, progression or damage-balance change, non-reproducible baseline, repeated engine error/leak, performance breach without owner disposition, absent source-bound receipt, model limit, dirty unrelated work, two failed repairs, or diminishing visual return.

## Gauntlet / Goal Loop

```text
M0 CONTRACT
  root reads authority -> verifies clean source/toolchain/model/quota
  -> four independent Spark read-only audits
  -> root freezes this decision-complete contract
  -> docs validation -> commit/push

M1 TRUTHFUL BASELINE
  one bounded Spark test/evidence writer in isolated full clone
  -> root reviews and imports only a cohesive commit
  -> input-only 90-second harness + receipt verifier + negative tests
  -> matched baseline run and stills
  -> Spark evidence critic
  -> root commit/push
  -> #gptusage checkpoint (M0 + M1)

M2 ENVIRONMENT
  root art brief and exact geometry/material ownership
  -> one isolated Spark content writer for mechanical source/export/manifest work
  -> root art direction, Blender output inspection, Godot integration
  -> matched still/motion/performance evidence
  -> fresh Spark artifact critic
  -> root commit/push

M3 COMBAT
  exact combat/viewmodel/audio ownership, environment paths frozen
  -> one isolated Spark gameplay writer
  -> root diff/test/runtime review
  -> matched firing clip + cleanup/accessibility/performance evidence
  -> fresh Spark artifact critic
  -> root commit/push
  -> #gptusage checkpoint (M2 + M3)

M4 ENEMY A/B
  select one existing enemy from evidence
  -> one isolated Spark content writer for deterministic Blender/atlas/manifest/test paths
  -> root renders and pixel-inspects all atlas cells
  -> production 2.5D vs debug-only 3D matched A/B
  -> fresh Spark critic
  -> root integrates or rejects, then commit/push

M5 INTEGRATED RUN
  clean rebuild -> full 90-second candidate -> canonical four-aspect stills
  -> native profile + packaged Web checks + full release matrix when warranted
  -> three fresh Spark critics: art/composition, combat/audio, evidence/performance
  -> root scores rubric and repairs one bounded material gap at most
  -> ledger + human review packet + commit/push
  -> #gptusage checkpoint (M4 + M5)
  -> HUMAN STOP
```

## Milestone ownership

### M0 — contract and baseline freeze

Owned: this packet, the WCB-008L block in `docs/IMPLEMENTATION_PLAN.md`, and the append-only ledger entry. No production files.

### M1 — continuous evidence infrastructure

Expected owned paths, frozen precisely before writer launch:

- one additive debug scene and script under `scenes/debug/` and `scripts/debug/`;
- one additive wrapper and standard-library verifier under `tools/`;
- focused verifier/unit/integration tests;
- the smallest capture-manifest seam if required.

All production level/combat/enemy/UI/audio/assets are frozen. The harness starts at the production spawn and uses named input after `level_ready`; no post-start transform, direct encounter activation, synthetic kill, direct progression call, or staged zone entry.

### M2 — environment/material/lighting

Candidate source families:

- `assets/source/blender/rain_city_run_foundry.blend` and its deterministic builder;
- `assets/models/environment/rain_city_run_foundry.glb`;
- exact Rain City Material Maker graphs/exports and manifest entries;
- presentation-only Rain City scene/applier/profile paths;
- focused asset/material/presentation tests.

Gameplay world-builder collision/navigation, route runtime, encounter choreography, boss, progression, and other missions remain frozen. Exact paths are narrowed after baseline/audits.

### M3 — Pawstol/combat presentation

Candidate paths are limited to existing Pawstol/viewmodel feel/resource/VFX/audio presentation seams and focused tests. Damage, range, cadence, ammo, auto-aim authority, enemy logic, level presentation, and weapon breadth remain frozen. Exact paths are narrowed after M2 integration.

### M4 — one existing enemy

Candidate is selected after M1–M3 evidence. Owned paths are one existing enemy's Blender source/builder, atlas/runtime presentation resource, exact manifest entry, optional debug-only same-source GLB/A-B scene, and focused tests. AI, collision, health/damage, role, encounter count, other enemies, and production runtime format remain frozen.

### M5 — integration/evidence only

Production writers stop. Root owns evidence adapters, comparisons, release validation, ledger/human packet, and bounded repair of one defect already inside accepted ownership. No breadth.

## Worker contract

Every Spark worker returns:

```yaml
work_id:
status: complete | blocked | failed
model: gpt-5.3-codex-spark
baseline_revision:
role: audit | writer | critic | repair
owned_paths: []
changed_paths: []
commands_run: []
mechanical_results: []
evidence_paths: []
verdict: accept | revise | reject | blocked
largest_gap:
regressions: []
remaining_human_gates: []
commit_hash: null
```

Writers use an isolated nested full clone, one cohesive commit, no merge/push/deploy/release stamp/privileged MCP/human claim. GPT-5.6 verifies the commit parent and path scope, reviews the complete patch, reruns tests in the canonical checkout, updates authority documents, and alone integrates.

## Root verification floor

Per coherent production milestone:

```bash
bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd
python3 tools/validate_world_class_docs.py
bash tools/architecture_check.sh
bash tools/asset_ip_scan.sh
/opt/homebrew/bin/godot --headless --path . --script res://tools/validate_content.gd
```

Run every new focused test, matched capture/compare, cleanup/performance probe, and asset/import contract for the milestone. M5 runs `QA_EXPORTS=1 bash tools/release_validate.sh` if production rendering/audio/assets changed, plus a target-Mac rendered profile and fresh packaged-Web console/performance check when available. Missing optional MCP does not block stock CLI Blender/Godot/capture evidence; it blocks MCP-specific claims only.

## Human handoff questions

- Does the 90-second slice read as Rain City without labels?
- Is the route clearer and the added density authored rather than cluttered?
- Does selective wetness feel plausible without mirror gloss?
- Does the Pawstol feel heavier and remain readable without discomfort?
- Is the selected enemy coherent in motion and readable at ordinary combat distance?
- Does the 2.5D production candidate retain more identity/readability than the debug runtime-3D alternative?
- Is audio variation supportive rather than noisy or fatiguing?
- Are humor, motion, flash, mix, keyboard/mouse, target-Mac, browser, iPad, and controller behavior acceptable?
