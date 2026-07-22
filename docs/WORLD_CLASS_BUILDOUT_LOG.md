# World-Class Buildout Log

This is the durable continuation ledger for the Cobie Nukem 3/6/9 quality program. New Hermes, Codex, or human sessions read this file after `AGENTS.md`, `docs/PRD.md` §1.5, and `docs/IMPLEMENTATION_PLAN.md`. Chat history is not a source of truth.

## Current state

- **Program branch:** `hermes/world-class-369-buildout`
- **Baseline source:** `4dbbe2e8571efec290ed863415a78f09bc970ca9`
- **Public baseline declared by roadmap:** `0.11.0-alpha.1-rc1`, gameplay/runtime `3c2de29`
- **Current packet:** WCB-008 — Mission-specific visual and audio identity
- **Last verified packet:** WCB-007 Towmaster combat/presentation/reset/capture matrix and packaged Web/macOS validation pass
- **Next dependency-safe packet:** WCB-008 only — Rain City Visual Foundry/audio paths declared in the implementation plan; WCB-007 boss paths remain frozen
- **Toolchain state:** Godot 4.7.1 and matching export templates are installed; automated import, tests, and export validation pass. Optional Blender/MCP production-art tooling remains unavailable and is recorded below.
- **Human-only gates:** target-Mac feel/playthrough, physical iPad, flight stick, art taste, pacing, mix, fairness, humor, motion comfort, photosensitivity

## Milestone dashboard

| Packet | State | Owner | Integrated commit | Verification | Honest boundary |
| --- | --- | --- | --- | --- | --- |
| WCB-000 Governance | COMPLETE | Integration/docs | `6b8077a` | Diff/link/validator/reviews pass | No gameplay claim |
| WCB-001 Toolchain baseline | COMPLETE | Architecture | `4479e2f` | Godot 4.7.1 import/tests/exports pass | Optional art MCP tooling is not ready |
| WCB-002 Input ownership | COMPLETE | Input/player seam | `1b1579f`, `f8a78e5` | Service + real player-boundary tests + packaged exports pass | Physical joystick remains unverified |
| WCB-003 Checkpoint invariants | COMPLETE | Save/mission runtime | `23a657d`, `f8a78e5` | Real controller order + boss write policy + progression + packaged exports pass | Manual continues remain open |
| WCB-004 Settings/allocation | COMPLETE | UI + combat | `5ce5501`, `5b8ad45`, `502535a`, `f8a78e5` | Runtime reset, shared effects, reuse contamination, performance + packaged exports pass | Headless timing is not rendered GPU evidence |
| WCB-005 Rain City spatial slice | COMPLETE | Level | `8a5a807` | Route/state/navigation/catalog/core + multi-aspect comparison + packaged exports pass | Human pacing, meaningfulness, and landmark readability remain open |
| WCB-006 Encounters | COMPLETE | Enemy/encounter + bounded integration transfer | `e61b73c` | Schema-v3 content/runtime/reset/navigation + 100-cycle soak + packaged exports pass | Human pacing/fairness open |
| WCB-007 Towmaster | COMPLETE | Boss/presentation + bounded integration transfer | `45bf41a` | Three attacks/four phases/two arena states + 100-cycle combat/reset + native comparison + packaged exports pass | Human spectacle/fairness/readability open |
| WCB-008 Art/audio identity | IN PROGRESS | Visual Foundry/audio | working tree after `5dbe291` | First fog/readability + authored barrier slice implemented; focused contracts and 16:9/4:3 captures pass | Full foundry/audio evidence and human art/mix/humor approval open |
| WCB-009 RC evidence/selection | BLOCKED by WCB-008 | Integration/release | — | WCB-005–007 verified | Human/device gates required |
| WCB-010 Second-mission replication | BLOCKED by WCB-009 | Assigned after selection | — | — | Mission-specific human gates required |
| WCB-011 Release identity/roadmap | BLOCKED by WCB-010 | Integration/release | — | — | Publish only an honest candidate |

## Intake evidence — 2026-07-21

### Repository and deployment

- Canonical source is `Louisleh/cobie-nukem`; website repository contains exported Web artifacts rather than reviewable Godot source.
- Audited source commit was clean at `4dbbe2e8571efec290ed863415a78f09bc970ca9`.
- The public build and audited source identify different gameplay revisions. This is not automatically a defect, but every future RC must make the relationship explicit and byte-verifiable.

### Automated evidence available at intake

- Safe-runner shell suite: PASS.
- Python visual-quality suite: 10/10 PASS in 6.96 seconds under the Hermes Python 3.11 environment.
- Repository CI installs Godot 4.7 and runs release validation.
- Fresh local Godot import/gameplay/release validation: BLOCKED because Godot was not installed.

### Precomputed WCB-001 workstation evidence — 2026-07-21

This evidence was collected while WCB-000 remained the active packet to avoid idle installation time. It does not advance WCB-001 or unblock dependent packets before the WCB-000 integration commit.

