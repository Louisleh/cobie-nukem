# Spark batch playbook

## Bootstrap

1. Run the static Spark setup validator.
2. Run one read-only audit pilot and one tiny isolated writer pilot.
3. Verify model identity from task metadata or explicit `codex exec --model gpt-5.3-codex-spark` output.
4. Review the pilot diff, result packet, sandbox behavior, and commit isolation before scaling.

## Worktrees

- Integration branch: `codex/<phase>`.
- Worker branch: `codex/spark/<work-id>`.
- Worktree root: a temporary sibling directory outside the source checkout.
- Create worktrees only from the recorded integration baseline.
- Never assign overlapping writer ownership concurrently.
- A writer commits one cohesive change. The root reviews `git show --stat --check <commit>` and the full patch before cherry-picking.
- Remove the temporary worktree and branch after integration or rejection.

## Concurrency

- Maximum four read-only workers.
- Maximum two writers, only with disjoint ownership.
- Default worker runtime: 30 minutes.
- No nested worker delegation.
- Integrate dependency layers sequentially even when discovery ran in parallel.

## Review and retry

1. Re-run the worker's focused tests from the integration tree.
2. Check owned and forbidden paths mechanically.
3. Check engine output, warnings, leaks, orphans, temporary-node bounds, and Web-safe syntax.
4. Compare each acceptance item to direct evidence.
5. Give one precise correction pass to the same worker. Resolve centrally or defer after a second failure.
6. Run a fresh read-only reviewer after each coherent batch.

## Credit exhaustion

- Treat an explicit model-unavailable or usage-limit result as the stop signal; there is no assumed credit API.
- Stop creating workers immediately.
- Preserve worker logs and completed commits.
- Finish root review/integration, record queued work, and leave all branches/worktrees clean.
- Never substitute another worker model without owner instruction.

## Release

Spark never owns the release. The GPT-5.6 root runs focused regressions, full `QA_EXPORTS=1 bash tools/release_validate.sh`, native profiling, packaged desktop/tablet browser checks, documentation, stamping, GitHub integration, deployment, public identity/hash verification, and rollback evidence.
