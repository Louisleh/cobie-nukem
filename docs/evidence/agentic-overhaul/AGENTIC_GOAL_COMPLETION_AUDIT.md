# Agentic game-development goal completion audit

Date: 2026-07-13

Engine: Godot `4.7.stable.official.5b4e0cb0f`

Release integration: `9539978824279bd886f7088b768597745f7a0619`

Durability follow-up branch: `codex/agentic-toolchain-evidence`

## Outcome

The repository now has one governed Godot MCP, one privacy-hardened Blender MCP, a Cobie-specific Codex skill, a documented native/browser/asset/release loop, measured FuncGodot and GdUnit4 decisions, deterministic Blender production assets, stricter export contamination checks, native route captures, and rendered 1080p zone profiling. The pass also fixed a production death-screen parser failure exposed by the new route capture and eliminated unowned gameplay timers that could resume after teardown.

## Requirement disposition

| Area | Status | Evidence |
| --- | --- | --- |
| Clean baseline and rollback | Complete | `docs/AGENTIC_GAMEDEV_BASELINE.md`; alpha.3 source/public hashes retained |
| Godot MCP bakeoff | Complete | alexmeckes selected; slangwald/bradypp rejected for missing required live-input/runtime coverage; `docs/design/agentic-toolchain.md` |
| Godot 4.7 live operation | Complete | Full title/menu/mission route, raw key/pointer, InputMap movement/weapon/pause, live player/enemy/pickup state and stdout exercised; audited fork `87ece14`; 148 local MCP tests |
| Export bridge safety | Complete | source-presence block plus post-export PCK marker inspection |
| Blender MCP | Complete | pinned localhost/telemetry-off installation and privileged-execution boundary |
| Blender-to-Godot production pilot | Complete | reproducible `.blend`, five GLBs, five directional/reaction frames, manifest hashes, native/Web gallery captures, asset contract |
| Cobie production skill | Complete | `/Users/louislehmann/.codex/skills/cobie-godot-production/SKILL.md` plus references, health workflow, and successful clean-clone/ephemeral-task discovery test |
| FuncGodot/TrenchBroom | Complete decision | 52-node scripted rebuild, collision/nav bake, semantic reimport comparison, and Compatibility Web export; isolated Vancouver pilot only; `docs/LEVEL_AUTHORING_PIPELINE.md` |
| GdUnit4 | Complete decision | compatibility pilot passed; not vendored due runner noise/class footprint/headless-input limits |
| Daily loop | Complete | `docs/AGENTIC_GAMEDEV_WORKFLOW.md`, `docs/GODOT_MCP_SETUP.md`, `tools/game_dev_health.sh` |
| Salmon Creek functional contracts | Complete automated evidence | 100 routes/checkpoints/touch cancellations, 500 weapon transitions, 100 effect cycles; native field-to-victory captures |
| Death/retry runtime | Fixed | typed fallback selection in `DeathScreen`; live death capture; UI regression |
| Async lifecycle | Fixed | every gameplay `SceneTreeTimer` replaced with node-owned timers; architecture gate rejects regressions |
| Combat first-use warmup | Improved | shared synthesized-cue cache, explicit title WARMING state, visual pipeline prewarmer, bounded 16-bolt pool, projectile rendered-frame regression |
| Performance | Complete checkpoint, ongoing optimization | native 1080p per-zone p95/p99/draw-call/object/memory report; headless 300-frame drift smoke; load/instantiate time plus enemy/physics/nav/audio/particle/decal populations |
| Physical iPad and subjective feel | Human-only | intentionally not claimed; see `docs/KNOWN_ISSUES.md` |
| Public desktop death/retry | Complete browser evidence | deployed alpha reached unattended combat death; Retry restored Salmon Creek with authored protection |
| Public tablet layout/start | Complete browser evidence | 1024×768 `?touch=1` route reached gameplay with distinct Move/Aim sticks and all action buttons visible |

## Asset pilot inventory

- Salmon Creek bench/barrier family: 11 meshes, 132 triangles, two collision proxies.
- Maintenance tunnel module: 11 meshes, 132 triangles, floor/wall/ceiling collision proxies.
- Compliance crate: LOD0/1/2 plus collision, 72 triangles across authored LOD meshes.
- Fetch-charge pedestal: eight meshes, 636 triangles, collision proxy.
- Rain City beacon: seven meshes, 428 triangles, collision proxy.
- Compliance sentry: four 384×384 directional frames plus a distinct hit frame.

Source and runtime SHA-256 values are in `docs/ASSET_MANIFEST.md`. The assets remain a validated pilot/gallery and are intentionally absent from release PCKs until promoted through level art direction.

## Rendered Mac evidence

The 1920×1080 Compatibility-renderer profile measures 120 frames per state after 24 warm-up frames. Final observed p95/p99 values were:

| State | p95 | p99 | Maximum draw calls | Peak objects | Peak static memory |
| --- | ---: | ---: | ---: | ---: | ---: |
| Main menu | 18.31 ms | 18.88 ms | 25 | 1,861 | 44,971,744 B |
| Opening field | 18.36 ms | 20.87 ms | 220 | 2,602 | 65,226,547 B |
| Lab | 20.15 ms | 62.65 ms | 140 | 2,780 | 66,297,409 B |
| Tunnels | 18.26 ms | 45.63 ms | 201 | 2,782 | 66,335,717 B |
| Walker arena | 18.49 ms | 29.15 ms | 74 | 2,812 | 66,521,325 B |
| Victory | 22.09 ms | 59.75 ms | 84 | 2,815 | 67,823,333 B |

All p95 values remain below the Web/iPad 33 ms budget and all p99 values below the 100 ms stall gate. An isolated 224 ms wall-time outlier occurred during the Walker attack sample even though the percentile gate remained green; it is retained as optimization evidence, not hidden or described as resolved. Static-AI profiling is clean, localizing the outlier to active combat rather than base rendering. Physical target-Mac feel and iPad thermal behavior remain human gates.

## Visual evidence

- `assets/native-production-gallery-1280x720.png`
- `assets/web-production-gallery-1280x720.png`
- `native-route/01-forbidden-field.png` through `07-victory.png`

All native route frames have distinct hashes. The Web gallery was exported from a disposable project and inspected at 1280×720 with no browser console warning/error.

## Remaining gates

- Physical iPad Safari multi-touch comfort, audio unlock, app switching, heat, and network load.
- Human full target-Mac playthrough and weapon/difficulty/Walker fairness.
- Art, humor, audio-mix, captions, and photosensitivity judgment.
- Continue profiler-driven reduction of the isolated Walker attack outlier; it is not a Blocker for a public alpha because p95/p99, functional routes, node lifetime, and exports pass, but it remains tracked technical work.
- Production navigation remains unimplemented in the current mission profile (`nav_agents=0`); the FuncGodot proxy bake does not satisfy that gameplay gate.

## Release artifact

The public alpha is also preserved as a GitHub release at <https://github.com/Louisleh/cobie-nukem/releases/tag/v0.6.0-alpha.4> with the verified itch/Web ZIP, unsigned macOS ZIP, `SHA256SUMS.txt`, and `BUILD_INFO.txt`. The tag targets source integration `9539978824279bd886f7088b768597745f7a0619`; the runtime gameplay identity remains `67a0ee4` as recorded in the build artifact.

The public runtime was rechecked after release through landing, title, menu, level select, Salmon Creek, live death, Retry, and a 1024×768 forced-touch startup. See `PUBLIC_RUNTIME_RECHECK.md`. Physical Safari/iPad claims remain open.