- Godot `4.7.1.stable.official.a13da4feb` installed at `/opt/homebrew/bin/godot`.
- Matching 4.7.1 export templates installed under `~/Library/Application Support/Godot/export_templates/4.7.1.stable`.
- `bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit`: PASS, clean asset import/editor exit.
- `bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd`: PASS, `PASS: core contract checks`.
- `QA_EXPORTS=1 bash tools/release_validate.sh`: PASS, including packaged export validation; manual UX checklist remains required before release.
- Material Maker 1.7 is installed at `/Applications/Material Maker.app`.
- `bash tools/game_dev_health.sh`: FAIL with four optional production-tool findings: Blender absent, Godot MCP checkout not at the required clean revision, Blender MCP executable absent, and Codex MCP privacy-hardening check incomplete. The same command passed Godot 4.7.1 detection and confirmed no live Godot bridge in the source project. These findings block privileged visual-production tooling claims, not the clean headless Godot import/test/export baseline.
- Homebrew's Blender 5.2.0 cask failed because the official download URL returned HTTP 403. A read-only probe found an official-version mirror, but Blender was not installed from an unverified substitute during this packet.
- Sanitized GPT usage snapshot at 2026-07-21 15:10 PDT: main GPT/Codex 11% used / 89% remaining; GPT-5.3-Codex-Spark 0% used / 100% remaining. The next quota check is due after milestone 2 or before the first large Spark batch.
- Sanitized post-batch snapshot at 2026-07-21 15:44 PDT: main GPT/Codex 13% used / 87% remaining; GPT-5.3-Codex-Spark 19% used / 81% remaining. Spark performed three audits, one governance review, and five bounded writers; the next check is due after WCB-005/006 or before another large batch.

### Product evidence

- Five campaign missions are publicly selectable; Levels 2–5 retain honest `BETA` gates.
- Deterministic repository inventory at the baseline contains 247 GDScript files, 77 scenes, 228 Resources, six weapon Resource files, four weapon scenes, 24 enemy Resource files, 18 enemy scenes, four mission-preview PNGs, eight Vancouver-named WAV files, and ten Rain City Material Maker source graphs.
- `docs/TEST_EVIDENCE.md`, `docs/RELEASE_0_11_0_ALPHA1_RC1_EVIDENCE.md`, and `docs/evidence/rain_city_stabilization_2026-07-16.md` prove substantial automated/runtime production work while explicitly leaving art cohesion, route clarity, encounter/boss feel, mix, and physical-device approval open. The PRD's qualitative gap statements therefore remain review hypotheses, not machine-certified defects.
- Later mission content inherits several earlier enemy/boss scenes and audio cues. Reuse remains acceptable only when intentional and subordinate to a distinct mission identity.

### Correctness/performance risks entering WCB-001

1. Prove that activated custom input profiles drive the real player, not only diagnostics/storage.
2. Prove checkpoint restore order preserves later-mission progression state.
3. Make options reset reapply runtime quality immediately.
4. Measure and bound per-hit effect allocation/object churn.

## Decisions

### D-WCB-001 — Quality before breadth

Freeze new mission, weapon, enemy-variant, economy, and meta-progression breadth until one mission passes the Rain City vertical-slice gates. Existing public betas remain available and honest.

### D-WCB-002 — Rain City is the default definitive slice

Rain City has the strongest existing secondary-lane and urban-interactivity foundation. It is the default target unless WCB-001–004 evidence shows a lower-risk mission would produce a better 15–22 minute slice. Changing this decision requires a recorded comparison, not conversational preference.

### D-WCB-003 — Evidence classes do not collapse

Automated functional, native rendered, packaged Web, simulated tablet, and human-only evidence remain separate. One class cannot silently satisfy another.

### D-WCB-004 — One writer per owned path

Parallel writers use isolated checkouts and non-overlapping ownership. Integration reviews commit objects and reruns tests. Agents do not merge, stamp, deploy, or claim human evidence.

## Packet entry template

Copy this section for every packet before marking it complete.

```md
## YYYY-MM-DD — WCB-### <title>

- Source commit:
- Owner / writer:
- Acceptance condition:
- Files changed:
- Commands and exact results:
- Evidence and class:
- Review findings:
- Human-only/open claims:
- Integrated commit:
- Next dependency-safe packet:
```

## 2026-07-21 — WCB-000 PRD, governance, and continuity

