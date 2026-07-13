# Cobie Nukem — Multi-Phase Production PRD

**Status:** Active production source of truth; `0.6.0-alpha.3` agentic-production candidate under release validation

**Created:** 2026-07-11

**Last status review:** 2026-07-13

**Current public baseline:** `0.6.0-alpha.2` (`e6b4700` gameplay/UI feature revision; source integration `5cc352b`)

**Unreleased development baseline:** `0.6.0-alpha.3` candidate at feature revision `b8795dc`; public remains `0.6.0-alpha.2` until the release matrix passes and the matching artifact is deployed

**Last playtest alpha:** `0.6.0-alpha.2` (`e6b4700`) — live at <https://www.louislehmann.fyi/games/cobie-nukem/>

**Engine:** Godot 4.7 stable, GDScript, Compatibility renderer
**Purpose:** Turn the family-playtest vertical slice into a sustainable, original multi-level game without sacrificing responsiveness, humor, Web support, or unusual-controller accessibility.

## 0. Current status dashboard

This section is the first place a new Codex or external-auditor run should read. “Foundation complete” means the reusable contract exists, Salmon Creek exercises it, and automated regression passes; it does not mean every future extension listed in the phase is finished.

| Phase | Status | Completed | Explicitly remaining |
| --- | --- | --- | --- |
| 1. Gameplay systems foundation | **VERTICAL-SLICE FOUNDATION IMPLEMENTED — IN REVIEW** | Previous foundation plus `PlayerFeelProfile`, `WeaponFeelProfile`, terminal combat feedback events, damage reactions, pressure/attack tokens, group alert, weak-point metadata, multi-wave encounter schema v2, mission runtime/spawn registry extraction, event-driven interaction/aim registries | Full navigation-mesh production pass, authored directional animation atlases, final feel/balance |
| 2. Content-production pipeline | **FOUNDATION COMPLETE** | Versioned manifest, Salmon Creek content data, headless validator, release-gate integration, authoring guide, manifest template, critical-path rules, Mission 2 (Vancouver Waterfront) manifest/objective/encounter skeleton validating in CI with a locked card and non-public graybox | Visual editor tooling; spawn volumes/patrol paths; richer pickup/prop/zone schemas; automated nav/reachability analysis; Mission 2 full production |
| 3. World and episode structure | **NOT STARTED — BRIEFS + TEASER ART ONLY** | Vancouver Waterfront, Mount Hood, Moon, and Ventura briefs/locked illustrated cards establish the campaign roadmap | No production geometry, mission routing, encounters, enemies, or playable level assets have been built |
| 4. Combat and presentation expansion | **STARTED — SYSTEM CONTRACTS** | High-resolution 640×360 presentation baseline, surface-aware combat events, muzzle/impact/death feedback, enemy state motion, numeric elite/boss identity, imported-sample audio contract and expanded bus/limiter layout | Original sample library, directional sprite atlases, adaptive music, environmental kit/interaction density, final boss spectacle |
| 5. Accessibility, persistence, observability | **IMPLEMENTED FOUNDATION — IN REVIEW** | Save schema v3 with v2 migration and objective/encounter/secret persistence; local-only frame/combat/damage/pickup metrics; objective HUD; reduced-flash integration; quality profiles | Complete settings UI for every assist, captions beyond current narrative text, visual regression gallery, 100-route/50-cycle expanded soak, physical devices |
| 6. Alpha, beta, release | **NOT STARTED** | Existing development packaging and CI are available | Episode content completion, full human/device/browser matrices, signing/notarization, legal review, store readiness |

### Immediate next gate

**Gate passed 2026-07-11.** Accepted critical Fable findings are addressed, the stamped build is public through the owner website, and the touch-first iPad browser path has automated and tablet-viewport regression evidence. The remaining hardware gate is a real iPad Safari feel/thermal/network pass.

**2026-07-12 implementation pass (source repo, not yet released):** the accessible Story/Classic/Mayhem selector is live on level select with all six difficulty multipliers consumed at runtime; save payloads are versioned and migrated; state-transition hardening plus adversarial regression coverage landed; and the Mission 2 content skeleton validates in CI. Next priorities are controlled family playtesting (including difficulty feel), the physical-iPad hardware pass, and Mission 2 production geometry. Do not treat missing Phase 3–6 content as a current defect unless a current contract falsely claims to support it.

