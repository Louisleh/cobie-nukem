# OX-WCB-008L-M1S — Non-Movie-Maker frame-sequence spike

**Role:** bounded writer
**Purpose:** answer one empirical question only: can an additive in-engine viewport frame-sequence host avoid the rejected Godot Movie Maker teardown path while producing a source-bound, fail-closed, 60-frame **non-evidence** probe?

## Root review disposition

The Ox audit is directionally useful but overstates two facts:

1. `wcb008l_rain_city_run.gd` derives `render_frames` from physics ticks; it does not currently prove actual rendered frame count. The spike must count actual `RenderingServer.frame_post_draw` callbacks separately and never equate projected and actual counts without evidence.
2. Movie Maker is a plausible source of the teardown diagnostics, not a proven one. The spike exists to test whether the diagnostics disappear when `--write-movie` is absent.

## Exact owned paths

- `scenes/debug/wcb008l_frame_sequence_capture_host.tscn`
- `scripts/debug/wcb008l_frame_sequence_capture_host.gd`
- `scripts/debug/wcb008l_frame_sequence_capture_host.gd.uid`
- `tools/capture_wcb008l_frame_sequence_probe.sh`
- `tools/verify_wcb008l_frame_sequence_receipt.py`
- `tools/test_verify_wcb008l_frame_sequence_receipt.py`
- `tests/integration/rain_city_frame_sequence_capture_host_test.gd`
- `tests/integration/rain_city_frame_sequence_capture_host_test.gd.uid`

No other path may change. In particular, do not edit the canonical harness, production content, `project.godot`, release validators, manifests, docs, or existing tests.

## Required design

- The host instantiates the untouched canonical WCB-008L harness and connects any relevant signal before `add_child`.
- It runs without `--write-movie`.
- It counts actual `frame_post_draw` callbacks and saves exactly 60 viewport PNGs numbered `000000.png` through `000059.png` to an absolute output directory.
- The host must not write a post-start player transform, activate encounters directly, kill actors synthetically, or call progression methods.
- At 60 captured frames it emits exactly one JSON receipt and exits itself. Receipt fields must make relabeling impossible: `mode=short_probe_non_evidence`, `eligible_for_90s_evidence=false`, `canonical_duration_completed=false`, actual captured-frame count, current canonical projected render-frame and physics-tick telemetry, image dimensions, seed if available, source revision supplied by wrapper, script/scene SHA-256 values supplied or independently verified, first/last frame SHA-256, output bytes, and completion reason.
- The wrapper uses a temporary isolated HOME/user-data directory, absolute paths, free-space floor, wall-time watchdog, stall watchdog, frame/byte ceilings, trap cleanup, and a surviving-process assertion.
- The standard-library verifier rejects malformed JSON; wrong mode/eligibility labels; any count other than 60; missing/extra/duplicate/non-contiguous frames; wrong dimensions; hash mismatch; byte ceiling breach; source/script/scene hash mismatch; or raw logs containing shader-cache creation errors, ObjectDB/resource leaks, `ParticlesShaderGLES3` not freed, shader RID leaks, parser errors, or other attributable engine errors.

## Verification floor

1. Standard-library verifier unit tests with positive fixture and negatives for truncation, extra frame, relabeling, telemetry/count mismatch, tampered PNG/hash, source-hash drift, and leak/error log.
2. Focused Godot integration test proving signal ownership, exact 60 actual callbacks, one receipt, fail-closed absolute output path, and no canonical harness mutation.
3. Real 60-frame rendered probe at 1280×720 without Movie Maker. Preserve raw log and verifier result outside the repository.
4. `git diff --check` and exact owned-path check.

## Stop rules

- If the real probe emits any forbidden engine diagnostic, stop and return `blocked`; do not repair or reinterpret it.
- If exact actual-frame counting requires editing the canonical harness, stop.
- If the probe exceeds 120 seconds, 64 MiB, or leaves a Godot descendant, stop.
- Do not launch 2,700 frames, call the spike 90-second evidence, integrate, push, deploy, or make human-quality claims.
- Make one cohesive local commit only if all focused tests and the real probe pass. Otherwise leave the clone clean or commit nothing and report blocked.
