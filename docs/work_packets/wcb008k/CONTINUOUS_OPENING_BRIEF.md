# WCB-008K — Continuous Opening-Run Evidence Continuation

**Frozen:** 2026-07-27 PDT
**Source commit:** `74a3032fe25fd535d59ab79f17ce2a52f7f72643`
**Evidence class:** deterministic native automated/bot-driven run; not human playtesting
**Root owner:** GPT-5.6-sol/high

## Acceptance condition

One reproducible 1280×720 native Compatibility-renderer capture contains exactly
900 rendered frames at 30 FPS and 1,800 physics ticks at 60 TPS (±1 tick). It
starts at Salmon Creek's real Level 1 spawn in asserted standard/non-Off-Leash
mode, defines evidence `t = 0` as the observed `level_ready` emission, observes
the subsequent real opening-timer start within one physics tick, drives the real
`CobiePlayer` through named `InputMap` actions, preserves the production
12.0-second opening grace and existing three-actor/one-attacker contracts, and
continuously reaches the equipment-shed approach without any post-start
translation, encounter activation call, staged zone entry, or production
gameplay change.

## Exact ownership

The continuation writer may add only:

- `scripts/debug/wcb008k_continuous_opening_capture.gd`
- `scenes/debug/wcb008k_continuous_opening_capture.tscn`
- `tools/capture_wcb008k_continuous_opening.sh`
- `tools/verify_wcb008k_continuous_opening.py`
- `tests/integration/salmon_creek_continuous_opening_capture_test.gd`
- Godot-generated `.uid` sidecars corresponding only to the new `.gd` files above

Root integration may additionally update:

- `docs/work_packets/wcb008k/CONTINUOUS_OPENING_RESULT.md`
- `docs/WORLD_CLASS_BUILDOUT_LOG.md`
- this brief only to correct a proven contradiction before a writer starts

Existing `vertical_slice_capture.gd`, its scene, the visual-quality manifest,
production Level 1/player/input/enemy/weapon/HUD files, collision, navigation,
route, progression, save, other missions, project/export settings, assets,
baselines, and release state are frozen. No existing production path may change;
the writer is limited to the five additive owned paths above.

## Proposed seam

A dedicated debug scene instances the unchanged production
`episode_1_level_1.tscn`, connects to `level_ready` before adding the level to
the tree, and fails unless the runtime is standard/non-Off-Leash. Its
non-rendering harness:

1. records the player's exact transform and establishes evidence `t = 0` when
   `level_ready` fires, then observes the production-created
   `OpeningGraceTimer` transition to running within one physics tick;
2. may set initial and subsequent camera yaw/pitch, but never player position;
3. drives movement/run/use/fire only through named input actions/events consumed
   by the real input service and `CobiePlayer`;
4. observes public signals plus read-only Level 1 evidence state, opening actors,
   `OpeningGraceTimer`, and `CombatPressure`;
5. writes runtime telemetry to an explicit isolated `/tmp` path;
6. releases every synthetic input action during teardown.

The wrapper runs Godot Movie Maker with isolated process homes, verifies the
runtime telemetry, binds Git/script identity, hashes keyframes, and writes the
final receipt. The new scene, harness, wrapper, verifier, and test must not use,
import, preload, load, instance, call, invoke, extend, or otherwise depend on
the legacy staged `vertical_slice_capture.gd`, its scene, or
`capture_native_evidence.sh`; those paths remain frozen and cannot contribute
code, frames, telemetry, or receipts to this evidence.

Before the evidence capture, the wrapper must complete two fresh, full-duration
dry semantic runs without Movie Maker frame output, followed by one fresh
900-frame Movie Maker run. All three runs use the same source, seed, standard
mode, action schedule, epoch semantics, isolated-home policy, and semantic
verifier gates. Each run must pass independently, the verifier must compare
their canonical semantic digests, and neither dry run may substitute for the
900-frame evidence run.

## Fixed run timeline

