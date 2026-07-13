---
name: cobie-spark-orchestration
description: Orchestrate complex Cobie Nukem development phases with GPT-5.6 as architect, reviewer, integrator, and release owner while delegating bounded code, test, content, accessibility, performance, and review work to explicitly pinned GPT-5.3-Codex-Spark agents. Use for multi-subsystem Cobie work, Spark-credit acceleration, parallel audits, isolated worktree implementation batches, or any request to run the alpha.7 Spark development loop.
---

# Cobie Spark Orchestration

Keep the root GPT-5.6 task responsible for requirements, architecture, task partitioning, cross-system decisions, visual/gameplay judgment, integration, PRD truth, release identity, merge, deployment, and final claims.

## Establish the run

1. Read `AGENTS.md`, `docs/PHASE_ROADMAP_PRD.md`, the relevant design records, and the `cobie-godot-production` skill.
2. Confirm a clean baseline, create one `codex/` integration branch, and run `scripts/verify_spark_setup.py` from this skill.
3. Read [worker-contracts.md](references/worker-contracts.md) before drafting any task packet.
4. Read [batch-playbook.md](references/batch-playbook.md) before starting workers, worktrees, integration, or release work.
5. Verify the worker actually uses `gpt-5.3-codex-spark`. If in-app metadata cannot prove this, invoke `codex exec --model gpt-5.3-codex-spark` in an isolated worktree. Never count or silently substitute an unverified model.

## Delegate safely

- Use the six project profiles under `.codex/agents`: gameplay, tests, content, performance, UI/accessibility, and independent review.
- Give each worker one decision-complete packet, one ownership boundary, 1–8 files normally, explicit forbidden paths, focused tests, and a time limit.
- Run at most four read-only workers or two non-overlapping writers concurrently.
- Give every writer a `codex/spark/<work-id>` branch and isolated worktree. Require one cohesive commit and the structured result contract.
- Keep workers at nesting depth one. Workers never merge, deploy, stamp releases, edit final PRD status, operate privileged Godot/Blender bridges, or claim human/device evidence.

## Integrate with GPT-5.6

1. Inspect the complete worker diff and test output; do not trust the summary alone.
2. Check architecture ownership, Web compatibility, bounded lifetimes, asset provenance, engine warnings/errors/leaks, and acceptance evidence.
3. Return a failed review to the same worker once with exact corrections. Re-scope or fix centrally after a second failure.
4. Integrate only green cohesive commits. Run focused regression after every integration batch.
5. Ask a fresh `spark-code-reviewer` to inspect each coherent batch without the implementing worker's conclusions.
6. Update the master PRD and evidence ledger from the root task only.

## Handle credits and stops

- Continue decision-complete Spark packets until the planned backlog is complete or Spark reports a model/usage limit.
- On Spark exhaustion, stop new workers, finish review of completed work, record the remaining queue, and leave the branch green.
- Do not reroute queued mechanical work to another model silently.
- Stop integration for progression deadlocks, stuck input, nondeterministic reset, attributable Godot errors/leaks, unbounded temporary nodes, unmanifested assets, runtime development bridges, identity mismatch, or false human claims.

## Release boundary

The root GPT-5.6 task alone runs the full Godot release matrix, native/profile/browser evidence, stamps `BuildInfo`, merges source, publishes artifacts, deploys the website build, verifies the public PCK hash, and records human-only gates.
