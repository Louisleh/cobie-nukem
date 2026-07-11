# Independent Phase 1–2 Hardening Audit Prompt

You are the independent senior gameplay engineer, Godot 4.7 specialist, QA lead, and production-pipeline reviewer for **Cobie Nukem**, an original retro FPS. Audit the repository rigorously and produce evidence-backed findings for a subsequent Codex implementation pass.

## Repository

Preferred live folder:

`/Users/louislehmann/Documents/Louis Lehmann Homepage/cobie-nukem`

If you received an archive, extract it and treat its root as the repository. Do not require network access. Do not modify production code, scenes, Resources, tests, documentation, Git history, or generated packages. You may create only the requested files beneath `handoffs/fable_phase12_audit/outputs/`.

## Mission

Bulletproof the current `0.3.0-dev` Phase 1–2 foundation before new levels are built. Find reproducible bugs, progression traps, hidden regressions, unsafe assumptions, inefficient runtime behavior, weak abstractions, data-authoring friction, misleading tests, missing validation, save/versioning risks, Web/macOS incompatibilities, and observability gaps.

This is an audit, not an implementation task. Do not broaden the scope into building Vancouver, Mount Hood, Moon, or Phase 3–6 features. Identify only current defects and high-leverage foundation risks that should be addressed before those phases.

## Required reading order

1. Read `AGENTS.md` completely.
2. Read `docs/PHASE_ROADMAP_PRD.md`, especially section 0 and the Phase 1–2 acceptance criteria.
3. Read `docs/PHASE_1_2_EVIDENCE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/CONTENT_AUTHORING.md`, `docs/KNOWN_ISSUES.md`, and `docs/PRD.md`.
4. Inspect the Phase 1–2 code/data/tests listed in `handoffs/fable_phase12_audit/README.md`.
5. Inspect adjacent player, combat, AI, save, UI, input, and level code wherever contracts cross boundaries.

Do not assume documentation or existing tests are correct. Compare every claim with source and runtime evidence.

## Mandatory audit tracks

### A. Build and regression truth

- Record Git revision, working-tree status, Godot version, OS, and exact commands.
- Run the parser/import gate and `QA_EXPORTS=0 bash tools/release_validate.sh`.
- If the environment supports it, run `QA_EXPORTS=1 bash tools/release_validate.sh` and package verification.
- Report every warning, leak, flaky result, long-running step, generated-file inconsistency, and misleading pass condition.
- Confirm tests fail when their protected invariant is deliberately violated conceptually; flag assertion-light tests that mostly inspect strings or structure.

### B. Full gameplay and progression

Play or otherwise exercise the packaged Web build and, if possible, native Mac build from title to victory without debug shortcuts. Test:

- New Game → mission selection → Salmon Creek.
- Opening grace and encounter activation by time and first shot.
- Every enemy spawn across all five zones.
- Weapon switching, magazines, reserve ammunition, manual/automatic reload, dry fire, death during reload, and switching during reload.
- Every critical pickup, Fetch Collar, door, switch, checkpoint, Continue, restart, death, out-of-bounds death, secret wall, optional secrets, Walker phases, Golden Ball, victory, and report copy.
- Options/pause/focus/pointer-lock recovery at several progression states.
- Rapid movement, low/unstable frame-rate behavior, repeated interactions, double signals, collision edges, and checkpoint reload.
- Whether difficulty identity or runtime scaling creates inconsistent HP, damage, cooldown, projectile damage, boss phase, HUD, or save behavior.

For every gameplay defect, provide exact reproduction steps, expected result, actual result, frequency, platform, build ID, screenshots/logs, and likely owning code—not merely a suggestion.

### C. Phase 1 systems review

Audit `ObjectiveDefinition`, `ObjectiveTracker`, `EncounterDefinition`, `EncounterRunner`, `DifficultyProfile`, enemy archetypes, and Salmon Creek integration for:

- Event loss, duplicate activation, repeated signals, reentrancy, ordering, closure capture, queued deletion, null targets, invalid Callables, partial spawns, dead actors, activation races, and scene-tree lifetime errors.
- Incorrect prerequisite semantics, progress recorded before unlock, optional-objective completion, empty-definition behavior, snapshot/restore type drift, duplicate IDs, cyclic graphs, and save compatibility.
- Encounter completion correctness for each policy, empty/failed spawn handling, boss-specific signals, actors without `died`, opening-disabled enemies, target assignment, and retry/checkpoint semantics.
- Difficulty scaling applied exactly once and consistently to hitscan, melee, projectile, splash, boss, HUD maximums, attack cadence, detection, speed, aim assist, pickups, and saved run identity.
- Archetype behavior that causes oscillation, wall sticking, retreat through geometry, perpetual strafing, unfair range control, NaNs/zero directions, or unnecessary per-frame work.
- Stale duplicated sources of truth, especially any legacy wave/objective tables left beside manifests.