All boundaries are relative to the observed `level_ready` emission, which is
evidence `t = 0` and must map to accepted capture frame 0. The real timer must
start after that emission and no more than one physics tick later.

| Time | Bot input/camera intent | Required evidence |
| --- | --- | --- |
| 0.0–5.0 s | Real spawn; bounded orientation only; no fire | Armed Pawstol, real HUD/objective, spawn receipt |
| 5.0–12.0 s | Hold/micro-adjust normal movement while framing the existing sign; no fire | `NO ANIMALS / ON SPORTS FIELD` readable; grace timer active |
| 12.0–22.0 s | Let the timer activate the existing three actors; camera tracks actual actors; movement and any fire after observed activation use normal input | Actor wake transition, first telegraph/attack/contact, pressure cap ≤1 |
| 22.0–30.0 s | Normal forward/run and, only if resolver range permits, normal `use` at the existing shed gate | Continuous path reaches the shed-approach region and visually establishes the existing shed cue |

No weapon input is allowed before the harness has observed actual timer-driven
actor activation; the nominal 12.0-second boundary alone is not permission to
fire. Production weapon fire is itself an authorized early-activation path and
would invalidate this evidence goal.

## Receipt schema

The final JSON receipt is fail-closed and contains:

- schema/version and `evidence_class = "automated_bot_driven"`;
- source commit, dirty-state flag, scene path, harness path and SHA-256, verifier
  path and SHA-256;
- seed, renderer, resolution, declared render FPS and physics TPS;
- asserted standard/non-Off-Leash mode and the read-only runtime observations
  proving it;
- zero-based start/end frame, exact PNG frame count, start/end/duration seconds,
  first/last physics tick, and physics-tick count;
- expected spawn and observed `level_ready` spawn transforms;
- exact `level_ready` frame/tick/time epoch, declared 12.0-second grace, timer
  start/stop samples, timer-start delta from the epoch, observed actor
  activation frame/tick/time and cause, and first weapon-input time;
- authored/staged opening-roster IDs/classes/spawn positions, active actor count
  over time, first alert/telegraph/attack/contact timestamps, and first
  player-damage timestamp;
- declared and observed maximum simultaneous attackers;
- named-action transition log and camera-yaw/pitch samples;
- player path samples at least every 0.25 seconds with frame/tick/time,
  position, velocity, and grounded/dead state;
- maximum adjacent path-sample and per-physics-tick displacement, final
  shed-approach-region result, and collision count where observable;
- explicit `post_start_teleport = false`,
  `direct_encounter_activation = false`, `staged_zone_entry = false`, plus the
  source-lint results that enforce those claims;
- opening, pre-contact, first-contact, and shed-route keyframe paths, exact
  frame/time, SHA-256, and decoded 1280×720 dimensions;
- per-phase draw calls, objects, nodes, static memory and frame-time
  percentiles;
- complete Godot exit code, classified errors/warnings, ObjectDB/resource/RID
  diagnostics, and receipt-verifier errors.
- two dry-run receipt paths and SHA-256 values, the capture-run semantic
  receipt, each run's canonical semantic digest, and the cross-run comparison
  result.

## Mechanical tolerances and tests

- Capture: exactly 900 decoded PNGs, frames `0..899`, 30.000-second declared
  interval; no missing/duplicate frame.
- Mode/epoch: standard/non-Off-Leash is observed true for the entire run;
  `level_ready` occurs exactly once at evidence `t = 0`/frame 0; the real timer
  transitions to running after that event and within one physics tick.
- Simulation: 1,800 physics ticks ±1; observed timer-driven activation at
  12.000 seconds ±1 physics tick from evidence start.
- Spawn: observed `level_ready` position within 0.05 m of `(0, 1.1, 10)`.
- Movement integrity: no harness assignment to player/global transform after
  evidence start; maximum per-tick player displacement ≤0.50 m; discontinuity,
  physics interpolation reset, or unexplained route-region entry fails.
