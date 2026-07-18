# Release Notes — 0.9.0-alpha.1-rc1 Five-Mission Public Beta

Built on 2026-07-18 with Godot `4.7.stable.official.5b4e0cb0f`. Runtime feature revision: `257d112`; build ID: `2026-07-18-five-mission-public-beta-rc1`.

## Player-visible changes

- The full five-mission Episode 1 route is now publicly testable. Salmon Creek remains the stable opening benchmark; Rain City, Mount Hood, **Dark Side of Fetch**, and **Pier Pressure** are clearly labelled public-development `BETA` missions.
- Dark Side of Fetch adds five lunar zones, low-gravity movement, five checkpoints and secrets, 28 regular enemy placements, six objectives, and a four-phase 1,000-HP Lunar Compliance Harvester finale.
- Pier Pressure adds five Ventura-coast zones, five checkpoints and secrets, 28 regular enemy placements, six objectives, and a four-phase 1,000-HP Municipal Tidebreaker finale.
- Replay and Continue now follow the active mission. Every finale gates its Golden Tennis Ball behind confirmed boss defeat, summon cleanup, and a persistent defeat state.
- Salmon Creek checkpoints now use save schema v5 and preserve loadout, ammunition, health, and armor while remapping obsolete legacy coordinates to authored anchors.
- Startup, Start-only mission launch, pointer capture, retry, focus recovery, proactive reload, twin-stick cancellation, and scene teardown remain transactional across all five missions.

## Engineering and validation

- One data-driven campaign graph and shared mission-pack, biome, movement-environment, set-piece, checkpoint, encounter, and boss-module contracts host all five missions without mission-specific runtime forks.
- Complete release validation passes 78 scenes, 180 Resources, five content manifests, parser/import, unit, integration, route, content, architecture, provenance/IP, smoke, Web export, and unsigned Universal macOS export gates.
- The deterministic five-mission gauntlet passes 1,200 route simulations and 1,000 checkpoint restores. Focused soaks cover 100 shared routes/checkpoints/touch cancellations/effects, 500 weapon transitions, and repeated Walker, Towmaster, Snowcat, Harvester, and Tidebreaker resets.
- Latest headless p95/p99 mission timing is Salmon Creek `22.1/24.2 ms`, Rain City `23.3/24.6 ms`, Mount Hood `22.0/23.5 ms`, Moon `21.0/23.3 ms`, and Ventura `21.8/22.7 ms`, with zero temporary-object/node drift in the new missions. These are CPU/stall signals, not rendered-GPU or physical-device claims.
- The exact packaged Web build passes desktop and 1024×768 touch flows: normalized boot identity, five-card selection, non-committing hover, explicit `START BETA`, Moon/Ventura launch, twin-stick HUD, death, retry, and menu return.

## Honest RC boundary

- Levels 2–5 remain `BETA`. Physical iPad Safari, full target-Mac and Safari/Chrome routes, final hero/environment animation and audio, pacing, boss fairness, art cohesion, touch comfort, humor, motion comfort, and photosensitivity remain human-only gates.
- Moon and Ventura are complete functional public-beta routes, not falsely claimed final world-class art or balance.
- The macOS ZIP remains unsigned and unnotarized. The working title requires clearance before commercial distribution.

## Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.9.0-alpha.1-rc1-itch.zip` | 55,159,424 | `95024131a5a216f8dbf6820a8d957c859d18581d167529228831e772b0539b36` |
| `cobie-nukem-0.9.0-alpha.1-rc1-macos-unsigned.zip` | 96,454,146 | `5d5e312182c1a9569c35db12e924e0322b05ff9a5a7bb1ea6f731b2d8e2b1b6b` |
| Packaged Web PCK | 50,340,272 | `4cd3e8e71f4c8aa4b89c3fc52f47dcbe0de5f0bc2239f296d1d9ed64554c2192` |

Publication integration, website deployment, and downloaded public-PCK identity are recorded in `docs/RELEASE_0_9_0_ALPHA1_RC1_EVIDENCE.md` only after those gates actually complete.

---

# Prior Release Notes — 0.8.0-alpha.1-rc1 Mount Hood Public Beta

Built on 2026-07-18 with Godot `4.7.stable.official.5b4e0cb0f`. Runtime feature revision: `7e6684e`.

## Player-visible changes

- **Mount Hood Whiteout** is now an always-available third mission under an explicit public `BETA` label: five continuous snowbound zones, six objectives, five checkpoints, four secrets, 24 regular enemies, and a four-phase 1,000-HP Municipal Snowcat finale.
- The mission introduces bounded Full/Reduced/Off snow traction, a reset-safe player-carrying chairlift, Ski-Patrol Rangers, Avalanche Recon Drones, original lodge/lift/mountain scenery, and a post-defeat Golden Ball that appears only after boss summons clear.
- Mission selection now performs truthful asynchronous warmup. `PREPARING…` replaces misleading readiness text, repeated activation cannot overlap scene transitions, and only the explicit Start action launches a selected card.
- Pointer/touch actions are released transactionally across scene handoffs. Web builds derive `RETURN TO SITE` from their actual deployment path; native builds retain Quit.
- Rain City remains public `BETA` while its human/device/art gates remain open. Its production material families now cover every authored support batch rather than only route floors.

