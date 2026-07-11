# Release Notes — 0.1.0 Vertical Slice RC

Built on 2026-07-10 with Godot `4.7.stable.official.5b4e0cb0f` and matching official export templates.

## Included

- Complete title-to-victory Episode 1 level with six zones, three secrets, checkpoint, three weapons, three regular enemies, Compliance Hound elite, and four-phase Animal Control Walker finale.
- Keyboard/mouse, generic gamepad, Classic 1996 flight-stick, and Hybrid profiles.
- Input diagnostics, calibration, response curves, inversion, remapping, conflicts, persistence, and report export.
- Cover-led title/menu presentation, HUD, pause/death/victory screens, accessibility options, original procedural audio, and 320×180 retro rendering.
- Headless unit, integration, scene/resource, performance, and asset/IP heuristic checks.

## Local artifacts

- `builds/macos/CobieNukem.zip` — 59 MB unsigned Universal macOS build; SHA-256 `201fe19527c78ae8cc07beff842f1e20629ac97b40141352aac2d1281f061df3`.
- `builds/web/index.html` — single-threaded Web entry; SHA-256 `7e165e130bd873fdfbed0013325550dffc508427886f570f94c34c82f8e04339`.
- `builds/web/index.wasm` — SHA-256 `7eda98958eb09135a1acb54a4323a00b1a55af1997f15fa1cdc2b93e3df46656`.
- `builds/web/index.pck` — SHA-256 `e9c5b768ee19a276752c1c095b9928f161e77ba07ef7b9583a6d6b15373dd886`.

## Validation

- All automated suites passed; 51 scenes and 28 resources load.
- Headless 180-frame level smoke averaged 6.830 ms with an 8.532 ms maximum. This detects stalls but is not GPU performance evidence.
- Web UI was interactively checked in the in-app Chromium browser from title → menu → diagnostics and title → menu → gameplay. No browser console errors or warnings were observed.
- The macOS and Web release exports completed successfully.

## Release gates still requiring owner hardware

- Full human keyboard/mouse playthrough and encounter-feel signoff.
- Chrome and Safari full playthrough matrix on the target Mac.
- Physical Thrustmaster 2960623 calibration, 20-minute stability, reconnect, saved-binding, and full-level test through the intended adapter/hub.
- macOS signing/notarization and working-title legal review before public distribution.
