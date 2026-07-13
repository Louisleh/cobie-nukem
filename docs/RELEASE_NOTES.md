# Release Notes — 0.6.0-alpha.7 Spark Interaction Slice

Built on 2026-07-13 with Godot `4.7.stable.official.5b4e0cb0f`. Runtime feature revision: `eb66cf8`.

## Player-visible changes

- Salmon Creek now contains 16 authored environmental interactions across its major arenas: breakables, explosive props, hazards, loot containers, and a persistent secret.
- The Walker fight has explicit phase floors, weak-point windows, bounded summons, recovery drops, a clear pressure lane, and deterministic reset behavior.
- Critical narrative, objective, enemy-warning, boss-phase, checkpoint, and PA cues use a bounded priority-caption system.
- The full twin-stick tablet layout remains first-class: left movement, right aiming, action controls, focus recovery, cancellation, handedness, opacity, and responsive layout contracts.
- Vancouver Waterfront now has a typed production route and three-wave citation-convoy foundation, but remains intentionally locked and non-public.

## Production improvements

- A committed Spark orchestration skill and six pinned `gpt-5.3-codex-spark` roles make bounded implementation, testing, content, audit, accessibility, and review work reproducible while root retains architecture and release ownership.
- Salmon Creek interaction construction, stable IDs, callbacks, restore, and reset moved into `MissionInteractionRuntime`.
- Interaction and Walker tuning are typed Resources with content validation and focused regression coverage.
- The release matrix covers 100 routes, 100 checkpoint/death/restarts, 100 touch/focus cancellations, 500 weapon transitions, low-frame projectile behavior, content/IP/architecture gates, Web export, and Universal macOS export.

## Validation boundary

- Native rendered gameplay p95 is 17.175–19.581 ms on the target M4 Mac. One 104.345 ms tunnel sample and one 165.351 ms Walker sample remain explicitly tracked.
- The exact packaged build passed desktop and 1024×768 forced-touch browser checks through title, menu, mission selection, gameplay, full twin-stick layout, and live right-stick aim response.
- Physical iPad Safari comfort/thermal/audio, full human playthrough, boss/difficulty feel, interaction usefulness, mix, humor, and photosensitivity remain human-only gates.
- The macOS ZIP is unsigned and unnotarized. The working title still requires clearance before commercial distribution.

## Artifacts

- `cobie-nukem-0.6.0-alpha.7-itch.zip` — 26,183,196 bytes; SHA-256 `7e50a546f75cc8cb7432e8653537549be49809325fcc5d246469d5f7f68bd59a`.
- `cobie-nukem-0.6.0-alpha.7-macos-unsigned.zip` — 75,547,579 bytes; SHA-256 `35a35380b659ddf031db3442adc1d5e1a5b7591d5eef3c86d34609d7d34eabde`.
- Web PCK — 16,323,388 bytes; SHA-256 `f9f11d5e419519b2fde01b57d2f46c8c56c1fe0e8baddd02176d3ee2835d0af6`.

## Integration

- Source integration: `4161363` through [PR #29](https://github.com/Louisleh/cobie-nukem/pull/29).
- GitHub prerelease: [v0.6.0-alpha.7](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.6.0-alpha.7).
- Website deployment: `0854ef4` through `Louisleh/louislehmann-site` [PR #98](https://github.com/Louisleh/louislehmann-site/pull/98).
- Live route: <https://www.louislehmann.fyi/games/cobie-nukem/>. The uncached public landing, stamped title, 1024×768 twin-stick gameplay, and downloaded PCK hash were verified after deployment with no browser warnings/errors.
