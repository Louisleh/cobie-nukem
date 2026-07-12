class_name MobileControls
extends Control

@export var force_visible := false

var player: CobiePlayer
var _move_finger := -1
var _look_finger := -1
var _move_value := Vector2.ZERO
var _look_value := Vector2.ZERO
var _button_fingers: Dictionary = {}
var _touch_enabled := false
var control_opacity := 0.75
var left_handed := false
var stick_size := &"medium"
var stick_position := &"standard"
var _onboarding_remaining := 6.0

const DESIGN_SIZE := Vector2(320, 180)
const BASE_STICK_RADIUS := 25.0
const STICK_DEAD_ZONE := 0.12
const STICK_SIZE_SCALE := {&"small": 0.85, &"medium": 1.0, &"large": 1.18}
const STICK_CENTERS := {
	&"compact": [Vector2(42, 103), Vector2(215, 103)],
	&"standard": [Vector2(48, 105), Vector2(220, 105)],
	&"wide": [Vector2(42, 108), Vector2(228, 108)],
}
const BUTTONS := {
	&"fire_primary": {"center": Vector2(292, 111), "radius": 20.0, "label": "FIRE"},
	&"use": {"center": Vector2(257, 92), "radius": 12.0, "label": "USE"},
	&"jump": {"center": Vector2(291, 71), "radius": 13.0, "label": "JUMP"},
	&"reload": {"center": Vector2(259, 61), "radius": 11.0, "label": "R"},
	&"weapon_previous": {"center": Vector2(274, 35), "radius": 10.0, "label": "<"},
	&"weapon_next": {"center": Vector2(303, 35), "radius": 10.0, "label": ">"},
	&"pause": {"center": Vector2(304, 13), "radius": 10.0, "label": "MENU"},
}

func _ready() -> void:
	add_to_group(&"mobile_controls")
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_enabled = force_visible or touchscreen_expected()
	visible = _touch_enabled
	_load_settings()
	queue_redraw()

func _load_settings() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null or not settings.has_method("get_value"): return
	control_opacity = clampf(float(settings.get_value(&"gameplay", &"control_opacity", 0.75)), 0.25, 1.0)
	left_handed = bool(settings.get_value(&"gameplay", &"left_handed_touch", false))
	stick_size = _validated_choice(settings.get_value(&"gameplay", &"touch_stick_size", "medium"), STICK_SIZE_SCALE, &"medium")
	stick_position = _validated_choice(settings.get_value(&"gameplay", &"touch_stick_position", "standard"), STICK_CENTERS, &"standard")
	if settings.has_signal("setting_changed"): settings.setting_changed.connect(_on_setting_changed)

func _validated_choice(value: Variant, choices: Dictionary, fallback: StringName) -> StringName:
	var choice := StringName(String(value).to_lower())
	return choice if choices.has(choice) else fallback

func _on_setting_changed(section: StringName, key: StringName, value: Variant) -> void:
	if section != &"gameplay": return
	match key:
		&"control_opacity": control_opacity = clampf(float(value), 0.25, 1.0)
		&"left_handed_touch": left_handed = bool(value); release_all()
		&"touch_stick_size": stick_size = _validated_choice(value, STICK_SIZE_SCALE, &"medium"); release_all()
		&"touch_stick_position": stick_position = _validated_choice(value, STICK_CENTERS, &"standard"); release_all()
	queue_redraw()

func bind_player(value: CobiePlayer) -> void: player = value
func is_touch_enabled() -> bool: return _touch_enabled

static func touchscreen_expected() -> bool:
	if DisplayServer.is_touchscreen_available() or OS.has_feature("web_ios") or OS.has_feature("web_android"): return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("location.search.includes('touch=1') || ('ontouchstart' in window) || (navigator.maxTouchPoints > 0)", true))
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		release_all()
		queue_redraw()
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_APPLICATION_FOCUS_OUT: release_all()

