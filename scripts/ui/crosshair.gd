class_name RetroCrosshair
extends Control

@export var target_locked := false:
	set(value):
		target_locked = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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

