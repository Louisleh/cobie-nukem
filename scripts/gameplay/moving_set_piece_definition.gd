class_name MovingSetPieceDefinition
extends Resource

enum ResetPolicy {
	NO_RESET,
	RETURN_TO_START,
	LOOP,
	PAUSE,
}

enum MotionMode {
	PATH,
	STATIONARY,
}

@export var id: StringName = &"moving_set_piece"
@export var schema_version := 1
@export var motion_mode: MotionMode = MotionMode.PATH
@export_file(".tscn") var actor_scene_path := ""
@export var path_points: Array[Vector3] = []
@export_range(0.05, 120.0, 0.05) var speed := 3.0
@export var stop_markers: Array[float] = []
@export var encounter_trigger_ids: Array[StringName] = []
@export var destructible_module_ids: Array[StringName] = []
@export var completion_event: StringName = &""
@export var reset_policy: ResetPolicy = ResetPolicy.LOOP
@export var phases: Array[MovingSetPiecePhaseDefinition] = []


func validate() -> PackedStringArray:
	if schema_version == 1:
		return _validate_schema_v1()
	if schema_version == 2:
		return _validate_schema_v2()
	return ["moving_set_piece_definition %s has unsupported schema_version %d" % [id, schema_version]]


func _validate_schema_v1() -> PackedStringArray:
	var errors := PackedStringArray()
	if motion_mode != MotionMode.PATH:
		errors.append("moving_set_piece_definition %s schema_version=1 only supports PATH motion" % id)
	if id == &"":
		errors.append("moving_set_piece_definition has empty id")
	if actor_scene_path.is_empty():
		errors.append("moving_set_piece_definition %s has empty actor_scene_path" % id)
	else:
		if not ResourceLoader.exists(actor_scene_path):
			errors.append("moving_set_piece_definition %s actor_scene_path missing: %s" % [id, actor_scene_path])
		else:
			var packed := load(actor_scene_path)
			if packed == null or not packed is PackedScene:
				errors.append("moving_set_piece_definition %s actor_scene_path is not a PackedScene: %s" % [id, actor_scene_path])
	if path_points.size() < 2:
		errors.append("moving_set_piece_definition %s must have at least two path points" % id)
	for point_index in range(path_points.size()):
		var point: Vector3 = path_points[point_index]
		if not point.is_finite():
			errors.append("moving_set_piece_definition %s path_points[%d] is not finite" % [id, point_index])
	if not is_finite(speed) or speed <= 0.0:
		errors.append("moving_set_piece_definition %s speed must be positive and finite" % id)
	var previous_marker_set := false
	var previous_marker := 0.0
	for marker_index in range(stop_markers.size()):
		var marker := stop_markers[marker_index]
		if not is_finite(marker) or marker < 0.0 or marker > 1.0:
			errors.append("moving_set_piece_definition %s stop_markers[%d] must be finite and within [0.0, 1.0]" % [id, marker_index])
			continue
		if previous_marker_set and marker < previous_marker:
			errors.append("moving_set_piece_definition %s stop_markers must be ordered" % id)
			break
		previous_marker_set = true
		previous_marker = marker
	if _has_duplicate_stop_markers(stop_markers):
		errors.append("moving_set_piece_definition %s has duplicate stop_markers" % id)
	if completion_event == &"":
		errors.append("moving_set_piece_definition %s missing completion_event" % id)
	for index in range(encounter_trigger_ids.size()):
		if encounter_trigger_ids[index] == &"":
			errors.append("moving_set_piece_definition %s has empty encounter_trigger_ids[%d]" % [id, index])
	for index in range(destructible_module_ids.size()):
		if destructible_module_ids[index] == &"":
			errors.append("moving_set_piece_definition %s has empty destructible_module_ids[%d]" % [id, index])
	var seen: Dictionary = {}
	for module_id in destructible_module_ids:
		var key := String(module_id)
		if key != "" and seen.has(key):
			errors.append("moving_set_piece_definition %s has duplicate destructible_module_id: %s" % [id, module_id])
		else:
			seen[key] = true
	return errors


