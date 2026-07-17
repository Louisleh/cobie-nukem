# Release Notes — 0.7.0-alpha.1-rc1 Rain City Run

Candidate built on 2026-07-16 with Godot `4.7.stable.official.5b4e0cb0f`. Final source revision, artifact hashes, PRs, release URL, deployment commit, and public PCK identity are appended after the release gate succeeds.

## Player-visible changes

- Rain City Run becomes the campaign's second mission, unlocked by completing Salmon Creek, with mission-aware Replay and `CONTINUE TO RAIN CITY` continuity.
- Five authored zones replace the straight beta corridor: Downtown Service Alley, Rain City Slice, Waterfront Seawall, Terminal Service, and Harbour Pier.
- The mission contains four secrets, 26 authored enemies, the new Compliance Gull, a production eight-direction Umbrella Shield Enforcer, original environmental jokes, and bounded Story/Classic/Mayhem pressure.
- Terminal Service awards Municipal Recall Override, improving Fetch recall speed and first-contact shield/module stagger without adding primary damage.
- The Municipal Towmaster is a four-phase 1,000-HP finale with ordered modules, reinforcement warnings, boss HUD/captions, authored audio, bounded ticket/spark effects, and a persistent wreck.
- Rain City receives original Blender environment/convoy assets, Material Maker source families, and 27 imported Gull/Umbrella/convoy audio variations.

## Engineering and validation

- Save schema v5 adds deterministic v4 migration, content-revision checkpoint remapping, mission loadouts/upgrades, and campaign/checkpoint isolation.
- Gameplay layout/collision/navigation remain independent of replaceable presentation art.
- Mission warning/audio routing, loadouts, set-piece path/phase state, Rain City checkpoint state, and convoy presentation now have focused owners; all production scripts meet the 500-line architecture gate except the documented Salmon Creek legacy exemption.
- The non-export matrix passes parser/import, unit/integration/content/smoke, 100 route/checkpoint/touch/effect cycles, 500 weapon transitions, 100 convoy cycles, provenance/IP, architecture, and drift/performance gates.

## Honest RC boundary

- The `BETA` badge and opening warning remain. Physical iPad Safari, target-Mac 15–22 minute playthrough, Chrome/Safari completion, Story/Mayhem feel, boss fairness, art cohesion, mix, humor, and photosensitivity are human-only finalization gates.
- Mount Hood, Moon, and Ventura remain locked illustrated teasers.
- The macOS ZIP remains unsigned and unnotarized. The working title still requires clearance before commercial distribution.

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
