# Cobie Nukem — Multi-Phase Production PRD

**Status:** Active production source of truth; `0.6.0-alpha.9` public beta

**Created:** 2026-07-11

**Last status review:** 2026-07-16

**Current public baseline:** `0.6.0-alpha.9` (`c00d54c` gameplay/runtime revision; source integration `7326ff6`; website deployment `13eba81`; PCK SHA-256 `a44af5d67ca30ccc3c69b315ae09286e5e299a0bd0a0dc3a1f31a918dea6e98c`)

**Unreleased development baseline:** `main` at `961d9e8` includes the four iPad playtest fixes from PR #36 (title touch readiness, elite/boss scale, removal of confusing Salmon Creek damage slabs, and a clearer critical-health portrait). The `codex/visual-quality-foundry` candidate adds the first repeatable visual-production pilot; neither source state is deployed yet.

**Last released alpha:** `0.6.0-alpha.9` (`c00d54c`) — live at <https://www.louislehmann.fyi/games/cobie-nukem/>; human full-route validation remains open

**Engine:** Godot 4.7 stable, GDScript, Compatibility renderer
**Purpose:** Turn the family-playtest vertical slice into a sustainable, original multi-level game without sacrificing responsiveness, humor, Web support, or unusual-controller accessibility.

## 0. Current status dashboard

### Alpha.9 public-beta and input-readiness ledger

Alpha.9 deliberately narrows the difference between public and internal development. Vancouver is now launchable from the normal mission selector with a `BETA` card badge, `START BETA` action, persistent work-in-progress notice, and public-beta mission caption. It remains visually and mechanically unfinished and has no claimed human full-playthrough approval. Browser mouse readiness is owned by a dedicated `PointerCaptureController`: launch requests occur inside the trusted mission-selection gesture, Web canvas pointer-down restores DOM focus, a first gameplay click reacquires released pointer lock before GUI handling and is consumed rather than fired, and the HUD explains the required action. While capture is unavailable, desktop Web players receive bounded renewable protection; Vancouver also grants ten seconds of opening/respawn protection so activation latency cannot become a spawn death.

| Workstream | Status | Acceptance evidence |
| --- | --- | --- |
| Vancouver public beta | **PUBLIC — HUMAN PLAYTHROUGH OPEN** | Routable production-preview scene, explicit `BETA` card/status/action/caption, stable mission ID, green Web/macOS exports, source PR #34, website PR #100, and byte-identical public PCK |
| Browser pointer readiness | **PUBLIC — HUMAN FEEL OPEN** | Scene-owned capture policy, trusted launch gesture, pre-GUI first-click fallback, visible recovery prompt, canvas focus hook, headless rejection semantics, adversarial coverage, packaged local Web evidence, and public artifact identity |
| Opening safety | **INTEGRATED** | Pointer-wait protection plus ten-second Vancouver initial/retry protection; mission-host and adversarial tests cover both contracts |
| Human validation | **OPEN** | Physical iPad Safari, Chrome/Safari full routes, Vancouver pacing/fairness/art/mix, and family comprehension remain human-only |

Alpha.9 is the current public baseline. Alpha.8 remains the retained rollback release and artifact set.

### Visual Quality Foundry pilot ledger

The 2026-07-16 pilot converts visual iteration from one-off asset generation into a source-controlled production and evidence loop. Chrome DevTools MCP and Context7 are installed locally, privacy-hardened, and available after a fresh Codex task; Material Maker 1.7 is installed as an authoring tool. The repository owns a `cobie-visual-foundry` skill, canonical art bible, ten-view/four-aspect manifest, isolated Godot Movie Maker capture host, perceptual comparison tools, and a 30/60/120 FPS plus 10-TPS diagnostic matrix. Approved baselines remain human-owned and cannot be overwritten implicitly.

