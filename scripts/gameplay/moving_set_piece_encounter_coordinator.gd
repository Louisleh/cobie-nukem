class_name MovingSetPieceEncounterCoordinator
extends Node

const ERROR_NONE := &""
const ERROR_MISSING_SET_PIECE_RUNTIME := &"missing_set_piece_runtime"
const ERROR_MISSING_MISSION_RUNTIME := &"missing_mission_runtime"
const ERROR_MISSING_DEFINITION := &"missing_definition"
const ERROR_MISSING_ENCOUNTER_ZONE := &"missing_encounter_zone"
const ERROR_MISMATCHED_DEFINITION := &"mismatched_definition"
const ERROR_NON_EXTERNAL_ENCOUNTER := &"non_external_encounter"

var _set_piece_runtime: MovingSetPieceRuntime
var _mission_runtime: MissionRuntime
var _encounter_zone_id: StringName = &""
var _encounter_wave_count := 0
var _encounter_requirement: StringName = &""
var _expected_generation := -1
var _active_zone_generation := -1

var _next_expected_stop_index := 0
var _active_wave_index := -1
var _zone_started := false
var _stops_started: Array[bool] = []
var _waves_completed: Array[bool] = []
var _configured := false
var _schema_version := 1
var _schema2_encounter_ids_by_wave: Array[StringName] = []


func configure(set_piece_runtime: MovingSetPieceRuntime, mission_runtime: MissionRuntime, definition: Object, encounter_zone_id: StringName) -> StringName:
	clear()
	if set_piece_runtime == null:
		return ERROR_MISSING_SET_PIECE_RUNTIME
	if mission_runtime == null:
		return ERROR_MISSING_MISSION_RUNTIME
	if definition == null:
		return ERROR_MISSING_DEFINITION
	if encounter_zone_id == &"":
		return ERROR_MISSING_ENCOUNTER_ZONE
	if mission_runtime.encounters == null:
		return ERROR_MISSING_MISSION_RUNTIME
	if not mission_runtime.encounters.definitions.has(encounter_zone_id):
		return ERROR_MISSING_ENCOUNTER_ZONE
	var encounter_definition := mission_runtime.encounters.definitions.get(encounter_zone_id) as EncounterDefinition
	if encounter_definition == null:
		return ERROR_MISSING_ENCOUNTER_ZONE
	if encounter_definition.wave_progression != EncounterDefinition.WaveProgression.EXTERNAL:
		return ERROR_NON_EXTERNAL_ENCOUNTER

	var wave_count: int = int(encounter_definition.effective_waves().size())
	if wave_count == 0:
		return ERROR_MISMATCHED_DEFINITION

	var schema_version := int(definition.get("schema_version", 1))
	_schema_version = schema_version
	if schema_version == 1:
		if definition.encounter_trigger_ids == null or definition.encounter_trigger_ids.is_empty():
			return ERROR_MISMATCHED_DEFINITION
		if definition.encounter_trigger_ids.size() != 1:
			return ERROR_MISMATCHED_DEFINITION
		if definition.encounter_trigger_ids[0] != encounter_definition.id:
			return ERROR_MISMATCHED_DEFINITION
		_encounter_requirement = definition.encounter_trigger_ids[0]
	elif schema_version == 2:
		if not _is_schema2_encounter_valid(definition, encounter_definition):
			return ERROR_MISMATCHED_DEFINITION
		_encounter_requirement = _encounter_id_for_schema2_definition(definition)
		if _encounter_requirement == &"":
			return ERROR_MISMATCHED_DEFINITION
		if definition.phases is Array and definition.phases.size() != wave_count:
			return ERROR_MISMATCHED_DEFINITION
		if definition.phases is Array:
			_schema2_encounter_ids_by_wave.clear()
			_schema2_encounter_ids_by_wave.resize(wave_count)
			for wave_index in range(wave_count):
				_schema2_encounter_ids_by_wave[wave_index] = &""
			for phase in definition.phases:
				if phase == null:
					return ERROR_MISMATCHED_DEFINITION
				var phase_wave_index := int(phase.get("encounter_wave_index", -1))
				if phase_wave_index < 0 or phase_wave_index >= wave_count:
					return ERROR_MISMATCHED_DEFINITION
				var encounter_id := phase.get("encounter_id", &"") as StringName
				if String(encounter_id).strip_edges().is_empty():
					return ERROR_MISMATCHED_DEFINITION
				_schema2_encounter_ids_by_wave[phase_wave_index] = encounter_id
	else:
		return ERROR_MISMATCHED_DEFINITION
	if definition.stop_markers.size() != 0 and definition.stop_markers.size() != wave_count:
		return ERROR_MISMATCHED_DEFINITION

	_set_piece_runtime = set_piece_runtime
	_mission_runtime = mission_runtime
	_encounter_zone_id = encounter_zone_id
	_encounter_wave_count = wave_count
	_expected_generation = _set_piece_runtime.generation()
	_reset_stage_state()
	_configure_success()
	return ERROR_NONE


