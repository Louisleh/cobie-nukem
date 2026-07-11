extends InputManagerService

## Project-wide input boundary. It layers control-method detection and the required
## action contract over the profile/calibration service used by diagnostics.
signal control_method_changed(method: StringName)

const REQUIRED_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_backward", &"strafe_left", &"strafe_right",
	&"look_left", &"look_right", &"look_up", &"look_down",
	&"fire_primary", &"fire_secondary", &"use", &"jump", &"run",
	&"weapon_next", &"weapon_previous", &"pause", &"menu_accept", &"menu_back",
]

var active_control_method: StringName = &"keyboard_mouse"


func _ready() -> void:
	starting_profile = load("res://resources/input_profiles/keyboard_mouse.tres") as InputProfile
	super._ready()


func _input(event: InputEvent) -> void:
	super._input(event)
	var next_method := active_control_method
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		next_method = &"flight_stick" if active_profile != null and active_profile.preset in ["classic_1996", "hybrid"] else &"gamepad"
	elif event is InputEventKey or event is InputEventMouse:
		next_method = &"keyboard_mouse"
	if next_method != active_control_method:
		active_control_method = next_method
		control_method_changed.emit(active_control_method)


func device_details(device_id: int) -> Dictionary:
	return {
		"id": device_id,
		"name": Input.get_joy_name(device_id),
		"guid": Input.get_joy_guid(device_id),
		"info": Input.get_joy_info(device_id),
	}


func missing_required_actions() -> Array[StringName]:
	var missing: Array[StringName] = []
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			missing.append(action)
	return missing