**2026-07-12 world-class vertical-slice pass (unreleased):** milestone and issue inventory created; baseline Mac release validation captured; event-driven registries replace per-frame group scans; the Salmon Creek controller has begun extraction into reusable mission runtime/spawn ownership; movement, combat, damage-reaction, pressure, quality, audio-sample, encounter-v2, save-v3, and local-metric contracts are implemented; the render baseline is upgraded from 320×180 nearest filtering to 640×360 linear filtering; fixed-coordinate HUD/menus were normalized and visually checked at desktop and 1024×768 tablet viewports. The non-export release matrix is green. This is an integration checkpoint, not the `0.6.0-alpha` claim.

**Accessibility/performance checkpoint (unreleased):** options now expose text scale, high contrast, reduced motion, touch opacity, left-handed touch, and automatic/Web/native quality selection. Camera shake uses projection offsets so it cannot perturb authoritative weapon aim. Touch controls mirror input and rendering safely, critical enemy telegraphs have optional captions, HUD damage direction is spatial, footsteps report authored surface identity, and temporary combat effects obey the active quality budget. Browser evidence covers the full options screen and a touch-forced Salmon Creek HUD at 1280×720; physical iPad ergonomics remain open.

**Autonomous soak checkpoint (unreleased):** the release gate now runs 100 deterministic Salmon Creek mission-contract routes, 100 schema-v3 checkpoint JSON cycles, 100 focus-loss/twin-stick-cancellation cycles, 500 weapon selection/reload transitions, and a 100-effect budget saturation pass. This supplements—not replaces—the existing scene route, adversarial lifecycle, export, and human/device gates.

**Twin-stick iPad checkpoint (0.6 alpha candidate):** right-side swipe look has been replaced by a fixed aiming joystick consumed in physics ticks. The left movement stick, right aim stick, and action buttons use exclusive multi-touch finger ownership. Options expose independent horizontal/vertical aim speed, Y inversion, stick size and placement presets, opacity, and complete left-handed mirroring. The legacy touch-speed setting migrates to both axes. Automated evidence covers dead zones, full response, three simultaneous fingers, 30/120 FPS aim equivalence, focus cancellation, tablet coordinate scaling, and expanded soak cycles; physical iPad Safari remains a named human gate.

**Loading/aim/roadmap stabilization checkpoint (`0.6.0-alpha.2` candidate):** Web bootstrap now preserves Godot's real download progress while explaining first-load latency; the title preloads the main menu and does not show or accept “continue” until ready. Right-stick aiming adds three typed response profiles, exponential smoothing, delayed outer-ring turn boost, and configurable target friction while retaining physics-tick consumption and clean cancellation. The mission selector now previews five destinations using original manifested art: playable Salmon Creek plus locked Vancouver Waterfront, Mount Hood, Moon, and Ventura Pier cards. This is teaser/pipeline work, not a claim that Phase 3 level production has begun.

**Agentic production checkpoint (2026-07-13, unreleased):** Godot 4.7, a privacy-hardened Blender 5.1 MCP path, and focused Godot production skills are installed locally and governed by repository contracts. Three Godot MCP candidates, GdUnit4, and FuncGodot/TrenchBroom were piloted before adoption decisions; runtime bridges remain forbidden from source and exports. The release gate now rejects engine script/leak/orphan output, a 300-frame percentile/drift performance smoke replaces the average-only check, and player lookup is event-indexed for pickup/enemy hot paths. The first Blender-authored production prop replaces the procedural ball-return placeholder in Salmon Creek with manifested source/runtime assets and a gameplay contract test. This improves the production loop and one secret; it does not complete the remaining directional-animation, imported-audio, navigation, encounter-balance, or physical-device gates.

### World-class vertical-slice delivery boundary

Completed in the current integration checkpoint:

- mechanical architecture, engine-error, generated-export, script-size, and asset-provenance gates;
- mission runtime/spawn registry extraction and event-driven interaction/aim indexing;
- profile-driven player feel, combat feedback, damage reactions, pressure tokens, group alert, weak points, and encounter schema v2;
- save schema v3 with deterministic migration and checkpoint restoration of objective/encounter/secret state;
- automatic Web/iPad vs native quality profiles and privacy-preserving local metrics;
- 640×360 render/UI normalization, current-objective HUD, reduced-flash effects, expanded audio buses/limiter, and an imported-sample playback pipeline with bounded polyphony;
- desktop and 4:3 tablet browser captures plus the complete headless regression matrix.