func reset() -> bool:
	if not _configured:
		return false
	disconnect_signals()
	var set_piece_ok := _set_piece_runtime != null and bool(_set_piece_runtime.reset())
	var mission_ok := _mission_runtime != null and bool(_mission_runtime.reset_zone(_encounter_zone_id))
	if _set_piece_runtime != null:
		_expected_generation = int(_set_piece_runtime.generation())
	_reset_stage_state()
	connect_signals()
	return set_piece_ok and mission_ok


func clear() -> void:
	disconnect_signals()
	_set_piece_runtime = null
	_mission_runtime = null
	_encounter_zone_id = &""
	_encounter_wave_count = 0
	_encounter_requirement = &""
	_expected_generation = -1
	_active_zone_generation = -1
	_next_expected_stop_index = 0
	_active_wave_index = -1
	_zone_started = false
	_stops_started.clear()
	_waves_completed.clear()
	_schema2_encounter_ids_by_wave.clear()
	_configured = false


func current_state() -> Dictionary:
	return {
		"configured": _configured,
		"encounter_zone_id": _encounter_zone_id,
		"generation": _expected_generation,
		"next_stop_index": _next_expected_stop_index,
		"active_wave_index": _active_wave_index,
		"zone_generation": _active_zone_generation,
		"stops_started": _stops_started.duplicate(),
		"waves_completed": _waves_completed.duplicate(),
	}


func report_module_destroyed(module_id: StringName, observed_generation: int = -1) -> bool:
	if not _configured or not is_instance_valid(_set_piece_runtime):
		return false
	if _set_piece_runtime.generation() != _expected_generation:
		return false
	if observed_generation != -1 and observed_generation != _expected_generation:
		return false
	return bool(_set_piece_runtime.mark_module_destroyed(module_id, _expected_generation))


func _ready() -> void:
	pass


func _exit_tree() -> void:
	clear()


func _configure_success() -> void:
	_configured = true
	connect_signals()


func connect_signals() -> void:
	if _set_piece_runtime == null or _mission_runtime == null:
		return
	if not _set_piece_runtime.stop_reached.is_connected(_on_set_piece_stop_reached):
		_set_piece_runtime.stop_reached.connect(_on_set_piece_stop_reached)
	if not _mission_runtime.wave_completed.is_connected(_on_mission_wave_completed):
		_mission_runtime.wave_completed.connect(_on_mission_wave_completed)


func disconnect_signals() -> void:
	if is_instance_valid(_set_piece_runtime):
		if _set_piece_runtime.stop_reached.is_connected(_on_set_piece_stop_reached):
			_set_piece_runtime.stop_reached.disconnect(_on_set_piece_stop_reached)
	if is_instance_valid(_mission_runtime):
		if _mission_runtime.wave_completed.is_connected(_on_mission_wave_completed):
			_mission_runtime.wave_completed.disconnect(_on_mission_wave_completed)


func _on_set_piece_stop_reached(stop_index: int, _fraction: float) -> void:
	if not _configured or not is_instance_valid(_set_piece_runtime) or not is_instance_valid(_mission_runtime):
		return
	if _set_piece_runtime.generation() != _expected_generation:
		return
	if stop_index < 0 or stop_index >= _encounter_wave_count:
		return
	if stop_index != _next_expected_stop_index:
		return
	if stop_index < _stops_started.size() and _stops_started[stop_index]:
		return

	var accepted := false
	if stop_index == 0:
		accepted = _start_initial_encounter_wave()
	else:
		accepted = _advance_to_next_encounter_wave()
	if not accepted:
		return

	_stops_started[stop_index] = true
	_next_expected_stop_index = stop_index + 1
	_active_wave_index = stop_index


