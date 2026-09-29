# WCB-008L M1R Capture Blocker

**Recorded:** 2026-08-03 PDT  
**Canonical source:** `21b406f4a6f5c809396c30f435c5e2b1c9cc4525`  
**Root owner:** GPT-5.6 SOL via OpenAI Codex  
**Bounded writer/repair model:** `gpt-5.3-codex-spark`

## Verdict

**BLOCKED / STOPPED.** Do not launch the canonical 90-second capture and do not advance WCB-008L to M2–M5 from this packet.

The original M1 capture-wrapper approach was discarded after unsafe unbounded raw output. M1R reduced the problem to an additive parent host, isolated launcher, strict verifier, and a 60-frame non-evidence probe. The parent-host design proved bounded execution and clean process/disk cleanup, but two rendered probes did not satisfy the frozen no-engine-leak gate.

No M1R implementation file was integrated into the canonical branch. The production scene, canonical run harness, gameplay, route, collision, navigation, art, combat, enemy, UI, audio, and release paths remain unchanged from `21b406f`.

## Root cause established

The canonical `wcb008l_rain_city_run.gd` emits `run_finished` but does not own standalone receipt emission or `SceneTree.quit()`. Its integration test connects the signal before adding the harness and explicitly quits; a direct Movie Maker scene launch has no equivalent owner. Godot Movie Maker therefore records until application exit and cannot infer the harness's custom completion signal.

The rejected M1R candidate added a parent capture host without editing the canonical harness. It connected before `add_child`, generated one structured receipt, provided a hardcoded short-probe mode that was explicitly ineligible for 90-second evidence, isolated user data, and enforced wall-time/frame/byte/free-space/stall watchdogs.

## Probe evidence

### Probe 1 — mechanically bounded, rejected after raw-log review

- Mode: `short_probe_non_evidence`.
- Source binding: `21b406f4a6f5c809396c30f435c5e2b1c9cc4525`.
- Output: 60 evidence frames plus one flush frame at 1280×720/30 FPS.
- Raw PNG bytes: `18,719,584` (about 18 MiB).
- Receipt count: exactly one.
- Receipt labels: `eligible_for_90s_evidence=false`, `canonical_duration_completed=false`, `host_reason=intentional_short_probe_cutoff`.
- Process cleanup: no WCB-008L or Godot descendant remained.
- Canonical verifier rejected relabeling with exit `1`.
- Rejection diagnostics: shader-cache creation error, one `ParticlesShaderGLES3` not freed, four ObjectDB instances leaked, two resources still in use, and one shader RID allocation leaked.

The first verifier failed to enforce raw-log cleanliness. Root rejected its apparent exit-0 result and added fail-closed engine-diagnostic validation.

### Probe 2 — failed closed after one bounded repair

- Same non-evidence mode and source binding.
- Godot generated 62 raw frames before clean process exit.
- Verifier rejected the run; no PNG was promoted.
- Retained output was only `run.log` and `verify.log` (about 8 KiB).
- Remaining diagnostics: shader-cache creation error, one `ParticlesShaderGLES3` not freed, and one shader RID allocation leaked.
- No WCB-008L or Godot descendant remained; disk stayed healthy.

Child teardown removed the prior ObjectDB/resource-leak diagnostics but did not produce a clean Movie Maker exit. Under the frozen two-failed-repair/repeated-engine-leak stop rule, no third repair is authorized.

## Mechanical checks completed on the rejected candidate

- `bash -n tools/capture_wcb008l_rain_city_run.sh` — PASS.
- Standard-library Python verifier tests — PASS, eight cases after root hardening.
- `res://tests/integration/rain_city_capture_host_test.gd` — PASS.
- `git diff --check` — PASS.
- Real 60-frame rendered probe — bounded and process-clean, but evidence gate FAIL due diagnostics above.

Passing focused tests do not override the rendered probe failure. No commit from the isolated candidate is accepted.

## Capacity checkpoint

As of 2026-08-03 15:26 PDT:

- Main GPT/Codex: 21% used / 79% remaining; no limit hit.
- GPT-5.3-Codex-Spark: 14% used / 86% remaining; no limit hit.

## Reopen conditions

M1R may be reopened only with a materially different, pre-approved evidence strategy that avoids repeating the same Movie Maker teardown path—for example a proven external bounded window capture or an upstream Godot fix—and still preserves exact 90.0-second/2,700-frame/5,400-tick source-bound evidence. Reopening requires a new packet and fresh baseline; it is not an implicit third repair.
