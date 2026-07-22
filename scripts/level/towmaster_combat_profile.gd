class_name TowmasterCombatProfile
extends Resource

const MIN_PHASES: int = 4
const MIN_ATTACKS: int = 3
const MIN_ARENA_STATES: int = 3
const MILESTONE_ID_KEY: StringName = &"id"
const MILESTONE_TIME_KEY: StringName = &"time"

@export var schema_version: int = 1
@export var id: StringName = &""
@export var attacks: Array[TowmasterAttackDefinition] = []
@export var phases: Array[TowmasterPhaseCombatDefinition] = []
@export_range(1, 6, 1) var max_temp_visuals: int = 6
@export_range(0, 48, 1) var max_defeat_particles: int = 46
@export_range(10.0, 11.0, 0.01) var defeat_duration: float = 10.2
@export var defeat_milestones: Array[Dictionary] = []


func attack_for_id(attack_id: StringName) -> TowmasterAttackDefinition:
	for attack: TowmasterAttackDefinition in attacks:
		if attack != null and attack.id == attack_id:
			return attack
	return null


func phase_at(phase_index: int) -> TowmasterPhaseCombatDefinition:
	if phase_index < 0 or phase_index >= phases.size():
		return null
	return phases[phase_index]


func attack_ids_for_phase(phase_index: int) -> Array[StringName]:
	if phase_index < 0 or phase_index >= phases.size():
		return []
	var phase: TowmasterPhaseCombatDefinition = phases[phase_index]
	if phase == null:
		return []
	return phase.attack_ids.duplicate()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if schema_version != 1:
		errors.append("TowmasterCombatProfile %s has unsupported schema_version %d" % [id, schema_version])

	if id == &"":
		errors.append("TowmasterCombatProfile has empty id")

	if max_temp_visuals < 1 or max_temp_visuals > 6:
		errors.append("TowmasterCombatProfile %s has max_temp_visuals outside [1, 6]" % id)

	if max_defeat_particles < 0 or max_defeat_particles > 48:
		errors.append("TowmasterCombatProfile %s has max_defeat_particles outside [0, 48]" % id)

	if not is_finite(defeat_duration) or defeat_duration < 10.0 or defeat_duration > 11.0:
		errors.append("TowmasterCombatProfile %s has invalid defeat_duration" % id)

	errors.append_array(_validate_milestones())
	errors.append_array(_validate_attacks())
	errors.append_array(_validate_phases())
	return errors


func _validate_attacks() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if attacks.size() != MIN_ATTACKS:
		errors.append("TowmasterCombatProfile %s must define exactly %d attacks" % [id, MIN_ATTACKS])

	var seen_attack_ids: Dictionary = {}
	for index in range(attacks.size()):
		var attack: TowmasterAttackDefinition = attacks[index]
		if attack == null:
			errors.append("TowmasterCombatProfile %s has null attack at index %d" % [id, index])
			continue
		errors.append_array(attack.validate())
		if attack.id == &"":
			errors.append("TowmasterCombatProfile %s attack at index %d has empty id" % [id, index])
			continue
		var key: String = String(attack.id)
		if seen_attack_ids.has(key):
			errors.append("TowmasterCombatProfile %s has duplicate attack id: %s" % [id, attack.id])
		else:
			seen_attack_ids[key] = true

	return errors


func _validate_phases() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if phases.size() != MIN_PHASES:
		errors.append("TowmasterCombatProfile %s must define exactly %d phases" % [id, MIN_PHASES])

	var phase_ids: Dictionary = {}
	var arena_states: Dictionary = {}
	var used_attack_ids: Dictionary = {}
	var arena_state_order: Array[StringName] = []
	for index in range(phases.size()):
		var phase: TowmasterPhaseCombatDefinition = phases[index]
		if phase == null:
			errors.append("TowmasterCombatProfile %s has null phase at index %d" % [id, index])
			continue
		errors.append_array(phase.validate())
		if phase.phase_id == &"":
			continue
		var phase_key: String = String(phase.phase_id)
		if phase_ids.has(phase_key):
			errors.append("TowmasterCombatProfile %s has duplicate phase id: %s" % [id, phase.phase_id])
		else:
			phase_ids[phase_key] = true

		if phase.arena_state_id == &"":
			continue
		var arena_state: StringName = phase.arena_state_id
		arena_states[String(arena_state)] = true
		arena_state_order.append(arena_state)

		for attack_index in range(phase.attack_ids.size()):
			var attack_id: StringName = phase.attack_ids[attack_index]
			if attack_id == &"":
				errors.append("TowmasterCombatProfile %s phase %s has empty attack_ids[%d]" % [id, phase.phase_id, attack_index])
				continue
			var attack_key: String = String(attack_id)
			used_attack_ids[attack_key] = true
			if not _attack_exists(attack_id):
				errors.append("TowmasterCombatProfile %s phase %s references missing attack %s" % [id, phase.phase_id, attack_id])

	if arena_states.size() < MIN_ARENA_STATES:
		errors.append("TowmasterCombatProfile %s has fewer than %d distinct arena states" % [id, MIN_ARENA_STATES])

	var all_attack_ids: Dictionary = _attack_id_set()
	if all_attack_ids.size() != attacks.size():
		errors.append("TowmasterCombatProfile %s has invalid attack definition set" % id)
	for attack_id in all_attack_ids:
		if not used_attack_ids.has(attack_id):
			errors.append("TowmasterCombatProfile %s has unused attack: %s" % [id, attack_id])

	var arena_changes: int = 0
	for index in range(arena_state_order.size() - 1):
		if arena_state_order[index] != arena_state_order[index + 1]:
			arena_changes += 1
	if arena_changes < 2:
		errors.append("TowmasterCombatProfile %s should have at least 2 arena state transitions" % id)

	return errors


