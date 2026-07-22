# World-class buildout scorecard

Snapshot: 2026-07-22, branch `hermes/world-class-369-buildout`, baseline source revision `5dbe291`.

Cobie Nukem is a mechanically substantial production candidate, not a finalized world-class release. WCB-000 through WCB-007 are mechanically closed, WCB-008 is active, and WCB-009 through WCB-011 remain blocked or pending.

| Final-state domain | Current evidence | Status |
| --- | --- | --- |
| Governance and production contracts | PRD, implementation plan, packet ledger, Visual Foundry, Godot, and Spark contracts exist and are exercised | Mechanically complete |
| Core gameplay, persistence, accessibility | Closed WCB-002–004 unit/integration/soak coverage | Mechanically complete; final regression gate remains |
| Rain City route and spatial combat | Five-zone route, authored loops/shortcut/sightlines, navigation bake, and route contracts pass | Mechanically complete |
| Rain City encounters and set piece | Authored 26-enemy budget, choreography, pressure, convoy integration, and reset contracts pass | Mechanically complete; human pacing/taste gate remains |
| Rain City Towmaster | WCB-007 combat/presentation seam is integrated and frozen from WCB-008 edits | Mechanically complete; human fight/readability gate remains |
| Rain City visual identity | Manifested foundry/material pipeline exists. The 2026-07-22 slice corrected excessive fog and replaced opaque collision-debug gate slabs with render-only authored barriers while preserving collision | In progress — WCB-008 |
| Rain City audio identity | Mission-specific music states, zone ambience, hero-enemy cues, and convoy cues exist and are event-wired | Mechanically present; final bounded evidence and human mix review remain |
| Canonical visual evidence | Deterministic 16:9 and 4:3 baseline/candidate captures exist for `vancouver_waterfront` | Partial; remaining aspects/views and human approval open |
| Integrated native/Web/device evidence | Validation, package, capture, motion, and provenance tooling exists; current source validation/export matrix passes | WCB-009 blocked behind WCB-008 |
| Pipeline replication | No second mission has passed the same end-to-end production contract | Pending WCB-009 selection / WCB-010 |
| Final release identity | No final source→package→public-download identity ledger is closed | Pending WCB-011 |

## Current WCB-008 evidence

- Rain City fog profiles now use a restrained `0.006`–`0.012` range instead of the flattening `0.12`–`0.27` range.
- Route gates retain their `StaticBody3D`, collision layer, `CollisionShape3D`, route metadata, and builder-owned open/close behavior; only the opaque debug mesh is hidden under a render-only authored barrier.
- Contracts cover fog ceiling, collision/presentation separation, dressing idempotence, and dedicated Compliance Gull/Umbrella Shield Enforcer behavior and visual paths.
- `QA_EXPORTS=1 bash tools/release_validate.sh` passes the full scripted matrix and Web/macOS exports.
- Candidate captures contain no capture failures:
  - `/tmp/cobie-wcb008-candidate/authored-gates-pass/vancouver_waterfront_1280x720.png`
  - `/tmp/cobie-wcb008-candidate/authored-gates-pass/vancouver_waterfront_1024x768.png`
- Image comparison exits `0` with no hard failures. Intentional review deltas versus the fog-only candidate are perceptual MAE `0.005747` at 16:9 and `0.007077` at 4:3.
- The candidate is not an approved baseline. The capture renderer still emits the previously recorded one-shader teardown warning, and human visual approval remains open.

## Roadmap authority

The dependency-complete roadmap is maintained in [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md), WCB-008 through WCB-011. Execution state and exact evidence are maintained in [`WORLD_CLASS_BUILDOUT_LOG.md`](WORLD_CLASS_BUILDOUT_LOG.md).

Immediate dependency-safe order:

1. Finish WCB-008 authored foundry/landmark/audio evidence and multi-aspect human review.
2. Run WCB-009 integrated native/Web/browser/device evidence and select exactly one replication target.
3. Execute WCB-010 for that one second mission.
4. Execute WCB-011 release identity and remaining campaign packetization.

Rain City and any replicated mission remain honestly labelled `BETA` until every applicable automated and human/device gate is recorded.

## Human-only open gates

- landmark and district identity from unlabelled captures;
- combat readability, pacing, fun, humor, and boss dominance;
- music/ambience/SFX mix and mission signature;
- photosensitivity, motion comfort, and accessibility usability;
- target-Mac route playthrough and physical-iPad touch/performance review;
- final `BETA` removal and public release approval.
