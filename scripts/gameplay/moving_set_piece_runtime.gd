class_name MovingSetPieceRuntime
extends Node3D

signal started(actor: Node3D, generation: int)
signal stop_reached(index: int, fraction: float)
signal encounter_requested(id: StringName, generation: int)
signal path_completed(generation: int)
signal completed(id: StringName, generation: int)
signal reset_completed(generation: int)
signal phase_changed(phase_index: int, phase_id: StringName, generation: int)
signal boss_health_changed(current_health: float, max_health: float, generation: int)

const ERROR_NONE := &""
const ERROR_MISSING_DEFINITION := &"missing_definition"
const ERROR_INVALID_DEFINITION := &"invalid_definition"
const ERROR_INVALID_ACTOR_PARENT := &"invalid_actor_parent"
const EPSILON := 0.0001

var _definition: Object = null
var _actor_parent: Node = null
var _actor_scene: PackedScene = null
var _actor: Node3D = null
var _generation := 0
var _running := false
var _moving := false
var _waiting_for_stop := false
var _path_completed := false
var _completion_emitted := false
var _completion_event_id: StringName = &""
var _schema_version := 1
var _phase_count := 0
var _path_points: Array[Vector3] = []
var _stop_fractions: Array[float] = []
var _stop_distances: Array[float] = []
var _segment_lengths: Array[float] = []
var _segment_directions: Array[Vector3] = []
var _total_path_length := 0.0
var _distance_along_path := 0.0
var _next_stop_index := 0
var _active_phase_index := 0
var _active_wave_index := -1
var _encounter_requirements: Array[StringName] = []
var _module_requirements: Array[StringName] = []
var _encounter_completed: Dictionary = {}
var _module_destroyed: Dictionary = {}
var _phase_encounter_requirements: Array[StringName] = []
var _phase_module_requirements: Array[StringName] = []
var _phase_ids: Array[StringName] = []
var _phase_health_max: Array[float] = []
var _phase_health_current: Array[float] = []
var _phase_encounter_completed: Array[bool] = []
var _phase_module_completed: Array[bool] = []
var _phase_completed_ids: Array[StringName] = []
var _wave_to_phase_index: Array[int] = []
var _max_boss_health := 0.0
var _current_boss_health := 0.0


func generation() -> int:
	return _generation


func current_state() -> Dictionary:
	return {
		"generation": _generation,
		"has_actor": is_instance_valid(_actor),
		"running": _running,
		"moving": _moving,
		"waiting_for_stop": _waiting_for_stop,
		"path_completed": _path_completed,
		"completion_emitted": _completion_emitted,
		"next_stop_index": _next_stop_index,
		"active_phase_index": _active_phase_index,
		"phase_index": _active_phase_index,
		"phase_ids": _phase_ids.duplicate(),
		"encounter_gates": _encounter_completed.duplicate(),
		"module_gates": _module_destroyed.duplicate(),
		"completed_phase_ids": _phase_completed_ids.duplicate(),
		"phase_health": _phase_health_current.duplicate(),
		"phase_health_max": _phase_health_max.duplicate(),
		"current_boss_health": _current_boss_health,
		"max_boss_health": _max_boss_health,
	}


func configure(definition: Object, actor_parent: Node = null) -> StringName:
	clear()

	if definition == null:
		return ERROR_MISSING_DEFINITION
	if not definition.has_method("validate"):
		return ERROR_INVALID_DEFINITION

	var errors: PackedStringArray = definition.validate()
	if not errors.is_empty():
		return ERROR_INVALID_DEFINITION

	var scene_path := definition.actor_scene_path as String
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return ERROR_INVALID_DEFINITION

	var probe: Object = scene.instantiate()
	if probe == null or not (probe is Node3D):
		if is_instance_valid(probe):
			(probe as Node).queue_free()
		return ERROR_INVALID_DEFINITION
	(probe as Node).queue_free()

	var parent: Node = actor_parent if actor_parent != null else self
	if parent == null:
		clear()
		return ERROR_INVALID_ACTOR_PARENT

	_definition = definition.duplicate(true)
	_schema_version = int(_definition.get("schema_version"))
	_actor_scene = scene
	_actor_parent = parent
	_path_points = _definition.path_points.duplicate()
	_completion_event_id = StringName(_definition.completion_event)

	if not _configure_definitions():
		clear()
		return ERROR_INVALID_DEFINITION

	_build_path_data()
	_reset_progress()
	_generation += 1
	return ERROR_NONE


