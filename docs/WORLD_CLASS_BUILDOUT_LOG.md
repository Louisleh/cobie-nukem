# World-Class Buildout Log

This is the durable continuation ledger for the Cobie Nukem 3/6/9 quality program. New Hermes, Codex, or human sessions read this file after `AGENTS.md`, `docs/PRD.md` §1.5, and `docs/IMPLEMENTATION_PLAN.md`. Chat history is not a source of truth.

## Current state

- **Program branch:** `hermes/world-class-369-buildout`
- **Baseline source:** `4dbbe2e8571efec290ed863415a78f09bc970ca9`
- **Public baseline declared by roadmap:** `0.11.0-alpha.1-rc1`, gameplay/runtime `3c2de29`
- **Current packet:** WCB-008 — Mission-specific visual and audio identity
- **Last verified packet:** WCB-008I exact four-aspect borderless route capture, independent dimension/pose/hash binding, twenty-image rendered review, and full release-wrapper/Web/macOS validation
- **Next dependency-safe packet:** WCB-008 continuation only — prepare the named human visual/audio/humor/accessibility review from the exact four-aspect image set and bounded audio evidence; WCB-007 boss paths remain frozen and WCB-009 remains blocked until the declared human prerequisite is recorded
- **Toolchain state:** Godot 4.7.1, Blender 5.2.0 LTS, Material Maker 1.7, and matching Godot export templates are installed; import, functional tests, IP/architecture/content gates, native Compatibility performance, the full release wrapper, and macOS/Web exports pass. Optional Codex/Godot/Blender MCP production-art integrations remain unavailable and are recorded below.
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
| WCB-008 Art/audio identity | IN PROGRESS | Visual Foundry/audio + QA evidence integrity | `5650453`, `eb4539f`, `a506b27`, `827e6c8` | Fog/readability, authored barriers, harbour backdrop, explicit audio events, camera/hash-bound exact four-aspect route evidence, compact HUD safety, native performance, and full Web/macOS release validation pass mechanically | Human art/mix/humor/accessibility approval remains open |
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
- Integrated implementation commit: `229de16c5cde4880a2f06aa6baf47b297615b9f1`.
- Next dependency-safe packet: continue WCB-008 only with the authored foundry/landmark pass, explicit Rain City audio event evidence, remaining canonical aspects/views, and human review packet. WCB-009 remains blocked.

## 2026-07-22 — WCB-008 authored harbour-backdrop slice

- Source commit: `d5639bd`; integrated implementation commit: `152b65d`.
- Owner / writers: GPT-5.6-sol architecture, implementation, native visual review, verification, and integration; three pinned GPT-5.3-Codex-Spark read-only audits for visual identity, audio identity, and UX/performance risk.
- Acceptance condition: make the unlabelled waterfront read as an original rain-soaked harbour city through persistent skyline/mountain/terminal silhouette rather than labels alone; preserve route, crosshair, HUD, combat sightlines, collision/navigation ownership, and the existing 13-batch Web-safe foundry budget; produce deterministic 16:9, 16:10, 4:3, and ultrawide candidate evidence without touching frozen WCB-007 boss paths.
- Implemented work:
  - expanded the deterministic Blender foundry from 216 to 272 source parts while retaining 13 consolidated material batches;
  - added an original broad harbour skyline, facade window-light scale cues, a tall Rainline beacon, and two source-built lightly extruded north-shore ridgelines;
  - replaced reused close-surface materials on skyline/mountain batches with two dedicated restrained distance-silhouette materials;
  - regenerated and manifested both editable `.blend` source and runtime `.glb` with current SHA-256 provenance;
  - extended the asset contract to guard skyline/ridgeline batch presence, production-scale bounds, dedicated material routing, and presentation-only collision separation.
- Visual iteration evidence:
  - v1 at realistic literal scale remained too small to affect the empty-sky composition;
  - v2 enlarged separate cone mountains but was rejected during native review as a crude repeated-pyramid chain;
  - v3 replaced those cones with irregular continuous two-layer profiles and darker distance materials. Four-aspect review retained v3: the route/crosshair/HUD remain clear, the ridgeline frames rather than occludes the terminal, and ultrawide exposes no edge repetition or clipping. Human taste approval remains open.
