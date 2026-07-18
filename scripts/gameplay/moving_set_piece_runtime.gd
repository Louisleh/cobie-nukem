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
var _motion_mode := MovingSetPieceDefinition.MotionMode.PATH
var _path_points: Array[Vector3] = []
var _stop_fractions: Array[float] = []
var _path := MovingSetPiecePath.new()
var _distance_along_path := 0.0
var _next_stop_index := 0
var _active_wave_index := -1
var _encounter_requirements: Array[StringName] = []
var _module_requirements: Array[StringName] = []
var _encounter_completed: Dictionary = {}
var _module_destroyed: Dictionary = {}
var _phase_state := MovingSetPiecePhaseState.new()
func generation() -> int:
	return _generation
func current_state() -> Dictionary:
	var state := {
		"generation": _generation,
		"has_actor": is_instance_valid(_actor),
		"running": _running,
		"moving": _moving,
		"waiting_for_stop": _waiting_for_stop,
		"path_completed": _path_completed,
		"completion_emitted": _completion_emitted,
		"motion_mode": _motion_mode,
		"next_stop_index": _next_stop_index,
		"encounter_gates": _encounter_completed.duplicate(),
		"module_gates": _module_destroyed.duplicate(),
	}
	state.merge(_phase_state.snapshot(), true)
	return state
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
	_motion_mode = int(_definition.get("motion_mode"))
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
	return _spawn_actor(_uses_path_motion())
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
	if not _spawn_actor(_uses_path_motion() and _definition.reset_policy != 3):
		return false
	reset_completed.emit(_generation)
	return true
func resume_from_stop() -> bool:
	if not _uses_path_motion():
		return false
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
	if not _phase_state.mark_encounter(id, _active_wave_index):
		return false
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
	if not _phase_state.mark_module(id):
		return false
	boss_health_changed.emit(_phase_state.current_health, _phase_state.max_health, _generation)
	_try_finalize_active_phase()
	_evaluate_completion_gates()
	return true
func update_module_health(id: StringName, current_health: float, maximum_health: float, observed_generation: int = -1) -> bool:
	if not _running or _schema_version != 2:
		return false
	if observed_generation != -1 and observed_generation != _generation:
		return false
	if not _phase_state.update_module_health(id, current_health, maximum_health):
		return false
	boss_health_changed.emit(_phase_state.current_health, _phase_state.max_health, _generation)
	return true
func restore_completed_state() -> bool:
	if _definition == null or _schema_version != 2 or _actor_scene == null or _actor_parent == null:
		return false
	_generation += 1
	_clear_actor()
	_distance_along_path = _path.total_length if _uses_path_motion() else 0.0
	_next_stop_index = _stop_fractions.size()
	_active_wave_index = _stop_fractions.size() - 1
	_running = false
	_moving = false
	_waiting_for_stop = false
	_path_completed = true
	_completion_emitted = true
	_phase_state.restore_completed()
	set_physics_process(false)
	var instance := _actor_scene.instantiate() as Node3D
	if instance == null:
		return false
	_actor = instance
	_actor.position = _completed_actor_position()
	_configure_actor_modules()
	_actor_parent.add_child(_actor)
	_sync_actor_phase()
	_actor.reset_physics_interpolation()
	started.emit(_actor, _generation)
	if _actor.has_method("play_defeat_sequence"):
		_actor.call("play_defeat_sequence")
	_emit_boss_health_state()
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
	_schema_version = 1
	_motion_mode = MovingSetPieceDefinition.MotionMode.PATH
	_path_points.clear()
	_stop_fractions.clear()
	_path.clear()
	_encounter_requirements.clear()
	_module_requirements.clear()
	_phase_state.clear()
	_encounter_completed.clear()
	_module_destroyed.clear()
	set_physics_process(false)
func _ready() -> void:
	set_physics_process(false)
func _exit_tree() -> void:
	clear()
func _physics_process(delta: float) -> void:
	if not _running or not _moving or _definition == null:
		return
	if not _uses_path_motion():
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
	var stop_distance: float = _path.next_stop(_next_stop_index)
	if stop_distance >= 0.0 and target_distance + EPSILON >= stop_distance and previous_distance < stop_distance - EPSILON:
		_distance_along_path = stop_distance
		_apply_position()
		_handle_stop_reached(_next_stop_index, _stop_fractions[_next_stop_index])
		return
	if target_distance >= _path.total_length - EPSILON:
		_distance_along_path = _path.total_length
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
	if _schema_version == 2 and stop_index < _phase_state.encounter_requirements.size():
		phase_changed.emit(_phase_state.phase_index_for_wave(stop_index), _phase_state.phase_id_for_wave(stop_index), _generation)
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
		if _phase_state.active_index < _phase_state.ids.size():
			return
	else:
		if not _path_completed:
			return
		if not _all_gates_complete():
			return
	_completion_emitted = true
	completed.emit(_completion_event_id, _generation)
	if _schema_version == 2:
		phase_changed.emit(_phase_state.active_index, _phase_state.active_id(), _generation)
		boss_health_changed.emit(_phase_state.current_health, _phase_state.max_health, _generation)
	if _definition.reset_policy == 2:
		_start_loop_cycle()