- Encounter: the authored/staged opening roster is exactly three while active
  opening-actor instances remain zero before timer-driven activation; activation
  creates exactly those three once, with no duplicate spawn, and the declared
  and observed attacker cap is exactly one. No fire is allowed before observed
  activation. There is no harness reference/call to
  `_activate_opening_encounter`, `_enter_zone`, `_stage_zone`,
  `activate_staged_enemies`, enemy damage methods, or enemy transforms; and no
  reference, import, load, instance, call, subprocess, or data dependency
  involving the legacy `vertical_slice_capture` script/scene or
  `capture_native_evidence.sh`.
- Route: final player position must enter the frozen shed-approach region
  `x ∈ [-4, 4]`, `z ∈ [-19, -14]` through recorded continuous movement. Entering
  the equipment-shed zone trigger is not required and cannot substitute for the
  route cue keyframe.
- Focused test statically rejects forbidden calls/transforms, instances the
  dedicated scene, proves named-action transitions, validates timing/path/
  actor/pressure contracts, enforces two dry semantic runs followed by one
  capture run, and tears down without ObjectDB/resource/RID leaks.
- Receipt verifier rejects wrong commit/hash/FPS/TPS/dimensions/count/timeline,
  forged mode/flags, wrong epoch or timer-start order, incomplete path samples,
  fire before observed activation, late/early or non-timer activation, legacy
  seam dependency, dry/capture semantic mismatch, missing contact, route miss,
  and any engine diagnostic outside the separately classified known movie-maker
  shader/RID pair.
- Existing Salmon Creek encounter pacing, Episode 1 route, import, core,
  documentation, architecture, and IP gates remain required.

## Performance budget

The harness adds no rendered node, light, particle, collision, navigation, audio,
enemy, weapon, HUD, or production process path. At 1280×720 after startup:

- scoped draw calls may not exceed a matched unchanged-Level-1 control by more
  than two;
- static memory may not exceed the matched control by more than 2 MiB;
- p95 frame time must be ≤33.33 ms and p99 ≤50 ms;
- no candidate-specific stall above 100 ms;
- node/object/static-memory samples may not grow monotonically after warm-up
  except for bounded, attributable production enemy/projectile/effect activity.

The known Movie Maker shader/RID teardown pair must be reported independently
for control and candidate. Any new ObjectDB/resource/RID diagnostic is a hard
failure.

## Side-effect policy

Every Godot/editor/capture process sets `HOME`, `CFFIXED_USER_HOME`,
`XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` to dedicated
subdirectories under `/tmp/cobie-wcb008k-continuation-runtime`. Evidence and
temporary movie frames stay under that root. No process may write the user's
Godot settings, production `user://` state, repository baselines, exported
packages, network services, or another checkout. The wrapper removes only its
own declared temporary frame directory after verified receipt/keyframe copying.

## Stop conditions

Stop and leave WCB-008K open if any of these is required or observed:

- a production player/input/enemy/weapon/HUD/level/collision/navigation/save
  change;
- Off-Leash mode, inability to prove standard mode, use of the legacy staged
  capture seam, or failure to align `level_ready`/timer start as specified;
- post-start translation, physics interpolation reset, direct encounter
  activation, staged zone entry, enemy manipulation, or fake overlay;
- inability to hold the exact 12.0-second boundary, three actors, one attacker,
  900 frames, or continuous path across both fresh dry semantic runs and the
  subsequent fresh capture run;
- no unmistakable actual contact or no normal-movement shed-approach keyframe;
- attributable engine error/leak, unbounded growth, or performance-budget miss;
- receipt/hash mismatch, dirty unrelated work, frozen-path need, or evidence
  that cannot be reproduced from the recorded source.

Human movement/feel, fairness, humor, audio mix, accessibility comfort,
photosensitivity, browser/target-Mac playthrough, controller, and iPad approval
remain open regardless of an automated pass.
