extends SceneTree

const MovingSetPieceDefinitionClass = preload("res://scripts/gameplay/moving_set_piece_definition.gd")
const MovingSetPiecePhaseDefinitionClass = preload("res://scripts/gameplay/moving_set_piece_phase_definition.gd")
const MovingSetPieceRuntimeClass = preload("res://scripts/gameplay/moving_set_piece_runtime.gd")
const CitationConvoyScene = preload("res://scenes/set_pieces/citation_convoy.tscn")

const PHASE_IDS: Array[StringName] = [&"one", &"two", &"three", &"four"]
const MODULE_IDS: Array[StringName] = [&"module_one", &"module_two", &"module_three", &"module_four"]
const ENCOUNTER_ID := &"stationary_showdown"
const SPAWN_POINT := Vector3(7.0, 2.0, -11.0)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_definition_contract()
	await _test_stationary_phase_progression_and_reset()
	await _test_runtime_configures_actor_module_order()
	if failures.is_empty():
		print("MOVING SET PIECE STATIONARY TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_definition_contract() -> void:
	var stationary := _make_stationary_definition([])
	_expect(stationary.validate().is_empty(), "schema v2 stationary definition accepts no fake path")

	stationary.path_points = [SPAWN_POINT]
	_expect(stationary.validate().is_empty(), "schema v2 stationary definition accepts one authored spawn point")

	stationary.path_points = [SPAWN_POINT, SPAWN_POINT + Vector3.RIGHT]
	_expect(not stationary.validate().is_empty(), "stationary definition rejects a disguised movement path")

	var path_definition := _make_stationary_definition([])
	path_definition.motion_mode = MovingSetPieceDefinitionClass.MotionMode.PATH
	_expect(not path_definition.validate().is_empty(), "path mode still requires at least two path points")

	var legacy := MovingSetPieceDefinitionClass.new()
	legacy.id = &"legacy_stationary_rejected"
	legacy.motion_mode = MovingSetPieceDefinitionClass.MotionMode.STATIONARY
	legacy.actor_scene_path = "res://tests/fixtures/moving_set_piece_probe.tscn"
	legacy.path_points = [Vector3.ZERO, Vector3.RIGHT]
	legacy.completion_event = &"legacy_complete"
	_expect(not legacy.validate().is_empty(), "schema v1 explicitly rejects stationary mode")


func _test_stationary_phase_progression_and_reset() -> void:
	var definition := _make_stationary_definition([SPAWN_POINT])
	var runtime := MovingSetPieceRuntimeClass.new() as MovingSetPieceRuntime
	var configured := runtime.configure(definition, runtime)
	_expect(configured == MovingSetPieceRuntimeClass.ERROR_NONE, "stationary runtime configures")
	if configured != MovingSetPieceRuntimeClass.ERROR_NONE:
		runtime.queue_free()
		return
	root.add_child(runtime)

	var observed_stops: Array[int] = []
	var observed_encounters: Array[StringName] = []
	var completion_state := {"count": 0}
	runtime.stop_reached.connect(func(index: int, _fraction: float) -> void: observed_stops.append(index))
	runtime.encounter_requested.connect(func(id: StringName, _generation: int) -> void: observed_encounters.append(id))
	runtime.completed.connect(func(_id: StringName, _generation: int) -> void: completion_state["count"] += 1)

	_expect(runtime.start(), "stationary runtime starts")
	_expect(runtime.get_child_count() == 1, "stationary runtime owns one actor")
	var actor := runtime.get_child(0) as Node3D
	_expect(actor != null and actor.position.is_equal_approx(SPAWN_POINT), "stationary actor spawns at its single authored point")
	var first_state := runtime.current_state()
	_expect(int(first_state.get("motion_mode", -1)) == MovingSetPieceDefinitionClass.MotionMode.STATIONARY, "runtime exposes stationary motion mode")
	_expect(bool(first_state.get("moving", true)) == false, "stationary actor never enters moving state")
	_expect(bool(first_state.get("waiting_for_stop", false)), "stationary actor begins at its first phase gate")
	_expect(observed_stops == [0], "first stationary phase starts exactly once")
	_expect(observed_encounters == [ENCOUNTER_ID], "first stationary encounter requests exactly once")
	_expect(not runtime.resume_from_stop(), "external resume cannot bypass stationary phase gates")

	var generation := runtime.generation()
	for phase_index in range(4):
		var module_first := phase_index % 2 == 0
		if module_first:
			_expect(runtime.mark_module_destroyed(MODULE_IDS[phase_index], generation), "phase %d accepts module gate" % phase_index)
			_expect(runtime.mark_encounter_completed(ENCOUNTER_ID, generation), "phase %d accepts encounter gate" % phase_index)
		else:
			_expect(runtime.mark_encounter_completed(ENCOUNTER_ID, generation), "phase %d accepts encounter-first gate" % phase_index)
			_expect(runtime.mark_module_destroyed(MODULE_IDS[phase_index], generation), "phase %d accepts module-after-encounter gate" % phase_index)
		_expect(not runtime.mark_module_destroyed(MODULE_IDS[phase_index], generation), "phase %d rejects duplicate module gate" % phase_index)
		var state := runtime.current_state()
		_expect(bool(state.get("moving", true)) == false, "phase %d remains stationary" % phase_index)
		if phase_index < 3:
			_expect(observed_stops == range(phase_index + 2), "phase %d advances immediately to the next stationary gate" % phase_index)
			_expect(int(state.get("active_phase_index", -1)) == phase_index + 1, "phase %d advances active phase" % phase_index)

	var final_state := runtime.current_state()
	_expect(bool(final_state.get("path_completed", false)), "stationary set piece reaches its terminal lifecycle state")
	_expect(bool(final_state.get("completion_emitted", false)), "stationary set piece emits completion after all four gates")
	_expect(is_zero_approx(float(final_state.get("current_boss_health", -1.0))), "stationary four-phase health reaches zero")
	_expect(int(completion_state["count"]) == 1, "stationary completion emits exactly once")
	_expect(observed_stops == [0, 1, 2, 3], "stationary phases each emit one ordered stop gate")
	_expect(observed_encounters.size() == 4, "stationary phases each request one encounter wave")

	var stale_generation := generation
	_expect(runtime.reset(), "stationary runtime resets")
	await process_frame
	_expect(runtime.generation() == stale_generation + 1, "stationary reset increments generation")
	_expect(runtime.get_child_count() == 1, "stationary reset replaces rather than duplicates its actor")
	_expect(not runtime.mark_module_destroyed(MODULE_IDS[0], stale_generation), "stationary reset rejects stale module callbacks")
	var reset_state := runtime.current_state()
	_expect(int(reset_state.get("active_phase_index", -1)) == 0, "stationary reset restores phase zero")
	_expect(int(reset_state.get("next_stop_index", -1)) == 1, "stationary reset immediately reopens the first gate")
	_expect(not bool(reset_state.get("path_completed", true)), "stationary reset clears terminal state")
	_expect(is_equal_approx(float(reset_state.get("current_boss_health", 0.0)), 1000.0), "stationary reset restores the full health budget")
	runtime.queue_free()
	await process_frame


func _test_runtime_configures_actor_module_order() -> void:
	var actor := CitationConvoyScene.instantiate() as CitationConvoyActor
	_expect(actor != null, "phased production actor instantiates")
	if actor == null:
		return
	var reversed_ids: Array[StringName] = [
		&"citation_core",
		&"citation_drive_right",
		&"citation_signal_dish",
		&"citation_drive_left",
	]
	_expect(actor.configure_phase_modules(reversed_ids), "base phased actor accepts a resource-owned module order")
	root.add_child(actor)
	await process_frame
	_expect(actor.phase_module_ids == reversed_ids, "phased actor retains configured ordering without a subclass constant")
	actor.set_active_phase(0)
	var core := _find_module(actor, &"citation_core")
	var left := _find_module(actor, &"citation_drive_left")
	_expect(core != null and core.visible and core.collision_layer != 0, "configured first module is active")
	_expect(left != null and not left.visible and left.collision_layer == 0, "non-active module is inert")
	actor.queue_free()
	await process_frame


func _make_stationary_definition(spawn_points: Array[Vector3]) -> MovingSetPieceDefinition:
	var definition := MovingSetPieceDefinitionClass.new() as MovingSetPieceDefinition
	definition.id = &"stationary_test"
	definition.schema_version = 2
	definition.motion_mode = MovingSetPieceDefinitionClass.MotionMode.STATIONARY
	definition.actor_scene_path = "res://tests/fixtures/moving_set_piece_probe.tscn"
	definition.path_points = spawn_points
	definition.completion_event = &"stationary_complete"
	definition.reset_policy = MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	definition.encounter_trigger_ids = [ENCOUNTER_ID]
	definition.destructible_module_ids = MODULE_IDS.duplicate()
	definition.stop_markers = [0.1, 0.35, 0.65, 0.9]
	for index in range(4):
		var phase := MovingSetPiecePhaseDefinitionClass.new() as MovingSetPiecePhaseDefinition
		phase.phase_id = PHASE_IDS[index]
		phase.stop_marker = definition.stop_markers[index]
		phase.encounter_wave_index = index
		phase.encounter_id = ENCOUNTER_ID
		phase.required_module_id = MODULE_IDS[index]
		phase.display_caption = "STATIONARY PHASE %d" % (index + 1)
		phase.health_allocation = 250.0
		definition.phases.append(phase)
	return definition


func _find_module(actor: CitationConvoyActor, module_id: StringName) -> WorldInteraction:
	for child in actor.get_children():
		var interaction := child as WorldInteraction
		if interaction != null and interaction.definition != null and interaction.definition.id == module_id:
			return interaction
	return null


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