- Verification:
  - Blender 5.2.0 deterministic build -> `Rain City foundry: parts=272 batches=13`;
  - `res://tests/unit/asset_contract_test.gd` -> `ASSET CONTRACT TESTS: PASS`;
  - `res://tests/integration/vancouver_content_contract_test.gd` -> `VANCOUVER CONTENT CONTRACT TEST: PASS`;
  - `res://tests/integration/rain_city_route_production_test.gd` -> `VANCOUVER ROUTE PRODUCTION TEST: PASS`;
  - `res://tests/run_tests.gd` -> `PASS: core contract checks`;
  - `QA_EXPORTS=1 bash tools/release_validate.sh` initially rejected Blender's unmanifested `.blend1` backup; the generated backup was removed, then the complete validation/export matrix passed, including asset/IP scan plus Web and macOS exports;
  - `/tmp/cobie-wcb008-candidate/harbour-backdrop-final/` contains successful 1280×720, 1680×1050, 1024×768, and 3440×1440 captures;
  - comparison against `authored-gates-pass` exits `0` with no hard failures; perceptual MAE is `0.003288` at 16:9 and `0.003668` at 4:3.
- Human-only/open claims: final unlabelled landmark/district identity, remaining non-boss views, combat-scale recognition, humor, audio mix/signature, motion comfort, photosensitivity, target-Mac route playthrough, physical iPad, and baseline approval. The native capture path still emits the previously recorded one-`ParticlesShaderGLES3`/RID teardown warning on some aspect runs, so this is not clean renderer-leak evidence.
- Next dependency-safe packet: explicit Rain City runtime audio-event evidence for mission state/ambience, Compliance Gull, Umbrella Shield Enforcer, and convoy cues; then remaining non-boss capture views and the human review packet. WCB-009 remains blocked.

## 2026-07-22 — WCB-008 runtime audio-event evidence slice

- Source commit: `fb2002f`; integrated implementation commit: `aeeb303`.
- Owner / review: GPT-5.6-sol implementation, verification, and integration; pinned GPT-5.3-Codex-Spark audio audit identified the precise runtime-evidence gap and mapped every authored event/cue path before implementation.
- Acceptance condition: prove exact runtime event→cue IDs for Vancouver music state, zone ambience, Compliance Gull, Umbrella Shield Enforcer, and citation-convoy identity without starting nondeterministic audio playback in headless CI; retain the real production classes, concrete hero enemy scenes, convoy actor, generation checks, objective/checkpoint completion effects, and normal release matrix.
- Implemented `tests/unit/rain_city_audio_event_contract_test.gd` and registered it in `tools/release_validate.sh`.
  - Mission presentation evidence drives exploration, terminal-zone, encounter tension/combat/completion, harbour boss, and mission-victory events and verifies `vancouver_music_*` plus `vancouver_ambience_*` resolution.
  - Hero-enemy evidence binds concrete Compliance Gull and Umbrella Shield Enforcer scenes, emits their production signals, and verifies mark/dive/death plus shield brace/open/break cue IDs and live spatial positions.
  - Convoy evidence uses the concrete Citation Convoy actor and generation-gated production handlers to verify movement, tow/module break, defeat milestone, and final defeat cues while retaining the canonical objective and harbour-clear checkpoint effects.
- Verification:
  - focused command -> `RAIN CITY AUDIO EVENT CONTRACT TEST: PASS`;
  - `bash -n tools/release_validate.sh` passes;
  - fresh `QA_EXPORTS=1 bash tools/release_validate.sh` includes the new test and passes the complete scripted, smoke, soak, performance, asset/IP, Web-export, and macOS-export matrix.
- Evidence boundary: playback is disabled only inside the music/ambience state-routing test so headless timing cannot masquerade as an audible mix review. Imported WAV/cue data and emitter playback retain their separate passing tests. Final loudness, layering, voice contention, humor, and mission-signature judgment remain human mix gates.
- Next dependency-safe packet: finish the remaining canonical non-boss capture views and assemble the human art/mix/humor/accessibility review packet. WCB-009 remains blocked.

## 2026-07-22 — WCB-008 isolated five-zone capture-evidence slice