Critical before `0.6.0-alpha`:

- production navigation and unreachable-actor recovery evidence;
- original directional enemy animation and imported weapon/enemy/footstep sample packs with manifest provenance;
- Salmon Creek encounter-v2 pacing authoring and Walker spectacle/balance playthrough;
- physical-device verification of the surfaced accessibility controls (text scale, contrast, captions, control opacity/layout);
- profiler evidence and target-Mac human playthrough (native/Web exports and the first seeded soak expansion are automated);
- physical iPad Safari touch comfort/thermal/focus validation and human photosensitivity/difficulty review.

Future nice-to-have, explicitly non-blocking for the vertical slice: comic-panel sequences, optional gib variants, advanced support/flank tactics, drag-anywhere touch-editor polish, and native iOS packaging.

### Independent Fable audit disposition — 2026-07-11

| Finding | Decision | PRD priority | Required outcome |
| --- | --- | --- | --- |
| FA-01 checkpoint restart leaves live enemies at spawn | **Accepted** | **Critical now** | Reset the active encounter and provide short respawn protection; behavioral regression test |
| FA-02 opening enemies appear too passive | **Partially accepted; audit input was unreliable and the authored grace window is 12 seconds** | **Tune after controlled measurement** | Add bounded engagement evidence and tune per difficulty only if reproducible; avoid making the family opener punitive |
| FA-03 actors without `died` deadlock ALL_DEFEATED | **Accepted** | **Critical now** | Fail the encounter loudly and reject invalid content |
| FA-04 all-null spawns silently complete | **Accepted** | **Critical now** | Emit named failure; never report completion |
| FA-05 stale `waves` table | **Accepted** | **Critical now / cheap cleanup** | Remove duplicate source of truth |
| FA-06 repeated difficulty Resource load | **Accepted** | **Critical now / cheap performance** | Cache profile by selected difficulty |
| FA-07 repeated objective activation signals | **Accepted** | **Critical now / correctness** | Emit only on transition; preserve JSON-safe snapshots |
| FA-08 save migration and snapshot type drift | **Accepted in part** | **Next phase before save-schema expansion** | JSON round-trip contract now; version migration framework before objective persistence ships |
| FA-09 packaged build can lag source | **Accepted** | **Critical for public hosting** | Stamp, export, package, and deploy the same feature revision; verify public build identity |
| FA-10 test leaks/assertion-light coverage | **Accepted** | **Critical now for touched paths; ongoing thereafter** | Clean teardown and add behavioral restart/mobile tests; do not block on unrelated engine internals |
| FA-11 per-frame route fallback scan | **Accepted as low-impact technical debt** | **Future nice-to-have before larger levels** | Replace with indexed/event fallback when Mission 2 route architecture is built |
| FA-12 difficulty picker absent | **Accepted, already documented** | **Next player-facing phase** | Add accessible selector after mobile/public-release gate unless capacity remains |
| FA-13 Web focus/pause timing recovery | **Accepted as mobile risk** | **Critical now** | Verify and harden touch/focus recovery during reload, encounter grace, pause, and death |
| FA-14 validator misses difficulty uniqueness/enemy contract | **Accepted** | **Critical now** | Validate unique difficulty IDs, finite positions, and spawn scene contract with named errors |

FA-08 (save migration framework) and FA-12 (difficulty selector) were delivered in the 2026-07-12 implementation pass; see `docs/FABLE_NEXT_PASS_HANDOFF.md`.

### Public Web and iPad critical-release requirements

- The game is accessible from the owner’s public website over HTTPS with a stable, shareable URL.
- iPad Safari is a first-class browser target, not an experimental afterthought.
- Touch UI provides simultaneous left-thumb movement and right-thumb fixed-stick aiming with multi-touch-safe finger ownership.
- Primary fire, use, jump, reload, weapon previous/next, and pause are reachable without a keyboard.
- Right-side aiming uses a visible rate-based joystick with center precision, independent axis sensitivity, pitch clamping, optional inversion, and no accidental firing while aiming. General right-side swipe gestures do not aim.
- Touch controls respect safe-area insets, landscape orientation, common iPad aspect ratios, and browser chrome changes.
- HUD, menus, mission cards, options, death, pause, and victory remain readable and tappable at mobile sizes.
- Pointer-lock instructions are hidden or replaced on touch devices; keyboard/mouse behavior remains unchanged.
- Focus loss, app switching, orientation/viewport changes, and resumed audio cannot strand input or gameplay state.
- Automated touch contract tests plus live tablet-size browser interaction are required; physical iPad Safari remains a named human/device gate until run on hardware.