### D. Phase 2 pipeline review

Audit content manifests, typed Godot Resource serialization, templates, validator, smoke discovery, and authoring guide for:

- Checks that can pass despite parser/resource errors.
- Duplicate zones, unsupported dictionary keys, wrong types, non-finite coordinates, path traversal, missing scripts, wrong scene root types, incompatible enemy contracts, invalid completion policy, unreachable prerequisites, required-objective deadlocks, and circular dependencies.
- Resource schema evolution/version handling.
- Whether adding Mission 2 truly avoids shared-runtime edits.
- Whether errors name the exact manifest, definition, entry, and repair action.
- Determinism, CI portability, Web export safety, and performance as content grows.
- Gaps between documented authoring rules and actual machine validation.

### E. Performance and efficiency

- Profile or reason carefully about `_physics_process`, target acquisition, navigation/movement, health-bar construction, particles, procedural geometry, Resource loading, signal counts, and scene instantiation.
- Check for leaks, orphan nodes, repeated loads, unbounded dictionaries/arrays, duplicate connections, timers surviving scene changes, expensive per-frame allocations, and scaling problems at 25, 50, and 100 enemies.
- Distinguish measured evidence from inference. Give a practical measurement plan where tooling is unavailable.

### F. Architecture, maintainability, and future-level readiness

- Trace ownership and dependency direction against `docs/ARCHITECTURE.md` and `AGENTS.md`.
- Identify abstractions that are premature, incomplete, overly coupled to Salmon Creek, or falsely reusable.
- Identify the smallest changes required before Mission 2 can be safely authored.
- Separate blockers from nice-to-have refactors. Do not recommend rewrites without quantified benefit and a migration strategy.

### G. Security, privacy, IP, and distribution sanity

- Check for unexpected network calls, unsafe filesystem assumptions, personal information, absolute paths in runtime data, credentials, unmanifested assets, or misleading hardware/platform claims.
- Verify real-place/business notes remain documentation only and no unapproved branded assets have been added.
- Treat the existing asset/IP scan as heuristic, not legal clearance.

## Severity and confidence

Use these severities:

- **P0 Blocker:** cannot build, boot, progress, save safely, or complete the level.
- **P1 Critical:** frequent crash/deadlock/data loss or major system contract failure.
- **P2 Major:** reproducible gameplay, balance, performance, pipeline, or accessibility defect that should be fixed before Phase 3.
- **P3 Minor:** localized defect or maintainability issue with a reasonable workaround.
- **P4 Suggestion:** evidence-backed improvement that is not required before Phase 3.

Assign confidence: **Confirmed**, **High**, **Medium**, or **Hypothesis**. Never present untested speculation as confirmed.

## Required deliverables

Create `handoffs/fable_phase12_audit/outputs/fable_phase12_audit.md` with:

1. Executive verdict: ready/not ready for Phase 3 and why.
2. Environment, revision, commands, and test results.
3. Coverage matrix showing Run / Pass / Fail / Not Run for every mandatory track.
4. Prioritized issue table: ID, severity, confidence, subsystem, concise title, evidence.
5. One full section per issue with reproduction, expected/actual, evidence, suspected root cause with exact files/functions, recommended minimal fix, regression-test proposal, and risk.
6. Architecture and content-authoring assessment.
7. Performance findings separated into measured and inferred.
8. Missing-test inventory.
9. “Fix before Phase 3” ordered backlog with dependencies and rough S/M/L effort—not time estimates.
10. Deferred suggestions that should not block Phase 3.
11. Explicit limitations and everything not run.

Also create `handoffs/fable_phase12_audit/outputs/issue_inventory.csv` with columns:

`id,severity,confidence,subsystem,title,reproducible,platform,owner_file,recommended_test,blocks_phase3`

Store screenshots under `handoffs/fable_phase12_audit/outputs/screenshots/` and link them relatively from the report. Do not include secrets, personal browser data, or unrelated desktop content.

## Quality bar

- Prefer ten deeply evidenced findings over fifty generic observations.
- Use exact file paths, function names, resource IDs, commands, and runtime states.
- Clearly distinguish current bugs from intentionally deferred Phase 3–6 work.
- Re-run any flaky failure at least three times before assigning P0–P2.
- End with a concise handoff addressed to Codex: what to fix first, how to verify it, and what remains uncertain.
