# Decisions

## D-008 — iPad uses fixed twin-stick rate aiming

**Status:** accepted from owner direction on 2026-07-12.

The Web/iPad control model uses a left movement stick and a right aiming stick,
with action buttons retaining independent finger ownership. Right-side swipe look
is removed because a fixed rate stick is more discoverable, repeatable, and
compatible with simultaneous fire. Defaults are adjustable through size and
position presets and mirror completely for left-handed play. Aim advances during
physics ticks, making it independent of browser touch-event frequency.

## D-001 — Standard Godot 4.7 and Compatibility renderer

**Status:** accepted by PRD.

Use GDScript with the standard Godot 4.7 stable build and `gl_compatibility`. The original 320×180 baseline was superseded by D-007’s 640×360 clarity pass. This preserves native macOS and Web export support without C# or a custom-renderer dependency.

## D-002 — Explicit, limited autoload layer

**Status:** accepted by PRD.

Keep the autoload layer explicit and limited to cross-scene services documented in `project.godot`. D-007 adds event indexing, pressure budgeting, and quality selection because each spans independently loaded scenes; entity and mission state remain scene-owned.

## D-003 — Dependency-free core test entry point

**Status:** accepted.

Keep `tests/run_tests.gd` runnable by stock Godot so repository and CI validation do not depend on an add-on. Feature suites may use helpers beneath `tests`, but the canonical command remains available in a clean checkout.

## D-004 — Unsigned Universal macOS ZIP in CI

**Status:** accepted with release limitation.

CI exports an unsigned Universal macOS ZIP and a single-threaded Web build. Signing and notarization require owner credentials and are not simulated.

## D-005 — Clean-retro world rendering and illustrated enemy sprites

**Status:** accepted from owner visual feedback on 2026-07-10.

Use Godot's `canvas_items` stretch mode with original, camera-facing high-resolution illustrations; retain underlying 3D collision, telegraphs, AI, weak points, hit reactions, and boss logic. D-007 raises the internal baseline and normalizes UI rather than retaining the old 320×180 pixelated presentation.

## D-006 — Resource-driven mission contracts

**Status:** accepted for production Phase 1–2.

Objectives, encounters, difficulty profiles, and each mission's content inventory use typed custom Resources under `resources/`. Reusable runtime behavior lives in `scripts/gameplay`; mission controllers translate local signals into semantic objective/encounter events. This avoids a new autoload, keeps Web compatibility, allows headless validation, and prevents future missions from copying Salmon Creek's hard-coded wave and progression tables.
## D-007 — World-class vertical-slice foundation

- Salmon Creek remains the definitive slice; Vancouver stays locked.
- Internal rendering moves from 320×180 nearest-filtered output to 640×360 with linear canvas filtering. UI keeps the original proportions through a 2× theme scale and normalized fixed panels.
- Checkpoints use schema v3 and persist objective, completed-encounter, and secret snapshots. Live actors/timers/projectiles intentionally restart from authored state.
- Frequent interaction and auto-aim queries use event-maintained registries. A 250 ms route-recovery timer replaces per-physics-frame fallback checks.
- Web/mobile and native quality budgets are typed Resources selected automatically, with manual override reserved in settings.
- Imported audio samples become the production path through `AudioCueSet`; synthesized audio remains an explicit fallback until manifested samples exist.
- Local playtest metrics contain gameplay/performance counters only, are written only on explicit local export, and have no network transport or identity fields.