## 1. Product direction

Cobie Nukem is a compact, fast, funny retro FPS starring Cobie, a leather-jacketed labradoodle who treats petty rules as boss encounters. The next buildout must prove that new missions, enemies, objectives, and environmental jokes can be produced from reusable systems instead of copying Salmon Creek's level script.

The project remains an original work. Location references may evoke real places through original geometry, writing, and art. Do not copy protected game assets, maps, dialogue, music, logos, restaurant branding, or trade dress. Real-business references such as Ruse should be affectionate, incidental environmental detail and should receive owner/legal review before public commercial distribution.

## 2. Success measures

### Production measures

- A new encounter can be authored as a Resource without editing a level controller.
- A new linear or optional objective can be authored as a Resource with prerequisites and count requirements.
- Every level has a manifest that validates IDs, scene paths, objectives, encounters, and difficulty profiles headlessly.
- Mission 2 production reuses at least 80% of runtime gameplay systems from Salmon Creek.
- Critical progression content has automated route and deadlock tests.

### Player measures

- First-time players can finish each mission without debug intervention.
- Combat communicates alert, attack, damage, stagger, death, and objective state clearly.
- Difficulty changes behavior and resource pressure, not merely enemy HP.
- Each mission introduces one enemy family, one traversal/environment mechanic, one signature set piece, and one meaningful reward.
- The campaign remains playable on keyboard/mouse; controller and flight-stick paths remain recoverable.

### Technical measures

- Web and Universal macOS exports remain green.
- No content manifest ships with duplicate IDs, missing scenes, empty required encounters, missing prerequisites, or invalid spawn data.
- Headless scene/resource smoke and full Salmon Creek route remain regression gates.
- Save payloads are versioned and migrations are explicit.

## 3. Phase map

| Phase | Outcome | Exit gate |
| --- | --- | --- |
| 1. Gameplay systems foundation | **Implemented foundation** — reusable objectives, encounters, difficulty, enemy roles, progression contracts | Salmon Creek runs through the new systems with all existing route tests passing |
| 2. Content-production pipeline | **Implemented foundation** — Resource schema, manifests, templates, validation, authoring rules | A designer can define a valid mission skeleton without changing core runtime code |
| 3. World and episode structure | Vancouver Waterfront, Mount Hood, and Moon mission briefs and production plans | Each mission has a route, landmark plan, mechanic, enemy addition, boss/set piece, and asset list |
| 4. Combat and presentation expansion | Deeper reactions, weak points, hazards, animations, music, identity | Combat sandbox and one production mission demonstrate the expanded vocabulary |
| 5. Accessibility, persistence, and observability | Durable saves, profiles, assists, metrics, soak testing | Alpha-quality settings/save compatibility and diagnostic coverage |
| 6. Alpha, beta, and release | Content complete, balanced, performant, distributable | Human/browser/native/device matrices and release/legal gates complete |

## 4. Phase 1 — Gameplay systems foundation

### 4.1 Objectives

Create a data-driven objective system supporting:

- reach zone;
- collect item;
- activate switch/device;
- defeat enemy or count;
- survive encounter/time window;
- complete level;
- required and optional objectives;
- prerequisite chains;
- progress snapshots suitable for saves and reports.

Runtime requirements:

- Objectives use stable `StringName` IDs.
- The tracker emits activated, progressed, completed, and all-required-completed signals.
- UI observes objective signals; it never owns objective truth.
- Duplicate completion events are idempotent.
- Prerequisites prevent premature progress.
- Snapshot data contains primitives only.

### 4.2 Encounters

Create data-driven encounter definitions with:

- stable encounter and zone IDs;
- scene path and world-position spawn entries;
- completion policy;
- activation/opening grace metadata;
- started, spawned, defeated, and completed signals;
- one-shot activation per zone;
- target assignment through a public enemy boundary.

Future extension points include multi-wave timing, reinforcement conditions, patrol splines, encounter budgets, spawn volumes, and combat-director pressure. These are schema extensions, not requirements for the first migration.

### 4.3 Difficulty profiles

Provide at least three data profiles:

