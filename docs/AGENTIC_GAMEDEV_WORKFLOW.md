# Agentic game-development workflow

This is the repository-facing operating guide for autonomous Cobie work. The installed `cobie-godot-production` skill is the concise entry point; this document contains commands and evidence boundaries that must remain reviewable with the source.

## Start clean

1. Read `AGENTS.md`, `docs/PRD.md`, `docs/PHASE_ROADMAP_PRD.md`, the relevant subsystem design record, and this document.
2. Run `bash tools/game_dev_health.sh`.
3. Confirm Godot reports `4.7.stable`, inspect `git status`, and work on a short-lived `codex/` branch.
4. State the exact reproduction and a falsifiable acceptance condition before changing source.

## Spark acceleration loop

For multi-subsystem phases, invoke the repo-scoped `cobie-spark-orchestration` skill. GPT-5.6 owns architecture, task packets, review, integration, evidence, and release. Six project profiles pin bounded workers to `gpt-5.3-codex-spark`; verify model identity before counting credit usage. Use up to four read-only workers or two non-overlapping isolated-worktree writers, require structured result packets and one cohesive commit, and run a fresh read-only reviewer after each coherent batch. On an explicit Spark usage limit, stop new workers, finish integration of completed work, record the queue in the PRD, and never silently substitute another model.

## Native inspection loop

The selected Codex server is `godot-cobie`, pinned and described in `docs/design/agentic-toolchain.md`.

1. Start the Godot 4.7 editor with the source project.
2. Enable the audited local bridge only for the active inspection session.
3. Use the MCP to inspect the current scene tree, run the relevant scene, drive named InputMap actions, inspect player/enemy/pickup state, capture screenshots, and query errors.
4. Treat the Godot editor process output as authoritative in parallel with the MCP error query.
5. Stop the game and bridge cleanly. Confirm the editor did not normalize unrelated scenes or project settings.
6. Remove/disable the bridge before headless validation. `tools/release_validate.sh` mechanically refuses to continue while it is present.

The bridge is privileged local tooling, not a gameplay dependency. A clean release never contains an editor plugin, listener, autoload, credential, test backdoor, or local machine path.

## Focused change loop

1. Add or improve the lowest-level deterministic regression that expresses the failure.
2. Make one cohesive change using typed Resources, signals, `WorldRegistry`, named InputMap actions, physics ticks, and bounded temporary nodes.
3. Run the focused test and inspect its complete output for errors, warnings, leaks, and orphans.
4. Re-run the native scenario, inspect live state and signals, and capture a standardized after image when the change is visual.
5. Run the relevant soak/route suite, followed by `QA_EXPORTS=1 bash tools/release_validate.sh` for export-affecting work.

For target-Mac rendered performance evidence, run:

```bash
/opt/homebrew/bin/godot --path . --resolution 1920x1080 --script res://tests/smoke/zone_performance_profile.gd
```

This records menu, opening, lab, tunnel, Walker-arena, and victory percentiles plus draw calls, object/node counts, and static memory. Headless timing remains a stall regression, not GPU evidence.

## Browser and tablet loop

1. Serve the freshly packaged Web artifact locally; do not browser-test a stale editor export.
2. Verify desktop loading, menu, selector, gameplay entry, pause/focus recovery, death/retry, and basic combat.
3. Repeat with `?touch=1` at a 4:3 tablet viewport. Verify safe areas, movement/aim finger ownership, simultaneous fire, cancellation, and portrait/landscape behavior.
4. Record console output and screenshots. Simulated tablet evidence is not physical-iPad evidence.
5. Physical iPad Safari comfort, thermal behavior, device audio, and family comprehension remain human gates.

## Blender loop

See `docs/BLENDER_ASSET_PIPELINE.md`. Blender MCP is localhost-only, telemetry-disabled, and privileged because it can execute arbitrary Python. Preserve editable `.blend` sources under `assets/source/blender/`, deterministic runtime exports under `assets/models/`, and exact provenance in `docs/ASSET_MANIFEST.md`.

## Release loop

1. Run `QA_EXPORTS=1 bash tools/release_validate.sh`.
2. Complete the applicable rows in `docs/MANUAL_UX_CHECKLIST.md` without inventing human/device evidence.
3. Stamp `scripts/core/build_info.gd`, package through `tools/package_release.sh`, and record hashes in `docs/TEST_EVIDENCE.md`.
4. Merge the green source PR first. Copy only the stamped Web artifact into the website repository, preserving site-owned presentation.
5. Run the website build, route verifier, and hygiene verifier. Merge its deployment PR.
6. Open the uncached and ordinary public URL, verify version/revision, exercise the public route, and hash the deployed PCK.
7. Record rollback artifacts and synchronize the PRD public baseline.

## Evidence taxonomy

- **Automated functional:** deterministic contracts, routes, soak/fuzz cycles, engine output.
- **Native rendered:** Godot Compatibility renderer on the target Mac; not a human playthrough by itself.
- **Packaged Web:** exact exported artifact served through a browser, including console evidence.
- **Simulated tablet:** browser viewport and forced-touch behavior; not hardware ergonomics.
- **Human-only:** feel, fairness, humor, mix, photosensitivity, physical iPad Safari, flight-stick hardware, and family comprehension.