| Workstream | Status | Acceptance evidence |
| --- | --- | --- |
| Toolchain and repository memory | **INTEGRATED ON CANDIDATE** | Godot/Blender/Material Maker verifier green; Chrome telemetry/CrUX disabled; Context7 docs-only; skill metadata/forward test green |
| Salmon Creek opening pilot | **INTEGRATED ON CANDIDATE — HUMAN ART REVIEW OPEN** | Original deterministic Blender source and eight-surface GLB replace procedural goal/fence/lights/trees/bleachers while preserving gameplay collision/navigation; asset/import contracts green |
| Visual and motion QA | **IMPLEMENTED — BASELINE APPROVAL OPEN** | Ten canonical adapters, real 16:9/16:10/4:3/ultrawide capture projects, wrong-dimension/blank/alpha/contrast gates, local diffs, 30/60/120 FPS and 10-TPS captures |
| 4:3 touch presentation | **AUTOMATED CANDIDATE GREEN — DEVICE OPEN** | Genuine 1024×768 Movie Maker evidence exposed and fixed the overlong onboarding line; twin-stick layout remains unchanged; physical iPad ergonomics remain human-only |
| Performance | **NATIVE PILOT GREEN** | Against merged `main`, opening field improves 442→426 draw calls, 567→552 nodes, and 3,169→3,135 objects; candidate p95 17.511 ms and p99 17.800 ms |
| Hero enemy source pipeline | **DEFERRED HIGH-PRIORITY ART WORK** | Existing manifested Hound/Walker atlases and PR #36 scale contracts are retained because a rushed procedural replacement would be a regression; reproducible Blender rigs and genuinely bespoke directional motion remain open |
| Packaged-Web trace | **TOOL READY — FRESH-TASK RUN OPEN** | Chrome DevTools MCP was installed during this task and is not callable until Codex reloads MCP inventory; no Web trace is falsely claimed |

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
| 3. Walker production pass | Salmon Creek | **INTEGRATED — HUMAN FEEL OPEN** | Typed combat profile; explicit phase floors/weak point/Golden Ball defeat; resource-driven attacks, summon cap, recovery policy, and reset coverage |
| 4. Accessibility and presentation | Salmon Creek | **INTEGRATED — DEVICE GATES OPEN** | Bounded priority captions for narrative/objective/enemy/boss/checkpoint/PA; settings/aspect coverage; existing twin-stick focus/cancellation soaks remain green |
| 5. Mission controller extraction | Salmon Creek | **INTEGRATED — FIRST RESPONSIBILITY SLICE** | `MissionInteractionRuntime` owns catalog validation, construction, stable identity, callbacks, restore, and reset; broader controller decomposition remains incremental technical work |
| 6. Vancouver production foundation | Vancouver | **INTEGRATED — LOCKED/NON-PUBLIC** | Five-zone typed route, finite spawn volumes/patrols/surfaces/checkpoints/secrets, schema-v2 encounters, three-wave convoy, and deterministic route/reset simulation |
| 7. Independent integration and release gate | Release | **COMPLETE — ALPHA.7 PUBLIC** | Independent review and full headless/soak/content/export matrix green; native and packaged/public 1024×768 twin-stick browser checks green; source `4161363`, website `0854ef4`, and public PCK hash verified |

Human-only throughout: physical iPad Safari comfort/thermal/audio, family comprehension, boss and difficulty feel, mix, humor, and photosensitivity.

Batch 0 evidence: setup commit `1b7f58e`; the read-only audit pilot reported structured evidence and no filesystem changes; the implementation pilot added a deterministic ten-pickup authoring assertion and passed `tests/integration/test_episode_1_level.gd`. Its first standard-worktree commit claim was rejected because CLI sandboxing could not update Git metadata outside the checkout. Explicit CLI writers now run in a disposable parent sandbox with a nested full local clone; root review verifies every commit object, parent, owned path, and test independently before integration.

Batch 1 evidence: audit ledger `b1ae6c9`; accepted worker changes `7b649ef` and `3593bdb`; root integration corrections `0bbc25a`. `EncounterRunner` now consumes the authored `BOSS_DEFEATED` policy through an explicit validated completion marker and cleans surviving runner-owned actors/timers exactly once. Checkpoint retry flushes pooled gameplay audio without rebuilding registrations, and Continue immediately restores the sanitized checkpoint ID into run statistics. `tests/unit/gameplay_foundation_test.gd` and `tests/integration/test_episode_1_level.gd` pass after root review. Performance opportunities without measured regressions remain queued rather than being mislabeled as leaks.