## Engineering and validation

- The shared mission-host assembly removes duplicated Rain City/Mount Hood runtime wiring; player interaction targeting moved into a reusable resolver so the player controller remains below the 500-line responsibility gate.
- Mount Hood owns typed mission, route, encounter, presentation, loadout, warmup, traction, and boss Resources. Production navigation bakes successfully and all authored signs pass route-facing/wall-clearance validation.
- An explicitly pinned `gpt-5.3-codex-spark` review found no Blocker or Critical issue. Its three Major findings—checkpoint-cleanup handling, true chairlift rider transport, and deployment-independent Return to Site—were fixed and retested.
- The complete non-export matrix passes 70 scenes, 126 resources, three content manifests, 300 Mount Hood route simulations, 100 chairlift cycles, 100 vertical-slice routes/checkpoints/touch cancellations, 500 weapon transitions, 100 Towmaster cycles, architecture, provenance/IP, and three-mission performance smoke.

## Honest RC boundary

- Mount Hood is a public-development `BETA`, not a final art, animation, balance, audio, or physical-device claim. Target-Mac and physical-iPad route/thermal/audio/touch review remain open.
- Rain City keeps its `BETA` badge until its recorded target-Mac, Safari/Chrome, and physical-iPad human gates pass.
- The macOS ZIP remains unsigned and unnotarized. The working title still requires clearance before commercial distribution.

Published through source [PR #57](https://github.com/Louisleh/cobie-nukem/pull/57) at integration `a03ef8f`, [GitHub prerelease `v0.8.0-alpha.1-rc1`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.8.0-alpha.1-rc1), and website [PR #127](https://github.com/Louisleh/louislehmann-site/pull/127) at deployment `76c1cad`. The downloaded 50,162,024-byte public PCK matches SHA-256 `40da43cbf6fa484feaf68397d4b58d3add786e3ebb0087ce3ea1b70a2c78ef51` exactly.

---

# Prior Release Notes — 0.7.0-alpha.1-rc3 Startup Stability

Built on 2026-07-17 with Godot `4.7.stable.official.5b4e0cb0f`. Runtime feature revision: `ba7c449`; stamped candidate: `4a65031`.

## Player-visible changes since RC2

- Mission cards now select and preview without launching. Gameplay begins only from the explicit `START MISSION` action, with double-launch protection and a clear `SELECTED // PRESS START` state.
- Desktop Web launch preserves the trusted Start-action pointer-lock request through scene startup. Packaged Chrome enters gameplay focused and captured; a released lock is restored by one direct canvas click.
- `R` proactively reloads a partially depleted magazine instead of waiting for empty. The HUD exposes reload availability and progress, while the existing original weapon-specific mechanical samples provide start, step, and completion feedback.
- The previously integrated iPad portrait sizing, two-state Cobie health art, forward-facing Salmon Creek signs, stable connector surfaces, bounded interaction placements, and deterministic Walker finale are included in this exact public candidate.

## Engineering and validation

- Reload presentation observes weapon lifecycle directly from the HUD, keeping `CobiePlayer` under the repository's 500-line responsibility gate.
- Focused UI, input, adversarial-state, imported-audio, and packaged-Web checks cover selection-only cards, explicit launch, pointer capture, proactive reload, and HUD lifecycle feedback.
- The complete release matrix passes parser/import, all unit/integration/content/smoke suites, 100 route/checkpoint/touch/effect cycles, 500 weapon transitions, 100 convoy cycles, architecture/provenance/IP/performance gates, Web export, and unsigned Universal macOS export.
- The exact cache-keyed package passes a fresh 1024×768 Chrome flow with no game-origin console warnings or errors.

## Honest RC boundary

- The Rain City `BETA` badge remains. Physical iPad Safari, target-Mac full routes, Safari completion, pacing, art, mix, fairness, humor, touch comfort, and photosensitivity remain human-only gates.
- The macOS ZIP is unsigned and unnotarized. The working title still requires clearance before commercial distribution.

## Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.7.0-alpha.1-rc3-itch.zip` | 35,790,399 | `422d57137d327597d974e80511e135b987ff6b60545e9c3e47f8c11f6a370221` |
| `cobie-nukem-0.7.0-alpha.1-rc3-macos-unsigned.zip` | 85,155,304 | `976d6172336bb684392bcd7d2e2951837ccc6af7e6cf0158b6cb2d62810a7066` |
| Packaged Web PCK | 26,282,532 | `d4c763ae8e3a74fcd2671992aad520b8866cb01d5dbbcdd6db15f00f2359d2cb` |

Published through source [PR #47](https://github.com/Louisleh/cobie-nukem/pull/47) at integration `93984f1`, [GitHub prerelease `v0.7.0-alpha.1-rc3`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.7.0-alpha.1-rc3), and website [PR #124](https://github.com/Louisleh/louislehmann-site/pull/124) at deployment `03f15c0`. Ordinary/cache-busted public URLs identify RC3, and the downloaded 26,282,532-byte PCK matches SHA-256 `d4c763ae8e3a74fcd2671992aad520b8866cb01d5dbbcdd6db15f00f2359d2cb` exactly.

---

# Prior Release Notes — 0.7.0-alpha.1-rc2 Rain City Stabilization

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
