# World-class vertical slice scorecard

Baseline: `0.5.0-rc1`, source revision `9c54c56`, captured 2026-07-12 before the
`codex/world-class-vertical-slice` implementation. Automated native/Web export
validation passed on the target Mac. Physical iPad and taste judgments are open.

| Domain | Baseline | 0.6 exit evidence |
| --- | --- | --- |
| Movement/camera | Functional; monolithic tuning | Profile-driven, deterministic FPS tests, reduced-motion path |
| Weapons | Three distinct weapons; partial feedback | Explicit lifecycle, one terminal event/shot, surface range evidence |
| Enemies | Five archetypes; billboard reactions | readable state vocabulary, pressure tokens, stable grounding/navigation |
| Encounters | Single-wave definitions | v2 waves, budgets, reset/restore soak |
| World | Continuous graybox route | authored landmarks, interactions, intentional secrets |
| Audio | Procedural prototype | licensed/original imported samples, bounded mix and Web unlock |
| HUD/accessibility | Mobile RC HUD and controls | scalable hierarchy, captions, contrast/motion/flash controls |
| Persistence | schema v2 | v3 objectives, encounters, secrets, migration corpus |
| Performance | smoke thresholds only | native/iPad frame-time, memory, load, voice and node evidence |
| Reliability | green release suite | seeded routes, fuzz/focus/checkpoint soak, zero Critical issues |

Baseline measurements that require an interactive renderer or physical device are
recorded as `NOT MEASURED`, never inferred from headless CI. The final scorecard
must link captures and profiler reports for opening, lab, tunnels, Walker, menus,
death, and victory.
