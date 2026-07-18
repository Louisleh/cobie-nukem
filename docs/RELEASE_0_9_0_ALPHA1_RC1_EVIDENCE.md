# `0.9.0-alpha.1-rc1` release evidence

Date: 2026-07-18

Engine/export templates: Godot `4.7.stable.official.5b4e0cb0f`

Runtime feature revision: `257d112`

Source stamp revision: `b4aad283580be13b268e286d23601313fc6dfb69`

Build ID: `2026-07-18-five-mission-public-beta-rc1`

## Automated evidence

- Full non-export `bash tools/release_validate.sh`: pass.
- Full `QA_EXPORTS=1 bash tools/release_validate.sh`: pass, including Web and unsigned Universal macOS exports.
- Load/import smoke: 78 scenes and 180 Resources.
- Content validation: five mission manifests and the complete asset/provenance/IP ledger.
- Five-mission gauntlet: 1,200 deterministic route simulations and 1,000 checkpoint restores.
- Shared soak: 100 routes, 100 checkpoints, 100 twin-stick/focus cancellations, 500 weapon transitions, and 100 temporary-effect cycles.
- Boss/finale coverage: Walker, Towmaster, Snowcat, Lunar Compliance Harvester, and Municipal Tidebreaker defeat, reset, checkpoint, summon-cleanup, and post-defeat Golden Ball contracts.
- Latest headless p95/p99: Salmon Creek `22.1/24.2 ms`, Rain City `23.3/24.6 ms`, Mount Hood `22.0/23.5 ms`, Moon `21.0/23.3 ms`, and Ventura `21.8/22.7 ms`. Moon and Ventura return object/node counts to baseline. Headless timing is CPU/stall evidence, not rendered GPU or physical-device evidence.
- Packaged Web: desktop and 1024×768 touch flows render the exact RC identity, all five cards, explicit selection/start boundaries, Moon and Ventura gameplay, twin-stick HUD, death/retry, and menu return.

## Artifact evidence

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.9.0-alpha.1-rc1-itch.zip` | 55,159,408 | `2a5a43d06b4c115fb25b163061613edbc6bcc3b9494f58c9df11f14c519d0ed0` |
| `cobie-nukem-0.9.0-alpha.1-rc1-macos-unsigned.zip` | 96,454,137 | `dcee949fc7e9987eb03db69bdeeb663674cb7f5fc6c501bf310bc5b3b624398a` |
| Packaged Web PCK | 50,340,256 | `56c1c49d3c0ffff180ba79eaba754055b4970a2e7f8718abc20f2fbf2d9b5d5d` |

The staged Web export is 86 MiB and remains below the 90 MB target and 100 MB hard ceiling.

## Publication ledger

- Source [PR #59](https://github.com/Louisleh/cobie-nukem/pull/59), integrated on `main` at `3854023` after green `validate-package` CI.
- GitHub prerelease: [`v0.9.0-alpha.1-rc1`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.9.0-alpha.1-rc1), carrying the exact two archives, build identity, and checksum ledger.
- Website [PR #128](https://github.com/Louisleh/louislehmann-site/pull/128), deployed from `main` at `7392826` after all six PR checks, all three post-merge CI jobs, and Vercel Production succeeded.
- Ordinary and cache-busted public URLs render `v0.9.0-alpha.1-rc1 • 257d112 • 2026-07-18-five-mission-public-beta-rc1`, expose all five cards, preserve Levels 2–5 `BETA`, and launch only through the explicit Start action.
- Downloaded public PCK: 50,340,256 bytes, byte-identical SHA-256 `56c1c49d3c0ffff180ba79eaba754055b4970a2e7f8718abc20f2fbf2d9b5d5d`.
- Chrome DevTools production trace reports 209 ms landing-page LCP, `0.00` CLS, and no game-origin error/issue messages. The single pre-input Web Audio warning is the expected browser autoplay gate and clears through the existing first-gesture audio unlock path.
- Rollback: `0.8.0-alpha.1-rc1` remains available as the prior byte-verified release.

## Human-only gates

- Rain City, Mount Hood, Moon, and Ventura remain explicit `BETA` missions.
- Target-Mac and physical-iPad full routes, Safari/Chrome completion, final art/animation/audio, pacing, boss fairness, combat readability, touch comfort, humor, motion comfort, photosensitivity, and thermal behavior remain open.
- macOS output is unsigned and unnotarized. Working-title clearance remains outside this engineering gate.
