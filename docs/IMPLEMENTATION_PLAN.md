# Implementation Plan

This plan decomposes the PRD into independently owned workstreams while keeping a runnable integration target. `docs/PRD.md` remains authoritative if this summary differs.

## Dependency graph

```text
Architecture/build + shared contracts
  ├── input profiles/calibration ──┐
  ├── player/combat ───────────────┼── full graybox level ── presentation/audio ── release
  ├── enemy/boss ──────────────────┤
  └── CI/test harness ─────────────┴── continuous integration and QA
```

Level integration begins once movement, damage, interaction, and enemy targetability contracts stabilize. Presentation can work against fixtures but is only accepted against the full gameplay path.

## Milestones and gates

### M0 — repository and proof of life

- Godot 4.7 project imports with Compatibility rendering at 320×180.
- Core autoloads and named actions load.
- Boot scene instantiates headlessly.
- CI and export presets are syntactically present.

Gate: import and `tests/run_tests.gd` both exit zero.

### M1 — input-first prototype

- Keyboard/mouse, Classic 1996, Hybrid, and generic gamepad profiles.
- Raw diagnostics, calibration, dead zones, curves, inversion, conflict-aware rebinding, reconnect, and persistence.
- Off/Light/Classic/Heavy auto-aim tuning.

Gate: serialization/math tests pass, keyboard escape path is manually verified, and hardware remains labeled unverified unless physically tested.

### M2 — combat sandbox

- Tuned CharacterBody3D movement, health/armor, Pawstol, Barkshot, Fetch Launcher, pickups, target fixture, and hit feedback.
- Two readable enemy types participate.

Gate: automated combat math/cooldown tests plus a manual keyboard/mouse feel pass.

### M3 — complete graybox

- Zones A–F, all gates, checkpoint, three-plus secrets, three regular enemies, elite, boss, Golden Tennis Ball, restart, and victory.

Gate: clean-launch start-to-finish manual playthrough and critical scene smoke test.

### M4 — Cobie presentation

- Title/cover, Cobie identity, HUD, signs, billboard art, low-resolution presentation, menus, settings, and accessibility visuals.

Gate: 16:9 and ultrawide visual QA; all state remains legible without color alone.

### M5 — audio, feedback, balance

- Original/permissive music and SFX, encounter mix, accessibility pass, score/ranks, performance tuning.

Gate: provenance complete, full playthrough target 12–20 minutes, no ordinary native frame over 33 ms in target testing.

### M6 — release candidate

- Web and universal macOS artifacts, full automated suite, keyboard/mouse browser/native manual matrix, release notes, known issues.

Gate: every Definition of Done item has evidence or a clearly documented external blocker. Joystick verification is never inferred.

## Integration cadence

Each workstream returns files changed, exact tests/results, risks, and integration notes. The integration owner then:

1. Reviews shared contracts and project settings.
2. Imports the combined project headlessly.
3. Runs the complete test runner.
4. Instantiates critical scenes.
5. Runs focused manual smoke tests when UI/gameplay exists.
6. Updates decisions and known issues to reflect reality.

An agent's green isolated test is not evidence that the integrated branch is green.

