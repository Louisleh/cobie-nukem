# Checkpoint runtime contract

- `RainCityCheckpointState.consume_requested()` validates and returns checkpoint payload/position; it does not restore progression before mission bootstrap.
- A mission controller calls `GameState.begin_run(level_id)` first, then `RainCityCheckpointState.restore_progression_state(payload, game_state)`, then restores mission route/objective/encounter state and finally player state after spawn.
- Rain City/Vancouver, Mount Hood, and the shared Moon/Ventura biome controller must preserve that order. A new mission may reuse the shared helper but may not reintroduce a restore-before-reset path.
- Restore regressions must cover pending compliance tags, run mode, route/checkpoint identity, objective and encounter snapshots, secrets, health/armor, selected weapon, and ammo. Automated coverage does not replace a manual continue/playthrough gate.
- Checkpoint writes are rejected with `ERR_BUSY` while a boss-zone encounter or the Rain City convoy is active. Until WCB-007 owns a complete phase snapshot, continuing resumes from the last pre-boss checkpoint into a fresh deterministic boss; no partial boss health/phase state is persisted.
- The unit regression executes the real Mount Hood and shared biome initialization transaction and requires `consume -> progression -> mission runtime -> mission restore -> player`.

## Regression evidence

```bash
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/unit/rain_city_checkpoint_state_test.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/mission_checkpoint_progression_integration_test.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/five_mission_gauntlet_test.gd
```