- Source commit: `4dbbe2e8571efec290ed863415a78f09bc970ca9`
- Owner / writer: GPT-5.6 integration/documentation
- Acceptance condition: the active PRD, dependency order, packet ledger, evidence classes, ownership boundaries, and resume protocol form one non-contradictory source-of-truth stack that survives chat/session compaction.
- Files changed: `AGENTS.md`, `docs/PRD.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/WORLD_CLASS_BUILDOUT_LOG.md`, `docs/PHASE_ROADMAP_PRD.md`, `docs/DECISIONS.md`, `docs/design/README.md`, `.agents/skills/cobie-godot-production/SKILL.md`, `tools/validate_world_class_docs.py`.
- Commands and exact results: `git diff --check` → exit 0; `python3 tools/validate_world_class_docs.py` → `WORLD-CLASS DOCS: PASS`; `/Users/orion/.hermes/hermes-agent/venv/bin/python .agents/skills/cobie-spark-orchestration/scripts/verify_spark_setup.py` → exit 0 and `SPARK SETUP: PASS (6 profiles pinned to gpt-5.3-codex-spark)`; read-only `codex exec --model gpt-5.3-codex-spark -c 'model_reasoning_effort="high"' --sandbox read-only ...` review → PASS with no Blocker/Critical/Major issue; its one timeout-consistency Minor was resolved by rerunning the canonical 300-second command.
- Evidence and class: documentation/source review plus `docs/RELEASE_0_11_0_ALPHA1_RC1_EVIDENCE.md`, `docs/TEST_EVIDENCE.md`, `docs/evidence/rain_city_stabilization_2026-07-16.md`, and `docs/RAIN_CITY_LEVEL2_QA_REPORT.md`; no new gameplay, rendered, browser, device, or human approval claim.
- Review findings: the historical roadmap remains release provenance; §1.5 and this ledger now own current product requirements and execution state respectively.
- Human-only/open claims: all product feel, art taste, pacing, fairness, mix, humor, motion comfort, photosensitivity, and physical-device claims remain open.
- Integrated commit: `6b8077a1b4d0bcf6fcffb1c290c53dab1679c0ba` (pushed to `origin/hermes/world-class-369-buildout`).
- Next dependency-safe packet: WCB-001 baseline closure, followed by WCB-002–004.

## 2026-07-21 — WCB-001 Reproducible Godot 4.7 workstation and baseline

- Source commit: `6b8077a1b4d0bcf6fcffb1c290c53dab1679c0ba`
- Owner / writer: GPT-5.6 architecture/integration
- Acceptance condition: a clean Godot 4.7.1 import, canonical test entry point, and Web/macOS export matrix run locally with attributable output; optional privileged art-tool failures are named rather than hidden.
- Files changed: `docs/IMPLEMENTATION_PLAN.md`, `docs/WORLD_CLASS_BUILDOUT_LOG.md`.
- Commands and exact results: `/opt/homebrew/bin/godot --version` → `4.7.1.stable.official.a13da4feb`; `bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit` → exit 0; `bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd` → exit 0 and `PASS: core contract checks`; `QA_EXPORTS=1 bash tools/release_validate.sh` → exit 0 and `Automated release validation passed`; `bash tools/game_dev_health.sh` → exit 1 with four named optional visual-tool findings and both Godot/source-bridge safety checks passing.
- Evidence and class: automated functional and packaged export evidence. No native rendered playthrough, browser interaction route, physical device, joystick, or human approval claim.
- Review findings: Godot 4.7.1, matching export templates, and Material Maker 1.7 are available. Blender and the privileged Godot/Blender MCP paths are not ready, so visual-production packets must repair/re-audit them before use. This does not block WCB-002–004's headless gameplay/correctness work.
- Human-only/open claims: target-Mac feel/playthrough, physical iPad, flight stick, art taste, pacing, fairness, mix, humor, motion comfort, and photosensitivity remain open.
- Integrated commit: `4479e2f5bad607d6c264bd4787fe99e64df7c38e` (pushed to `origin/hermes/world-class-369-buildout`).
- Next dependency-safe packets: WCB-002, WCB-003, and the non-overlapping settings/allocation halves of WCB-004.

## 2026-07-21 — WCB-002 Effective input-profile ownership

- Source commit: `4479e2f5bad607d6c264bd4787fe99e64df7c38e`
- Owner / writer: isolated GPT-5.3-Codex-Spark writer; GPT-5.6 integration review/amendment
- Acceptance condition: a deliberately non-default profile drives the real player and pause consumer for movement, look, jump, run, primary/secondary fire, use, reload, weapon switching, and pause without editing `project.godot`.
- Files changed: `scripts/input/input_manager_service.gd`, `scripts/input/player_input_adapter.gd`, `scripts/player/player_controller.gd`, `scripts/ui/pause_menu.gd`, `tests/unit/input_system_test.gd`, `tests/integration/input_profile_service_boundary_test.gd`, and sidecar UIDs; contract recorded in `docs/design/input.md`.
- Commands and exact results: input unit → `PASS: input profiles, calibration math, and diagnostics scene`; player-boundary integration → `INPUT PROFILE SERVICE BOUNDARY TEST: PASS`; integrated core → `PASS: core contract checks`; `player_controller.gd` → 499 lines under the 500-line gate; combined matrix exit `0` for all commands.
- Evidence and class: automated synthetic event and real player-scene boundary. A press/release jump tap between physics ticks is explicitly covered.
- Review findings: GPT-5.6 added a key-binding type guard, event-latched jump/toggle edges, look and secondary-fire coverage, and fixture cleanup before integration.
- Human-only/open claims: no physical joystick, browser controller, comfort, or feel claim.
- Integrated commit: `1b1579f`.
- Next dependency-safe packet: WCB-005 after WCB-003/004 evidence push.

## 2026-07-21 — WCB-003 Later-mission checkpoint invariants

