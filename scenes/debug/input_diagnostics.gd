class_name InputDiagnosticsScreen
extends Control

signal back_requested

const ManagerScript = preload("res://scripts/input/input_manager_service.gd")
const ProfileScript = preload("res://scripts/input/input_profile.gd")
const PROFILES := [
	"res://resources/input_profiles/keyboard_mouse.tres",
	"res://resources/input_profiles/classic_1996.tres",
	"res://resources/input_profiles/hybrid.tres",
	"res://resources/input_profiles/generic_gamepad.tres",
]

var manager: InputManagerService
var owns_manager := false
var device_picker: OptionButton
var profile_picker: OptionButton
var axis_picker: OptionButton
var dead_zone: HSlider
var sensitivity: HSlider
var curve: HSlider
var inverted: CheckBox
var live_display: RichTextLabel
var action_display: RichTextLabel
var status: Label
var updating := false
var action_buttons: Dictionary = {}


func _ready() -> void:
	modulate.a = 0.0
	manager = get_node_or_null("/root/InputManager") as InputManagerService
	if manager == null:
		manager = ManagerScript.new()
		add_child(manager)
		owns_manager = true
	build_ui()
	manager.device_connected.connect(func(_a, _b, _c): refresh_devices())
	manager.device_disconnected.connect(func(_a): refresh_devices())
	manager.binding_captured.connect(binding_captured)
	manager.binding_capture_cancelled.connect(func(): status.text = "Remap cancelled.")
	load_profiles()
	refresh_devices()
	refresh_axis_editor()
	refresh_action_labels()
	_reveal_after_layout()


func _reveal_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	modulate.a = 1.0


func _process(_delta: float) -> void:
	if manager == null or live_display == null:
		return
	var snapshot := manager.diagnostic_snapshot()
	var lines := PackedStringArray()
	if snapshot.devices.is_empty():
		lines.append("[b]No joystick detected.[/b] Keyboard/mouse remains available.")
	for device in snapshot.devices:
		lines.append("[b]Device %d: %s[/b]\nGUID: %s" % [device.index, device.name, device.guid])
		if int(device.index) == manager.active_device_id:
			for axis in range(device.axes.size()):
				lines.append("Axis %02d  raw %+.3f  processed %+.3f" % [axis, device.axes[axis], device.processed_axes[axis]])
			var pressed := PackedStringArray()
			for button in range(device.buttons.size()):
				if device.buttons[button]: pressed.append(str(button))
			lines.append("Buttons pressed: " + (", ".join(pressed) if not pressed.is_empty() else "none"))
	live_display.text = "\n".join(lines)
	var actions := PackedStringArray(["[b]ACTION  MAPPING  LIVE[/b]"])
	for action in ProfileScript.UNIVERSAL_ACTIONS:
		actions.append("%-14s %-10s %.1f" % [_short_action_name(action), binding_label(action), snapshot.actions.get(String(action), 0.0)])
	action_display.text = "\n".join(actions)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if manager.is_capturing_binding():
			manager.cancel_binding_capture()
		else:
			_request_back()


