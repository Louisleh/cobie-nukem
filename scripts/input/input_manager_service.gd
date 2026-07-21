class_name InputManagerService
extends Node

signal device_connected(device_id: int, device_name: String, guid: String)
signal device_disconnected(device_id: int)
signal active_device_changed(device_id: int)
signal profile_changed(profile: InputProfile)
signal binding_captured(action: StringName, binding: Dictionary, conflicts: Array[StringName])
signal binding_capture_cancelled
signal calibration_changed(mode: String)

const InputMathScript = preload("res://scripts/input/input_math.gd")
const InputProfileScript = preload("res://scripts/input/input_profile.gd")
const USER_PROFILE_DIRECTORY := "user://input_profiles"
const MAX_DIAGNOSTIC_AXES := 10
const MAX_DIAGNOSTIC_BUTTONS := 24

@export var starting_profile: InputProfile
@export var reconnect_by_guid := true
@export var input_activity_threshold := 0.2

var active_profile: InputProfile
var active_device_id := -1
var last_input_timestamp_ms := 0
var last_input_description := "none"
var _pressed_keys: Dictionary = {}
var _pressed_mouse_buttons: Dictionary = {}
var _discrete_action_pressed: Dictionary = {}
var _capture_action := StringName()
var _capture_device_id := -1
var _calibration_mode := ""
var _calibration_started_ms := 0
var _rest_samples: Dictionary = {}
var _range_samples: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	set_process(true)
	set_process_input(true)
	if starting_profile:
		set_active_profile(starting_profile.duplicate(true))
	else:
		var fallback := InputProfileScript.new()
		fallback.profile_id = "generic_gamepad"
		fallback.display_name = "Generic Gamepad"
		fallback.preset = "generic_gamepad"
		fallback.ensure_defaults()
		set_active_profile(fallback)
	select_best_available_device()


func _process(_delta: float) -> void:
	_poll_device_activity()
	_poll_calibration()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_pressed_keys[event.physical_keycode] = event.pressed
		_pressed_keys[event.keycode] = event.pressed
	elif event is InputEventMouseButton:
		_pressed_mouse_buttons[event.button_index] = event.pressed

	if event.is_pressed() or event is InputEventJoypadMotion:
		last_input_timestamp_ms = Time.get_ticks_msec()
		last_input_description = event.as_text()

	if _capture_action.is_empty():
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			cancel_binding_capture()
		else:
			_complete_binding_capture({"type": "key", "index": event.physical_keycode})
	elif event is InputEventMouseButton and event.pressed:
		_complete_binding_capture({"type": "mouse_button", "index": event.button_index})
	elif event is InputEventJoypadButton and event.pressed and _capture_matches_device(event.device):
		_complete_binding_capture({"type": "button", "index": event.button_index})
	elif event is InputEventJoypadMotion and _capture_matches_device(event.device):
		if absf(event.axis_value) >= 0.65:
			_complete_binding_capture({
				"type": "axis", "index": event.axis,
				"direction": signf(event.axis_value), "range": "directional"
			})


func set_active_profile(profile: InputProfile) -> void:
	active_profile = profile
	active_profile.ensure_defaults()
	_discrete_action_pressed.clear()
	if active_profile.preferred_device_id in Input.get_connected_joypads():
		active_device_id = active_profile.preferred_device_id
	profile_changed.emit(active_profile)


func load_profile(resource_path: String) -> Error:
	var loaded := load(resource_path) as InputProfile
	if loaded == null:
		return ERR_CANT_OPEN
	set_active_profile(loaded.duplicate(true))
	select_best_available_device()
	return OK


func save_active_profile(file_name := "") -> Error:
	if active_profile == null:
		return ERR_UNCONFIGURED
	var directory_error := DirAccess.make_dir_recursive_absolute(USER_PROFILE_DIRECTORY)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return directory_error
	var safe_name := file_name if not file_name.is_empty() else active_profile.profile_id + ".json"
	if not safe_name.ends_with(".json"):
		safe_name += ".json"
	var file := FileAccess.open(USER_PROFILE_DIRECTORY.path_join(safe_name), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(active_profile.to_dict(), "  "))
	return OK


