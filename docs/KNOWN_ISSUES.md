# Known Issues

This file distinguishes confirmed product limitations from unperformed validation. Update it for every release candidate; do not silently convert “not tested” into “passed.”

## `0.6.0-alpha.7` candidate human gates

- Right-stick profiles are automated for response, frame-rate stability, cancellation, and settings wiring, but final friction/boost strength and thumb comfort require physical iPad Safari testing.
- The Web bootstrap and title preload are browser-tested; slow real-world mobile networks still need a physical first-load timing pass.
- Vancouver Waterfront, Mount Hood, Moon, and Ventura are illustrated locked teasers only. Their art is not playable-level completion.
- Three regular archetypes have directional/reaction atlases. Compliance Hound and Walker still use their canonical illustrations with deterministic motion, tint, telegraph, hit/stagger, phase, and death presentation; bespoke directional atlases are a future art upgrade, not claimed complete here.
- The 60 imported primary-combat WAVs and their timing/routing are contract-tested, but loudness, tonal character, repetition, spatial mix, and perceived weapon/enemy weight require human listening. Ambience, adaptive music, and Cobie voice remain future authored-audio work.
- Salmon Creek now contains 17 required actors across staged waves while limiting peak authored density to three. Encounter completion, reset, pressure distance, boss phases, summons, and recovery are automated; 12–20 minute route pacing, fairness by difficulty, and spectacle remain human gates.
- Salmon Creek now instantiates 16 data-authored breakable, explosive, hazard, loot, and secret interactions across five arenas. Their collision, grounding, reset, bounded effects, and route safety are automated; visual density, discoverability, and whether each placement feels meaningfully useful require a human playthrough.
- Walker weak-point phase floors, Golden Ball defeat, summon caps, recovery drops, and repeated reset behavior are automated. Boss telegraph fairness, perceived speed, spectacle, and the approximately 1,000-HP pacing target still require human play.
- Vancouver has a locked typed route and three-wave citation-convoy production foundation only. It remains unrouted and non-public; none of this data is a claim of finished geometry or playability.
- The new native 1080p zone profiler passes its p95/p99 gates. The current candidate recorded p95 17.180–18.395 ms in gameplay zones, a 38.132 ms tunnel p99 with one 101.365 ms sample, and one isolated 155.964 ms Walker sample. These are preserved as profiler-driven optimization evidence rather than described as resolved ordinary-combat smoothness.

## Distribution and legal

- The working title requires an IP/name review before public commercial distribution. The original generated cover does not resolve title clearance.
- macOS exports are unsigned and unnotarized until owner-controlled Apple credentials and an explicit signing process are available. Gatekeeper may warn or block a downloaded build.
- The static landing page intentionally has no analytics, login, telemetry, or feedback submission backend. Testers copy a non-sensitive playtest report and send it separately.

## Input and browser limitations

- Keyboard/mouse and the fixed twin-stick touch layout are supported Web input paths. Browser hardware-joystick identity and mappings remain experimental and vary by browser.
- The Thrustmaster USB Joystick model 2960623 has not been physically verified on the target Mac and adapter/hub. Software diagnostics are not hardware evidence.
- Browser audio and pointer lock require a user gesture. The landing/game copy must remain explicit about the first click.

## Validation still requiring real hardware

- Packaged Web smoke passed at desktop and simulated 1024x768 tablet viewports on 2026-07-13: menu, level select, Salmon Creek launch, twin-stick HUD layout, and aim response rendered without game console warnings. This does not replace physical iPad Safari touch, thermal, or audio-mix validation.
- A complete non-debug human playthrough remains required on the owner’s target Mac for every final candidate.
- The new Story/Classic/Mayhem selector and difficulty-driven pickup/aim-assist scaling have automated contract coverage only; difficulty feel (especially Story for family players and Mayhem pressure) needs a human playtest pass, including on iPad touch.
- Chrome and Safari each require a full keyboard/mouse playthrough of the packaged Web artifact, including reload/audio, options, death, and victory states.
- Native frame pacing, GPU performance, memory ceiling, load time, and the 12–20 minute first-time pacing target cannot be inferred from headless smoke tests.
- Generic controller and flight-stick completion remain unverified until exact device models, connection path, diagnostics, reconnect, persistence, and playthrough results are recorded.

## World-class vertical-slice open gates

- The 640×360 desktop and 1024×768 tablet layouts have visual automation evidence. Fixed twin-stick rendering, target sizing, onboarding, settings, and left-handed transforms are automated, but physical iPad comfort, reach, simultaneous real-touch behavior, Safari focus recovery, and thermal validation remain open.
- Original, imported, bounded weapon lifecycle, enemy reaction/attack, and four-surface footstep samples are primary. Procedural audio remains an emergency fallback plus a source for still-unauthored UI/secondary cues; ambience, adaptive music, Cobie voice, and human mix review remain open.
- Enemy state motion, hit/stagger/death reactions, attack tokens, group alert, weak-point contracts, production navigation, bounded stuck recovery, and three regular directional sprite atlases are implemented. Bespoke Hound/Walker atlases and human combat-path feel remain open.
- Headless drift smoke and native 1080p Compatibility-renderer zone profiling are green, including draw calls, object/node counts, and static memory. Compatibility/OpenGL does not expose useful GPU task timing here; Web/iPad thermal behavior and audio-voice saturation remain unmeasured hardware evidence.
- The Salmon Creek ball-return machine is the first validated Blender-authored prop and has automated import/collision/puzzle coverage. Its final scale, lighting readability, projectile feel, and placement still need a rendered human playthrough; the rest of the environment remains a mixed prototype/production kit.

## Reporting policy

Open Blocker/Critical defects cannot ship. Any Major issue retained for a candidate must be added here with its owner-approved disposition and workaround. Automated tests, browser automation, and debug-assisted route checks must not be described as a human full playthrough.