func start() -> bool:
	if _definition == null:
		return false
	if _actor_parent == null:
		return false
	if is_instance_valid(_actor):
		return false
	_running = true
	_reset_progress()
	_clear_actor()
	return _spawn_actor(true)


func reset() -> bool:
	if _definition == null:
		return false

	_generation += 1
	_clear_actor()
	_running = true
	_completion_emitted = false
	_reset_progress()

	if _definition.reset_policy == 0:
		_running = false
		_waiting_for_stop = false
		_path_completed = false
		set_physics_process(false)
		reset_completed.emit(_generation)
		return true

	if _definition.reset_policy == 3:
		if not _spawn_actor(false):
			return false
		reset_completed.emit(_generation)
		return true

	if not _spawn_actor(_definition.reset_policy != 3):
		return false

	reset_completed.emit(_generation)
	return true


func resume_from_stop() -> bool:
	if not _running or not _waiting_for_stop or _moving:
		return false
	_waiting_for_stop = false
	_moving = true
	set_physics_process(true)
	return true


func mark_encounter_completed(id: StringName, observed_generation: int = -1) -> bool:
	if not _running or _definition == null:
		return false
	if observed_generation != -1 and observed_generation != _generation:
		return false
	if _schema_version == 1:
		var key := String(id).strip_edges().to_lower()
		if key.is_empty():
			return false
		if not _encounter_completed.has(key):
			return false
		if bool(_encounter_completed[key]):
			return false
		_encounter_completed[key] = true
		_evaluate_completion_gates()
		return true

	var phase_index := _active_phase_index
	var mapped_phase_index := _phase_index_for_wave(_active_wave_index)
	if mapped_phase_index != -1:
		phase_index = mapped_phase_index
	if phase_index < 0 or phase_index >= _phase_encounter_requirements.size():
		return false
	var expected := String(_phase_encounter_requirements[phase_index]).strip_edges().to_lower()
	var candidate := String(id).strip_edges().to_lower()
	if candidate.is_empty() or candidate != expected:
		return false
	if _phase_encounter_completed[phase_index]:
		return false
	_phase_encounter_completed[phase_index] = true
	_try_finalize_active_phase()
	_evaluate_completion_gates()
	return true


func mark_module_destroyed(id: StringName, observed_generation: int = -1) -> bool:
	if not _running or _definition == null:
		return false
	if observed_generation != -1 and observed_generation != _generation:
		return false
	if _schema_version == 1:
		var key := String(id).strip_edges().to_lower()
		if key.is_empty():
			return false
		if not _module_destroyed.has(key):
			return false
		if bool(_module_destroyed[key]):
			return false
		_module_destroyed[key] = true
		_evaluate_completion_gates()
		return true

	var phase_index := _active_phase_index
	if phase_index < 0 or phase_index >= _phase_module_requirements.size():
		return false
	var expected := String(_phase_module_requirements[phase_index]).strip_edges().to_lower()
	var candidate := String(id).strip_edges().to_lower()
	if candidate.is_empty() or candidate != expected:
		return false
	if _phase_module_completed[phase_index]:
		return false
	_phase_module_completed[phase_index] = true
	var previous := _phase_health_current[phase_index] if phase_index >= 0 and phase_index < _phase_health_current.size() else 0.0
	_phase_health_current[phase_index] = 0.0
	_current_boss_health = max(0.0, _current_boss_health - previous)
	boss_health_changed.emit(_current_boss_health, _max_boss_health, _generation)
	_try_finalize_active_phase()
	_evaluate_completion_gates()
	return true


