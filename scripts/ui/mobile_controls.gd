class_name MobileControls
extends Control

@export var force_visible := false
@export_range(0.25, 3.0, 0.05) var look_sensitivity := 1.0

var player: CobiePlayer
var _move_finger := -1
var _look_finger := -1
var _move_origin := Vector2.ZERO
var _move_value := Vector2.ZERO
var _button_fingers: Dictionary = {}
var _touch_enabled := false

const MOVE_RADIUS := 25.0
const BUTTONS := {
	&"fire_primary": {"center": Vector2(287, 139), "radius": 24.0, "label": "FIRE"},
	&"use": {"center": Vector2(239, 148), "radius": 15.0, "label": "USE"},
	&"jump": {"center": Vector2(286, 91), "radius": 15.0, "label": "JUMP"},
	&"reload": {"center": Vector2(244, 112), "radius": 13.0, "label": "R"},
	&"weapon_previous": {"center": Vector2(274, 48), "radius": 12.0, "label": "◀"},
	&"weapon_next": {"center": Vector2(304, 48), "radius": 12.0, "label": "▶"},
	&"pause": {"center": Vector2(304, 15), "radius": 10.0, "label": "Ⅱ"},
}


func _ready() -> void:
	add_to_group(&"mobile_controls")
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_enabled = force_visible or touchscreen_expected()
	visible = _touch_enabled
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_value"):
		look_sensitivity = clampf(float(settings.get_value(&"gameplay", &"touch_sensitivity", 1.0)), 0.25, 3.0)
	if settings != null and settings.has_signal("setting_changed"):
		settings.setting_changed.connect(func(section: StringName, key: StringName, value: Variant) -> void:
			if section == &"gameplay" and key == &"touch_sensitivity": look_sensitivity = clampf(float(value), 0.25, 3.0)
		)
	queue_redraw()


func bind_player(value: CobiePlayer) -> void:
	player = value


func is_touch_enabled() -> bool:
	return _touch_enabled


static func touchscreen_expected() -> bool:
	if DisplayServer.is_touchscreen_available() or OS.has_feature("web_ios") or OS.has_feature("web_android"): return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("location.search.includes('touch=1') || ('ontouchstart' in window) || (navigator.maxTouchPoints > 0)", true))
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or player == null or player.is_dead: return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var position := _to_design(event.position)
	if event.pressed:
		var action := _button_at(position)
		if action != &"":
			_button_fingers[event.index] = action
			_emit_action(action, true)
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if position.x < 120.0 and position.y > 75.0 and _move_finger < 0:
			_move_finger = event.index
			_move_origin = Vector2(52, 137)
			_update_move(position)
			get_viewport().set_input_as_handled()
			return
		if position.x >= 105.0 and _look_finger < 0:
			_look_finger = event.index
			get_viewport().set_input_as_handled()
	else:
		if _button_fingers.has(event.index):
			_emit_action(_button_fingers[event.index], false)
			_button_fingers.erase(event.index)
		if event.index == _move_finger:
			_move_finger = -1
			_move_value = Vector2.ZERO
			player.set_touch_move(Vector2.ZERO)
		if event.index == _look_finger: _look_finger = -1
		queue_redraw()
		get_viewport().set_input_as_handled()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_finger:
		_update_move(_to_design(event.position))
		get_viewport().set_input_as_handled()
	elif event.index == _look_finger:
		var scale_factor := Vector2(320.0 / maxf(size.x, 1.0), 180.0 / maxf(size.y, 1.0))
		player.apply_touch_look(event.relative * scale_factor * look_sensitivity)
		get_viewport().set_input_as_handled()


func release_all() -> void:
	for action in _button_fingers.values(): _emit_action(action, false)
	_button_fingers.clear()
	_move_finger = -1
	_look_finger = -1
	_move_value = Vector2.ZERO
	if player != null: player.set_touch_move(Vector2.ZERO)
	queue_redraw()


func _emit_action(action: StringName, pressed: bool) -> void:
	var input_event := InputEventAction.new()
	input_event.action = action
	input_event.pressed = pressed
	Input.parse_input_event(input_event)


func _update_move(position: Vector2) -> void:
	_move_value = (position - _move_origin) / MOVE_RADIUS
	if _move_value.length() > 1.0: _move_value = _move_value.normalized()
	player.set_touch_move(_move_value)
	queue_redraw()


func _button_at(position: Vector2) -> StringName:
	for action in BUTTONS:
		var data: Dictionary = BUTTONS[action]
		if position.distance_to(data.center) <= float(data.radius) * 1.25: return action
	return &""


func _to_design(position: Vector2) -> Vector2:
	return Vector2(position.x * 320.0 / maxf(size.x, 1.0), position.y * 180.0 / maxf(size.y, 1.0))


func _from_design(position: Vector2) -> Vector2:
	return Vector2(position.x * size.x / 320.0, position.y * size.y / 180.0)


func _draw() -> void:
	if not visible: return
	var scale_value := minf(size.x / 320.0, size.y / 180.0)
	var font := ThemeDB.fallback_font
	var move_center := _from_design(Vector2(52, 137))
	draw_circle(move_center, MOVE_RADIUS * scale_value, Color(0.05, 0.08, 0.09, 0.38))
	draw_arc(move_center, MOVE_RADIUS * scale_value, 0.0, TAU, 40, Color(0.78, 0.72, 0.42, 0.6), maxf(1.0, scale_value))
	var knob := move_center + _move_value * MOVE_RADIUS * 0.55 * scale_value
	draw_circle(knob, 10.0 * scale_value, Color(0.95, 0.7, 0.18, 0.7))
	for action in BUTTONS:
		var data: Dictionary = BUTTONS[action]
		var center := _from_design(data.center)
		var radius := float(data.radius) * scale_value
		var active: bool = action in _button_fingers.values()
		draw_circle(center, radius, Color(0.95, 0.45, 0.12, 0.72) if active else Color(0.05, 0.08, 0.09, 0.48))
		draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.75, 0.24, 0.75), maxf(1.0, scale_value))
		var label := String(data.label)
		var font_size := maxi(7, roundi(8.0 * scale_value))
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.32), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
