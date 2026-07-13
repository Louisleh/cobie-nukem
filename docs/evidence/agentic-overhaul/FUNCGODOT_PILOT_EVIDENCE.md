# FuncGodot/TrenchBroom pilot evidence — 2026-07-13

This disposable pilot tested whether the optional brush workflow is ready to become a Cobie production dependency. It is not.

## Pinned inputs

- FuncGodot: `d68960dfce8b99f0dbc571abfc3fd9c396126b76`
- Example project/map: `d9a02b846d1de0fcca338604d8631da282112ba7`
- TrenchBroom: 2026.1
- Godot: `4.7.stable.official.5b4e0cb0f`

The source example exercises world geometry, collision, movable gate brushes, triggers, actors, cameras, lights, and elevation. It is a proxy arena, not a Cobie-authored level.

## Measured results

| Contract | Result |
| --- | --- |
| scripted map rebuild | 238–289 ms |
| generated tree | 52 nodes |
| mesh instances | 8 |
| collision shapes | 11 |
| leaf point entities | 16 |
| packed generated scene | 669,812 bytes |
| collision-derived nav bake | 8 vertices / 4 polygons |
| two-run semantic diff | stable except generated `unique_id` values |
| Compatibility Web export | passed |
| Web PCK | 1.1 MB; SHA-256 `a50c8db6b83e8b81f7b68576776be4a9ffd5c9c630aa5b769f40634ce6f536d1` |
| Web WASM | 38 MB engine artifact |

An initial rebuild with UV2 generation under the dummy headless renderer emitted RID errors. The deterministic runner disabled runtime UV2 generation, flushed the old generated children for one frame, and then rebuilt cleanly. This is an important workflow constraint, not a hidden success.

## Adoption decision

The geometry/collision/nav/export fundamentals work, but the pilot fails the production-dependency gate because:

1. it has no Cobie FGD definitions for objectives, encounter/wave IDs, critical pickups, enemy roles, checkpoints, secrets, audio zones, or surface identity;
2. node `unique_id` churn would create noisy generated-scene diffs;
3. the navigation bake is too small to prove multi-zone reachability or recovery;
4. the all-resources Web export bundled FuncGodot tooling into the PCK;
5. no ownership rule yet prevents hand edits to generated output.

Therefore Salmon Creek stays Godot-native. A future Vancouver blockout may use this workflow only in a disposable branch and only after a generated-geometry-only export filter, stable-ID normalization, and Cobie-specific FGD contract exist.
