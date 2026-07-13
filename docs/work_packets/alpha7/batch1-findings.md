# Alpha.7 Batch 1 stabilization findings

Baseline: `cad60c3`  
Execution: four explicit `gpt-5.3-codex-spark` read-only CLI workers; root review performed against source.

The CLI event stream records the requested Spark model. One worker's prose incorrectly self-identified as GPT-5.6; that self-report is rejected in favor of the explicit invocation and model event. Future result review treats worker-authored model labels as untrusted metadata.

## Accepted implementation queue

| Priority | Finding | Root disposition |
| --- | --- | --- |
| Major | `BOSS_DEFEATED` is authored by `salmon_walker.tres` but not consumed by `EncounterRunner`. | Accepted. Add an explicit completion-target contract, validation, runtime behavior, cleanup, and regression coverage. |
| Major phase work | Walker can jump across multiple authored health thresholds in one damage event, skipping phase presentation/recovery semantics. | Accepted into the Walker production packet. Preserve ordered, deterministic phase progression rather than emitting several simultaneous phase beats. |
| Major performance work | Interaction and auto-aim registry queries materialize arrays in hot paths. | Accepted for measured optimization. Replace repeated materialization without reintroducing scene scans; retain invalid-node pruning and add contract coverage. |
| Medium | Checkpoint retry has no explicit gameplay-audio flush. | Accepted as safe adjacent stabilization. Stop active pooled gameplay voices while retaining registered pools and long-lived music policy. |
| Medium | Continue restores mission state but leaves `run_stats.checkpoint_id` at `start`. | Accepted as correctness/observability cleanup with a focused restore assertion. |

## Deferred or rejected as automatic defects

- Per-impact nodes and materials are bounded by `QualityManager`, covered by the temporary-effect soak, and self-free through tweens/timers. Pooling remains a profiler-led optimization candidate, not a confirmed leak.
- Enemy global lookup is an exceptional target-acquisition recovery path, not normal per-frame ownership. Keep it visible for future metrics rather than removing the defensive fallback without evidence.
- Per-enemy death and telegraph timers are node-owned and bounded. Reuse may reduce churn, but this is not a correctness failure.
- Walker summon group lookup occurs only on checkpoint reset and is bounded by authored summon behavior. A registry would add complexity without measured benefit at current scale.
- Human mix, boss fairness, touch comfort, thermals, and photosensitivity remain human-only gates.

## Audit summary

No Blocker or Critical issue was reproduced. The save/progression contracts, schema-v3 sanitization/migrations, imported-audio voice caps, encounter reset cleanup, and current route soak were otherwise coherent. The complete implementation and release matrices remain mandatory after the accepted queue is integrated.
