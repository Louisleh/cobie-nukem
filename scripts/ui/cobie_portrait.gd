class_name CobiePortrait
extends Control

enum State { HEALTHY, HURT, CRITICAL }

const HEALTHY_TEXTURE := preload("res://assets/ui/portraits/cobie_healthy.png")
const HURT_TEXTURE := preload("res://assets/ui/portraits/cobie_hurt.png")
const CRITICAL_TEXTURE := preload("res://assets/ui/portraits/cobie_critical.png")

@export_range(0.0, 1.0) var health_ratio := 1.0:
	set(value):
		health_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()


func portrait_state() -> State:
	if health_ratio < 0.3:
		return State.CRITICAL
	if health_ratio < 0.7:
		return State.HURT
	return State.HEALTHY


func _draw() -> void:
	var texture := HEALTHY_TEXTURE
	match portrait_state():
		State.HURT: texture = HURT_TEXTURE
		State.CRITICAL: texture = CRITICAL_TEXTURE
	var edge := minf(size.x, size.y)
	var portrait_rect := Rect2((size - Vector2.ONE * edge) * 0.5, Vector2.ONE * edge)
	draw_texture_rect(texture, portrait_rect, false)
