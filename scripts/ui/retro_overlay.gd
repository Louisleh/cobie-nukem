class_name RetroOverlay
extends Control

@export_range(0.0, 1.0) var scanline_opacity := 0.12
@export_range(0.0, 1.0) var vignette_opacity := 0.22

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	for y in range(0, int(size.y), 2):
		draw_rect(Rect2(0, y, size.x, 1), Color(0, 0, 0, scanline_opacity), true)
	var edge := maxf(4.0, minf(size.x, size.y) * 0.035)
	draw_rect(Rect2(0, 0, size.x, edge), Color(0, 0, 0, vignette_opacity), true)
	draw_rect(Rect2(0, size.y - edge, size.x, edge), Color(0, 0, 0, vignette_opacity), true)
	draw_rect(Rect2(0, 0, edge, size.y), Color(0, 0, 0, vignette_opacity), true)
	draw_rect(Rect2(size.x - edge, 0, edge, size.y), Color(0, 0, 0, vignette_opacity), true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