- Source commit: `aeeb303`; integrated implementation commit: `5650453`.
- Owner / review: GPT-5.6-sol implementation and integration, native visual review across 4:3/16:9/16:10/ultrawide, and repeated GPT-5.6-sol/high read-only review. Final blocker-only review result: `APPROVE`.
- Acceptance target: register deterministic non-boss views for all five Rain City route zones, capture every canonical aspect without gameplay-event contamination or production save/settings access, fail on unexpected engine diagnostics, and keep human art approval explicitly open.

Implemented:

1. Added canonical `rain_city_downtown`, `rain_city_slice`, `rain_city_terminal`, and `rain_city_harbour` direct-scene views alongside the existing `vancouver_waterfront` view; manifest contracts now require all twenty view/aspect combinations.
2. Route staging freezes level/player simulation, removes collision and non-player actor visibility, clears transient captions, sets the zone-specific objective/caption, and leaves production mission logic untouched outside the capture process.
3. Native and direct capture subprocesses now receive temporary `HOME`, `CFFIXED_USER_HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` roots. A real capture preserved the production checkpoint SHA-256 and user-data file count.
4. Capture now accepts each of the two known Godot renderer teardown diagnostics exactly once and rejects duplicates, near matches, other `ERROR:`, `SCRIPT ERROR:`, ObjectDB/resource leaks, and orphan diagnostics even when Godot exits `0`.
5. Added dependency-free capture isolation/classifier regressions to `release_validate.sh`; Pillow is imported lazily only for actual image copying, so CI gains no new package requirement.
6. Raised the Rain City Slice hero sign above its awning and added a geometric clearance contract. The capture pass also exposed and removed an unsafe `monitoring = false` mutation inside `MiniBallCollectible.body_entered`; repeated clean captures no longer emit that engine error.

Verification:

- `python3 tools/visual_quality/test_capture_tool.py` → four tests pass, including isolated-home launch wiring and bounded fatal-diagnostic classification.
- `res://tests/unit/visual_capture_manifest_test.gd` → `VISUAL CAPTURE MANIFEST TEST: PASS`.
- `res://tests/integration/rain_city_route_production_test.gd` → `VANCOUVER ROUTE PRODUCTION TEST: PASS` with Slice sign/awning clearance guarded.
- `QA_EXPORTS=1 bash tools/release_validate.sh` → complete scripted matrix plus Web/macOS exports pass after the final staging, collectible, and capture-tool changes.
- `/tmp/cobie-wcb008-candidate/rain-city-route-views-clean-final/` → sixteen clean downtown/Slice/terminal/harbour captures at all four aspects; every run reaches 103 frames and emits only the two exact bounded teardown diagnostics.
- `/tmp/cobie-wcb008-candidate/rain-city-waterfront-isolated-final/` → four clean waterfront captures at all four aspects under the same isolated policy.
- GPT-5.6-sol/high review caught and forced fixes for production-user-data inheritance, CI `uv` coupling, unclassified `SCRIPT ERROR:`, unbounded renderer exceptions, and the canonical ObjectDB leak form before returning `APPROVE`.

Decision and remaining gate:

- Canonical Rain City non-boss capture coverage is mechanically complete and trustworthy enough to guide art work; no candidate is promoted to baseline.
- The captures honestly show that downtown, Slice, terminal, and harbour still repeat too much corridor massing, flat facade treatment, and weak unlabelled landmark hierarchy. WCB-008 remains `IN PROGRESS`; the next dependency-safe packet is district-specific landmark/material composition followed by human visual/audio/humor/accessibility review.
- WCB-009 remains blocked. No human, physical-device, or public-artifact approval is inferred.

### WCB-008G route-evidence integrity and fail-closed QA packet — COMPLETE (WCB-008 remains open)

