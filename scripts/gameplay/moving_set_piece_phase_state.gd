class_name MovingSetPiecePhaseState
extends RefCounted

var ids: Array[StringName] = []
var stop_markers: Array[float] = []
var encounter_requirements: Array[StringName] = []
var module_requirements: Array[StringName] = []
var health_max: Array[float] = []
var health_current: Array[float] = []
var encounter_completed: Array[bool] = []
var module_completed: Array[bool] = []
var completed_ids: Array[StringName] = []
var wave_to_phase: Array[int] = []
var active_index := 0
var current_health := 0.0
var max_health := 0.0
var last_health_delta := 0.0


func configure(definitions: Array) -> bool:
	clear()
	if definitions.is_empty():
		return false
	var count := definitions.size()
	health_max.resize(count)
	health_current.resize(count)
	encounter_requirements.resize(count)
	module_requirements.resize(count)
	ids.resize(count)
	wave_to_phase.resize(count)
	wave_to_phase.fill(-1)
	for index in range(count):
		var phase := definitions[index] as MovingSetPiecePhaseDefinition
		if phase == null or phase.encounter_wave_index < 0 or phase.encounter_wave_index >= count:
			clear()
			return false
		stop_markers.append(phase.stop_marker)
		ids[index] = phase.phase_id
		encounter_requirements[index] = phase.encounter_id
		module_requirements[index] = phase.required_module_id
		health_max[index] = phase.health_allocation if is_finite(phase.health_allocation) else 0.0
		wave_to_phase[phase.encounter_wave_index] = index
	reset()
	return true


func clear() -> void:
	ids.clear()
	stop_markers.clear()
	encounter_requirements.clear()
	module_requirements.clear()
	health_max.clear()
	health_current.clear()
	encounter_completed.clear()
	module_completed.clear()
	completed_ids.clear()
	wave_to_phase.clear()
	active_index = 0
	current_health = 0.0
	max_health = 0.0
	last_health_delta = 0.0


func reset() -> void:
	active_index = 0
	completed_ids.clear()
	encounter_completed = []
	module_completed = []
	health_current = health_max.duplicate()
	max_health = 0.0
	for index in range(ids.size()):
		encounter_completed.append(false)
		module_completed.append(false)
		var value := health_max[index]
		if is_finite(value):
			max_health += value
	current_health = max_health
	last_health_delta = 0.0


func mark_encounter(id: StringName, active_wave_index: int) -> bool:
	var phase_index := phase_index_for_wave(active_wave_index)
	if phase_index == -1:
		phase_index = active_index
	if phase_index < 0 or phase_index >= encounter_requirements.size():
		return false
	if String(id).strip_edges().to_lower() != String(encounter_requirements[phase_index]).strip_edges().to_lower():
		return false
	if encounter_completed[phase_index]:
		return false
	encounter_completed[phase_index] = true
	return true


func mark_module(id: StringName) -> bool:
	last_health_delta = 0.0
	if active_index < 0 or active_index >= module_requirements.size():
		return false
	if String(id).strip_edges().to_lower() != String(module_requirements[active_index]).strip_edges().to_lower():
		return false
	if module_completed[active_index]:
		return false
	module_completed[active_index] = true
	last_health_delta = health_current[active_index]
	health_current[active_index] = 0.0
	current_health = max(0.0, current_health - last_health_delta)
	return true


func finalize_completed() -> bool:
	var changed := false
	while active_index < ids.size() and is_complete(active_index):
		var phase_id := ids[active_index]
		if phase_id != &"" and not completed_ids.has(phase_id):
			completed_ids.append(phase_id)
		active_index += 1
		changed = true
	return changed


func all_complete() -> bool:
	for phase_index in range(ids.size()):
		if not is_complete(phase_index):
			return false
	return true


func is_complete(phase_index: int) -> bool:
	return phase_index >= 0 and phase_index < ids.size() and encounter_completed[phase_index] and module_completed[phase_index]


func active_id() -> StringName:
	return ids[active_index] if active_index >= 0 and active_index < ids.size() else &""


func phase_index_for_wave(wave_index: int) -> int:
	return wave_to_phase[wave_index] if wave_index >= 0 and wave_index < wave_to_phase.size() else -1


func phase_id_for_wave(wave_index: int) -> StringName:
	var phase_index := phase_index_for_wave(wave_index)
	return ids[phase_index] if phase_index >= 0 and phase_index < ids.size() else &""


func snapshot() -> Dictionary:
	return {
		"active_phase_index": active_index,
		"phase_index": active_index,
		"phase_ids": ids.duplicate(),
		"completed_phase_ids": completed_ids.duplicate(),
		"phase_health": health_current.duplicate(),
		"phase_health_max": health_max.duplicate(),
		"current_boss_health": current_health,
		"max_boss_health": max_health,
	}
