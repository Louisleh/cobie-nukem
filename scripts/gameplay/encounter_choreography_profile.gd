class_name EncounterChoreographyProfile
extends Resource

@export var id: StringName = &"encounter_choreography"
@export var intent := "default encounter choreography intent"
@export var role_ids: Array[StringName] = []
@export var approach_ids: Array[StringName] = []
@export var recovery_position: Vector3 = Vector3.ZERO
@export var environment_choice_ids: Array[StringName] = []
@export var wave_transition_ids: Array[StringName] = []
@export var counterplay_ids: Array[StringName] = []


func validate(wave_count: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("encounter choreography profile id is empty")
	if intent.strip_edges().is_empty(): errors.append("encounter choreography profile %s has empty intent" % id)

	var validated_roles := _unique_nonempty_ids(role_ids)
	if validated_roles.size() < 3:
		errors.append("encounter choreography profile %s has fewer than three unique nonempty roles" % id)

	var validated_approaches := _unique_nonempty_ids(approach_ids)
	if validated_approaches.size() < 2:
		errors.append("encounter choreography profile %s has fewer than two unique nonempty approaches" % id)

	var recovery_position_is_finite := is_finite(recovery_position.x) and is_finite(recovery_position.y) and is_finite(recovery_position.z)
	if not recovery_position_is_finite:
		errors.append("encounter choreography profile %s has invalid non-finite recovery_position" % id)

	var validated_environment := _unique_nonempty_ids(environment_choice_ids)
	if validated_environment.is_empty():
		errors.append("encounter choreography profile %s has no nonempty environment_choice_ids" % id)

	var validated_counterplay := _unique_nonempty_ids(counterplay_ids)
	if validated_counterplay.is_empty():
		errors.append("encounter choreography profile %s has no nonempty counterplay_ids" % id)

	if wave_count < 0 or wave_transition_ids.size() != wave_count:
		errors.append("encounter choreography profile %s has transition count %d but requires %d to match wave_count" % [id, wave_transition_ids.size(), wave_count])

	return errors


func context_for_wave(index: int) -> Dictionary:
	var wave_index: int = index
	if wave_index < 0:
		wave_index = 0
	var context := {
		"encounter_role_id": _cyclic_choice(role_ids, wave_index),
		"encounter_approach_id": _cyclic_choice(approach_ids, wave_index),
		"encounter_transition_id": _cyclic_choice(wave_transition_ids, wave_index),
		"encounter_recovery_position": recovery_position,
		"encounter_environment_choice_ids": environment_choice_ids.duplicate(true),
		"encounter_counterplay_ids": counterplay_ids.duplicate(true),
		"encounter_counterplay_id": _cyclic_choice(counterplay_ids, wave_index),
	}
	return context


func _unique_nonempty_ids(values: Array[StringName]) -> Dictionary:
	var normalized: Dictionary = {}
	for value in values:
		if value is StringName:
			var entry: StringName = value
			if entry == &"":
				continue
			normalized[entry] = true
	return normalized


func _cyclic_choice(values: Array[StringName], index: int) -> StringName:
	if values.is_empty():
		return &""
	return values[index % values.size()]