func build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_font_size_override("font_size", 7)
	var bg := ColorRect.new()
	bg.color = Color("111820")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 5)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 1)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "INPUT SETUP / DIAGNOSTICS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color("ffc857"))
	header.add_child(title)
	button(header, "BACK / ESC", _request_back)
	var warning := Label.new()
	warning.text = "NATIVE MAC RECOMMENDED • WEB JOYSTICKS EXPERIMENTAL • ESC BACK"
	warning.add_theme_font_size_override("font_size", 6)
	warning.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	warning.clip_text = true
	root.add_child(warning)
	var selectors := HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 4)
	root.add_child(selectors)
	profile_picker = picker(selectors, "Profile")
	profile_picker.item_selected.connect(profile_selected)
	device_picker = picker(selectors, "Device")
	device_picker.item_selected.connect(device_selected)
	axis_picker = picker(selectors, "Edit axis")
	for axis in range(ManagerScript.MAX_DIAGNOSTIC_AXES): axis_picker.add_item("Axis %d" % axis, axis)
	axis_picker.item_selected.connect(func(_i): refresh_axis_editor())
	var columns := HSplitContainer.new()
	columns.split_offset = 126
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)
	var live := VBoxContainer.new()
	live.custom_minimum_size.x = 122
	columns.add_child(live)
	live_display = panel(live)
	action_display = panel(live)
	var edit_scroll := ScrollContainer.new()
	edit_scroll.custom_minimum_size.x = 160
	edit_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit_scroll.follow_focus = true
	columns.add_child(edit_scroll)
	var edit := VBoxContainer.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_scroll.add_child(edit)
	var calibration := GridContainer.new()
	calibration.columns = 2
	edit.add_child(calibration)
	button(calibration, "CALIBRATE REST", func(): manager.start_rest_calibration(); status.text = "Hands off for one second…")
	button(calibration, "START RANGE", func(): manager.start_range_calibration(); status.text = "Move all axes fully.")
	button(calibration, "FINISH RANGE", func(): manager.finish_range_calibration(); refresh_axis_editor())
	dead_zone = slider(edit, "Dead zone", 0.0, 0.5, func(v): if not updating: manager.set_axis_dead_zone(selected_axis(), v))
	sensitivity = slider(edit, "Sensitivity", 0.1, 3.0, func(v): if not updating: manager.set_axis_sensitivity(selected_axis(), v))
	curve = slider(edit, "Curve (1 linear; >1 exponential)", 0.1, 3.0, func(v): if not updating: manager.set_axis_curve(selected_axis(), v))
	inverted = CheckBox.new()
	inverted.text = "Invert selected axis"
	inverted.toggled.connect(func(v): if not updating: manager.set_axis_inverted(selected_axis(), v))
	edit.add_child(inverted)
	var hint := Label.new()
	hint.text = "REMAP: SELECT ACTION, THEN PRESS KEY / BUTTON"
	hint.add_theme_font_size_override("font_size", 6)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	edit.add_child(hint)
	var remap_grid := GridContainer.new()
	remap_grid.columns = 2
	edit.add_child(remap_grid)
	for action in ProfileScript.UNIVERSAL_ACTIONS:
		var captured_action := action
		action_buttons[action] = button(remap_grid, "", func(): manager.begin_binding_capture(captured_action); status.text = "Listening for %s (Escape cancels)…" % captured_action)
	var actions := HBoxContainer.new()
	edit.add_child(actions)
	button(actions, "Save profile", save_profile)
	button(actions, "Reset defaults", _reset_profile)
	button(actions, "Export report", export_report)
	status = Label.new()
	status.text = "Physical Thrustmaster compatibility: pending owner hardware test."
	status.add_theme_color_override("font_color", Color("ffc857"))
	status.add_theme_font_size_override("font_size", 7)
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.clip_text = true
	root.add_child(status)


func _request_back() -> void:
	back_requested.emit()
	if owns_manager:
		get_tree().quit()
	elif get_node_or_null("/root/SceneRouter"):
		get_node("/root/SceneRouter").go_to("res://scenes/menus/main_menu.tscn")


func load_profiles() -> void:
	profile_picker.clear()
	for path in PROFILES:
		var profile := load(path) as InputProfile
		if profile:
			profile_picker.add_item(_profile_picker_name(profile))
			profile_picker.set_item_metadata(profile_picker.item_count - 1, path)
	for saved in manager.list_saved_profiles():
		profile_picker.add_item("Saved: " + saved)
		profile_picker.set_item_metadata(profile_picker.item_count - 1, "user:" + saved)


func refresh_devices() -> void:
	device_picker.clear()
	device_picker.add_item("KB / MOUSE", -1)
	var selection := 0
	for id in Input.get_connected_joypads():
		device_picker.add_item("%d: %s" % [id, Input.get_joy_name(id)], id)
		if id == manager.active_device_id: selection = device_picker.item_count - 1
	device_picker.select(selection)


func refresh_axis_editor() -> void:
	if axis_picker == null or manager.active_profile == null: return
	updating = true
	var config := manager.active_profile.axis_config(selected_axis())
	dead_zone.value = config.dead_zone
	sensitivity.value = config.sensitivity
	curve.value = config.curve
	inverted.button_pressed = config.invert
	updating = false


func profile_selected(index: int) -> void:
	var source := str(profile_picker.get_item_metadata(index))
	var error := manager.load_saved_profile(source.trim_prefix("user:")) if source.begins_with("user:") else manager.load_profile(source)
	status.text = "Profile loaded." if error == OK else "Profile load failed: %d" % error
	refresh_axis_editor()
	refresh_action_labels()


func device_selected(index: int) -> void:
	manager.select_device(device_picker.get_item_id(index))


