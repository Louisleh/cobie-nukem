# Test Evidence

This is a durable evidence template, not a claim that every listed check has run against the current working tree. Add one section per candidate; never overwrite older evidence.

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
