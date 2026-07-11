class_name InputProfile
extends Resource

const PROFILE_VERSION := 1
const UNIVERSAL_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_backward", &"strafe_left", &"strafe_right",
	&"look_left", &"look_right", &"look_up", &"look_down",
	&"fire_primary", &"fire_secondary", &"use", &"jump", &"run",
	&"weapon_next", &"weapon_previous", &"pause", &"menu_accept", &"menu_back"
]

@export var profile_id := "generic_gamepad"
@export var display_name := "Generic Gamepad"
@export_enum("keyboard_mouse", "classic_1996", "hybrid", "generic_gamepad") var preset := "generic_gamepad"
@export var device_guid := ""
@export var device_name_hint := ""
@export var preferred_device_id := -1
@export var browser_experimental := false
@export var action_bindings: Dictionary = {}
@export var axis_settings: Dictionary = {}


func ensure_defaults() -> void:
	if action_bindings.is_empty():
		action_bindings = default_bindings_for(preset)
	if axis_settings.is_empty():
		axis_settings = default_axis_settings_for(preset)


func axis_config(axis: int) -> Dictionary:
	ensure_defaults()
	var key := str(axis)
	if not axis_settings.has(key):
		axis_settings[key] = make_axis_config()
	return axis_settings[key].duplicate(true)


func set_axis_config(axis: int, config: Dictionary) -> void:
	axis_settings[str(axis)] = sanitize_axis_config(config)
	emit_changed()


func bindings_for(action: StringName) -> Array:
	ensure_defaults()
	return action_bindings.get(String(action), [])


func set_binding(action: StringName, binding: Dictionary, replace_existing := true) -> Array[StringName]:
	ensure_defaults()
	var conflicts: Array[StringName] = []
	for other_action_key in action_bindings:
		for existing in action_bindings[other_action_key]:
			if bindings_conflict(existing, binding) and StringName(other_action_key) != action:
				conflicts.append(StringName(other_action_key))
	if replace_existing:
		action_bindings[String(action)] = [sanitize_binding(binding)]
	else:
		var current: Array = action_bindings.get(String(action), [])
		current.append(sanitize_binding(binding))
		action_bindings[String(action)] = current
	emit_changed()
	return conflicts


func remove_binding(action: StringName, index: int) -> void:
	var current: Array = action_bindings.get(String(action), [])
	if index >= 0 and index < current.size():
		current.remove_at(index)
		action_bindings[String(action)] = current
		emit_changed()


func reset_to_defaults() -> void:
	action_bindings = default_bindings_for(preset)
	axis_settings = default_axis_settings_for(preset)
	emit_changed()


func to_dict() -> Dictionary:
	ensure_defaults()
	return {
		"version": PROFILE_VERSION,
		"profile_id": profile_id,
		"display_name": display_name,
		"preset": preset,
		"device_guid": device_guid,
		"device_name_hint": device_name_hint,
		"preferred_device_id": preferred_device_id,
		"browser_experimental": browser_experimental,
		"action_bindings": action_bindings.duplicate(true),
		"axis_settings": axis_settings.duplicate(true),
	}


static func from_dict(data: Dictionary) -> InputProfile:
	var result := InputProfile.new()
	result.profile_id = str(data.get("profile_id", "custom"))
	result.display_name = str(data.get("display_name", "Custom Profile"))
	result.preset = str(data.get("preset", "generic_gamepad"))
	result.device_guid = str(data.get("device_guid", ""))
	result.device_name_hint = str(data.get("device_name_hint", ""))
	result.preferred_device_id = int(data.get("preferred_device_id", -1))
	result.browser_experimental = bool(data.get("browser_experimental", false))
	result.action_bindings = data.get("action_bindings", {}).duplicate(true)
	result.axis_settings = data.get("axis_settings", {}).duplicate(true)
	result.ensure_defaults()
	for axis_key in result.axis_settings.keys():
		result.axis_settings[axis_key] = sanitize_axis_config(result.axis_settings[axis_key])
	return result


static func make_axis_config(
	dead_zone := 0.12,
	sensitivity := 1.0,
	curve := 1.0,
	invert := false
) -> Dictionary:
	return {
		"minimum": -1.0,
		"center": 0.0,
		"maximum": 1.0,
		"dead_zone": dead_zone,
		"sensitivity": sensitivity,
		"curve": curve,
		"invert": invert,
	}