func load_saved_profile(file_name: String) -> Error:
	var path := USER_PROFILE_DIRECTORY.path_join(file_name)
	if not path.ends_with(".json"):
		path += ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR
	set_active_profile(InputProfileScript.from_dict(parsed))
	select_best_available_device()
	return OK


func list_saved_profiles() -> PackedStringArray:
	var result := PackedStringArray()
	var directory := DirAccess.open(USER_PROFILE_DIRECTORY)
	if directory == null:
		return result
	for file_name in directory.get_files():
		if file_name.ends_with(".json"):
			result.append(file_name)
	result.sort()
	return result


func select_device(device_id: int) -> bool:
	if device_id != -1 and device_id not in Input.get_connected_joypads():
		return false
	active_device_id = device_id
	if active_profile:
		active_profile.preferred_device_id = device_id
		if device_id >= 0:
			active_profile.device_guid = Input.get_joy_guid(device_id)
			active_profile.device_name_hint = Input.get_joy_name(device_id)
	active_device_changed.emit(active_device_id)
	return true


func select_best_available_device() -> int:
	var connected := Input.get_connected_joypads()
	if connected.is_empty():
		select_device(-1)
		return -1
	if active_profile:
		if active_profile.preferred_device_id in connected:
			select_device(active_profile.preferred_device_id)
			return active_device_id
		if reconnect_by_guid and not active_profile.device_guid.is_empty():
			for device_id in connected:
				if Input.get_joy_guid(device_id) == active_profile.device_guid:
					select_device(device_id)
					return active_device_id
		if not active_profile.device_name_hint.is_empty():
			for device_id in connected:
				if Input.get_joy_name(device_id) == active_profile.device_name_hint:
					select_device(device_id)
					return active_device_id
	select_device(connected[0])
	return active_device_id


func get_action_strength(action: StringName) -> float:
	var result := Input.get_action_strength(action) if InputMap.has_action(action) else 0.0
	if active_profile == null:
		return result
	for binding in active_profile.bindings_for(action):
		result = maxf(result, _binding_strength(binding))
	return clampf(result, 0.0, 1.0)


func get_axis(negative: StringName, positive: StringName) -> float:
	return get_action_strength(positive) - get_action_strength(negative)


func get_action_pressed(action: StringName) -> bool:
	return get_action_strength(action) >= 0.5


func get_action_just_pressed(action: StringName) -> bool:
	if InputMap.has_action(action) and Input.is_action_just_pressed(action):
		_discrete_action_pressed[action] = true
		return true
	if active_profile == null:
		_discrete_action_pressed[action] = false
		return false
	var is_pressed := get_action_strength(action) >= 0.5
	var was_pressed := bool(_discrete_action_pressed.get(action, false))
	_discrete_action_pressed[action] = is_pressed
	return is_pressed and not was_pressed


func is_action_event_pressed(event: InputEvent, action: StringName) -> bool:
	if event == null:
		return false
	if event.is_action_pressed(action):
		return true
	if active_profile == null:
		return false
	for binding in active_profile.bindings_for(action):
		if _binding_matches_event(binding, event):
			return true
	return false


func get_vector(
	negative_x: StringName,
	positive_x: StringName,
	negative_y: StringName,
	positive_y: StringName
) -> Vector2:
	var vector := Vector2(
		get_action_strength(positive_x) - get_action_strength(negative_x),
		get_action_strength(positive_y) - get_action_strength(negative_y)
	)
	return vector.limit_length(1.0)


func processed_axis(axis: int, device_id := -999) -> float:
	var target_device := active_device_id if device_id == -999 else device_id
	if target_device < 0 or target_device not in Input.get_connected_joypads():
		return 0.0
	var config := active_profile.axis_config(axis) if active_profile else InputProfileScript.make_axis_config()
	return InputMathScript.process_axis(Input.get_joy_axis(target_device, axis), config)


func begin_binding_capture(action: StringName, device_id := -1) -> void:
	_capture_action = action
	_capture_device_id = device_id if device_id >= 0 else active_device_id


func cancel_binding_capture() -> void:
	_capture_action = StringName()
	_capture_device_id = -1
	binding_capture_cancelled.emit()


func is_capturing_binding() -> bool:
	return not _capture_action.is_empty()


