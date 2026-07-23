# World-Class 3/6/9 Implementation Plan

**Program:** Cobie Nukem quality-first buildout
**Status:** Active
**Started:** 2026-07-21
**Authoritative requirements:** `docs/PRD.md`, especially §1.5
**Live status and resumability:** `docs/WORLD_CLASS_BUILDOUT_LOG.md`

This plan replaces the historical scaffold milestones with an evidence-gated program for turning the existing five-mission public alpha into a polished original retro 2.5D shooter. It is deliberately quality-first: one definitive mission and one proven replication are more valuable than five superficially different betas.

## Operating rules

1. `docs/PRD.md` defines product intent and acceptance criteria.
2. This file defines dependency order and ownership; `docs/WORLD_CLASS_BUILDOUT_LOG.md` records actual state.
3. Every writer owns a non-overlapping packet. Shared-file changes remain with the integration owner.
4. A packet is complete only after root review, applicable focused tests, integrated tests, and an updated log entry.
5. Automated evidence never claims human feel, taste, physical-device, mix, humor, fairness, or photosensitivity approval.
6. No Level 2–5 `BETA` badge is removed by automation.
7. No release is stamped while source commit, packaged artifact, website artifact, and public PCK identity disagree.
8. If Godot is unavailable, documentation and deterministic non-engine work may proceed, but gameplay packets remain blocked rather than being marked complete.
9. After every two major milestones—and before launching a large Spark batch—run the sanitized `gpt-usage-shortcut` workflow. Use GPT-5.3-Codex-Spark aggressively for useful bounded workers while GPT-5.6-sol/high owns architecture, review, integration, and final claims; never create low-value work solely to burn quota.

## Program dependency graph

```text
WCB-000 governance/PRD
  └─ WCB-001 toolchain + baseline
       ├─ WCB-002 input ownership
       ├─ WCB-003 checkpoint restore
       └─ WCB-004 options reset + combat allocation baseline
             └─ WCB-005 Rain City spatial vertical slice
                  ├─ WCB-006 encounter choreography
                  ├─ WCB-007 Towmaster spectacle
                  └─ WCB-008 mission-specific art/audio
                         └─ WCB-009 Rain City integrated evidence + replication selection
                              └─ WCB-010 second-mission implementation + validation
                                   └─ WCB-011 release identity + campaign roadmap
```

WCB-002, WCB-003, and the non-overlapping halves of WCB-004 may run in parallel after WCB-001. WCB-006–008 may use isolated writers only after WCB-005 freezes route/collision ownership.

## Work packets

### WCB-000 — PRD, governance, and continuity

**Status:** Complete — integrated and pushed at `6b8077a`
**Owner:** Integration/documentation
**Paths:** `AGENTS.md`, `docs/PRD.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/WORLD_CLASS_BUILDOUT_LOG.md`, `docs/PHASE_ROADMAP_PRD.md`, `docs/DECISIONS.md`, `docs/design/README.md`, `.agents/skills/cobie-godot-production/SKILL.md`, `tools/validate_world_class_docs.py`

**Deliverables**

- Record the 2026-07-21 audit and the 3/6/9 quality mandate.
- Define evidence classes, milestone gates, ownership, and handoff format.
- Establish a durable current-state log that survives chat/session compaction.

**Exit**

- Cross-document links resolve.
- PRD requirements and implementation packets do not contradict current public-beta honesty rules.
- Documentation commit is pushed before gameplay edits begin.

### WCB-001 — Reproducible Godot 4.7 workstation and baseline

**Status:** Complete — integrated and pushed at `4479e2f`
**Owner:** Architecture/integration
**Paths:** tooling/docs only unless a verified compatibility fix is required

**Deliverables**

- Install or locate Godot 4.7 stable and export templates.
- Run `bash tools/game_dev_health.sh`.
- Run parser/import and full automated baseline through `tools/run_godot_safe.sh`.
- Record exact tool versions, failures, and the public/source build identity delta.
- Produce no gameplay changes until the baseline is attributable.

