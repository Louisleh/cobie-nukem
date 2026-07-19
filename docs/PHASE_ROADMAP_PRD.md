# Cobie Nukem — Multi-Phase Production PRD

**Status:** Active production source of truth; five-mission public-beta RC released

**Created:** 2026-07-11

**Last status review:** 2026-07-18

**Current public baseline:** `0.10.0-alpha.1-rc1` (`7cb7ac6` gameplay/runtime revision; source integration `be2b048`; website deployment `a80fec3`; PCK SHA-256 `f24a9911c141aefc97c2eb5ad86c87c74e3e87856c484671a9c773e01d9a0aaf`)

**Current production gate:** All five missions are publicly playable and byte-verified. The definitive-convergence RC hardens startup/scene ownership, closes Level 1–3 regressions, and replaces the most visible Moon/Ventura blockout with original authored presentation kits and mission-specific materials. Levels 2–5 remain explicit `BETA` missions until human/device/art/balance approval.

**Last released alpha:** [`0.10.0-alpha.1-rc1`](https://github.com/Louisleh/cobie-nukem/releases/tag/v0.10.0-alpha.1-rc1) (`7cb7ac6`) — live at <https://www.louislehmann.fyi/games/cobie-nukem/>; Levels 2–5 retain honest `BETA` badges because human full-route, final-art, and physical-device validation are open

**Engine:** Godot 4.7 stable, GDScript, Compatibility renderer
**Purpose:** Turn the family-playtest vertical slice into a sustainable, original multi-level game without sacrificing responsiveness, humor, Web support, or unusual-controller accessibility.

## 0. Current phase dashboard — five-mission world-class cycle

| Mission / track | Public state | Automated state | Current work and honest gate |
| --- | --- | --- | --- |
| Salmon Creek | **PUBLIC** | Route/boss/save-v5/input/signage/connector/portrait/reload gates green; legacy checkpoints remap to authored anchors and retain loadout, ammo, health, and armor | Regression benchmark. Human target-Mac/iPad route, pacing, boss feel, art, mix, motion, humor, and photosensitivity remain open. |
| Rain City Run | **PUBLIC `BETA`** | Five zones, 26-enemy pressure contract, saves, Towmaster resets, touch, manifested materials, signs, weather teardown, and selector/startup gates green | `BETA` removal requires physical iPad, target-Mac, Safari/Chrome routes, pacing, boss fairness, art, mix, humor, and photosensitivity approval. |
| Mount Hood Whiteout | **PUBLIC `BETA`** | Five zones, six objectives, five checkpoints, four secrets, 24 regular enemies, Snowcat, traction, chairlift, Continue restore, and Golden Ball gates green | Human/device/art/balance/audio approval remains explicitly open. |
| Dark Side of Fetch | **PUBLIC `BETA`** | Five-zone lunar route, six objectives, five checkpoints/secrets, 28 enemies, movement environment, 1,000-HP modular boss, restore/finale contracts, and route simulation green | Final hero animation/audio/material pass plus target-Mac, browser, physical-iPad, pacing, combat-readability, mix, humor, and photosensitivity approval open. |
| Pier Pressure | **PUBLIC `BETA`** | Five-zone coastal route, six objectives, five checkpoints/secrets, 28 enemies, 1,000-HP Tidebreaker, restore/finale contracts, and route simulation green | Final hero animation/audio/material pass plus target-Mac, browser, physical-iPad, pacing, combat-readability, mix, humor, and photosensitivity approval open. |
| Packaging | **PUBLIC — BYTE VERIFIED** | Full parser/import, test, Web/macOS export, package, desktop Web, 1024×768 touch, source CI, website CI, Vercel production, and public-PCK identity gates are green. | `0.8.0-alpha.1-rc1` remains the rollback; unsigned/notarized status and human/device gates remain explicit. |

### Implemented five-mission integration checkpoint

- Data-driven Episode 1 campaign definition owns all five cards and mission ordering; Replay and Continue are mission-aware.
- Shared mission-pack, biome-host, movement-environment, timed-hazard, stationary/moving set-piece, and phased-module contracts replace mission-specific forks.
- Startup entry is transactional: repeated activation cannot overlap transitions, gameplay entry owns pointer capture, and retry/restart paths are idempotent.
- Salmon Creek’s Walker HUD streams ordinary damage to zero, fallback reward spawning is removed, summons must clear before the Golden Ball is enabled, and v5 checkpoints persist the full player/loadout state.
- Rain City and Mount Hood retain their existing authored missions while checkpoint route gates, connector depth, environment ownership, pantry reachability, chairlift arrival, and four-attacker Mayhem pressure are hardened.
- Moon and Ventura are complete public-beta mission contracts with original identity, five authored zones, five checkpoints, five secrets, six objectives, 28 regular placements, typed bosses, post-defeat rewards, and checkpoint-safe resets.
- The deterministic five-mission gauntlet covers 1,200 route simulations and 1,000 checkpoint restores in addition to focused mission boot, save, input, boss, and campaign tests.

### Honest completion boundary

This cycle delivers functional, testable five-mission public development—not a false declaration that every mission is already visually or subjectively world-class. Human taste, full physical-device play, final hero assets, mission-specific imported audio, combat pacing, fairness, humor, motion comfort, and photosensitivity remain named gates. Findings become the next evidence-backed production tranche rather than being hidden behind an “automated complete” claim.

### Current definitive-convergence cycle

- **20% flow and stability:** drain asynchronous warmups, reject duplicate transitions, make retry/restart/victory routes idempotent, preserve pointer recovery, and replace touch action words with scalable icons.
- **25% Levels 1–3 closure:** retain their proven gameplay contracts while correcting reproduced sign, connector, placement, summon-cleanup, loading, and UI lifecycle defects.
- **35% Moon/Ventura visual production:** use original Blender-authored presentation-only kits and 25 manifested 512px material families while collision, navigation, objectives, encounters, saves, and boss logic remain independently owned.
- **20% five-mission evidence:** extend the canonical capture harness to Levels 4–5, run every route/boss/checkpoint/input/export gate, measure package growth, and publish only an honestly labelled RC if automated gates are green.

Checkpoint rule: each subsystem lands only after its focused tests and attributable engine-log gate pass. Physical iPad comfort, full human routes, art taste, pacing, mix, fairness, humor, motion, and photosensitivity remain named human gates rather than inferred completion.

**Definitive-convergence public release:** feature revision `7cb7ac6` is stamped as `0.10.0-alpha.1-rc1`, merged through source PR #61 at `be2b048`, published as a GitHub prerelease, and deployed through website PR #129 at `a80fec3`. The complete Web/macOS export matrix, 1,200-route/1,000-checkpoint five-mission gauntlet, 100-route/100-checkpoint/100-touch-cancellation/500-weapon-transition soak, asset/IP and architecture gates, packaged desktop launch, simulated 1024x768 touch launch, and isolated packaged/public Chrome traces are green. The downloaded public 69,468,616-byte PCK is byte-identical at SHA-256 `f24a9911c141aefc97c2eb5ad86c87c74e3e87856c484671a9c773e01d9a0aaf`. Levels 2–5 remain explicitly `BETA`; physical iPad and human full-route/taste gates remain open.

### Archived RC5 foundry release evidence

- Fresh full non-export validation passes both mission routes, all unit/integration/content/architecture/asset-IP gates, 100-route/checkpoint/touch/effect soaks, 500 weapon transitions, 100 Towmaster cycles, 66 scenes, and 95 resources.
- Foreground native Compatibility profiling at 1280×720 uses 300 rendered frames per zone. Rain City p95/p99 results are alley 17.447/23.337 ms, Slice 20.978/21.625 ms, seawall 17.532/21.546 ms, terminal 17.368/17.689 ms, and pier 17.485/20.358 ms, at 200–403 draw calls and approximately 83.6 MB static memory.
- No zone has recurring >100 ms stalls. One isolated 1,054.530 ms macOS scheduling pause was recorded in the pier sample and is retained transparently; the other 2,699 measured gameplay frames remained within the statistical frame budgets.
- Mount Hood pilot captures exist at 16:9, 16:10, 4:3, and ultrawide. They validate the mountain/lodge/fir/snowbank/snowman/lift identity, not gameplay or final art approval.
- The packaged and live Web builds render the RC5 identity without game-origin console errors. The 38,229,008-byte downloaded public PCK is byte-identical to the packaged artifact at SHA-256 `a53c5ccc3b11222d55000d36dc547c508ca6a0683f13184ce3e5634b668b1bfa`.

### Phase allocation and exit policy

- **15% truth/stabilization:** keep docs, GitHub issues, release identity, and Level 1 evidence synchronized.
- **55% Rain City finalization:** manifested textures, zone identity, lighting/readability, lifecycle cleanup, captures, performance, and evidence-backed gameplay fixes.
- **30% Mount Hood foundation:** original source assets, Web-safe materials, canonical pilot, stable five-zone art brief, and validation while locked.
- Flat-color blockout cannot be called final critical-route art. Presentation never owns collision/navigation. Automated evidence never substitutes for human/device approval.
- Broad foundation issues #2–11 are closed as implemented. Current narrowly scoped gates are [#52 Rain City human/art finalization](https://github.com/Louisleh/cobie-nukem/issues/52), [#53 physical iPad validation](https://github.com/Louisleh/cobie-nukem/issues/53), and [#54 Mount Hood public-beta human/art finalization](https://github.com/Louisleh/cobie-nukem/issues/54).

## Archived release and production evidence

### Rain City Run `0.7.0-alpha.1-rc4` public selector/public-beta RC

The mission selector now has an explicit commit boundary: hover and focus never change mission details or the footer action; click, touch, Enter, or controller accept commits a card. Locked future cards remain intentionally selectable for their descriptions, while Start remains disabled. Rain City Run is restored to an always-available public `BETA` with `START BETA`, independent of campaign-save state. Focused UI tests and packaged/live Chrome exercise crossing a locked card after selecting Rain City, deliberate locked-card selection, direct public-beta availability, and a clean browser console.

### Rain City Run startup/reload foundation retained in RC4

RC4 retains RC3's already-merged iPad portrait/sign/connector/interaction/Walker-finale corrections and first-minute startup fixes: cards select without launching, Start is explicit, the trusted Web pointer lock survives scene startup, and `R` proactively reloads partial magazines with HUD and authored audio feedback.

| Workstream | Status | Evidence |
| --- | --- | --- |
| Mission selection | **PUBLIC — AUTOMATED/PACKAGED/LIVE CHROME GREEN** | Hover/focus are non-committing; card activation alone updates details/action; Start is the only launch route; locked teasers remain inspectable; Rain City is public `BETA` |
| Pointer capture | **PUBLIC — PACKAGED/LIVE CHROME GREEN** | Start enters gameplay with canvas focus and pointer lock; one direct click restores a released lock; no game-origin console errors |
| Reload | **PUBLIC — AUTOMATED/PACKAGED GREEN** | `R` reloads a 14/15 Pawstol magazine, HUD exposes available/active state, and imported per-weapon reload start/step/finish cues remain bounded |
| Prior owner fixes | **PUBLIC — AUTOMATED GREEN, HUMAN REVIEW OPEN** | Two-state iPad portrait, forward-facing signs, stable connector top surfaces, bounded interactions, zero-HP Walker defeat, summon cleanup, and post-defeat Golden Ball sequencing ship in the exact PCK |
| Release identity | **BYTE-VERIFIED** | Source PR #49/integration `951f07e`, prerelease `v0.7.0-alpha.1-rc4`, website PR #125/deployment `3a0c5af`, and public 26,282,436-byte PCK SHA-256 `1260693005804915d30f6163036e4ab943063a0ccfbb75380aaee0729ed8bbe8` |
| Human-only | **OPEN** | Physical iPad Safari, full target-Mac route, Safari completion, pacing, art, mix, humor, fairness, touch comfort, and photosensitivity |

### Rain City Run `0.7.0-alpha.1-rc2` public stabilization RC

This focused pass diagnoses the repeated local Godot crash notifications and hardens Level 2 against progression, persistence, physics, navigation, and performance regressions. Recent macOS reports were attributable to overlapping Codex-launched Godot processes: two orphaned mission-host tests retained blocked output pipes while duplicate Godot MCP servers and an old editor process competed for the same project. The new serialized runner gives each invocation an atomic project lock, isolated test save root, bounded timeout, unique log, descendant cleanup, and stale-lock recovery. No new Godot crash report was observed after the cleanup and guarded runs.

| Workstream | Status | Evidence |
| --- | --- | --- |
| Process/crash stability | **AUTOMATED GREEN** | `tools/run_godot_safe.sh` plus runner tests cover lock contention, timeout cleanup, stale recovery, and isolated HOME/save state; release validation routes every Godot invocation through it |
| Route/progression | **AUTOMATED GREEN** | Four visible encounter gates prevent combat skips; mission-host coverage defeats each wave before advancing; checkpoint-restored gates synchronize from encounter state |
| Saves/completion | **AUTOMATED GREEN** | Checkpoints announce only after successful writes; campaign completion is transactional and retryable; secrets autosave exactly once; failed completion preserves checkpoint and departure retry |
| Physics/enemies | **AUTOMATED GREEN** | Umbrella front/rear/open/break damage routes through the shield; Gull movement and attack-token ownership are single-authority; Hound/Groundskeeper attacks require line of sight and consume difficulty damage; pooled projectiles reset interpolation after final placement |
| Grounding/navigation | **AUTOMATED GREEN** | Pickup collision roots remain authoritative while visual children bob; unreachable enemies use bounded recovery or terminal defeat; production Rain City nav bake/path is explicitly tested while mission-host fixtures do not perform redundant bakes |
| Secrets | **AUTOMATED GREEN** | Four unique rewards are functional, checkpointed, and idempotent; terminal secret removes one finale reinforcement without mutating shared source data |
| Performance | **NATIVE AUTOMATED GREEN** | M4 1280×720 Compatibility: alley 18.43/18.54 ms p95/p99, Slice 18.54/18.62, seawall 18.49/18.60, terminal 18.34/18.42, pier 18.30/23.36; 195–406 draw calls and approximately 83 MB static memory |
| Release | **PUBLIC RC — HUMAN GATES OPEN** | Full matrix, source PR #42/integration `e016e44`, prerelease `v0.7.0-alpha.1-rc2`, website PR #123/deployment `c0d7171`, 1024×768 Chrome startup, and downloaded public PCK byte identity are green |
| Human-only | **OPEN** | Physical iPad Safari, full target-Mac route, Chrome/Safari completion, awkward-motion/convoy contact feel, encounter balance, art, mix, humor, and photosensitivity |

### Rain City Run `0.7.0-alpha.1-rc1` public RC ledger

This candidate turns the public Vancouver beta into the campaign's second production mission while preserving an honest `BETA` label until human gates pass. GPT-5.6 retained architecture, art direction, integration, review, evidence, release identity, and deployment ownership. Explicitly pinned `gpt-5.3-codex-spark` workers contributed bounded campaign, save/loadout, boss-soak, audio/HUD, and independent-review packets; root inspected and retested every accepted contribution.

| Workstream | Status | Acceptance evidence |
| --- | --- | --- |
| Campaign continuity | **INTEGRATED — AUTOMATED GREEN** | Rain City public-beta access, mission-aware Replay/Continue, Salmon Creek `CONTINUE TO RAIN CITY`, locked future teasers, direct development override, and canonical mission IDs |
| Persistence/loadout | **SAVE V5 INTEGRATED** | Deterministic v4 migration, checkpoint content revision/remap, campaign/checkpoint isolation, Vancouver loadout, weapon/upgrade snapshots, stale-route recovery, and Municipal Recall Override persistence |
| Authored mission route | **INTEGRATED — HUMAN ROUTE REVIEW OPEN** | Five separated gameplay/presentation zones, vertical lanes, checkpoints, harbour kill plane, four secrets, original jokes/landmarks, 26 authored enemies, and Story/Classic/Mayhem pressure caps of 2/3/4 |
| Enemies and boss | **INTEGRATED — HUMAN FEEL OPEN** | Compliance Gull telegraph/dive/interrupt contracts; manifested 8×4 Umbrella atlas; four typed convoy phases/modules/waves; shared 1,000-HP budget; persistent Towmaster wreck and bounded defeat effects |
| Audio/presentation | **INTEGRATED — HUMAN MIX/ART OPEN** | 27 deterministic imported Gull/Umbrella/convoy WAVs, bounded spatial routing, boss HUD/captions, 13-batch Rain City Blender foundry, Material Maker sources, and project-original Towmaster model |
| Architecture/durability | **AUTOMATED GREEN** | Mission presentation, loadout, path, phase, checkpoint, and convoy-presentation ownership extracted; all production scripts at or below 500 lines except the documented Salmon Creek legacy exemption |
| Automated gate | **FULL EXPORT MATRIX GREEN** | Parser/import, unit/integration/content/smoke, 100 route/checkpoint/touch/effect cycles, 500 weapon transitions, 100 convoy cycles, asset/IP, architecture, headless drift/performance, Web export, and Universal macOS export pass |
| Release | **PUBLIC RC — HUMAN GATES OPEN** | Full matrix, source PR #40/integration `1dcb28c`, prerelease `v0.7.0-alpha.1-rc1`, website PR #122/deployment `ecfdcd6`, packaged/public Chrome startup, and downloaded public PCK byte identity are green |

Human-only throughout: one 15–22 minute target-Mac Classic route, Story/Mayhem spot checks, physical iPad Safari simultaneous twin-stick/audio/thermal pass, Chrome/Safari completion, boss/encounter fairness, route clarity, touch comfort, art cohesion, mix, humor, and photosensitivity. These gates prevent removal of the `BETA` badge; they do not prevent an honestly labeled public RC.

### Alpha.10 production-foundry ledger

Alpha.10 is the first phase to run the complete local visual-foundry loop with the newly available Chrome DevTools integration. GPT-5.6 retained architecture, art direction, review, integration, release identity, and claims. Four pinned Spark audits, two pinned implementation pilots, and one independent pinned reviewer were used. The pickup/auto-aim optimization pilot was rejected after root reproduction showed engine errors and weaker collection reliability; rejected output is not counted as progress.

| Workstream | Status | Acceptance evidence |
| --- | --- | --- |
| First-person weapon art | **PUBLIC — HUMAN ART REVIEW OPEN** | Project-original deterministic Blender source plus manifested Pawstol, Barkshot, and Fetch Launcher GLBs; mechanical, leather-sleeve, and Cobie-paw silhouettes; Godot import/asset contracts and native captures green |
| Weapon switching and feedback | **PUBLIC — HUMAN FEEL OPEN** | Timed resource-driven raise/lower states, eased viewmodel motion, reduced-motion path, overwrite-only queue, richer kill/destructible/world/miss crosshair states, legacy signal compatibility, focused tests, adversarial reload switching, and 500-transition soak |
| Salmon Creek readability | **PUBLIC — HUMAN ART REVIEW OPEN** | Bounded shadowless work/key/fill lights, hazard/guide markings, and zone labels in shed, lab, tunnel, and Walker arena; collision/navigation unchanged; canonical captures reviewed by root |
| Native performance | **GREEN** | Apple M4 1080p Compatibility profile: opening p95/p99 19.378/19.481 ms, lab 17.931/18.524 ms, tunnels 17.787/19.092 ms, Walker 17.583/18.341 ms; static memory below 81 MB |
| Packaged Web trace | **GREEN WITH HUMAN DEVICE GATE** | Chrome DevTools on a real packaged Web export at 1024×768 touch, Fast 4G, and 2× CPU: LCP 797 ms, CLS 0.00, clean Godot/WebGL console, 24.32 MB PCK, 39.51 MB WASM, correct loading screen and title render. Physical iPad thermals/input remain open |
| Independent review | **PASS** | Explicit `gpt-5.3-codex-spark` reviewer found no evidence-backed defect; root test runs supersede the worker sandbox's unavailable Godot user-data path |
| Release evidence | **COMPLETE — ALPHA.10 PUBLIC** | Full `QA_EXPORTS=1` matrix, source PR #38, prerelease `v0.6.0-alpha.10`, website PR #120, Vercel production success, live browser bootstrap, and public PCK byte identity green |

Human-only throughout: subjective weapon feel/art, physical iPad Safari simultaneous touch/thermal/audio, target-Mac clean playthrough, mix, difficulty, boss fairness, humor, and photosensitivity.

### Alpha.9 public-beta and input-readiness ledger

Alpha.9 deliberately narrows the difference between public and internal development. Vancouver is now launchable from the normal mission selector with a `BETA` card badge, `START BETA` action, persistent work-in-progress notice, and public-beta mission caption. It remains visually and mechanically unfinished and has no claimed human full-playthrough approval. Browser mouse readiness is owned by a dedicated `PointerCaptureController`: launch requests occur inside the trusted mission-selection gesture, Web canvas pointer-down restores DOM focus, a first gameplay click reacquires released pointer lock before GUI handling and is consumed rather than fired, and the HUD explains the required action. While capture is unavailable, desktop Web players receive bounded renewable protection; Vancouver also grants ten seconds of opening/respawn protection so activation latency cannot become a spawn death.

| Workstream | Status | Acceptance evidence |
| --- | --- | --- |
| Vancouver public beta | **PUBLIC — HUMAN PLAYTHROUGH OPEN** | Routable production-preview scene, explicit `BETA` card/status/action/caption, stable mission ID, green Web/macOS exports, source PR #34, website PR #100, and byte-identical public PCK |
| Browser pointer readiness | **PUBLIC — HUMAN FEEL OPEN** | Scene-owned capture policy, trusted launch gesture, pre-GUI first-click fallback, visible recovery prompt, canvas focus hook, headless rejection semantics, adversarial coverage, packaged local Web evidence, and public artifact identity |
| Opening safety | **INTEGRATED** | Pointer-wait protection plus ten-second Vancouver initial/retry protection; mission-host and adversarial tests cover both contracts |
| Human validation | **OPEN** | Physical iPad Safari, Chrome/Safari full routes, Vancouver pacing/fairness/art/mix, and family comprehension remain human-only |

Alpha.9 is the immediate rollback release. Alpha.8 remains an older retained rollback artifact set.

### Visual Quality Foundry pilot ledger

The 2026-07-16 pilot converts visual iteration from one-off asset generation into a source-controlled production and evidence loop. Chrome DevTools MCP and Context7 are installed locally, privacy-hardened, and available after a fresh Codex task; Material Maker 1.7 is installed as an authoring tool. The repository owns a `cobie-visual-foundry` skill, canonical art bible, ten-view/four-aspect manifest, isolated Godot Movie Maker capture host, perceptual comparison tools, and a 30/60/120 FPS plus 10-TPS diagnostic matrix. Approved baselines remain human-owned and cannot be overwritten implicitly.

| Workstream | Status | Acceptance evidence |
| --- | --- | --- |
| Toolchain and repository memory | **INTEGRATED PUBLIC** | Godot/Blender/Material Maker verifier green; Chrome telemetry/CrUX disabled; Context7 docs-only; skill metadata/forward test green |
| Salmon Creek opening pilot | **INTEGRATED PUBLIC — HUMAN ART REVIEW OPEN** | Original deterministic Blender source and eight-surface GLB replace procedural goal/fence/lights/trees/bleachers while preserving gameplay collision/navigation; asset/import contracts green |
| Visual and motion QA | **IMPLEMENTED — BASELINE APPROVAL OPEN** | Ten canonical adapters, real 16:9/16:10/4:3/ultrawide capture projects, wrong-dimension/blank/alpha/contrast gates, local diffs, 30/60/120 FPS and 10-TPS captures |
| 4:3 touch presentation | **AUTOMATED CANDIDATE GREEN — DEVICE OPEN** | Genuine 1024×768 Movie Maker evidence exposed and fixed the overlong onboarding line; twin-stick layout remains unchanged; physical iPad ergonomics remain human-only |
| Performance | **NATIVE PILOT GREEN** | Against merged `main`, opening field improves 442→426 draw calls, 567→552 nodes, and 3,169→3,135 objects; candidate p95 17.511 ms and p99 17.800 ms |
| Hero enemy source pipeline | **DEFERRED HIGH-PRIORITY ART WORK** | Existing manifested Hound/Walker atlases and PR #36 scale contracts are retained because a rushed procedural replacement would be a regression; reproducible Blender rigs and genuinely bespoke directional motion remain open |
| Packaged-Web trace | **COMPLETE — HUMAN HARDWARE OPEN** | Fresh-task Chrome DevTools trace covers 1024×768 touch, Fast 4G, and 2× CPU with LCP 797 ms, CLS 0.00, no game-origin console error, and correct loading/title behavior; physical iPad remains open |

### Alpha.8 Rain City Forge ledger

Alpha.8 advances the definitive Salmon Creek slice and produces a complete, development-only Vancouver mission. Vancouver source development is public, but its mission card remains locked in the public build until Alpha.9 human approval. GPT-5.6 retained architecture, integration, art/taste, evidence, and release ownership; explicitly pinned GPT-5.3-Codex-Spark workers contributed bounded UI, gameplay, testing, and review packets. Incomplete or unverifiable worker output was rejected rather than counted as evidence.

| Workstream | Status | Acceptance evidence |
| --- | --- | --- |
| Reusable mission host | **INTEGRATED** | `MissionRuntime`, route, spawn, presentation, audio, campaign, checkpoint, and moving-set-piece contracts are shared; Salmon Creek controller reduced to 445 lines; characterization and route tests remain green |
| Definitive Salmon Creek presentation | **INTEGRATED — HUMAN ART REVIEW OPEN** | Original production material/landmark kit; manifested 8×4 Compliance Hound and Walker atlases; typed presentation profiles; authored ambience/adaptive audio and event-driven Cobie barks |
| Vancouver production preview | **INTEGRATED — SUPERSEDED BY ALPHA.9 PUBLIC BETA** | Five connected zones, upper/lower routes, four checkpoint-safe objectives, four secrets, twenty interactions, Umbrella Shield Enforcer, three-stop citation convoy, post-convoy departure, and Continue rehydration |
| Persistence and durability | **INTEGRATED** | Save schema v4 with deterministic v3 migration; separate campaign progress; strict route snapshots; bounded reset/cleanup and checkpoint restoration |
| Touch and accessibility | **INTEGRATED — PHYSICAL DEVICE OPEN** | Dedicated touch `ALT` secondary-fire action, twin-stick ownership/cancellation, captions and presentation cues, responsive contracts, and focus-loss soak |
| Release evidence | **COMPLETE — ALPHA.8 PUBLIC** | Full matrix, native 1080p profile, Web/macOS exports, source PR #31, prerelease `v0.6.0-alpha.8`, website PR #99, and public PCK byte identity green; gameplay p95 16.907–18.183 ms, p99 17.339–24.872 ms |

Human-only throughout: physical iPad Safari comfort/thermal/audio, target-Mac full playthrough, family comprehension, boss/difficulty/interaction feel, music mix, humor, visual art direction, and photosensitivity.

### Alpha.7 Spark acceleration ledger

The alpha.7 phase uses a repo-committed GPT-5.6/Spark orchestration contract. GPT-5.6 owns architecture, review, integration, evidence, and release; explicitly pinned GPT-5.3-Codex-Spark profiles own bounded packets. Target allocation is 70% definitive Salmon Creek work and 30% locked Vancouver production foundation. Repository guidance and this PRD—not conversational memory—are authoritative.

| Batch | Allocation | Status | Exit evidence |
| --- | ---: | --- | --- |
| 0. Orchestration skill, profiles, validator, pilots | Foundation | **COMPLETE** | Six profiles validate; explicit model inventory proves `gpt-5.3-codex-spark`; read-only sandbox stayed clean; writer pilot integrated; CLI writer sandbox/commit procedure forward-tested and hardened |
| 1. Stabilization audits | Salmon Creek | **COMPLETE — ACCEPTED FIXES INTEGRATED** | Four independent audits; no Blocker/Critical; boss-completion contract, retry audio flush, and Continue checkpoint identity pass focused tests |
| 2. Environmental interaction foundation | Salmon Creek | **INTEGRATED — AUTOMATED GATES GREEN** | Reusable five-kind runtime; 16 stable placements; three-plus per arena; grounded collision, bounded effects, loot/secret wiring, and deterministic reset tests |
| 3. Walker production pass | Salmon Creek | **INTEGRATED — HUMAN FEEL OPEN** | Typed combat profile; explicit phase thresholds and final vulnerable core; normal weapon damage reaches zero; resource-driven attacks, summon cap, post-defeat Golden Ball reward, spectacle, and reset coverage |
| 4. Accessibility and presentation | Salmon Creek | **INTEGRATED — DEVICE GATES OPEN** | Bounded priority captions for narrative/objective/enemy/boss/checkpoint/PA; settings/aspect coverage; existing twin-stick focus/cancellation soaks remain green |
| 5. Mission controller extraction | Salmon Creek | **INTEGRATED — FIRST RESPONSIBILITY SLICE** | `MissionInteractionRuntime` owns catalog validation, construction, stable identity, callbacks, restore, and reset; broader controller decomposition remains incremental technical work |
| 6. Vancouver production foundation | Vancouver | **INTEGRATED — LOCKED/NON-PUBLIC** | Five-zone typed route, finite spawn volumes/patrols/surfaces/checkpoints/secrets, schema-v2 encounters, three-wave convoy, and deterministic route/reset simulation |
| 7. Independent integration and release gate | Release | **COMPLETE — ALPHA.7 PUBLIC** | Independent review and full headless/soak/content/export matrix green; native and packaged/public 1024×768 twin-stick browser checks green; source `4161363`, website `0854ef4`, and public PCK hash verified |

Human-only throughout: physical iPad Safari comfort/thermal/audio, family comprehension, boss and difficulty feel, mix, humor, and photosensitivity.

Batch 0 evidence: setup commit `1b7f58e`; the read-only audit pilot reported structured evidence and no filesystem changes; the implementation pilot added a deterministic ten-pickup authoring assertion and passed `tests/integration/test_episode_1_level.gd`. Its first standard-worktree commit claim was rejected because CLI sandboxing could not update Git metadata outside the checkout. Explicit CLI writers now run in a disposable parent sandbox with a nested full local clone; root review verifies every commit object, parent, owned path, and test independently before integration.

Batch 1 evidence: audit ledger `b1ae6c9`; accepted worker changes `7b649ef` and `3593bdb`; root integration corrections `0bbc25a`. `EncounterRunner` now consumes the authored `BOSS_DEFEATED` policy through an explicit validated completion marker and cleans surviving runner-owned actors/timers exactly once. Checkpoint retry flushes pooled gameplay audio without rebuilding registrations, and Continue immediately restores the sanitized checkpoint ID into run statistics. `tests/unit/gameplay_foundation_test.gd` and `tests/integration/test_episode_1_level.gd` pass after root review. Performance opportunities without measured regressions remain queued rather than being mislabeled as leaks.

Batches 2–6 evidence: the root rejected and corrected incomplete Spark handoffs before integration. `MissionInteractionRuntime`, `WorldInteraction`, and the Salmon Creek catalog now produce 16 unique live props with floor-correct transforms, bounded loot/effects, permanent in-run secrets, and deterministic checkpoint reset. Walker damage advances through explicit phase thresholds, the final vulnerability accepts normal weapon damage to zero, and the Golden Ball is a post-defeat reward rather than an unexplained finishing lock; attack cadence, summon cap, weak-point behavior, recovery, defeat spectacle, and reward sequencing are typed. `GameHUD` uses a bounded priority/deduplication queue across all critical cue families. Hot player/aim registries no longer materialize arrays per physics tick. Mission 2 now owns a five-zone typed route and schema-v2 encounters, including the locked three-wave citation convoy. Focused Episode 1, interaction, catalog, Walker pacing, UI, Vancouver route, and content validation suites are green; physical iPad, human boss feel, and human interaction-density review remain open.

This section is the first place a new Codex or external-auditor run should read. “Foundation complete” means the reusable contract exists, Salmon Creek exercises it, and automated regression passes; it does not mean every future extension listed in the phase is finished.

| Phase | Status | Completed | Explicitly remaining |
| --- | --- | --- | --- |
| 1. Gameplay systems foundation | **VERTICAL-SLICE FOUNDATION IMPLEMENTED — IN REVIEW** | Previous foundation plus profile-driven feel/combat, encounter schema v2, shared mission host, event registries, navigation, reusable directional shields, and reusable moving set pieces | Final human feel/balance and broader mission-host adoption |
| 2. Content-production pipeline | **PRODUCTION PIPELINE EXERCISED BY TWO MISSIONS** | Versioned manifests, validators, authoring guides, provenance gates, Salmon interaction/environment content, Rain City production data/art/audio, and the visual-foundry art/capture loop | Encounter visual editor tooling, human-approved Rain City art baseline, and human pacing review |
| 3. World and episode structure | **MISSION 2 RC — HUMAN REVIEW OPEN** | Rain City has five authored zones, campaign continuity, route/objectives/checkpoints/secrets, Gull and Umbrella enemies, interactions, and a four-phase Towmaster finale; Mount Hood, Moon, and Ventura remain illustrated briefs | Rain City human production approval and `BETA` removal; later missions remain unbuilt |
| 4. Combat and presentation expansion | **ALPHA.10 PRODUCTION TRANCHE PUBLIC** | Existing combat/audio plus bespoke Hound/Walker atlases, Salmon environment materials/landmarks, adaptive mission audio, ambience, event-driven Cobie barks, production weapon viewmodels/lifecycle, shield enemy, and convoy spectacle | Human art, animation, mix, boss, encounter, and effects review |
| 5. Accessibility, persistence, observability | **SAVE V5 + TOUCH + VISUAL/WEB QA FOUNDATION IMPLEMENTED** | Save schema v5, campaign/checkpoint separation, content-revision remap, loadout/upgrades, route snapshots, local metrics, accessible HUD/touch controls, canonical captures, and packaged-Web trace tooling | Human-approved visual baselines, complete settings review, long-session Web memory evidence, and physical devices |
| 6. Alpha, beta, release | **PUBLIC ALPHA PROGRAM ACTIVE** | Reproducible CI/export/package/deploy gates and public Alpha.3–Alpha.10 evidence; Vancouver public beta remains explicitly unfinished | Human/device/browser matrices, content completion, signing/notarization, legal review, store readiness |

### Immediate next gate

**2026-07-17 public-startup and reload stabilization candidate:** mission-card clicks now only select and display `SELECTED // PRESS START`; the explicit Start action is the sole launch path, is guarded against double activation, and preserves the trusted Web pointer-lock request through scene startup. Packaged-Chrome evidence confirms pointer lock is active on gameplay entry and a released lock is restored by one direct canvas click. The `R` action is handled before raw weapon-shortcut keys, allowing proactive reload at any partially depleted magazine; the HUD reports both available and active reload states while the existing original per-weapon mechanical samples play their complete start/step/finish sequence. Focused UI, input, adversarial-state, imported-audio, parser/import, and packaged-Web checks are green. Physical iPad and full human route gates remain open.

**2026-07-17 Salmon Creek finale-integrity candidate:** owner screenshots reproduced six related presentation/progression faults. Interaction placements are constrained to authored walkable bounds; connector top faces are separated from adjacent floors to remove coplanar blue-surface flicker; the tunnel policy sign is wall-mounted with a stable authored transform; Walker health now reaches zero through the final vulnerable phase and triggers a bounded grounded destruction spectacle; live summons are cleared before the Golden Ball reward appears; the fetch objective depends on confirmed boss defeat; and the boss panel is a compact upper-right element that briefly renders `0% / DESTROYED` before hiding. Focused encounter, enemy, interaction, level, asset, and UI contracts are green. Full matrix, runtime capture, and human boss-feel review remain the release gate.

**2026-07-17 visual-production mandate:** D-014 makes high-resolution retro 2.5D authoritative and rejects a pure pixel-art rewrite. The art bible now defines distinct identities for Salmon Creek, Rain City, Mount Hood, Moon, and Ventura, plus one fixed directional-sprite scale formula and feet-baseline contract. New enemy/environment work must use the visual-foundry skill and prove desktop/tablet silhouette consistency.

**2026-07-17 iPad readability and Level 2 QA follow-up (candidate):** the owner-selected Set A HUD art is reduced to two unmistakable states (healthy at 65–100%, critical below 65%) with 512px tight crops and a larger tablet-safe frame. Simulated 1024×768 capture shows an approximately 220px rendered portrait with health/armor and twin-stick controls unobstructed. Salmon Creek landmark labels are single-sided and the scoreboard faces the playable field, preventing mirrored text. Claude PR #44’s actionable Rain City findings are addressed: all three silent floor-damage slabs are gone, the harbour gains a readable explosive chain, Level 2 enemy-size contracts cover Gull/Umbrella, and the flaky mission-presentation teardown passed 20/20 clean stress runs. Physical-iPad re-verification remains open.

**2026-07-16 Rain City public stabilization RC:** `0.7.0-alpha.1-rc2` is live after the full Web/macOS export matrix, independent diff review, exact artifact identity, public browser startup, and website PCK byte verification passed. Preserve the `BETA` label until the target-Mac, physical-iPad, browser-completion, pacing, feel, mix, art, humor, and photosensitivity gates receive human approval.

**2026-07-16 Rain City Run public RC:** `0.7.0-alpha.1-rc1` is live with exact source, package, deployment, runtime identity, and downloaded PCK byte identity verified. The immediate gate is now human-only: target-Mac Classic route, Story/Mayhem spot checks, physical iPad Safari twin-stick/audio/thermal route, Chrome/Safari completion, and review of pacing, fairness, route clarity, touch, art, mix, humor, and photosensitivity. Fix evidence-backed findings against the RC; after approval, remove the badge/warning and restamp final `0.7.0-alpha.1`. Do not unlock Mount Hood, Moon, or Ventura.

**2026-07-16 Alpha.10 production-foundry release:** the visual-foundry pilot and its first full production application are public at feature revision `20649be`. Chrome DevTools validates the real packaged Web bootstrap and 1024×768 title path; three original weapon viewmodels replace the primitive placeholders; explicit lifecycle/feedback is fuzzed; and the remaining Salmon Creek interiors have readable authored lighting. `QA_EXPORTS=1`, source PR #38, GitHub prerelease `v0.6.0-alpha.10`, website PR #120, Vercel production deployment, browser startup, and public PCK byte identity are green. Human review must still approve weapon feel/art, the opening/interior direction, touch hierarchy, complete routes, and physical-device behavior before captures become approved taste baselines.

**Gate passed 2026-07-11.** Accepted critical Fable findings are addressed, the stamped build is public through the owner website, and the touch-first iPad browser path has automated and tablet-viewport regression evidence. The remaining hardware gate is a real iPad Safari feel/thermal/network pass.

**2026-07-12 implementation pass (source repo, not yet released):** the accessible Story/Classic/Mayhem selector is live on level select with all six difficulty multipliers consumed at runtime; save payloads are versioned and migrated; state-transition hardening plus adversarial regression coverage landed; and the Mission 2 content skeleton validates in CI. Next priorities are controlled family playtesting (including difficulty feel), the physical-iPad hardware pass, and Mission 2 production geometry. Do not treat missing Phase 3–6 content as a current defect unless a current contract falsely claims to support it.

**2026-07-12 world-class vertical-slice pass (unreleased):** milestone and issue inventory created; baseline Mac release validation captured; event-driven registries replace per-frame group scans; the Salmon Creek controller has begun extraction into reusable mission runtime/spawn ownership; movement, combat, damage-reaction, pressure, quality, audio-sample, encounter-v2, save-v3, and local-metric contracts are implemented; the render baseline is upgraded from 320×180 nearest filtering to 640×360 linear filtering; fixed-coordinate HUD/menus were normalized and visually checked at desktop and 1024×768 tablet viewports. The non-export release matrix is green. This is an integration checkpoint, not the `0.6.0-alpha` claim.

**Accessibility/performance checkpoint (unreleased):** options now expose text scale, high contrast, reduced motion, touch opacity, left-handed touch, and automatic/Web/native quality selection. Camera shake uses projection offsets so it cannot perturb authoritative weapon aim. Touch controls mirror input and rendering safely, critical enemy telegraphs have optional captions, HUD damage direction is spatial, footsteps report authored surface identity, and temporary combat effects obey the active quality budget. Browser evidence covers the full options screen and a touch-forced Salmon Creek HUD at 1280×720; physical iPad ergonomics remain open.

**Autonomous soak checkpoint (unreleased):** the release gate now runs 100 deterministic Salmon Creek mission-contract routes, 100 schema-v3 checkpoint JSON cycles, 100 focus-loss/twin-stick-cancellation cycles, 500 weapon selection/reload transitions, and a 100-effect budget saturation pass. This supplements—not replaces—the existing scene route, adversarial lifecycle, export, and human/device gates.

**Twin-stick iPad checkpoint (0.6 alpha candidate):** right-side swipe look has been replaced by a fixed aiming joystick consumed in physics ticks. The left movement stick, right aim stick, and action buttons use exclusive multi-touch finger ownership. Options expose independent horizontal/vertical aim speed, Y inversion, stick size and placement presets, opacity, and complete left-handed mirroring. The legacy touch-speed setting migrates to both axes. Automated evidence covers dead zones, full response, three simultaneous fingers, 30/120 FPS aim equivalence, focus cancellation, tablet coordinate scaling, and expanded soak cycles; physical iPad Safari remains a named human gate.

**Loading/aim/roadmap stabilization checkpoint (`0.6.0-alpha.2` candidate):** Web bootstrap now preserves Godot's real download progress while explaining first-load latency; the title preloads the main menu and does not show or accept “continue” until ready. Right-stick aiming adds three typed response profiles, exponential smoothing, delayed outer-ring turn boost, and configurable target friction while retaining physics-tick consumption and clean cancellation. The mission selector now previews five destinations using original manifested art: playable Salmon Creek plus locked Vancouver Waterfront, Mount Hood, Moon, and Ventura Pier cards. This is teaser/pipeline work, not a claim that Phase 3 level production has begun.

**Agentic production checkpoint (`0.6.0-alpha.3`, shipped 2026-07-13):** Godot 4.7, a privacy-hardened Blender 5.1 MCP path, and focused Godot production skills are installed locally and governed by repository contracts. Three Godot MCP candidates, GdUnit4, and FuncGodot/TrenchBroom were piloted before adoption decisions; runtime bridges remain forbidden from source and exports. The release gate now rejects engine script/leak/orphan output, a 300-frame percentile/drift performance smoke replaces the average-only check, and player lookup is event-indexed for pickup/enemy hot paths. The first Blender-authored production prop replaces the procedural ball-return placeholder in Salmon Creek with manifested source/runtime assets and a gameplay contract test. The matching Web artifact is deployed at the public play URL with PCK SHA-256 `4d9ffb7714618d17357d364d8f51d9b8387c8567c6cf6547071b9815e7ab67d1`. This improves the production loop and one secret; it does not complete the remaining directional-animation, imported-audio, navigation, encounter-balance, or physical-device gates.

**Agentic overhaul checkpoint (`0.6.0-alpha.4`, shipped 2026-07-13):** the Blender pipeline now reproducibly emits a five-category original kit plus four-direction/hit-reaction sentry frames, all with source, hashes, collisions, LOD vocabulary, automated Godot import contracts, and native/Web gallery evidence. A native route capture uncovered and fixed a typed-array failure in the real death screen. Gameplay callbacks now use node-owned timers, with an architecture gate preventing SceneTreeTimer regressions; combat audio WAVs are synthesized once during the explicit title WARMING phase and shared; hidden combat material variants are prewarmed; and enemy bolts use a bounded pool. The 1080p Compatibility-renderer profile now reports menu/field/lab/tunnels/Walker/victory p95/p99, draw calls, object counts, and memory. All p95 values are below 33 ms and p99 below 100 ms; one isolated 224 ms Walker attack wall-time sample remains visible as optimization work rather than being misreported as resolved. The public artifact uses cache-keyed engine, PCK, WASM, and audio-worklet names; its PCK SHA-256 is `aaafdefdc9e649387a9bc070830dbb889eba13b66df96de1548e2779a2c2574d`. Physical iPad and subjective playtest gates remain unchanged.

**Agentic durability follow-up (2026-07-13, post-release source evidence):** the selected Godot MCP is now an auditable project fork pinned at `87ece143e3fedb494dd13494c35f120d6fb0a8d7`. A reproducible 44-operation live bake-off covers the complete title/menu/mission route, raw and InputMap input, live player/enemy/pickup state, pause/resume, screenshots, and zero engine errors; a clean ephemeral Codex task independently discovered and followed the Cobie production skill. The FuncGodot pilot now includes measured collision-derived navigation and Compatibility Web export, but remains rejected as a production dependency because stable-ID normalization, Cobie FGD contracts, representative reachability, and tooling-free PCK export are unresolved. Performance profiling now records load/instantiate time and active enemy/physics/navigation/audio/particle/decal populations; current static mission profiles report zero navigation agents, keeping production navigation explicitly open. The shipped alpha is preserved at <https://github.com/Louisleh/cobie-nukem/releases/tag/v0.6.0-alpha.4> with verified artifacts.

**Production-navigation checkpoint (`0.6.0-alpha.5`, shipped 2026-07-13):** Salmon Creek now bakes a Web-safe navigation map from temporary CPU-side collision sources before combat, then removes those sources. The bake contains 112 polygons/114 vertices and a deterministic 41-point route from the opening field through the Walker arena; a separate cover query proves lateral obstacle avoidance. Every grounded archetype receives a throttled `NavigationAgent3D`, flying drones retain authored flight steering, and three failed repaths produce one bounded, locally counted recovery. The pass also fixed a real half-metre Connector D seam that radius erosion exposed as a disconnected arena island. The release gate now runs this contract, the extended profiler reports seven agents at Walker density, and shared death VFX moved out of the 500-line enemy-controller boundary. The live PCK SHA-256 is `0249b13ca7036cd73d546c5923a927ce5c528591902947b3218a6e7203e86ac2`; physical feel remains a human gate.

**Presentation and encounter checkpoint (`0.6.0-alpha.6` candidate, feature revision `52e8240`, 2026-07-13):** three regular enemy archetypes now use original manifested 4×2 atlases with four directional locomotion views plus alert, attack, hurt/stagger, and death poses; Compliance Hound and Walker receive the same deterministic state vocabulary while bespoke atlases remain explicit future art. The procedural primary-combat path is replaced by 60 byte-distinct, deterministic, project-original imported WAVs grouped into 29 bounded cue families: all three weapon lifecycles, four footstep surfaces, and positional enemy alert/attack/hurt/death. Web quality caps concurrent imported voices at 16 and missed first-alert transitions are replayed once on binding. Every Salmon Creek encounter now uses schema-v2 waves: 12 initial-wave actors (including the boss) plus five delayed reinforcements, for 17 total, with peak authored density held at three. Walker pressure, phase cues, recovery drops, and third-cannon summon cadence are resource-driven and reset-safe; checkpoint replay cannot inflate defeated counts. Focused tests, 100-route soak, native 1080p profiling, the full native/Web export gate, independent code review, and packaged desktop/1024×768 browser smoke are green. Human mix, encounter duration/balance, physical iPad, and target-Mac playthrough remain open.

### World-class vertical-slice delivery boundary

Completed in the current integration checkpoint:

- mechanical architecture, engine-error, generated-export, script-size, and asset-provenance gates;
- mission runtime/spawn registry extraction and event-driven interaction/aim indexing;
- profile-driven player feel, combat feedback, damage reactions, pressure tokens, group alert, weak points, and encounter schema v2;
- save schema v3 with deterministic migration and checkpoint restoration of objective/encounter/secret state;
- automatic Web/iPad vs native quality profiles and privacy-preserving local metrics;
- 640×360 render/UI normalization, current-objective HUD, reduced-flash effects, expanded audio buses/limiter, and an imported-sample playback pipeline with bounded polyphony;
- desktop and 4:3 tablet browser captures plus the complete headless regression matrix.

Critical before the next public alpha:

- production navigation and unreachable-actor recovery evidence (**automated gate shipped in `0.6.0-alpha.5`; human feel still required**);
- original directional enemy animation and imported weapon/enemy/footstep sample packs with manifest provenance (**automated production tranche complete for three regular archetypes and all primary cue families; bespoke elite/boss art and human mix remain**);
- Salmon Creek encounter-v2 pacing authoring and Walker spectacle/balance playthrough (**authoring and automated pressure/reset evidence complete; human duration/balance remains**);
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
