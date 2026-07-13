# Known Issues

This file distinguishes confirmed product limitations from unperformed validation. Update it for every release candidate; do not silently convert “not tested” into “passed.”

## `0.6.0-alpha.5` shipped human gates

- Right-stick profiles are automated for response, frame-rate stability, cancellation, and settings wiring, but final friction/boost strength and thumb comfort require physical iPad Safari testing.
- The Web bootstrap and title preload are browser-tested; slow real-world mobile networks still need a physical first-load timing pass.
- Vancouver Waterfront, Mount Hood, Moon, and Ventura are illustrated locked teasers only. Their art is not playable-level completion.
- The new native 1080p zone profiler passes its p95/p99 gates. The navigation candidate improved the prior Walker outlier from 224 ms to 151.852 ms, while the tunnels produced a 33.929 ms p99 in one run. Static-AI profiling and projectile first-render warmup are contract-tested; continue profiler-driven combat-path work and confirm perceived pacing in the target-Mac human playthrough.

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
- Enemy state motion, hit/stagger/death reactions, attack tokens, group alert, weak-point contracts, production navigation, and bounded stuck recovery are implemented. Directional sprite atlases and human combat-path feel remain open content gates.
- Headless drift smoke and native 1080p Compatibility-renderer zone profiling are green, including draw calls, object/node counts, and static memory. Compatibility/OpenGL does not expose useful GPU task timing here; Web/iPad thermal behavior and audio-voice saturation remain unmeasured hardware evidence.
- The Salmon Creek ball-return machine is the first validated Blender-authored prop and has automated import/collision/puzzle coverage. Its final scale, lighting readability, projectile feel, and placement still need a rendered human playthrough; the rest of the environment remains a mixed prototype/production kit.

## Reporting policy

Open Blocker/Critical defects cannot ship. Any Major issue retained for a candidate must be added here with its owner-approved disposition and workaround. Automated tests, browser automation, and debug-assisted route checks must not be described as a human full playthrough.