- Source commit: `4479e2f5bad607d6c264bd4787fe99e64df7c38e`
- Owner / writer: isolated GPT-5.3-Codex-Spark writer; GPT-5.6 integration review/amendment
- Acceptance condition: checkpoint consumption remains payload-only; Mount Hood, Moon, and Ventura call `begin_run()` before progression restore and preserve route/objective/encounter/player state.
- Files changed: `scripts/level/rain_city_checkpoint_state.gd`, `scripts/level/mount_hood_whiteout.gd`, `scripts/level/biome_mission_controller.gd`, checkpoint unit/integration tests, and generated UID; contract recorded in `docs/design/checkpoints.md`.
- Commands and exact results: checkpoint unit → `RAIN CITY CHECKPOINT STATE TEST: PASS`; later-mission integration → `MISSION CHECKPOINT PROGRESSION TEST: PASS`; gauntlet → `FIVE MISSION GAUNTLET: PASS (5 missions, 1200 routes, 1000 checkpoint restores)`; combined matrix exits `0`.
- Evidence and class: automated functional evidence includes 100 post-`begin_run` progression cycles for each later mission, one full controller/player restore per mission, and the existing 1,000 route checkpoint restores.
- Review findings: GPT-5.6 added exact cycle coverage and a single-active-encounter assertion before integration.
- Human-only/open claims: no manual continue/playthrough or reward-feel claim.
- Integrated commit: `23a657d`.
- Next dependency-safe packet: WCB-005 after WCB-004 evidence push.

## 2026-07-21 — WCB-004 Runtime settings and combat allocation budget

- Source commit: `4479e2f5bad607d6c264bd4787fe99e64df7c38e`
- Owner / writers: three isolated GPT-5.3-Codex-Spark packets (settings, Fetch pool, impact pool); GPT-5.6 architecture, adversarial review, amendments, integration
- Acceptance condition: defaults reapply runtime listeners immediately; Fetch shots and impact presentation use bounded reuse with fixed creation counts and no monotonic node growth after warm-up.
- Files changed: `scripts/core/settings_manager.gd`, `scripts/core/quality_manager.gd`, `scripts/core/projectile_pool.gd`, `scripts/combat/fetch_launcher.gd`, `scripts/combat/fetch_projectile.gd`, `scripts/combat/weapon_base.gd`, `scripts/combat/impact_effect_pool.gd`, focused tests/profiles and UIDs; contract recorded in `docs/design/performance-accessibility.md`.
- Commands and exact results: settings → `PASS: settings reset runtime contract`; Fetch → `FETCH PROJECTILE POOL TEST: PASS`; combat → `COMBAT TESTS: PASS`; soak → `VERTICAL SLICE SOAK: PASS (100 routes, 100 checkpoints, 100 twin-stick cancellations, 500 weapon transitions, 100 effects)`; performance smoke covered five missions with all focused-matrix P95 values below 23 ms and no monotonic node drift; combined matrix and core exits `0`; `QA_EXPORTS=1 bash tools/release_validate.sh` → exit `0`, `Automated release validation passed` after the 499-line extraction.
- Evidence and class: automated functional/headless timing. Fetch capacity pressure does not create overflow objects; the player owns one shared 20-root impact pool below the Web decal budget of 32, and tests inspect real node/resource IDs, full teardown, and mutable projectile-state reset across reuse.
- Review findings: GPT-5.6 rejected false-green async timing, removed double-counted/unbounded Fetch overflow, made pool return synchronous, added pressure tests, removed per-hit destination-array allocation, moved impact prewarm to live weapons, and fixed ObjectDB/RID teardown leaks.
- Human-only/open claims: headless timing is not rendered GPU evidence; Web/iPad/native feel, thermals, and photosensitivity remain open.
- Integrated commits: `5ce5501`, `5b8ad45`, `502535a`.
- Next dependency-safe packet: WCB-005 after release/export validation and evidence push.

## 2026-07-21 — WCB-002–004 corrective acceptance pass

- Source commit: `502535a` plus the current reviewed working tree.
- Owner / writer: GPT-5.6 architecture, adversarial review, correction, and integration.
- Acceptance condition: eliminate false-green async tests; prove the custom profile at real player/pause boundaries; enforce progression-before-runtime/player checkpoint order; define safe boss continuation; make options reset affect live player feedback; and bound combat allocation through shared, measurable reuse.
- Files changed: input adapter/service/axis latch and boundary tests; later-mission controllers/checkpoint policy and real-order probes; player runtime settings/tactile feedback; shared player impact service/pool tests; Fetch mutable-state reset and pool tests; associated design/ledger files.
- Commands and exact results: input unit → `PASS: input profiles, calibration math, and diagnostics scene`; player boundary → `INPUT PROFILE SERVICE BOUNDARY TEST: PASS`; checkpoint unit → `RAIN CITY CHECKPOINT STATE TEST: PASS`; later-mission progression → `MISSION CHECKPOINT PROGRESSION TEST: PASS`; settings reset → `PASS: settings reset runtime contract`; combat → `COMBAT TESTS: PASS` with no ObjectDB/RID leak warning; Fetch pool → `FETCH PROJECTILE POOL TEST: PASS`; projectile profile → `PROJECTILE PERFORMANCE PROFILE: PASS` with recorded rendered-frame samples 13.155, 15.975, 20.957, and 16.261 ms; core → `PASS: core contract checks`; combined status `0`; `QA_EXPORTS=1 bash tools/release_validate.sh` → exit `0`, `Automated release validation passed` after Web/macOS package creation.
- Evidence and class: automated functional/headless evidence. Custom fire/use/weapon switching and axis hysteresis run through the real player scene; Mount Hood/shared biome tests execute the production initialization transaction; impact tests inspect real instance IDs and teardown; Fetch reuse mutates and verifies every mutable exported runtime field.
- Review findings: checkpoint consumption is payload-only; later missions now run `consume -> progression -> mission runtime -> mission restore -> player`. Checkpoint writes return `ERR_BUSY` during active boss combat, so continuation starts from a deterministic pre-boss checkpoint until WCB-007 implements complete phase serialization. Impact effects are one shared player-owned pool rather than one pool per weapon.
- Human-only/open claims: physical joystick/browser-controller feel, manual checkpoint playthrough, rendered native/Web/iPad GPU performance, thermals, motion comfort, and photosensitivity remain open.
- Integrated commit: `f8a78e5293b2dd343ba400840f41761f690e64d1`.
- Next dependency-safe packet: WCB-005 Rain City spatial route authoring and freeze.