func _process(delta: float) -> void:
	if _onboarding_remaining <= 0.0: return
	_onboarding_remaining = maxf(0.0, _onboarding_remaining - delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible or player == null or player.is_dead or _portrait_viewport(): return
	if event is InputEventScreenTouch: _handle_touch(event)
	elif event is InputEventScreenDrag: _handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var position := _to_design(event.position)
	if event.pressed:
		_onboarding_remaining = minf(_onboarding_remaining, 1.5)
		var action := _button_at(position)
		if action != &"":
			_button_fingers[event.index] = action
			_emit_action(action, true)
		elif _stick_at(position) == &"move" and _move_finger < 0:
			_move_finger = event.index; _update_stick(&"move", position)
		elif _stick_at(position) == &"look" and _look_finger < 0:
			_look_finger = event.index; _update_stick(&"look", position)
		else: return
	else:
		if _button_fingers.has(event.index):
			_emit_action(_button_fingers[event.index], false)
			_button_fingers.erase(event.index)
		if event.index == _move_finger:
			_move_finger = -1; _move_value = Vector2.ZERO; player.set_touch_move(Vector2.ZERO)
		if event.index == _look_finger:
			_look_finger = -1; _look_value = Vector2.ZERO; player.set_touch_look(Vector2.ZERO)
	queue_redraw()
	get_viewport().set_input_as_handled()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _move_finger: _update_stick(&"move", _to_design(event.position))
	elif event.index == _look_finger: _update_stick(&"look", _to_design(event.position))
	else: return
	get_viewport().set_input_as_handled()

func release_all() -> void:
	for action in _button_fingers.values(): _emit_action(action, false)
	_button_fingers.clear(); _move_finger = -1; _look_finger = -1
	_move_value = Vector2.ZERO; _look_value = Vector2.ZERO
	if player != null: player.clear_touch_input()
	queue_redraw()

func _emit_action(action: StringName, pressed: bool) -> void:
	var input_event := InputEventAction.new(); input_event.action = action; input_event.pressed = pressed
	Input.parse_input_event(input_event)

func _stick_centers() -> Array: return STICK_CENTERS.get(stick_position, STICK_CENTERS[&"standard"])
func _stick_radius() -> float: return BASE_STICK_RADIUS * float(STICK_SIZE_SCALE.get(stick_size, 1.0))

func _stick_at(position: Vector2) -> StringName:
	var centers := _stick_centers(); var capture_radius := _stick_radius() * 1.35
	if position.distance_to(centers[0]) <= capture_radius: return &"move"
	if position.distance_to(centers[1]) <= capture_radius: return &"look"
	return &""

func _update_stick(kind: StringName, position: Vector2) -> void:
	var center: Vector2 = _stick_centers()[0 if kind == &"move" else 1]
	var raw := (position - center) / _stick_radius()
	if raw.length() > 1.0: raw = raw.normalized()
	var value := _apply_dead_zone(raw)
	if kind == &"move": _move_value = value; player.set_touch_move(value)
	else: _look_value = value; player.set_touch_look(value)
	queue_redraw()

static func _apply_dead_zone(value: Vector2) -> Vector2:
	var magnitude := value.length()
	if magnitude <= STICK_DEAD_ZONE: return Vector2.ZERO
	var scaled := clampf((magnitude - STICK_DEAD_ZONE) / (1.0 - STICK_DEAD_ZONE), 0.0, 1.0)
	return value.normalized() * lerpf(scaled, scaled * scaled, 0.55)

func _button_at(position: Vector2) -> StringName:
	for action in BUTTONS:
		var data: Dictionary = BUTTONS[action]
		if position.distance_to(data.center) <= float(data.radius) * 1.25: return action
	return &""

func _to_design(position: Vector2) -> Vector2:
	var result := Vector2(position.x * DESIGN_SIZE.x / maxf(size.x, 1.0), position.y * DESIGN_SIZE.y / maxf(size.y, 1.0))
	if left_handed: result.x = DESIGN_SIZE.x - result.x
	return result

func _from_design(position: Vector2) -> Vector2:
	var result := position
	if left_handed: result.x = DESIGN_SIZE.x - result.x
	return Vector2(result.x * size.x / DESIGN_SIZE.x, result.y * size.y / DESIGN_SIZE.y)

func _portrait_viewport() -> bool:
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("window.innerHeight > window.innerWidth", true))
	return size.y > size.x

func _draw() -> void:
	if not visible: return
	var scale_value := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y); var centers := _stick_centers()
	if _portrait_viewport():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.025, 0.9), true)
		var rotate_font := ThemeDB.fallback_font; var rotate_text := "ROTATE IPAD TO LANDSCAPE"; var rotate_size := maxi(16, roundi(11.0 * scale_value)); var rotate_measure := rotate_font.get_string_size(rotate_text, HORIZONTAL_ALIGNMENT_LEFT, -1, rotate_size)
		draw_string(rotate_font, size * 0.5 - Vector2(rotate_measure.x * 0.5, -rotate_measure.y * 0.3), rotate_text, HORIZONTAL_ALIGNMENT_LEFT, -1, rotate_size, Color(1.0, 0.75, 0.24))
		return
	_draw_stick(_from_design(centers[0]), _move_value, "MOVE", scale_value)
	_draw_stick(_from_design(centers[1]), _look_value, "AIM", scale_value)
	var font := ThemeDB.fallback_font
	if _onboarding_remaining > 0.0:
		var hint := "LEFT: MOVE   RIGHT: AIM   FIRE TO FETCH"
		var hint_size := maxi(7, roundi(8.0 * scale_value)); var measured := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hint_size)
		var hint_center := _from_design(Vector2(160, 17))
		draw_rect(Rect2(hint_center - Vector2(measured.x * 0.5 + 6.0 * scale_value, measured.y * 0.65), Vector2(measured.x + 12.0 * scale_value, measured.y + 5.0 * scale_value)), Color(0.02, 0.04, 0.04, 0.72 * control_opacity), true)
		draw_string(font, hint_center - Vector2(measured.x * 0.5, -measured.y * 0.3), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hint_size, Color(1.0, 0.82, 0.32, minf(1.0, _onboarding_remaining)))
	for action in BUTTONS:
		var data: Dictionary = BUTTONS[action]; var center := _from_design(data.center); var radius := float(data.radius) * scale_value
		var active: bool = action in _button_fingers.values()
		draw_circle(center, radius, Color(0.95, 0.45, 0.12, control_opacity) if active else Color(0.05, 0.08, 0.09, 0.65 * control_opacity))
		draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.75, 0.24, 0.9), maxf(1.0, scale_value))
		var label := String(data.label); var font_size := maxi(7, roundi(8.0 * scale_value)); var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.32), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func _draw_stick(center: Vector2, value: Vector2, label: String, scale_value: float) -> void:
	var radius := _stick_radius() * scale_value
	draw_circle(center, radius, Color(0.03, 0.06, 0.07, 0.48 * control_opacity))
	draw_circle(center, radius * STICK_DEAD_ZONE, Color(0.95, 0.7, 0.18, 0.12 * control_opacity))
	draw_arc(center, radius, 0.0, TAU, 40, Color(0.78, 0.72, 0.42, 0.8), maxf(1.0, scale_value))
	var knob := center + value * radius * 0.68
	draw_circle(knob, radius * 0.38, Color(0.95, 0.7, 0.18, 0.82 * control_opacity))
	var font := ThemeDB.fallback_font; var font_size := maxi(6, roundi(7.0 * scale_value)); var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, center + Vector2(-text_size.x * 0.5, radius * 0.72), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.75))
