# QA Plan

## Purpose and evidence standard

QA establishes that the integrated vertical slice is complete, playable, honest about hardware support, and safe to package. Automated success is evidence for deterministic contracts only. It does not prove weapon feel, 12–20 minute pacing, visual readability, browser controller mapping, target-Mac performance, or physical joystick compatibility.

For each release candidate, retain the commit, Godot version, command, exit code, relevant output, artifact hash, machine/browser/controller configuration, and manual tester result.

## Automated suites

Run from the repository root with Godot 4.7 stable:

```bash
/opt/homebrew/bin/godot --headless --path . --editor --quit
/opt/homebrew/bin/godot --headless --path . --script res://tests/run_tests.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/unit/input_system_test.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/unit/combat_test_runner.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/unit/enemy_contract_tests.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/unit/save_schema_test.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/integration/integration_test_runner.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/integration/adversarial_state_test.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/smoke/smoke_test_runner.gd
/opt/homebrew/bin/godot --headless --path . --script res://tests/smoke/performance_smoke.gd
bash tools/asset_ip_scan.sh
```

`bash tools/release_validate.sh` composes these gates. Set `QA_EXPORTS=1` to require both Web and unsigned macOS artifacts.

### Coverage map

| Requirement | Evidence |
| --- | --- |
| Project settings and boot contract | `tests/run_tests.gd` |
| Dead zones, response curves, profiles, diagnostics | `tests/unit/input_system_test.gd` |
| Damage/armor, ammo, cooldown, weapon scenes | `tests/unit/combat_test_runner.gd` |
| Five enemy scenes, damage hooks, shield, boss phases | `tests/unit/enemy_contract_tests.gd` |
| Save/load, profile JSON, auto-aim filtering, FSM, secrets, finale | `tests/integration/integration_test_runner.gd` |
| Save-schema versioning, migrations, corrupt/legacy/future payload recovery | `tests/unit/save_schema_test.gd` |
| Difficulty selector contract, resource-driven labels, Classic default | `tests/unit/ui_scene_test.gd` |
| Grace-timer lifecycle, restart pressure, pause suppression, stuck touch input, reload interruption, double level lifecycle, enemy drops | `tests/integration/adversarial_state_test.gd` |
| Every scene loads/instantiates; boot/diagnostics survive entry | `tests/smoke/smoke_test_runner.gd` |
| Catastrophic main-loop stalls | `tests/smoke/performance_smoke.gd` |
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
- Three secrets are independently discoverable and count exactly once.
- The opening forbidden-field sign and final Golden Tennis Ball payoff work.
- End screen totals enemies, secrets, accuracy, damage, time, control method, and rank plausibly.
- Keyboard-only recovery exists from every menu and calibration state.

## Performance validation

The headless performance smoke is only a stall detector. On the target M4 Mac mini, capture a representative full run and verify:

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

