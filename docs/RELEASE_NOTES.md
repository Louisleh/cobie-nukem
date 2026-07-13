# Release Notes — 0.6.0-alpha.2 Aim and Roadmap Stabilization

Built on 2026-07-12 with Godot `4.7.stable.official.5b4e0cb0f` and matching official export templates. Feature revision: `e6b4700`.

## Included

- Honest Web download progress and title-menu preload states; input and the continue prompt remain disabled until ready, with retry on preload failure.
- Precision, Balanced, and Fast profile-driven right-stick response with smoothing, delayed outer turn boost, target friction, independent axes, inversion, and clean cancellation.
- Five illustrated mission cards: playable Salmon Creek plus original locked teasers for Vancouver Waterfront, Mount Hood, the Moon, and Ventura Pier.
- Fixed left movement and right rate-aim joysticks retain independent multi-touch ownership and simultaneous fire/actions.
- Legacy touch-speed migration, landscape onboarding, portrait rotation guard, focus/orientation cancellation, and Web scroll/zoom/callout suppression.
- Existing 0.5 vertical-slice foundation: normalized menus, three weapons, calibrated enemy HP/health bars, impact feedback, grounded pickups/enemies, Walker phases, save schema v3, accessibility controls, platform quality profiles, and local playtest metrics.
- Expanded release soak: 100 deterministic routes, 100 checkpoint cycles, 100 twin-stick cancellation cycles, 500 weapon transitions, and 100 temporary effects.

## Validation

- `QA_EXPORTS=1 bash tools/release_validate.sh` passed on macOS with Godot 4.7, including Web and unsigned Universal macOS exports.
- Tablet browser inspection passed at 1024×768 across title, main menu, five-card level select, gameplay twin-stick HUD, and expanded aim options with zero captured console warnings/errors.
- Portrait viewport inspection showed the input-blocking `ROTATE IPAD TO LANDSCAPE` guard.
- Physical iPad Safari comfort, true multi-touch, thermal behavior, and a human full playthrough remain explicitly unverified alpha gates.

## Artifacts

- `cobie-nukem-0.6.0-alpha.2-itch.zip` — 21,365,147 bytes; SHA-256 `1be13ee23464d28f2951bc04da14e5e53d25f2f25db5ca5150901b955cc42d16`.
- `cobie-nukem-0.6.0-alpha.2-macos-unsigned.zip` — 70,729,118 bytes; SHA-256 `5161b04e8d1f0d7088437acbc80444927368b8d7fb356a860b008a66e7a4361c`.

---

# Previous Release — 0.2.0-rc1 Family Playtest RC

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

- `builds/packages/cobie-nukem-0.2.0-rc1-itch.zip` — 17,623,182 bytes; SHA-256 `7e4bcf554d80a3b9128ecd662a12e326fb58e2c21aa885ea4713b8e1462ac910`.
- `builds/packages/cobie-nukem-0.2.0-rc1-macos-unsigned.zip` — 66,987,145 bytes; SHA-256 `c6f32804a0d3f1dff31c0bd8fbad6035063d3e65923fa30e11074b643fbfbf52`.
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
