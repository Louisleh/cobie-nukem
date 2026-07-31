# WCB-008K — Salmon Creek First-30-Second Hardened Gauntlet

**Frozen:** 2026-07-27 PDT  
**Integration branch:** `hermes/world-class-369-buildout`  
**Source commit:** `1015f6ba803f8059ed87abc0b356e84ba112069d`  
**Root owner:** GPT-5.6-sol/high through Hermes  
**Bounded workers:** explicitly pinned `gpt-5.3-codex-spark`

## Mandate

Make Salmon Creek's first 30 seconds feel like an authored, legible, funny action-game opening rather than a functional test arena. A reproducible opening must communicate, in order:

1. Cobie is ready and visibly armed;
2. the municipal rule-break joke is readable;
3. first enemy contact is unmistakable but fair;
4. the equipment shed is the obvious next route anchor.

The result may improve presentation, pacing cues, deterministic evidence, and focused tests. It may not change route topology, collision, navigation, progression/save semantics, boss architecture, enemy/weapon breadth, release identity, or another mission.

## Required reading

1. `AGENTS.md`
2. `docs/PRD.md` §1.5, especially the opening-quality continuation
3. `docs/IMPLEMENTATION_PLAN.md` WCB-008K
4. `docs/WORLD_CLASS_BUILDOUT_LOG.md` latest WCB-008J entry
5. `docs/ART_BIBLE.md` Salmon Creek identity and visual hierarchy
6. `.agents/skills/cobie-spark-orchestration/SKILL.md`
7. This brief

Repository files and Git state override chat summaries.

## Frozen baseline

- Baseline commit: `1015f6ba803f8059ed87abc0b356e84ba112069d`
- Canonical views: `salmon_opening`, `salmon_sports_field`, `salmon_shed`
- Canonical aspects: 1280×720, 1680×1050, 1024×768, 3440×1440
- Deterministic seed: `2026071601`
- Existing opening encounter invariants:
  - 12-second grace window;
  - three opening actors;
  - one simultaneous attacker;
  - original Pawstol/weapon kit;
  - unchanged shed gate and route topology.

A candidate is compared only against matched captures from this commit and the same capture/tool settings.

## Frozen product constraints

- Preserve high-resolution retro 2.5D; do not pivot to pixel art.
- Preserve the Salmon Creek palette: storm blue, wet evergreen, dark turf, municipal sodium amber, cream markings, hazard red.
- Preserve Web/Compatibility-renderer constraints and asset provenance.
- Do not copy protected shooter art, lines, layouts, or trade dress.
- Do not add an autoload, dependency, plugin, network service, or telemetry.
- No `BETA` removal, baseline promotion, release stamping, deployment, or human/device claim.

## Exact ownership boundary

### Candidate writer may own

- `scripts/level/salmon_creek_environment_kit.gd`
- `scripts/level/salmon_creek_world_builder.gd`, limited to the existing `no_animals` sign transform/size; its text, interaction/secret semantics, node count, and route/collision ownership remain frozen
- `resources/encounters/salmon_forbidden_field.tres`
- one new focused test under `tests/integration/` whose filename begins `salmon_creek_opening_`
- the smallest opening-evidence seam in:
  - `scripts/debug/vertical_slice_capture.gd`
  - `tools/capture_native_evidence.sh`
  - `tools/visual_quality/capture_manifest.json`
  - `tests/unit/visual_capture_manifest_test.gd`
- this packet's result file under `docs/work_packets/wcb008k/`

The writer need not touch every allowed path. Fewer production changes are preferred.

### Frozen production paths

- `scripts/level/salmon_creek_world_builder.gd` route geometry, collision, navigation, gates, progression objects, and pickup locations
- `scripts/level/episode_1_level_1.gd`
- `scenes/levels/episode_1_level_1.tscn`
- player, weapon, enemy, save, campaign, boss, core, input, UI/HUD, audio, export, release, and other-mission paths
- all existing `.blend`, `.glb`, texture, and audio assets unless the root owner records a new provenance-safe ownership transfer first

If a critic finds a real defect outside ownership, report it. Do not route around it by widening scope silently.

## Frozen rubric — 100 points

### A. Opening orientation and hero affordance — 20

- By the first canonical opening state, HUD/build identity/weapon presentation are unobscured.
- The view has a dominant forward read rather than undifferentiated field space.
- No caption, prop, or presentation layer hides the reticle, ammo, objective, or weapon.

