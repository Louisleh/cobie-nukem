# Known Issues

This file distinguishes confirmed product limitations from unperformed validation. Update it for every release candidate; do not silently convert “not tested” into “passed.”

## Local progression candidate gates

- Progress is an offline guest profile stored in native/Web user storage. There is intentionally no login, cloud sync, telemetry, account recovery, paid currency, advertising, daily streak, randomized reward, or social leaderboard.
- Portable `COBIE1` backup codes cover campaign progression but require the player to copy and retain the code. Private browsing, browser storage clearing, or device loss can otherwise remove progress.
- Mini Ball collections are authored only for Salmon Creek and Rain City in this pass. Mount Hood, Moon, and Ventura accurately display `COLLECTION COMING SOON`.
- Automated tests prove save migration, duplicate protection, payout arithmetic, purchases, equips, backup integrity, Off-Leash lifecycle, and responsive Doghouse layout. They do not establish human economy balance, collectible placement quality, replay motivation, touch comfort, or whether rewards feel sufficiently valuable.
- The first Off-Leash mode is a denser Salmon Creek remix. It is not yet a campaign-wide prestige system; additional missions/mutators remain future content.

## Five-mission candidate gates

- **Dark Side of Fetch** and **Pier Pressure** are complete automated-route public betas, not human-approved final missions. Each has five zones, five checkpoints, five secrets, six objectives, 28 regular enemy placements, difficulty pressure caps, a typed 1,000-HP modular boss, post-defeat Golden Ball gating, checkpoint restore, and campaign continuation. Original presentation-only Blender kits and manifested Moon/Ventura material libraries are integrated; bespoke hero animation, imported mission-specific audio, final zone-by-zone composition, human encounter tuning, and physical-iPad review remain open.
- Levels 2–5 intentionally display `BETA`. No automated route simulation, headless boss cycle, screenshot, or packaged-browser smoke test authorizes removing those labels.
- The five-mission campaign graph, startup transaction guard, save-v5 checkpoints, mission loadouts, pointer recovery, and replay/continue routes have automated coverage. Full human title-to-Level-5 continuity on target Mac and iPad remains required.
- Moon and Ventura currently ship in the main public bundle. The reusable mission-pack loader is a validated future packaging boundary, not a claim that optional content is downloaded on demand.
- Moon vacuum/decompression hazards and Ventura tide/surf hazards are bounded typed gameplay components. Their timing, spectacle, readability, and comfort require human review.
- The Lunar Ordinance Walker and Municipal Tidebreaker use the shared modular boss framework with mission-specific phase data and presentation. Bespoke final hero art and motion remain open.

## Archived `0.8.0-alpha.1-rc1` candidate gates

- Mount Hood Whiteout is an always-available public-development `BETA`, not a human-approved final mission. Its five-zone route, objectives, encounters, navigation, traction profiles, chairlift resets, Snowcat gating, saves/resources, and package eligibility have automated coverage. Physical iPad touch/thermal/audio, target-Mac pacing, final environmental art, enemy animation quality, boss fairness, mix, humor, and photosensitivity remain human gates.
- Rain City remains labelled `BETA`. This cycle does not remove the badge because target-Mac, Safari/Chrome full routes, physical-iPad completion, route pacing, Towmaster feel, final art/mix, humor, and photosensitivity approval remain open.
- Snow traction offers Full/Reduced/Off. Automated physics contracts do not substitute for human steering comfort, especially on twin sticks.
- Mount Hood uses original mesh-primary production-preview enemies and modular environments. Directional hero atlases and fully authored mission-specific audio are quality follow-ups; no automated test claims those subjective gates passed.

## Archived `0.7.0-alpha.1-rc5` Rain City human gates

- RC5 converts Rain City's authored Blender batches to manifested albedo/normal/packed-ORM runtime families and adds a presentation-only Mount Hood pilot. The complete release matrix and public byte-identity gate pass; automated import/material/identity contracts still do not constitute human art approval.

- RC5 retains the selector ownership fix so merely hovering or focusing another mission cannot replace a committed selection. Rain City is intentionally public and immediately playable under its `BETA` badge; only Mount Hood, Moon, and Ventura remain locked teasers. Automated, packaged-Chrome, live-Chrome, and byte-identity gates passed; physical iPad/Safari pointer and touch feel remain human validation.

- RC3 separates card selection from launch, retains Web pointer lock across the Start transition, and enables proactive `R` reloads with authored HUD/audio feedback. Packaged and public Chrome verify the pointer and reload contracts; Safari, physical iPad, and full human route confirmation remain open.
- The Rain City RC is intended for open public development with an explicit `BETA` badge and warning. Automated gates do not convert the human/device checks below into passes; final publication identity and hashes are recorded only after deployment.

