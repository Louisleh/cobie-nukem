# Known Issues

This file distinguishes confirmed product limitations from unperformed validation. Update it for every release candidate; do not silently convert “not tested” into “passed.”

## `0.6.0-alpha.8` shipped human gates

- Right-stick profiles are automated for response, frame-rate stability, cancellation, and settings wiring, but final friction/boost strength and thumb comfort require physical iPad Safari testing.
- The Web bootstrap and title preload are browser-tested; slow real-world mobile networks still need a physical first-load timing pass.
- Vancouver Waterfront is now a complete internal five-zone production preview with objectives, checkpoints, interactions, a shield enemy, and a three-stop convoy finale. It remains deliberately locked in the public UI and has not had a human end-to-end playthrough. Mount Hood, Moon, and Ventura remain illustrated locked teasers only.
- Three regular archetypes plus Compliance Hound and Walker have original directional/reaction atlases and typed presentation profiles. The generated Walker source produced three distinct authored rows, so its alternate locomotion slot intentionally reuses the primary gait; this is manifested provenance, not a claim of eight unique animation families.
- Imported primary-combat audio, Salmon Creek ambience, adaptive mission music states, and nonverbal Cobie bark events are contract-tested. Loudness, tonal character, repetition, spatial mix, emotional timing, and perceived weapon/enemy weight still require human listening.
- Salmon Creek now contains 17 required actors across staged waves while limiting peak authored density to three. Encounter completion, reset, pressure distance, boss phases, summons, and recovery are automated; 12–20 minute route pacing, fairness by difficulty, and spectacle remain human gates.
- Salmon Creek now instantiates 16 data-authored breakable, explosive, hazard, loot, and secret interactions across five arenas. Their collision, grounding, reset, bounded effects, and route safety are automated; visual density, discoverability, and whether each placement feels meaningfully useful require a human playthrough.
- Walker weak-point phase floors, Golden Ball defeat, summon caps, recovery drops, and repeated reset behavior are automated. Boss telegraph fairness, perceived speed, spectacle, and the approximately 1,000-HP pacing target still require human play.
- Vancouver uses intentionally original low-poly preview geometry and authored route contracts; it is internally launchable for automated evaluation but is not presented as final environment art or public mission completion.
- Alpha.8 native 1080p Compatibility profiling passes: gameplay p95 is 16.907–18.183 ms and p99 is 17.339–24.872 ms, with one isolated 94.584 ms tunnel maximum; observed static memory remained below 78 MB. Exported Web/tablet performance and physical-device thermals remain release/human gates rather than being inferred from native results.

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
- Original, imported, bounded weapon lifecycle, enemy reaction/attack, four-surface footsteps, ambience, adaptive music, and event-driven nonverbal Cobie barks are primary. Procedural audio remains an emergency fallback plus a source for still-unauthored secondary cues; human mix review remains open.
- Enemy state motion, hit/stagger/death reactions, attack tokens, group alert, weak-point contracts, production navigation, bounded stuck recovery, and five directional sprite atlases including Hound/Walker are implemented. Human combat-path and animation-readability review remain open.
- Headless drift smoke and native 1080p Compatibility-renderer zone profiling are green, including draw calls, object/node counts, and static memory. Compatibility/OpenGL does not expose useful GPU task timing here; Web/iPad thermal behavior and audio-voice saturation remain unmeasured hardware evidence.
- Salmon Creek now combines the validated Blender-authored ball-return prop with an original low-poly production material and landmark kit. Final scale, lighting readability, visual cohesion, projectile feel, and placement still need a rendered human playthrough; some structural geometry remains intentionally simple.

## Reporting policy

Open Blocker/Critical defects cannot ship. Any Major issue retained for a candidate must be added here with its owner-approved disposition and workaround. Automated tests, browser automation, and debug-assisted route checks must not be described as a human full playthrough.
