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

Final package sizes, SHA-256 hashes, source integration, GitHub prerelease, website deployment, and public PCK identity are recorded after the green release/deployment gate.