Batches 2–6 evidence: the root rejected and corrected incomplete Spark handoffs before integration. `MissionInteractionRuntime`, `WorldInteraction`, and the Salmon Creek catalog now produce 16 unique live props with floor-correct transforms, bounded loot/effects, permanent in-run secrets, and deterministic checkpoint reset. Walker normal damage cannot skip phase floors or bypass the Golden Ball finish; its attack cadence, summon cap, weak-point behavior, and recovery data are typed. `GameHUD` uses a bounded priority/deduplication queue across all critical cue families. Hot player/aim registries no longer materialize arrays per physics tick. Mission 2 now owns a five-zone typed route and schema-v2 encounters, including the locked three-wave citation convoy. Focused Episode 1, interaction, catalog, Walker pacing, UI, Vancouver route, and content validation suites are green; physical iPad, human boss feel, and human interaction-density review remain open.

This section is the first place a new Codex or external-auditor run should read. “Foundation complete” means the reusable contract exists, Salmon Creek exercises it, and automated regression passes; it does not mean every future extension listed in the phase is finished.

| Phase | Status | Completed | Explicitly remaining |
| --- | --- | --- | --- |
| 1. Gameplay systems foundation | **VERTICAL-SLICE FOUNDATION IMPLEMENTED — IN REVIEW** | Previous foundation plus profile-driven feel/combat, encounter schema v2, shared mission host, event registries, navigation, reusable directional shields, and reusable moving set pieces | Final human feel/balance and broader mission-host adoption |
| 2. Content-production pipeline | **PRODUCTION PIPELINE EXERCISED BY TWO MISSIONS** | Versioned manifests, validators, authoring guides, provenance gates, Salmon interaction/environment content, public-beta Vancouver data, and the visual-foundry art/capture loop | Encounter visual editor tooling, final Vancouver art/navigation bake, and human pacing review |
| 3. World and episode structure | **MISSION 2 PUBLIC BETA — HUMAN REVIEW OPEN** | Vancouver has five connected authored zones, route/objectives/checkpoints/secrets, a new enemy, interactions, and a citation-convoy finale; Mount Hood, Moon, and Ventura remain illustrated briefs | Vancouver human production review and polish; later missions remain unbuilt |
| 4. Combat and presentation expansion | **ALPHA.8 PRODUCTION TRANCHE IN VALIDATION** | Existing combat/audio plus bespoke Hound/Walker atlases, Salmon environment materials/landmarks, adaptive mission audio, ambience, event-driven Cobie barks, shield enemy, and convoy spectacle | Human art, animation, mix, boss, encounter, and effects review |
| 5. Accessibility, persistence, observability | **SAVE V4 + TOUCH + VISUAL QA FOUNDATION IMPLEMENTED** | Save schema v4, campaign/checkpoint separation, route snapshots, local metrics, accessible HUD/touch controls, and canonical visual/motion capture tooling | Human-approved visual baselines, complete settings review, Chrome packaged-Web traces, and physical devices |
| 6. Alpha, beta, release | **PUBLIC ALPHA PROGRAM ACTIVE** | Reproducible CI/export/package/deploy gates and public Alpha.3–Alpha.8 evidence; Alpha.9 public-beta candidate in validation | Human/device/browser matrices, content completion, signing/notarization, legal review, store readiness |

### Immediate next gate

**2026-07-16 Visual Quality Foundry candidate:** merge the green, source-only pilot after independent review; then restart Codex so Chrome DevTools MCP can trace the freshly packaged Web artifact. Human review must approve the opening art direction and 4:3 touch hierarchy before any candidate capture becomes an approved baseline. Next production work is the same pipeline applied to one truly reproducible Compliance Hound rig/atlas, one Walker phase/death sequence, and the remaining Salmon Creek graybox zones—not another broad tool-installation pass.

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