- **Source commit:** `f91975e`
- **Implementation commit:** `eb4539fb64171e63713c458d6164cc52fef1caa9`
- **Writer/integration owner:** GPT-5.6-sol/Hermes
- **Read-only reviewers:** one GPT-5.3-Codex-Spark capture audit, three focused GPT-5.6-sol/high adversarial passes, and one GPT-5.3-Codex-Spark test-harness review. No worker wrote, merged, pushed, or claimed human/device evidence.
- **Acceptance condition:** a Rain City district capture is evidence only when the post-draw screenshot is hash-bound to a validated player/camera/look/FOV receipt, all declared route views are geometrically and low-frequency distinct, and baseline promotion is complete and recoverable. Prior fallback-camera evidence must be invalidated rather than defended.
- **Owned/changed paths:** `scripts/debug/visual_direct_capture.gd`; `tests/unit/visual_capture_manifest_test.gd`; `tools/visual_quality/capture_manifest.json`; `tools/visual_quality/capture_tool.py`; `tools/visual_quality/test_capture_tool.py`; `tests/unit/umbrella_shield_enforcer_test.gd`; `docs/IMPLEMENTATION_PLAN.md`; `docs/VERTICAL_SLICE_SCORECARD.md`; this ledger.
- **Implementation:**
  - direct capture now applies declared player/camera/look/FOV staging, verifies the active camera belongs to the staged player, waits for `frame_post_draw`, saves the exact PNG, and emits an image SHA-256 receipt;
  - the Python runner requires the structured receipt, validates camera and image contracts, rejects blank/hash-mismatched output, compares a HUD-excluding scene ROI with edge IoU plus low-frequency MAE, requires every declared route/aspect before group approval, and promotes complete baselines through a sibling staging/backup transaction with rollback and retained recovery evidence if rollback itself fails;
  - manifest/Godot/Python tests cover complete-group approval, camera ancestry/pose, exact image binding, weather-noise duplicate rejection, transactional promotion, rollback failure retention, and no-write-on-failure;
  - a release-matrix hang exposed unrelated nondeterminism in `umbrella_shield_enforcer_test.gd`; the test now uses actor-local hit geometry, bounded fail-closed shield attempts, physics isolation, known starting states, and deterministic shared-timer callback sequencing. Production enemy paths were not changed.
- **Mechanical verification:**
  1. `python3 tools/visual_quality/test_capture_tool.py` — **PASS**, 11 tests.
  2. `bash tools/run_godot_safe.sh --timeout 120 -- --headless --path . --script res://tests/unit/visual_capture_manifest_test.gd` — **PASS**, `VISUAL CAPTURE MANIFEST TEST: PASS`.
  3. `env -u PYTHONPATH -u VIRTUAL_ENV bash tools/visual_quality/capture.sh --candidate /tmp/cobie-wcb008-candidate --run-id route-evidence-integrity-final --view rain_city_downtown --view rain_city_slice --view vancouver_waterfront --view rain_city_terminal --view rain_city_harbour --aspect 1280x720 --aspect 1024x768` — **PASS**, ten exact post-draw images/receipts; no baseline approval.
     - 16:9 pairwise edge IoU `0.107397`–`0.436021`, low-frequency MAE `0.063798`–`0.139763`.
     - 4:3 pairwise edge IoU `0.119314`–`0.463381`, low-frequency MAE `0.061399`–`0.121410`.
     - report: `/tmp/cobie-wcb008-candidate/route-evidence-integrity-final/capture_report.json`.
  4. Twenty old route images were remeasured and invalidated: 16:9 edge IoU `0.906449`–`0.992621`; 4:3 `0.908159`–`0.991297`; low-frequency MAE `0.004952`–`0.049008`.
  5. OS-temp ad-hoc verifier loop after the umbrella-harness fix — **PASS 30/30**; `/tmp/hermes-verify-umbrella` was removed.
  6. `bash tools/run_godot_safe.sh --timeout 590 -- --headless --path . --editor --quit` and `bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd` — **PASS**.
  7. `bash tools/architecture_check.sh` — **PASS**; `bash tools/asset_ip_scan.sh` — **PASS**; `res://tools/validate_content.gd` — **PASS**, five manifests.
  8. `QA_EXPORTS=1 bash tools/release_validate.sh` was run three times and remains **BLOCKED**, not green: the first run exposed the now-fixed umbrella test hang; the second emitted an intermittent two-object smoke teardown leak that did not recur in five isolated smoke runs; the third passed the functional/smoke matrix and then failed the unchanged headless performance budget. Representative third-run samples: Rain City average `47.853 ms`, p95 `124.320 ms`; Ventura average `59.892 ms`, p95 `147.960 ms`; existing average/p95 limits are `50 ms`. This packet changes no production scene or performance path.
  9. Standalone package fallback required by the release docs — **PASS**:
     - macOS `builds/macos/CobieNukem.zip`, `115791391` bytes, SHA-256 `b0493f2259b59927b9cd4786de96acc9e072149c04d2ba46f4cd3fe6f4dd78bc`;
     - Web `index.html`, `index.js`, `index.pck`, and `index.wasm` exported; `index.pck` SHA-256 `86f6dbc8760e45b2cf56216b9ab38ed2042958043d30db06a40ad568d6857674`, `index.wasm` `35116f68540ac41acf7d71ea457added91b5e960a9cca3e2acc72918eaf01277`.
  10. `bash tools/game_dev_health.sh` and the Visual Foundry toolchain verifier remain **environment-blocked only** by the four absent optional Codex MCP tools (`blender-bridge`, `imagegen`, `godot`, `godot-editor`).
