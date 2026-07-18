# QA Plan

## Purpose and evidence standard

QA establishes that the integrated vertical slice is complete, playable, honest about hardware support, and safe to package. Automated success is evidence for deterministic contracts only. It does not prove weapon feel, 12–20 minute pacing, visual readability, browser controller mapping, target-Mac performance, or physical joystick compatibility.

For each release candidate, retain the commit, Godot version, command, exit code, relevant output, artifact hash, machine/browser/controller configuration, and manual tester result.

## Automated suites

Run from the repository root with Godot 4.7 stable. All automated invocations use the serialized runner so a timeout, interrupted Codex task, or blocked output pipe cannot leave a competing Godot process behind:

```bash
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 120 -- --headless --editor --path . --quit
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 120 -- --headless --path . --script res://tests/run_tests.gd
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 120 -- --headless --path . --script res://tests/unit/input_system_test.gd
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 120 -- --headless --path . --script res://tests/unit/combat_test_runner.gd
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 120 -- --headless --path . --script res://tests/unit/enemy_contract_tests.gd
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 120 -- --headless --path . --script res://tests/unit/navigation_contract_test.gd
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 120 -- --headless --path . --script res://tests/unit/save_schema_test.gd
GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 240 -- --headless --path . --script res://tests/integration/vancouver_mission_host_test.gd
GODOT_TEST_USE_REAL_HOME=1 GODOT_BIN=/opt/homebrew/bin/godot bash tools/run_godot_safe.sh --timeout 360 -- --path . --resolution 1280x720 --script res://tests/smoke/zone_performance_profile.gd -- --profile-static --profile-invulnerable
bash tools/asset_ip_scan.sh
```

`bash tools/release_validate.sh` composes these gates. Set `QA_EXPORTS=1` to require both Web and unsigned macOS artifacts.

The runner isolates test `HOME` and `COBIE_TEST_SAVE_ROOT` by default. Rendered profiling may set `GODOT_TEST_USE_REAL_HOME=1` so the engine can use the normal shader cache while `COBIE_TEST_SAVE_ROOT` still prevents test saves from touching player data. A lock-contention exit of 75 and timeout exit of 124 are infrastructure results, not game-test failures.

### Coverage map

| Requirement | Evidence |
| --- | --- |
| Project settings and boot contract | `tests/run_tests.gd` |
| Dead zones, response curves, profiles, diagnostics | `tests/unit/input_system_test.gd` |
| Damage/armor, ammo, cooldown, weapon scenes | `tests/unit/combat_test_runner.gd` |
| Five enemy scenes, damage hooks, shield, boss phases | `tests/unit/enemy_contract_tests.gd` |
| Reusable interaction lifecycle, bounded effects, damage, hazards, loot, and reset | `tests/unit/world_interaction_test.gd` |
| Salmon Creek interaction placement IDs, zone density, transforms, and manifest validation | `tests/unit/interaction_catalog_test.gd` |
| Multi-zone navmesh, ground/flying split, arena-cover routing, bounded stuck recovery | `tests/unit/navigation_contract_test.gd` |
| Save/load, profile JSON, auto-aim filtering, FSM, secrets, finale | `tests/integration/integration_test_runner.gd` |
| Save-schema versioning, migrations, corrupt/legacy/future payload recovery | `tests/unit/save_schema_test.gd` |
| Save-v5 migration, content-revision remap, mission loadout/upgrades, route snapshots, and separate campaign progression | `tests/unit/save_schema_test.gd`, `tests/unit/campaign_progress_runtime_test.gd`, `tests/unit/rain_city_campaign_test.gd`, `tests/unit/mission_loadout_profile_test.gd`, `tests/integration/mission_runtime_contract_test.gd` |
| Mission audio crossfades, presentation cues, route ownership, and spawn ownership | `tests/unit/mission_audio_director_test.gd`, `tests/unit/mission_presentation_test.gd`, `tests/unit/mission_route_runtime_test.gd`, `tests/unit/mission_spawn_registry_test.gd` |
| Moving-set-piece lifecycle, external waves, 150 stage/reset cycles, and bounded cleanup | `tests/unit/moving_set_piece_runtime_test.gd`, `tests/unit/moving_set_piece_encounter_coordinator_test.gd`, `tests/unit/external_wave_encounter_test.gd` |
| Directional shield, Umbrella Shield Enforcer behavior, and authored content | `tests/unit/directional_shield_component_test.gd`, `tests/unit/umbrella_shield_enforcer_test.gd`, `tests/integration/umbrella_shield_content_test.gd` |
| Alpha.8 typed Resource validation and invalid-reference rejection | `tests/unit/alpha8_resource_contract_test.gd` |
| Difficulty selector contract, resource-driven labels, Classic default | `tests/unit/ui_scene_test.gd` |
| Grace-timer lifecycle, restart pressure, pause suppression, stuck touch input, reload interruption, double level lifecycle, enemy drops | `tests/integration/adversarial_state_test.gd` |
| Rain City route graph, production content, interactions, Gull/shield enemies, four-phase convoy soak, Continue rehydration, and departure gating | `tests/integration/vancouver_route_foundation_test.gd`, `tests/integration/vancouver_content_contract_test.gd`, `tests/integration/vancouver_interaction_catalog_test.gd`, `tests/integration/vancouver_mission_host_test.gd`, `tests/integration/rain_city_route_production_test.gd`, `tests/integration/rain_city_convoy_boss_test.gd` |
| Every scene loads/instantiates; boot/diagnostics survive entry | `tests/smoke/smoke_test_runner.gd` |
| Catastrophic main-loop stalls across Salmon Creek and Rain City | `tests/smoke/performance_smoke.gd` |
| Rendered 300-frame per-zone p95/p99, isolated >100 ms stall count, draw calls, objects, nodes, memory, and gameplay populations across both missions | `tests/smoke/zone_performance_profile.gd` |
| Godot process serialization, timeout cleanup, stale-lock recovery, and isolated test state | `tools/tests/run_godot_safe_test.sh` |
| Asset manifest coverage and obvious protected-source indicators | `tools/asset_ip_scan.sh` |

