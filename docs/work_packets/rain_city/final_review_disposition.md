# Rain City final integration review disposition

Date: 2026-07-16
Baseline: `e385aee`
Reviewed head before fixes: `08c7753`
Fix revisions: `0d9d081`, `1dc0747`

## Review execution

- The explicitly pinned `gpt-5.3-codex-spark` reviewer was verified from its runtime metadata and inspected the complete integration diff in read-only mode. Its very large review process did not reach a structured terminal report and was stopped rather than represented as a pass.
- Three fresh, focused independent reviews then covered save/campaign state, convoy lifecycle, and route/enemy lifecycle. Their concrete findings were reproduced locally before fixes were accepted.
- Root reviewed every resulting diff and reran focused Godot tests. Full release validation is recorded in the release evidence rather than inferred from worker output.

## Accepted and resolved findings

| Severity | Finding | Disposition |
| --- | --- | --- |
| Major | Current-revision checkpoints with no position could restore at world origin; stale unknown beta checkpoints could retain obsolete coordinates. | Reject unknown unusable checkpoints and remap known anchors through `RainCityCheckpointState`; permanent unit coverage added. |
| Major | Alpha.10 Vancouver completers and explicitly unlocked saves could be relocked by the new Salmon Creek prerequisite. | `CAMPAIGN` policy now honors self-completion and explicit unlock before checking the normal prerequisite; v4 migration and availability coverage added. |
| Major | Convoy movement resumed when its wave ended even if the required module remained intact. | Schema-v2 phases resume only when both gates finalize, in either order; the 100-cycle soak asserts the stopped state between gates. |
| Major | A post-victory retry or Continue could resurrect the convoy instead of restoring the defeated wreck. | Added deterministic completed-state restoration and mission-host coverage for the clear checkpoint and retry path. |
| Major | Convoy boss health changed only when whole modules broke. | Module health now feeds the shared 1,000-point budget continuously. |
| Major | Municipal Recall Override emitted a convoy stagger event without affecting the module. | Recall stagger now applies bounded module-health stagger damage while leaving primary projectile damage unchanged. |
| Major | Ground enemies knocked through pier gaps could hover outside navigation and deadlock a wave. | Enemies recover once to a confirmed safe grounded position, then resolve deterministically if the recovery point is invalid. |
| Moderate | Compliance Gull marked and dealt stationary range damage rather than performing an interruptible dive. | Replaced with telegraph, locked physical dive, hit/miss, interruption, and readable recovery states. |
| Moderate | Convoy phase synchronization could duplicate captions or play a movement cue after defeat. | Presentation deduplicates generation/phase announcements and ignores the terminal phase index. |

## Deliberately open human gates

- Physical iPad Safari twin-stick comfort, audio, focus switching, and thermals.
- Target-Mac, desktop Chrome, and desktop Safari complete playthroughs.
- Fifteen-to-twenty-two-minute route timing, boss fairness, difficulty feel, art cohesion, mix, humor, motion comfort, and photosensitivity.

These remain release-candidate gates. They are not automated passes and the public Rain City card retains its RC/BETA treatment.