- **Best Friend:** reduced enemy pressure, more recovery, stronger aim support.
- **Good Dog:** intended baseline.
- **Off Leash:** faster aggression, higher damage, scarcer recovery, reduced aim support.

Profiles separately control health, damage, speed, aggression, pickup amount, and aim assistance. Phase 1 must establish runtime enemy scaling and selected-difficulty run metadata. Menu selection and complete pickup/aim-assist integration can iterate later without changing the Resource contract.

### 4.4 Enemy archetypes

Definitions identify a tactical role:

- melee pursuer;
- ranged keeper;
- skirmisher;
- tank;
- flying pressure;
- support;
- boss.

Phase 1 adds preferred/retreat distance behavior so ranged and skirmisher enemies stop behaving like melee enemies. Later phases add cover selection, support actions, coordinated flanks, suspicion, and group alert propagation.

### 4.5 Progression and saves

- Run summaries record selected difficulty.
- Objective snapshots are serializable.
- Level scripts remain responsible for mission-specific narrative and geometry.
- Save schema migrations are required before persisting new objective snapshots into existing checkpoint slots.

### 4.6 Phase 1 acceptance criteria

- Salmon Creek opening, lab access, Walker release, Walker defeat, and Golden Ball completion are represented by objective Resources.
- All five Salmon Creek combat zones are represented by encounter Resources.
- Salmon Creek spawns encounters through the reusable runner.
- Existing enemy, route, boss, pickup, death, and victory behavior remains intact.
- Unit tests cover prerequisites, idempotency, completion, encounter one-shot activation, and difficulty math.

## 5. Phase 2 — Content-production pipeline

### 5.1 Level manifest

Every production level owns a `ContentManifest` containing:

- schema/content version;
- level ID and scene path;
- supported difficulty profiles;
- objective definitions;
- encounter definitions.

The manifest is the machine-readable inventory for validation, CI, release reporting, and future editor tooling.

### 5.2 Content validator

Headless validation must reject:

- missing level scenes;
- blank or duplicate objective/encounter IDs;
- self-dependencies and missing prerequisites;
- empty encounters;
- missing enemy scenes;
- invalid spawn positions;
- invalid difficulty identity.

The validator scans `resources/content/*.tres`, prints actionable resource-specific errors, and exits non-zero. It becomes part of `tools/release_validate.sh` and CI.

### 5.3 Authoring kit

Provide reusable templates and documentation for:

- manifest;
- objective chain;
- encounter;
- level metadata/card;
- zone trigger;
- door/switch/key requirement;
- checkpoint;
- pickup cluster;
- secret and narrative sign.

Authoring rules:

- Put tuning in Resources, not script dictionaries.
- Keep mission prose/geometry in the mission domain.
- Use stable lowercase snake-case IDs.
- Scene paths must be `res://` paths.
- Each critical item must have a progression owner and recovery strategy.
- Every gated route requires an automated proof that the key/objective is reachable first.

### 5.4 Phase 2 acceptance criteria

- Salmon Creek has a valid manifest.
- CI runs the content validator.
- Authoring documentation explains how to add a mission skeleton and encounter without editing shared gameplay code.
- A template manifest exists for Mission 2.
- Smoke tests discover all new Resources and scripts.

## 6. Phase 3 — Personally relevant episode plan

The campaign moves through places connected to the owner. These are stylized memories and jokes, not geographic simulations.

### Mission 1 — Salmon Creek: No Dogs Allowed

Status: playable foundation mission. Role: onboarding, field-to-facility descent, first three weapons, Fetch Collar, secrets, Walker finale.

### Mission 2 — Downtown Vancouver / Waterfront: Rain City Run

**Fantasy:** Cobie chases an automated citation convoy from a rain-soaked downtown block onto Vancouver's waterfront while the city declares an emergency leash protocol.

**Route proposal:**

1. Rainy downtown service alley and parking entrance.
2. Waterfront streets and café/pizza frontage.
3. Seawall promenade with sightlines across the water.
4. Convention/terminal service corridors.
5. Rooftop or pier confrontation with the bridge framed in the distance.

**Recognizable but original details:**

