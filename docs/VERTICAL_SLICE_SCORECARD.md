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
| Canonical visual evidence | Camera-bound deterministic evidence now proves five distinct non-boss route views at 16:9 and 4:3, but the older 16:10/ultrawide set was invalidated and the 4:3 review exposed a clipped lower-right ammo/weapon cluster | Reopened in WCB-008; safe-area fix plus a fresh four-aspect set remain, and human visual approval is open |
| Integrated native/Web/device evidence | Validation, package, capture, motion, and provenance tooling exists. Standalone macOS/Web exports pass; the full wrapper currently stops at the unchanged headless performance budget | WCB-009 blocked behind WCB-008 and the recorded performance-wrapper blocker |
| Pipeline replication | No second mission has passed the same end-to-end production contract | Pending WCB-009 selection / WCB-010 |
| Final release identity | No final source→package→public-download identity ledger is closed | Pending WCB-011 |

## Current WCB-008 evidence

- Rain City fog profiles now use a restrained `0.006`–`0.012` range instead of the flattening `0.12`–`0.27` range.
- Route gates retain their `StaticBody3D`, collision layer, `CollisionShape3D`, route metadata, and builder-owned open/close behavior; only the opaque debug mesh is hidden under a render-only authored barrier.
- Contracts cover fog ceiling, collision/presentation separation, dressing idempotence, and dedicated Compliance Gull/Umbrella Shield Enforcer behavior and visual paths.
- The reproducible Blender foundry now authors 272 source parts into the same 13 runtime material batches, including a broad harbour skyline, window-light scale cues, an original Rainline beacon, and two source-built north-shore ridgelines. Dedicated distance materials preserve restrained atmospheric value separation without owning collision or navigation.
- The asset contract guards the skyline/ridgeline batch presence, production-scale bounds, dedicated runtime materials, and presentation-only collision separation.
- `rain_city_audio_event_contract_test.gd` drives production mission-presentation methods, concrete hero-enemy signals, and generation-gated convoy handlers to prove exact Vancouver music/ambience plus Rain City Gull, shield, module, movement, and defeat cue IDs. The test is part of `release_validate.sh`; it deliberately disables playback only for deterministic state routing, not data substitution.
- `QA_EXPORTS=1 bash tools/release_validate.sh` reaches the unchanged headless performance gate but does not pass it on this host: Rain City measured `47.853 ms` average / `124.320 ms` p95 and Ventura `59.892 ms` / `147.960 ms` against the existing 50 ms average/p95 budgets. The packet touches no production scene/performance paths. Standalone macOS and Web exports, the asset/IP scan, architecture check, and content validator pass; the wrapper blocker remains open.
- WCB-008G invalidated the earlier twenty-image district-evidence claim: the five supposed route views were near-duplicate fallback compositions (16:9 edge IoU `0.906449`–`0.992621`; 4:3 `0.908159`–`0.991297`; low-frequency MAE `0.004952`–`0.049008`) even though each process exited successfully.
- The corrected `/tmp/cobie-wcb008-candidate/route-evidence-integrity-final/` candidate contains ten post-draw, hash-bound captures for all five route views at 1280×720 and 1024×768. All ten receipts independently validate player origin, camera origin, direction, FOV, active player-camera ancestry, and exact image SHA-256.
- Pairwise corrected metrics pass at 16:9 (edge IoU `0.107397`–`0.436021`, low-frequency MAE `0.063798`–`0.139763`) and 4:3 (edge IoU `0.119314`–`0.463381`, low-frequency MAE `0.061399`–`0.121410`). Rendered review confirms five nonblank, materially distinct route compositions rather than one fallback camera.
- Native/direct capture subprocesses use temporary `HOME`, `CFFIXED_USER_HOME`, and XDG roots. Group baseline approval now requires every declared route view and aspect, validates both edge and low-frequency composition, and stages/hash-verifies/atomically swaps or restores the baseline package.
- The corrected 4:3 evidence exposes a real safe-area defect: the lower-right ammo count and weapon label are absent/clipped while the portrait, health, armor, access status, objective, and crosshair remain visible. This mechanical UX gate is open; no human taste approval is implied.
- No WCB-008G candidate was approved as a baseline. Successful direct runs retain one exact shader and one exact RID teardown diagnostic; those bounded exceptions remain classified while any duplicate, near-match, script error, ObjectDB/resource leak, orphan diagnostic, missing receipt, pose drift, or image-hash mismatch fails capture.

## Roadmap authority

The dependency-complete roadmap is maintained in [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md), WCB-008 through WCB-011. Execution state and exact evidence are maintained in [`WORLD_CLASS_BUILDOUT_LOG.md`](WORLD_CLASS_BUILDOUT_LOG.md).

Immediate dependency-safe order:

1. Repair the 4:3 HUD safe-area defect, recapture all five Rain City route views across four declared aspects under WCB-008G integrity guards, and rerun the headless performance gate before human art/mix/humor/accessibility review.
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
