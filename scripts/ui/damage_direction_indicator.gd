class_name DamageDirectionIndicator
extends Control

var _direction := Vector2(0.0, -1.0)
var _remaining := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func show_damage(player: Node3D, source: Node) -> void:
	if source is Node3D:
		var local := player.global_basis.inverse() * ((source as Node3D).global_position - player.global_position)
		_direction = Vector2(local.x, local.z).normalized()
	else:
		_direction = Vector2(0.0, 1.0)
	_remaining = 0.65
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= 0.0: set_process(false)
	queue_redraw()


func _draw() -> void:
	if _remaining <= 0.0: return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.32
	var direction := _direction.normalized()
	var point := center + direction * radius
	var tangent := Vector2(-direction.y, direction.x)
	var color := Color(1.0, 0.12, 0.04, clampf(_remaining / 0.35, 0.0, 0.9))
	draw_polyline(PackedVector2Array([point - tangent * 13.0 + direction * 5.0, point, point + tangent * 13.0 + direction * 5.0]), color, 4.0, true)
