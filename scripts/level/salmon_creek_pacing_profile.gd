class_name SalmonCreekPacingProfile
extends Resource

@export var phase_ids: Array[StringName] = []
@export var phase_cues := PackedStringArray()
@export var phase_recovery_pickups := PackedStringArray()
@export var phase_recovery_positions: Array[Vector3] = []
@export var pressure_distance := Vector2(4.5, 12.0)


func phase_id(phase: int) -> StringName:
	return phase_ids[phase] if phase >= 0 and phase < phase_ids.size() else &"unknown"


func phase_cue(phase: int) -> String:
	return phase_cues[phase] if phase >= 0 and phase < phase_cues.size() else ""


func recovery_drop(phase: int) -> Dictionary:
	if phase < 0 or phase >= phase_recovery_pickups.size() or phase >= phase_recovery_positions.size():
		return {}
	var path := phase_recovery_pickups[phase]
	if path.is_empty():
		return {}
	return {"scene": path, "position": phase_recovery_positions[phase]}


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if phase_ids.size() != phase_cues.size():
		errors.append("Walker phase IDs and cues have different lengths")
	if phase_ids.size() != phase_recovery_pickups.size() or phase_ids.size() != phase_recovery_positions.size():
		errors.append("Walker recovery cadence does not cover every authored phase")
	if pressure_distance.x <= 0.0 or pressure_distance.y <= pressure_distance.x:
		errors.append("Walker pressure distance must be a positive ordered range")
	for phase in mini(phase_recovery_pickups.size(), phase_recovery_positions.size()):
		var path := phase_recovery_pickups[phase]
		if not path.is_empty() and not ResourceLoader.exists(path, "PackedScene"):
			errors.append("Walker phase %d recovery pickup is missing: %s" % [phase, path])
		if not phase_recovery_positions[phase].is_finite():
			errors.append("Walker phase %d recovery position is not finite" % phase)
	return errors
