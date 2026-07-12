# Fable Implementation Pass Handoff — 2026-07-12

Continuation point for Codex after the Phase 1–2 implementation and stabilization pass on `fable/phase12-next-pass` (base: `a2b9ea7`).

## Executive summary

This pass delivered the four highest-leverage remaining Phase 1–2 items: a player-facing Story/Classic/Mayhem difficulty selector, full consumption of every `DifficultyProfile` field, versioned-and-migrated save payloads, and a validated Mission 2 (Vancouver Waterfront) content-pipeline production proof. A code-led bug hunt fixed eight classes of state-transition defects (stale async callbacks, stuck synthetic touch input, pause-over-death/victory, unlistened enemy drops, kill-plane vs. respawn protection, stale boss summons, missing proximity-interaction group members, stale post-victory checkpoints). Every fix carries regression coverage; a new adversarial integration suite and a save-schema unit suite joined the release gate. The complete validation suite, including fresh Web and macOS exports, passes. **The public website repository and live release were not touched.**

## Environment note

This pass ran in a Linux container against the new GitHub source of truth `Louisleh/cobie-nukem` (cloned at `a2b9ea7`), using Godot 4.7.stable official (`5b4e0cb0f`) downloaded from the official CDN, with export templates 4.7.stable. No macOS hardware was available: nothing in this pass was validated on a physical Mac or iPad, and no human playthrough occurred.

## Features implemented

1. **Difficulty selection UI** (`a3c9281`) — toggle row on level select between the mission panel and course cards. Labels, tooltips, and the tuning blurb derive from the `DifficultyProfile` resources (no duplicated data in UI scripts). Classic is default; invalid IDs are rejected by `GameState.select_difficulty`; keyboard/controller focus neighbors wired (cards → difficulty → play/back); mouse hover and touch presses work through standard `Button` behavior; selection never resets an active run or deletes saves. `GameState` gained `difficulty_options()` and a cached `_profile_for()`.
2. **Complete difficulty consumption** (`ccd96c1`) — audit result for all six exported fields:
   - `enemy_health/damage/speed/aggression_multiplier`: already consumed by `EnemyAgent` (verified).
   - `pickup_amount_multiplier`: now scales HEALTH/ARMOR/AMMO pickups via `scaled_pickup_amount`/`scaled_pickup_ammo` (ammo never rounds below 1).
   - `aim_assist_strength`: now scales the auto-aim correction budget via `aim_assist_scale()`, normalized against the Classic baseline (0.65) so existing `AutoAimTuning` resources stay authoritative on Classic; Story ≈1.38×, Mayhem ≈0.69×.
   - Intentionally deferred (documented in PRD §12): scaling ZOOMIES/SQUEAKER durations and FULL_RESTORE.
3. **Save-schema v2 with migrations** (`656c335`) — envelope `{version, saved_at, payload}` with documented history; unversioned bare payloads read as v0; v0/v1 checkpoint-shaped payloads gain `difficulty_id: "classic"`; future versions rejected cleanly and left on disk. `CheckpointPayload.sanitize()` is the single gate between persisted data and runtime state (boot Continue button, `_continue_game`, `_apply_requested_checkpoint`); it type-checks every field, drops unknown keys, validates difficulty against `GameState.DIFFICULTY_PATHS`, and returns `{}` when no resumable scene can be named. Checkpoints now persist the selected difficulty; Continue restores it.
4. **Mission 2 production proof** (`3a606fa`) — `vancouver_waterfront_manifest.tres` (level id `episode_1_vancouver_waterfront`), four-objective prerequisite chain, five per-zone placeholder encounters using existing enemies, a non-public graybox scene, and the `rain_city_card` updated to the Rain City Run identity while staying locked/unroutable. Validates in CI alongside Salmon Creek (2 manifests). Asset/landmark list recorded in `docs/CONTENT_AUTHORING.md`.

## Bugs found and root causes

