# Agentic game-development baseline — 2026-07-13

## Identity

- Source branch: `codex/agentic-gamedev-overhaul`.
- Baseline source commit: `5daea607b1bee76ffba7f897ff0ff77344ff7186`.
- Godot: `4.7.stable.official.5b4e0cb0f`.
- Source build label: `0.6.0-alpha.2`.
- Public build observed at `https://www.louislehmann.fyi/games/cobie-nukem/`: `0.6.0-alpha.2`, revision `e6b4700`.

The public revision and current source commit are intentionally recorded as different identities; deployment verification must reconcile them before the next release claim.

## Clean baseline gate

`QA_EXPORTS=1 bash tools/release_validate.sh` passed before implementation:

- 100 seeded routes;
- 100 checkpoint cycles;
- 100 twin-stick cancellation cycles;
- 500 weapon transitions;
- 100 effect cycles;
- 55 scenes and 68 Resources validated;
- Web and macOS exports completed.

The headless performance smoke ran 180 frames at 16.503 ms average and 21.481 ms maximum. This is a stall detector, not GPU, draw-call, memory, thermal, or physical-device evidence.

One ObjectDB leak warning was observed in `ui_scene_test.gd` despite the green exit. The smoke suite was rechecked independently and was clean. The UI leak was traced to polling a threaded menu preload without retrieving its completed Resource; title/menu deferred-layout callbacks also remained vulnerable to resuming after teardown.

Baseline artifact sizes and hashes:

- Web PCK: approximately 11 MB; SHA-256 `924016c447e83230b85283445d14f22806f40084a976d60b08e824d0cb8e7064`.
- Web WASM: approximately 38 MB; SHA-256 `7eda98958eb09135a1acb54a4323a00b1a55af1997f15fa1cdc2b93e3df46656`.
- macOS ZIP: approximately 67 MB; SHA-256 `3e4d9d644b8e640517b7b27aa1a139855a8e382c05f0a5c3a49d37f9a8c70d6d`.

## Live-tool bakeoff evidence

Three Godot MCP candidates were inspected. Only the alexmeckes candidate exposed all required runtime InputMap and screenshot operations. Its original production dependency audit had eight vulnerabilities; the local pinned installation was upgraded and now reports zero known vulnerabilities with 144/144 tests passing. The bridge connected to Godot 4.7, returned the live scene tree, ran the game, reported the 640×360 runtime viewport, captured the title screen, and stopped the scene.

The first run also exposed an upstream defect: play-scene was invoked while Godot flushed a deferred message, emitting editor progress-dialog errors that the MCP error query did not report. The local fork now defers play/stop by a full process frame, and editor stdout remains a required parallel evidence channel.

Blender 5.1.2 and its pinned MCP were checksum-verified, connected on localhost, and validated by reading the scene, creating and inspecting a temporary object, then removing it. Telemetry and all third-party asset integrations are off.

## Implementation checkpoint

Completed on this branch:

1. The threaded preload is now retrieved and explicitly released; title/menu deferred layout uses cancellable frame-signal callbacks. The strict release gate rejects ObjectDB/resource/orphan warnings, and the UI suite is clean.
2. Live MCP sessions require editor-process stdout in addition to the bridge error query; local play/stop lifecycle handling was hardened.
3. Architecture documentation now describes the actual 640×360 linear-filter baseline.
4. Performance smoke now records 300 post-warmup samples, p50/p95/p99/max frame time, object/node drift, static memory, and draw calls where the renderer exposes them. Current headless evidence is p95 21.936 ms, p99 23.354 ms, no node drift, and a two-object cleanup decrease.
5. `WorldRegistry` now indexes the player, eliminating pickup per-physics group scans and making enemy target acquisition event-first.
6. The Blender pipeline produced and integrated the original Salmon Creek ball-return machine. A new asset contract validates authored mesh parts, ground placement, physical collision, a dedicated projectile trigger, and one-shot Fetch activation.

Still human-only: physical iPad feel and Safari thermal behavior, target-Mac rendered pacing/playthrough, weapon/difficulty balance, photosensitivity, and final art/audio taste.

## Optional-pipeline pilot decisions

### FuncGodot and TrenchBroom

Pinned FuncGodot commit `d68960dfce8b99f0dbc571abfc3fd9c396126b76` successfully imported the pinned example map at commit `d9a02b846d1de0fcca338604d8631da282112ba7` under Godot 4.7. The 10,128-byte source map generated a 17,201-byte, 29-node scene with 14 mesh/collision-related nodes and no engine errors. TrenchBroom 2026.1 is installed.

Decision: viable for an isolated Vancouver graybox experiment, deferred for Salmon Creek. Adoption still requires a Cobie-specific FGD/entity contract, Compatibility/Web export proof, deterministic reimport diff, navigation bake, collision/performance budget, and confirmation that authored post-import changes have a safe ownership model.

### GdUnit4

Pinned GdUnit4 commit `237b1b19c2041790b277d6dbae10b402ffb9cb69` passed a four-case pilot covering parameterized weapon data and async signal observation with zero test failures, errors, flakes, skips, or orphans. It also adds roughly 459 globally scanned framework classes. Its stock macOS runner uses remote-debug port `0`, which Godot 4.7 rejects; changing to a valid closed port still emits expected connection errors. A direct headless run works for non-input tests with `--ignoreHeadlessMode`, while the framework explicitly warns that UI InputEvents are ineffective there.

Decision: do not vendor it now. The stock dependency-free suite remains faster, quieter, and Web-safe. Reconsider only when a production defect genuinely needs its scene runner, mocking, fuzzing, or rich report output; if adopted, wrap the CLI to eliminate spurious engine errors and exclude the addon from exports.
