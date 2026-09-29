# ENV-1 workstation recovery receipt — 2026-09-15 PT

Status: **CLI/build recovery verified; environment phase remains partially open.**

Source tested: `cdacb2ce50f8afc1eacbb975a40055faf467be06` on `hermes/world-class-369-buildout`, plus the new doctor/tests. Gameplay scripts, scenes, resources, assets, project settings and export presets were unchanged. No public deployment or BETA promotion occurred.

## Verified changes and evidence

- Restored the official Godot 4.7.1 Web and macOS export templates and added `ios.zip`. Before repair the local export-template directory was empty. Version text, ZIP CRC integrity and the complete downloaded archive SHA-256 were checked before installation. Downloads and staging were removed after successful installation.
- Official source: <https://godotengine.org/download/archive/4.7.1-stable/>; GitHub release `godotengine/godot-builds`, asset `Godot_v4.7.1-stable_export_templates.tpz`.
- Archive SHA-256: `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72` (matched the official release API asset digest).
- Installed subset: Web variants, `macos.zip`, `ios.zip`, `version.txt`. Other platform templates are not claimed installed.
- Template hashes: macOS `f9de131f5ed0210924b9b156aea43b1e20fd720dd97690e151081a65c0937a3e`; single-thread Web release `b7b7d7da29fc6cc2f4934fdd26cc571a40e7af57f716ea3eb7e18da720dae28a`; iOS `285e9a01bfa0d0babd8d618f5380f69a81347aae724a304c8a17bbb079d972ce`.
- `tools/workstation_doctor.py` reports version/template integrity, disk thresholds, source bridge exclusion, authoring executables and optional iOS SDK prerequisites without claiming runtime/device acceptance. `--require-headroom` makes the chosen 20 GiB heavy-workload reserve mandatory; ordinary mode warns below 20 GiB and fails below 6 GiB.
- CI pin updated from 4.7.0 to 4.7.1; doctor regression and prerequisite steps added. Remote CI has not yet been exercised for this change.
- Ledger header reconciled with August M1R blocker and August 22 receipt-verifier commits. Existing art/capture/human blockers were not closed.

## Safe storage cleanup

Owner explicitly authorized Mac mini cleanup and iOS preparation in the active session. Cleanup scope remained regenerable development data:

- `npm cache verify` garbage-collected 408,649,798 bytes; `npm cache clean --force` then cleared cached package downloads, not installed packages or active `_npx` environments.
- Homebrew cleanup dry-run reviewed first; actual cleanup reported approximately 811.3 MB removed from cached downloads/obsolete internal files. No installed application was removed.
- Two inactive installer staging directories were removed after bounded `lsof +D` checks found no open files: `~/.cache/codex-runtimes/codex-runtime-install-asIck9` and `~/Library/Caches/com.openai.codex/org.sparkle-project.Sparkle/Installation`. Their allocated sizes before removal were 2,017,841,152 and 2,931,150,848 bytes respectively. The primary Codex runtime was explicitly preserved.
- Free space after staging cleanup measured 18,216,046,592 bytes. Free-space change is not assumed equal to summed directory sizes on APFS or while other processes run.
- `uv cache prune` waited on an in-use cache and was terminated by a 120-second timeout. It was not forced. Model caches, installed apps, source, personal files, simulator runtimes and active environments were retained.

## Commands and results

| Command / operation | Result | Evidence class |
| --- | --- | --- |
| Blender background factory-startup Python version probe | PASS: 5.2.0 LTS | Executable/Python capability, not production asset acceptance |
| `python3 -m unittest discover -s tools/tests -p test_workstation_doctor.py -v` | PASS: 9 tests | Regression fixtures |
| `python3 tools/workstation_doctor.py --ios --json` | WARN, exit 0: CLI prerequisites pass; storage/iOS-delivery warnings remain | Live prerequisite report in `workstation.json` |
| Doctor with `--require-headroom` | Expected FAIL below 20 GiB | Real heavy-workload guard exercised |
| `bash tools/run_godot_safe.sh --timeout 180 --lock-wait 2 -- --headless --path . --editor --quit` | PASS, no reported engine errors | Import/parser |
| `bash tools/release_validate.sh` with exports disabled | PASS, exit 0; 58 unit/integration/smoke script invocations, safe-runner and capture-isolation tests, asset/IP/architecture/content gates | Full non-export local mechanical matrix; `release-validation.log` |
| Safe runner `--export-release Web builds/environment-20260915/web/index.html` | PASS, exit 0; error/leak scan empty | Fresh export; `web-export.log` |
| Safe runner `--export-release macOS builds/environment-20260915/macos/CobieNukem.zip` | PASS, exit 0; error/leak scan empty | Fresh unsigned export; `macos-export.log` |
| Native ZIP CRC + exactly one PCK; Web/native PCK development-marker scans using the release wrapper's marker list | PASS | Package structural/exclusion check, not rendered gameplay |
| `python3 tools/validate_world_class_docs.py`; `git diff --check` | PASS | Documentation/diff |

Headless five-mission performance smoke passed on this run. It explicitly reports zero draw calls and is **not** GPU, rendered frame-pacing, physical-device or human evidence. Historical failures remain historical rather than silently overwritten.

## Fresh artifact identity

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Web PCK | 69,816,612 | `be9706181d06ee9a0c95cd173ff1b0f6f06155722e53054936a16a88290160ee` |
| Web WASM | 39,513,091 | `35116f68540ac41acf7d71ea457added91b5e960a9cca3e2acc72918eaf01277` |
| Unsigned macOS ZIP | 115,810,853 | `dc4970114b66138ee43e28337fe04bdaf617b1c6bb50d89af65d7d22eb6fcf5d` |

Artifacts are ignored local build outputs under `builds/environment-20260915/`, not a stamped release. Platform-specific PCKs differ normally; native PCK SHA-256 is `8bbad3ebb31d472f0fb9f1b3933551241c3be74f03adedb77a0b185f8a338109`.

## Remaining boundaries

1. The protected `AGENTS.md` edit timed out awaiting UI approval and was not applied or retried via another path. Astra is live in Hermes, but existing repository model-role instructions and Codex's unrelated global model default remain unchanged.
2. Approximately 17 GiB free is improved but below the deliberately chosen 20 GiB high-workload reserve. No force-prune or disruption of active services was used to make a green number.
3. iOS template and SDK 26.5 exist; no iOS preset, signing identity, signed native build, App Store setup, or physical iPhone/iPad acceptance is claimed. Exact target device models are still needed.
4. Godot/Blender/editor-browser MCP installation and live capability proof are ENV-2 work. A passing CLI report does not imply those bridges work.
5. WCB-008L continuous evidence remains blocked pending the materially different ENV-3 strategy. Visual production and public release remain separate subsequent phases.

Capacity snapshot at phase start: main GPT/Codex 77% used / 23% remaining in the endpoint's primary window; Spark 0% short-window and 41% weekly used. No credentials were exposed. The post-phase snapshot is reported separately when sampled.