- North Shore mountains and a stylized bridge silhouette in the distance; choose a legally safe original skyline composition rather than copied photography.
- Wet pavement, glass towers, seawall railings, floatplanes/ferries, harbor cranes, umbrellas, bike-lane markings, gulls, and rain-slick neon.
- A small affectionate **Ruse Pizza** restaurant reference: pizza boxes, a “RUSE SLICE / DOGS NEGOTIABLE” poster, delivery scooter, or optional health-secret interaction. Confirm naming/logo permission before public release; use original typography and art.
- Local-flavor posters such as “RAIN DELAYED DUE TO RAIN,” “SEAWALL SPEED LIMIT: ZOOMIES,” and “NO FETCHING FROM THE HARBOUR.”
- Easter eggs may include a Cobie reservation card, owner initials, a familiar order, or a date—stored as configurable copy rather than hard-coded personal data.

**New mechanic:** vertical combat across stairs, ramps, seawall levels, and interior/exterior transitions.  
**New enemy:** umbrella shield unit or gull reconnaissance/support enemy.  
**Signature set piece:** moving citation convoy/ferry-terminal lockdown.  
**Reward:** weapon alternate fire or mobility upgrade.  
**Target:** 15–22 minutes, 3–4 secrets.

### Mission 3 — Mount Hood: Off-Leash Summit

**Fantasy:** Cobie follows a stolen weather-control beacon from the forest highway through a snowbound lodge complex and onto Mount Hood.

**Route proposal:**

1. Forest pullout with **Sandy, OR**-style highway signage.
2. Snow road, maintenance sheds, and lift machinery.
3. Timberline-inspired lodge exterior and original grand-lodge interior.
4. Service tunnels/boiler room.
5. Ski slope or summit relay finale.

**Relevant props and Easter eggs:**

- Original green highway signs referencing **Sandy OR**, Government Camp, and Mount Hood destinations; verify exact sign/trademark use before commercial release.
- A Timberline Lodge-inspired silhouette, stonework, timber beams, fireplaces, snowbanks, trail maps, ski racks, lift chairs, grooming machines, hot-cocoa props, and vintage mountain posters. Do not reproduce protected floorplans, signage, logos, or branded artwork.
- Posters: “CHAIRLIFT RESERVED FOR GOOD DOGS,” “AVALANCHE CONTROL / BARK TWICE,” and “SANDY: LAST TREATS FOR 37 MILES.”
- Optional cabin-room Easter eggs drawn from owner memories, kept configurable and privacy-reviewed.

**New mechanic:** slippery/snowy exposure zones, wind gusts, warming shelters, or lift traversal.  
**New enemy:** snowplow tank or ski-patrol ranged unit.  
**Signature set piece:** lodge siege into chairlift/slope assault.  
**Reward:** cold-resistant armor or charged Fetch shot.  
**Target:** 18–25 minutes, 4 secrets.

### Mission 4 — Moon: One Giant Fetch

**Fantasy:** The Golden Tennis Ball signal leads to an absurd lunar compliance base where Earth itself is marked “NO DOGS.”

**Route proposal:**

1. Lunar landing pad.
2. Low-gravity exterior trenches.
3. Kennel research habitat.
4. Observatory/control core.
5. Crater arena and episode boss.

**Props and Easter eggs:**

- Earthrise vista, rover with chew marks, tennis-ball craters, oxygen hydrants, paw-print boot marks, freeze-dried treats, mission patches, and retro space posters.
- Posters: “MOON LEASHES MUST BE 384,400 KM OR SHORTER,” “EARTHRISE: NOT A FETCH TOY,” and “ONE SMALL STEP FOR DOG.”
- Callback props from Vancouver and Mount Hood aboard cargo pallets.

**New mechanic:** controlled low gravity and decompression/airlock timing.  
**New enemy:** vacuum drone/support constellation.  
**Signature set piece:** crater-scale boss with Earth in the sky.  
**Reward/outcome:** episode completion and New Game+ difficulty unlock.  
**Target:** 20–28 minutes, 4–5 secrets.

## 7. Phase 4 — Combat and presentation expansion

- Directional hit reactions and weapon-specific stagger thresholds.
- Weak points, shields, armor, explosive props, hazards, and status effects.
- Alert/suspicion presentation and group tactics.
- Proper weapon view-model reload animations.
- Enemy animation vocabulary: idle, alert, locomotion, telegraph, attack, hurt, stagger, death.
- Exploration/combat/boss/victory music state machine with original music.
- Original Cobie barks and enemy vocals; no imitation of protected dialogue or performances.
- Comic-panel mission intros/outros and end-rank presentation.

Exit gate: Mission 2 demonstrates the expanded combat vocabulary without bespoke forks of shared systems.

