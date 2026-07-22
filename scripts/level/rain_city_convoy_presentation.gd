class_name RainCityConvoyPresentation
extends Node

signal boss_state_changed(state: StringName, fraction: float)
signal boss_phase_caption(text: String, duration: float)
signal narrative_message(text: String, duration: float)

const ATTACK_CAPTIONS: Dictionary = {
	&"citation_barrage": "CITATION BARRAGE // LEAVE THE MARK",
	&"tow_sweep": "TOW SWEEP // CLEAR THE LANE",
	&"impound_pulse": "IMPOUND PULSE // CREATE DISTANCE",
}

const ATTACK_CUES: Dictionary = {
	&"citation_barrage": &"rain_city_convoy_move",
	&"tow_sweep": &"rain_city_module_break",
	&"impound_pulse": &"rain_city_convoy_move",
}

const ARENA_CAPTIONS: Dictionary = {
	&"citation_lanes": "CITATION LANES ACTIVE",
	&"impound_field": "IMPOUND FIELD ACTIVE",
}

const DEFEAT_MILESTONE_CAPTIONS: Dictionary = {
	&"tickets": "CITATION TICKETS // DEPLETED",
	&"tow_arm": "TOW ARM // DEACTIVATED",
	&"core_discharge": "CORE DISCHARGE // REDUCED",
}
const DEFEAT_MILESTONE_CUE := &"rain_city_module_break"

var _runtime: MovingSetPieceRuntime
var _coordinator: MovingSetPieceEncounterCoordinator
var _mission_runtime: MissionRuntime
var _presentation: MissionPresentation
var _active_actor: CitationConvoyActor
var _target: Node3D
var _actor_generation := -1
var _last_announced_phase := -1
var _last_arena_state: StringName = &""
var _runtime_was_moving := false


func configure(runtime: MovingSetPieceRuntime, coordinator: MovingSetPieceEncounterCoordinator, mission_runtime: MissionRuntime, presentation: MissionPresentation = null) -> void:
	_runtime = runtime
	_coordinator = coordinator
	_mission_runtime = mission_runtime
	_presentation = presentation
	_runtime.started.connect(_on_actor_started)
	_runtime.stop_reached.connect(_on_actor_arrived_at_stop)
	_runtime.completed.connect(_on_completed)
	_runtime.phase_changed.connect(_on_phase_changed)
	_runtime.reset_completed.connect(func(_generation: int) -> void: _set_active_actor(null))
	_runtime.boss_health_changed.connect(_on_health_changed)


func set_presentation(presentation: MissionPresentation) -> void:
	_presentation = presentation


func set_target(value: Node3D) -> void:
	_target = value
	if is_instance_valid(_active_actor):
		_active_actor.set_target(_target)


func _physics_process(_delta: float) -> void:
	if _runtime == null:
		_runtime_was_moving = false
		return
	var state: Dictionary = _runtime.current_state()
	var moving: bool = bool(state.get("moving", false))
	if moving and not _runtime_was_moving:
		_on_convoy_moving()
	elif not moving and _runtime_was_moving and bool(state.get("waiting_for_stop", false)):
		_on_actor_arrived_at_stop()
	_runtime_was_moving = moving


func _on_actor_started(actor: Node3D, generation: int) -> void:
	var convoy := actor as CitationConvoyActor
	if convoy == null:
		push_error("Citation convoy scene does not implement CitationConvoyActor")
		return
	_set_active_actor(convoy)
	_actor_generation = generation
	_last_announced_phase = -1
	convoy.set_target(_target)
	convoy.set_combat_enabled(false)
	if not convoy.attack_telegraphed.is_connected(_on_actor_attack_telegraphed):
		convoy.attack_telegraphed.connect(_on_actor_attack_telegraphed)
	if not convoy.arena_state_changed.is_connected(_on_actor_arena_state_changed):
		convoy.arena_state_changed.connect(_on_actor_arena_state_changed)
	if not convoy.defeat_milestone_reached.is_connected(_on_actor_defeat_milestone_reached):
		convoy.defeat_milestone_reached.connect(_on_actor_defeat_milestone_reached)
	if not convoy.module_destroyed.is_connected(_on_actor_module_destroyed):
		convoy.module_destroyed.connect(_on_actor_module_destroyed)
	if not convoy.module_health_changed.is_connected(_on_actor_module_health_changed):
		convoy.module_health_changed.connect(_on_actor_module_health_changed)
	if not convoy.tree_exited.is_connected(_on_active_actor_tree_exited):
		convoy.tree_exited.connect(_on_active_actor_tree_exited.bind(convoy))
	var state: Dictionary = _runtime.current_state()
	_on_health_changed(float(state.get("current_boss_health", 1000.0)), float(state.get("max_boss_health", 1000.0)), generation)


