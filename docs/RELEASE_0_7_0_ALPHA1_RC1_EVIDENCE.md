# Rain City Run `0.7.0-alpha.1-rc1` release evidence

**Candidate date:** 2026-07-16  
**Engine:** Godot `4.7.stable.official.5b4e0cb0f`  
**Runtime feature revision:** `3144a22`  
**Stamped source revision:** `3d46c465a1389d31129544179b57c050db414375`  
**Build ID:** `2026-07-16-rain-city-rc1`

This is an honestly labelled public RC. Automated validation supports publication, but it does not close the physical-iPad, complete human playthrough, balance, art, mix, humor, or photosensitivity gates. The Rain City `BETA` badge and warning remain.

## Automated validation

- `QA_EXPORTS=1 bash tools/release_validate.sh` passed after the final lifecycle, checkpoint, boss, Gull, floor-recovery, and architecture corrections.
- The matrix covered parser/import validation, the complete unit/integration/content/smoke suite, 100 route and checkpoint cycles, 100 focus/touch cycles, 500 weapon transitions, 100 convoy cycles, asset/IP scanning, the 500-line architecture gate, content validation, Web export, and unsigned Universal macOS export.
- Focused final performance smoke: average `16.658 ms`, p50 `16.117 ms`, p95 `21.518 ms`, p99 `22.818 ms`, maximum `24.726 ms`; nodes remained `645 → 645`, memory declined by 40,136 bytes, and the test emitted no engine errors, leaks, or orphan warnings. This is headless stall evidence, not rendered GPU evidence.
- Independent focused review found and closed stale checkpoint coordinates, legacy Vancouver unlock regression, convoy/module gating, post-victory resurrection, discontinuous boss health, non-functional Recall Override module stagger, pier floor recovery, Gull dive lifecycle, and duplicated/mistimed cues. The attempted final pinned Spark CLI reviewer was stopped after failing to return a bounded structured result; its output is not counted as release evidence. Root re-ran the complete matrix after every accepted correction.

## Packaged browser evidence

- The exact `builds/pages` package opened in Chrome at `1024×768` with `?touch=1&verify=rain-city-rc1`.
- The normalized loading/title presentation rendered at the target aspect ratio.
- The first tap advanced immediately to the main menu; `NEW GAME` opened the mission selector without a second focus-recovery action.
- The title, menu, difficulty controls, mission cards, status bar, and navigation actions fit the 4:3 viewport.
- Chrome reported no game-origin error. Browser-extension warnings were excluded because their URLs originated from installed extension content scripts rather than the packaged game.
- A fresh campaign correctly showed Rain City as campaign-locked. Full mission completion in Chrome/Safari and physical iPad simultaneous-twin-stick behavior remain human gates.

## Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.7.0-alpha.1-rc1-itch.zip` | 35,345,432 | `1d9529e67804c5e2cd053fa9af2c94ee28a9d33745e7cbcf3e06d07e0f6a1784` |
| `cobie-nukem-0.7.0-alpha.1-rc1-macos-unsigned.zip` | 84,711,021 | `76a5ddedc30e938b4e5e86c89d7d6f8736df1310ef88916df5c7e799f84d44a3` |
| Packaged Web PCK | 25,836,140 | `462120a8057db93badb1d8b033701fbca31187326031ee4617a6b0bec787bc8d` |
| Packaged Web WASM | 39,509,339 | `7eda98958eb09135a1acb54a4323a00b1a55af1997f15fa1cdc2b93e3df46656` |

The packaged Web directory is approximately 65 MB and remains below the 90 MB target and 100 MB hard ceiling. The macOS artifact is unsigned and unnotarized.

## Publication ledger

- Source [PR #40](https://github.com/Louisleh/cobie-nukem/pull/40) passed `validate-package` and was squash-merged to `main` at `1dcb28c88f3201ffca52284f93beaec735a9425e`.
- GitHub prerelease [`v0.7.0-alpha.1-rc1`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.7.0-alpha.1-rc1) contains the exact itch/Web and unsigned macOS packages plus `BUILD_INFO.txt` and `SHA256SUMS.txt`.
- Website [PR #122](https://github.com/Louisleh/louislehmann-site/pull/122) passed repository hygiene, curated build, route verification, app checks, review, and Vercel preview before squash merge at `ecfdcd6ff1182e1fe2bc454588e853155a7ca6d8`.
- Ordinary and cache-busted apex/`www` URLs identify `0.7.0-alpha.1-rc1` and runtime revision `3144a22`.
- The downloaded public PCK is 25,836,140 bytes and matches the packaged SHA-256 exactly: `462120a8057db93badb1d8b033701fbca31187326031ee4617a6b0bec787bc8d`.
- The public 1024×768 touch-forced title accepted its first tap and entered the responsive main menu with no game-origin Chrome error.
- `0.6.0-alpha.10` remains the immediate rollback release.

## Human gates still open

- One clean 15–22 minute target-Mac Classic playthrough.
- Story and Mayhem spot checks across every Rain City encounter and Towmaster phase.
- One physical iPad Safari playthrough covering both sticks, action buttons, app switching, audio, and thermals.
- Chrome and Safari desktop mission completion.
- Human assessment of route clarity, encounter and boss fairness, Gull/shield readability, touch comfort, art cohesion, music/mix, humor, and photosensitivity.