The smoke runner reports menu/level absence as `PENDING` during development. The release validator treats either absence as a hard failure.

## Manual test matrix

Complete [MANUAL_UX_CHECKLIST.md](MANUAL_UX_CHECKLIST.md) on the release candidate.

| Platform | Required input | Required browser/hardware |
| --- | --- | --- |
| Native macOS | Keyboard/mouse | target Apple-silicon Mac, current supported macOS |
| Native macOS | Generic gamepad | at least one recognized fallback device |
| Native macOS | Flight stick | only when physical device/adapter are available; record exact identity |
| Web | Keyboard/mouse | current Chrome and Safari over HTTPS |
| Web | Controller diagnostics | experimental, non-blocking; keyboard recovery required |

Also test 16:9, 16:10, and ultrawide; clean `user://`; existing settings/save; no controller; disconnect/reconnect; focus loss; muted audio; reduced flashes/shake/head bob; each auto-aim mode; every gore option.

## Full-playthrough gates

- Launch from title, begin a clean run, and finish at victory without editor intervention.
- Time is 12–20 minutes for a first-time representative playthrough.
- All six zones are traversable; checkpoint/restart never traps progress.
- Three weapons, three regular enemies, elite, and boss appear and function.
- Four secrets are independently discoverable and count exactly once.
- The opening forbidden-field sign and final Golden Tennis Ball payoff work.
- End screen totals enemies, secrets, accuracy, damage, time, control method, and rank plausibly.
- Keyboard-only recovery exists from every menu and calibration state.

## Performance validation

The headless performance smoke is only a stall detector. The native rendered profile samples 300 frames per zone, fails p95 above 33 ms or p99 above 33.3 ms, and fails when more than one >100 ms scheduling stall occurs in a zone. One isolated OS scheduling pause remains reported in evidence but is not misrepresented as a recurring gameplay stall. On the target M4 Mac mini, capture a representative full run and verify:

- native target 60 FPS at 1920×1080 output;
- ordinary combat frame spikes remain below 33 ms;
- launch and level load each remain below 10 seconds;
- memory remains below 1 GB;
- Web remains at least 30 FPS in Chrome and Safari;
- Web compressed download remains below 150 MB.

Record tooling and sampling method; do not infer GPU performance from headless CI.

## Defect severity

- **Blocker:** cannot launch/finish, progress loss, keyboard trap, parser/export failure, missing required content, unlicensed/protected asset.
- **Critical:** repeatable crash, save corruption, inaccessible required action, boss cannot complete, severe photosensitive/accessibility regression.
- **Major:** enemy/weapon/secret contract broken, wrong totals, material performance degradation, unusable remapping.
- **Minor:** polish defect without meaningful progression, safety, or comprehension impact.

No Blocker/Critical defect may ship. Major defects require explicit owner disposition in `docs/KNOWN_ISSUES.md`.
