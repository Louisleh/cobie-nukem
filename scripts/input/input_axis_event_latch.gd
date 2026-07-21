class_name InputAxisEventLatch
extends RefCounted

const InputMathScript = preload("res://scripts/input/input_math.gd")
const PRESS_THRESHOLD := 0.65
const RELEASE_THRESHOLD := 0.45

var _down: Dictionary = {}


func clear() -> void:
	_down.clear()


func pressed(
	action: StringName,
	binding: Dictionary,
	event: InputEventJoypadMotion,
	profile: InputProfile,
	active_device_id: int
) -> bool:
	if binding.get("type", "") != "axis":
		return false
	if active_device_id >= 0 and event.device != active_device_id:
		return false
	var axis := int(binding.get("index", -1))
	if axis < 0 or event.axis != axis:
		return false
	var processed := InputMathScript.process_axis(event.axis_value, profile.axis_config(axis))
	var strength: float
	if binding.get("range", "directional") == "full_range":
		strength = clampf((processed + 1.0) * 0.5, 0.0, 1.0)
	else:
		strength = maxf(0.0, processed * signf(float(binding.get("direction", 1.0))))
	var key := "%s:%d:%d:%s:%s" % [action, event.device, axis, binding.get("direction", 1.0), binding.get("range", "directional")]
	var was_down := bool(_down.get(key, false))
	if strength <= RELEASE_THRESHOLD:
		_down[key] = false
		return false
	if strength >= PRESS_THRESHOLD:
		_down[key] = true
		return not was_down
	return false
