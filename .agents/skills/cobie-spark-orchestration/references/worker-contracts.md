# Spark worker contracts

## Task packet

Every worker receives all fields below. Use YAML or an equivalent clearly labelled block.

```yaml
work_id:
role:
goal:
baseline_revision:
dependencies:
owned_paths:
read_only_context:
forbidden_paths:
behavioral_contract:
acceptance_criteria:
focused_tests:
evidence_required:
out_of_scope:
time_limit_minutes:
```

The packet must be decision-complete. A worker stops rather than inventing product, architecture, legal, release, visual-quality, difficulty, or human-evidence decisions.

## Result packet

Every worker returns:

```yaml
work_id:
status: complete | blocked | failed
model:
baseline_revision:
root_cause_or_design_summary:
changed_files:
tests_run:
test_results:
acceptance_results:
known_risks:
questions_for_orchestrator:
commit_hash:
```

`commit_hash` is required for writers and `null` for read-only agents. Raw logs remain available in the worker thread or worktree but do not replace the summary.

## Role routing

| Profile | Owns | Must not own |
| --- | --- | --- |
| `spark-gameplay-worker` | One bounded gameplay mechanic or defect plus focused tests | Cross-system architecture, core services, release metadata, unrelated balance |
| `spark-test-engineer` | Unit/integration/route/fuzz/soak coverage and fixtures | Production edits unless named explicitly |
| `spark-content-author` | Typed Resources, manifests, non-public grayboxes, content fixtures, provenance | Public unlocks, legal clearance, mission-specific shared-system forks |
| `spark-performance-auditor` | Read-only hot-path, lifetime, allocation, and profiler analysis | Speculative implementation or unmeasured claims |
| `spark-ui-accessibility-worker` | HUD, captions, options, responsive/touch contracts and tests | Subjective comfort/photosensitivity claims or desktop regressions |
| `spark-code-reviewer` | Independent diff review with severity and file/line evidence | Editing, merging, or relying on implementer conclusions |

## Universal forbidden paths

Unless the root packet explicitly narrows an exception, Spark writers may not edit:

- `scripts/core/build_info.gd`
- `docs/PHASE_ROADMAP_PRD.md`
- `.github/workflows/`
- `export_presets.cfg`
- `project.godot`
- the website repository

No worker may run a merge, push, release, deployment, or privileged Godot/Blender MCP bridge.
