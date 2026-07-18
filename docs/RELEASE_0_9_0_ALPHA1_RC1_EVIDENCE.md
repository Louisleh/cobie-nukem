# `0.9.0-alpha.1-rc1` release evidence

Date: 2026-07-18

Engine/export templates: Godot `4.7.stable.official.5b4e0cb0f`

Runtime feature revision: `df84813`

Source stamp revision: `0f6bacc5a14e2af3a13f76ec65c72c7ed89785bd`

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
| `cobie-nukem-0.9.0-alpha.1-rc1-itch.zip` | 55,159,424 | `95024131a5a216f8dbf6820a8d957c859d18581d167529228831e772b0539b36` |
| `cobie-nukem-0.9.0-alpha.1-rc1-macos-unsigned.zip` | 96,454,146 | `5d5e312182c1a9569c35db12e924e0322b05ff9a5a7bb1ea6f731b2d8e2b1b6b` |
| Packaged Web PCK | 50,340,272 | `4cd3e8e71f4c8aa4b89c3fc52f47dcbe0de5f0bc2239f296d1d9ed64554c2192` |

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
