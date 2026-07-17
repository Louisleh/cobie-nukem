---
name: cobie-visual-foundry
description: Produce, integrate, and validate authored visual work for Cobie Nukem using the project Blender-to-2.5D pipeline, Material Maker sources, Godot runtime captures, multi-aspect visual comparison, Web performance traces, and asset provenance. Use for Cobie environment art, character/enemy sprites, animation atlases, materials, lighting, VFX, HUD/touch presentation, canonical screenshots, visual regressions, or any request to make the game more visually cohesive and production-ready.
---

# Cobie Visual Foundry

Turn a bounded art target into a reproducible source-to-runtime asset with reviewable performance and visual evidence. Keep GPT-5.6 responsible for art direction, composition, taste, final acceptance, and release claims. Spark workers may perform mechanical metadata, import, capture, comparison, and manifest work only.

## Establish the target

1. Read `AGENTS.md`, `docs/PHASE_ROADMAP_PRD.md`, `docs/ART_BIBLE.md`, `docs/BLENDER_ASSET_PIPELINE.md`, `docs/design/agentic-toolchain.md`, and the `cobie-godot-production` skill.
2. Run `python3 .agents/skills/cobie-visual-foundry/scripts/verify_visual_toolchain.py --project-root .`.
3. Name one bounded target: a canonical view, hero asset, material family, animation vocabulary, VFX family, or responsive UI state.
4. Capture the current runtime view before changing source. Record the exact revision, viewport, quality profile, camera/staging ID, and frame rate.
5. Write an art brief using [art-brief-contract.md](references/art-brief-contract.md). Stop if silhouette, palette, gameplay readability, source ownership, or platform budget is undecided.
6. Name the mission identity row from `docs/ART_BIBLE.md`. Record the dominant landmark, material families, weather/ambience, route-value hierarchy, and location-specific prop/joke language; reject a treatment that reads as a recolor of another mission.

## Select the production route

- **Hero enemy or animated prop:** concept/reference sheet → Blender source and rig → deterministic directional renders → atlas metadata → Godot import → runtime capture.
- **Environment kit or landmark:** blockout over preserved gameplay collision/navigation → Blender modular source → LOD/collision names → GLB export → Godot presentation layer.
- **Surface material:** Material Maker source graph → Web-safe albedo/normal/packed ORM exports → import settings → surface response metadata → runtime lighting capture.
- **HUD or touch presentation:** safe-area/container contract → authored vector/raster assets → pressed/cooldown/focus states → 16:9, 16:10, 4:3, and ultrawide captures.
- **VFX:** readability brief → bounded particle/decal/audio ownership → reduced-flash and lower-quality variants → combat and cleanup captures.

Image generation is for concepts and reference sheets, not uncontrolled final atlases. Blender owns repeatable proportions, camera, lighting, orientation, animation, and final sprite renders. Original hero characters, weapons, jokes, signage, and landmarks must not be assembled from unreviewed third-party assets.

## Build reproducibly

1. Preserve editable sources under `assets/source/`; store runtime-ready assets only under the established `assets/models`, `assets/materials`, `assets/sprites`, or `assets/ui` roots.
2. Use deterministic scripts for Blender export, atlas packing, and capture. Record Blender version, render engine, camera, lighting, frame vocabulary, atlas grid, feet baseline, and output sizes.
   - Directional sprites use one fixed cell grid, consistent transparent padding, and one feet baseline across every state and direction.
   - Record opaque-frame height and intended world height, then set `Sprite3D.pixel_size = intended_world_height / opaque_frame_height`. Never tune enemy scale separately by viewport or device.
   - Validate intended silhouette height against collision height and capture it at desktop and 1024×768 tablet viewports.
3. Use Material Maker project files as the material source of truth. Export Web-safe maps at the minimum resolution that survives the canonical views. Do not bake field markings, labels, or unique grime into tiling base materials.
4. Add mipmaps, compression, alpha, filter, LOD, collision, and distant-animation metadata deliberately. Do not rely on editor defaults.
5. Update `docs/ASSET_MANIFEST.md` in the same change with origin, authoring method, license, source path, runtime path, version/tooling, hashes where required, and prohibited-IP review.
6. Keep collision/navigation contracts separate from presentation replacement so an art pass cannot silently change progression.

## Validate in Godot

1. Import with Godot 4.7 stable and fix every attributable parser/import error.
2. Run the lowest-level asset, animation, material, UI, or presentation contract first.
3. Use `tools/visual_quality/capture.sh` and `tools/visual_quality/compare.sh` for the affected canonical views. Visual differences are review prompts; missing, blank, transparent, malformed, or wrong-size captures are hard failures.
4. Capture deterministic motion at 30, 60, and 120 rendered FPS. Run the 10-TPS diagnostic for movement, weapon, enemy, teleport, and knockback work; authoritative transforms remain in physics ticks and reset interpolation after teleports.
5. Inspect the real runtime through Godot MCP when available. Editor/process output remains authoritative over MCP summaries.
6. Confirm temporary nodes, particles, decals, timers, audio voices, and animation players return to baseline after reset.

## Validate the packaged Web build

1. Package a fresh Web artifact; never profile an editor run or stale export.
2. Use Chrome DevTools MCP with the isolated profile for loading waterfall, console, long tasks, frame stalls, heap growth, tablet emulation, and screenshots. Disable usage statistics and CrUX collection in its local MCP configuration.
3. Record ordinary-combat stalls over 100 ms, shader/main-thread stalls, download size, memory before/after reset, and viewport/touch evidence.
4. If the MCP is unavailable in the current task, record that a Codex restart is required and leave Web-trace acceptance open. Do not replace trace evidence with inference.

## Review and approve

1. Generate a side-by-side packet with before, candidate, difference image, metrics, motion clips, performance delta, provenance, and known risks using [review-packet.md](references/review-packet.md).
2. GPT-5.6 checks composition, hierarchy, landmark/enemy readability, palette, material consistency, motion, UI safe areas, and stylistic cohesion.
3. A human retains final ownership of taste, comfort, humor, touch ergonomics, photosensitivity, and whether the new work is clearly better.
4. Approve baselines explicitly with `tools/visual_quality/capture.sh --approve`; never overwrite them implicitly.
5. Scale the technique to another zone or asset only after the pilot has green functional/import/performance gates and an explicit visual-review disposition.

## Stop conditions

Stop and report rather than integrating when any of these is true:

- gameplay collision, navigation, scale, or progression changed without a named contract;
- an asset lacks editable source or provenance;
- a hero asset is inconsistent across directions or required animation states;
- critical silhouettes, HUD, captions, or touch controls fail at 1024×768;
- the Web profile regresses beyond its quality budget without evidence-backed disposition;
- captures contain blank/transparent regions, missing materials, missing sprites, or invalid dimensions;
- a generated or third-party asset introduces protected branding, copied layouts, unclear licensing, or private data;
- a development bridge, local path, debug capture scene, or source working file enters a release artifact;
- human-only visual/device conclusions are being represented as automated evidence.
