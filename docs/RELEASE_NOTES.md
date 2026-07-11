# Release Notes — 0.1.0 Vertical Slice RC

Built on 2026-07-11 with Godot `4.7.stable.official.5b4e0cb0f` and matching official export templates.

## Included

- Complete title-to-victory Episode 1 level with six zones, three secrets, checkpoint, three weapons, three regular enemies, Compliance Hound elite, and four-phase Animal Control Walker finale.
- Keyboard/mouse, generic gamepad, Classic 1996 flight-stick, and Hybrid profiles.
- Input diagnostics, calibration, response curves, inversion, remapping, conflicts, persistence, and report export.
- Compact Input Setup presentation with visible default keyboard/mouse mappings and independently scrollable diagnostics panels.
- Cover-led title/menu presentation, HUD, pause/death/victory screens, accessibility options, original procedural audio, and 320×180 retro rendering.
- Reliable overlap-safe pickup collection, explicit access-collar HUD state, and first-frame Web canvas sizing.
- Continuous Secret Dog Park doorway/floor geometry and resilient zone-triggered Compliance Lab/Fetch Guard progression.
- Correct player-layer progression detection plus route-position fallbacks for all four post-opening encounters.
- World-anchored pickups, grounded-enemy floor recovery, gravity-free drone hovering, and a normalized loading splash before the Web canvas becomes visible.
- Deterministic Up/Down weapon cycling, calibrated knockback and HP tiers with numeric labels, aggressive Walker approach behavior, full-state pickup collection, and enemy-colliding Fetch-ball rebounds.
- QA-review pass: first-shot/12-second opening aggro grace, reduced opening DPS, compact fixed-size HP presentation, reliable three-read sign secret, deterministic checkpoint continuation, Escape/modal/focus-loss safety, debounced wheel weapon aliases, FOV/run-mode/subtitle options, keyboard-follow and wheel scrolling, input-grid fitting, mouse-delta clamping, portable asset validation, storm/rain/field dressing, shed roof, hidden open doors, and enemy death debris.
- Headless unit, integration, scene/resource, performance, and asset/IP heuristic checks.

## Local artifacts

- `builds/macos/CobieNukem.zip` — unsigned Universal macOS build; SHA-256 `b0c2211cf2d119983c4c66ef16b74435f26de4cb41aa3013d1b7d2e8fd0ae8f0`.
- `builds/web/index.html` — single-threaded Web entry; SHA-256 `91978ecd7f56576c70e7a9f5c0fa360c73be3b0725656f32cf3fd3caa9856b46`.
- `builds/web/index.wasm` — SHA-256 `7eda98958eb09135a1acb54a4323a00b1a55af1997f15fa1cdc2b93e3df46656`.
- `builds/web/index.pck` — SHA-256 `c2214b6cdde1f681ee8af702c0a01bc02fe1f98afae921babc16718d7bf3639b`.

## Validation

- All automated suites passed; 51 scenes and 28 resources load.
- Headless 180-frame level smoke averaged 6.827 ms with a 10.737 ms maximum. This detects stalls but is not GPU performance evidence.
- Web UI was interactively checked at 1280×720 from title → menu → Options and title → gameplay. The canvas was normalized on first paint, mouse scrolling reached every accessibility row without overlap, and an idle player retained 100 health throughout the verified opening safety window.
- The macOS and Web release exports completed successfully.

## Release gates still requiring owner hardware

- Full human keyboard/mouse playthrough and encounter-feel signoff.
- Chrome and Safari full playthrough matrix on the target Mac.
- Physical Thrustmaster 2960623 calibration, 20-minute stability, reconnect, saved-binding, and full-level test through the intended adapter/hub.
- macOS signing/notarization and working-title legal review before public distribution.
