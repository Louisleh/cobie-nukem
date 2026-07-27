# WCB-008K — Continuous Opening-Run Continuation Result

**Closeout date:** 2026-07-27 PDT
**Source commit:** `74a3032fe25fd535d59ab79f17ce2a52f7f72643`
**Root owner/model:** GPT-5.6-sol/high
**Spark writer model:** `gpt-5.3-codex-spark`
**Recommendation:** **REJECT CANDIDATE / RETAIN PACKET FOR NEXT ITERATION**

## Root verdict

The continuous-opening candidate is rejected. Nothing from the Spark writer is
accepted or integrated, and WCB-008K remains open.

The current accepted WCB-008K v1 remains only the staged 7.3-second candidate.
This continuation did not replace, extend, or strengthen that evidence.

## Independent audit verdicts

1. **Capture audit — REVISE.** The existing infrastructure makes the requested
   deterministic native capture feasible and presents no hard technical block,
   but the legacy native path does not satisfy the 900-frame continuous-run,
   telemetry, hash, receipt, diagnostic-classification, or duration-semantics
   contract.
2. **Input/encounter audit — FEASIBLE.** The production seam can preserve the
   real spawn, timer-driven three-actor/one-attacker opening, and named-action
   movement/look/use flow, provided standard/non-Off-Leash mode, epoch
   alignment, run-mode behavior, no early fire, contact, and continuous route
   arrival are observed and fail-closed.
3. **Evidence-safety audit — BLOCKED.** The legacy staged seam contains direct
   player translation, interpolation resets, direct zone/encounter control, and
   synthetic encounter closure. It cannot support a continuous-opening claim.
   A separate source-bound, receipt-verified seam is mandatory.
4. **Test audit — FEASIBLE but REVISE, with definitive ObjectDB/resource/RID
   delta coverage partially BLOCKED.** Dedicated timer-boundary, input-only
   route, actor-cap, trace-integrity, teardown, and receipt-negative tests are
   required. The dedicated capture pipeline must supply engine diagnostics
   that are not reliably enumerable from GDScript alone.

## Selected architecture

The selected architecture remains the additive, isolated architecture specified
by the frozen brief:

- a non-rendering debug scene and harness that dynamically instantiate the
  unchanged production Salmon Creek Level 1;
- connection to `level_ready` before the level enters the tree, with that single
  emission defining evidence `t = 0`, physics tick 0, and accepted frame 0;
- read-only observation of standard/non-Off-Leash state, the production
  `OpeningGraceTimer`, the authored three-actor roster, and the one-attacker
  pressure cap;
- player movement, look, run, and interaction driven only through whitelisted
  named `InputMap` actions, with no post-start transform write, direct
  activation, staged zone entry, enemy manipulation, interpolation reset, or
  early weapon input;
- an isolated wrapper and standard-library verifier that run a matched control,
  two fresh full-duration dry semantic runs, and then one fresh 900-frame
  1280×720 Compatibility capture at 30 FPS and 60 TPS;
- a fail-closed receipt binding source and script identities, continuous
  telemetry, frame/tick counts, route/contact/encounter facts, diagnostics,
  keyframe hashes, and cross-run semantic equality; and
- a standalone focused integration test plus verifier self-tests and negative
  receipt fixtures.

This architecture was selected because it preserves production gameplay
ownership and excludes the legacy staged seam entirely.

## Spark writer outcome

The writer session used `gpt-5.3-codex-spark` on branch
`codex/spark/wcb008k-continuous-opening`.

The exact terminal outcome was:

- one untracked 1,195-line
  `scripts/debug/wcb008k_continuous_opening_capture.gd`;
- that sole harness did not parse;
- the other four owned primary files were absent:
  `scenes/debug/wcb008k_continuous_opening_capture.tscn`,
  `tools/capture_wcb008k_continuous_opening.sh`,
  `tools/verify_wcb008k_continuous_opening.py`, and
  `tests/integration/salmon_creek_continuous_opening_capture_test.gd`;
- no writer commit was created; and
- the one authorized same-writer repair could not start because the writer
  session had exhausted its context window. The repair terminal reported
  `tokens used 0`.

The independently reported parse and warning-as-error failure classes were:

1. invalid `PackedStringArray.duplicate(true)` usage, which must be
   `duplicate()`;
2. inconsistent/undeclared spawn-registry identity: `_spawn_registry` was used
   while `_mission_spawn` was the declared variable;
3. undeclared `_pressure`;
4. unavailable `ObjectDB` usage; and
5. Variant type inference treated as an error under warning-as-error policy.

These are only the known parser/static failures. Because the harness did not
parse and the remaining four files did not exist, no runtime or evidence claim
can be inferred.

## Evidence and integration accounting

- **Integration:** none.
- **Accepted writer commit:** none.
- **Godot parse probe:** ran once against the incomplete harness and failed with
  the five parser/warning-as-error classes listed above.
- **Successful editor/import/integration/full test run:** none for this candidate.
- **Dry semantic runs:** none.
- **900-frame evidence run:** none.
- **Receipt:** none.
- **Keyframes or hashes:** none.
- **Performance evidence:** none.
- **Fresh independent critic:** none.
- **Production-path changes:** none.
- **Main-checkout changes:** none.

No production paths or main checkout were touched. The incomplete writer draft
remains isolated and rejected in the writer sandbox.

## Durable lessons

The packet was too large for one Spark writer context. It combined a substantial
typed-GDScript runtime harness, a scene, orchestration shell, a fail-closed
standard-library verifier and self-test matrix, a focused Godot integration
test, multiple full-duration runs, evidence generation, and a cohesive commit.
The writer exhausted context before producing a parsable first component.

The next attempt must split implementation into bounded, fresh-context
milestones while preserving one writer identity and non-overlapping ownership,
or use root-owned mechanical integration. A safe milestone sequence is:

1. parsable scene/harness with focused epoch, timer, input, and teardown tests;
2. verifier plus exhaustive negative self-tests;
3. wrapper plus isolation, identity, frame, and diagnostic gates;
4. focused integration and full automated regression;
5. matched control, two dry semantic runs, capture, receipt verification, and
   fresh critic review.

Each milestone must end with a small reviewable diff, exact terminal output, and
a fresh context before the next milestone. No milestone may weaken the frozen
acceptance gates or reuse the legacy staged capture seam.

## Remaining gates

All human, browser, device, and feel gates remain open, including human movement
and combat feel, pacing, fairness, humor, audio mix, accessibility comfort,
photosensitivity, packaged-browser behavior, target-Mac playthrough, controller,
physical iPad, flight-stick, and family-comprehension review.

**Final recommendation:** **REJECT CANDIDATE / RETAIN PACKET FOR NEXT ITERATION**
