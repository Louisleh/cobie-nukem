# WCB-008K Result — Salmon Creek Opening Presentation v1

**Status:** integrated-candidate ready; fresh Spark/high artifact critic accepted at 80/100; continuous 0–30 second human/browser run remains open  
**Baseline:** `a86e3f07c489b028cfcb1fa0cdbea76b6d9a9c21`  
**Root owner:** GPT-5.6-sol/high through Hermes  
**Writer:** GPT-5.3-Codex-Spark/high, isolated clone `/tmp/cobie-spark-wcb008k`

## Bounded change

- Existing `NO ANIMALS / ON SPORTS FIELD` sign moved one metre toward the opening camera and scaled to 95%, preserving text, secret, signals, and left-of-route placement.
- Existing equipment-shed `Label3D` moved forward into the shed approach and increased from font size 42 to 44.
- Existing `ShedWorkLight` moved toward the route and retuned warmer/brighter with a 12 m range.
- No asset, prop, light, label, collision, route, enemy, weapon, HUD, progression, navigation, or encounter node was added.
- Added a focused construction-contract test; existing encounter pacing test is byte-identical to baseline.

## Root verification already executed

```text
SALMON CREEK OPENING PRESENTATION TEST: PASS
SALMON CREEK ENCOUNTER PACING: PASS
PASS: Episode 1 Level 1 route, gates, secrets, pacing metadata, encounter wiring, and finale
Godot headless editor import/parse: exit 0
```

Commands:

```bash
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/salmon_creek_opening_presentation_test.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/salmon_creek_encounter_pacing_test.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/test_episode_1_level.gd
bash tools/run_godot_safe.sh --timeout 600 -- --headless --path . --editor --quit
```

The focused and route commands emitted no ObjectDB/resource/RID teardown diagnostics. The macOS certificate lookup warning seen in the isolated writer was not present in the root rerun.

## Matched artifact evidence

- Baseline: `/tmp/cobie-wcb008k-baseline/a86e3f0-opening`
- Candidate: `/tmp/cobie-wcb008k-candidate/candidate-v1`
- Comparison: `/tmp/cobie-wcb008k-compare-v1/comparison.md`
- Three views × four aspects: 12/12 present and dimension-matched
- Automated comparison status: PASS, with intentional pixel/perceptual review warnings in all cells

Root pixel review:

- Opening 1024×768: candidate fully frames both lines of the `NO ANIMALS` joke; baseline cuts the first characters off both lines. HUD, weapon, reticle, objective, enemy silhouettes, and dominant route remain unobscured.
- First contact 1024×768: same improvement to joke continuity; no visible threat/HUD/route regression.
- Shed 1280×720: candidate exposes the existing equipment-shed label above the route and creates a warmer ceiling/approach value group; no glare, clipping, false pickup, or HUD competition observed.
- Residual: health labels remain visually noisy and the shed cue is still subtler from the field than inside the shed. Enemy/HUD paths were frozen for this packet.

## Performance and topology evidence

The candidate adds no renderable node or light. The focused test asserts the shed-only kit remains exactly 21 direct children with exactly one shed label and one `ShedWorkLight`. Opening sign count remains exactly one.

Matched native movie capture CPU render averages:

| Aspect | Baseline | Candidate | Delta |
| --- | ---: | ---: | ---: |
| 1280×720 | 2.04 ms/frame | 1.93 ms/frame | -0.11 |
| 1680×1050 | 2.07 ms/frame | 2.00 ms/frame | -0.07 |
| 1024×768 | 2.01 ms/frame | 1.90 ms/frame | -0.11 |
| 3440×1440 | 2.19 ms/frame | 2.13 ms/frame | -0.06 |

These are matched-run evidence, not a statistical benchmark. They show no observed CPU-render regression. Draw-call topology is unchanged because the same singular `NarrativeSign`, `Label3D`, and `OmniLight3D` nodes are retained; only transforms/parameters changed.

## Honest harness boundary

`scripts/debug/vertical_slice_capture.gd` produces staged key viewpoints across a 220-frame / 7.3-second movie. It is **not** a continuous 30-second playthrough and is not claimed as one.

Both baseline and candidate movie-maker runs emit the same pre-existing Compatibility-renderer particle shader/RID exit leak. It is not candidate-specific, but capture hygiene remains open and no fully-clean capture claim is made.

## Provisional root rubric

- A Opening orientation/hero affordance: **17/20**
- B Rule-break joke/environment identity: **18/20**
- C First-contact readability/fairness: **20/25**
- D Equipment-shed route cue: **13/20**
- E Engineering/performance/accessibility/provenance: **12/15**
- **Total: 80/100**; every category at least 60%

## Gauntlet process evidence

- Four initial parallel read-only Spark auditors were launched. Two over-read broad authority and exhausted useful context without a final verdict; those outputs were rejected.
- A lean fresh Spark auditor returned `revise`, correctly finding that the sign ownership transfer needed to be recorded and that the existing capture script was staged rather than a 30-second run.
- First writer candidate passed functionally but leaked 27 ObjectDB instances and retained resources/RIDs. Root rejected it.
- Same writer repair #1 moved coverage into a focused test and removed the leak diagnostics. Root independently reran the accepted commands.
- First fresh image-attached critic returned `revise` because its read-only environment could not complete the focused test and because performance/draw-call evidence was missing from its packet. Root supplied real completed outputs and the matched topology/performance evidence above for re-adjudication.

## Remaining human/device gates

- Continuous 0–30 second browser and target-Mac playthrough
- Combat feel and fairness under live player movement
- Humor timing and readability while moving
- Audio mix, motion comfort, photosensitivity comfort
- Physical controller and iPad validation
- Human taste judgment that the warmer shed cue is strong enough without becoming overbearing

## Final independent critic

- Durable result: `docs/work_packets/wcb008k/FRESH_CRITIC.md`
- Verdict: **accept**
- Score: **80/100**, with every category at least 60%
- Largest residual: the shed route cue remains subtler from the opening field than inside the shed; enemy health-label noise still competes with threat/route hierarchy.

## Rejected alternatives

- Adding new signs, lamps, props, assets, enemies, captions, route geometry, or HUD logic
- Moving enemy health labels or changing combat timing to solve presentation noise
- Claiming staged capture frames as a real 30-second run
- Accepting the writer's first leaking test