- **Rendered automated evidence:**
  - prior/suspect contact: `/tmp/cobie-wcb008-old-route-contact.png`;
  - final 16:9 contact: `/tmp/cobie-wcb008-1280x720-final-contact.png`;
  - final 4:3 contact: `/tmp/cobie-wcb008-1024x768-final-contact.png`.
  - Pixel review confirms five nonblank, materially distinct route compositions at both aspects. It also exposes a real 4:3 defect: the lower-right ammo count and weapon label are absent/clipped. This is an open mechanical UX gate, not taste approval.
- **Review disposition:** the first high review correctly blocked on unenforced pose fields, weak receipt/image binding, weather-sensitive duplicate detection, and non-transactional approval; the second caught failed-rollback backup deletion; all were fixed and regression-tested. Final GPT-5.6-sol/high review and the focused Spark umbrella-harness review returned **APPROVE** with no blocker/major findings.
- **Evidence classes:** mechanical parser/tests/contracts/capture receipts/metrics/IP/content/architecture/exports; rendered automated contact sheets; **no** human taste, route-feel, mix, accessibility-comfort, photosensitivity, browser-playthrough, target-Mac, iPad, or physical-controller evidence.
- **Usage checkpoint (2026-07-22 19:14 PT):** Main GPT/Codex `54%` remaining; GPT-5.3-Codex-Spark `31%` remaining; reset credits `100%` remaining.
- **Remaining gates / next packet:** WCB-008 remains **IN PROGRESS**. WCB-008H owns the 4:3 HUD safe-area repair, headless performance investigation/rerun, and fresh five-view × four-aspect bound capture set. Human visual/mix/humor/accessibility approval remains open; WCB-009 stays blocked.

### WCB-008H compact HUD safe-area and supported-aspect evidence packet — COMPLETE (WCB-008 remains open)

- **Source commit:** `bb0b9a8`
- **Implementation commit:** `a506b27694a295eb453170f12b2baf5e4c7440b4`
- **Writer/integration owner:** GPT-5.6-sol/Hermes
- **Read-only reviewers:** one GPT-5.3-Codex-Spark HUD audit, one GPT-5.3-Codex-Spark test-integrity audit, and two GPT-5.6-sol/high adversarial reviews. Reviewers did not write, merge, push, or claim human/device evidence.
- **Acceptance condition:** the lower-right HUD remains inside the supported compact 4:3 safe area under real viewport-resize lifecycle events, representative maximum-scale text cannot clip, and all compact access/weapon/ammo/reload regions remain disjoint. Fresh bound 16:9/4:3 captures and release packages must verify the repair; unsupported native receipt dimensions and unchanged performance failures stay open rather than being normalized.
- **Owned/changed paths:** `scripts/ui/hud.gd`; `tests/unit/ui_scene_test.gd`; `docs/IMPLEMENTATION_PLAN.md`; `docs/VERTICAL_SLICE_SCORECARD.md`; this ledger. WCB-007 boss, collision, navigation, mission, art, and audio paths were not changed.
- **Implementation:**
  - `GameHUD` now reads the live viewport during the existing caption/boss resize callback and reapplies one responsive bottom-bar contract;
  - logical widths below `630` receive a compact two-column layout with a `12`-pixel right margin: access on the top row, weapon/reload in the lower-left subcolumn, and ammo in the lower-right subcolumn; desktop coordinates remain unchanged at `630+`;
  - the UI regression instantiates the production HUD in a `SubViewport`, drives the actual `Viewport.size_changed` signal through logical widths `480`, `576`, `619`, `620`, `629`, `630`, `640`, and `860`, stresses `NO ACCESS COLLAR`, `FETCH LAUNCHER`, `99 / 99`, and `RELOADING...` at the clamped `1.5×` accessibility scale, and checks live applied rectangles, global safe area, minimum width/height, font-scale clamping, and all six compact rectangle pairs.
