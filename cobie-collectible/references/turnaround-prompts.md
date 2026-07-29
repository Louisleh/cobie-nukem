# Phase 1 — canonical turnaround prompts

Generate five images, save them as `cobie-collectible/concepts/turnaround/{front,left,rear,right,hero}.png`,
then run:

```bash
uv run --project cobie-collectible/tools \
  python cobie-collectible/scripts/validate_turnaround.py
```

## Why the wording is this rigid

Multi-view image-to-3D generators resolve disagreement between input views by
inventing geometry. Every generator does this silently. If the front view is
framed slightly larger than the side view, the model reads it as a shape change
rather than a scale change, and the result is a subtly wrong character that no
amount of Blender cleanup recovers — you would be sculpting, not cleaning.

So the prompts below over-specify framing and under-specify mood. That is
deliberate. This is a technical input, not concept art. The concept work is
already done and frozen in `character-brief/cobie_figurine_v1.yaml`.

## Shared preamble

Paste this before every view prompt, unchanged:

> Character reference sheet for a collectible figurine. Full body, standing
> upright on two legs. Neutral A-pose, arms slightly away from the body, weight
> even. Plain flat mid-grey background, no scenery, no props on the ground, no
> shadow on the background. Flat even studio lighting from the front, no
> dramatic rim light, no colour cast, no lens flare. Orthographic-looking, no
> perspective distortion, camera at chest height. The character fills the same
> vertical space in frame with clear margin above the head and below the feet.
> Clean line, no motion blur, no depth of field. No text, no watermark, no
> logos, no border.
>
> Subject: an anthropomorphic labradoodle action hero. Apricot and golden-honey
> coat in tight corkscrew curls, longest on the crown and the ears. Long floppy
> drop ears hanging to jaw level, reading as one continuous curled mass framing
> the face. Short blunt muzzle blended into beard furnishings. Large glossy
> black nose. Teardrop aviator sunglasses with thin gold wire frames and dark
> mirrored lenses, sitting low on the muzzle. Black leather biker jacket, worn
> open, wide notched lapels, asymmetric zip, silver snap studs, weathered not
> new, chest fur showing through the open front. A chain collar carrying a
> rectangular metal dog tag stamped COBIE hanging at the sternum. Fur paws with
> visible toe pads. Slightly oversized head, figurine proportions.

## Per-view lines

Append exactly one of these to the preamble.

**front.png**
> View: directly from the front, facing the camera straight on. Both ears
> symmetrical. The dog tag is fully visible and centred at the sternum.

**left.png**
> View: exact left profile, rotated 90 degrees from the front. The far arm is
> hidden behind the body. The muzzle points to the left edge of frame. Same
> height and same framing as the front view.

**rear.png**
> View: directly from behind, rotated 180 degrees from the front. The back of
> the jacket is fully visible, showing the yoke and shoulder seams. The back of
> the head and the outer surface of both ears are visible. The face is not
> visible at all. Same height and same framing as the front view.

**right.png**
> View: exact right profile, rotated 90 degrees the other way from the front.
> The muzzle points to the right edge of frame. Same height and same framing as
> the front view.

**hero.png**
> View: three-quarter, rotated about 35 degrees from the front. Holding a
> chunky sci-fi tennis-ball launcher across the body with both paws — gold drum
> magazine with a bright yellow-green tennis ball visible in it, caged barrel,
> cyan glowing charge ring near the muzzle. Same height and same framing as the
> front view.

## The rear view is where this fails

Generators are strongly biased toward faces. Ask for a rear view and you will
often get a mirrored front, or a back with a face faintly implied. Check
`rear.png` before anything else: if you can see the sunglasses, regenerate.
The rear view is the single input that determines whether the mesh has real
back geometry or hallucinated back geometry, and hallucinated rear anatomy is
the second-ranked risk in the PRD.

## After generating

`validate_turnaround.py` checks framing geometry and palette consistency —
scale drift, vertical alignment, centring, background cleanliness. It cannot
check identity, and it says so. It prints a human checklist on success. Work
through that checklist honestly; it is cheaper than a print.
