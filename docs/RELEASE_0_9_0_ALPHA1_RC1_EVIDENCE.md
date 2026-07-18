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

- Source PR/integration: pending.
- GitHub prerelease: pending.
- Website PR/deployment: pending.
- Downloaded public PCK identity: pending.
- Rollback: `0.8.0-alpha.1-rc1` remains the byte-verified public baseline until deployment completes.

## Human-only gates

- Rain City, Mount Hood, Moon, and Ventura remain explicit `BETA` missions.
- Target-Mac and physical-iPad full routes, Safari/Chrome completion, final art/animation/audio, pacing, boss fairness, combat readability, touch comfort, humor, motion comfort, photosensitivity, and thermal behavior remain open.
- macOS output is unsigned and unnotarized. Working-title clearance remains outside this engineering gate.