- **Mechanical verification:**
  1. `bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/unit/ui_scene_test.gd` — **PASS**, `UI SCENE TESTS: PASS`.
  2. `bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit` followed by `bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd` — **PASS**, clean import/class registration and `PASS: core contract checks`.
  3. `git diff --check`; `bash tools/architecture_check.sh`; `python3 tools/validate_world_class_docs.py` — **PASS**. Final sizes before ledger closeout: `scripts/ui/hud.gd` `500` lines; `tests/unit/ui_scene_test.gd` `560` lines.
  4. `bash tools/asset_ip_scan.sh` — **PASS**; `res://tools/validate_content.gd` — **PASS**, five manifests.
  5. `env -u PYTHONPATH -u VIRTUAL_ENV bash tools/visual_quality/capture.sh --candidate /tmp/cobie-wcb008-candidate --run-id wcb008h-final-supported --view rain_city_downtown --view rain_city_slice --view vancouver_waterfront --view rain_city_terminal --view rain_city_harbour --aspect 1280x720 --aspect 1024x768` — **PASS**, ten exact post-draw hash-bound images, zero capture failures, no baseline approval. Pairwise low-frequency MAE minimum `0.061397`; edge IoU maximum `0.463361`.
  6. `QA_EXPORTS=1 bash tools/release_validate.sh` — **BLOCKED**, not green: import, visual-isolation tests, the complete unit/integration/smoke matrix, and HUD regression passed; the wrapper then stopped before exports at the unchanged headless performance gate. Samples: Rain City `46.874 ms` average / `123.820 ms` p95; Vancouver `45.605 / 123.614`; Mount Hood `55.830 / 147.291`; Moon `59.134 / 148.003`; Ventura `56.238 / 147.050`, against `50 ms` average/p95 limits. A detached `45bf41a` control also failed similarly (`46.420 / 124.969` Rain City; `59.521 / 147.734` Ventura), so no HUD-caused performance regression is claimed.
  7. Standalone fallback exports required after the wrapper stopped — **PASS**:
     - Web `index.html` `6605` bytes SHA-256 `d3dbb20e89bea4a94d949419130416d03df5c4270303612370a5813fee2d06ef`; `index.js` `279815` bytes SHA-256 `68586d6daafc93c6e697b3fb258976874aa7459b8931165ebb1dc3c9614cc42c`; `index.pck` `69796692` bytes SHA-256 `1a52444074a725fbf3610345c8ade99a36676a01bcf915198baf1261076b395b`; `index.wasm` `39513091` bytes SHA-256 `35116f68540ac41acf7d71ea457added91b5e960a9cca3e2acc72918eaf01277`;
     - macOS `builds/macos/CobieNukem.zip`, `115792291` bytes, SHA-256 `771407d45d930fbcd5c0debfece1a5cffafc88740b855c431162b9cd41055871`; ZIP integrity and forbidden-marker pack scans passed.
  8. `bash tools/game_dev_health.sh` and the Visual Foundry verifier remain **environment-blocked only**: Godot, Blender 5.2.0 LTS, Material Maker, and source-project bridge hygiene pass, while the optional Godot/Blender/Chrome/context MCP integrations are missing or not privacy-hardened.
- **Rendered automated evidence:**
  - report: `/tmp/cobie-wcb008-candidate/wcb008h-final-supported/capture_report.json`;
  - final 16:9 contact: `/tmp/cobie-wcb008h-final-supported-1280x720-contact.png`;
  - final 4:3 contact: `/tmp/cobie-wcb008h-final-supported-1024x768-contact.png`.
  - Pixel inspection of every final image found five nonblank/correct route views at each aspect and no mechanical portrait/health/armor/access/weapon/ammo/objective/crosshair/caption clipping or overlap. This is rendered automated evidence, not taste approval.
