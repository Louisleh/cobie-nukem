# Saturday Level 1 opening candidate — 2026-09-19

**Scope:** Salmon Creek / **No Dogs Allowed**, the actual first campaign card and `scenes/levels/episode_1_level_1.tscn`. Rain City remains the definitive WCB slice; its frozen production packets are not advanced here.

## What changed

A deliberately small lighting-only readability candidate: fog density `0.012 → 0.0045`, aerial perspective `0.7 → 0.35`, ambient energy `0.55 → 0.48`, existing cool directional key `1.1 → 1.25`. The runtime keeps exactly the same two lighting nodes, directions, shadows, environment assets, route, collision, navigation, weapons, enemies, encounters, and progression. Every byte outside the lighting function in the production file is unchanged.

This is **not a polished-Level-1 completion claim**. Matched image inspection supports only a modest visibility change, not a major art improvement. Large floating enemy HP labels still dominate their silhouettes; the field/shed/fence grouping remains visually crowded. Lighting is level-wide, so interior comfort still needs human review.

## Review the actual result

- [Desktop before/after](comparison-desktop.jpg)
- [Native 4:3 before/after](comparison-tablet.jpg)
- [Before desktop motion](before-desktop/sampled-motion.mp4)
- [After desktop motion](after-desktop/sampled-motion.mp4)
- [After 4:3 motion](after-tablet/sampled-motion.mp4)
- [Measured frames, positions, draw calls and file hashes](motion-summary.json)

Each clip is **five seconds of sampled automated native motion**, encoded from 50 real images at 10 samples/sec while the simulation ran at 30 process FPS / 60 physics TPS. Runtime receipts measure 150 process frames and 300 physics ticks. The actor advances through ordinary named movement, from z=10 to approximately z=-1.935, without teleporting or directly activating an encounter. This is not a human playthrough, a continuous 30/90-second acceptance run, or physical tablet evidence. There is no audio track. The attempted named fire input produced no visible ammo expenditure; these clips prove moving presentation, **not successful combat**.

Before and after have identical sampled draw-call ranges: desktop 555–572, native 4:3 551–571. These are capture observations, not an uncapped frame-time benchmark. The original scene already has substantial draw-call density.

The four accepted folders contain source-file SHA-256 maps, runtime receipts, engine output and two exact PNG keyframes. Early probes with overbroad save-isolation wording were superseded and are not acceptance artifacts. Accepted user-data and actual SaveManager roots were explicitly redirected and verified; this is not an OS filesystem sandbox.

## Safety and review

`tools/evidence/salmon_opening_probe.py` is capped at five simulated seconds. It uses no Movie Maker or privileged bridge. Independent polling watchdogs bound wall time (120 seconds), frame stall (30 seconds), sampled frame count, scratch bytes (64 MiB), and free disk (6 GiB on scratch/output volumes), with post-exit rechecks and owned process-group TERM/KILL cleanup. Both wrapper and harness hashes are bound. The byte bound is a polling watchdog, not an OS write quota. The known exact one-shader/one-RID Compatibility-renderer teardown pair is retained in logs and allowed once each; other engine/script/leak diagnostics fail closed.

A separate Astra reviewer approved the lighting-only scope but rejected the first wrapper's isolation, timing and cleanup claims. Parent fixed the actual SaveManager override, both-script identity, measured counters, post-exit budgets and process-group handling, then reran the real captures and five focused Python tests. No worker implementation was integrated. Explicit Spark launch returned HTTP 400: model unsupported for this ChatGPT account; further attempts stopped.

## Validation and playable artifacts

Final disposition: **review candidate only; full release gate remains BLOCKED**. `QA_EXPORTS=1 bash tools/release_validate.sh` reached 57 script invocations, including the five-mission gauntlet and 100-route vertical-slice soak, but stopped because `tests/smoke/smoke_test_runner.gd` emitted **2 ObjectDB instances leaked at exit**, despite its PASS sentinel. This is a failure, not a green matrix; the later headless performance/content/export stages were not reached by that wrapper. Raw failed attempts are retained in [logs/](logs/).

