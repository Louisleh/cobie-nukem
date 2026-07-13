# Spark batch playbook

## Bootstrap

1. Run the static Spark setup validator.
2. Run one read-only audit pilot and one tiny isolated writer pilot.
3. Verify model identity from task metadata or explicit `codex exec --model gpt-5.3-codex-spark` output.
4. Review the pilot diff, result packet, sandbox behavior, and commit isolation before scaling.

## Isolated writer checkouts

- Integration branch: `codex/<phase>`.
- Worker branch: `codex/spark/<work-id>`.
- Checkout root: a temporary sibling directory outside the source checkout.
- Create isolated checkouts only from the recorded integration baseline.
- In-app workers may use standard Git worktrees when their sandbox can update the shared Git metadata.
- Explicit CLI Spark writers should run from a disposable parent sandbox containing a nested local full clone. The CLI protects the sandbox root's own `.git` even when it is otherwise writable; putting the assigned repository one level below the sandbox root keeps its metadata writable. Instruct the worker to operate only in that nested clone.
- A source edit without a commit object importable by the parent repository is incomplete; never accept an ephemeral or reported-only hash.
- Never assign overlapping writer ownership concurrently.
- A writer commits one cohesive change. The root imports the object from the isolated clone when needed, then reviews `git show --stat --check <commit>` and the full patch before cherry-picking.
- The root independently verifies the named commit exists, its parent equals the packet baseline, and it changes only owned paths.
- Fresh clones must complete a headless editor import scan before focused script tests. Do not mislabel missing `.godot` class caches as product parse failures; rerun after import and report any remaining exact parser error.
- Remove the temporary checkout and branch after integration or rejection.

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
- Preserve worker logs and externally verified completed commits.
- Finish root review/integration, record queued work, and leave all branches/worktrees clean.
- Never substitute another worker model without owner instruction.

## Release

Spark never owns the release. The GPT-5.6 root runs focused regressions, full `QA_EXPORTS=1 bash tools/release_validate.sh`, native profiling, packaged desktop/tablet browser checks, documentation, stamping, GitHub integration, deployment, public identity/hash verification, and rollback evidence.
