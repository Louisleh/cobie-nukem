# Blender asset-production pipeline

## Security boundary

Blender 5.1.2 and the pinned `blender` MCP are local development tools. The MCP binds to `localhost:9876`, runs with `DISABLE_TELEMETRY=true`, and may execute arbitrary Python. Poly Haven, Sketchfab, Hyper3D, Hunyuan, and other external asset services remain disabled unless the owner authorizes one specific licensed import. No MCP code, credentials, or listener may enter a game export.

## Source and runtime ownership

- Editable sources: `assets/source/blender/` (excluded from Godot import by `.gdignore`).
- Runtime models: `assets/models/` as GLB with embedded project-original materials.
- Rendered sprite experiments: `assets/sprites/experiments/`.
- Every source and runtime result requires an exact `docs/ASSET_MANIFEST.md` entry.
- One Blender unit equals one meter; +Z is up in Blender and the exporter converts to Godot's +Y-up glTF convention.
- Object names ending in `-colonly` become collision-only nodes through Godot's scene importer.
- Pivots sit at the intended placement origin; level geometry is authored around a ground plane at zero.

## Reproduce the production pilot

```bash
/Applications/Blender.app/Contents/MacOS/Blender --background \
  --python tools/blender/build_asset_pipeline_pilot.py
/opt/homebrew/bin/godot --headless --path . --editor --quit
/opt/homebrew/bin/godot --headless --path . \
  --script res://tests/unit/asset_contract_test.gd
```

The script builds one project-original source scene and exports:

- Salmon Creek bench/barrier prop family;
- modular maintenance-tunnel segment;
- explicit LOD0/LOD1/LOD2 crate study;
- Fetch-charge pickup/weapon presentation pedestal;
- original Rain City future-level landmark;
- four-direction sentry frames plus a distinct hit-reaction frame.

The gallery at `scenes/debug/production_asset_gallery.tscn` is a disposable inspection scene, not campaign content. The contract test verifies Godot import, visible part vocabulary, explicit collisions, LOD naming, sprite resolution, and distinct reaction presentation.

## Production budgets

- Prefer one material atlas or a small shared palette per kit.
- Use explicit collision proxies rather than render-mesh collision for repeated props.
- Keep small props below roughly 1,000 triangles unless profiling justifies more.
- Define LOD range ownership in a Godot wrapper or imported metadata before a pilot becomes production content.
- Verify the Compatibility renderer and Web export after import.
- Capture native and packaged-Web evidence before promoting a pilot into a mission.

The current pilot proves the path and style vocabulary; it does not automatically promote the sentry, pedestal, tunnel, or Vancouver beacon into playable campaign content.