**Verification**

```bash
bash tools/game_dev_health.sh
bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd
```

**Exit:** clean import and test baseline, or explicit named failures entered in the log with the next bounded packet.

### WCB-002 — Effective input-profile ownership

**Status:** Complete — corrective runtime pass integrated at `f8a78e5`; physical joystick gate open
**Owner:** Input, with a surgical player integration seam
**Paths:** `scripts/input/`, `scripts/input/player_input_adapter.gd`, `scripts/player/player_controller.gd`, `scripts/ui/pause_menu.gd`, `resources/input_profiles/`, `tests/unit/input_system_test.gd`, `tests/integration/input_profile_service_boundary_test.gd`, `docs/design/input.md`

**Problem:** profile-aware input accessors exist, while the player also consumes global named actions and hard-coded shortcut paths. A saved profile is not accepted as functional until non-default bindings drive the real player.

**Deliverables**

- Establish one authority for gameplay actions.
- Keep raw axes/buttons inside diagnostics/adapters.
- Ensure profile activation updates the runtime action path consumed by `CobiePlayer`.
- Add a player-level regression for remapped movement, jump, fire, reload, and weapon switching.

**Exit:** a deliberately non-default profile controls the real player without modifying `project.godot`; keyboard recovery remains available.

### WCB-003 — Checkpoint restore invariants across all missions

**Status:** Complete — corrective runtime pass integrated at `f8a78e5`
**Owner:** Save/mission runtime
**Paths:** `scripts/level/rain_city_checkpoint_state.gd`, `scripts/level/mount_hood_whiteout.gd`, `scripts/level/biome_mission_controller.gd`, checkpoint/campaign tests, `docs/design/checkpoints.md`

**Problem:** later mission restore paths can call run initialization after applying checkpoint data, risking reset of pending progression state.

**Deliverables**

- Define restore order once and reuse it.
- Preserve route gate, objective, health, armor, loadout, ammo, tags, secrets, and mission mode.
- Reject checkpoint writes during active boss combat. Until WCB-007 owns phase serialization, continuation resumes from the last pre-boss checkpoint into a fresh deterministic boss.
- Add deterministic tests for Mount Hood, Moon, and Ventura matching Salmon/Rain City coverage.

**Exit:** 100 seeded restore cycles per mission reproduce the saved state and finish without orphaned progression or duplicate rewards.

### WCB-004 — Runtime setting truth and combat allocation budget

**Status:** Complete — corrective runtime pass integrated at `f8a78e5`
**Owner:** UI/presentation for settings; combat for effects
**Paths:** `scripts/core/settings_manager.gd`, `scripts/core/quality_manager.gd`, `scripts/core/projectile_pool.gd`, `scripts/player/player_runtime_settings.gd`, `scripts/player/player_impact_effects.gd`, `scripts/player/tactile_feedback.gd`, `scripts/combat/weapon_base.gd`, `scripts/combat/impact_effect_pool.gd`, `scripts/combat/fetch_launcher.gd`, `scripts/combat/fetch_projectile.gd`, focused settings/combat/pool/performance tests, `docs/design/performance-accessibility.md`

**Deliverables**

- Reset-to-default immediately reapplies render scale, FPS cap, effects, and audio/UI state.
- Establish an allocation/object-count baseline for sustained Pawstol, Barkshot, and Fetch Launcher fire.
- Replace per-hit mesh/material/timer churn with bounded reused effects where evidence shows churn.
- Preserve reduced-motion and quality-tier behavior.

**Exit:** settings UI and runtime agree in the same frame; after warm-up, sustained combat has bounded node/material counts and no monotonic growth.

### WCB-005 — Rain City authored spatial vertical slice

**Status:** Complete — integrated at `8a5a807`; human pacing, meaningfulness, and landmark readability remain open
**Owner:** Level
**Paths:** `scripts/level/rain_city_spatial_route_builder.gd`, Rain City world/mission controllers, route definition, interaction catalog, route/mission/capture tests, and `docs/design/rain-city-route.md`

