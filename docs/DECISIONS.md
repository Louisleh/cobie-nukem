# Decisions

## D-014 — High-resolution 2.5D is the production constraint

Cobie remains a high-resolution retro 2.5D shooter: authored low-poly 3D environments carry collision, navigation, materials, lighting, and landmarks, while original directional billboard sprites carry character detail and readable animation. A pure pixel-art rewrite is rejected because it would not solve the actual consistency problems—sprite scale, baselines, animation vocabulary, collision agreement, and environmental authorship—and would discard the existing visual direction.

All manifested sprite atlases use a fixed grid and feet baseline and record opaque-frame height, intended world height, and `pixel_size = intended_world_height / opaque_frame_height`. Every mission follows the distinct identity matrix in `docs/ART_BIBLE.md`; shared systems are reusable, but environments cannot be mere palette swaps. Human review retains taste and cohesion ownership, while scale metadata, imports, safe areas, performance, and malformed captures are mechanical gates.

## D-013 — Cobie HUD portrait uses two unmistakable health states

The owner-selected Set A portrait is the sole HUD art direction. Cobie uses a clean portrait at 65–100% health and the most visibly damaged portrait below 65%; the nuanced middle image is intentionally omitted because it did not read distinctly at gameplay size. Runtime assets are 512×512 tight crops, the controller draws consistent HUD chrome, and source concepts remain under `assets/source/ui/` with provenance.

## D-011 — Audited local agentic game-development toolchain

Godot and Blender automation are privileged localhost-only development tools, not game dependencies. The permanent Godot MCP is an audited, locally pinned fork of `alexmeckes/godot-mcp` because it alone passed the required live InputMap, screenshot, output, and runtime-state capability gate. Its Node dependencies are upgraded to a zero-known-vulnerability production audit. Its temporary runtime autoload is removed when the plugin exits, and `tools/release_validate.sh` fails if bridge files or settings are present. The upstream package currently lacks a distributable top-level license file, so the bridge is not vendored into this repository.

Blender MCP is pinned locally with telemetry and all external asset services disabled. Blender output enters the game only as an intentional exported asset with provenance. TrenchBroom/FuncGodot and GdUnit4 remain isolated pilots until their acceptance gates pass; neither can replace the stock Godot test entry point or become an export dependency by default.

## D-009 — Fixed-speed twin-stick response with bounded assistance

The right stick remains a rate-based aiming control: displacement controls angular speed, not an unbounded swipe delta. Fine aim uses a configurable response curve and time-based smoothing; sustained outer-ring input receives a delayed, bounded turn boost; visible targets may reduce angular rate through configurable friction. No gyro or swipe-look is added in this pass. Profiles live in typed Resources and transient response state lives outside the player controller.

## D-010 — Future levels are illustrated promises, not false routes (superseded for Vancouver by D-012)

Mount Hood, Moon, and Ventura Pier appear as original illustrated mission cards. They remain locked, contain no scene route, and say COMING SOON. Vancouver followed this rule through Alpha.8 and is now governed by D-012.

## D-012 — Public development uses explicit beta routes

Vancouver Waterfront is public from Alpha.9 onward because its shared mission/runtime contracts, complete route, persistence, encounters, and reset behavior pass automated gates. Its card, action, status, and opening caption all say `BETA` or public work in progress. Public accessibility is not a claim of finished art, balance, pacing, hardware validation, or human completion. Later missions stay locked until they reach an equivalent minimum contract.

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

- Salmon Creek remains the definitive slice; Vancouver stayed locked through Alpha.8 and is public only under D-012's explicit beta contract.
- Internal rendering moves from 320×180 nearest-filtered output to 640×360 with linear canvas filtering. UI keeps the original proportions through a 2× theme scale and normalized fixed panels.
- Checkpoints use schema v3 and persist objective, completed-encounter, and secret snapshots. Live actors/timers/projectiles intentionally restart from authored state.
- Frequent interaction and auto-aim queries use event-maintained registries. A 250 ms route-recovery timer replaces per-physics-frame fallback checks.
- Web/mobile and native quality budgets are typed Resources selected automatically, with manual override reserved in settings.
- Imported audio samples become the production path through `AudioCueSet`; synthesized audio remains an explicit fallback until manifested samples exist.
- Local playtest metrics contain gameplay/performance counters only, are written only on explicit local export, and have no network transport or identity fields.
