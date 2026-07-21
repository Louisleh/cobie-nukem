class_name TactileFeedback
extends Node

signal vibration_requested(weak: float, strong: float, duration: float)

@export var camera: Camera3D
@export_range(0.0, 1.0) var shake_scale := 1.0
@export var reduced_flashes := false

var _trauma := 0.0
var _time := 0.0
var _base_h_offset := 0.0
var _base_v_offset := 0.0
var _base_shake_scale := 1.0

func _ready() -> void:
	if camera != null:
		_base_h_offset = camera.h_offset
		_base_v_offset = camera.v_offset
	_base_shake_scale = shake_scale
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		_apply_runtime_settings(settings)
		settings.setting_changed.connect(_on_setting_changed)


func _apply_runtime_settings(settings: Node) -> void:
	shake_scale = _base_shake_scale * clampf(float(settings.get_value(&"accessibility", &"camera_shake", 1.0)), 0.0, 1.0)
	if bool(settings.get_value(&"accessibility", &"reduced_motion", false)):
		shake_scale = 0.0
	reduced_flashes = bool(settings.get_value(&"video", &"reduced_flashes", false))


func _on_setting_changed(section: StringName, _key: StringName, _value: Variant) -> void:
	if section in [&"accessibility", &"video"]:
		_apply_runtime_settings(get_node("/root/SettingsManager"))

func _process(delta: float) -> void:
	if camera == null:
		return
	_time += delta
	_trauma = maxf(0.0, _trauma - delta * 3.5)
	var amount := _trauma * _trauma * shake_scale
	# Projection offsets provide readable shake without rotating the authoritative
	# camera basis used by weapon rays and auto aim.
	camera.h_offset = _base_h_offset + sin(_time * 47.0) * amount * 0.04
	camera.v_offset = _base_v_offset + cos(_time * 41.0) * amount * 0.035

func kick(amount: float, weak_vibration := 0.0, strong_vibration := 0.0, duration := 0.08) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	vibration_requested.emit(weak_vibration, strong_vibration, duration)
	if weak_vibration > 0.0 or strong_vibration > 0.0:
		Input.start_joy_vibration(0, weak_vibration, strong_vibration, duration)