**Native performance gate: FAIL**, not a claimed regression/improvement relative to baseline. The bounded 1920×1080 `tests/smoke/zone_performance_profile.gd` run exited 1; opening-field average `19.576 ms`, p95 `57.979 ms`, p99 `71.375 ms` exceeds the 33 ms p95 / 33.3 ms p99 budget. Other sampled zones also exceeded their budgets. The first attempt had a shader-cache-directory setup error and is not accepted performance evidence; the repeated run precreated the isolated macOS user directory and preserved consistent HOME/CFFIXED routing, eliminating that setup error while still failing the performance thresholds. [Final raw profile](logs/native-profile-final.log). No matched baseline frame-time run was collected, so causation is unassigned.

Final canonical editor import, core contracts, content validation (five manifests), architecture, asset/IP heuristic, documentation validator and diff checks pass independently. These passes do not override either the smoke leak or the rendered performance failure.

Fresh independent Web and unsigned macOS exports both exited 0, with no engine/script error lines. Both PCKs exclude the new probe, existing debug captures and privileged bridge markers; macOS ZIP integrity passes. [packages.json](packages.json) binds exact bytes/hashes. Web PCK SHA-256: `62c200cdbbfcdbe007112604fd2ae3a18fb2c9dd80dfb04922c08e8e264299d8`.

**Play locally on the Mac mini:** double-click `builds/Play_Saturday_Candidate.command`, then open <http://127.0.0.1:8060/> → **PLAY // DOGHOUSE → CHOOSE MISSION → NO DOGS ALLOWED → START MISSION**. The fresh build is `builds/web/`; the unsigned native artifact is `builds/macos/CobieNukem.zip`. No server is intentionally left running after the sprint. These are unstamped development artifacts; the in-game historical version/revision is not this candidate's source identity.

Packaged Web was exercised in a fresh isolated headless Chrome context: boot → main menu → Doghouse → first-mission selector → actual level entry → keyboard movement → pause → resize to 1024×768. Four normal console messages and **zero captured console warnings/errors/page errors**; [browser screenshots and console](browser/). Pixel inspection confirms a real field/weapon/HUD, not merely a menu. The resized browser view is **letterboxed**, not proof of a true native 4:3 layout. Touch gestures, Chrome performance tracing, Safari, death/retry/completion and physical devices were **not tested**. Hermes' real-profile browser helper was blocked by Chrome's profile lock; no user browser was quit or global configuration changed. The fallback used a new isolated Playwright context with the installed Chrome binary, then closed it.

Initial full release attempts exposed two test-lifecycle issues, retained in raw logs:

1. `world_interaction_test.gd`: the 0.5-second timer could observe an effect before the final tween callback/deferred free; two process-frame flushes were added without removing the exact baseline-count assertion or changing the production lifetime. Three successive focused reruns pass.
2. `umbrella_shield_content_test.gd`: the production death timer could free the enemy before test teardown; a validity guard avoids freeing it twice. All damage/death/state assertions remain intact; focused rerun passes.

A fresh narrow Astra re-review approved the corrected wrapper and both test teardown changes by static inspection, with no remaining high/medium findings; it did not claim to have run tests or inspect rendered artifacts. Parent owns the real reruns and evidence above.

### Open gates and next session

0. Resolve the two-object smoke-test leak and rerun the complete release matrix before integrating this branch into the program branch.

1. Scope a presentation-only enemy-health-label/silhouette pass without changing damage, target acquisition or enemy scale metadata.
2. Extend the *new non-Movie-Maker strategy* only through another bounded packet to truthful 30-second movement/combat evidence; the current five-second probe is not that acceptance.
3. Review the actual target-Mac/browser opening with a human, then assess authored turf/landmark/material work. Restore the 20 GiB high-workload reserve before heavy asset renders.
4. Physical iPhone/iPad/joystick, Safari, signing, thermal/frame pacing, art taste, combat feel, pacing, mix, humor and photosensitivity remain open. No BETA removal, public deployment, App Store submission or release stamp.

No continuation was scheduled: the enclosing existing-job instruction forbids creating/updating schedules. This run checkpoints a bounded candidate instead of inventing an unattended multi-hour continuation.
