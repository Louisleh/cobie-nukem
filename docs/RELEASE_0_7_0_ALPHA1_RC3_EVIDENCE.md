# Rain City Run `0.7.0-alpha.1-rc3` release evidence

**Built:** 2026-07-17  
**Godot:** `4.7.stable.official.5b4e0cb0f`  
**Runtime feature revision:** `ba7c449`  
**Stamped candidate:** `4a650318dc0ac9d1016c316d9a8cb77ca69c5b39`  
**Build ID:** `2026-07-17-startup-stability-rc3`

## Scope

- Explicit mission selection followed by explicit Start.
- Trusted Web pointer-lock handoff and one-click recovery.
- Proactive `R` reload with HUD and authored audio lifecycle feedback.
- Public inclusion of the already-integrated portrait/iPad, sign orientation, connector-surface, interaction-boundary, and Walker-finale fixes.

## Automated and packaged-browser gates

- `QA_EXPORTS=1 bash tools/release_validate.sh`: PASS.
- Parser/import, unit, integration, route, adversarial, content, smoke, performance, architecture, provenance/IP, Web, and Universal macOS export gates: PASS.
- Soak evidence: 100 routes, 100 checkpoint cycles, 100 twin-stick cancellation cycles, 500 weapon transitions, 100 effect cycles, and 100 convoy cycles: PASS.
- Packaged cache-keyed Chrome at 1024×768: normalized title, selection-only card activation, explicit Start, immediate pointer capture, one-click recapture, proactive partial-magazine reload, and clean game-origin console: PASS.
- Human physical-iPad, Safari, target-Mac full route, feel, pacing, art, mix, humor, and photosensitivity gates: OPEN.

## Artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `cobie-nukem-0.7.0-alpha.1-rc3-itch.zip` | 35,790,399 | `422d57137d327597d974e80511e135b987ff6b60545e9c3e47f8c11f6a370221` |
| `cobie-nukem-0.7.0-alpha.1-rc3-macos-unsigned.zip` | 85,155,304 | `976d6172336bb684392bcd7d2e2951837ccc6af7e6cf0158b6cb2d62810a7066` |
| `index-0.7.0-alpha.1-rc3.pck` | 26,282,532 | `d4c763ae8e3a74fcd2671992aad520b8866cb01d5dbbcdd6db15f00f2359d2cb` |

## Publication record

Source PR/integration, GitHub prerelease, website PR/deployment, public runtime identity, and downloaded PCK byte verification are appended after the publication transactions complete.
