# Test Evidence

This is a durable evidence template, not a claim that every listed check has run against the current working tree. Add one section per candidate; never overwrite older evidence.

## Candidate 0.2.0-rc1 — 2026-07-11

| Field | Value |
| --- | --- |
| Version | `0.2.0-rc1` / build `2026-07-11-ambitious-rc` |
| Git base | `000aafb4026d`; final feature revision recorded in the handoff |
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
| `cobie-nukem-0.2.0-rc1-itch.zip` | 17,623,184 | `7d92c074c2bdb83fda3872e9a83a45b0a4eda68e64e4aee7da79554230675632` |
| `cobie-nukem-0.2.0-rc1-macos-unsigned.zip` | 66,987,144 | `9daff1c6d84e6888d613be37829ddd9e3a8d6ffe8882261068b8c37395f30108` |

Browser acceptance used the locally served packaged Pages artifact at `http://127.0.0.1:8060/`. No Godot asset/navigation failure was observed. A generic in-app Chromium automation error appeared around screenshot/clipboard operations and is not attributed to game code. Audio implementation and timing are contract-tested, but subjective mix quality still needs human listening on the target speakers/headphones.
