class_name MovementEnvironmentProfile
extends Resource

@export var id: StringName = &"normal_gravity"
@export_range(0.1, 2.0, 0.01) var gravity_multiplier := 1.0
@export_range(0.5, 2.0, 0.01) var jump_multiplier := 1.0
@export_range(0.1, 2.0, 0.01) var air_control_multiplier := 1.0
@export_range(2.0, 100.0, 0.5) var terminal_fall_speed := 45.0
@export_range(0.0, 2.0, 0.01) var projectile_gravity_multiplier := 1.0


func multiplier(value: float, assist_mode: String) -> float:
	match assist_mode.strip_edges().to_lower():
		"assisted", "off": return 1.0
		"reduced": return lerpf(1.0, value, 0.5)
		_: return value


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("movement environment has empty id")
	if not is_finite(gravity_multiplier) or gravity_multiplier <= 0.0: errors.append("movement environment %s has invalid gravity" % id)
	if not is_finite(jump_multiplier) or jump_multiplier <= 0.0: errors.append("movement environment %s has invalid jump" % id)
	if not is_finite(air_control_multiplier) or air_control_multiplier <= 0.0: errors.append("movement environment %s has invalid air control" % id)
	if not is_finite(terminal_fall_speed) or terminal_fall_speed <= 0.0: errors.append("movement environment %s has invalid terminal speed" % id)
	return errors