| # | Defect | Root cause | Fix (commit) |
| --- | --- | --- | --- |
| 1 | Opening-grace callback could fire into a freed level; checkpoint restart stacked a second, earlier grace activation; grace kept counting while paused | `get_tree().create_timer(12.0)` outlives the scene and ignores pause by default | Level-owned one-shot `Timer` node, restarted on reset (`61ceaad`) |
| 2 | Finale used `await create_timer(1.2)`; quitting to menu during the delay resumed a coroutine on a freed level | await on `SceneTreeTimer` | Level-owned `CompletionTimer` + `_finalize_level_completion` (`61ceaad`) |
| 3 | Enemy death linger resumed `await` on freed instances after scene change/encounter reset | same class | bound `queue_free` connection, auto-dropped on free (`61ceaad`) |
| 4 | Walker EXPOSED_CORE follow-up bolt lambda could execute against a freed walker after reset | lambda capture is not auto-disconnected | bound `_fire_followup_bolt` method (`61ceaad`) |
| 5 | Respawning pickups resumed `await` on freed instances | same class | bound `_respawn` connection (`61ceaad`) |
| 6 | Checkpoint reset of the walker arena left walker-summoned drones alive at the arena | summons never entered the encounter runner's actor list | `boss_summons` group cleared during reset (`61ceaad`) |
| 7 | Finishing the level left the mid-level checkpoint, so the menu offered a misleading Continue into a completed run | no completion-side cleanup | finale claim deletes the checkpoint slot (`61ceaad`) |
| 8 | Pause menu could open over the death or victory screen (Esc or browser focus loss), double-stacking UI and re-capturing the mouse | no suppression state; focus-loss auto-pause ignored game phase | `_suppressed` flag driven by death/victory/restart + `phase == PLAYING` guard (`61ceaad`) |
| 9 | A finger held on FIRE across a scene change or app switch left `fire_primary` latched forever | synthetic `InputEventAction` presses live in the global `Input` singleton; controls freed without releasing | `release_all()` on `NOTIFICATION_EXIT_TREE` and `NOTIFICATION_APPLICATION_FOCUS_OUT` (`61ceaad`) |
| 10 | Switches, golden ball, breakable wall, and ball return were unreachable through the proximity-interaction fallback touch players rely on | missing `interactables` group membership (only doors/signs had it) | group joins in `_ready` (ball joins on `enable_for_boss` so the hidden ball cannot answer the use key early) (`61ceaad`) |
| 11 | Falling out of bounds within the 1.5 s respawn protection left the player falling through the void until it expired | kill plane routed through combat damage, which invulnerability blocks | kill plane clears `invulnerable_remaining` first (`61ceaad`) |
| 12 | Compliance hound's authored `drop_id = leather_padding` never spawned anything | `drop_requested` had no listener anywhere | level spawns the matching pickup scene; warns loudly for unknown drop ids (`7dee6c2`) |
| 13 | Legacy/corrupt/future save files were all silently discarded as one case; difficulty was lost on Continue | `load_slot` rejected everything but exact version 1; checkpoint payload never carried difficulty | save-schema v2 + `CheckpointPayload` (`656c335`) |

## Tests added

- `tests/unit/save_schema_test.gd` (new, in release gate): new save creation, current-version round trip, unversioned legacy payload, v1 migration, non-checkpoint payloads untouched by migration, missing fields, wrong types, non-finite positions, invalid difficulty, truncated/non-dictionary JSON, future-version rejection with file preserved, canonical-shape/unknown-key drops.
- `tests/integration/adversarial_state_test.gd` (new, in release gate): grace-timer lifecycle across checkpoint restarts, double finale claims completing once + checkpoint clear, triple fall-death/restart loop, pause suppression during death/victory incl. focus loss, synthetic touch release on focus loss and tree exit, weapon-switch spam during reload (no ammo duplication), pause freezing reload and grace windows, complete level lifecycle twice in one process, authored enemy drop spawning.
- `tests/unit/ui_scene_test.gd`: difficulty-selector contract (three resource-driven buttons, Classic default pressed, focusable, presses update GameState, blurb populated, selector use never deletes saves).
- `tests/unit/gameplay_foundation_test.gd`: pickup/ammo/aim-assist scaling per profile, selection API (invalid rejection, ordering, caching, run-stats recording), Mission 2 manifest shape and locked-card contract.

## Commands run and results

All on Godot 4.7.stable.official.5b4e0cb0f (Linux headless), repo root:

- `QA_EXPORTS=0 bash tools/release_validate.sh` — **PASS** (all 13 suites incl. the two new ones; smoke: 55 scenes and 55 resources; content validation: 2 manifests).
- `QA_EXPORTS=1 bash tools/release_validate.sh` — **PASS**; Web export (`builds/web/index.html` + wasm/pck) and unsigned macOS export (`builds/macos/CobieNukem.zip`) produced with 4.7.stable export templates. `builds/web` contains no service worker, offline page, or PWA manifest (PWA remains disabled in `export_presets.cfg`).
- Individual suites were run repeatedly during development; final states all PASS.

## Exports and packages

Web and macOS exports were regenerated locally only as validation evidence (`builds/` is gitignored). **No release package was produced** (`tools/package_release.sh` not run) and **nothing was deployed**: the public site still serves `0.4.0-mobile-rc1` / `0dad139`. The next public release must re-export from CI or the owner's Mac and follow `docs/BUILD_AND_RELEASE.md` + the website copy step.

## Remaining known issues / risks

- Human validation gaps are unchanged and listed in `docs/KNOWN_ISSUES.md`; this pass adds the difficulty-feel playtest (Story family-feel, Mayhem pressure) to that list. No physical iPad or target-Mac validation was performed here.
- The difficulty blurb line is dense at the 320×180 design resolution on very narrow phones; it autowraps but was only verified at desktop and iPad-landscape proportions in scene layout, not on hardware.
- `_physics_process` route fallback scan (FA-11) remains accepted technical debt for Mission 2 route architecture.
- The harbour-pier "citation convoy" encounter is an explicit placeholder pending multi-wave schema support.

## Deferred nice-to-haves

- Persist last-selected difficulty across app restarts (e.g., via SettingsManager).
- Difficulty scaling for temporary-effect durations and FULL_RESTORE pickups.
- Objective-snapshot persistence into checkpoint saves (now unblocked by save-schema v2).
- Multi-wave/reinforcement encounter schema; objective-list HUD; editor authoring plugin.

## Assumptions

- `aim_assist_strength` semantics: interpreted as strength relative to the authored Classic baseline (0.65) so Classic gameplay is byte-identical to the previous tuning; see `DifficultyProfile.AIM_ASSIST_BASELINE`.
- Deleting the checkpoint on level completion is the intended Continue semantic (a finished run should not resume mid-level).
- The Mission 2 identity follows `docs/CONTENT_AUTHORING.md` (`episode_1_vancouver_waterfront`, "Rain City Run") rather than the older "Rain City Kennel" card copy.

## Commits on `fable/phase12-next-pass`

1. `a3c9281` feat: add player-facing difficulty selection to level select
2. `ccd96c1` feat: consume pickup and aim-assist difficulty multipliers
3. `656c335` feat: version and migrate save payloads
4. `61ceaad` fix: harden gameplay state transitions against stale async and stuck input
5. `1422646` test: add adversarial progression coverage
6. `3a606fa` feat: author Mission 2 Vancouver Waterfront production proof
7. `7dee6c2` fix: honor authored enemy drop_id contracts and drop dead UI helper
8. `ef425cc` docs: reflect difficulty, save-schema, and Mission 2 status in Phase 1-2 records
9. `19343ef` chore: stop the editor importing export artifacts under builds/
10. (this handoff commit)

Pull request: <https://github.com/Louisleh/cobie-nukem/pull/1> (draft, targeting `main`).

## What Codex should verify next

1. On the owner's Mac: `QA_EXPORTS=1 bash tools/release_validate.sh` with the homebrew Godot, then a human playthrough on each difficulty — confirm Story feels family-friendly, Mayhem meaningfully harder, and the selector is comfortable on iPad touch (button sizes, blurb readability).
2. Continue-flow behavior end to end on device: select Mayhem → reach the lab checkpoint → quit → Continue → confirm difficulty and position restore; corrupt `user://saves/checkpoint.json` by hand and confirm boot stays clean and Continue disables.
3. Confirm the death → focus-switch → retry path on iPad Safari never opens the pause menu over the death screen and never latches touch fire.
4. When starting Mission 2 production, build on the validated skeleton (`vancouver_waterfront_manifest.tres`) instead of new IDs; the graybox is disposable.
5. Before the next public release: re-export, re-package, and copy to the website repo per `docs/DEPLOYMENT.md`; this pass intentionally did not.

## Website confirmation

The `Louisleh/louislehmann-site` repository, its generated `games/cobie-nukem` files, and the live release at <https://www.louislehmann.fyi/games/cobie-nukem/> were **not modified or deployed** by this pass.
