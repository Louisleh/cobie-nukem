# Release Notes — 0.6.0-alpha.3 Agentic Production Checkpoint

Built on 2026-07-13 with Godot `4.7.stable.official.5b4e0cb0f` and matching official export templates. Feature revision: `b8795dc`.

## Player-visible change

- The Salmon Creek ball-return secret now uses an original Blender-authored automatic tennis-ball machine instead of the procedural orange-box placeholder.
- The machine has a clearer orange/charcoal silhouette, visible tennis balls, paw identity, a status light, and production collision while preserving the Fetch-projectile puzzle.

## Stability and production improvements

- Removed a threaded menu-preload Resource leak and made title/menu delayed layout teardown-safe.
- Indexed the live player through `WorldRegistry`, removing repeated hot-path scene-tree searches from pickup fallback collection and enemy targeting.
- Release validation now rejects script errors, ObjectDB/resource leaks, orphan nodes, embedded live-editor bridges, and development Resources under `tmp/`.
- Performance smoke now records warmup-separated average, p50, p95, p99, max, object/node drift, memory, and available draw-call evidence.
- Added an automated asset contract for imported mesh vocabulary, ground placement, physical collision, projectile triggering, and one-shot secret activation.
- Added a pinned, audited local Godot/Blender agentic workflow and documented explicit adoption decisions for FuncGodot/TrenchBroom and GdUnit4.

## Validation

- Full Godot 4.7 parser, unit, integration, adversarial, route, soak, smoke, content, architecture, provenance, Web export, and macOS export matrix passed.
- The packaged Web artifact passed desktop 1280×720 and tablet 1024×768 `?touch=1` startup/menu/selector/gameplay-entry checks with no captured browser warnings or errors.
- Physical iPad Safari multi-touch comfort/thermal behavior, native rendered performance, the prop’s in-route visual readability, and a complete human playthrough remain explicit manual gates.

## Artifacts

- `cobie-nukem-0.6.0-alpha.3-itch.zip` — 21,421,046 bytes; SHA-256 `ba2a1e0c9a99be076f50b6f152fe1c5e870893652f4566421455cf8017012e4c`.
- `cobie-nukem-0.6.0-alpha.3-macos-unsigned.zip` — 70,785,017 bytes; SHA-256 `f7ff01c9d186feb62abdd34c45040721b2fe0d86e7769b933016573ff3ac91cc`.

The macOS ZIP remains unsigned and unnotarized. The working title still requires clearance before commercial distribution.
