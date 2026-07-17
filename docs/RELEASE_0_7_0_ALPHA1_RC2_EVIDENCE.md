# Rain City Run `0.7.0-alpha.1-rc2` release evidence

**Candidate date:** 2026-07-16

**Engine:** Godot `4.7.stable.official.5b4e0cb0f`

**Runtime feature revision:** `0d80348`

**Stamped candidate revision:** `6228ecd671eaec7bf4eb8e03cb809cef3a82494b`

**Build ID:** `2026-07-16-rain-city-rc2`

This remains an honestly labelled public RC. Automated validation supports publication but does not close physical-iPad, complete human playthrough, encounter feel, art, mix, humor, or photosensitivity gates. The Rain City `BETA` badge and warning remain.

## Crash and stabilization outcome

- The repeated macOS crash notifications correlated with orphaned Codex-launched Godot tests, duplicate MCP hosts, and an old editor process competing against one project.
- `tools/run_godot_safe.sh` now serializes the project, bounds every invocation, cleans descendants, recovers stale locks, isolates test state, and owns unique logs.
- No new Godot crash report occurred during focused tests, complete soak, rendered profiling, full export validation, or packaging.
- Four independent-review Majors were found and closed before release: restored-secret interaction teardown, pre-reward checkpoint snapshots, victory after checkpoint-delete failure, and open gates during replayed encounters.

## Automated validation

- `QA_EXPORTS=1 GODOT_BIN=/opt/homebrew/bin/godot bash tools/release_validate.sh`: pass on the exact stamped candidate.
- Complete parser/import, unit, integration, content, asset/IP, architecture, smoke, Web export, and unsigned Universal macOS export matrix: pass.
- Soak: 100 routes, 100 checkpoint cycles, 100 twin-stick cancellations, 500 weapon transitions, 100 effects, and the dedicated convoy boss soak.
- Headless stall smoke: Salmon Creek p95/p99 `22.727/23.576 ms`; Rain City `21.649/23.822 ms`; no positive node drift.
- Native M4 1280×720 Compatibility Rain City profile: p95/p99 between `18.30/23.36 ms`, 195–406 draw calls, approximately 83 MB static memory.
- Independent full-diff review disposition: APPROVE, no remaining Blocker/Critical/Major issue.

## Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.7.0-alpha.1-rc2-itch.zip` | 35,359,299 | `a73918c42de978674c435b289f115a6889c3d870332062d694dbf67730619929` |
| `cobie-nukem-0.7.0-alpha.1-rc2-macos-unsigned.zip` | 84,723,809 | `98c215c24da7bf671f618a5cc3f293e7a85b48a4a3394ff6cc52f1cff2dd9b6a` |
| Packaged Web PCK | 25,851,096 | `03a3fe985217b303bc90bad881fd79760761e9119aff696091a29d0e7906abe2` |
| Packaged Web WASM | 39,509,339 | `7eda98958eb09135a1acb54a4323a00b1a55af1997f15fa1cdc2b93e3df46656` |

## Publication ledger

- Source [PR #42](https://github.com/Louisleh/cobie-nukem/pull/42) merged at integration `e016e44c072c6730f5b1bc636d1c6f66807ed47b`.
- GitHub prerelease [`v0.7.0-alpha.1-rc2`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.7.0-alpha.1-rc2) contains the exact validated Web and unsigned Universal macOS packages.
- Website [PR #123](https://github.com/Louisleh/louislehmann-site/pull/123) deployed at `c0d7171cc9083093fc6b4f5e3099f45e87c27955`.
- Ordinary and cache-busted public URLs identify RC2. The downloaded 25,851,096-byte public PCK matched SHA-256 `03a3fe985217b303bc90bad881fd79760761e9119aff696091a29d0e7906abe2` exactly.
- Immediate rollback: `0.7.0-alpha.1-rc1`.

## Public browser evidence

- A fresh 1024×768 touch-forced Chrome run displayed the RC2 loading identity and then the ready title prompt.
- The first activation click entered a responsive main menu; no menu-resume workaround was required.
- Mission selection fit the 4:3 viewport, and a fresh campaign correctly kept Rain City locked behind Salmon Creek completion.
- No game-origin console error occurred. Browser-extension/content-script warnings were identified separately and excluded from game evidence.

## Human gates still open

- One clean 15–22 minute target-Mac Classic playthrough and Story/Mayhem spot checks.
- Physical iPad Safari full route with simultaneous twin sticks, actions, focus/app switching, audio, and thermals.
- Chrome and Safari desktop mission completion.
- Human assessment of route clarity, enemy/convoy physics and fairness, touch comfort, art cohesion, mix, humor, and photosensitivity.