func clear() -> void:
	_clear_actor()
	_definition = null
	_actor_parent = null
	_actor_scene = null
	_running = false
	_moving = false
	_waiting_for_stop = false
	_path_completed = false
	_completion_emitted = false
	_active_wave_index = -1
	_completion_event_id = &""
	_distance_along_path = 0.0
	_next_stop_index = 0
	_active_phase_index = 0
	_schema_version = 1
	_path_points.clear()
	_stop_fractions.clear()
	_stop_distances.clear()
	_segment_lengths.clear()
	_segment_directions.clear()
	_encounter_requirements.clear()
	_module_requirements.clear()
	_phase_encounter_requirements.clear()
	_phase_module_requirements.clear()
	_phase_ids.clear()
	_phase_health_max.clear()
	_phase_health_current.clear()
	_phase_encounter_completed.clear()
	_phase_module_completed.clear()
	_phase_completed_ids.clear()
	_wave_to_phase_index.clear()
	_encounter_completed.clear()
	_module_destroyed.clear()
	_max_boss_health = 0.0
	_current_boss_health = 0.0
	set_physics_process(false)


func _ready() -> void:
	set_physics_process(false)


func _exit_tree() -> void:
	clear()


func _physics_process(delta: float) -> void:
	if not _running or not _moving or _definition == null:
		return
	if _actor == null or not is_instance_valid(_actor):
		return
	if _path_points.size() < 2:
		return
	if not is_finite(delta) or delta <= 0.0:
		return

	var move_distance: float = float(_definition.speed) * delta
	if move_distance <= 0.0:
		return

	var previous_distance: float = _distance_along_path
	var target_distance: float = previous_distance + move_distance
	var stop_distance: float = _next_stop_distance()
	if stop_distance >= 0.0 and target_distance + EPSILON >= stop_distance and previous_distance < stop_distance - EPSILON:
		_distance_along_path = stop_distance
		_apply_position()
		_handle_stop_reached(_next_stop_index, _stop_fractions[_next_stop_index])
		return

	if target_distance >= _total_path_length - EPSILON:
		_distance_along_path = _total_path_length
		_apply_position()
		_handle_path_completed()
		return

	_distance_along_path = target_distance
	_apply_position()


func _handle_stop_reached(stop_index: int, fraction: float) -> void:
	if _schema_version == 2:
		_active_wave_index = stop_index
	_next_stop_index += 1
	_waiting_for_stop = true
	_moving = false
	set_physics_process(false)
	stop_reached.emit(stop_index, fraction)
	if _schema_version == 2 and stop_index < _phase_encounter_requirements.size():
		phase_changed.emit(_phase_index_for_wave(stop_index), _phase_id_for_wave(stop_index), _generation)
	var encounter_id := _encounter_id_for_index(stop_index)
	if encounter_id != &"":
		encounter_requested.emit(encounter_id, _generation)


func _handle_path_completed() -> void:
	if _path_completed:
		return
	_path_completed = true
	_moving = false
	_waiting_for_stop = false
	set_physics_process(false)
	path_completed.emit(_generation)
	_evaluate_completion_gates()


func _evaluate_completion_gates() -> void:
	if _definition == null or _completion_emitted:
		return
	if _schema_version == 2:
		if not _path_completed:
			return
		if _active_phase_index < _phase_count:
			return
	else:
		if not _path_completed:
			return
		if not _all_gates_complete():
			return
	_completion_emitted = true
	completed.emit(_completion_event_id, _generation)
	if _schema_version == 2:
		phase_changed.emit(_active_phase_index, _active_phase_id(), _generation)
		boss_health_changed.emit(_current_boss_health, _max_boss_health, _generation)
	if _definition.reset_policy == 2:
		_start_loop_cycle()


func _build_path_data() -> void:
	_segment_lengths.clear()
	_segment_directions.clear()
	_stop_distances.clear()
	_total_path_length = 0.0

	if _path_points.size() < 2:
		return

	for index in range(_path_points.size() - 1):
		var segment := _path_points[index + 1] - _path_points[index]
		var segment_length: float = segment.length()
		_segment_lengths.append(segment_length)
		if segment_length > EPSILON:
			_segment_directions.append(segment / segment_length)
		else:
			_segment_directions.append(Vector3.ZERO)
		_total_path_length += segment_length

	for marker in _stop_fractions:
		_stop_distances.append(marker * _total_path_length)

	_reset_requirements()


