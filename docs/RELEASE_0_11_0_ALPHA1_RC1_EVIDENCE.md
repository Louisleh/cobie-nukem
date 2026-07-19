# `0.11.0-alpha.1-rc1` release evidence

Date: 2026-07-18

Engine/export templates: Godot `4.7.stable.official.5b4e0cb0f`

Runtime feature revision: `3c2de29`

Build ID: `2026-07-18-doghouse-progression-rc1`

## Automated evidence

- Full non-export `bash tools/release_validate.sh`: pass.
- Save schema v6 migration, corrupt/future rejection, atomic writes, campaign/checkpoint isolation, collection idempotency, wallet/purchase/equip rules, result calculation, challenge evaluation, backup-code integrity, Off-Leash mode, and owned-loadout restoration: pass.
- Load/import smoke: 79 scenes and 183 Resources.
- Content/architecture/asset-IP validation: five mission manifests; all production controllers remain within their responsibility limits.
- Five-mission gauntlet: 1,200 deterministic route simulations and 1,000 checkpoint restores.
- Shared soak: 100 routes, 100 checkpoints, 100 twin-stick/focus cancellations, 500 weapon transitions, and 100 temporary-effect cycles.
- Doghouse rendered natively and at 1024×768 with all stations, wallet, records, controls, and content inside the safe layout.
- Independent `gpt-5.3-codex-spark` review: no Blocker or Critical finding; one Major checkpoint-ownership finding fixed and regression-tested.

## Export and artifact evidence

Pending the final `QA_EXPORTS=1` package run and public byte-identity verification.

## Human-only gates

- Economy/reward feel, collectible visibility and route placement, replay motivation, challenge balance, and Off-Leash pacing require human play.
- Physical iPad Safari touch/storage/thermal/audio and target-Mac/Safari/Chrome full routes remain open.
- Levels 2–5 remain explicit `BETA`; macOS is unsigned/unnotarized and working-title clearance is separate.
