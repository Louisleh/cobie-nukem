# World-class buildout scorecard

Snapshot: 2026-07-23, branch `hermes/world-class-369-buildout`, packet source revision `0501924`.

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
| Canonical visual evidence | Camera-bound deterministic evidence now proves five distinct non-boss route views at exact 1280×720, 1680×1050, 1024×768, and 3440×1440. WCB-008H repaired compact HUD lifecycle safety; WCB-008I decoupled a desktop-safe bootstrap from exact borderless capture size and independently verifies window, decoded PNG, pose, and image hash | Automated four-aspect prerequisite complete; human visual approval remains open |
| Integrated native/Web/device evidence | Validation, package, capture, motion, and provenance tooling exists. The full release wrapper, native Compatibility performance profile, and fresh macOS/Web exports pass on this host | WCB-009 remains blocked behind WCB-008 human acceptance; browser and physical-device evidence remain open |
| Pipeline replication | No second mission has passed the same end-to-end production contract | Pending WCB-009 selection / WCB-010 |
| Final release identity | No final source→package→public-download identity ledger is closed | Pending WCB-011 |

## Current WCB-008 evidence

- Rain City fog profiles now use a restrained `0.006`–`0.012` range instead of the flattening `0.12`–`0.27` range.
- Route gates retain their `StaticBody3D`, collision layer, `CollisionShape3D`, route metadata, and builder-owned open/close behavior; only the opaque debug mesh is hidden under a render-only authored barrier.
- Contracts cover fog ceiling, collision/presentation separation, dressing idempotence, and dedicated Compliance Gull/Umbrella Shield Enforcer behavior and visual paths.
- The reproducible Blender foundry now authors 272 source parts into the same 13 runtime material batches, including a broad harbour skyline, window-light scale cues, an original Rainline beacon, and two source-built north-shore ridgelines. Dedicated distance materials preserve restrained atmospheric value separation without owning collision or navigation.
- The asset contract guards the skyline/ridgeline batch presence, production-scale bounds, dedicated runtime materials, and presentation-only collision separation.
- `rain_city_audio_event_contract_test.gd` drives production mission-presentation methods, concrete hero-enemy signals, and generation-gated convoy handlers to prove exact Vancouver music/ambience plus Rain City Gull, shield, module, movement, and defeat cue IDs. The test is part of `release_validate.sh`; it deliberately disables playback only for deterministic state routing, not data substitution.
- `QA_EXPORTS=1 bash tools/release_validate.sh` now passes the complete import/test/performance/export matrix on this host. A fresh native Compatibility profile also passes: Rain City samples average `16.655`–`17.083 ms`, p95 `17.422`–`23.346 ms`, and report zero stalls above `100 ms`. The two known bounded GLES3 shader/RID teardown diagnostics remain visible rather than suppressed.
- WCB-008G invalidated the earlier twenty-image district-evidence claim: the five supposed route views were near-duplicate fallback compositions (16:9 edge IoU `0.906449`–`0.992621`; 4:3 `0.908159`–`0.991297`; low-frequency MAE `0.004952`–`0.049008`) even though each process exited successfully.
- The corrected `/tmp/cobie-wcb008-candidate/route-evidence-integrity-final/` candidate contains ten post-draw, hash-bound captures for all five route views at 1280×720 and 1024×768. All ten receipts independently validate player origin, camera origin, direction, FOV, active player-camera ancestry, and exact image SHA-256.
- Pairwise corrected metrics pass at 16:9 (edge IoU `0.107397`–`0.436021`, low-frequency MAE `0.063798`–`0.139763`) and 4:3 (edge IoU `0.119314`–`0.463381`, low-frequency MAE `0.061399`–`0.121410`). Rendered review confirms five nonblank, materially distinct route compositions rather than one fallback camera.
- Native/direct capture subprocesses use temporary `HOME`, `CFFIXED_USER_HOME`, and XDG roots. Group baseline approval now requires every declared route view and aspect, validates both edge and low-frequency composition, and stages/hash-verifies/atomically swaps or restores the baseline package.
- WCB-008H closes that compact HUD defect mechanically: the bottom bar now uses the live viewport size, switches at a tested 630-logical-pixel breakpoint, and assigns non-overlapping access/weapon/ammo/reload regions. A `SubViewport` regression exercises the production `size_changed` path at 480, 576, 619, 620, 629, 630, 640, and 860 logical pixels with representative stress text at the clamped `1.5×` accessibility scale; it checks applied bounds, global safe area, minimum width/height, every compact rect pair, and the font-scale clamp.
- `/tmp/cobie-wcb008-candidate/wcb008i-final-four-aspect/` contains twenty fresh post-draw, pose/hash-bound captures for all five route views at exact 1280×720, 1680×1050, 1024×768, and 3440×1440. The report has zero failures and marks `rain_city_non_boss_routes.complete = true`; pairwise edge IoU peaks at `0.463343` and low-frequency MAE bottoms at `0.061401`.
- WCB-008I boots direct capture at a desktop-safe decorated 1280×720, switches borderless before applying the requested capture size and instantiating the production scene, then fails if requested/window/viewport/decoded-PNG dimensions disagree. This resolved the prior macOS decorated-window clamp without weakening receipt validation.
- Pixel review of all twenty images found five nonblank/correct route views at every declared aspect and no mechanical portrait/health/armor/access/weapon/ammo/objective/crosshair/caption clipping or overlap. Supported-aspect comparison against WCB-008H passes with perceptual MAE `0.000001`–`0.000090`; human taste remains open.
- No WCB-008G candidate was approved as a baseline. Successful direct runs retain one exact shader and one exact RID teardown diagnostic; those bounded exceptions remain classified while any duplicate, near-match, script error, ObjectDB/resource leak, orphan diagnostic, missing receipt, pose drift, or image-hash mismatch fails capture.

## Roadmap authority

The dependency-complete roadmap is maintained in [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md), WCB-008 through WCB-011. Execution state and exact evidence are maintained in [`WORLD_CLASS_BUILDOUT_LOG.md`](WORLD_CLASS_BUILDOUT_LOG.md).

Immediate dependency-safe order:

1. Prepare and run WCB-008's named human art/mix/humor/accessibility review from the exact four-aspect rendered set and existing bounded audio evidence. Automated evidence must not substitute for that approval.
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