func _on_mission_wave_completed(definition: EncounterDefinition, wave_index: int) -> void:
	if not _configured or not is_instance_valid(_set_piece_runtime) or not is_instance_valid(_mission_runtime):
		return
	if definition == null:
		return
	if definition.zone_id != _encounter_zone_id:
		return
	if _set_piece_runtime.generation() != _expected_generation:
		return
	if wave_index < 0 or wave_index >= _encounter_wave_count:
		return
	if not _stops_started[wave_index]:
		return
	if _waves_completed[wave_index]:
		return
	if _active_wave_index != wave_index:
		return
	if not _is_wave_active_with_matching_generation_and_empty(wave_index):
		return
	_waves_completed[wave_index] = true
	if _schema_version == 1 and wave_index != _encounter_wave_count - 1:
		_set_piece_runtime.resume_from_stop()
		return

	var encounter_id := _encounter_requirement
	if _schema_version == 2:
		encounter_id = _encounter_id_for_wave_index(wave_index)
	if encounter_id == &"":
		_waves_completed[wave_index] = false
		return
	if not _set_piece_runtime.mark_encounter_completed(encounter_id, _expected_generation):
		_waves_completed[wave_index] = false
		return
	_set_piece_runtime.resume_from_stop()


func _start_initial_encounter_wave() -> bool:
	if _zone_started:
		return false
	var actors: Array = _mission_runtime.activate_zone(_encounter_zone_id)
	if actors.is_empty():
		return false
	_zone_started = true
	_active_zone_generation = _current_zone_generation()
	return _active_zone_generation >= 0


func _advance_to_next_encounter_wave() -> bool:
	if not _zone_started:
		return false
	if not _mission_runtime.advance_external_wave(_encounter_zone_id):
		return false
	_active_zone_generation = _current_zone_generation()
	return _active_zone_generation >= 0


func _is_wave_active_with_matching_generation_and_empty(wave_index: int) -> bool:
	if _mission_runtime == null or _mission_runtime.encounters == null:
		return false
	if not _mission_runtime.encounters.active.has(_encounter_zone_id):
		return false
	var active_state: Variant = _mission_runtime.encounters.active.get(_encounter_zone_id)
	if active_state == null or not (active_state is Dictionary):
		return false
	var zone_state := active_state as Dictionary
	if int(zone_state.get("generation", -1)) != _active_zone_generation:
		return false
	if int(zone_state.get("wave", -1)) != wave_index:
		return false
	if int(zone_state.get("remaining", 0)) != 0:
		return false
	return true


func _current_zone_generation() -> int:
	if _mission_runtime == null or _mission_runtime.encounters == null:
		return -1
	if not _mission_runtime.encounters.active.has(_encounter_zone_id):
		return -1
	var active_state: Variant = _mission_runtime.encounters.active.get(_encounter_zone_id)
	if not (active_state is Dictionary):
		return -1
	return int(active_state.get("generation", -1))


func _is_schema2_encounter_valid(definition: Object, encounter_definition: EncounterDefinition) -> bool:
	if definition == null or not (definition.phases is Array):
		return false
	var phase_count: int = definition.phases.size()
	if phase_count == 0:
		return false
	var found := false
	var encounter_id: StringName = &""
	var seen_wave_indices: Dictionary = {}
	for phase in definition.phases:
		if phase == null:
			return false
		if int(phase.get("schema_version", 0)) != 2:
			return false
		var required_id := phase.get("encounter_id", &"") as StringName
		if String(required_id).strip_edges().is_empty():
			return false
		if not found:
			encounter_id = required_id
			found = true
		elif String(required_id) != String(encounter_id):
			return false
		var wave_index := int(phase.get("encounter_wave_index", -1))
		if seen_wave_indices.has(wave_index):
			return false
		seen_wave_indices[wave_index] = true
	return found and String(encounter_id) == String(encounter_definition.id)


func _encounter_id_for_wave_index(wave_index: int) -> StringName:
	if wave_index < 0 or wave_index >= _schema2_encounter_ids_by_wave.size():
		return &""
	return _schema2_encounter_ids_by_wave[wave_index]


func _encounter_id_for_schema2_definition(definition: Object) -> StringName:
	if definition == null or not (definition.phases is Array) or definition.phases.is_empty():
		return &""
	var phase := definition.phases[0] as Object
	if phase == null:
		return &""
	var required_id := phase.get("encounter_id", &"") as StringName
	if String(required_id).strip_edges().is_empty():
		return &""
	return required_id


func _reset_stage_state() -> void:
	_next_expected_stop_index = 0
	_active_wave_index = -1
	_zone_started = false
	_active_zone_generation = -1
	_stops_started.clear()
	_waves_completed.clear()
	_stops_started.resize(_encounter_wave_count)
	_waves_completed.resize(_encounter_wave_count)
	for stop_index in range(_encounter_wave_count):
		_stops_started[stop_index] = false
		_waves_completed[stop_index] = false
