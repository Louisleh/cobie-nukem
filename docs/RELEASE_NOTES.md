# Release Notes — 0.6.0-alpha.4 Agentic Overhaul

Built on 2026-07-13 with Godot `4.7.stable.official.5b4e0cb0f`. Gameplay/runtime feature revision: `67a0ee4`.

## Player-visible changes

- Startup now keeps the explicit WARMING state until combat audio and hidden material variants are ready, reducing first-hit/first-projectile hitches.
- Death/retry presentation is reliable in the real routed mission; a typed fallback failure found by native capture is fixed.
- Enemy bolts use a bounded pool, preventing repeated allocation during ranged encounters and the Walker fight.
- Pawstol burst timing, muzzle cleanup, telegraphs, pickup respawns, death effects, and Walker follow-ups are owned by their actors and cannot resume into the next scene.

## Production improvements

- Reproducible Blender 5.1 pipeline pilot: Salmon Creek prop family, modular tunnel piece, three-level LOD crate, Fetch pedestal, Rain City beacon, and four-direction/hit sentry frames.
- Exact source/runtime provenance, hashes, collision and LOD contracts, plus native and Web gallery evidence.
- One selected Godot MCP and one telemetry-disabled Blender MCP are governed by startup/removal/security documentation and export contamination checks.
- Rendered 1080p profiles cover menu, field, lab, tunnels, Walker arena, and victory with p95/p99, draw calls, objects, nodes, and memory.
- Native route evidence covers seven distinct states from opening field through death and victory.

## Validation boundary

- Automated functional, soak, native-rendered, macOS export, and packaged-Web gates are required for this candidate.
- One isolated 224 ms Walker attack sample remains tracked even though every zone's p95 is below 33 ms and p99 below 100 ms.
- Physical iPad Safari comfort/thermal/audio, final difficulty feel, photosensitivity, mix quality, and a target-Mac human playthrough remain explicit human gates.

The macOS ZIP is unsigned and unnotarized. The working title still requires clearance before commercial distribution.