func _attack_exists(attack_id: StringName) -> bool:
	return attack_for_id(attack_id) != null


func _attack_id_set() -> Dictionary:
	var ids: Dictionary = {}
	for attack in attacks:
		if attack == null or attack.id == &"":
			continue
		ids[String(attack.id)] = true
	return ids


func _validate_milestones() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if defeat_milestones.is_empty():
		errors.append("TowmasterCombatProfile %s has no defeat_milestones" % id)
		return errors

	var previous_time: float = -1.0
	var seen_ids: Dictionary = {}
	for index in range(defeat_milestones.size()):
		var raw: Variant = defeat_milestones[index]
		if raw == null or not (raw is Dictionary):
			errors.append("TowmasterCombatProfile %s defeat_milestones[%d] must be a Dictionary" % [id, index])
			continue
		var milestone: Dictionary = raw
		var milestone_id: String = String(milestone.get(MILESTONE_ID_KEY, ""))
		if milestone_id.strip_edges().is_empty():
			errors.append("TowmasterCombatProfile %s defeat_milestones[%d] has empty id" % [id, index])
		elif seen_ids.has(milestone_id):
			errors.append("TowmasterCombatProfile %s defeat_milestones has duplicate id %s" % [id, milestone_id])
		else:
			seen_ids[milestone_id] = true

		var raw_time: Variant = milestone.get(MILESTONE_TIME_KEY, null)
		if not _is_float_time(raw_time):
			errors.append("TowmasterCombatProfile %s defeat_milestones[%d] has invalid time type" % [id, index])
			continue
		var milestone_time: float = float(raw_time)
		if not is_finite(milestone_time) or milestone_time < 0.0 or milestone_time > defeat_duration:
			errors.append("TowmasterCombatProfile %s defeat_milestones[%d] has out-of-range time %.3f" % [id, index, milestone_time])
			continue
		if index > 0 and milestone_time <= previous_time:
			errors.append("TowmasterCombatProfile %s defeat_milestones are not strictly ordered" % id)
		previous_time = milestone_time

	if defeat_milestones.size() >= 1:
		var first_raw: Variant = defeat_milestones[0]
		if first_raw == null or not (first_raw is Dictionary):
			errors.append("TowmasterCombatProfile %s first defeat_milestone must be a Dictionary" % id)
			return errors
		var first_raw_dict: Dictionary = first_raw
		var first_time: float = float(first_raw_dict.get(MILESTONE_TIME_KEY, -1.0))
		if not is_equal_approx(first_time, 0.0):
			errors.append("TowmasterCombatProfile %s first defeat_milestone must be at time 0" % id)

	var last_raw: Variant = defeat_milestones[defeat_milestones.size() - 1]
	if last_raw == null or not (last_raw is Dictionary):
		errors.append("TowmasterCombatProfile %s last defeat_milestone must be a Dictionary" % id)
		return errors
	var last_raw_dict: Dictionary = last_raw
	var last_time: float = float(last_raw_dict.get(MILESTONE_TIME_KEY, -1.0))
	if not is_equal_approx(last_time, defeat_duration):
		errors.append("TowmasterCombatProfile %s last defeat_milestone must be at defeat_duration %.2f" % [id, defeat_duration])

	return errors


func _is_float_time(value: Variant) -> bool:
	if value is String or value == null:
		return false
	if not (value is float or value is int):
		return false
	var converted: float = float(value)
	return is_finite(converted)