### B. Rule-break joke and environmental identity — 20

- `NO ANIMALS ON SPORTS FIELD` is legible or unmistakably framed from the opening route.
- The joke is supported by authored municipal/sports-field context, not a text wall.
- Salmon Creek is recognizable without relying on a mission label.

### C. First contact readability and fairness — 25

- The 12-second grace window remains exact.
- Three existing actor roles remain; one attacker maximum remains.
- Threats separate from the cool background by value/silhouette.
- Contact does not spawn behind the player, inside props, or as unreadable visual noise.

### D. Equipment-shed route cue — 20

- The shed reads as the next destination after initial contact.
- Warm light, landmark, sign, or value grouping guides the eye without changing collision/topology.
- The route cue does not overpower threats or look like a pickup/objective that does not exist.

### E. Engineering, performance, accessibility, provenance — 15

- Focused and root tests remain fail-closed.
- Canonical aspect captures have no HUD/text clipping or dead layouts.
- Candidate does not exceed baseline by more than two draw calls in the scoped capture report; any object/node/static-memory growth must be justified.
- No new engine errors, leaks, unmanifested assets, or provenance ambiguity.
- Cues do not rely on hue alone or add flashing/photosensitive effects.

## Acceptance

A candidate may be integrated only when all are true:

1. mechanical gates pass;
2. no frozen invariant changed;
3. matched evidence exists for all three views at all four aspects;
4. root pixel review finds no mechanical visual blocker;
5. a fresh critic returns `accept`, or `revise` findings are repaired within the declared budget;
6. total rubric score is at least 80/100, no category is below 60%, and candidate is a clear improvement rather than merely different;
7. root GPT-5.6 independently reviews the complete diff and reruns the accepted commands.

Human learning, humor, combat feel, art taste, audio mix, motion comfort, photosensitivity comfort, browser playthrough, target-Mac route playthrough, iPad, and physical-controller quality remain open even after automated acceptance.

## Gauntlet graph and budgets

```text
INTAKE
  -> BASELINE_CAPTURE
  -> PARALLEL_READ_ONLY_AUDITS (maximum 4)
  -> ROOT_SYNTHESIS_AND_SCOPE_FREEZE
  -> ONE_ISOLATED_SPARK_WRITER
  -> ROOT_DIFF_AND_MECHANICAL_GATES
      -> REJECT/ROLLBACK when frozen paths or hard gates fail
      -> MATCHED_CANDIDATE_CAPTURE
  -> FRESH_BLIND_ARTIFACT_CRITIC
      -> ACCEPT
      -> REVISE -> SAME WRITER once with exact findings
      -> REJECT/BLOCKED -> ROOT adjudication
  -> ROOT_INTEGRATION
  -> FOCUSED + ROOT VERIFICATION
  -> LEDGER + COMMIT + PUSH
  -> HUMAN STOP
```

- Maximum four concurrent read-only Spark auditors.
- Exactly one implementation writer for this coupled opening slice.
- Default one repair return to the same writer; a second return requires root evidence that the remaining gap is both material and within scope.
- Maximum three Spark implementation/repair calls total.
- Check GPT/Spark capacity after baseline/audit synthesis and after candidate criticism.
- Stop on model limit, non-reproducible evidence, unrelated dirty work, protected material, frozen-path need, repeated engine leak/error, no clear improvement, or diminishing returns.

## Worker result contract

Every worker must return:

```yaml
work_id:
model_seen_in_startup_metadata:
baseline_commit:
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
commit: null
```

Workers do not merge, push, promote baselines, edit final PRD status, or claim human/device evidence.

## Root verification floor

At minimum, after integration:

```bash
bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/salmon_creek_encounter_pacing_test.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/test_episode_1_level.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/unit/visual_capture_manifest_test.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd
python3 tools/validate_world_class_docs.py
bash tools/architecture_check.sh
bash tools/asset_ip_scan.sh
```

Run the new focused opening test if added, matched capture/compare commands, and an appropriate scoped rendered performance comparison. Full release/export validation is required only if affected paths warrant it; any existing broader performance gate remains honestly separate.

## Final handback

Report:

- source and integration commits;
- changed paths and why;
- baseline/candidate/critic evidence paths;
- exact commands and real outcomes;
- rubric score and largest residual gap;
- performance delta;
- rejected alternatives;
- remaining human/device gates;
- next dependency-safe packet.