- Right-stick profiles are automated for response, frame-rate stability, cancellation, and settings wiring, but final friction/boost strength and thumb comfort require physical iPad Safari testing.
- The Web bootstrap and title preload are browser-tested; slow real-world mobile networks still need a physical first-load timing pass.
- Rain City Run has campaign continuity, five authored zones, 26 enemies, Compliance Gulls, a production Umbrella Shield Enforcer, four secrets, save-v5/loadout/upgrade continuity, and a four-phase 1,000-HP Municipal Towmaster finale. It has not had the required human 15–22 minute end-to-end playthrough; art, pacing, balance, navigation clarity, touch comfort, mix, and boss feel remain explicitly open.
- Three regular archetypes plus Compliance Hound and Walker have original directional/reaction atlases and typed presentation profiles. The generated Walker source produced three distinct authored rows, so its alternate locomotion slot intentionally reuses the primary gait; this is manifested provenance, not a claim of eight unique animation families.
- Imported primary-combat audio, Salmon Creek ambience, adaptive mission music states, and nonverbal Cobie bark events are contract-tested. Loudness, tonal character, repetition, spatial mix, emotional timing, and perceived weapon/enemy weight still require human listening.
- Salmon Creek now contains 17 required actors across staged waves while limiting peak authored density to three. Encounter completion, reset, pressure distance, boss phases, summons, and recovery are automated; 12–20 minute route pacing, fairness by difficulty, and spectacle remain human gates.
- Salmon Creek instantiates data-authored breakable, explosive, loot, and secret interactions across five arenas. Rain City’s three silent flat damage slabs were also removed after the same iPad readability issue was confirmed by the Level 2 QA report; the harbour placement is now a readable two-prop explosive-chain challenge. The reusable `HAZARD_ZONE` kind remains available for future telegraphed/timed hazards, but neither public mission currently relies on an invisible floor-damage slab. Collision, grounding, reset, bounded effects, and route safety are automated; visual density and usefulness still require a human playthrough.
- Walker phase thresholds, final-core damage to zero, post-defeat Golden Ball sequencing, summon cleanup, recovery drops, and repeated reset behavior are automated. A deterministic runtime capture proves the compact boss panel reaches `0% / DESTROYED` during the bounded defeat spectacle. Boss telegraph fairness, perceived speed, spectacle quality, and the approximately 1,000-HP pacing target still require human play.
- Rain City uses intentionally original low-poly authored geometry, project-original Blender/Material Maker sources, and independent gameplay collision/navigation. Its badge and launch notice identify the current RC as unfinished rather than falsely claiming final human approval.
- RC5's rendered native Compatibility profile uses 300 foreground-rendered frames per zone. Rain City p95/p99 is 17.447/23.337 ms in the alley, 20.978/21.625 in Rain City Slice, 17.532/21.546 at the seawall, 17.368/17.689 in the terminal, and 17.485/20.358 at the pier, with 200–403 draw calls and approximately 83.6 MB static memory. One isolated 1,054.530 ms macOS scheduling pause occurred at the pier; it was not recurring and remains reported. A packaged-Web trace still cannot establish long-session physical-iPad thermals, simultaneous-finger comfort, or human encounter feel.
- Convoy movement/reset, enemy navigation recovery, projectiles, pickup grounding, and encounter gating have deterministic coverage, but human observation is still required for contact motion, perceived acceleration, environmental snagging, and whether combat movement looks natural at ordinary play speed.

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

- RC5 renders genuine 1280×720 and 1024×768 Movie Maker evidence rather than relabeling the fixed project viewport. Its first real 4:3 capture exposed and fixed an overlong touch-onboarding line. Fixed twin-stick rendering, target sizing, settings, and left-handed transforms are automated, but physical iPad comfort, reach, simultaneous real-touch behavior, Safari focus recovery, and thermal validation remain open.
- Original, imported, bounded weapon lifecycle, enemy reaction/attack, four-surface footsteps, ambience, adaptive music, and event-driven nonverbal Cobie barks are primary. Procedural audio remains an emergency fallback plus a source for still-unauthored secondary cues; human mix review remains open.
- Enemy state motion, hit/stagger/death reactions, attack tokens, group alert, weak-point contracts, production navigation, bounded stuck recovery, and five directional sprite atlases including Hound/Walker are implemented. Human combat-path and animation-readability review remain open.
- Headless drift smoke and native 1080p Compatibility-renderer zone profiling are green, including draw calls, object/node counts, and static memory. Compatibility/OpenGL does not expose useful GPU task timing here; Web/iPad thermal behavior and audio-voice saturation remain unmeasured hardware evidence.
- Salmon Creek now combines the validated ball-return prop with a deterministic Blender-authored opening kit and an editable Material Maker pilot graph. The opening kit improves current-main draw calls/nodes/objects, but final scale, lighting, visual cohesion, projectile feel, and placement still need a human playthrough; shed/lab/tunnel/arena structural geometry remains intentionally simple.
- Existing Hound/Walker atlases are visually stronger than a quick procedural substitute and were retained. PR #36 corrects their world scale; the 2026-07-17 follow-up extends the explicit visible-size guard to Compliance Gull and Umbrella Shield Enforcer. Editable Blender rigs, fully bespoke directional animation, and a human motion/readability review remain open.
- Manny’s physical-iPad report that the HUD dog portrait was too small is addressed in RC5 with a tighter 512px Set A crop and a 104-logical-pixel frame (approximately 220 rendered pixels in the 1024×768 capture). This simulated-layout evidence does not claim the physical iPad follow-up has passed.
- Chrome DevTools now covers a real packaged-Web load at 1024×768 touch under Fast 4G and 2× CPU: LCP 797 ms, CLS 0.00, no game console warnings/errors, and a correctly rendered loading/title path. The MCP filesystem allowlist prevented persisting a heap snapshot; long-session Web memory growth, physical iPad thermals, and device input remain open.

## Reporting policy

Open Blocker/Critical defects cannot ship. Any Major issue retained for a candidate must be added here with its owner-approved disposition and workaround. Automated tests, browser automation, and debug-assisted route checks must not be described as a human full playthrough.