## 2026-07-21 — WCB-005 Rain City spatial-route freeze

- Source commit: `58d7058` plus the current reviewed working tree.
- Owner / writers: GPT-5.6 architecture, implementation, visual review, and integration; four broad GPT-5.3-Codex-Spark audits produced no final summary and are not cited; one bounded final Spark diff review reported no blockers and one non-progressive-revisit coverage gap, which was closed.
- Acceptance condition: preserve the continuous lower route while providing three two-ended vertical loops, at least two baked elevations, two cross-zone sightlines, a terminal-powered state change, a prior-zone revisit with new access, four stable interaction-backed secrets, and opening/mid/finale landmark anchors without moving presentation into collision/navigation ownership.
- Files changed: `scripts/level/rain_city_spatial_route_builder.gd`, Vancouver world/mission controllers, route/interaction resources, route/mission/capture tests, `docs/design/rain-city-route.md`, D-019, toolchain truth, and the repository Visual Foundry capture-environment pitfall.
- Commands and exact results: editor import → exit `0`; route production → `VANCOUVER ROUTE PRODUCTION TEST: PASS`; route foundation → `Vancouver route foundation test PASS`; mission host → `VANCOUVER MISSION HOST TEST: PASS`; interaction catalog → `VANCOUVER INTERACTION CATALOG TEST: PASS`; content contract → `VANCOUVER CONTENT CONTRACT TEST: PASS`; visual manifest → `VISUAL CAPTURE MANIFEST TEST: PASS` after correcting its stale 14-view expectation to the manifested 15; core → `PASS: core contract checks`.
- Packaged validation: `QA_EXPORTS=1 bash tools/release_validate.sh` → exit `0`, `Automated release validation passed` after the adversarial suite, 100-cycle soak, 79-scene/183-resource smoke load, performance checks, Web export, and macOS ZIP export.
- Visual evidence: clean `58d7058` was imported in an isolated worktree and recaptured at 1280×720 and 1024×768; the working tree was captured with the same canonical `vancouver_waterfront` staging. `tools/visual_quality/compare.sh` → PASS with perceptual MAE `0.001790` (16:9) and `0.001635` (4:3). The candidate visibly adds the cyan powered-route panel without HUD clipping; the panel remains blockout-level and landmark silhouettes remain weak. Capture teardown reports one `ParticlesShaderGLES3`/RID leak warning and is not treated as clean renderer evidence.
- Evidence and class: automated functional, collision-ray, navigation, restore-state, route-graph, and deterministic image-difference evidence. The optional revisit edge is behaviorally tested to leave ordered objective/checkpoint progression at `terminal_service`.
- Human-only/open claims: 15–22 minute first-playthrough timing, meaningful combat payoff of loops/shortcut, ten-second landmark recognition, readability/taste, target-Mac/iPad feel, and renderer-leak attribution. The captures are review prompts, not visual approval.
- Integrated commit: `8a5a807f36f7e9cba776ab00a98ff3c95309a4c5`.
- Next dependency-safe packet: WCB-006 encounter choreography only.

## 2026-07-21 — WCB-006 Rain City encounter choreography

