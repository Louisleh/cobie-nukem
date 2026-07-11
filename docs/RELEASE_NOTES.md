# Release Notes — 0.2.0-rc1 Family Playtest RC

Built on 2026-07-11 with Godot `4.7.stable.official.5b4e0cb0f` and matching official export templates.

## Included

- Complete title-to-victory Episode 1 level with six zones, three secrets, checkpoint, three weapons, three regular enemies, Compliance Hound elite, and four-phase Animal Control Walker finale.
- Keyboard/mouse, generic gamepad, Classic 1996 flight-stick, and Hybrid profiles.
- Input diagnostics, calibration, response curves, inversion, remapping, conflicts, persistence, and report export.
- Compact Input Setup presentation with visible default keyboard/mouse mappings and independently scrollable diagnostics panels.
- Cover-led title/menu presentation, HUD, pause/death/victory screens, accessibility options, original procedural audio, and 320×180 retro rendering.
- Responsive full-height Cobie title art and a mission-select flow with one playable Salmon Creek course plus clearly locked future courses.
- Weapon-specific magazines and reload cadence: 15-round infinite-reserve Pawstol, six-shell Barkshot with per-shell reload, and three-ball Fetch Launcher with finite reserve.
- Lower, heavier original weapon synthesis, dry-fire/reload cues, grounded walk/run footsteps, ammo HUD state, and a copyable in-game playtest report.
- Reliable overlap-safe pickup collection, explicit access-collar HUD state, and first-frame Web canvas sizing.
- Continuous Secret Dog Park doorway/floor geometry and resilient zone-triggered Compliance Lab/Fetch Guard progression.
- Correct player-layer progression detection plus route-position fallbacks for all four post-opening encounters.
- World-anchored pickups, grounded-enemy floor recovery, gravity-free drone hovering, and a normalized loading splash before the Web canvas becomes visible.
- Deterministic Up/Down weapon cycling, calibrated knockback and HP tiers with numeric labels, aggressive Walker approach behavior, full-state pickup collection, and enemy-colliding Fetch-ball rebounds.
- QA-review pass: first-shot/12-second opening aggro grace, reduced opening DPS, compact fixed-size HP presentation, reliable three-read sign secret, deterministic checkpoint continuation, Escape/modal/focus-loss safety, debounced wheel weapon aliases, FOV/run-mode/subtitle options, keyboard-follow and wheel scrolling, input-grid fitting, mouse-delta clamping, portable asset validation, storm/rain/field dressing, shed roof, hidden open doors, and enemy death debris.
- Headless unit, integration, scene/resource, performance, and asset/IP heuristic checks.

## Local artifacts

- `builds/packages/cobie-nukem-0.2.0-rc1-itch.zip` — 17,623,184 bytes; SHA-256 `7d92c074c2bdb83fda3872e9a83a45b0a4eda68e64e4aee7da79554230675632`.
- `builds/packages/cobie-nukem-0.2.0-rc1-macos-unsigned.zip` — 66,987,144 bytes; SHA-256 `9daff1c6d84e6888d613be37829ddd9e3a8d6ffe8882261068b8c37395f30108`.
- `builds/pages/` — static landing page plus playable `/play/` route.

## Validation

- All automated suites passed; 53 scenes and 32 resources load.
- Headless 180-frame level smoke averaged 6.834 ms with a 10.640 ms maximum. This detects stalls but is not GPU performance evidence.
- Packaged Web UI was interactively checked at 1280×720 across title, main menu, mission selector/locked courses, gameplay HUD/enemy HP, pause, and playtest feedback; the title was also checked at 1440×900.
- The macOS and Web release exports completed successfully.

## Release gates still requiring owner hardware

- Full human keyboard/mouse playthrough and encounter-feel signoff.
- Chrome and Safari full playthrough matrix on the target Mac.
- Physical Thrustmaster 2960623 calibration, 20-minute stability, reconnect, saved-binding, and full-level test through the intended adapter/hub.
- macOS signing/notarization and working-title legal review before public distribution.
