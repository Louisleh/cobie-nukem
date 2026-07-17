# Release Notes — 0.7.0-alpha.1-rc2 Rain City Stabilization

Built on 2026-07-16 with Godot `4.7.stable.official.5b4e0cb0f`. Runtime feature revision: `0d80348`; stamped candidate: `6228ecd`.

## Player-visible changes since RC1

- Four visible encounter gates prevent route fragmentation and combat-wave skips; replaying a checkpoint re-closes the active gate until the wave is defeated again.
- All four Rain City secrets now grant their authored rewards, save exactly once, and restore ammo, health, armor, and the reduced finale reinforcement state.
- Umbrella shields correctly block/drain frontal hits, expose attack windows, reward rear flanks, and remain broken after depletion.
- Compliance Gulls use one physics movement authority and retain one CombatPressure token through their dive/recovery lifecycle.
- Ground enemies require a clear attack path, use difficulty-scaled damage, and recover from unreachable navigation only within a bounded local radius.
- Pickup collision roots remain grounded while only their visual children bob and spin.

## Engineering and validation

- Campaign completion is transactional: campaign progress must save and the completed checkpoint must delete before victory; either failure preserves a retry path.
- Checkpoints only announce after successful writes, secret rewards are included in the saved snapshot, and test saves are isolated from real player data.
- A serialized Godot runner adds per-project locking, stale-lock recovery, bounded timeouts, descendant cleanup, and unique logs. It prevents interrupted Codex tests from accumulating competing Godot processes—the root cause of the repeated local crash notifications.
- Production Rain City navigation is baked and verified once; mission-host tests no longer launch five redundant bakes.
- Rain City assembly, completion flow, and secret policy are extracted; all production scripts pass the 500-line architecture gate except the documented Salmon Creek legacy exemption.
- The complete export matrix passes parser/import, unit/integration/content/smoke, 100 route/checkpoint/touch/effect cycles, 500 weapon transitions, 100 convoy cycles, provenance/IP, architecture, drift/performance, Web export, and unsigned Universal macOS export gates.
- The exact packaged Web build passes a 1024×768 Chrome startup check: normalized title, first-tap activation, responsive menu, fitted mission selection, and no game-origin console errors.

## Honest RC boundary

- The `BETA` badge and opening warning remain. Physical iPad Safari, target-Mac 15–22 minute playthrough, Chrome/Safari completion, Story/Mayhem feel, boss fairness, art cohesion, mix, humor, and photosensitivity are human-only finalization gates.
- Mount Hood, Moon, and Ventura remain locked illustrated teasers.
- The macOS ZIP remains unsigned and unnotarized. The working title still requires clearance before commercial distribution.

## Artifacts and integration

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.7.0-alpha.1-rc2-itch.zip` | 35,359,299 | `a73918c42de978674c435b289f115a6889c3d870332062d694dbf67730619929` |
| `cobie-nukem-0.7.0-alpha.1-rc2-macos-unsigned.zip` | 84,723,809 | `98c215c24da7bf671f618a5cc3f293e7a85b48a4a3394ff6cc52f1cff2dd9b6a` |
| Packaged Web PCK | 25,851,096 | `03a3fe985217b303bc90bad881fd79760761e9119aff696091a29d0e7906abe2` |

Published through source [PR #42](https://github.com/Louisleh/cobie-nukem/pull/42) at integration `e016e44`, [GitHub prerelease `v0.7.0-alpha.1-rc2`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.7.0-alpha.1-rc2), and `Louisleh/louislehmann-site` [PR #123](https://github.com/Louisleh/louislehmann-site/pull/123) at deployment `c0d7171`. Ordinary and cache-busted public URLs identify RC2, and the downloaded public PCK matched the packaged 25,851,096-byte artifact and SHA-256 `03a3fe985217b303bc90bad881fd79760761e9119aff696091a29d0e7906abe2` exactly.

---

# Prior Release Notes — 0.6.0-alpha.9 Public Beta Focus

Built on 2026-07-14 with Godot `4.7.stable.official.5b4e0cb0f`. Runtime feature revision: `c00d54c`.

## Player-visible changes

- Vancouver Waterfront is now playable from the normal mission selector as a clearly marked `BETA` preview.
- The Vancouver card, launch action, status message, and opening caption all state that the mission is a public work in progress.
- Browser mouse aiming is requested directly from the mission-launch gesture instead of waiting until the new player scene is already loading.
- If a browser releases or declines pointer lock, the HUD shows `CLICK TO AIM • ESC FOR MENU`; the activation click is consumed and never doubles as a shot.
- Web canvas pointer-down restores keyboard focus, reducing silent menu/input disconnection after tab or window changes.
- Vancouver grants a ten-second opening/retry protection window. Desktop Web players also remain protected while the game is visibly waiting for pointer activation.

## Engineering and regression coverage

- Pointer-lock ownership moved into a dedicated scene-owned `PointerCaptureController`, keeping the player controller below the repository's 500-line responsibility gate.
- Level-card release state is data-driven through `release_badge`, `launch_notice`, `status_badge()`, and `is_preview_release()` rather than a Vancouver-specific UI branch.
- UI, input, gameplay-foundation, Vancouver content/host, and adversarial suites cover the beta route, badge/warning, touch isolation, rejected-capture behavior, first-click request, protection window, and prompt click-through.
- Packaged Web browser evidence covers title readiness, menu navigation, the visible `BETA` card, `START BETA`, work-in-progress status, Vancouver launch, and the recovery prompt. Physical-device and full human-route claims remain open.

## Validation boundary

- Salmon Creek remains the definitive polished slice. Vancouver is intentionally public and unfinished; its art, encounter feel, pacing, navigation clarity, mix, and complete human playthrough are not claimed complete.
- Browser pointer lock still requires a trusted user gesture by platform policy. Alpha.9 makes that state explicit, safe, and one-click recoverable rather than attempting to bypass it.
- Physical iPad Safari comfort/thermal/audio, full Chrome/Safari routes, boss/difficulty/interaction feel, art, mix, humor, and photosensitivity remain human-only gates.
- The macOS ZIP is unsigned and unnotarized. The working title still requires clearance before commercial distribution.

## Artifacts and integration

The exact stamped candidate at source revision `08e24deb25930dfae8b6f2a1eafe0de38ab40565` passed `QA_EXPORTS=1 bash tools/release_validate.sh` and produced:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.6.0-alpha.9-itch.zip` | 33,406,380 | `66070b5495b8d601310c05e9a9124a3dacc7a034693e085b9cadc37a34f6d969` |
| `cobie-nukem-0.6.0-alpha.9-macos-unsigned.zip` | 82,771,158 | `1bbd378daffcffec5a872f335f1002edcf701b3872859fa173115a53e2fd9d74` |
| Web PCK | 23,801,320 | `a44af5d67ca30ccc3c69b315ae09286e5e299a0bd0a0dc3a1f31a918dea6e98c` |

Published through source [PR #34](https://github.com/Louisleh/cobie-nukem/pull/34) at integration `7326ff6`, [GitHub prerelease `v0.6.0-alpha.9`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.6.0-alpha.9), and `Louisleh/louislehmann-site` [PR #100](https://github.com/Louisleh/louislehmann-site/pull/100) at deployment `13eba81`. Ordinary and cache-busted public URLs identify Alpha.9 and its cache-keyed assets. The downloaded public 23,801,320-byte PCK matched SHA-256 `a44af5d67ca30ccc3c69b315ae09286e5e299a0bd0a0dc3a1f31a918dea6e98c` exactly.
