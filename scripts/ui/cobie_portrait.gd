class_name CobiePortrait
extends Control

@export_range(0.0, 1.0) var health_ratio := 1.0:
	set(value):
		health_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	var center := size * Vector2(0.5, 0.46)
	var fur := Color("d9a35f") if health_ratio > 0.3 else Color("a66a45")
	draw_circle(center + Vector2(-9, -6), 8, fur)
	draw_circle(center + Vector2(9, -6), 8, fur)
	draw_circle(center, 15, fur)
	draw_circle(center + Vector2(0, 7), 7, Color("efbd78"))
	draw_circle(center + Vector2(0, 5), 3, Color("17191c"))
	draw_rect(Rect2(center + Vector2(-14, -5), Vector2(28, 6)), Color("111318"), true)
	draw_circle(center + Vector2(-7, -2), 5, Color("20252b"))
	draw_circle(center + Vector2(7, -2), 5, Color("20252b"))
	draw_line(center + Vector2(-2, -2), center + Vector2(2, -2), Color("dca24b"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(3, 33), Vector2(37, 33), Vector2(32, 48), Vector2(8, 48)]), Color("17191c"))
	if health_ratio < 0.65:
		draw_line(center + Vector2(-12, 10), center + Vector2(-7, 14), Color("ef4b3e"), 2)
	if health_ratio < 0.3:
		draw_line(center + Vector2(7, -6), center + Vector2(12, 2), Color("ef4b3e"), 2)

