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
| Rain City visual identity | Manifested foundry/material pipeline exists. The 2026-07-22 slices corrected excessive fog, replaced opaque collision-debug gate slabs with authored barriers, and added an original harbour skyline, Rainline beacon, and layered north-shore silhouette | In progress — WCB-008; human identity/taste gate remains |
| Rain City audio identity | Mission-specific music states, zone ambience, hero-enemy cues, and convoy cues exist; runtime event→cue routing is now explicitly regression-tested | Mechanically evidenced; human mix/signature review remains |
| Canonical visual evidence | Isolated deterministic 16:9, 16:10, 4:3, and ultrawide captures exist for all five non-boss Rain City route zones | Mechanically complete; human visual approval remains open |
| Integrated native/Web/device evidence | Validation, package, capture, motion, and provenance tooling exists; current source validation/export matrix passes | WCB-009 blocked behind WCB-008 |
| Pipeline replication | No second mission has passed the same end-to-end production contract | Pending WCB-009 selection / WCB-010 |
| Final release identity | No final source→package→public-download identity ledger is closed | Pending WCB-011 |

## Current WCB-008 evidence

- Rain City fog profiles now use a restrained `0.006`–`0.012` range instead of the flattening `0.12`–`0.27` range.
- Route gates retain their `StaticBody3D`, collision layer, `CollisionShape3D`, route metadata, and builder-owned open/close behavior; only the opaque debug mesh is hidden under a render-only authored barrier.
- Contracts cover fog ceiling, collision/presentation separation, dressing idempotence, and dedicated Compliance Gull/Umbrella Shield Enforcer behavior and visual paths.
- The reproducible Blender foundry now authors 272 source parts into the same 13 runtime material batches, including a broad harbour skyline, window-light scale cues, an original Rainline beacon, and two source-built north-shore ridgelines. Dedicated distance materials preserve restrained atmospheric value separation without owning collision or navigation.
- The asset contract guards the skyline/ridgeline batch presence, production-scale bounds, dedicated runtime materials, and presentation-only collision separation.
- `rain_city_audio_event_contract_test.gd` drives production mission-presentation methods, concrete hero-enemy signals, and generation-gated convoy handlers to prove exact Vancouver music/ambience plus Rain City Gull, shield, module, movement, and defeat cue IDs. The test is part of `release_validate.sh`; it deliberately disables playback only for deterministic state routing, not data substitution.
- `QA_EXPORTS=1 bash tools/release_validate.sh` passes the full scripted matrix and Web/macOS exports.
- Twenty isolated canonical captures cover downtown, Rain City Slice, waterfront, terminal, and harbour at 1280×720, 1680×1050, 1024×768, and 3440×1440 under `/tmp/cobie-wcb008-candidate/rain-city-route-views-clean-final/` and `/tmp/cobie-wcb008-candidate/rain-city-waterfront-isolated-final/`.
- Native/direct capture subprocesses use temporary `HOME`, `CFFIXED_USER_HOME`, and XDG roots. A real-run check preserved the production checkpoint hash and user-data file count; the release matrix now includes four isolation/diagnostic-classifier regressions.
- Image comparison against the authored-gate candidate exits `0` with no hard failures. Intentional backdrop deltas are perceptual MAE `0.003288` at 16:9 and `0.003668` at 4:3.
- Cross-aspect capture review found no actor/event contamination, HUD clipping, or FOV blocker. It also exposed the honest remaining art gap: downtown, Slice, terminal, and harbour still share too much rectilinear corridor geometry and weak material/landmark hierarchy to satisfy world-class unlabelled district identity.
- The candidate is not an approved baseline. The capture renderer still emits one exact shader and one exact RID teardown diagnostic per direct run; those two bounded exceptions are classified explicitly while any duplicate, near-match, script error, ObjectDB/resource leak, or orphan diagnostic fails capture.

## Roadmap authority

The dependency-complete roadmap is maintained in [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md), WCB-008 through WCB-011. Execution state and exact evidence are maintained in [`WORLD_CLASS_BUILDOUT_LOG.md`](WORLD_CLASS_BUILDOUT_LOG.md).

Immediate dependency-safe order:

1. Finish WCB-008 district-specific landmark/material composition, then run multi-aspect human art/mix/humor/accessibility review against the mechanically complete capture set.
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