func _on_phase_changed(phase_index: int, phase_id: StringName, generation: int) -> void:
	if _runtime == null or generation != _runtime.generation() or generation != _actor_generation:
		return
	if phase_index < 0 or phase_index == _last_announced_phase:
		return
	_last_announced_phase = phase_index
	_on_phase_completed()
	var state: Dictionary = _runtime.current_state()
	var maximum: float = maxf(1.0, float(state.get("max_boss_health", 1000.0)))
	var current: float = clampf(float(state.get("current_boss_health", maximum)), 0.0, maximum)
	boss_state_changed.emit(phase_id, current / maximum)


func _on_health_changed(current_health: float, maximum_health: float, generation: int) -> void:
	if _runtime == null or generation != _runtime.generation():
		return
	var state: Dictionary = _runtime.current_state()
	if bool(state.get("completion_emitted", false)):
		boss_state_changed.emit(&"defeated", 0.0)
		return
	var phase_ids: Array[Variant] = state.get("phase_ids", [])
	var phase_index: int = int(state.get("active_phase_index", 0))
	var phase_id: StringName = StringName(phase_ids[phase_index]) if phase_index >= 0 and phase_index < phase_ids.size() else &"appeal_filed"
	boss_state_changed.emit(phase_id, clampf(current_health / maxf(1.0, maximum_health), 0.0, 1.0))


func _on_actor_module_destroyed(module_id: StringName) -> void:
	if _presentation != null:
		_presentation.play_spatial_cue(&"rain_city_module_break", _active_actor.global_position if is_instance_valid(_active_actor) else Vector3.ZERO)
	if _coordinator != null:
		_coordinator.report_module_destroyed(module_id, _actor_generation)


func _on_actor_module_health_changed(module_id: StringName, current_health: float, maximum_health: float, _applied_amount: float) -> void:
	if _runtime != null:
		_runtime.update_module_health(module_id, current_health, maximum_health, _actor_generation)


func _on_actor_attack_telegraphed(attack_id: StringName, _phase_index: int, _locked_position: Vector3, seconds: float) -> void:
	var caption: String = ATTACK_CAPTIONS.get(attack_id, &"")
	if caption == "":
		return
	var duration: float = maxf(0.65, seconds)
	var cue_id: StringName = ATTACK_CUES.get(attack_id, &"")
	if _presentation == null or not is_instance_valid(_active_actor):
		return
	_presentation.on_boss_phase_caption(caption, duration)
	if cue_id != &"":
		_presentation.play_spatial_cue(cue_id, _active_actor.global_position)


func _on_actor_arena_state_changed(arena_state_id: StringName, _phase_index: int) -> void:
	if is_instance_valid(_active_actor) == false:
		_last_arena_state = StringName()
		return
	if arena_state_id == _last_arena_state:
		return
	_last_arena_state = arena_state_id
	var text: String = ARENA_CAPTIONS.get(arena_state_id, &"")
	if text == &"" or _presentation == null:
		return
	_presentation.on_boss_phase_caption(text, 2.2)


func _on_actor_defeat_milestone_reached(milestone_id: StringName, _elapsed: float) -> void:
	if is_instance_valid(_active_actor) == false:
		return
	if milestone_id == &"final_settle":
		if _presentation != null:
			_presentation.on_boss_phase_caption("TOWMASTER IMPOUNDED", 2.4)
		return
	var caption: String = DEFEAT_MILESTONE_CAPTIONS.get(milestone_id, &"")
	if caption == &"" or _presentation == null:
		return
	_presentation.on_boss_phase_caption(caption, 1.6)
	_presentation.play_spatial_cue(DEFEAT_MILESTONE_CUE, _active_actor.global_position)


func _on_actor_arrived_at_stop(_index: int = -1, _fraction: float = 0.0) -> void:
	if not is_instance_valid(_active_actor) or _active_actor.defeat_started():
		return
	_active_actor.set_combat_enabled(true)


func _on_phase_completed() -> void:
	if is_instance_valid(_active_actor):
		_active_actor.set_combat_enabled(false)


func _on_convoy_moving() -> void:
	_on_phase_completed()


func _on_active_actor_tree_exited(actor: Node) -> void:
	if actor != _active_actor:
		return
	_active_actor = null
	_last_announced_phase = -1
	_last_arena_state = &""
	_runtime_was_moving = false


func _set_active_actor(actor: CitationConvoyActor) -> void:
	_active_actor = actor
	_last_arena_state = &""
	_runtime_was_moving = false


func _on_completed(event_id: StringName, generation: int) -> void:
	if event_id != &"citation_convoy_stopped" or _runtime == null or generation != _runtime.generation():
		return
	boss_state_changed.emit(&"defeated", 0.0)
	boss_phase_caption.emit("CASE CLOSED // MUNICIPAL TOWMASTER DISABLED", 3.0)
	if is_instance_valid(_active_actor):
		_active_actor.set_combat_enabled(false)
		_active_actor.play_defeat_sequence()
		if _presentation != null:
			_presentation.play_spatial_cue(&"rain_city_convoy_defeat", _active_actor.global_position)
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.DEFEAT, &"citation_convoy")
	_mission_runtime.activate_checkpoint(&"checkpoint_harbour_clear")
	narrative_message.emit("CITATION CONVOY DISABLED. MUNICIPAL JOY RESTORED.", 3.0)