func start_rest_calibration() -> void:
	if active_device_id < 0:
		return
	_calibration_mode = "rest"
	_calibration_started_ms = Time.get_ticks_msec()
	_rest_samples.clear()
	calibration_changed.emit(_calibration_mode)


func start_range_calibration() -> void:
	if active_device_id < 0:
		return
	_calibration_mode = "range"
	_calibration_started_ms = Time.get_ticks_msec()
	_range_samples.clear()
	calibration_changed.emit(_calibration_mode)


func finish_range_calibration() -> void:
	if _calibration_mode != "range" or active_profile == null:
		return
	for axis in _range_samples:
		var config := active_profile.axis_config(axis)
		config.minimum = float(_range_samples[axis].minimum)
		config.maximum = float(_range_samples[axis].maximum)
		active_profile.set_axis_config(axis, config)
	_calibration_mode = ""
	calibration_changed.emit(_calibration_mode)


func set_axis_dead_zone(axis: int, value: float) -> void:
	_update_axis_setting(axis, "dead_zone", value)


func set_axis_sensitivity(axis: int, value: float) -> void:
	_update_axis_setting(axis, "sensitivity", value)


func set_axis_curve(axis: int, value: float) -> void:
	_update_axis_setting(axis, "curve", value)


func set_axis_inverted(axis: int, inverted: bool) -> void:
	_update_axis_setting(axis, "invert", inverted)


func diagnostic_snapshot() -> Dictionary:
	var devices: Array[Dictionary] = []
	for device_id in Input.get_connected_joypads():
		var axes: Array[float] = []
		var processed_axes: Array[float] = []
		for axis in range(MAX_DIAGNOSTIC_AXES):
			axes.append(Input.get_joy_axis(device_id, axis))
			processed_axes.append(processed_axis(axis, device_id))
		var buttons: Array[bool] = []
		for button in range(MAX_DIAGNOSTIC_BUTTONS):
			buttons.append(Input.is_joy_button_pressed(device_id, button))
		devices.append({
			"index": device_id,
			"name": Input.get_joy_name(device_id),
			"guid": Input.get_joy_guid(device_id),
			"axes": axes,
			"processed_axes": processed_axes,
			"buttons": buttons,
		})
	var actions := {}
	for action in InputProfileScript.UNIVERSAL_ACTIONS:
		actions[String(action)] = get_action_strength(action)
	return {
		"generated_at_unix": Time.get_unix_time_from_system(),
		"platform": OS.get_name(),
		"engine": Engine.get_version_info(),
		"active_device": active_device_id,
		"profile": active_profile.to_dict() if active_profile else {},
		"devices": devices,
		"actions": actions,
		"last_input_timestamp_ms": last_input_timestamp_ms,
		"last_input_description": last_input_description,
		"browser_controller_support": "experimental" if OS.has_feature("web") else "native",
	}


func export_diagnostic_report(path := "user://input_diagnostics.txt") -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var snapshot := diagnostic_snapshot()
	file.store_line("COBIE NUKEM INPUT DIAGNOSTICS")
	file.store_line("Physical hardware verification: PENDING OWNER TEST")
	file.store_line("Browser flight-stick support: EXPERIMENTAL")
	file.store_line("")
	file.store_string(JSON.stringify(snapshot, "  "))
	return OK


func _binding_strength(binding: Dictionary) -> float:
	match str(binding.get("type", "")):
		"axis":
			var value := processed_axis(int(binding.get("index", 0)))
			if str(binding.get("range", "directional")) == "full_range":
				return clampf((value + 1.0) * 0.5, 0.0, 1.0)
			return maxf(0.0, value * float(binding.get("direction", 1.0)))
		"button":
			return 1.0 if active_device_id >= 0 and Input.is_joy_button_pressed(
				active_device_id, int(binding.get("index", 0))
			) else 0.0
		"key":
			return 1.0 if bool(_pressed_keys.get(int(binding.get("index", 0)), false)) else 0.0
		"mouse_button":
			return 1.0 if bool(_pressed_mouse_buttons.get(int(binding.get("index", 0)), false)) else 0.0
	return 0.0


func _complete_binding_capture(binding: Dictionary) -> void:
	if active_profile == null:
		cancel_binding_capture()
		return
	var action := _capture_action
	var conflicts := active_profile.set_binding(action, binding, true)
	_capture_action = StringName()
	_capture_device_id = -1
	binding_captured.emit(action, binding, conflicts)


