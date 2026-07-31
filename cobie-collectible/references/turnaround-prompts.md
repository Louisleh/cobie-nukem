# Phase 1 — canonical turnaround prompts (v2, image-conditioned)

**v2 supersedes the text-only v1.** An owner-approved canonical hero render of
Cobie now exists (Fable-generated, figurine-sculpt style, 2026-07-30). Every
prompt below is **image-conditioned**: attach that render to each generation and
the prompt describes the delta, not the character from scratch. This removes
most of the identity-drift risk that v1 had to fight with words alone.

Target files, which `scripts/validate_turnaround.py` expects by name:

```
cobie-collectible/concepts/turnaround/{front,left,rear,right,hero}.png
```

Then run:

```bash
uv run --project cobie-collectible/tools \
  python cobie-collectible/scripts/validate_turnaround.py
```

## What changed in v2 and why

- **T-pose, not A-pose.** The turnaround now targets a full T-pose so the
  generated mesh is a reusable neutral asset (PRD FR-6: support a second pose).
  The **final figurine pose stays the hero render's stance** — the mesh gets
  posed in Blender.
- **No launcher in the character views.** The weapon is a separate printed part
  (`Cobie_Prop_FetchLauncher`); it gets its own prop sheet below. Sunglasses
  and the COBIE tag stay on — they are identity-critical.
- **Explicit ear directives on every view.** Past generations collapsed the ear
  mass into a bob of crown fur in side and rear views. The ears are drop ears:
  distinct hanging lobes, visually separate from the skull, even though the
  print will fuse them structurally.