func _build_path_data() -> void:
	_path.configure(_path_points, _stop_fractions)
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
		_phase_state.reset()
func _reset_progress() -> void:
	_completion_emitted = false
	_distance_along_path = 0.0
	_next_stop_index = 0
	_phase_state.active_index = 0
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
	if _uses_path_motion() and _path_points.is_empty():
		return false
	if _actor_parent == null:
		return false
	var instance: Object = _actor_scene.instantiate()
	if instance == null or not (instance is Node3D):
		if instance != null:
			(instance as Node).queue_free()
		return false
	_actor = instance as Node3D
	_actor.position = _spawn_position()
	_configure_actor_modules()
	_actor_parent.add_child(_actor)
	_sync_actor_phase()
	_actor.reset_physics_interpolation()
	_running = true
	_moving = moving and _uses_path_motion()
	_waiting_for_stop = not _moving and _uses_path_motion()
	set_physics_process(_moving)
	started.emit(_actor, _generation)
	if _uses_path_motion():
		_apply_position()
		_process_stops_at_distance()
	else:
		_advance_stationary_phase()
	return true
func _process_stops_at_distance() -> void:
	var can_process := true
	while can_process and _next_stop_index < _path.stop_distances.size():
		var stop_distance: float = _path.stop_distances[_next_stop_index]
		if _distance_along_path + EPSILON >= stop_distance:
			var stop_fraction: float = _stop_fractions[_next_stop_index]
			_handle_stop_reached(_next_stop_index, stop_fraction)
			can_process = _moving
		else:
			can_process = false
func _apply_position() -> void:
	if _actor == null or not is_instance_valid(_actor):
		return
	_actor.position = _path.position_at(_distance_along_path)
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
	return _phase_state.all_complete()
func _try_finalize_active_phase() -> void:
	if _phase_state.finalize_completed():
		_sync_actor_phase()
		phase_changed.emit(_phase_state.active_index, _phase_state.active_id(), _generation)
		if _waiting_for_stop:
			if _uses_path_motion():
				resume_from_stop()
			else:
				_waiting_for_stop = false
				_advance_stationary_phase()
func _emit_phase_state() -> void:
	if _schema_version != 2:
		return
	phase_changed.emit(_phase_state.active_index, _phase_state.active_id(), _generation)
func _emit_boss_health_state() -> void:
	if _schema_version != 2:
		return
	boss_health_changed.emit(_phase_state.current_health, _phase_state.max_health, _generation)
func _sync_actor_phase() -> void:
	if is_instance_valid(_actor) and _actor.has_method("set_active_phase"):
		_actor.call("set_active_phase", _phase_state.active_index)
func _start_loop_cycle() -> void:
	if _definition == null:
		return
	_generation += 1
	_reset_progress()
	if not _spawn_actor(_uses_path_motion()):
		_running = false
		set_physics_process(false)
func _configure_definitions() -> bool:
	_encounter_requirements = []
	_module_requirements = []
	_phase_state.clear()
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
	if not (_definition.phases is Array) or not _phase_state.configure(_definition.phases):
		return false
	_stop_fractions = _phase_state.stop_markers.duplicate()
	_encounter_requirements = _phase_state.encounter_requirements.duplicate()
	_module_requirements = _phase_state.module_requirements.duplicate()
	return true
func _uses_path_motion() -> bool:
	return _motion_mode == MovingSetPieceDefinition.MotionMode.PATH
func _spawn_position() -> Vector3:
	return _path_points[0] if not _path_points.is_empty() else Vector3.ZERO
func _completed_actor_position() -> Vector3:
	return _path.position_at(_distance_along_path) if _uses_path_motion() else _spawn_position()
func _configure_actor_modules() -> void:
	if not is_instance_valid(_actor) or not _actor.has_method("configure_phase_modules"):
		return
	_actor.call("configure_phase_modules", _module_requirements)
func _advance_stationary_phase() -> void:
	if _uses_path_motion() or not _running or _definition == null:
		return
	if _next_stop_index >= _stop_fractions.size():
		_handle_path_completed()
		return
	_handle_stop_reached(_next_stop_index, _stop_fractions[_next_stop_index])
