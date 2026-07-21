---
name: cobie-godot-production
description: Execute evidence-gated Cobie Nukem Godot gameplay, testing, browser, performance, and release work without drifting from the active WCB packet or claiming human/device evidence.
---

# Cobie Godot Production

Use for any Cobie gameplay, level, UI, input, performance, export, or release change.

## Read first

1. `AGENTS.md`
2. `docs/PRD.md` §1.5
3. `docs/IMPLEMENTATION_PLAN.md`
4. `docs/WORLD_CLASS_BUILDOUT_LOG.md`
5. The relevant file under `docs/design/`
6. `docs/AGENTIC_GAMEDEV_WORKFLOW.md`

The repository and current WCB packet are authoritative. Chat context is not.

## Start gate

```bash
git status --short --branch
bash tools/game_dev_health.sh
bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit
```

- Do not overwrite uncommitted work.
- Work only on a dependency-safe WCB packet.
- State one falsifiable acceptance condition and explicit owned paths.
- Keep raw controller axes/buttons in the input adapter/diagnostics; gameplay consumes named actions.
- Never enable a privileged editor bridge during headless validation or export.

## Focused change loop

1. Reproduce or establish a deterministic baseline.
2. Add the lowest-level regression that captures the required behavior.
3. Make one cohesive typed-GDScript/Resource change.
4. Run the focused applicable suite through the serialized safe runner.
5. Inspect complete output for errors, warnings, leaks, or orphan nodes.
6. Run integration/route/reset/performance coverage appropriate to the packet.
7. For visual changes, follow `.agents/skills/cobie-visual-foundry/SKILL.md` and preserve editable sources/provenance.
8. Update `docs/WORLD_CLASS_BUILDOUT_LOG.md` before committing.

## Standard validation

```bash
bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/run_tests.gd
```

For export-affecting work:

```bash
QA_EXPORTS=1 bash tools/release_validate.sh
```

For target-Mac rendered performance:

```bash
/opt/homebrew/bin/godot --path . --resolution 1920x1080 --script res://tests/smoke/zone_performance_profile.gd
```

## Evidence classes

Keep these separate:

- **Automated functional:** parser, unit/integration, route, reset, soak, content checks.
- **Native rendered:** Compatibility renderer on the target Mac; not a human playthrough.
- **Packaged Web:** freshly exported artifact in a browser with console evidence.
- **Simulated tablet:** forced-touch/4:3 browser evidence; not physical-device evidence.
- **Human-only:** feel, pacing, fairness, humor, mix, photosensitivity, physical iPad, flight stick, family comprehension.

## Worker contract

A delegated writer receives:

- one WCB packet and one acceptance condition;
- 1–8 files normally;
- explicit owned and forbidden paths;
- focused verification commands;
- an isolated checkout/branch;
- no authority to merge, stamp, deploy, alter final PRD status, or claim human evidence.

The integration owner inspects the complete diff and output, reruns tests, updates the ledger, and accepts or rejects the commit.

## Stop conditions

Stop integration and leave the packet blocked for:

- progression deadlock or nondeterministic restore;
- stuck input or loss of keyboard recovery;
- attributable Godot errors, leaks, or orphan nodes;
- unbounded temporary nodes or measurable monotonic growth;
- unmanifested/unlicensed assets;
- runtime/editor bridges in source or export;
- source/package/site/public identity mismatch;
- false human/device claims;
- a required test that cannot run.

## Packet completion record

Record in `docs/WORLD_CLASS_BUILDOUT_LOG.md`:

- packet ID and acceptance condition;
- source commit and owned paths;
- files changed;
- exact commands/results;
- evidence paths/classes;
- remaining human-only or blocked claims;
- integrated commit;
- next dependency-safe packet.
