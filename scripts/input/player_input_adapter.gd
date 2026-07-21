class_name PlayerInputAdapter
extends RefCounted

const EVENT_ACTIONS := [
	&"jump",
	&"run",
	&"reload",
	&"weapon_next",
	&"weapon_previous",
	&"fire_primary",
	&"fire_secondary",
	&"use",
]


static func resolve_service(current: Node, owner: Node) -> Node:
	if current != null:
		return current
	return owner.get_node_or_null("/root/InputManager") if owner != null else null


static func event_action(service: Node, event: InputEvent) -> StringName:
	if service == null or not service.has_method("is_action_event_pressed"):
		return &""
	for action in EVENT_ACTIONS:
		if service.is_action_event_pressed(event, action):
			return action
	return &""


static func run_mode(owner: Node) -> String:
	var settings := owner.get_node_or_null("/root/SettingsManager") if owner != null else null
	if settings != null and settings.has_method("get_value"):
		return String(settings.call("get_value", &"gameplay", &"run_mode", "hold"))
	return "hold"


static func look_axes(service: Node) -> Vector2:
	if service == null:
		return Vector2.ZERO
	return Vector2(
		service.get_axis(&"look_left", &"look_right"),
		service.get_axis(&"look_up", &"look_down")
	)


static func weapon_shortcut(event: InputEvent, last_wheel_time_ms: int) -> Dictionary:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_UP:
				return {"delta": -1}
			KEY_DOWN:
				return {"delta": 1}
			KEY_1:
				return {"slot": 0}
			KEY_2:
				return {"slot": 1}
			KEY_3:
				return {"slot": 2}
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var now := Time.get_ticks_msec()
		return {
			"delta": -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1,
			"wheel_time_ms": now,
			"debounced": now - last_wheel_time_ms < 180,
		}
	return {}
