# Test Evidence

This is a durable evidence template, not a claim that every listed check has run against the current working tree. Add one section per candidate; never overwrite older evidence.

## Shipped 0.6.0-alpha.5 — 2026-07-13

| Field | Value |
| --- | --- |
| Version | `0.6.0-alpha.5` / build `2026-07-13-production-navigation-alpha` |
| Feature revision | `4059174` (`query navigation through active ground consumer`) |
| Godot | `4.7.stable.official.5b4e0cb0f` |
| Platform | macOS M4 native Compatibility renderer, Linux headless CI, packaged Web; no physical-device claim |

### Gates

| Check | Result | Evidence |
| --- | --- | --- |
| Navigation contract | Pass | 112 polygons/114 vertices; 41-point full route; eight-point cover route with 2.00 m lateral deviation; registered-before-wake contract; one bounded recovery after three repaths |
| Complete regression/soak | Pass | 100 routes, 100 checkpoints, 100 twin-stick cancellations, 500 weapon transitions, 100 effects; architecture/IP/content/smoke gates green |
| Native 1080p zone profile | Pass with retained outlier | Seven agents at Walker density; Walker p95/p99 19.735/22.058 ms; maximum 151.852 ms retained in Known Issues |
| Complete release/export matrix | Pass | `QA_EXPORTS=1 bash tools/release_validate.sh`; Web and unsigned Universal macOS exports; GitHub Actions `validate-package` green |
| Public deployment | Pass | Source integration `499eab2`; website deployment `f9065c4`; public 1024×768 title screen and truthful loader verified with no console warnings/errors; downloaded PCK hash matched the release artifact |
| Physical iPad and human playthrough | Not run | Explicit human-only gate |

### Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.6.0-alpha.5-itch.zip` | 21,435,476 | `c9045d978f1813f573563b1eccf7a489eebb2c6c8848cd496f9aac89443f9442` |
| `cobie-nukem-0.6.0-alpha.5-macos-unsigned.zip` | 70,799,482 | `3349967becde835e38bcbdc745b207cb4f5b60ce4555f7988af7b01357ab819c` |
| Web PCK | 11,489,896 | `0249b13ca7036cd73d546c5923a927ce5c528591902947b3218a6e7203e86ac2` |

## Candidate 0.6.0-alpha.4 — 2026-07-13

| Field | Value |
| --- | --- |
| Version | `0.6.0-alpha.4` / build `2026-07-13-agentic-overhaul-alpha` |
| Feature revision | `67a0ee4` (`Stabilize combat lifecycle and add rendered route profiling`) |
| Godot | `4.7.stable.official.5b4e0cb0f` |
| Platform | macOS M4 native Compatibility renderer plus packaged Web; no physical-device claim |

### Gates

| Check | Result | Evidence |
| --- | --- | --- |
| Focused UI/asset/gameplay/adversarial/soak | Pass | Typed death screen, five GLBs/five sentry frames, owned timers, pooled bolts, 100 routes/checkpoints/touch cancellations, 500 weapon transitions |
| Native visual route | Pass | Seven distinct 1280×720 captures from opening through death/victory under `docs/evidence/agentic-overhaul/native-route/` |
| Native 1080p zone profile | Pass with retained outlier | p95 ≤22.09 ms and p99 ≤62.65 ms across menu/field/lab/tunnels/Walker/victory; peak 220 draw calls, 2,815 objects, 67.8 MB static memory; isolated Walker maximum 224 ms tracked in Known Issues |
| Projectile first-render profile | Pass | Runtime visual/audio warmup plus bounded pool; four rendered spawn frames stay below 50 ms |
| Complete release/export matrix | Pending final stamped tree | `QA_EXPORTS=1 bash tools/release_validate.sh` required before merge |
| Packaged Web desktop/tablet | PASS | Cache-keyed alpha.4 payload; loading/warming/ready, menu, mission select, gameplay, combat input, and 1024×768 twin-stick HUD verified in the in-app Chromium browser |
| Public deployment | PASS | Source merge `9539978`; website deploy `65863c8`; uncached public landing and 1024×768 twin-stick gameplay passed with no new console warnings/errors; downloaded public PCK hash matched the candidate |
| Physical iPad and human playthrough | Not run | Explicit human-only gate |

### Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.6.0-alpha.4-itch.zip` | 21,429,209 | `24f9468724b3396b843a67be793c6d2688728db0ff69e8b07eaac050e1c14430` |
| `cobie-nukem-0.6.0-alpha.4-macos-unsigned.zip` | 70,793,257 | `b7395cc96379b891c5246675cb3301eb449a339774079c6e2288a277823297dc` |
| Web PCK | 11,482,536 | `aaafdefdc9e649387a9bc070830dbb889eba13b66df96de1548e2779a2c2574d` |

## Candidate 0.6.0-alpha.3 — 2026-07-13

| Field | Value |
| --- | --- |
| Version | `0.6.0-alpha.3` / build `2026-07-13-agentic-production-alpha` |
| Feature revision | `b8795dc` (`Harden agentic production loop and add authored prop`) |
| Godot | `4.7.stable.official.5b4e0cb0f` |
| Platform | macOS host plus locally served packaged Web export; no physical-device claim |

### Gates

| Check | Result | Evidence |
| --- | --- | --- |
| Complete automated release matrix | Pass | `QA_EXPORTS=1 bash tools/release_validate.sh`, exit 0; Web and unsigned Universal macOS exports |
| Expanded vertical-slice soak | Pass | 100 routes, 100 checkpoints, 100 twin-stick cancellations, 500 weapon transitions, 100 effects |
| Engine lifecycle and artifact hygiene | Pass | Zero script/leak/orphan errors; no runtime bridge; no development Resource under `tmp/`; artifact re-exported after the new gate caught two probes |
| Blender-to-Godot asset contract | Pass | Nine rendered mesh parts, collision-only hull, ground placement, dedicated projectile trigger, Fetch-only one-shot activation |
| Headless performance smoke | Pass | 30-frame warmup plus 300 samples: 16.663 ms average, 22.921 ms p95, 24.757 ms p99, 26.142 ms max; zero node drift and -2 object drift (not GPU evidence) |
| Packaged Web desktop | Pass | 1280×720 canvas, title build identity, no browser warnings/errors |
| Packaged Web tablet viewport | Pass | 1024×768 `?touch=1`: title, main menu, five-card selector, and Salmon Creek twin-stick HUD; no browser warnings/errors |
| True iPad multi-touch/comfort/thermal | Not run | Requires physical iPad Safari testing |
| Human full playthrough, prop readability, and feel | Not run | Automated route and browser entry evidence are not represented as a human playthrough |

### Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.6.0-alpha.3-itch.zip` | 21,421,046 | `ba2a1e0c9a99be076f50b6f152fe1c5e870893652f4566421455cf8017012e4c` |
| `cobie-nukem-0.6.0-alpha.3-macos-unsigned.zip` | 70,785,017 | `f7ff01c9d186feb62abdd34c45040721b2fe0d86e7769b933016573ff3ac91cc` |

## Candidate 0.6.0-alpha.2 — 2026-07-12

| Field | Value |
| --- | --- |
| Version | `0.6.0-alpha.2` / build `2026-07-12-aim-roadmap-alpha` |
| Feature revision | `e6b4700` (`Stabilize loading, touch aim, and mission teasers`) |
| Godot | `4.7.stable.official.5b4e0cb0f` |
| Platform | macOS host plus locally served Web export; no physical-device claim |

### Gates

| Check | Result | Evidence |
| --- | --- | --- |
| Parser and focused contracts | Pass | Title readiness, five-card previews, touch aim and adversarial lifecycle |
| Expanded vertical-slice soak | Pass | 100 routes, 100 checkpoints, 100 twin-stick cancellations, 500 weapon transitions, 100 effects |
| 1024×768 tablet browser | Pass | Title, menu, illustrated selector, aim options and gameplay HUD; no captured console warnings/errors |
| Complete export/release matrix | Pass | `QA_EXPORTS=1 bash tools/release_validate.sh`, exit 0; Web and unsigned Universal macOS exports |
| Headless stall smoke | Pass | 180 frames; 16.492 ms average, 24.486 ms maximum (not GPU evidence) |
| True iPad multi-touch/comfort/thermal | Not run | Requires physical iPad Safari testing |
| Human full playthrough and feel | Not run | Automated route evidence is not represented as human evidence |

### Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.6.0-alpha.2-itch.zip` | 21,365,147 | `1be13ee23464d28f2951bc04da14e5e53d25f2f25db5ca5150901b955cc42d16` |
| `cobie-nukem-0.6.0-alpha.2-macos-unsigned.zip` | 70,729,118 | `5161b04e8d1f0d7088437acbc80444927368b8d7fb356a860b008a66e7a4361c` |