- Source commit: `0d8a0b0321bd6aa5af8c10611c0933813ecbec12`.
- Owner / writers: GPT-5.6 architecture, encounter cards, review, correction, integration, and evidence; four explicitly pinned GPT-5.3-Codex-Spark read-only audits; one isolated schema writer; two non-overlapping encounter-content writers; two final read-only Spark reviewers.
- Acceptance condition: each of the four pre-boss fights declares and runs at least three existing roles, two approach directions, a recovery lane, one environment-dependent choice, and an authored reveal/ambush/reposition/reinforcement transition; the existing six-role, 26-enemy mission budget, attacker caps, navigation recovery, checkpoint semantics, optional-secret reduction, and four-wave external harbour boundary remain deterministic through 100 complete pre-boss route/reset cycles.
- Owned paths: Vancouver encounter resources, new Rain City choreography-profile resources, focused encounter tests, `docs/design/rain-city-encounters.md`, and encounter contract/ledger files. Integration temporarily owns the additive shared seam in `scripts/gameplay/encounter_choreography_profile.gd`, `encounter_definition.gd`, and `encounter_runner.gd`, plus the exact-ID secret-reduction seam in `scripts/level/rain_city_secret_policy.gd`. No `scripts/ai/`, boss, presentation, route-geometry, project, export, or release ownership is transferred.
- Files changed: typed choreography profile/schema/runner metadata; five Rain City choreography resources and five schema-v3 encounter definitions; exact-ID terminal-secret reduction and tests; 100-cycle production-resource soak; route-foundation schema assertion; encounter cards, design index/contract, implementation plan, and this ledger. Enemy AI, boss behavior, presentation, route geometry, project/export configuration, and release ownership were unchanged.
- Commands and exact results: Godot editor import → exit `0`; choreography profile unit → `ENCOUNTER CHOREOGRAPHY PROFILE TEST: PASS`; production-resource soak → `RAIN CITY ENCOUNTER CHOREOGRAPHY TEST: PASS (5 profiles, 6 roles, 26 actors, 100 pre-boss route/reset cycles)`; content contract → `VANCOUVER CONTENT CONTRACT TEST: PASS`; exact-ID secret policy → exit `0` and `RAIN CITY SECRET POLICY TEST: PASS` with intentional error logs for malformed negative fixtures; external wave → `EXTERNAL WAVE ENCOUNTER TEST: PASS`; moving-set-piece coordinator → `MOVING SET PIECE ENCOUNTER COORDINATOR TEST: PASS`; mission runtime → `MISSION RUNTIME CONTRACT TEST: PASS`; route foundation → `Vancouver route foundation test PASS`; mission host → `VANCOUVER MISSION HOST TEST: PASS`; route production → `VANCOUVER ROUTE PRODUCTION TEST: PASS`; checkpoint state → `RAIN CITY CHECKPOINT STATE TEST: PASS`; production navigation → PASS with 112 polygons, 41-point cross-zone path, and all three bounded recovery reasons; enemy contracts → PASS; core → `PASS: core contract checks`; docs → `WORLD-CLASS DOCS: PASS`; `QA_EXPORTS=1 bash tools/release_validate.sh` → exit `0`, `Automated release validation passed` after the full scripted matrix, scans, performance smoke, Web export, and macOS ZIP export.
- Evidence and class: automated schema/resource, functional runtime, reset/timer, route-graph, navigation-recovery, soak, performance-smoke, content/IP/architecture, and packaged export evidence. Headless timing is not rendered GPU evidence; no manual playthrough or device approval is claimed.
- Review findings: root corrected four role/approach labels, replaced positional `pop_back()` secret behavior with exact-ID fail-closed reduction, reconciled reduced-profile roles/approaches without mutating source resources, and updated the stale route schema-v2 assertion. The final content reviewer reported `NO BLOCKERS`. The final schema reviewer raised two pre-existing checkpoint temporal-continuity findings that remain intentionally owned by WCB-007's phase serialization policy; root accepted and closed its two additive findings by rejecting unsupported schema versions and propagating authored counterplay metadata to actors. Its low malformed-runtime-spawn and isolated-fixture concerns are covered by definition validation plus real-resource tests and did not require runtime hot-reload scope.
- Human-only/open claims: pacing, fairness, practical recovery-lane usability, role readability under final presentation, environment-choice meaningfulness, 15–22 minute route timing, and physical-device feel remain open.
- Integrated commits: `e680bc5`, `e9c5257`, `baffeb2`, `f7fa600`, `44242d1`, `15b5870`, and `e61b73c`, pushed to `origin/hermes/world-class-369-buildout`.
- Next dependency-safe packet: WCB-007 Municipal Towmaster production boss only.

## 2026-07-21 — WCB-007 Municipal Towmaster production boss