**Deliverables**

- Freeze one definitive 15–22 minute route.
- At least three meaningful loops/shortcuts and two combat elevations.
- At least two cross-area sightline windows, one route-state change, four observation-based secrets, and a revisit with new access.
- Three unmistakable landmarks with 10-second orientation from canonical entrances.
- Presentation remains separate from collision/navigation ownership.

**Exit:** deterministic route tests prove the enumerated loops, elevations, sightline windows, route-state change, revisit, and secrets exist; a route map and multi-aspect images are prepared for review. Readability, orientation quality, and whether a loop is meaningful remain human-review decisions and cannot be closed by automation.

### WCB-006 — Authored encounter choreography

**Status:** Complete — schema-v3 cards/content/runtime metadata, secret reduction, 100 route/reset cycles, focused matrix, and packaged Web/macOS validation pass
**Owner:** Encounter/enemy
**Paths:** `resources/encounters/vancouver_*.tres`, Rain City encounter-only resources declared in the packet, and `tests/integration/rain_city_*encounter*.gd`. Any `scripts/ai/` change requires a separately recorded ownership transfer and cannot overlap another writer.

**Deliverables**

- Six visually and behaviorally readable roles across the mission.
- Each major encounter combines at least three roles, two attack directions, a recovery lane, and one environment-dependent choice.
- Add patrol, reveal, ambush, retreat/reposition, or reinforcement logic so fights are not only wave spawns in boxes.
- Preserve attacker budgets, fairness, checkpoint reset, and navigation recovery.

**Exit:** 100 route/reset cycles pass; encounter cards document intent and counters; human pacing/fairness remains open.

### WCB-007 — Municipal Towmaster production boss

**Status:** Complete — three attacks, four phases, two arena states, bounded 10.2-second defeat, 100-cycle combat/reset evidence, native multi-aspect comparison, and packaged Web/macOS validation pass
**Owner:** Enemy/boss + presentation integration
**Paths:** `scenes/set_pieces/citation_convoy.tscn`, `scripts/level/citation_convoy_actor.gd`, `scripts/level/rain_city_convoy_presentation.gd`, `resources/set_pieces/vancouver_citation_convoy.tres`, `resources/set_pieces/vancouver_convoy_phases/`, `assets/models/set_pieces/municipal_towmaster.glb`, `assets/source/blender/municipal_towmaster.blend`, `tests/integration/rain_city_convoy_boss_test.gd`. Additional paths require an integration-owner transfer recorded before editing.

**Deliverables**

- Unique readable silhouette at intended combat distance.
- At least three distinct attacks, four readable phases, and two arena-state changes.
- Phase-specific telegraph, audio, lighting, and counterplay.
- Bounded summons/effects, deterministic reset, and a memorable ten-second defeat payoff.

**Exit:** boss soak and checkpoint/reset tests pass; 16:9 and 4:3 evidence captures exist; human spectacle/fairness review remains open.

### WCB-008 — Mission-specific visual and audio identity

**Status:** In progress — readability/gate, authored harbour-backdrop, runtime audio-event evidence, post-draw hash/pose-bound route evidence, and compact HUD safety are implemented. WCB-008I now produces the declared exact 1280×720, 1680×1050, 1024×768, and 3440×1440 five-route set on the current macOS host through a fail-closed borderless capture path; automated capture/package prerequisites pass, while named human visual/audio/humor/accessibility acceptance remains open
**Owner:** Visual Foundry/audio
**Paths:** `assets/models/environment/rain_city_*`, `assets/source/blender/rain_city_run_foundry.blend`, `assets/source/material_maker/rain_city_*.ptex`, `assets/textures/materials/rain_city/`, `resources/presentation/vancouver_*.tres`, `resources/audio/vancouver_mission_audio.tres`, `assets/audio/**/vancouver_*.wav`, `scenes/levels/vancouver/rain_city_presentation.tscn`, `scripts/level/rain_city_material_applier.gd`, `docs/ART_BIBLE.md`, `docs/ASSET_MANIFEST.md`, and canonical non-boss captures. WCB-007 boss paths are explicitly excluded.

