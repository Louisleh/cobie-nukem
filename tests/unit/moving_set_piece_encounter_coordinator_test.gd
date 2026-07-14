extends SceneTree

class ProbeEncounterActor extends Node3D:
	signal died(actor: Node, source: Node)

const MovingSetPieceDefinitionClass = preload("res://scripts/gameplay/moving_set_piece_definition.gd")
const MovingSetPieceRuntimeClass = preload("res://scripts/gameplay/moving_set_piece_runtime.gd")
const MovingSetPieceEncounterCoordinatorClass = preload("res://scripts/gameplay/moving_set_piece_encounter_coordinator.gd")
const EncounterDefinitionClass = preload("res://scripts/gameplay/encounter_definition.gd")
const ContentManifestClass = preload("res://scripts/gameplay/content_manifest.gd")
const MissionRuntimeClass = preload("res://scripts/gameplay/mission_runtime.gd")

const PROBE_SCENE_PATH := "res://tests/fixtures/moving_set_piece_probe.tscn"

var failures: Array[String] = []
var spawned_actors: Array[Node] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_happy_path_three_stops_three_waves()
	await _test_duplicate_and_stale_callback_rejection()
	await _test_reset_cycles_for_each_stage()
	await _test_reject_invalid_configuration()
	await _test_modules_required_for_completion()
	if failures.is_empty():
		print("MOVING SET PIECE ENCOUNTER COORDINATOR TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_happy_path_three_stops_three_waves() -> void:
	var runtime := _make_set_piece_runtime()
	var mission := _make_mission_runtime(&"external_three", 3)
	var definition := _make_set_piece_definition(
		[0.2, 0.5, 0.85],
		[&"enc_external_three"],
		[&"mod_alpha", &"mod_beta"],
	)
	var coordinator := MovingSetPieceEncounterCoordinatorClass.new()
	root.add_child(runtime)
	root.add_child(mission)
	root.add_child(coordinator)

	var configured := coordinator.configure(runtime, mission, definition, &"external_three")
	_expect(configured == MovingSetPieceEncounterCoordinatorClass.ERROR_NONE, "happy configure succeeds")
	if configured != MovingSetPieceEncounterCoordinatorClass.ERROR_NONE:
		_cleanup(runtime, mission, coordinator)
		return

	var completion_count := [0]
	runtime.completed.connect(func(_id: StringName, _generation: int) -> void: completion_count[0] += 1)
	if not runtime.start():
		failures.append("happy path runtime start")
		_cleanup(runtime, mission, coordinator)
		return

	_expect(await _wait_for_stop(runtime, 0), "first stop reached")
	_expect(_active_zone_wave_size(mission, &"external_three") == 1, "wave 0 spawns on first stop")
	_expect(_is_waiting_at_stop(runtime), "runtime waits at first stop")
	_kill_active_wave(mission, &"external_three")
	_expect(await _wait_for_stop(runtime, 1), "second stop reached after first wave clear")
	_expect(_active_zone_wave_size(mission, &"external_three") == 1, "wave 1 active after second stop")
	_kill_active_wave(mission, &"external_three")
	_expect(await _wait_for_stop(runtime, 2), "third stop reached after second wave clear")
	_expect(_active_zone_wave_size(mission, &"external_three") == 1, "wave 2 active after third stop")

	_kill_active_wave(mission, &"external_three")
	var generation := runtime.generation()
	_expect(coordinator.report_module_destroyed(&"mod_alpha", generation), "first module mark accepted")
	_expect(coordinator.report_module_destroyed(&"mod_beta", generation), "second module mark accepted")
	for _frame in 30:
		if completion_count[0] > 0:
			break
		await physics_frame
	_expect(completion_count[0] > 0, "set-piece completes after modules: runtime=%s coordinator=%s" % [runtime.current_state(), coordinator.current_state()])
	_expect(completion_count[0] == 1, "completion emitted once")
	_cleanup(runtime, mission, coordinator)


func _test_duplicate_and_stale_callback_rejection() -> void:
	var runtime := _make_set_piece_runtime()
	var mission := _make_mission_runtime(&"external_three", 3)
	var definition := _make_set_piece_definition(
		[0.2, 0.5, 0.8],
		[&"enc_external_three"],
		[&"mod_alpha", &"mod_beta"],
	)
	var coordinator := MovingSetPieceEncounterCoordinatorClass.new()
	var completion_count := [0]
	root.add_child(runtime)
	root.add_child(mission)
	root.add_child(coordinator)
	runtime.completed.connect(func(_id: StringName, _generation: int) -> void: completion_count[0] += 1)
	if coordinator.configure(runtime, mission, definition, &"external_three") != MovingSetPieceEncounterCoordinatorClass.ERROR_NONE:
		failures.append("duplicate/stale configure")
		_cleanup(runtime, mission, coordinator)
		return
	if not runtime.start():
		failures.append("duplicate/stale runtime start")
		_cleanup(runtime, mission, coordinator)
		return

	_expect(await _wait_for_stop(runtime, 0), "duplicate test reaches first stop")
	runtime.emit_signal("stop_reached", 0, 0.2)
	await physics_frame
	_expect(runtime.current_state().get("next_stop_index") == 1, "duplicate stop callback ignored")
	var stale_generation = int(runtime.generation())
	mission.emit_signal("wave_completed", mission.encounters.definitions.get(&"external_three"), 0)
	await physics_frame
	_expect(_is_waiting_at_stop(runtime), "stale wave callback does not resume")

	_kill_active_wave(mission, &"external_three")
	_expect(await _wait_for_stop(runtime, 1), "wave clear still reaches second stop")
	_expect(coordinator.report_module_destroyed(&"mod_alpha", stale_generation - 1) == false, "stale module generation rejected")
	_expect(coordinator.report_module_destroyed(&"mod_alpha", stale_generation), "current module generation accepted")
	_expect(coordinator.report_module_destroyed(&"mod_alpha", stale_generation) == false, "duplicate module callback rejected")
	_kill_active_wave(mission, &"external_three")
	_expect(await _wait_for_stop(runtime, 2), "second wave clear reaches third stop")
	_kill_active_wave(mission, &"external_three")
	_expect(coordinator.report_module_destroyed(&"mod_beta", stale_generation), "second module accepted")
	for _frame in 30:
		if completion_count[0] > 0:
			break
		await physics_frame
	_expect(completion_count[0] == 1, "completion after stale test: runtime=%s coordinator=%s" % [runtime.current_state(), coordinator.current_state()])
	_cleanup(runtime, mission, coordinator)


func _test_reset_cycles_for_each_stage() -> void:
	for stage in range(3):
		for iteration in range(5):
			var runtime := _make_set_piece_runtime()
			var mission := _make_mission_runtime(&"external_three", 3)
			var definition := _make_set_piece_definition(
				[0.2, 0.5, 0.8],
				[&"enc_external_three"],
				[&"mod_alpha", &"mod_beta"],
			)
			var coordinator := MovingSetPieceEncounterCoordinatorClass.new()
			root.add_child(runtime)
			root.add_child(mission)
			root.add_child(coordinator)
			if coordinator.configure(runtime, mission, definition, &"external_three") != MovingSetPieceEncounterCoordinatorClass.ERROR_NONE:
				failures.append("reset stage %d configure failed at %d" % [stage, iteration])
				_cleanup(runtime, mission, coordinator)
				continue
			if not runtime.start():
				failures.append("reset stage %d start failed at %d" % [stage, iteration])
				_cleanup(runtime, mission, coordinator)
				continue

			if stage >= 1:
				if not await _wait_for_stop(runtime, 0):
					failures.append("reset stage %d stalled at stop0 during %d" % [stage, iteration])
					_cleanup(runtime, mission, coordinator)
					continue
				_kill_active_wave(mission, &"external_three")
				if not await _wait_for_stop(runtime, 1):
					failures.append("reset stage %d stalled at stop1 during %d" % [stage, iteration])
					_cleanup(runtime, mission, coordinator)
					continue
			if stage == 2:
				_kill_active_wave(mission, &"external_three")
				if not await _wait_for_stop(runtime, 2):
					failures.append("reset stage %d stalled at stop2 during %d" % [stage, iteration])
					_cleanup(runtime, mission, coordinator)
					continue

			var before_generation := runtime.generation()
			if not coordinator.reset():
				failures.append("reset failed at stage %d iteration %d" % [stage, iteration])
				_cleanup(runtime, mission, coordinator)
				continue
			await physics_frame
			if runtime.generation() == before_generation:
				failures.append("reset did not invalidate generation at stage %d iteration %d" % [stage, iteration])
			if runtime.get_child_count() != 1:
				failures.append("reset keeps one runtime actor at stage %d iteration %d" % [stage, iteration])
			_cleanup(runtime, mission, coordinator)


func _test_reject_invalid_configuration() -> void:
	var runtime := _make_set_piece_runtime()
	var mission := _make_mission_runtime(&"reject_auto", 2)
	var coordinator := MovingSetPieceEncounterCoordinatorClass.new()
	var definition := _make_set_piece_definition(
		[0.25],
		[&"enc_reject_auto"],
		[&"mod_alpha"],
	)
	root.add_child(runtime)
	root.add_child(mission)
	root.add_child(coordinator)
	if coordinator.configure(runtime, mission, definition, &"reject_auto") != MovingSetPieceEncounterCoordinatorClass.ERROR_MISMATCHED_DEFINITION:
		failures.append("mismatched stop/wave counts rejected")
	_cleanup(runtime, mission, coordinator)

	runtime = _make_set_piece_runtime()
	mission = _make_mission_runtime(&"reject_auto", 2, EncounterDefinitionClass.WaveProgression.AUTO)
	coordinator = MovingSetPieceEncounterCoordinatorClass.new()
	definition = _make_set_piece_definition(
		[0.25, 0.6],
		[&"enc_reject_auto"],
		[&"mod_alpha", &"mod_beta"],
	)
	root.add_child(runtime)
	root.add_child(mission)
	root.add_child(coordinator)
	if coordinator.configure(runtime, mission, definition, &"reject_auto") != MovingSetPieceEncounterCoordinatorClass.ERROR_NON_EXTERNAL_ENCOUNTER:
		failures.append("AUTO encounter mode rejected")
	_cleanup(runtime, mission, coordinator)


func _test_modules_required_for_completion() -> void:
	var runtime := _make_set_piece_runtime([0.25], [&"enc_external_three"], [&"mod_alpha", &"mod_beta"])
	var mission := _make_mission_runtime(&"external_three", 1)
	var definition := _make_set_piece_definition(
		[0.25],
		[&"enc_external_three"],
		[&"mod_alpha", &"mod_beta"],
	)
	var coordinator := MovingSetPieceEncounterCoordinatorClass.new()
	var completion_count := [0]
	root.add_child(runtime)
	root.add_child(mission)
	root.add_child(coordinator)
	runtime.completed.connect(func(_id: StringName, _generation: int) -> void: completion_count[0] += 1)
	if coordinator.configure(runtime, mission, definition, &"external_three") != MovingSetPieceEncounterCoordinatorClass.ERROR_NONE:
		failures.append("module gate configure")
		_cleanup(runtime, mission, coordinator)
		return
	if not runtime.start():
		failures.append("module gate start")
		_cleanup(runtime, mission, coordinator)
		return

	if not await _wait_for_stop(runtime, 0):
		failures.append("module gate stop")
		_cleanup(runtime, mission, coordinator)
		return
	_kill_active_wave(mission, &"external_three")
	var generation := runtime.generation()
	_expect(not await _wait_for_completion(runtime, 30), "final completion waits for both modules")
	_expect(coordinator.report_module_destroyed(&"mod_alpha", generation), "first module accepted")
	_expect(completion_count[0] == 0, "first module cannot complete set piece")
	_expect(not await _wait_for_completion(runtime, 30), "still waiting for second module")
	_expect(coordinator.report_module_destroyed(&"mod_beta", generation), "second module accepted")
	await physics_frame
	_expect(completion_count[0] == 1, "completion after final module: runtime=%s coordinator=%s" % [runtime.current_state(), coordinator.current_state()])
	_cleanup(runtime, mission, coordinator)


func _make_set_piece_definition(stop_markers: Array[float], encounter_trigger_ids: Array[StringName], module_ids: Array[StringName]) -> MovingSetPieceDefinition:
	var definition := MovingSetPieceDefinitionClass.new() as MovingSetPieceDefinition
	definition.id = &"moving_set_piece_encounter"
	definition.actor_scene_path = PROBE_SCENE_PATH
	definition.path_points = [Vector3.ZERO, Vector3(5.0, 0.0, 0.0)]
	definition.speed = 4.0
	definition.stop_markers = stop_markers
	definition.encounter_trigger_ids = encounter_trigger_ids
	definition.destructible_module_ids = module_ids
	definition.completion_event = &"moving_set_piece_complete"
	definition.reset_policy = MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	return definition


func _make_set_piece_runtime(
	stop_markers: Array[float] = [0.2, 0.5, 0.8],
	encounter_trigger_ids: Array[StringName] = [&"enc_external_three"],
	module_ids: Array[StringName] = [&"mod_alpha", &"mod_beta"],
) -> MovingSetPieceRuntime:
	var definition := _make_set_piece_definition(
		stop_markers,
		encounter_trigger_ids,
		module_ids,
	)
	var runtime := MovingSetPieceRuntimeClass.new() as MovingSetPieceRuntime
	var result := runtime.configure(definition)
	_expect(result == MovingSetPieceRuntimeClass.ERROR_NONE, "set piece runtime configure baseline")
	return runtime


func _make_mission_runtime(zone_id: StringName, wave_count: int, progression: int = EncounterDefinitionClass.WaveProgression.EXTERNAL) -> MissionRuntime:
	var manifest := ContentManifestClass.new() as ContentManifest
	var encounter := EncounterDefinitionClass.new()
	encounter.id = StringName("enc_%s" % zone_id)
	encounter.zone_id = zone_id
	encounter.wave_progression = progression
	encounter.completion_policy = EncounterDefinitionClass.CompletionPolicy.ALL_DEFEATED
	var waves: Array[Dictionary] = []
	for wave_index in wave_count:
		waves.append({
			"delay_seconds": 0.0,
			"spawns": [{"scene": "res://tests/unit/missing", "position": Vector3(float(wave_index), 0.0, 0.0)}],
		})
	encounter.waves = waves
	manifest.encounters = [encounter]
	var mission := MissionRuntimeClass.new() as MissionRuntime
	mission.configure(manifest, Callable(self, "_spawn_encounter_actor"))
	return mission


func _spawn_encounter_actor(_scene_path: String, position: Vector3) -> Node:
	var actor := ProbeEncounterActor.new() as ProbeEncounterActor
	actor.position = position
	root.add_child(actor)
	spawned_actors.append(actor)
	return actor


func _wait_for_stop(runtime: MovingSetPieceRuntime, index: int, timeout_frames: int = 180) -> bool:
	for _frame in range(timeout_frames):
		await physics_frame
		if int(runtime.current_state().get("next_stop_index", 0)) > index:
			return true
	return false


func _wait_for_completion(runtime: MovingSetPieceRuntime, timeout_frames: int = 240) -> bool:
	var done := false
	runtime.completed.connect(func(_id: StringName, _generation: int) -> void: done = true, CONNECT_ONE_SHOT)
	for _frame in range(timeout_frames):
		await physics_frame
		if done:
			return true
	return false


func _kill_active_wave(mission: MissionRuntime, zone_id: StringName) -> bool:
	if mission.encounters == null:
		return false
	if not mission.encounters.active.has(zone_id):
		return false
	var active_state := mission.encounters.active.get(zone_id) as Dictionary
	var actors: Array = active_state.get("actors", [])
	if actors.is_empty():
		return false
	for actor in actors.duplicate():
		if not is_instance_valid(actor):
			continue
		(actor as ProbeEncounterActor).died.emit(actor, mission)
	return true


func _is_waiting_at_stop(runtime: MovingSetPieceRuntime) -> bool:
	var state := runtime.current_state()
	return bool(state.get("waiting_for_stop", false)) and not bool(state.get("moving", false))


func _active_zone_wave_size(mission: MissionRuntime, zone_id: StringName) -> int:
	if mission.encounters == null or not mission.encounters.active.has(zone_id):
		return 0
	var active_state := mission.encounters.active.get(zone_id) as Dictionary
	return int(active_state.get("actors", []).size())


func _cleanup(runtime: MovingSetPieceRuntime, mission: MissionRuntime, coordinator: MovingSetPieceEncounterCoordinator) -> void:
	if runtime != null and is_instance_valid(runtime):
		runtime.queue_free()
	if mission != null and is_instance_valid(mission):
		mission.queue_free()
	if coordinator != null and is_instance_valid(coordinator):
		coordinator.queue_free()
	for actor in spawned_actors:
		if is_instance_valid(actor):
			actor.queue_free()
	spawned_actors.clear()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