- Source commit: `cf8c5d5906d7431d0be674dae794122ea3c697de`.
- Owner / writers: GPT-5.6 architecture, art direction, integration, review, evidence, and final claims; bounded non-overlapping GPT-5.3-Codex-Spark workers may implement/test Godot-only packets after this brief is frozen.
- Acceptance condition: preserve the existing project-original Towmaster GLB/source provenance and transactional four-module/four-wave/1,000-HP boss contract while adding three geometrically distinct telegraphed attacks, four escalating readable phases, two explicit arena threat states, bounded reduced-flash/motion-aware VFX, deterministic reset/cleanup, and a 10–11 second ordered defeat payoff; 100 boss/reset cycles and native 16:9/4:3 capture validity must pass while fairness, spectacle, readability, mix, and photosensitivity remain human gates.
- Owned paths: `scenes/set_pieces/citation_convoy.tscn`, `scripts/level/citation_convoy_actor.gd`, `scripts/level/rain_city_convoy_presentation.gd`, new `scripts/level/towmaster_*`, `resources/set_pieces/vancouver_citation_convoy.tres`, `resources/set_pieces/vancouver_convoy_phases/`, new `resources/set_pieces/towmaster_*`, `tests/integration/rain_city_convoy_boss_test.gd`, the bounded visual capture manifest/adapter/test seam, `docs/design/rain-city-towmaster.md`, this plan, and this ledger. Enemy AI, encounter resources, route geometry/navigation, new audio assets, project/export settings, progression, and release identity are excluded.
- Start-gate evidence: Godot `4.7.1` and Material Maker `1.7` detected; clean repository/no live bridge confirmed. Visual Foundry verifier and `game_dev_health.sh` fail only on the recorded optional Blender/MCP/Chrome capability stack. Existing `assets/source/blender/municipal_towmaster.blend` and `assets/models/set_pieces/municipal_towmaster.glb` remain manifested project-original assets; no new Blender authoring/export or live-MCP evidence will be claimed.
- Human-only/open claims: silhouette dominance at intended combat distance, attack/phase readability, fairness, recovery-lane usability, perceived weight, ten-second spectacle, humor, mix, motion comfort, photosensitivity, target-Mac feel, and physical-iPad behavior.
- Implemented paths: typed `TowmasterAttackDefinition`, `TowmasterPhaseCombatDefinition`, and `TowmasterCombatProfile` resources; pure `TowmasterCombatGeometry`; production `CitationConvoyActor` attack/arena/defeat runtime; bounded `TowmasterHazardVisual`; `RainCityConvoyPresentation` stop-only target/cue/caption/generation seam; production scene warning lights, arena fields, core beacon, and bounded particles; dedicated combat soak; mission-host lifecycle assertions; release-validator registration; and deterministic visual capture manifest/adapter coverage.
- Spark/integration review: bounded profile, actor, host, test, and capture packets were independently reviewed before cherry-pick. The final read-only adversarial review returned `FINAL VERDICT: NO BLOCKERS`. Root accepted and fixed its stop-state/generation lifecycle findings; production mission-host assertions now prove combat disabled while moving, enabled at every authored stop, disabled after phase advance/defeat, and disabled during checkpoint path restart.
- Functional evidence:
  - `RAIN CITY TOWMASTER COMBAT TEST: PASS (3 attacks, 4 phases, 2 arena changes, 100 reset cycles, 10.2s defeat)`.
  - `RAIN CITY CONVOY BOSS SOAK TEST: PASS` for four external waves/modules, exact 1,000-HP budget, reset/retry, stale generation, one completion, and completed-wreck restore.
  - `VANCOUVER MISSION HOST TEST: PASS`, including production stop/move/checkpoint combat gating.
  - `VISUAL CAPTURE MANIFEST TEST: PASS`; Python visual-quality suite 10/10 PASS.
  - `ARCHITECTURE CHECK: PASS`; actor split to 498 lines plus a 55-line pure geometry helper rather than suppressing the 500-line limit.
  - Mandatory editor import and core contract suite PASS on final code revision `45bf41acb23fa018bf03f16a65552194aa03446f`.
- Visual evidence:
  - Pre-WCB-007 static baseline reconstructed from exact source `cf8c5d5` with a temporary uncommitted static staging adapter at `/tmp/cobie-wcb007-baseline-captures/cf8c5d5-static`.
  - Canonical candidate captured from the production adapter at `/tmp/cobie-wcb007-candidate-captures/460c111-candidate` for `1280x720` and `1024x768`; both PNGs were non-empty and visually inspected.
  - `env -u PYTHONPATH -u VIRTUAL_ENV bash tools/visual_quality/compare.sh --baseline /tmp/cobie-wcb007-baseline-captures/cf8c5d5-static --candidate /tmp/cobie-wcb007-candidate-captures/460c111-candidate --out /tmp/cobie-wcb007-comparison --view rain_city_towmaster --aspect 1280x720 --aspect 1024x768`: PASS, no hard failures. Review warnings were intentional deltas: MAE `0.007904` / perceptual `0.005635` at 16:9 and MAE `0.009027` / perceptual `0.006248` at 4:3. Automated differences were treated as review prompts; root inspection confirmed correct boss HUD/objective, three-vehicle silhouette, red impound field, amber sweep lane, emissive final core, and no severe clipping.
  - Each native capture still emits the recorded teardown warning for one `ParticlesShaderGLES3` and one GLES shader RID; captures complete successfully, but renderer evidence is not clean.
- Release evidence: `QA_EXPORTS=1 bash tools/release_validate.sh` on `45bf41a` exits `0`; complete tests, architecture/IP/content scans, five-mission gauntlet, adversarial/soak/performance smoke, Web export, and macOS ZIP export pass. The first attempt on `2f84bb4` correctly failed the 500-line architecture limit and is not counted as pass evidence.
- Integrated commits: `2a562bf` (brief), `d9ef81b` (profile), `ca69296` (actor/arena), `b6939ec` (host presentation), `0fa9fb4` (combat evidence), `48d8f56` (hazard/core readability), `460c111` (capture staging), `2f84bb4` (lifecycle hardening), `45bf41a` (architecture-compliant geometry split).
- Remaining human gates: ordinary-distance silhouette dominance, telegraph fairness and readability, recovery-lane usability, perceived weight, full ten-second spectacle, humor, final audio mix, motion comfort, photosensitivity, target-Mac playthrough, and physical iPad behavior. No manual/device approval is claimed.
- Next dependency-safe packet: WCB-008 only; WCB-007 boss paths are frozen unless regression repair is explicitly transferred.

