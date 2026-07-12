# Cobie Nukem 0.5.0-rc1 Release Evidence

Status: **LIVE — 2026-07-12**

## Identity

- Runtime: `0.5.0-rc1`
- Gameplay/UI revision: `f505679`
- Build ID: `2026-07-12-phase12-public-rc`
- Source integration: <https://github.com/Louisleh/cobie-nukem/pull/1>
- Website deployment: <https://github.com/Louisleh/louislehmann-site/pull/87>
- Public landing: <https://www.louislehmann.fyi/games/cobie-nukem/>
- Public game: <https://www.louislehmann.fyi/games/cobie-nukem/play/>

## Shipped scope

- Story, Classic, and Mayhem player-facing difficulty selection.
- Full pickup and aim-assist difficulty multiplier consumption.
- Save-schema v2 with legacy migration and malformed/future-save handling.
- Scene-transition, checkpoint, pause, touch-input, kill-plane, boss-summon, and enemy-drop hardening.
- Save-schema and adversarial state regression suites.
- Locked Rain City Run / Vancouver Waterfront content-pipeline proof.
- Tablet-fit correction for the expanded level-selection screen.

## Verification

- PR #1 validation passed on GitHub before merge.
- Native macOS Godot 4.7 `QA_EXPORTS=1 bash tools/release_validate.sh` passed after integration and again after the final tablet layout correction.
- The gate covered 55 scenes, 55 resources, two content manifests, the complete Salmon Creek route, save-schema tests, adversarial state tests, Web export, and unsigned macOS export.
- The release gate now fails when a Godot test emits an engine `ERROR:` even if Godot exits zero; this caught and fixed pre-tree pickup difficulty lookup during review.
- Website build, 30 public routes, 31 private guards, repository hygiene, GitHub checks, and Vercel deployment passed.
- Production metadata returned revision `f505679`; the production PCK returned HTTP 200 with cache revalidation headers.
- Public Web boot and the difficulty selector were visually verified at 1024×768 with forced touch mode. Header, selector, mission cards, and footer controls fit without clipping.

## Remaining human gates

- Physical iPad Safari thumb reach, sustained performance, heat, audio unlock, app switching, and real-network behavior.
- Story/Classic/Mayhem feel and balance playtest.
- End-to-end checkpoint Continue verification on device, including Mayhem restoration and a hand-corrupted save.
