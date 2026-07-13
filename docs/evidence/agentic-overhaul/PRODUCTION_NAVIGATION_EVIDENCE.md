# Production navigation evidence — `0.6.0-alpha.5`

## Outcome

Salmon Creek now has production navigation for every grounded enemy while
preserving direct authored steering for flying drones. This closes the prior
`nav_agents=0` technical gap; it does not substitute for a human combat-feel
playthrough.

## Architecture

- `EnemyNavigator` owns throttled target refresh, next-path steering, stuck
  sampling, repath attempts, and bounded recovery.
- `EnemyAgent` retains authoritative physics, gravity, combat state, and aim.
- The procedural mission creates temporary navigation-only `StaticBody3D`
  sources, synchronously bakes once after CSG construction, forces the initial
  server sync, and removes the temporary bodies.
- No render-mesh GPU readback, runtime bridge, avoidance callback, gameplay
  rebake, or per-frame server force-update is used.
- Bake and map synchronization use two deferred construction turns because
  Linux headless queues the region assignment later than macOS. CI caught this
  portability difference; both platforms must report map iteration 2.
- Recovery requires three stationary samples, moves no more than three metres
  to a valid mesh point, resets interpolation, and increments local-only
  `navigation_recoveries`.

## Deterministic evidence

Command:

```bash
godot --headless --path . --script tests/unit/navigation_contract_test.gd
```

Observed on Godot `4.7.stable.official.5b4e0cb0f`:

- 112 polygons and 114 vertices;
- 41 path points from opening field to arena conclusion;
- eight-point arena-cover route with 2.00 metres lateral deviation;
- one recovery after three failed repaths;
- grounded actor has a `NavigationAgent3D`; flying actor does not.

The test exposed a real disconnected arena seam caused by agent-radius erosion.
Connector D now overlaps the arena by more than one agent diameter.

## Regression and performance evidence

- Full non-export release gate: pass.
- Vertical-slice soak: 100 routes, 100 checkpoints, 100 touch cancellations,
  500 weapon transitions, and 100 temporary effects: pass.
- Headless 300-frame smoke after integration: p95 19.734 ms, p99 21.910 ms,
  max 23.550 ms, zero node drift.
- Extended native 1080p profile: one navigation agent in the opening and seven
  at Walker density. Opening p95/p99 was 17.076/17.246 ms, lab 17.341/17.944,
  tunnels 17.519/33.929, Walker 19.735/22.058, and victory 19.949/20.479. The
  one-frame Walker wall-time maximum was 151.852 ms, down from the prior
  candidate's recorded 224 ms but still retained as optimization evidence.

## Remaining human gates

- Confirm ground actors choose paths that feel aggressive rather than robotic.
- Confirm temporary door stalls do not produce visible corrections before the
  authored gate opens.
- Recheck Walker pressure, physical iPad thermal behavior, and family difficulty
  feel on the packaged candidate.