## 2026-07-22 — WCB-008 Rain City readability and authored-gate slice

- Source commit: `5dbe291985b8c82f5ffc28b32f9a274b2141d3cd` plus the current reviewed working tree.
- Owner / writers: GPT-5.6 architecture, implementation, visual review, verification, and integration; four pinned GPT-5.3-Codex-Spark read-only audits for visual, audio, evidence, and independent contract review; final GPT-5.6-sol/high adversarial review through Codex CLI `0.145.0`.
- Acceptance condition: remove the full-frame fog flattening and opaque collision-debug slabs visible in the canonical Rain City waterfront view; preserve every route gate's collision shape/layer, route-state metadata, navigation ownership, and builder-controlled open/close lifecycle; prove the two Rain City hero enemies are dedicated behavior/visual paths rather than renamed base scenes; create deterministic 16:9/4:3 review evidence without touching frozen WCB-007 boss paths.
- Files changed: five `resources/presentation/vancouver_*_presentation.tres` profiles; `scripts/level/rain_city_material_applier.gd`; Rain City content/route production integration tests; `docs/IMPLEMENTATION_PLAN.md`, `docs/VERTICAL_SLICE_SCORECARD.md`, and this ledger.
- Commands and exact results: Godot 4.7.1 headless editor import → exit `0`; `res://tests/run_tests.gd` → `PASS: core contract checks`; `res://tests/integration/vancouver_content_contract_test.gd` → `VANCOUVER CONTENT CONTRACT TEST: PASS`; `res://tests/integration/rain_city_route_production_test.gd` → `VANCOUVER ROUTE PRODUCTION TEST: PASS`; `python3 tools/validate_world_class_docs.py` → `WORLD-CLASS DOCS: PASS`; `QA_EXPORTS=1 bash tools/release_validate.sh` → exit `0`, `Automated release validation passed` after the complete registered test matrix, 79-scene/189-resource smoke load, adversarial/soak/performance checks, Web export, and macOS ZIP export.
- Visual evidence: baseline `/tmp/cobie-wcb008-baseline/5dbe291-baseline` and final candidate `/tmp/cobie-wcb008-candidate/authored-gates-pass` each captured `vancouver_waterfront` at `1280x720` and `1024x768` with fixed manifest seed/frame; candidate `capture_report.json` records no failures. Fog-only comparison exits `0` with no hard failures and perceptual MAE `0.060867` / `0.059786`; authored-gate comparison exits `0` with no hard failures and perceptual MAE `0.005747` / `0.007077`. Automated differences are review prompts, not quality approval.
- Evidence and class: automated functional, collision/presentation ownership, idempotence, hero-enemy structure, import, architecture/IP/content, soak/performance-smoke, packaged Web/macOS export, and deterministic native-rendered image-difference evidence. Root visual inspection found materially clearer value/landmark depth, no HUD clipping, and authored rail barriers replacing dominant opaque slabs at both aspects.
- Review findings: the fog resources were using engine density values `0.12`–`0.27`, which flattened the route; they now use a restrained `0.006`–`0.012` range guarded by a Rain City-specific ceiling. Gate dressing hides only the builder's debug mesh and adds no collision object. The first GPT-5.6-sol/high review found no collision/navigation/route-state defect and requested two governance fixes: return the scorecard to evidence scope with an authoritative roadmap link, and add this exact packet handoff. Both were resolved; the bounded follow-up review reported no remaining blocker and confirmed the code/test change was safe to retain.
- Performance/Web/iPad status: full headless performance smoke and packaged Web/macOS export pass. The gate pass adds five bounded render-only barrier assemblies and no dynamic lights, particles, transparency, process loop, collision, or navigation nodes. Rendered Web trace and physical-iPad thermal/touch evidence remain WCB-009/human gates.
- Human-only/open claims: final foundry/landmark identity, ordinary-distance hero-enemy recognition, humor, combat readability, audio mix and mission signature, motion comfort, photosensitivity, target-Mac route playthrough, physical iPad, and baseline approval. Native captures still emit the recorded one-`ParticlesShaderGLES3`/RID teardown warning and are not clean renderer-leak evidence.
- Integrated commit: pending final diff review/commit.
- Next dependency-safe packet: continue WCB-008 only with the authored foundry/landmark pass, explicit Rain City audio event evidence, remaining canonical aspects/views, and human review packet. WCB-009 remains blocked.

## Resume protocol

1. Read `AGENTS.md`, `docs/PRD.md` §1.5, `docs/IMPLEMENTATION_PLAN.md`, and this current-state section.
2. Run `git status --short --branch`; do not overwrite uncommitted work.
3. Confirm the current packet and dependency state above.
4. Inspect its latest commit/diff and rerun the smallest applicable verification before continuing.
5. Update this log before each milestone commit.
6. If context becomes crowded, stop at a describable verified state and resume from this file—not from an inferred chat summary.
