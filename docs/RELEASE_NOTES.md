# Release Notes — 0.6.0-alpha.9 Public Beta Focus

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

Source integration, GitHub prerelease, website deployment, and downloaded public PCK identity are recorded after publication.
