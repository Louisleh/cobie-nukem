class_name RetroCrosshair
extends Control

@export var target_locked := false:
	set(value):
		target_locked = value
		queue_redraw()
@export var high_contrast := false:
	set(value): high_contrast = value; queue_redraw()

var _shot_result: StringName = &""
var _shot_result_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func show_shot_result(kind: StringName) -> void:
	_show_shot_result(kind)


func show_shot_feedback(event: CombatFeedbackEvent) -> void:
	var kind := event.legacy_kind()
	if event.hit_type == CombatFeedbackEvent.HitType.ENEMY and event.killed:
		kind = &"kill"
	_show_shot_result(kind)


func _show_shot_result(kind: StringName) -> void:
	var priority_map := {
		&"": 0,
		&"miss": 1,
		&"world": 2,
		&"destructible": 3,
		&"enemy": 4,
		&"kill": 5,
	}
	if _shot_result_time > 0.0 and priority_map.get(_shot_result, 0) >= priority_map.get(kind, 0):
		return
	if not priority_map.has(kind):
		return
	# A pellet hitting an enemy takes priority over later pellets hitting scenery.
	_shot_result = kind
	_shot_result_time = 0.2 if kind == &"kill" or kind == &"enemy" or kind == &"destructible" else 0.13
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_shot_result_time = maxf(0.0, _shot_result_time - delta)
	if _shot_result_time <= 0.0:
		_shot_result = &""
		set_process(false)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var color := (Color("00ffff") if target_locked else Color("ffff00")) if high_contrast else (Color("ffd34d") if target_locked else Color(1, 1, 1, 0.9))
	var gap := 3.0
	var length := 4.0
	draw_line(center + Vector2(-gap - length, 0), center + Vector2(-gap, 0), color, 1)
	draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), color, 1)
	draw_line(center + Vector2(0, -gap - length), center + Vector2(0, -gap), color, 1)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), color, 1)
	if target_locked:
		draw_arc(center, 10, 0, TAU, 16, color, 1)
	match _shot_result:
		&"enemy":
			var hit_color := Color(1.0, 0.2, 0.08, 1.0)
			draw_line(center + Vector2(-5, -5), center + Vector2(-2, -2), hit_color, 1.5)
			draw_line(center + Vector2(5, -5), center + Vector2(2, -2), hit_color, 1.5)
			draw_line(center + Vector2(-5, 5), center + Vector2(-2, 2), hit_color, 1.5)
			draw_line(center + Vector2(5, 5), center + Vector2(2, 2), hit_color, 1.5)
		&"destructible":
			var hit_color := Color(1.0, 0.64, 0.14, 1.0)
			draw_arc(center, 7.0, 0, TAU, 16, hit_color, 1.0)
			for index in 2:
				draw_line(center + Vector2(-4, -4 + index * 8), center + Vector2(4, 4 - index * 8), hit_color, 1.1)
				draw_line(center + Vector2(-4, 4 - index * 8), center + Vector2(4, -4 + index * 8), hit_color, 1.1)
		&"kill":
			var hit_color := Color(1.0, 0.0, 0.15, 1.0)
			draw_circle(center, 2.8, hit_color)
			draw_line(center + Vector2(-7, -1), center + Vector2(7, 1), hit_color, 2.0)
			draw_line(center + Vector2(-7, 1), center + Vector2(7, -1), hit_color, 2.0)
		&"world":
			draw_circle(center, 2.0, Color(1.0, 0.8, 0.25, 0.95))
		&"miss":
			draw_arc(center, 7.0, 0, TAU, 12, Color(0.72, 0.78, 0.8, 0.65), 1.0)
