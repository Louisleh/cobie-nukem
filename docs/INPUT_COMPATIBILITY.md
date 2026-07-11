# Input Compatibility

The native macOS build is the canonical flight-stick experience. Browser controller support is experimental; keyboard and mouse must always remain available.

## Status

The input abstraction, profiles, live diagnostics, calibration, remapping, persistence, report export, and reconnect handling are implemented. Physical compatibility for the Thrustmaster USB Joystick 2960623 is **not verified** because the target device and USB-A-to-USB-C adapter have not been tested. Do not change that wording based on software-only tests.

Profiles included:

- Keyboard + Mouse (uses the project InputMap defaults).
- Flight Stick — Classic 1996: stick X turns, stick Y moves, POV strafes/looks, trigger fires, throttle governs run strength.
- Flight Stick + Keyboard — Hybrid: stick looks, keyboard moves, trigger fires.
- Generic Gamepad: left stick moves, right stick looks, standard face/shoulder buttons act.

POV and button indices are intentionally remappable because raw flight sticks may enumerate differently across SDL mappings and browser Gamepad implementations.

## Owner hardware verification

1. Connect the joystick through the intended USB-A-to-USB-C adapter or hub.
2. Launch the native macOS build and open **Input Setup → Diagnostics**.
3. Record the displayed device index, name, and GUID.
4. Press the trigger and every button; move stick X/Y, throttle, and POV through their complete ranges.
5. Run **Calibrate Rest** with hands off the controller.
6. Run **Start Min/Max**, move every analog control fully, then choose **Finish Min/Max**.
7. Remap any missing or mismatched controls. Confirm Escape recovers the UI without the joystick.
8. Save the profile, restart the game, and confirm it persists.
9. Play the complete level in Classic 1996 mode for at least 20 minutes.
10. Unplug/replug the joystick and confirm the same profile is reselected by GUID/name without restarting.
11. Export `user://input_diagnostics.txt` and attach it to the test record.
12. Record joystick model, adapter/hub, Mac model, macOS version, game version, observed mapping, and pass/fail notes below.

## Verification records

| Date | Device | Adapter/hub | Mac / macOS | Game | Result | Notes/report |
|---|---|---|---|---|---|---|
| Pending | Thrustmaster 2960623 | Pending | M4 Mac mini / Pending | Pending | **UNVERIFIED** | Physical test required |

## Developer commands

```sh
godot --headless --path . scenes/debug/input_diagnostics.tscn
godot --headless --path . -s tests/unit/input_system_test.gd
```

The diagnostics report is written to `user://input_diagnostics.txt`; profile JSON files are written to `user://input_profiles/`.
