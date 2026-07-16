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
	var state := portrait_state()
	var texture := HEALTHY_TEXTURE
	match state:
		State.HURT: texture = HURT_TEXTURE
		State.CRITICAL: texture = CRITICAL_TEXTURE
	var edge := minf(size.x, size.y)
	var portrait_rect := Rect2((size - Vector2.ONE * edge) * 0.5, Vector2.ONE * edge)
	draw_texture_rect(texture, portrait_rect, false)
	# The base portraits read as too similar between states, so layer a
	# deterministic damage overlay — reddening plus cracks — that scales with
	# severity. This makes low health legible even when the art alone does not.
	_draw_damage_overlay(state, portrait_rect)


func _draw_damage_overlay(state: State, rect: Rect2) -> void:
	if state == State.HEALTHY:
		return
	var severe := state == State.CRITICAL
	draw_rect(rect, Color(0.86, 0.12, 0.08, 0.22 if severe else 0.12))
	var crack_color := Color(0.05, 0.02, 0.03, 0.85 if severe else 0.6)
	var crack_width := rect.size.x * (0.03 if severe else 0.022)
	# Normalized crack polylines (0..1 within the portrait). The first two show
	# on HURT; CRITICAL adds a spidered shatter for an unmistakable read.
	var cracks: Array = [
		[Vector2(0.32, 0.0), Vector2(0.42, 0.34), Vector2(0.3, 0.52), Vector2(0.4, 1.0)],
		[Vector2(0.78, 0.0), Vector2(0.62, 0.28), Vector2(0.72, 0.55), Vector2(0.6, 1.0)],
	]
	if severe:
		cracks.append([Vector2(0.0, 0.4), Vector2(0.34, 0.5), Vector2(0.66, 0.44), Vector2(1.0, 0.58)])
		cracks.append([Vector2(0.46, 0.3), Vector2(0.5, 0.5), Vector2(0.42, 0.68), Vector2(0.54, 0.86)])
	for crack: Array in cracks:
		var points := PackedVector2Array()
		for normalized: Vector2 in crack:
			points.append(rect.position + normalized * rect.size)
		draw_polyline(points, crack_color, crack_width, true)
