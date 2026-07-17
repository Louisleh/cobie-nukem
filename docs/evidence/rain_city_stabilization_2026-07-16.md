# Rain City stabilization evidence — 2026-07-16

## Scope

Focused `0.7.0-alpha.1-rc2` stabilization and bug-hunt pass for Godot process reliability and Level 2 progression, persistence, physics, navigation, enemy behavior, pickups, secrets, performance, and release readiness.

## Godot crash diagnosis

- Recent macOS crash reports identified Godot 4.7 launched from Codex.
- Two orphaned `vancouver_mission_host_test.gd` processes had remained alive with blocked output pipes for roughly two hours.
- Four duplicate Godot MCP Node servers and an old GUI editor process were present against the same project.
- Stale processes were terminated before validation. Three duplicate MCP Node hosts respawned with agent sessions, but no competing Godot child remained; release testing used the serialized CLI runner only.
- No new Godot crash report appeared during the guarded focused, soak, rendered-profile, or complete non-export release runs.

## Implemented controls

- `tools/run_godot_safe.sh`: atomic per-project lock, stale-lock recovery, bounded timeout, descendant cleanup, unique log path, isolated test HOME/save root, and explicit opt-in for the real shader-cache HOME.
- `tools/tests/run_godot_safe_test.sh`: concurrency, timeout, lock release, and HOME-isolation contracts.
- `tools/release_validate.sh`: every import, test, and export invocation now uses the guarded runner.
- `SaveManager`: honors `COBIE_TEST_SAVE_ROOT` without changing production `user://saves` behavior.

## Level 2 fixes

- Visible encounter gates keep each combat wave authoritative and prevent fragmented route skips.
- Production navigation bake is tested once; mission-host fixtures disable five redundant bakes.
- Checkpoint/campaign writes are transactional, failures are retryable, and secret autosaves are idempotent.
- Umbrella shields now own front/rear/open/broken damage behavior.
- Compliance Gull movement and CombatPressure ownership have one physics authority.
- Hound and Groundskeeper direct attacks require clear line of sight and apply difficulty damage.
- Unreachable ground enemies use bounded local recovery or terminal defeat instead of blocking progression.
- Pickup collisions stay grounded while only visual children animate.
- Projectile interpolation resets after authoritative launch placement.
- All four secrets grant distinct, checkpoint-safe rewards; the terminal reward removes one finale reinforcement.
- Rain City orchestration was split into mission assembly, completion flow, and secret policy; every production script passes the 500-line architecture gate.

## Automated results

- Focused enemy, navigation, Gull, Umbrella, persistence, production route, and mission-host suites: pass.
- Complete non-export release matrix: pass.
- Soak: 100 routes, 100 checkpoint cycles, 100 twin-stick cancellations, 500 weapon transitions, and 100 effect cycles.
- Headless stall smoke:
  - Salmon Creek p95 21.775 ms, p99 23.341 ms.
  - Rain City p95 21.488 ms, p99 22.965 ms.
  - No positive node drift.
- Native M4 1280×720 Compatibility Rain City profile:
  - alley p95/p99 18.43/18.54 ms, 406 draw calls;
  - Rain City Slice 18.54/18.62 ms, 360 draw calls;
  - seawall 18.49/18.60 ms, 303 draw calls;
  - terminal 18.34/18.42 ms, 256 draw calls;
  - pier 18.30/23.36 ms, 195 draw calls;
  - approximately 83 MB static memory.

## Human-only gates

Automated evidence does not approve physical iPad comfort/thermals/audio, complete target-Mac or browser playthroughs, encounter and convoy feel, route clarity, perceived physics, art cohesion, mix, humor, or photosensitivity. The public mission keeps its `BETA` label until those checks are recorded.
