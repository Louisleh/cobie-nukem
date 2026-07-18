# `0.8.0-alpha.1-rc1` release evidence

Date: 2026-07-18  
Engine/export templates: Godot `4.7.stable.official.5b4e0cb0f`  
Runtime feature revision: `7e6684e`  
Build ID: `2026-07-18-whiteout-public-beta-rc1`

## Automated and review evidence

- Explicitly pinned `gpt-5.3-codex-spark` independent review: no Blocker or Critical finding. All three Major findings were fixed: completion checkpoint-cleanup handling, true chairlift rider transport/release, and deployment-independent Web return navigation.
- Full non-export validation: pass.
- `QA_EXPORTS=1 bash tools/release_validate.sh`: pass, including Web and unsigned Universal macOS exports.
- Load/import smoke: 70 scenes and 126 Resources.
- Content validation: three manifests.
- Mount Hood: 300 route simulations, five-zone navigation bake, exact 24 regular-enemy plus one boss contract, Golden Ball gating, and 100 chairlift reset cycles.
- Shared soak: 100 routes, 100 checkpoints, 100 twin-stick cancellations, 500 weapon transitions, and 100 temporary-effect cycles.
- Three-mission headless timing smoke remained within the RC budget. Latest p95/p99: Salmon Creek `22.462/23.863 ms`, Rain City `22.071/24.433 ms`, Mount Hood `23.189/24.386 ms`. Headless timing is stall evidence, not rendered GPU or physical-device evidence.
- Packaged Web at 1024×768 touch: normalized title, RC1 identity, main menu, five-card selector, selectable Mount Hood `BETA`, `START BETA`, and Mount Hood gameplay HUD all render. No warning or error was reported by the game-origin browser console.

## Artifact evidence

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.8.0-alpha.1-rc1-itch.zip` | 55,079,899 | `996fd6cf17e7f9057c18bccf7bc7f24bc3a527f4cf8f81ef106e7698fac14e9a` |
| `cobie-nukem-0.8.0-alpha.1-rc1-macos-unsigned.zip` | 96,377,215 | `45600fa2b05abcb7fe909481b6f15ac325f12e9e82d6c839eaf9c36baaafad79` |
| Packaged Web PCK | 50,162,024 | `40da43cbf6fa484feaf68397d4b58d3add786e3ebb0087ce3ea1b70a2c78ef51` |

The staged public Pages transfer is 92,883,745 bytes: below the 100 MB hard ceiling, but 2,883,745 bytes above the 90 MB aspiration. Mount Hood increases the PCK by 11,933,016 bytes versus public RC5, remaining within the phase's explicit 12 MB Mount Hood allowance. This RC accepts the target miss; optimization remains a measured follow-up and does not weaken the hard ceiling.

Packaging now excludes byte-identical macOS cloud-conflict copies such as `index 2.wasm`. Those files are local sync debris and are absent from the Pages artifact and itch archive.

## Publication ledger

- Source [PR #57](https://github.com/Louisleh/cobie-nukem/pull/57), integrated on `main` at `a03ef8f`.
- GitHub prerelease: [`v0.8.0-alpha.1-rc1`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.8.0-alpha.1-rc1).
- Website [PR #127](https://github.com/Louisleh/louislehmann-site/pull/127), deployed from `main` at `76c1cad` after green site, application, review, and Vercel checks.
- Ordinary and cache-busted public URLs load RC1 at <https://www.louislehmann.fyi/games/cobie-nukem/> and <https://www.louislehmann.fyi/games/cobie-nukem/play/?verify=alpha8&touch=1&v=0.8.0-alpha.1-rc1>. The live browser reports Godot 4.7 Compatibility boot completion with no warning or error log.
- Downloaded public PCK: 50,162,024 bytes, byte-identical SHA-256 `40da43cbf6fa484feaf68397d4b58d3add786e3ebb0087ce3ea1b70a2c78ef51`.
- Rollback artifact: `0.7.0-alpha.1-rc5` remains available; RC1 is now the public baseline.

## Human-only gates

- Rain City remains `BETA`: target-Mac route, Chrome/Safari full routes, physical-iPad route, pacing, Towmaster fairness, art cohesion, mix, humor, touch comfort, and photosensitivity remain open.
- Mount Hood ships as an explicit public-development `BETA`: physical-iPad touch/thermal/audio, target-Mac pacing, final animation/environment art, Snowcat fairness, mix, humor, and photosensitivity remain open.
- macOS output is unsigned and unnotarized. Working-title clearance remains outside this engineering gate.
