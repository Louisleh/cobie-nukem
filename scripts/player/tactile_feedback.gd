class_name TactileFeedback
extends Node

signal vibration_requested(weak: float, strong: float, duration: float)

@export var camera: Camera3D
@export_range(0.0, 1.0) var shake_scale := 1.0
@export var reduced_flashes := false

var _trauma := 0.0
var _time := 0.0
var _base_rotation := Vector3.ZERO

func _ready() -> void:
	if camera != null:
		_base_rotation = camera.rotation

func _process(delta: float) -> void:
	if camera == null:
		return
	_time += delta
	_trauma = maxf(0.0, _trauma - delta * 3.5)
	var amount := _trauma * _trauma * shake_scale
	camera.rotation = _base_rotation + Vector3(
		sin(_time * 47.0) * amount * 0.018,
		cos(_time * 41.0) * amount * 0.014,
		sin(_time * 53.0) * amount * 0.008
	)

func kick(amount: float, weak_vibration := 0.0, strong_vibration := 0.0, duration := 0.08) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	vibration_requested.emit(weak_vibration, strong_vibration, duration)
	if weak_vibration > 0.0 or strong_vibration > 0.0:
		Input.start_joy_vibration(0, weak_vibration, strong_vibration, duration)
