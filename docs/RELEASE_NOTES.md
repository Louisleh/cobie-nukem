# Release Notes — 0.6.0-alpha.5 Production Navigation

Built on 2026-07-13 with Godot `4.7.stable.official.5b4e0cb0f`. Gameplay/runtime feature revision: `4059174`.

## Player-visible changes

- Ground enemies now path around walls and arena cover instead of steering in a straight line and becoming stranded.
- The complete Salmon Creek route is navigation-connected from the opening field through the Walker conclusion.
- Persistent stalls trigger a bounded recovery only after three failed repaths, with a cooldown that prevents visible correction spam.
- Flying drones retain their authored hovering and direct flight behavior.
- The arena connector is widened to remove a real navigation seam exposed by agent-radius erosion.

## Production improvements

- Salmon Creek bakes 112 polygons/114 vertices once from temporary CPU-side collision sources, avoiding render-mesh GPU readback and removing the source bodies after construction.
- Every grounded archetype receives a throttled `NavigationAgent3D`; target refresh is capped at four times per second unless the destination moves materially.
- Navigation registration, map lifecycle, cover routing, ground/flying separation, and recovery are deterministic release gates on macOS and Linux CI.
- Navigation recoveries increment privacy-preserving local playtest metrics.
- Enemy death VFX moved into a focused component so the shared enemy controller remains within the repository's 500-line architecture limit.

## Validation boundary

- Full functional, soak, native-rendered, Linux CI, Web export, and unsigned macOS export gates pass.
- The native profile reached seven navigation agents at Walker density. Walker p95/p99 was 19.735/22.058 ms; a 151.852 ms single-frame wall-time maximum remains tracked.
- Physical iPad Safari comfort/thermal/audio, final difficulty feel, pathing feel, photosensitivity, mix quality, and a target-Mac human playthrough remain explicit human gates.

The macOS ZIP is unsigned and unnotarized. The working title still requires clearance before commercial distribution.

## Artifacts

- `cobie-nukem-0.6.0-alpha.5-itch.zip` — 21,435,476 bytes; SHA-256 `4ed71e5745c1b5f6162fd5c4c4082d55166245a7baf69af78d00f5d15e72190e`.
- `cobie-nukem-0.6.0-alpha.5-macos-unsigned.zip` — 70,799,482 bytes; SHA-256 `78b603eec3a5a2e864340df8a21daca799e93b2f43cac337b572c0283c1a6f62`.
- Web PCK — 11,489,896 bytes; SHA-256 `0249b13ca7036cd73d546c5923a927ce5c528591902947b3218a6e7203e86ac2`.

## Integration

- Gameplay integration: `64ee96f` on `Louisleh/cobie-nukem` through PR #25.
- Release metadata: PR #26.
- Live route after deployment: <https://www.louislehmann.fyi/games/cobie-nukem/>.
