# Known Issues

This file distinguishes confirmed product limitations from unperformed validation. Update it for every release candidate; do not silently convert “not tested” into “passed.”

## `0.7.0-alpha.1-rc1` Rain City human gates

- The Rain City RC is intended for open public development with an explicit `BETA` badge and warning. Automated gates do not convert the human/device checks below into passes; final publication identity and hashes are recorded only after deployment.

- Right-stick profiles are automated for response, frame-rate stability, cancellation, and settings wiring, but final friction/boost strength and thumb comfort require physical iPad Safari testing.
- The Web bootstrap and title preload are browser-tested; slow real-world mobile networks still need a physical first-load timing pass.
- Rain City Run now has campaign continuity, five authored zones, 26 enemies, Compliance Gulls, a production Umbrella Shield Enforcer, four secrets, save-v5/loadout/upgrade continuity, and a four-phase 1,000-HP Municipal Towmaster finale. It has not had the required human 15–22 minute end-to-end playthrough; art, pacing, balance, navigation clarity, touch comfort, mix, and boss feel remain explicitly open. Mount Hood, Moon, and Ventura remain illustrated locked teasers only.
- Three regular archetypes plus Compliance Hound and Walker have original directional/reaction atlases and typed presentation profiles. The generated Walker source produced three distinct authored rows, so its alternate locomotion slot intentionally reuses the primary gait; this is manifested provenance, not a claim of eight unique animation families.
- Imported primary-combat audio, Salmon Creek ambience, adaptive mission music states, and nonverbal Cobie bark events are contract-tested. Loudness, tonal character, repetition, spatial mix, emotional timing, and perceived weapon/enemy weight still require human listening.
- Salmon Creek now contains 17 required actors across staged waves while limiting peak authored density to three. Encounter completion, reset, pressure distance, boss phases, summons, and recovery are automated; 12–20 minute route pacing, fairness by difficulty, and spectacle remain human gates.
- Salmon Creek now instantiates 16 data-authored breakable, explosive, loot, and secret interactions across five arenas. Damaging steam hazard zones were removed from Salmon Creek after iPad playtest feedback (their flat beige visual read as a random slab and dealt unexplained damage in the finale approach); the reusable HAZARD_ZONE kind remains available and is still used by Vancouver. Their collision, grounding, reset, bounded effects, and route safety are automated; visual density, discoverability, and whether each placement feels meaningfully useful require a human playthrough.
- Walker weak-point phase floors, Golden Ball defeat, summon caps, recovery drops, and repeated reset behavior are automated. Boss telegraph fairness, perceived speed, spectacle, and the approximately 1,000-HP pacing target still require human play.
- Rain City uses intentionally original low-poly authored geometry, project-original Blender/Material Maker sources, and independent gameplay collision/navigation. Its badge and launch notice identify the current RC as unfinished rather than falsely claiming final human approval.
- Alpha.10 native 1080p Compatibility profiling passes: opening p95/p99 is 19.378/19.481 ms, lab 17.931/18.524 ms, tunnels 17.787/19.092 ms, and Walker 17.583/18.341 ms; observed static memory remained below 81 MB. A packaged-Web Fast 4G/2× CPU trace is green, but long-session Web memory and physical-device thermals remain human/hardware gates.

## Distribution and legal

- The working title requires an IP/name review before public commercial distribution. The original generated cover does not resolve title clearance.
- macOS exports are unsigned and unnotarized until owner-controlled Apple credentials and an explicit signing process are available. Gatekeeper may warn or block a downloaded build.
- The static landing page intentionally has no analytics, login, telemetry, or feedback submission backend. Testers copy a non-sensitive playtest report and send it separately.

## Input and browser limitations

- Keyboard/mouse and the fixed twin-stick touch layout are supported Web input paths. Browser hardware-joystick identity and mappings remain experimental and vary by browser.
- The Thrustmaster USB Joystick model 2960623 has not been physically verified on the target Mac and adapter/hub. Software diagnostics are not hardware evidence.
- Browser audio and pointer lock require a user gesture. Alpha.9 requests capture from mission launch, restores canvas focus on pointer-down, and shows `CLICK TO AIM` if a browser still requires a fresh gesture; that activation click is consumed and the player is protected while waiting. Physical Safari/Chrome focus behavior remains a human-device gate.

## Validation still requiring real hardware

- Packaged Web smoke passed at desktop and simulated 1024x768 tablet viewports on 2026-07-13: menu, level select, Salmon Creek launch, twin-stick HUD layout, and aim response rendered without game console warnings. This does not replace physical iPad Safari touch, thermal, or audio-mix validation.
- A complete non-debug human playthrough remains required on the owner’s target Mac for every final candidate.
- The new Story/Classic/Mayhem selector and difficulty-driven pickup/aim-assist scaling have automated contract coverage only; difficulty feel (especially Story for family players and Mayhem pressure) needs a human playtest pass, including on iPad touch.
- Chrome and Safari each require a full keyboard/mouse playthrough of the packaged Web artifact, including reload/audio, options, death, and victory states.
- Native frame pacing, GPU performance, memory ceiling, load time, and the 12–20 minute first-time pacing target cannot be inferred from headless smoke tests.
- Generic controller and flight-stick completion remain unverified until exact device models, connection path, diagnostics, reconnect, persistence, and playthrough results are recorded.

## World-class vertical-slice open gates

- The visual-foundry candidate renders genuine 1280×720 and 1024×768 Movie Maker evidence rather than relabeling the fixed project viewport. Its first real 4:3 capture exposed and fixed an overlong touch-onboarding line. Fixed twin-stick rendering, target sizing, settings, and left-handed transforms are automated, but physical iPad comfort, reach, simultaneous real-touch behavior, Safari focus recovery, and thermal validation remain open.
- Original, imported, bounded weapon lifecycle, enemy reaction/attack, four-surface footsteps, ambience, adaptive music, and event-driven nonverbal Cobie barks are primary. Procedural audio remains an emergency fallback plus a source for still-unauthored secondary cues; human mix review remains open.
- Enemy state motion, hit/stagger/death reactions, attack tokens, group alert, weak-point contracts, production navigation, bounded stuck recovery, and five directional sprite atlases including Hound/Walker are implemented. Human combat-path and animation-readability review remain open.
- Headless drift smoke and native 1080p Compatibility-renderer zone profiling are green, including draw calls, object/node counts, and static memory. Compatibility/OpenGL does not expose useful GPU task timing here; Web/iPad thermal behavior and audio-voice saturation remain unmeasured hardware evidence.
- Salmon Creek now combines the validated ball-return prop with a deterministic Blender-authored opening kit and an editable Material Maker pilot graph. The opening kit improves current-main draw calls/nodes/objects, but final scale, lighting, visual cohesion, projectile feel, and placement still need a human playthrough; shed/lab/tunnel/arena structural geometry remains intentionally simple.
- Existing Hound/Walker atlases are visually stronger than a quick procedural substitute and were retained. PR #36 corrects their world scale, but editable Blender rigs, fully bespoke directional animation, and a human motion/readability review remain open.
- Chrome DevTools now covers a real packaged-Web load at 1024×768 touch under Fast 4G and 2× CPU: LCP 797 ms, CLS 0.00, no game console warnings/errors, and a correctly rendered loading/title path. The MCP filesystem allowlist prevented persisting a heap snapshot; long-session Web memory growth, physical iPad thermals, and device input remain open.

## Reporting policy

Open Blocker/Critical defects cannot ship. Any Major issue retained for a candidate must be added here with its owner-approved disposition and workaround. Automated tests, browser automation, and debug-assisted route checks must not be described as a human full playthrough.
