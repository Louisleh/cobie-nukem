# AGENTS.md

These rules apply to the entire repository.

## Source of truth

1. Read `docs/PRD.md` before changing product behavior.
2. Use Godot 4.7 stable, standard GDScript, and the Compatibility renderer.
3. Do not add copyrighted Duke Nukem assets, dialogue, code, map data, branding, or imitations. Record all asset provenance in `docs/ASSET_MANIFEST.md`.
4. Never describe joystick hardware as verified without a recorded physical test.
5. Read `docs/design/README.md` for the contract of any subsystem you touch.
6. For agent-assisted game work, use the installed `cobie-godot-production` skill and follow `docs/design/agentic-toolchain.md`.

## Spark acceleration

- For complex multi-subsystem phases or requests to use GPT-5.3-Codex-Spark credits, invoke the repo skill `cobie-spark-orchestration`.
- GPT-5.6 remains architect, task owner, reviewer, integrator, PRD/release owner, and final claimant. Spark workers receive one decision-complete, bounded ownership packet and focused tests.
- Use isolated checkouts for Spark writers and never allow overlapping writer ownership. Explicit CLI workers use a disposable parent sandbox with the assigned full local clone nested beneath it so their commit metadata is writable and externally verifiable. Spark workers do not merge, deploy, stamp builds, operate privileged MCP bridges, or claim human/physical-device evidence.
- Review every Spark diff and complete test output with GPT-5.6 before integration. Repository guidance and the PRD—not conversational memory—are authoritative.

## Shared-file ownership

- Architecture/integration owns `project.godot`, `export_presets.cfg`, `.github/workflows`, and `scripts/core`.
- Input owns `scripts/input`, `resources/input_profiles`, and `scenes/debug`.
- Player/combat owns `scripts/player`, `scripts/combat`, `scenes/player`, `scenes/weapons`, and weapon resources.
- Enemy owns `scripts/ai`, `scenes/enemies`, and enemy resources.
- Level owns `scenes/levels` and level-specific interactables.
- UI/presentation owns `scenes/menus`, `scenes/ui`, `scripts/ui`, and rendering presentation.
- QA may add tests but should coordinate before changing production architecture.

When a change crosses an ownership boundary, keep it small and explain its contract in the integration notes. Do not rewrite shared files to work around another system.

## Engineering conventions

- Gameplay reads named `InputMap` actions only. Raw joystick axes/buttons belong in the input adapter and diagnostics.
- Prefer typed GDScript, signals for cross-system events, and custom Resources for balance data.
- Avoid additional autoloads. Add a responsibility to an existing service or justify the exception in `docs/DECISIONS.md`.
- Use `StringName` for stable identifiers and `res://` paths in project data.
- Keep physics behavior in `_physics_process`; keep input edge handling in `_unhandled_input` or the input adapter.
- Keep Web compatibility: no C#, native plugins, thread dependency, or filesystem assumptions.
- Use collision-layer names from `project.godot`; do not hard-code unexplained masks.
- User state belongs under `user://`; no telemetry, accounts, or network dependency.
- Treat warnings as work to resolve, not noise to suppress globally.
- Never commit or export a live-editor MCP bridge, development autoload, or generated Blender working file unless its production purpose and provenance are explicit.
- Register nearby interactables and aim targets through `WorldRegistry`; do not add per-frame global group scans.
- Temporary combat nodes must have a bounded lifetime or return to a pool.

## Quality gate

Before handing off a coherent change, run what the environment supports:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/run_tests.gd
```

For export-affecting changes, also build Web and macOS using the commands in `docs/BUILD_AND_RELEASE.md`. Report commands, results, and anything not run. Do not claim a manual playthrough or physical-device result that did not happen.
