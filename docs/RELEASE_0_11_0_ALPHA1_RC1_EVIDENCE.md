# `0.11.0-alpha.1-rc1` release evidence

Date: 2026-07-18

Engine/export templates: Godot `4.7.stable.official.5b4e0cb0f`

Runtime feature revision: `3c2de29`

Build ID: `2026-07-18-doghouse-progression-rc1`

## Automated evidence

- Full non-export `bash tools/release_validate.sh`: pass.
- Save schema v6 migration, corrupt/future rejection, atomic writes, campaign/checkpoint isolation, collection idempotency, wallet/purchase/equip rules, result calculation, challenge evaluation, backup-code integrity, Off-Leash mode, and owned-loadout restoration: pass.
- Load/import smoke: 79 scenes and 183 Resources.
- Content/architecture/asset-IP validation: five mission manifests; all production controllers remain within their responsibility limits.
- Five-mission gauntlet: 1,200 deterministic route simulations and 1,000 checkpoint restores.
- Shared soak: 100 routes, 100 checkpoints, 100 twin-stick/focus cancellations, 500 weapon transitions, and 100 temporary-effect cycles.
- Doghouse rendered natively and at 1024×768 with all stations, wallet, records, controls, and content inside the safe layout.
- Independent `gpt-5.3-codex-spark` review: no Blocker or Critical finding; one Major checkpoint-ownership finding fixed and regression-tested.

## Export and artifact evidence

- Full `QA_EXPORTS=1 bash tools/release_validate.sh`: pass, including Web and unsigned Universal macOS exports.
- Package source stamp: `6d9dae914cbad46d461d414c5bf683aea61a1306`; runtime revision remains `3c2de29`.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.11.0-alpha.1-rc1-itch.zip` | 74,238,200 | `2a6d149a7da206f57ed726df374bb81994ea918a1521ad3fc05f95e929599cfd` |
| `cobie-nukem-0.11.0-alpha.1-rc1-macos-unsigned.zip` | 115,537,576 | `da62f5505b4f5d876ae8b1c99a6b71ae59cab01c8fc9824c6cedea09d1f464df` |
| Packaged Web PCK | 69,554,484 | `1d86d7747dd73f4a8f120da85d832a816018dbbfdcb8d01a1089e23f45e16501` |

## Publication evidence

- Source integration: [PR #63](https://github.com/Louisleh/cobie-nukem/pull/63), merge `6e107e7`.
- GitHub prerelease: [`v0.11.0-alpha.1-rc1`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.11.0-alpha.1-rc1); uploaded ZIP digests match the locally packaged artifacts.
- Website deployment: [PR #130](https://github.com/Louisleh/louislehmann-site/pull/130), squash `32bcd39`.
- Packaged and production-browser startup both reached the stamped title and Doghouse hub with no browser error/warning output attributable to the game.
- Ordinary and cache-busted production URLs serve `0.11.0-alpha.1-rc1` / runtime revision `3c2de29`.
- The downloaded public PCK is exactly 69,554,484 bytes and matches packaged SHA-256 `1d86d7747dd73f4a8f120da85d832a816018dbbfdcb8d01a1089e23f45e16501`.
- Rollback release: [`v0.10.0-alpha.1-rc1`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.10.0-alpha.1-rc1).

## Human-only gates

- Economy/reward feel, collectible visibility and route placement, replay motivation, challenge balance, and Off-Leash pacing require human play.
- Physical iPad Safari touch/storage/thermal/audio and target-Mac/Safari/Chrome full routes remain open.
- Levels 2–5 remain explicit `BETA`; macOS is unsigned/unnotarized and working-title clearance is separate.
