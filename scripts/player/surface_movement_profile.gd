class_name SurfaceMovementProfile
extends Resource

@export var id: StringName = &"normal"
@export var surface_ids: Array[StringName] = []
@export_range(0.5, 1.25, 0.01) var speed_multiplier := 1.0
@export_range(0.25, 1.25, 0.01) var acceleration_multiplier := 1.0
@export_range(0.20, 1.25, 0.01) var deceleration_multiplier := 1.0


func applies_to(surface_id: StringName) -> bool:
	return surface_id in surface_ids


func scaled_multiplier(value: float, accessibility_mode: String) -> float:
	match accessibility_mode.to_lower():
		"off":
			return 1.0
		"reduced":
			return lerpf(1.0, value, 0.5)
		_:
			return value


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("surface movement profile has no id")
	if surface_ids.is_empty(): errors.append("surface movement profile %s has no surface ids" % id)
	if speed_multiplier <= 0.0: errors.append("surface movement profile %s has invalid speed" % id)
	if acceleration_multiplier <= 0.0: errors.append("surface movement profile %s has invalid acceleration" % id)
	if deceleration_multiplier <= 0.0: errors.append("surface movement profile %s has invalid deceleration" % id)
	return errors