## Candidate 0.6.0-alpha.1 — 2026-07-12

| Field | Value |
| --- | --- |
| Version | `0.6.0-alpha.1` / build `2026-07-12-twin-stick-alpha` |
| Feature revision | `575d84e` (`Add deterministic twin-stick iPad controls`) |
| Godot | `4.7.stable.official.5b4e0cb0f` |
| Platform | macOS host plus locally served Web export; no physical-device claim |

### Gates

| Check | Result | Evidence |
| --- | --- | --- |
| Complete automated suite | Pass | `QA_EXPORTS=1 bash tools/release_validate.sh`, exit 0 |
| Expanded vertical-slice soak | Pass | 100 routes, 100 checkpoints, 100 twin-stick cancellations, 500 weapon transitions, 100 effects |
| Web and unsigned Universal macOS exports | Pass | Godot 4.7 release exporters |
| 1024×768 tablet browser | Pass | Title, menu, selector, gameplay, pause, options; no captured console warnings/errors |
| Portrait behavior | Pass | Rotation guard visible and gameplay touch input suppressed |
| True iPad multi-touch/comfort/thermal | Not run | Requires physical iPad Safari testing |
| Human full playthrough and feel | Not run | Automated route evidence is not represented as human evidence |

### Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.6.0-alpha.1-itch.zip` | 17,972,102 | `0b459500a4f9521a5a08fcd224fbd002c6383866896f96c80b6a36dffe1ec35d` |
| `cobie-nukem-0.6.0-alpha.1-macos-unsigned.zip` | 67,336,124 | `ede455d76e362ad70d402f9f244efe2058de2f7c68dd3cb952268bb8dcb1aa26` |

## Candidate 0.2.0-rc1 — 2026-07-11

| Field | Value |
| --- | --- |
| Version | `0.2.0-rc1` / build `2026-07-11-ambitious-rc` |
| Feature revision | `67d6a33` (`feat: deliver ambitious family playtest rc`) |
| Working tree | Candidate source complete; packaging artifacts ignored |
| Godot | `4.7.stable.official.5b4e0cb0f` |
| Platform | macOS host plus packaged Web build in Codex Chromium; no physical-device claim |

### Final candidate gates

| Check | Result | Evidence |
| --- | --- | --- |
| Import/parser and all automated suites | Pass | `QA_EXPORTS=1 bash tools/release_validate.sh`, exit 0 |
| Unit/UI/integration/route contracts | Pass | Combat, input, enemy, UI, integrated gameplay, and Episode 1 route scripts |
| Scene/resource smoke | Pass | 53 scenes and 32 resources load; boot/menu/level/diagnostics enter tree |
| Headless performance smoke | Pass | 180 frames; 6.834 ms average, 10.640 ms max (stall evidence only) |
| Asset/IP heuristic | Pass | Manifest coverage and prohibited filename/source scan |
| Web and unsigned Universal macOS exports | Pass | Godot release exporters, exit 0 |
| Landing and itch archive contracts | Pass | Pages route generated; required Web files at itch ZIP root |
| Packaged browser acceptance | Pass with scope noted below | Title, main menu, selector/locked cards, gameplay HUD, enemy HP, pause and feedback inspected at 1280×720; title also inspected at 1440×900 |
| Debug-assisted complete route | Pass | Automated Episode 1 route validates gates, Fetch Collar, secrets, encounter wiring, boss/finale progression |
| Human clean playthrough | Not run | Requires an independent human tester; automation is not represented as human evidence |
| Chrome/Safari/native/hardware matrix | Not run | Requires the named browsers, native launch, and physical devices |

### Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.2.0-rc1-itch.zip` | 17,623,182 | `7e4bcf554d80a3b9128ecd662a12e326fb58e2c21aa885ea4713b8e1462ac910` |
| `cobie-nukem-0.2.0-rc1-macos-unsigned.zip` | 66,987,145 | `c6f32804a0d3f1dff31c0bd8fbad6035063d3e65923fa30e11074b643fbfbf52` |

Browser acceptance used the locally served packaged Pages artifact at `http://127.0.0.1:8060/`. No Godot asset/navigation failure was observed. A generic in-app Chromium automation error appeared around screenshot/clipboard operations and is not attributed to game code. Audio implementation and timing are contract-tested, but subjective mix quality still needs human listening on the target speakers/headphones.