- **The tail is specified.** The hero render is frontal; without a spec the
  generator invents rear anatomy (the PRD's #2 risk).

**All five files in `concepts/turnaround/` are geometry inputs, `hero.png`
included.** They therefore all show the same prop-free neutral T-pose.
`validate_turnaround.py` requires all five, at identical pixel dimensions, and
measures scale/alignment drift across the whole set — so an action-posed
`hero.png` would be read as a shape change and poison the very comparison the
gate exists to make. The final two-hand launcher pose is authored later in
Blender from the separate pose reference at the end of this document.

So the prompts below over-specify framing and under-specify mood. That is
deliberate. This is a technical input, not concept art. The concept work is
already done and frozen in `character-brief/cobie_figurine_v1.yaml`.

## Background rule — mid-grey, never black

The canonical render's black background is fine for identity reference and for
feeding single-image generators. It is **not** acceptable for the five
turnaround views: `validate_turnaround.py` separates subject from background by
colour distance, and on a near-black backdrop the **black leather jacket
classifies as background**, corrupting the silhouette, coverage and palette
metrics. Use a flat mid-grey (#808080 or close).

## Shared preamble

Attach the canonical hero render, then paste this before every view prompt:

> Use the attached reference image as the exact character design. Same
> character, same materials, same proportions, same sculpted-figurine style:
> matte clay-like fur in distinct corkscrew curl clumps, apricot / golden-honey
> coat, longest curls on the crown and ears. Teardrop aviator sunglasses with
> thin gold wire frames, a double bridge bar, and dark mirrored lenses, sitting
> low on the muzzle. Large glossy black nose, short blunt muzzle blended into
> beard furnishings. Ball-chain necklace carrying a rounded-rectangle metal tag
> stamped COBIE at the sternum. Black leather biker jacket, worn open, wide
> notched lapels, asymmetric zip, silver hardware, weathered not new, sleeves
> ending above the paws, chest fur showing through the open front. Fur paws
> with defined toes. Digitigrade hind legs, bare curly fur, no trousers.
> Slightly oversized head, figurine proportions.
>
> Character reference sheet for a collectible figurine. Full body, standing
> upright on two legs, weight even, paws open and empty. **No handheld prop or
> weapon in any turnaround view.** Clean line, no motion blur, no depth of
> field. No scenery, no props on the ground, no shadow cast on the backdrop.
>
> Render on a plain flat mid-grey background, no scenery, no ground shadow
> beyond a soft contact patch. Flat even studio lighting from the front, no
> rim light, no color cast. Orthographic-looking, camera at chest height, no
> perspective distortion. The character fills the same vertical space in every
> view with clear margin above the head and below the feet. No text, no
> watermark, no border.
>
> Do not fuse the ears and crown into a single rounded bob of hair. The ear
> flaps must read as separate hanging shapes in silhouette.

## Per-view prompts

**front.png**
> View: directly from the front, facing the camera straight on. Full T-pose:
> both arms extended straight out horizontally to the sides, palms down,
> fingers relaxed. No weapon. Both ears symmetrical, framing the face as
> distinct hanging flaps with a visible notch in the silhouette where each ear
> separates from the shoulder line. The COBIE tag fully visible and centred.

**left.png**
> View: exact left profile, rotated 90 degrees from the front. Arms remain in
> T-pose — the near arm points toward the viewer, foreshortened; do not lower
> the arms. The muzzle points to the left edge of frame. One drop ear visible
> as a distinct hanging volume: its leading edge sits behind the eye line, it
> hangs past the jaw, and it is clearly separated from the skull curls and the
> beard. The back of the head shows short crown curls — not a large bob merging
> into the ear. Tail visible: a medium-length labradoodle tail carried in a
> relaxed upward curve with a plume of curls, emerging below the jacket hem.
> Same height and framing as the front view.

**rear.png**
> View: directly from behind, rotated 180 degrees from the front. Arms remain
> in T-pose. The back of the jacket is fully visible: yoke seam, back panel,
> sleeve seams, weathered leather. The back of the head shows crown curls, and
> BOTH ears are visible as separate hanging lobes on either side of the head,
> outer surfaces showing, clearly distinct from the neck and shoulders. Tail
> centred, relaxed upward curve with a curl plume, emerging below the jacket
> hem. No facial features are visible anywhere — no glasses, no nose, no eyes.
> Same height and framing as the front view.

**right.png**
> View: exact right profile, rotated 90 degrees the other way from the front.
> Mirror of the left profile: same T-pose arms, same distinct hanging drop ear,
> same tail, muzzle pointing to the right edge of frame. Same height and
> framing as the front view.

**hero.png**
> View: three-quarter, rotated about 35 degrees from the front. Identical
> neutral T-pose, empty paws, same clothing and accessories as the four cardinal
> views. No handheld prop or weapon. One ear reads as a distinct hanging lobe on
> the near side; the far ear is still visible past the muzzle. Tail visible in
> the same relaxed upward curve. Same height and same framing as the front view.

Note: this slot is **not** the canonical action render. Despite the filename,
`hero.png` is the fifth geometry input and must match the other four exactly.

## Separate final-pose reference — never feed this to multi-view generation

The canonical hero render already serves this purpose. If you need to
regenerate it on a neutral backdrop, save it outside `concepts/turnaround/` —
for example `concepts/pose-reference/fetch_launcher_hero.png`. It guides
supervised Blender posing and launcher placement; it is not a sixth
identity-mesh input.

Use the same subject description from the shared preamble, then append:

> Dynamic three-quarter pose reference for a 140 mm static display figurine.
> Planted wide hero stance with slight contrapposto, weight on the back paw,
> chin subtly raised. Both paws hold a chunky sci-fi tennis-ball launcher
> across the body: gunmetal receiver, hazard-gold armour panels, a windowed
> chamber with the golden tennis ball visible inside, ribbed barrel collars,
> round muzzle, cyan charge indicators, under-barrel grip. Preserve the same
> head ratio, face, ears, aviators, jacket, collar and COBIE tag as the
> approved neutral turnaround. Plain grey studio background. This image is for
> Blender posing only, not image-to-3D multi-view generation.

## Prop sheet — fetch launcher (separate generation)

The launcher design is the one in the hero render: gunmetal receiver,
hazard-gold armor panels, a windowed chamber with the golden tennis ball
visible inside, ribbed barrel collars, round muzzle, cyan charge indicators,
under-barrel grip. Generate three views on mid-grey, same flat light:

> The sci-fi tennis-ball launcher from the attached reference image, alone, no
> character. [front view / exact left profile / top-down view]. Same materials
> and proportions as the reference. Plain flat mid-grey background, flat even
> studio light, orthographic look, no text.

Save as `concepts/turnaround/prop_launcher_{front,left,top}.png` (not checked
by the validator; used for Blender reference when detailing
`Cobie_Prop_FetchLauncher`).

## Which generator eats which images

| Generator | Input | Give it |
|---|---|---|
| Hunyuan3D 2.1 / 3.x multi-view | up to 4 views | `front`, `left`, `rear`, `right` |
| TRELLIS.2 | single image only ([issue #10](https://github.com/microsoft/TRELLIS.2/issues/10)) | the neutral `hero.png` |
| Stable Fast 3D | single image | the neutral `hero.png` |

Single-image generators should be fed the **neutral** `hero.png` so their
candidate is comparable with the multi-view one in the clay bakeoff.

Separately, the canonical action render can be run through a single-image
generator **today**, before any turnaround exists, as an early feasibility
probe. Treat that output as a throwaway smoke test, not a bakeoff candidate:
its baked-in action pose and held launcher make it non-comparable with the
neutral candidates and unusable as the reusable core asset (FR-6).

TRELLIS.2 caution: its O-Voxel representation deliberately produces open
surfaces and non-manifold geometry — a feature for game engines, a defect for
resin. Its own docs ship hole-filling post-processing for "applications
requiring strictly watertight geometry (e.g. 3D printing)". Expect
`print_check.py` to demand more cleanup from its output, not less. Its PBR
texture headline is irrelevant here: the bakeoff scores neutral clay and V1
prints in grey resin.

## The rear view is where this fails

Generators are strongly biased toward faces. Check `rear.png` before anything
else: if you can see the sunglasses, or the ears have merged into a bob,
regenerate. The rear view is the single input that decides whether the mesh has
real back geometry or hallucinated back geometry.

## After generating

`validate_turnaround.py` checks framing geometry and palette consistency —
scale drift, vertical alignment, centring, background cleanliness. It cannot
check identity, and says so; it prints a human checklist on success. Work
through that checklist honestly — it is cheaper than a print.