**Deliverables**

- Replace critical-route flat-color/blockout presentation with manifested material families and authored landmarks.
- Provide mission-specific exploration, combat, boss, and victory sound identity.
- Ensure hero enemies are not merely inherited scenes with renamed labels.
- Label promotional art as concept art until paired runtime evidence reaches the same identity target.
- Preserve editable Blender/Material Maker sources and provenance.

**Exit:** asset/IP/import gates pass; canonical multi-aspect captures and bounded audio evidence exist; human art/mix/humor/photosensitivity gates remain open.

### WCB-009 — Rain City integrated evidence and replication selection

**Status:** Blocked pending WCB-008
**Owner:** Integration/release
**Paths:** tests, evidence, release docs, build info; website repo only after source RC is green

**Deliverables**

- Full import/unit/integration/route/soak/performance/export matrix.
- Native Mac, packaged Web, Chrome, Safari, and simulated 4:3 tablet checks.
- One 15–22 minute human target-Mac route and physical-iPad gate owned by a human.
- Source commit → package hash → website commit → public PCK identity ledger.
- Select exactly one second mission for pipeline replication using a recorded cost/quality/risk comparison.
- Freeze WCB-010's exact ownership manifest, acceptance condition, automated tests, and human-review packet before its writer starts.

**Exit:** Rain City's automated matrix and human-review packet are complete, and one second-mission implementation packet is decision-complete. Rain City may lose `BETA` only after every applicable automated and human gate is recorded; otherwise it remains honestly labelled.

### WCB-010 — Second-mission pipeline replication

**Status:** Pending WCB-009 selection
**Owner:** Assigned after the WCB-009 comparison
**Paths:** Exact non-overlapping mission paths are frozen in the buildout log before work starts; shared architecture and Rain City paths remain integration-owned.

**Deliverables**

- Apply the accepted route, encounter, boss, presentation, audio, performance, and evidence pipeline to exactly one selected mission.
- Replace inherited hero scenes/audio where reuse obscures that mission's identity.
- Run the mission's route, checkpoint, boss, soak, native/Web performance, import, and multi-aspect evidence gates.
- Preserve its `BETA` badge until its own human/device gates pass.

**Exit:** the selected mission meets the same mechanical production contract as Rain City, has a complete human-review packet, and demonstrates that the pipeline replicates without copying Rain City's identity.

### WCB-011 — Release identity and campaign roadmap

**Status:** Pending WCB-010
**Owner:** Integration/release
**Paths:** tests, evidence, release docs, build info, packages; website repository only after the source candidate is green

**Deliverables**

- Run the final import/unit/integration/route/checkpoint/soak/performance/Web/macOS matrix.
- Record source commit → package hashes → website commit → downloaded public PCK identity.
- Publish only an honestly labelled candidate and convert remaining missions into bounded packets.

**Exit:** one definitive mission, one proven replication, reproducible package identity, and a dependency-safe remaining campaign roadmap are recorded. Human and physical-device gates remain separate.

## Required packet handoff

Every agent or Codex worker must leave this exact information in its commit message, PR body, or `docs/WORLD_CLASS_BUILDOUT_LOG.md` entry:

- Packet ID and acceptance condition
- Source commit and owned paths
- Files changed
- Tests/commands with exact results
- Evidence created and evidence class
- Claims that remain human-only or blocked
- Risks/regressions reviewed
- Next dependency-safe packet

## Milestone reporting policy

Chat updates are limited to verified milestones:

1. Governance baseline pushed
2. Godot/toolchain baseline green
3. Correctness tranche green
4. Rain City route freeze green
5. Encounter/boss/presentation integration green
6. Rain City evidence and replication selection complete or explicitly blocked
7. Second-mission replication green
8. Release identity complete or explicitly blocked

Intermediate experimentation belongs in the repository log, not chat.