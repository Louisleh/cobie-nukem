class_name CobiePortrait
extends Control

enum State { HEALTHY, CRITICAL }

const HEALTHY_TEXTURE := preload("res://assets/ui/portraits/cobie_healthy.png")
const CRITICAL_TEXTURE := preload("res://assets/ui/portraits/cobie_critical.png")
const CRITICAL_THRESHOLD := 0.65

@export var ring_color := Color("f4b63d"):
	set(value):
		ring_color = value
		queue_redraw()

@export_range(0.0, 1.0) var health_ratio := 1.0:
	set(value):
		health_ratio = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()


func portrait_state() -> State:
	if health_ratio < CRITICAL_THRESHOLD:
		return State.CRITICAL
	return State.HEALTHY


func _draw() -> void:
	var state := portrait_state()
	var texture := HEALTHY_TEXTURE
	if state == State.CRITICAL:
		texture = CRITICAL_TEXTURE
	var edge := minf(size.x, size.y)
	var portrait_rect := Rect2((size - Vector2.ONE * edge) * 0.5, Vector2.ONE * edge)
	draw_texture_rect(texture, portrait_rect, false)
	# Keep a strong circular HUD silhouette without baking UI chrome into the
	# owner-approved source art. The tighter 512px crops make Cobie's face read
	# on Retina iPads while the ring remains crisp at every supported scale.
	var center := portrait_rect.get_center()
	draw_arc(center, edge * 0.485, 0.0, TAU, 96, ring_color, maxf(2.0, edge * 0.022), true)
