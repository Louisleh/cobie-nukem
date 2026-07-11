# Mobile Public Release Evidence

Status: **LIVE — 2026-07-11**

## Release identity

- Runtime: `0.4.0-mobile-rc1`
- Gameplay/export revision: `0dad139`
- Build ID: `2026-07-11-public-ipad-rc`
- Public landing page: <https://www.louislehmann.fyi/games/cobie-nukem/>
- Public game: <https://www.louislehmann.fyi/games/cobie-nukem/play/>
- Website release PR: <https://github.com/Louisleh/louislehmann-site/pull/86>

## Automated evidence

`QA_EXPORTS=1 bash tools/release_validate.sh` passed after the final export changes:

- parser/import validation;
- core, input, combat, enemy, UI, gameplay-foundation, and mobile-control unit suites;
- integrated combat/persistence/input/aim/enemy/secret/exit contracts;
- complete Episode 1 route, gate, secret, pacing, encounter, and finale contract;
- all 54 scenes and 45 resources loaded in smoke tests;
- headless performance smoke: 7.037 ms average, 36.104 ms maximum over 180 frames;
- asset/IP scan and content-manifest validation;
- final Web and unsigned macOS exports.

The mobile-control suite simulates independent simultaneous touch identifiers for movement and aiming. The public route was additionally booted with deterministic `?touch=1` at a 1024×768 tablet viewport.

## Public-host evidence

- Production landing returned the expected `0dad139` revision.
- Production game booted to the normalized title screen at 1024×768.
- `index.wasm` returned HTTP 200 with `Content-Type: application/wasm`.
- Game assets use `max-age=0, must-revalidate` to prevent stale build caching.
- Website build, 30-public-route/31-private-guard verification, repository hygiene, GitHub checks, and Vercel deployment all passed.

## Release notes and remaining human checks

- Audit screenshots and handoff evidence are excluded from exports; the final Web directory is approximately 46 MB and its playable PCK is approximately 8 MB.
- The deterministic desktop-browser tablet pass verifies layout, boot, and touch-control wiring. A physical iPad Safari feel pass is still required for thumb reach, sustained frame pacing, heat, audio-unlock behavior, and real network conditions.
- First-load time depends on connection speed; the landing page sets that expectation.
- Continue logging subjective tuning feedback against `docs/MANUAL_UX_CHECKLIST.md` and the phased roadmap.
