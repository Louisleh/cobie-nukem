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

