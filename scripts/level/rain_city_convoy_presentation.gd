class_name RainCityConvoyPresentation
extends Node

signal boss_state_changed(state: StringName, fraction: float)
signal boss_phase_caption(text: String, duration: float)
signal narrative_message(text: String, duration: float)

const PHASE_CAPTIONS: Array[String] = [
	"APPEAL FILED // DISABLE LEFT DRIVE",
	"APPEAL DENIED // DISABLE SIGNAL DISH",
	"FINAL NOTICE // DISABLE RIGHT DRIVE",
	"CASE CLOSED // CITATION CORE EXPOSED",
]

var active_convoy: CitationConvoyActor
var _runtime: MovingSetPieceRuntime
var _coordinator: MovingSetPieceEncounterCoordinator
var _mission_runtime: MissionRuntime
var _presentation: MissionPresentation
var _actor_generation := -1
var _last_announced_phase := -1


func configure(runtime: MovingSetPieceRuntime, coordinator: MovingSetPieceEncounterCoordinator, mission_runtime: MissionRuntime, presentation: MissionPresentation = null) -> void:
	_runtime = runtime
	_coordinator = coordinator
	_mission_runtime = mission_runtime
	_presentation = presentation
	_runtime.started.connect(_on_actor_started)
	_runtime.completed.connect(_on_completed)
	_runtime.phase_changed.connect(_on_phase_changed)
	_runtime.boss_health_changed.connect(_on_health_changed)


func set_presentation(presentation: MissionPresentation) -> void:
	_presentation = presentation


func _on_actor_started(actor: Node3D, generation: int) -> void:
	var convoy := actor as CitationConvoyActor
	if convoy == null:
		push_error("Citation convoy scene does not implement CitationConvoyActor")
		return
	active_convoy = convoy
	_actor_generation = generation
	_last_announced_phase = -1
	convoy.module_destroyed.connect(func(module_id: StringName) -> void:
		if _presentation != null:
			_presentation.play_spatial_cue(&"rain_city_module_break", convoy.global_position)
		if _coordinator != null:
			_coordinator.report_module_destroyed(module_id, generation)
	)
	convoy.module_health_changed.connect(func(module_id: StringName, current_health: float, maximum_health: float, _applied_amount: float) -> void:
		if _runtime != null:
			_runtime.update_module_health(module_id, current_health, maximum_health, generation)
	)
	var state := _runtime.current_state()
	_on_health_changed(float(state.get("current_boss_health", 1000.0)), float(state.get("max_boss_health", 1000.0)), generation)


func _on_phase_changed(phase_index: int, phase_id: StringName, generation: int) -> void:
	if _runtime == null or generation != _runtime.generation() or generation != _actor_generation:
		return
	if phase_index < 0 or phase_index >= PHASE_CAPTIONS.size() or phase_index == _last_announced_phase:
		return
	_last_announced_phase = phase_index
	boss_phase_caption.emit(PHASE_CAPTIONS[phase_index], 2.6)
	if _presentation != null and is_instance_valid(active_convoy):
		_presentation.play_spatial_cue(&"rain_city_convoy_move", active_convoy.global_position)
	var state := _runtime.current_state()
	var maximum := maxf(1.0, float(state.get("max_boss_health", 1000.0)))
	var current := clampf(float(state.get("current_boss_health", maximum)), 0.0, maximum)
	boss_state_changed.emit(phase_id, current / maximum)


func _on_health_changed(current_health: float, maximum_health: float, generation: int) -> void:
	if _runtime == null or generation != _runtime.generation():
		return
	var state := _runtime.current_state()
	if bool(state.get("completion_emitted", false)):
		boss_state_changed.emit(&"defeated", 0.0)
		return
	var phase_ids: Array = state.get("phase_ids", [])
	var phase_index := int(state.get("active_phase_index", 0))
	var phase_id := StringName(phase_ids[phase_index]) if phase_index >= 0 and phase_index < phase_ids.size() else &"appeal_filed"
	boss_state_changed.emit(phase_id, clampf(current_health / maxf(1.0, maximum_health), 0.0, 1.0))


func _on_completed(event_id: StringName, generation: int) -> void:
	if event_id != &"citation_convoy_stopped" or _runtime == null or generation != _runtime.generation():
		return
	boss_state_changed.emit(&"defeated", 0.0)
	boss_phase_caption.emit("CASE CLOSED // MUNICIPAL TOWMASTER DISABLED", 3.0)
	if is_instance_valid(active_convoy):
		active_convoy.play_defeat_sequence()
		if _presentation != null:
			_presentation.play_spatial_cue(&"rain_city_convoy_defeat", active_convoy.global_position)
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.DEFEAT, &"citation_convoy")
	_mission_runtime.activate_checkpoint(&"checkpoint_harbour_clear")
	narrative_message.emit("CITATION CONVOY DISABLED. MUNICIPAL JOY RESTORED.", 3.0)
