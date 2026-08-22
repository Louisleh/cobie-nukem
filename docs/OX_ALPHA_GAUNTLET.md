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
2. **Ox Alpha audit/critic:** inspects a clean isolated clone and returns the required delimiter-bound strict JSON receipt without writing.
3. **Ox Alpha writer:** optional; receives exact non-overlapping paths, works in a full clone, makes one cohesive local commit, and cannot push or integrate.
4. **GPT-5.6 integrator:** independently reviews the patch and raw outputs, reruns focused and root tests in canonical source, accepts or rejects, commits, pushes, and updates the durable ledger.

No worker self-report is evidence. The runner fails closed on a dirty audit clone, missing receipt fields, out-of-scope writer paths, uncommitted writer changes, missing writer commit, nonzero Hermes exit, or dirty canonical source at launch. It retries only transient HTTP 429/5xx or timeout failures, preserving every attempt log in the evidence directory.

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

Writer clones with changes are retained and identified in `receipt.json`; clean failed clones are removed automatically unless `--keep-clone` is set. Never cherry-pick until GPT-5.6 verifies baseline parent, changed-path scope, full diff, tests, and evidence.

## Stop rules

Stop rather than widen scope when:

- canonical source is dirty;
- the packet conflicts with `AGENTS.md`, PRD, implementation plan, or buildout log;
- WCB-007 frozen paths, route/collision/navigation, progression, damage/balance, breadth, BETA status, deployment, or release identity would change;
- the worker reads or changes outside its clone;
- evidence cannot distinguish automated, rendered, browser, device, and human classes;
- two bounded repairs fail;
- free-route availability, privacy terms, or output quality changes materially.

## Ambitious free-development operating mode

Significant Ox work uses one **logical serialized writer lane with fresh model context per verified milestone**, not one enormous prompt. GPT-5.6 freezes the complete authority contract, then decomposes it into dependency-ordered packets that each fit a bounded context and exact path set:

1. narrow read-only audit with a required verdict;
2. dependency-free implementation and focused tests;
3. runtime/engine integration only after root accepts the prior checkpoint;
4. wrapper, isolation, provenance, and negative fixtures;
5. real bounded evidence generation;
6. fresh Ox critic followed by GPT-5.6 adjudication and canonical gates.

Each milestone gets a new work ID/output directory, one scoped commit, and an independent root review. The next context receives the frozen parent contract plus only the current packet and prior verified checkpoint. A timeout without a valid receipt is no progress. Do not resume an exhausted model context, widen ownership, run parallel writers over coupled paths, or substitute a paid/weaker model.

Use the free lane aggressively for useful public-repository audits, tests, tooling, additive gameplay/presentation packets, accessibility/performance reviews, and fresh criticism. Keep architecture, integration, release, protected configuration, cross-project context, human taste/device gates, and final claims with GPT-5.6.

## Current first use

The first audit evaluated a materially different WCB-008L reopen strategy after the rejected Godot Movie Maker teardown path. Its initial all-in-one writer packet timed out twice. The replacement serialized lane is frozen as:

- `wcb008l_m1a_receipt_verifier.md` — dependency-free Python verifier/tests;
- `wcb008l_m1b_capture_host.md` — additive Godot host/test after M1A integration;
- a later root-authored wrapper/probe packet only after both checkpoints pass.

This decomposition is a reliability repair, not permission to bypass WCB-008K/WCB-008L dependency truth, launch the 90-second run, or weaken the original M1S stop rules.

### M1A pilot result

Ox Alpha timed out on its first attempt, then completed the two owned files and committed them on the fresh second attempt. The gauntlet correctly rejected the handoff because the final answer omitted the required `WORKER_REPORT_JSON` envelope; root therefore treated it as an untrusted candidate rather than an accepted worker receipt.

GPT-5.6 independently inspected and salvaged the exact two-path commit, added symlink rejection plus a pre-read aggregate-byte ceiling, and reran the focused and canonical gates. Root evidence at integration: 40 focused verifier tests pass, Python compilation passes, `git diff --check` passes, world-class docs pass, Godot 4.7.1 import passes, and the core contract suite reports `PASS`.

M1A is accepted as a root-verified checkpoint. M1B remains a separate fresh-context packet; no capture run or WCB-008L evidence claim is authorized by M1A alone.
