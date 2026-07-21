# World-Class Buildout Log

This is the durable continuation ledger for the Cobie Nukem 3/6/9 quality program. New Hermes, Codex, or human sessions read this file after `AGENTS.md`, `docs/PRD.md` §1.5, and `docs/IMPLEMENTATION_PLAN.md`. Chat history is not a source of truth.

## Current state

- **Program branch:** `hermes/world-class-369-buildout`
- **Baseline source:** `4dbbe2e8571efec290ed863415a78f09bc970ca9`
- **Public baseline declared by roadmap:** `0.11.0-alpha.1-rc1`, gameplay/runtime `3c2de29`
- **Current packet:** WCB-002–004 corrective evidence commit/push
- **Last verified packet:** WCB-002/003/004 corrective nine-test matrix and packaged Web/macOS release validation passed on the current working tree
- **Next dependency-safe packet:** WCB-005 — blocked until the corrective evidence commit/push completes
- **Toolchain state:** Godot 4.7.1 and matching export templates are installed; automated import, tests, and export validation pass. Optional Blender/MCP production-art tooling remains unavailable and is recorded below.
- **Human-only gates:** target-Mac feel/playthrough, physical iPad, flight stick, art taste, pacing, mix, fairness, humor, motion comfort, photosensitivity

## Milestone dashboard

| Packet | State | Owner | Integrated commit | Verification | Honest boundary |
| --- | --- | --- | --- | --- | --- |
| WCB-000 Governance | COMPLETE | Integration/docs | `6b8077a` | Diff/link/validator/reviews pass | No gameplay claim |
| WCB-001 Toolchain baseline | COMPLETE | Architecture | `4479e2f` | Godot 4.7.1 import/tests/exports pass | Optional art MCP tooling is not ready |
| WCB-002 Input ownership | VERIFIED; PUSH PENDING | Input/player seam | `1b1579f` + pending | Service + real player-boundary tests + packaged exports pass | Physical joystick remains unverified |
| WCB-003 Checkpoint invariants | VERIFIED; PUSH PENDING | Save/mission runtime | `23a657d` + pending | Real controller order + boss write policy + progression + packaged exports pass | Manual continues remain open |
| WCB-004 Settings/allocation | VERIFIED; PUSH PENDING | UI + combat | `5ce5501`, `5b8ad45`, `502535a` + pending | Runtime reset, shared effects, reuse contamination, performance + packaged exports pass | Headless timing is not rendered GPU evidence |
| WCB-005 Rain City spatial slice | BLOCKED by corrective push | Level | — | — | Current route remains public BETA |
| WCB-006 Encounters | BLOCKED by WCB-005 | Enemy/encounter | — | — | Human pacing/fairness open |
| WCB-007 Towmaster | BLOCKED by WCB-005 | Boss/presentation | — | — | Human spectacle/fairness open |
| WCB-008 Art/audio identity | BLOCKED by WCB-005 | Visual Foundry/audio | — | — | Human art/mix/humor open |
| WCB-009 RC evidence/selection | BLOCKED by WCB-005–008 | Integration/release | — | — | Human/device gates required |
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
- Integrated commit: pending corrective commit/push.
- Next dependency-safe packet: WCB-005 only after this entry records the pushed corrective commit and packaged validation result.

## Resume protocol

1. Read `AGENTS.md`, `docs/PRD.md` §1.5, `docs/IMPLEMENTATION_PLAN.md`, and this current-state section.
2. Run `git status --short --branch`; do not overwrite uncommitted work.
3. Confirm the current packet and dependency state above.
4. Inspect its latest commit/diff and rerun the smallest applicable verification before continuing.
5. Update this log before each milestone commit.
6. If context becomes crowded, stop at a describable verified state and resume from this file—not from an inferred chat summary.
