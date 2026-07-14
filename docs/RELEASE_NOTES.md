# Release Notes — 0.6.0-alpha.8 Rain City Forge

Built on 2026-07-14 with Godot `4.7.stable.official.5b4e0cb0f`. Packaged source: `b566dce`; runtime feature revision: `06fa2d1`.

## Player-visible changes

- Salmon Creek gains an original low-poly production material and landmark kit plus manifested 8×4 directional/reaction atlases for Compliance Hound and Walker.
- Mission-scoped adaptive exploration, tension, combat, boss, victory, and zone ambience now reacts to real gameplay events; Cobie secret/victory moments trigger original nonverbal barks.
- Touch HUD adds a dedicated `ALT` secondary-fire button while preserving independent move/aim joystick ownership and cancellation.
- Campaign progress is separate from save-v4 checkpoints, with deterministic migration and route restoration.
- Vancouver Waterfront is a complete five-zone internal production preview with twenty interactions, four secrets, Umbrella Shield Enforcers, and a three-stop citation convoy. Its public mission card remains intentionally locked.

## Production improvements

- Shared mission runtime, route, spawn, presentation, audio, campaign, shield, and moving-set-piece contracts reduce mission-specific coupling; Salmon Creek's controller is 445 lines.
- The release gate directly exercises the new Alpha.8 Resources, Vancouver route/content/host, Continue rehydration, departure gating, shields, convoy, campaign saves, audio, and touch secondary fire.
- A release-gate-discovered mission-audio teardown race was fixed by restoring single ownership to normal Godot child teardown; 20 consecutive performance smoke runs were leak-free afterward.
- An exact `gpt-5.3-codex-spark` independent read-only review found no Blocker, Critical, or Major defects. GPT-5.6 retained integration and release ownership.

## Validation boundary

- Full native/Web export validation passed with 100 Salmon routes, 100 checkpoint cycles, 100 touch cancellations, 500 weapon transitions, 100 effects, and 150 staged convoy reset scenarios.
- Native 1080p Compatibility gameplay p95 was 16.907–18.183 ms and p99 17.339–24.872 ms; static memory remained below 78 MB. One isolated tunnel maximum reached 94.584 ms.
- The packaged landing and cache-keyed PCK/WASM/JS assets return successfully over HTTP and identify Alpha.8. Browser-control initialization failed in the local automation host, so no new Alpha.8 interactive browser claim is made from that attempt.
- Physical iPad Safari comfort/thermal/audio, full human playthrough, boss/difficulty/interaction feel, art, mix, humor, and photosensitivity remain human-only gates.
- The macOS ZIP is unsigned and unnotarized. The working title still requires clearance before commercial distribution.

## Artifacts

- `cobie-nukem-0.6.0-alpha.8-itch.zip` — 33,403,347 bytes; SHA-256 `2c54836bdb32b7361e6c5cb5633d24e78c7f622e30c2875e06934b28c55e59ad`.
- `cobie-nukem-0.6.0-alpha.8-macos-unsigned.zip` — 82,768,233 bytes; SHA-256 `3dd13a7cc3c8ae99417d2d6c9ccd034358c19fdaa4da52c36e70c9c6362894ae`.
- Web PCK — 23,797,272 bytes; SHA-256 `a6ac552600d488963b83fa69a235b51aaecb70dd11b56a5b98f082407114debc`.

## Integration

- Source PR, merge commit, prerelease, website deployment, and public PCK verification are recorded after successful publication in `docs/PHASE_ROADMAP_PRD.md` and `docs/TEST_EVIDENCE.md`.
- Live route: <https://www.louislehmann.fyi/games/cobie-nukem/>.