func _validate_schema_v2() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("moving_set_piece_definition has empty id")
	if actor_scene_path.is_empty():
		errors.append("moving_set_piece_definition %s has empty actor_scene_path" % id)
	else:
		if not ResourceLoader.exists(actor_scene_path):
			errors.append("moving_set_piece_definition %s actor_scene_path missing: %s" % [id, actor_scene_path])
		else:
			var packed := load(actor_scene_path)
			if packed == null or not packed is PackedScene:
				errors.append("moving_set_piece_definition %s actor_scene_path is not a PackedScene: %s" % [id, actor_scene_path])
	if motion_mode == MotionMode.PATH and path_points.size() < 2:
		errors.append("moving_set_piece_definition %s PATH motion must have at least two path points" % id)
	elif motion_mode == MotionMode.STATIONARY and path_points.size() > 1:
		errors.append("moving_set_piece_definition %s STATIONARY motion accepts at most one spawn point" % id)
	for point_index in range(path_points.size()):
		var point: Vector3 = path_points[point_index]
		if not point.is_finite():
			errors.append("moving_set_piece_definition %s path_points[%d] is not finite" % [id, point_index])
	if motion_mode == MotionMode.PATH and (not is_finite(speed) or speed <= 0.0):
		errors.append("moving_set_piece_definition %s speed must be positive and finite" % id)
	if completion_event == &"":
		errors.append("moving_set_piece_definition %s missing completion_event" % id)

	if phases.size() != 4:
		errors.append("moving_set_piece_definition %s requires exactly four schema_version=2 phases" % id)
	var expected_wave_count := phases.size()
	var seen_waves: Dictionary = {}
	var seen_module_ids: Dictionary = {}
	var seen_phase_ids: Dictionary = {}
	var last_stop := -1.0
	var derived_markers: Array[float] = []
	var derived_encounter_ids: Array[StringName] = []
	var has_invalid_phase := false

	for index in range(phases.size()):
		var phase := phases[index]
		if phase == null:
			errors.append("moving_set_piece_definition %s has null phase at index %d" % [id, index])
			continue
		has_invalid_phase = has_invalid_phase or phase == null
		errors.append_array(phase.validate())
		if seen_phase_ids.has(String(phase.phase_id)):
			errors.append("moving_set_piece_definition %s has duplicate phase_id: %s" % [id, phase.phase_id])
		else:
			seen_phase_ids[String(phase.phase_id)] = true
		if phase.encounter_wave_index < 0:
			errors.append("moving_set_piece_definition %s phase %s has negative encounter_wave_index" % [id, phase.phase_id])
		elif phase.encounter_wave_index >= expected_wave_count:
			errors.append("moving_set_piece_definition %s phase %s has encounter_wave_index %d outside phase count" % [id, phase.phase_id, phase.encounter_wave_index])
		elif seen_waves.has(phase.encounter_wave_index):
			errors.append("moving_set_piece_definition %s has duplicate encounter_wave_index %d" % [id, phase.encounter_wave_index])
		else:
			seen_waves[phase.encounter_wave_index] = true
		if not is_finite(phase.stop_marker) or phase.stop_marker < 0.0 or phase.stop_marker > 1.0:
			errors.append("moving_set_piece_definition %s phase %s has invalid stop_marker" % [id, phase.phase_id])
			continue
		if phase.stop_marker < last_stop:
			errors.append("moving_set_piece_definition %s schema_v2 phases must be ordered by stop_marker" % id)
			break
		last_stop = phase.stop_marker
		derived_markers.append(phase.stop_marker)
		if String(phase.encounter_id).is_empty():
			errors.append("moving_set_piece_definition %s phase %s has empty encounter_id" % [id, phase.phase_id])
		elif not derived_encounter_ids.has(phase.encounter_id):
			derived_encounter_ids.append(phase.encounter_id)
		if phase.required_module_id == &"":
			errors.append("moving_set_piece_definition %s phase %s has empty required_module_id" % [id, phase.phase_id])
		elif seen_module_ids.has(String(phase.required_module_id)):
			errors.append("moving_set_piece_definition %s has duplicate required_module_id: %s" % [id, phase.required_module_id])
		else:
			seen_module_ids[String(phase.required_module_id)] = true

	for wave_index in range(expected_wave_count):
		if not seen_waves.has(wave_index):
			errors.append("moving_set_piece_definition %s missing encounter_wave_index %d in schema_v2 phases" % [id, wave_index])
	if derived_encounter_ids.size() > 1:
		errors.append("moving_set_piece_definition %s must use exactly one encounter across schema_v2 phases" % id)
	if has_invalid_phase:
		return errors
	if derived_encounter_ids.size() == 1:
		var primary_encounter := String(derived_encounter_ids[0])
		if encounter_trigger_ids.size() > 0:
			if encounter_trigger_ids.size() != 1:
				errors.append("moving_set_piece_definition %s has unexpected encounter_trigger_ids for schema_v2" % id)
			elif String(encounter_trigger_ids[0]) != primary_encounter:
				errors.append("moving_set_piece_definition %s encounter_trigger_ids[0] must match schema_v2 phase encounter" % id)

	if _has_duplicate_stop_markers(derived_markers):
		errors.append("moving_set_piece_definition %s has duplicate phase stop markers" % id)

	if stop_markers.size() > 0 and stop_markers.size() != derived_markers.size():
		errors.append("moving_set_piece_definition %s stop_markers length does not match phase count" % id)
	if stop_markers.size() > 0:
		for index in range(min(stop_markers.size(), derived_markers.size())):
			if stop_markers[index] != derived_markers[index]:
				errors.append("moving_set_piece_definition %s stop_markers[%d] must match phase stop_marker" % [id, index])
	if destructible_module_ids.size() > 0 and destructible_module_ids.size() != seen_module_ids.size():
		errors.append("moving_set_piece_definition %s destructible_module_ids must list all phase modules" % id)
	return errors


func _has_duplicate_stop_markers(stop_markers: Array[float]) -> bool:
	var seen_markers: Dictionary = {}
	for marker in stop_markers:
		var key := "%0.6f" % marker
		if seen_markers.has(key):
			return true
		seen_markers[key] = true
	return false
