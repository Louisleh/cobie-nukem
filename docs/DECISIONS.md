# Decisions

## D-001 — Standard Godot 4.7 and Compatibility renderer

**Status:** accepted by PRD.

Use GDScript with the standard Godot 4.7 stable build. Configure `gl_compatibility` and a 320×180 default viewport. This preserves native macOS and Web export support without a C# or custom-renderer dependency.

## D-002 — Explicit, limited autoload layer

**Status:** accepted by PRD.

Use exactly the seven documented core services until a cross-domain need justifies another. Entity state stays in scene-owned components. This avoids a broad mutable global state while providing stable integration boundaries.

## D-003 — Dependency-free core test entry point

**Status:** accepted.

Keep `tests/run_tests.gd` runnable by stock Godot so repository and CI validation do not depend on an add-on. Feature suites may use helpers beneath `tests`, but the canonical command remains available in a clean checkout.

## D-004 — Unsigned Universal macOS ZIP in CI

**Status:** accepted with release limitation.

CI exports an unsigned Universal macOS ZIP and a single-threaded Web build. Signing and notarization require owner credentials and are not simulated.

## D-005 — Clean-retro world rendering and illustrated enemy sprites

**Status:** accepted from owner visual feedback on 2026-07-10.

Use Godot's `canvas_items` stretch mode so the 3D world renders at the output resolution while the deliberately compact retro HUD keeps its authored 320×180 layout. Replace abstract enemy primitives at runtime with original, camera-facing high-resolution illustrations; retain the underlying 3D collision, telegraphs, AI, weak points, hit reactions, and boss logic. This preserves the boomer-shooter read while materially improving clarity and character identity.
