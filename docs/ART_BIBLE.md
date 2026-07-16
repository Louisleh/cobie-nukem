# Cobie Nukem visual art bible

## Direction

Cobie uses **high-resolution retro 2.5D**: authored low-poly 3D spaces with illustrated or pre-rendered directional characters, modern readability, selective atmospheric effects, and no deliberate low-resolution pixelation as a default. The tone is rainy municipal absurdity seen through an action-comedy lens: dangerous shapes read instantly, quiet surfaces support the action, and jokes reward a second look.

This is an original project. Do not imitate protected shooter characters, performances, logos, layouts, dialogue, or trade dress. Real locations are evoked through original silhouettes and fictionalized details rather than copied photography, maps, floorplans, or branding.

## Visual hierarchy

Every canonical view should read in this order:

1. immediate threat, interactable, or route decision;
2. dominant landmark and intended direction of travel;
3. Cobie HUD state and current objective;
4. environmental story and jokes;
5. supporting texture and weather detail.

Critical progression uses a consistent golden-tennis-ball accent, strong silhouette, localized pulse, and authored cue. Enemy danger uses warm red/orange telegraphs; player/assist information uses pale cream, cool teal, and tennis-ball yellow. Cyan is reserved for technological weak points and recoverable systems. Do not communicate state through hue alone.

## Palette and value

- **Salmon Creek exterior:** storm blue, wet evergreen, dark turf, municipal sodium amber, cream field markings, hazard red.
- **Shed and tunnels:** charcoal, damp cedar/rust, practical amber, sparse cool utility light.
- **Laboratory:** blue-green shadow, bone-white panels, oxidized metal, restrained cyan systems, contaminated yellow accents.
- **Walker arena:** near-black steel and rain, amber structure light, red attack language, cyan weak point, golden finale reward.
- **Vancouver:** slate rain, seawall concrete, harbour green, ferry cream, warm storefront pockets, original neon used sparingly.

Keep threats at least one clear value step away from their background at intended combat distance. Avoid full-frame fog, bloom, particles, or dark overlays that flatten that separation.

## Shapes and edges

- Cobie and friendly/progression elements favor rounded, energetic shapes.
- Compliance enemies favor boxes, clamps, warning stripes, rigid shields, lenses, and officious symmetry.
- Major landmarks need one identifiable silhouette at thumbnail size.
- Hero sprites use clean alpha, stable feet baselines, consistent world height, and no orientation snap during reactions.
- Edge wear, decals, puddles, markings, and jokes are separate layers; do not bake unique details into visibly repeating base tiles.

## Materials

Use consistent texel density within a zone. Each production material records tiling scale, albedo range, roughness range, normal intensity, packed-map channels, mipmaps/filtering, surface response, and source graph. Wetness darkens albedo and lowers roughness selectively; it is not a universal mirror coating.

Core families are wet turf, painted concrete, laboratory panels, rusted municipal metal, sports-field paint, tunnel masonry, rain-darkened wood, seawall concrete, harbour steel, and mud. Web/iPad materials must remain readable with fewer texture samples and without dynamic reflections.

## Lighting, fog, and landmarks

Light establishes direction before mood. Each major zone has a dominant direction, at least two memorable landmarks, a restrained fog range, and a clear combat value structure. Prefer baked/static and authored emissive support; reserve dynamic lights and shadows for gameplay-relevant moments. Transparency is limited, especially on Web.

## Character and animation contract

Major enemies use eight-direction presentation where memory permits. Required vocabulary: idle, locomotion, alert, telegraph, attack, hurt, stagger, milestone/phase, and death. Reaction states preserve the current orientation or use a transition designed to hide the change. Every atlas records orthographic camera, frame size, direction order, feet baseline, world height, FPS, distant FPS, alpha mode, compression, and provenance.

Enemy scale is gameplay data: the rendered silhouette must agree with collision and intended threat. A boss cannot render as a tiny atlas cell; a reaction cannot expose a full sheet.

## HUD, touch, and typography

UI uses bold condensed display type for identity and a highly legible sans-serif for instructions, captions, numbers, and touch labels. Hierarchy comes from size, spacing, containers, icons, and contrast—not repeated outlines or oversized text.

HUD and touch presentation must fit 16:9, 16:10, tablet 4:3, and ultrawide. Respect safe-area insets. Touch controls need authored idle, pressed, held, cooldown, and disabled states; left/right sticks remain visually distinct from action buttons. Controls may never cover health, ammo, current objective, captions, or boss health.

## VFX language

- enemy hit: compact warm spark/debris plus target reaction;
- weak point: cyan/gold flash with readable state change;
- shield: directional blue-white plane, stress cracks, then a bounded break burst;
- explosion: bright core, short debris, smoke that clears quickly;
- secret: tennis-ball gold pop, concise particles, and unmistakable caption/audio;
- player damage: directional indicator and portrait response, never only a full-screen red wash.

All effects have reduced-flash and lower-density variants, bounded lifetime, pooled or capped ownership, and a performance budget.

## Prohibited placeholder treatments

- visible unstyled CSG on the critical route;
- stretched spheres as final trees or vegetation;
- flat beige slabs with invisible damage behavior;
- duplicated locomotion cells represented as unique animation;
- baked text or field lines repeating inside tiling materials;
- generic labels where an authored sign/icon is required;
- procedural circles and fallback glyphs represented as final touch art;
- unmanifested one-off generated images without editable or reproducible source.

## Canonical review views

The fixed review set is title, mission selection, Salmon Creek opening, sports-field encounter, shed, laboratory, tunnel, Walker arena, Vancouver waterfront, and 4:3 touch HUD. Capture before and candidate views at the same revision-controlled staging, seed, aspect, quality tier, and frame. Visual differences prompt review; only malformed captures, missing assets, safe-area failures, and measured budget violations fail mechanically.
