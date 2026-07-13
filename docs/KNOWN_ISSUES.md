# Known Issues

This file distinguishes confirmed product limitations from unperformed validation. Update it for every release candidate; do not silently convert “not tested” into “passed.”

## `0.6.0-alpha.2` human gates

- Right-stick profiles are automated for response, frame-rate stability, cancellation, and settings wiring, but final friction/boost strength and thumb comfort require physical iPad Safari testing.
- The Web bootstrap and title preload are browser-tested; slow real-world mobile networks still need a physical first-load timing pass.
- Vancouver Waterfront, Mount Hood, Moon, and Ventura are illustrated locked teasers only. Their art is not playable-level completion.

## Distribution and legal

- The working title requires an IP/name review before public commercial distribution. The original generated cover does not resolve title clearance.
- macOS exports are unsigned and unnotarized until owner-controlled Apple credentials and an explicit signing process are available. Gatekeeper may warn or block a downloaded build.
- The static landing page intentionally has no analytics, login, telemetry, or feedback submission backend. Testers copy a non-sensitive playtest report and send it separately.

## Input and browser limitations

- Keyboard/mouse and the fixed twin-stick touch layout are supported Web input paths. Browser hardware-joystick identity and mappings remain experimental and vary by browser.
- The Thrustmaster USB Joystick model 2960623 has not been physically verified on the target Mac and adapter/hub. Software diagnostics are not hardware evidence.
- Browser audio and pointer lock require a user gesture. The landing/game copy must remain explicit about the first click.

## Validation still requiring real hardware

- A complete non-debug human playthrough remains required on the owner’s target Mac for every final candidate.
- The new Story/Classic/Mayhem selector and difficulty-driven pickup/aim-assist scaling have automated contract coverage only; difficulty feel (especially Story for family players and Mayhem pressure) needs a human playtest pass, including on iPad touch.
- Chrome and Safari each require a full keyboard/mouse playthrough of the packaged Web artifact, including reload/audio, options, death, and victory states.
- Native frame pacing, GPU performance, memory ceiling, load time, and the 12–20 minute first-time pacing target cannot be inferred from headless smoke tests.
- Generic controller and flight-stick completion remain unverified until exact device models, connection path, diagnostics, reconnect, persistence, and playthrough results are recorded.

## World-class vertical-slice open gates

- The 640×360 desktop and 1024×768 tablet layouts have visual automation evidence. Fixed twin-stick rendering, target sizing, onboarding, settings, and left-handed transforms are automated, but physical iPad comfort, reach, simultaneous real-touch behavior, Safari focus recovery, and thermal validation remain open.
- `AudioCueSet` and bounded sample playback are implemented, but production still falls back to synthesized cues until original/licensed weapon, enemy, footstep, ambience, and music assets are authored and manifested.
- Enemy state motion, hit/stagger/death reactions, attack tokens, group alert, and weak-point contracts are implemented; directional sprite atlases and production navigation meshes remain open content gates.
- Headless performance smoke is green. Native GPU frame time, Web/iPad thermal behavior, draw calls, memory, download size, and audio-voice saturation are not yet measured release evidence.
- The Salmon Creek ball-return machine is the first validated Blender-authored prop and has automated import/collision/puzzle coverage. Its final scale, lighting readability, projectile feel, and placement still need a rendered human playthrough; the rest of the environment remains a mixed prototype/production kit.

## Reporting policy

Open Blocker/Critical defects cannot ship. Any Major issue retained for a candidate must be added here with its owner-approved disposition and workaround. Automated tests, browser automation, and debug-assisted route checks must not be described as a human full playthrough.