static func sanitize_axis_config(config: Dictionary) -> Dictionary:
	var result := make_axis_config()
	result.merge(config, true)
	result.minimum = clampf(float(result.minimum), -1.0, 1.0)
	result.center = clampf(float(result.center), -1.0, 1.0)
	result.maximum = clampf(float(result.maximum), -1.0, 1.0)
	if result.minimum >= result.center:
		result.minimum = result.center - 0.0001
	if result.maximum <= result.center:
		result.maximum = result.center + 0.0001
	result.dead_zone = clampf(float(result.dead_zone), 0.0, 0.95)
	result.sensitivity = clampf(float(result.sensitivity), 0.1, 3.0)
	result.curve = clampf(float(result.curve), 0.1, 5.0)
	result.invert = bool(result.invert)
	return result


static func sanitize_binding(binding: Dictionary) -> Dictionary:
	var result := binding.duplicate(true)
	result["type"] = str(result.get("type", "button"))
	result["index"] = int(result.get("index", 0))
	result["direction"] = signf(float(result.get("direction", 1.0)))
	if is_zero_approx(float(result.direction)):
		result.direction = 1.0
	result["range"] = str(result.get("range", "directional"))
	return result


static func bindings_conflict(a: Dictionary, b: Dictionary) -> bool:
	if str(a.get("type", "")) != str(b.get("type", "")):
		return false
	if int(a.get("index", -999)) != int(b.get("index", -998)):
		return false
	if str(a.get("type")) == "axis":
		return signf(float(a.get("direction", 1.0))) == signf(float(b.get("direction", 1.0)))
	return true


static func default_axis_settings_for(profile_preset: String) -> Dictionary:
	match profile_preset:
		"classic_1996":
			return {
				"0": make_axis_config(0.14, 1.0, 1.45),
				"1": make_axis_config(0.14, 1.0, 1.25),
				"2": make_axis_config(0.06, 1.0, 1.0),
			}
		"hybrid":
			return {
				"0": make_axis_config(0.12, 1.0, 1.35),
				"1": make_axis_config(0.12, 0.85, 1.35, true),
				"2": make_axis_config(0.06, 1.0, 1.0),
			}
		"generic_gamepad":
			return {
				"0": make_axis_config(0.18), "1": make_axis_config(0.18),
				"2": make_axis_config(0.16, 1.0, 1.2), "3": make_axis_config(0.16, 1.0, 1.2),
			}
	return {}


static func default_bindings_for(profile_preset: String) -> Dictionary:
	match profile_preset:
		"classic_1996":
			return {
				"look_left": [_axis(0, -1)], "look_right": [_axis(0, 1)],
				"move_forward": [_axis(1, -1)], "move_backward": [_axis(1, 1)],
				"strafe_left": [_button(13)], "strafe_right": [_button(14)],
				"look_up": [_button(11)], "look_down": [_button(12)],
				"fire_primary": [_button(0)], "use": [_button(1)],
				"jump": [_button(2)], "fire_secondary": [_button(3)],
				"weapon_next": [_button(4)], "run": [_axis(2, 1, "full_range")],
				"menu_accept": [_button(0)], "menu_back": [_button(1)], "pause": [_button(6)],
			}
		"hybrid":
			return {
				"look_left": [_axis(0, -1)], "look_right": [_axis(0, 1)],
				"look_up": [_axis(1, -1)], "look_down": [_axis(1, 1)],
				"fire_primary": [_button(0)], "use": [_button(1)],
				"jump": [_button(2)], "fire_secondary": [_button(3)],
				"weapon_next": [_button(4)], "run": [_axis(2, 1, "full_range")],
				"menu_accept": [_button(0)], "menu_back": [_button(1)], "pause": [_button(6)],
			}
		"generic_gamepad":
			return {
				"strafe_left": [_axis(0, -1)], "strafe_right": [_axis(0, 1)],
				"move_forward": [_axis(1, -1)], "move_backward": [_axis(1, 1)],
				"look_left": [_axis(2, -1)], "look_right": [_axis(2, 1)],
				"look_up": [_axis(3, -1)], "look_down": [_axis(3, 1)],
				"jump": [_button(0)], "use": [_button(2)], "fire_primary": [_button(7)],
				"fire_secondary": [_button(6)], "weapon_previous": [_button(9)],
				"weapon_next": [_button(10)], "run": [_button(8)],
				"menu_accept": [_button(0)], "menu_back": [_button(1)], "pause": [_button(6)],
			}
	return {}


static func _axis(index: int, direction: int, axis_range := "directional") -> Dictionary:
	return {"type": "axis", "index": index, "direction": direction, "range": axis_range}


static func _button(index: int) -> Dictionary:
	return {"type": "button", "index": index, "direction": 1.0, "range": "directional"}