func _reset_requirements() -> void:
	_encounter_completed.clear()
	_module_destroyed.clear()
	if _schema_version == 1:
		for id in _encounter_requirements:
			var key := String(id).strip_edges().to_lower()
			if not key.is_empty():
				_encounter_completed[key] = false
		for id in _module_requirements:
			var key := String(id).strip_edges().to_lower()
			if not key.is_empty():
				_module_destroyed[key] = false
	else:
		_phase_encounter_completed = []
		_phase_module_completed = []
		_phase_completed_ids.clear()
		for index in range(_phase_count):
			_phase_encounter_completed.append(false)
			_phase_module_completed.append(false)
			_phase_health_current[index] = _phase_health_max[index]
		_max_boss_health = 0.0
		for value in _phase_health_max:
			if is_finite(value):
				_max_boss_health += value
		_current_boss_health = _max_boss_health


func _reset_progress() -> void:
	_completion_emitted = false
	_distance_along_path = 0.0
	_next_stop_index = 0
	_active_phase_index = 0
	_active_wave_index = -1
	_waiting_for_stop = false
	_moving = false
	_path_completed = false
	_reset_requirements()
	set_physics_process(false)
	_emit_phase_state()
	_emit_boss_health_state()


func _clear_actor() -> void:
	if is_instance_valid(_actor):
		_actor.queue_free()
	_actor = null


func _spawn_actor(moving: bool) -> bool:
	if _actor_scene == null:
		return false
	if _path_points.is_empty():
		return false
	if _actor_parent == null:
		return false
	var instance: Object = _actor_scene.instantiate()
	if instance == null or not (instance is Node3D):
		if instance != null:
			(instance as Node).queue_free()
		return false
	_actor = instance as Node3D
	_actor.position = _path_points[0]
	_actor_parent.add_child(_actor)
	_sync_actor_phase()
	_actor.reset_physics_interpolation()
	_running = true
	_moving = moving
	_waiting_for_stop = not moving
	set_physics_process(_moving)
	started.emit(_actor, _generation)
	_apply_position()
	_process_stops_at_distance()
	return true


func _process_stops_at_distance() -> void:
	var can_process := true
	while can_process and _next_stop_index < _stop_distances.size():
		var stop_distance: float = _stop_distances[_next_stop_index]
		if _distance_along_path + EPSILON >= stop_distance:
			var stop_fraction: float = _stop_fractions[_next_stop_index]
			_handle_stop_reached(_next_stop_index, stop_fraction)
			can_process = _moving
		else:
			can_process = false


func _apply_position() -> void:
	if _actor == null or not is_instance_valid(_actor):
		return
	_actor.position = _position_at_distance(_distance_along_path)


func _position_at_distance(distance: float) -> Vector3:
	if _path_points.is_empty():
		return Vector3.ZERO
	if _path_points.size() == 1:
		return _path_points[0]
	if _total_path_length <= EPSILON:
		return _path_points[-1]

	var remaining := clampf(distance, 0.0, _total_path_length)
	for index in range(_segment_lengths.size()):
		var segment_length: float = _segment_lengths[index]
		if segment_length <= EPSILON:
			continue
		if remaining <= segment_length:
			return _path_points[index] + _segment_directions[index] * remaining
		remaining -= segment_length
	return _path_points[_path_points.size() - 1]


func _next_stop_distance() -> float:
	if _next_stop_index < 0 or _next_stop_index >= _stop_distances.size():
		return -1.0
	return _stop_distances[_next_stop_index]


func _encounter_id_for_index(stop_index: int) -> StringName:
	if stop_index < 0 or stop_index >= _encounter_requirements.size():
		return &""
	return _encounter_requirements[stop_index]


func _all_gates_complete() -> bool:
	if _schema_version == 1:
		for key in _encounter_completed.keys():
			if bool(_encounter_completed[key]) == false:
				return false
		for key in _module_destroyed.keys():
			if bool(_module_destroyed[key]) == false:
				return false
		return true
	for phase_index in range(_phase_count):
		if not _is_phase_complete(phase_index):
			return false
	return true


func _is_phase_complete(phase_index: int) -> bool:
	if phase_index < 0 or phase_index >= _phase_count:
		return false
	return bool(_phase_encounter_completed[phase_index]) and bool(_phase_module_completed[phase_index])