func binding_captured(action: StringName, binding: Dictionary, conflicts: Array[StringName]) -> void:
	status.text = "%s remapped%s" % [action, " (conflicts: %s)" % ", ".join(conflicts) if not conflicts.is_empty() else ""]
	refresh_action_labels()


func save_profile() -> void:
	var error := manager.save_active_profile()
	status.text = "Saved to user://input_profiles/." if error == OK else "Save failed: %d" % error
	if error == OK: load_profiles()


func export_report() -> void:
	var error := manager.export_diagnostic_report()
	status.text = "Report: user://input_diagnostics.txt" if error == OK else "Export failed: %d" % error


func selected_axis() -> int:
	return axis_picker.get_item_id(axis_picker.selected)


func _reset_profile() -> void:
	manager.active_profile.reset_to_defaults()
	refresh_axis_editor()
	refresh_action_labels()


func refresh_action_labels() -> void:
	for action in action_buttons:
		var target := action_buttons[action] as Button
		target.text = "%s  —  %s" % [_short_action_name(action), binding_label(action)]


func binding_label(action: StringName) -> String:
	if manager != null and manager.active_profile != null:
		var custom := manager.active_profile.bindings_for(action)
		if not custom.is_empty():
			return _binding_text(custom[0])
	if InputMap.has_action(action):
		var events := InputMap.action_get_events(action)
		if not events.is_empty():
			var event := events[0]
			if event is InputEventKey:
				return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode).to_upper()
			if event is InputEventMouseButton:
				return _mouse_button_text(event.button_index)
	if String(action).begins_with("look_"):
		return "MOUSE"
	return "UNBOUND"


func _binding_text(binding: Dictionary) -> String:
	match str(binding.get("type", "")):
		"key": return OS.get_keycode_string(int(binding.get("index", 0))).to_upper()
		"mouse_button": return _mouse_button_text(int(binding.get("index", 0)))
		"button": return "BTN %d" % int(binding.get("index", 0))
		"axis": return "AXIS %d%s" % [int(binding.get("index", 0)), "+" if float(binding.get("direction", 1.0)) > 0 else "−"]
	return "UNBOUND"


func _mouse_button_text(index: int) -> String:
	match index:
		MOUSE_BUTTON_LEFT: return "LMB"
		MOUSE_BUTTON_RIGHT: return "RMB"
		MOUSE_BUTTON_MIDDLE: return "MMB"
		MOUSE_BUTTON_WHEEL_UP: return "WHEEL ↑"
		MOUSE_BUTTON_WHEEL_DOWN: return "WHEEL ↓"
	return "MOUSE %d" % index


func _short_action_name(action: StringName) -> String:
	return String(action).replace("_", " ").to_upper()


func _profile_picker_name(profile: InputProfile) -> String:
	match profile.preset:
		"keyboard_mouse": return "KB + MOUSE"
		"classic_1996": return "FLIGHT STICK: CLASSIC"
		"hybrid": return "STICK + KB: HYBRID"
		"generic_gamepad": return "GAMEPAD"
	return profile.display_name


func picker(parent: Control, text: String) -> OptionButton:
	var box := VBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; box.size_flags_stretch_ratio = 1.0; parent.add_child(box)
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", 6); box.add_child(label)
	var result := OptionButton.new(); result.fit_to_longest_item = false; result.size_flags_horizontal = Control.SIZE_EXPAND_FILL; result.clip_text = true; result.custom_minimum_size.y = 13; box.add_child(result)
	return result


func slider(parent: Control, text: String, min_value: float, max_value: float, callback: Callable) -> HSlider:
	var label := Label.new(); label.text = text; parent.add_child(label)
	var result := HSlider.new(); result.min_value = min_value; result.max_value = max_value; result.step = 0.01; result.value_changed.connect(callback); parent.add_child(result)
	return result


func panel(parent: Control) -> RichTextLabel:
	var result := RichTextLabel.new(); result.bbcode_enabled = true; result.custom_minimum_size.y = 34; result.size_flags_vertical = Control.SIZE_EXPAND_FILL; result.add_theme_font_size_override("normal_font_size", 6); result.add_theme_font_size_override("bold_font_size", 6); parent.add_child(result)
	return result


func button(parent: Control, text: String, callback: Callable) -> Button:
	var result := Button.new(); result.text = text; result.custom_minimum_size.y = 14; result.add_theme_font_size_override("font_size", 7); result.pressed.connect(callback); parent.add_child(result)
	return result
