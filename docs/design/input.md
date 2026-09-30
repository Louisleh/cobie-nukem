# Input runtime contract

- Raw device events and joystick axes terminate in `scripts/input/input_manager_service.gd`; gameplay consumes named universal actions through the `InputManager` wrapper.
- The active `InputProfile` is authoritative for continuous movement/look strength, held actions, and discrete event matching. Gameplay must not bypass it with direct `Input.*` polling.
- `CobiePlayer` consumes continuous intents in `_physics_process` and profile-aware edge intents from events. Jump taps are latched until the next physics tick so a press/release between ticks is not lost.
- `PauseMenu` uses the same profile-aware event seam. Raw number-key shortcuts may remain as explicit keyboard conveniences but never replace universal actions.
- Physical joystick quality remains a human/device gate. Automated diagnostics and synthetic events are not physical verification.

## Regression evidence

```bash
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/unit/input_system_test.gd
bash tools/run_godot_safe.sh --timeout 300 -- --headless --path . --script res://tests/integration/input_profile_service_boundary_test.gd
```

## Focus-loss ownership

On application focus loss, the service discards its local keyboard/mouse event cache and rearms only discrete actions that lose their last held source. Independently held engine actions, touch and joystick sources retain their strength and edge latches, including mixed sources mapped to the same action. Profile, device, calibration and axis-event ownership remain unchanged; pause/mobile controls retain their separate cancellation contract. The regression is `tests/integration/input_focus_release_test.gd`, using omitted releases and the real player consumer. This deterministic boundary evidence does not verify OS event delivery or physical devices.