- **Four-aspect blocker:** the current `1920×1080` macOS workspace clamps requested native `1680×1050` captures to `1484×928` and `3440×1440` captures to `1800×753`; WCB-008G correctly rejects both dimension-mismatched receipts. The logical 16:10 (`576`) and ultrawide (`860`) branches pass the maximum-scale lifecycle regression, but automation is not substituted for missing native rendered receipts. The report therefore honestly marks `rain_city_non_boss_routes.complete = false`.
- **Review disposition:** the first high review rejected boundary overlap at `620–629`, a direct-call false green, missing height checks, and untested compact pairs. All were fixed. Final GPT-5.6-sol/high review returned **APPROVE — no actionable findings**, with only the recorded four-aspect/source-binding/maximum-scale-rendered residual risks.
- **Evidence classes:** mechanical parser/tests/contracts/capture receipts/metrics/IP/content/architecture/exports; rendered automated contact sheets; **no** human taste, route-feel, mix, humor, accessibility-comfort, photosensitivity, browser-playthrough, target-Mac, iPad, or physical-controller evidence.
- **Remaining gates / next packet:** WCB-008 remains **IN PROGRESS** and WCB-009 remains blocked. Next, produce exact native 1680×1050 and 3440×1440 receipts through a capable display or isolated capture path without weakening receipt validation, then prepare the named human visual/audio/humor/accessibility review. The unchanged headless performance budget remains separately open.

### WCB-008I exact four-aspect borderless route evidence packet — COMPLETE (WCB-008 remains open)

- **Source commit:** `05019241d08721c5ee73f371d198f081c0f24245`
- **Implementation commit:** `827e6c8ab71c96639936309a97ed069f8fa7df56`
- **Writer/integration owner:** GPT-5.6-sol/Hermes
- **Read-only reviewers:** two GPT-5.3-Codex-Spark audits (root cause/test integrity and final evidence consistency) plus one GPT-5.6-sol/high adversarial diff review. Reviewers did not write, merge, push, or claim human/device evidence.
- **Acceptance condition:** on the current 1920×1080 macOS host, a desktop-safe 1280×720 decorated bootstrap must transition to a borderless exact target before production-scene instantiation and produce post-draw, pose/hash-bound five-route receipts at 1280×720, 1680×1050, 1024×768, and 3440×1440. Requested/window/viewport/decoded-PNG dimensions must agree exactly; unsupported behavior fails closed.
- **Owned/changed paths:** `scripts/debug/visual_direct_capture.gd`; `tools/visual_quality/capture_tool.py`; `tools/visual_quality/test_capture_tool.py`; `docs/IMPLEMENTATION_PLAN.md`; `docs/VERTICAL_SLICE_SCORECARD.md`; this ledger. No gameplay, collision, navigation, mission, art, audio, WCB-007 boss, production HUD, or baseline image path changed.
- **Implementation:**
  - direct capture boots at a desktop-safe 1280×720 instead of the requested oversized decorated resolution, then switches borderless and applies the requested target before production-scene instantiation;
  - the capture host records and fails on requested/window/viewport dimension drift or loss of borderless state;
  - the Python tool independently verifies receipt sizes, borderless state, decoded PNG dimensions, camera pose, active camera ancestry, and SHA-256 before copying any evidence;
  - tests distinguish bootstrap from target size and reject both forged receipt dimensions and a correctly declared/hash-bound receipt backed by a wrongly sized PNG.