## 8. Phase 5 — Accessibility, persistence, and observability

- Multiple versioned save profiles and migrations.
- Mission completion, secrets, difficulty, best time, rank, and collectibles.
- Corrupt-save recovery and checkpoint compatibility tests.
- Full input remapping and specialist-device recovery.
- Subtitle presentation, color-safe indicators, scalable UI, and reduced-motion/flash controls.
- Separate assists for aim, incoming damage, aggression, navigation, ammunition, and timing.
- Privacy-conscious local playtest metrics: encounter time, deaths, accuracy, weapon share, damage source, pickups missed, and objective stalls.
- Long-running soak, unstable-frame pickup/collision, and save-upgrade tests.

## 9. Phase 6 — Alpha, beta, and release

### Alpha

- Episode content complete and start-to-finish playable.
- No progression blockers or missing critical assets.
- Save format frozen with migration policy.
- Performance budgets met on target Mac and representative Web hardware.

### Beta

- Broad human balance and onboarding tests.
- Chrome, Safari, Firefox, native Apple Silicon, and available Intel validation.
- Controller and exact flight-stick hardware matrix.
- Accessibility signoff and photosensitivity review.
- Working-title, real-place, real-business, music, voice, and asset legal review.

### Release

- Signed/notarized Mac build if distributed publicly.
- Store/itch metadata, privacy statement, credits, licenses, support instructions, and reproducible artifact hashes.
- No Blocker/Critical issues; every retained Major issue has an owner-approved disposition.

## 10. Cross-phase non-goals

- Multiplayer, online accounts, cloud saves, mobile/console, procedural campaign generation, photorealism, and a public mod SDK remain out of scope until the single-player episode is stable.
- Do not grow content breadth faster than the production pipeline. Mission 2 is the proof that the project can scale.

## 11. Working method

For each phase:

1. Create a phase branch/commit with a short design note.
2. Implement the smallest reusable contract that supports a real mission need.
3. Migrate Salmon Creek or the current production mission as proof.
4. Add unit, integration, route, smoke, and content-validation coverage.
5. Run Web/macOS exports for export-affecting changes.
6. Record evidence and explicitly list human/hardware checks not performed.
7. Update this PRD's status and acceptance evidence rather than starting a disconnected roadmap.

## 12. Phase 1–2 implementation record

Implemented in the first production-foundation pass:

- `DifficultyProfile`, three initial balance profiles, selected difficulty in run state, and runtime enemy health/damage/speed/aggression scaling.
- Enemy tactical archetype metadata plus preferred-distance, strafe, and retreat behavior.
- `ObjectiveDefinition` and `ObjectiveTracker` with prerequisites, counts, idempotency, lifecycle signals, snapshots, and cycle validation.
- `EncounterDefinition` and `EncounterRunner` with one-shot zone activation, target assignment, lifecycle signals, and completion policies.
- Salmon Creek manifest, four critical objectives, and five encounter Resources replacing runtime use of the level's wave table.
- Content-manifest validation for level paths, identities, prerequisites, cycles, encounter zones, spawn scenes, and spawn positions.
- Authoring guide, template manifest, CI/release-gate integration, focused unit coverage, and full Salmon Creek route regression.

Delivered by the 2026-07-12 implementation pass:

- player-facing Story/Classic/Mayhem selection on level select, defaulting to Classic, driven entirely by the DifficultyProfile resources;
- pickup_amount_multiplier consumption for health/armor/ammo pickups and aim_assist_strength consumption normalized against the Classic baseline — every DifficultyProfile field now affects gameplay;
- save-schema v2 with deterministic migrations, a canonical sanitized checkpoint payload, and difficulty persistence across Continue;
- Mission 2 (Rain City Run) manifest/objective/encounter skeleton with a locked card and non-public graybox.

Intentionally deferred refinements that fit the established contracts:

- multi-wave/reinforcement encounter schema and combat director;
- objective-list HUD instead of the current notification presentation;
- checkpoint persistence of objective snapshots (now unblocked by save-schema v2);
- editor plugin/visual encounter authoring;
- coordinated group tactics, cover selection, and support actions;
- difficulty scaling of temporary-effect durations (zoomies/squeaker) and FULL_RESTORE pickups — pickup_amount_multiplier deliberately covers only health/armor/ammo payloads;
- persisting the last-selected difficulty across application restarts (selection currently lives for the session and in checkpoint saves).