func _try_finalize_active_phase() -> void:
	var changed := false
	while _active_phase_index < _phase_count and _is_phase_complete(_active_phase_index):
		var phase_id := _phase_ids[_active_phase_index]
		if phase_id != &"" and not _phase_completed_ids.has(phase_id):
			_phase_completed_ids.append(phase_id)
		_active_phase_index += 1
		changed = true
	if changed:
		_sync_actor_phase()
		phase_changed.emit(_active_phase_index, _active_phase_id(), _generation)


func _active_phase_id() -> StringName:
	if _active_phase_index < 0 or _active_phase_index >= _phase_ids.size():
		return &""
	return _phase_ids[_active_phase_index]


func _emit_phase_state() -> void:
	if _schema_version != 2:
		return
	phase_changed.emit(_active_phase_index, _active_phase_id(), _generation)


func _emit_boss_health_state() -> void:
	if _schema_version != 2:
		return
	boss_health_changed.emit(_current_boss_health, _max_boss_health, _generation)


func _sync_actor_phase() -> void:
	if is_instance_valid(_actor) and _actor.has_method("set_active_phase"):
		_actor.call("set_active_phase", _active_phase_index)


func _start_loop_cycle() -> void:
	if _definition == null:
		return
	_generation += 1
	_reset_progress()
	if not _spawn_actor(true):
		_running = false
		set_physics_process(false)


func _configure_definitions() -> bool:
	_encounter_requirements = []
	_module_requirements = []
	_phase_encounter_requirements = []
	_phase_module_requirements = []
	_phase_ids = []
	_phase_health_max = []
	_phase_health_current = []
	_wave_to_phase_index = []
	_phase_encounter_completed = []
	_phase_module_completed = []
	_phase_count = 0
	_active_phase_index = 0
	_stop_fractions = []
	_encounter_completed.clear()
	_module_destroyed.clear()

	if _schema_version == 1:
		_stop_fractions = _definition.stop_markers.duplicate()
		_encounter_requirements = _definition.encounter_trigger_ids.duplicate()
		_module_requirements = _definition.destructible_module_ids.duplicate()
		if _encounter_requirements.size() > _stop_fractions.size():
			return false
		return true

	if not (_definition.phases is Array) or _definition.phases.is_empty():
		return false

	_phase_count = _definition.phases.size()
	_stop_fractions = []
	_phase_health_max.resize(_phase_count)
	_phase_health_current.resize(_phase_count)
	_phase_encounter_requirements.resize(_phase_count)
	_phase_module_requirements.resize(_phase_count)
	_phase_ids.resize(_phase_count)
	_wave_to_phase_index.resize(_phase_count)
	for index in range(_phase_count):
		_wave_to_phase_index[index] = -1

	for index in range(_phase_count):
		var phase := _definition.phases[index] as MovingSetPiecePhaseDefinition
		if phase == null:
			return false
		_stop_fractions.append(phase.stop_marker)
		_phase_ids[index] = phase.phase_id
		_phase_encounter_requirements[index] = phase.encounter_id
		_phase_module_requirements[index] = phase.required_module_id
		_phase_health_max[index] = phase.health_allocation if is_finite(phase.health_allocation) else 0.0
		_phase_health_current[index] = 0.0
		_phase_encounter_completed.append(false)
		_phase_module_completed.append(false)
		_wave_to_phase_index[phase.encounter_wave_index] = index
		_encounter_requirements.append(phase.encounter_id)
		_module_requirements.append(phase.required_module_id)

	_phase_health_current = _phase_health_max.duplicate()
	_max_boss_health = 0.0
	for health in _phase_health_max:
		_max_boss_health += health if is_finite(health) else 0.0
	_current_boss_health = _max_boss_health
	return true


func _phase_index_for_wave(wave_index: int) -> int:
	if wave_index < 0 or wave_index >= _wave_to_phase_index.size():
		return -1
	return _wave_to_phase_index[wave_index]


func _phase_id_for_wave(wave_index: int) -> StringName:
	var phase_index := _phase_index_for_wave(wave_index)
	if phase_index < 0 or phase_index >= _phase_ids.size():
		return &""
	return _phase_ids[phase_index]
