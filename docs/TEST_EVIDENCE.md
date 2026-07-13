# Test Evidence

This is a durable evidence template, not a claim that every listed check has run against the current working tree. Add one section per candidate; never overwrite older evidence.

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