func _binding_matches_event(binding: Dictionary, event: InputEvent) -> bool:
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return false
		if binding.get("type", "") != "key":
			return false
		var binding_key := int(binding.get("index", -1))
		return event.physical_keycode == binding_key or event.keycode == binding_key
	if event is InputEventMouseButton:
		if not event.pressed:
			return false
		return binding.get("type", "") == "mouse_button" and int(event.button_index) == int(binding.get("index", -1))
	if event is InputEventJoypadButton:
		if not event.pressed:
			return false
		if active_device_id >= 0 and int(event.device) != active_device_id:
			return false
		return binding.get("type", "") == "button" and int(event.button_index) == int(binding.get("index", -1))
	if event is InputEventJoypadMotion:
		if absf(event.axis_value) < 0.65:
			return false
		if active_device_id >= 0 and int(event.device) != active_device_id:
			return false
		if binding.get("type", "") != "axis":
			return false
		if int(event.axis) != int(binding.get("index", -1)):
			return false
		var binding_direction := signf(float(binding.get("direction", 1.0)))
		return signf(event.axis_value) == binding_direction
	return false


func _capture_matches_device(event_device: int) -> bool:
	return _capture_device_id < 0 or event_device == _capture_device_id


func _update_axis_setting(axis: int, key: String, value: Variant) -> void:
	if active_profile == null:
		return
	var config := active_profile.axis_config(axis)
	config[key] = value
	active_profile.set_axis_config(axis, config)


func _poll_device_activity() -> void:
	for device_id in Input.get_connected_joypads():
		for axis in range(MAX_DIAGNOSTIC_AXES):
			if absf(Input.get_joy_axis(device_id, axis)) >= input_activity_threshold:
				last_input_timestamp_ms = Time.get_ticks_msec()
				last_input_description = "Device %d axis %d" % [device_id, axis]
				return
		for button in range(MAX_DIAGNOSTIC_BUTTONS):
			if Input.is_joy_button_pressed(device_id, button):
				last_input_timestamp_ms = Time.get_ticks_msec()
				last_input_description = "Device %d button %d" % [device_id, button]
				return


func _poll_calibration() -> void:
	if _calibration_mode.is_empty() or active_device_id < 0:
		return
	for axis in range(MAX_DIAGNOSTIC_AXES):
		var raw := Input.get_joy_axis(active_device_id, axis)
		if _calibration_mode == "rest":
			var samples: Array = _rest_samples.get(axis, [])
			samples.append(raw)
			_rest_samples[axis] = samples
		else:
			var range_data: Dictionary = _range_samples.get(axis, {"minimum": raw, "maximum": raw})
			range_data.minimum = minf(float(range_data.minimum), raw)
			range_data.maximum = maxf(float(range_data.maximum), raw)
			_range_samples[axis] = range_data
	if _calibration_mode == "rest" and Time.get_ticks_msec() - _calibration_started_ms >= 1000:
		_finish_rest_calibration()


func _finish_rest_calibration() -> void:
	if active_profile == null:
		return
	for axis in _rest_samples:
		var samples: Array = _rest_samples[axis]
		if samples.is_empty():
			continue
		var sum := 0.0
		var peak_delta := 0.0
		for sample in samples:
			sum += float(sample)
		var center := sum / samples.size()
		for sample in samples:
			peak_delta = maxf(peak_delta, absf(float(sample) - center))
		var config := active_profile.axis_config(axis)
		config.center = center
		config.dead_zone = clampf(maxf(float(config.dead_zone), peak_delta * 1.5 + 0.02), 0.02, 0.35)
		active_profile.set_axis_config(axis, config)
	_calibration_mode = ""
	calibration_changed.emit(_calibration_mode)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		device_connected.emit(device_id, Input.get_joy_name(device_id), Input.get_joy_guid(device_id))
		if active_device_id < 0:
			select_best_available_device()
		elif active_profile and reconnect_by_guid and Input.get_joy_guid(device_id) == active_profile.device_guid:
			select_device(device_id)
	else:
		device_disconnected.emit(device_id)
		if device_id == active_device_id:
			active_device_id = -1
			active_device_changed.emit(-1)
			select_best_available_device()
