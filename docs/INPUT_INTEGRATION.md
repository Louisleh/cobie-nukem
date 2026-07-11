# Input Integration Notes

`scripts/input/input_manager_service.gd` is the complete service implementation. The architecture-owned `scripts/core/input_manager.gd` can either extend it or forward the methods below while preserving its existing `control_method_changed` contract.

Required gameplay boundary:

```gdscript
var move := InputManager.get_vector(&"strafe_left", &"strafe_right", &"move_forward", &"move_backward")
var fire := InputManager.get_action_pressed(&"fire_primary")
var look_x := InputManager.get_action_strength(&"look_right") - InputManager.get_action_strength(&"look_left")
```

The service also provides profile load/save, device selection, bind capture, calibration, processed-axis access, diagnostic snapshots, and report export. Gameplay must not read raw joystick axes or button indices.

## Shared configuration changes for the integration owner

No shared configuration was edited by the input workstream. Apply these in the architecture-owned files:

1. Make the `InputManager` autoload use or extend `res://scripts/input/input_manager_service.gd`. Preserve control-method detection if extending the implementation.
2. Ensure all 18 actions in `InputProfile.UNIVERSAL_ACTIONS` exist in `project.godot`; keyboard/mouse defaults belong in InputMap. Custom joystick profiles are evaluated by the service.
3. Route the main menu's **Input Setup** item and the `--input-diagnostics` command-line flag to `res://scenes/debug/input_diagnostics.tscn`.
4. Connect the scene's `back_requested` signal to the menu/router. Escape is handled directly and can cancel capture even if the active controller mapping is unusable.
5. The Classic/Hybrid presets assume common SDL button indices but are deliberately remappable. Do not advertise hardware verification until the owner procedure passes.
