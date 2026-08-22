# Ox Alpha Coding Gauntlet

**Status:** experimental, manual-only worker lane
**Root owner:** GPT-5.6-sol/high through the default Hermes profile
**Worker route:** `opencode-free/x-preview-f-free` through the isolated `oxcobielab` profile

## Purpose

Use the temporary Ox Alpha preview for bounded public-repository coding work without changing Cobie Nukem's default model, source authority, ownership rules, or evidence standards. Ox Alpha is a worker and critic; it is not the architect, integrator, release owner, or final claimant.

## Safety boundary

- The `oxcobielab` profile is fresh, has no bundled skills, and disables persistent memory and user-profile injection.
- The runner starts Hermes with a minimal environment, a temporary HOME, no inherited credential-like environment variables, and an isolated full clone.
- Workers receive only `terminal,file` tools and are told to stay inside the clone. Profile and prompt isolation reduce accidental disclosure but are not an OS security boundary.
- Use only for this public/sanitized repository. Never include credentials, private notes, customer information, financial data, health data, or unrelated repositories.
- Ox Alpha remains manual-only. It is not an automatic fallback or delegation default.

## Roles

1. **GPT-5.6 architect:** reads authority, freezes one dependency-safe packet, exact ownership, acceptance, and stop rules.
2. **Ox Alpha audit/critic:** inspects a clean isolated clone and returns the required YAML receipt without writing.
3. **Ox Alpha writer:** optional; receives exact non-overlapping paths, works in a full clone, makes one cohesive local commit, and cannot push or integrate.
4. **GPT-5.6 integrator:** independently reviews the patch and raw outputs, reruns focused and root tests in canonical source, accepts or rejects, commits, pushes, and updates the durable ledger.

No worker self-report is evidence. The runner fails closed on a dirty audit clone, missing receipt fields, out-of-scope writer paths, uncommitted writer changes, missing writer commit, nonzero Hermes exit, or dirty canonical source at launch.

## Commands

Read-only audit:

```bash
python3 tools/ox_alpha_gauntlet.py \
  --mode audit \
  --work-id OX-WCB-008L-REOPEN-AUDIT \
  --task-file docs/work_packets/ox_alpha/wcb008l_reopen_audit.md \
  --output-dir /tmp/cobie-ox-evidence/OX-WCB-008L-REOPEN-AUDIT
```

Bounded writer after GPT-5.6 freezes ownership:

```bash
python3 tools/ox_alpha_gauntlet.py \
  --mode writer \
  --work-id OX-WCB-008L-M1-EXTERNAL-CAPTURE \
  --task-file /absolute/path/to/frozen-task.md \
  --owned-path tools/example.py \
  --owned-path tests/example_test.py \
  --output-dir /tmp/cobie-ox-evidence/OX-WCB-008L-M1-EXTERNAL-CAPTURE
```

Writer clones are retained and identified in `receipt.json`. Never cherry-pick until GPT-5.6 verifies baseline parent, changed-path scope, full diff, tests, and evidence.

## Stop rules

Stop rather than widen scope when:

- canonical source is dirty;
- the packet conflicts with `AGENTS.md`, PRD, implementation plan, or buildout log;
- WCB-007 frozen paths, route/collision/navigation, progression, damage/balance, breadth, BETA status, deployment, or release identity would change;
- the worker reads or changes outside its clone;
- evidence cannot distinguish automated, rendered, browser, device, and human classes;
- two bounded repairs fail;
- free-route availability, privacy terms, or output quality changes materially.

## Current first use

The first audit asks Ox Alpha to evaluate a materially different WCB-008L reopen strategy: external bounded window capture instead of the rejected Godot Movie Maker teardown path. It may recommend a narrow spike or keep the packet blocked. GPT-5.6 decides whether any implementation packet is justified.
