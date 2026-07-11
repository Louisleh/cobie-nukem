class_name RetroCrosshair
extends Control

@export var target_locked := false:
	set(value):
		target_locked = value
		queue_redraw()

var _shot_result: StringName = &""
var _shot_result_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func show_shot_result(kind: StringName) -> void:
	# A pellet hitting an enemy takes priority over later pellets hitting scenery.
	if _shot_result == &"enemy" and _shot_result_time > 0.0 and kind != &"enemy":
		return
	_shot_result = kind
	_shot_result_time = 0.2 if kind == &"enemy" else 0.13
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
	var color := Color("ffd34d") if target_locked else Color(1, 1, 1, 0.9)
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
		&"world":
			draw_circle(center, 2.0, Color(1.0, 0.8, 0.25, 0.95))
		&"miss":
			draw_arc(center, 7.0, 0, TAU, 12, Color(0.72, 0.78, 0.8, 0.65), 1.0)