- **Mechanical verification:**
  1. `env -u PYTHONPATH -u VIRTUAL_ENV python3 tools/visual_quality/test_capture_tool.py` — **PASS**, 11 tests.
  2. `bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit`; `res://tests/unit/visual_capture_manifest_test.gd`; `res://tests/unit/ui_scene_test.gd`; `res://tests/run_tests.gd` — **PASS**, clean import plus `VISUAL CAPTURE MANIFEST TEST: PASS`, `UI SCENE TESTS: PASS`, and `PASS: core contract checks`.
  3. `git diff --check`; `bash tools/architecture_check.sh`; `python3 tools/validate_world_class_docs.py`; `bash tools/asset_ip_scan.sh`; `res://tools/validate_content.gd` — **PASS**, including five manifested asset families.
  4. `env -u PYTHONPATH -u VIRTUAL_ENV bash tools/visual_quality/capture.sh --candidate /tmp/cobie-wcb008-candidate --run-id wcb008i-final-four-aspect --view rain_city_downtown --view rain_city_slice --view vancouver_waterfront --view rain_city_terminal --view rain_city_harbour --aspect 1280x720 --aspect 1680x1050 --aspect 1024x768 --aspect 3440x1440` — **PASS**, twenty exact images, twenty independent receipts, zero failures, `rain_city_non_boss_routes.complete = true`, no baseline approval. Edge IoU maximum `0.463343`; low-frequency MAE minimum `0.061401`.
  5. `env -u PYTHONPATH -u VIRTUAL_ENV bash tools/visual_quality/compare.sh --baseline /tmp/cobie-wcb008-candidate/wcb008h-final-supported --candidate /tmp/cobie-wcb008-candidate/wcb008i-final-four-aspect --out /tmp/cobie-wcb008i-supported-comparison ... --aspect 1280x720 --aspect 1024x768` — **PASS**; supported-aspect perceptual MAE `0.000001`–`0.000090`, with exact matching dimensions.
  6. `QA_EXPORTS=1 bash tools/release_validate.sh` — **PASS**, complete import/test/performance/export matrix and `Automated release validation passed`. Fresh Web hashes: `index.html` `d3dbb20e...2d06ef`, `index.js` `68586d6d...c42c`, `index.pck` `1a524440...95b`, `index.wasm` `35116f68...e2d`; macOS ZIP `115792291` bytes, SHA-256 `e98f8534bc877007d99ccc7b2ae5f23a9ca26dd43090b9085732d01d15f61b0a`, ZIP integrity pass.
  7. `/opt/homebrew/bin/godot --path . --resolution 1920x1080 --script res://tests/smoke/zone_performance_profile.gd` — **PASS**, Rain City average `16.655`–`17.083 ms`, p95 `17.422`–`23.346 ms`, zero stalls above `100 ms`. The known exact one-shader/one-RID GLES3 teardown diagnostics remained visible.
  8. Sanitized GPT capacity at 2026-07-23 00:06 PDT: Main GPT/Codex `46%` remaining; GPT-5.3-Codex-Spark `28%` remaining; no limit hit.
- **Rendered automated evidence:**
  - report: `/tmp/cobie-wcb008-candidate/wcb008i-final-four-aspect/capture_report.json`;
  - contacts: `/tmp/cobie-wcb008i-final-1280x720-contact.png`, `/tmp/cobie-wcb008i-final-1680x1050-contact.png`, `/tmp/cobie-wcb008i-final-1024x768-contact.png`, `/tmp/cobie-wcb008i-final-3440x1440-contact.png`;
  - comparison: `/tmp/cobie-wcb008i-supported-comparison/comparison.md`.
  - Pixel inspection of every final image found five nonblank/correct route views at every declared aspect and no mechanical portrait/health/armor/access/weapon/ammo/objective/crosshair/caption clipping or overlap. This is rendered automated evidence, not taste approval.
- **Review disposition:** GPT-5.6-sol/high returned **APPROVE** with two minor test-integrity gaps; both were fixed by separating bootstrap/target sizes in the launch test and adding a hash-correct but dimension-wrong PNG rejection. The remaining portability risk is intentionally fail-closed on display backends that cannot support borderless exact sizing.
- **Evidence classes:** mechanical parser/tests/contracts/capture receipts/metrics/IP/content/architecture/performance/exports; rendered automated contact sheets; **no** human taste, route-feel, mix, humor, accessibility-comfort, photosensitivity, browser-playthrough, target-Mac route playthrough, iPad, or physical-controller evidence.
- **Remaining gates / next packet:** WCB-008 remains **IN PROGRESS** and WCB-009 remains blocked. Next, prepare the named human visual/audio/humor/accessibility review from this exact four-aspect set and existing bounded audio evidence. Do not remove `BETA` or advance WCB-009 solely from this automated packet.

---

## Resume protocol

1. Read `AGENTS.md`, `docs/PRD.md` §1.5, `docs/IMPLEMENTATION_PLAN.md`, and this current-state section.
2. Run `git status --short --branch`; do not overwrite uncommitted work.
3. Confirm the current packet and dependency state above.
4. Inspect its latest commit/diff and rerun the smallest applicable verification before continuing.
5. Update this log before each milestone commit.
6. If context becomes crowded, stop at a describable verified state and resume from this file—not from an inferred chat summary.
