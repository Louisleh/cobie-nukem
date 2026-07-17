extends SceneTree

class TestWaveProbe extends Node3D:
	signal died(actor: Node, source: Node)

const CYCLE_COUNT := 100
const PHASE_COUNT := 4

const ENCOUNTER_ZONE_ID := &"harbour_pier"
const TARGET_ENCOUNTER_ID := &"vancouver_convoy_showdown"

const EXPECTED_PHASE_IDS: Array[StringName] = [
	&"appeal_filed",
	&"appeal_denied",
	&"final_notice",
	&"case_closed",
]
const EXPECTED_MODULE_IDS: Array[StringName] = [
	&"citation_drive_left",
	&"citation_signal_dish",
	&"citation_drive_right",
	&"citation_core",
]
const EXPECTED_WAVE_INDICES: Array[int] = [0, 1, 2, 3]
const EXPECTED_HEALTH_ALLOCATION: Array[float] = [250.0, 250.0, 250.0, 250.0]
const EXPECTED_STOP_MARKERS: Array[float] = [0.22, 0.51, 0.75, 0.94]
const BOSS_HEALTH_BUDGET := 1000.0

const CONVOY_DEFINITION := preload("res://resources/set_pieces/vancouver_citation_convoy.tres") as MovingSetPieceDefinition
const VANCOUVER_MANIFEST := preload("res://resources/content/vancouver_waterfront_manifest.tres") as ContentManifest
const CONVOY_SCENE := preload("res://scenes/set_pieces/citation_convoy.tscn")

var failures: Array[String] = []
var _completion_signal_count := 0
var _completion_generations: Array[int] = []
var _seen_completion_generations: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_convoy_contract()
	if failures.is_empty():
		await _validate_actor_presentation()
	if failures.is_empty():
		await _test_deterministic_reset_cycles()
	if failures.is_empty():
		print("RAIN CITY CONVOY BOSS SOAK TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _validate_convoy_contract() -> void:
	_expect(CONVOY_DEFINITION != null, "production convoy definition loads")
	if CONVOY_DEFINITION == null:
		return

	var validation := CONVOY_DEFINITION.validate()
	_expect(validation.is_empty(), "vancouver convoy definition validates")
	if not validation.is_empty():
		return

	_expect(CONVOY_DEFINITION.schema_version == 2, "convoy schema_version is 2")
	_expect(CONVOY_DEFINITION.id == &"citation_convoy", "convoy id is canonical")
	_expect(CONVOY_DEFINITION.path_points.size() >= 2, "convoy has authored path points")
	_expect(CONVOY_DEFINITION.phases.size() == PHASE_COUNT, "convoy defines %d phases" % PHASE_COUNT)
	_expect(CONVOY_DEFINITION.destructible_module_ids == EXPECTED_MODULE_IDS, "convoy module order is canonical")
	_expect(CONVOY_DEFINITION.encounter_trigger_ids == [TARGET_ENCOUNTER_ID], "convoy uses only the canonical encounter trigger")
	_expect(_float_arrays_match(CONVOY_DEFINITION.stop_markers, EXPECTED_STOP_MARKERS), "convoy stop markers are canonical")

	var phase_ids: Array[StringName] = []
	var module_ids: Array[StringName] = []
	var wave_indices: Array[int] = []
	var health_values: Array[float] = []
	var total_health := 0.0
	for phase in CONVOY_DEFINITION.phases:
		if phase == null:
			_expect(false, "convoy phase entries are non-null")
			continue
		phase_ids.append(phase.phase_id)
		module_ids.append(phase.required_module_id)
		wave_indices.append(int(phase.encounter_wave_index))
		health_values.append(float(phase.health_allocation))
		_expect(phase.encounter_id == TARGET_ENCOUNTER_ID, "convoy phase encounter id is canonical")
		total_health += float(phase.health_allocation)

	_expect(phase_ids == EXPECTED_PHASE_IDS, "convoy phase ids are canonical")
	_expect(module_ids == EXPECTED_MODULE_IDS, "convoy required modules are canonical")
	_expect(wave_indices == EXPECTED_WAVE_INDICES, "convoy wave indexes are canonical")
	_expect(_float_arrays_match(health_values, EXPECTED_HEALTH_ALLOCATION), "convoy health allocations are canonical")
	_expect(is_equal_approx(total_health, BOSS_HEALTH_BUDGET), "convoy health budget totals 1000")


func _validate_actor_presentation() -> void:
	var actor := CONVOY_SCENE.instantiate() as CitationConvoyActor
	_expect(actor != null, "production convoy actor instantiates")
	if actor == null:
		return
	root.add_child(actor)
	await process_frame
	_expect(actor.get_node_or_null("LeadVehicle") != null, "convoy owns authored lead vehicle presentation")
	_expect(actor.get_node_or_null("EscortLeft") != null and actor.get_node_or_null("EscortRight") != null, "convoy owns two escort vehicles")
	var tickets := actor.get_node_or_null("TicketDebris") as CPUParticles3D
	var sparks := actor.get_node_or_null("DefeatSparks") as CPUParticles3D
	_expect(tickets != null and tickets.one_shot and tickets.amount <= 28, "ticket debris is one-shot and bounded")
	_expect(sparks != null and sparks.one_shot and sparks.amount <= 18, "defeat sparks are one-shot and bounded")
	_expect(actor.play_defeat_sequence(), "convoy defeat presentation starts exactly once")
	_expect(actor.defeat_started(), "convoy records persistent defeat state")
	_expect(not actor.play_defeat_sequence(), "convoy rejects duplicate defeat presentation")
	actor.queue_free()
	await process_frame


func _test_deterministic_reset_cycles() -> void:
	var mission_runtime := _make_mission_runtime()
	if mission_runtime == null:
		return

	var runtime := _make_set_piece_runtime()
	if runtime == null:
		mission_runtime.queue_free()
		return

	var coordinator := _make_coordinator(runtime, mission_runtime)
	if coordinator == null:
		runtime.queue_free()
		mission_runtime.queue_free()
		return

	runtime.completed.connect(_on_convoy_completed)

	if not runtime.start():
		failures.append("convoy runtime start")
		_cleanup(runtime, mission_runtime, coordinator)
		return

	for cycle in range(CYCLE_COUNT):
		var cycle_generation := int(runtime.generation())
		var stale_generation := cycle_generation - 1
		var completion_target := _completion_signal_count + 1

		_expect(not runtime.mark_encounter_completed(TARGET_ENCOUNTER_ID, stale_generation), "cycle %d stale encounter callback is ignored" % cycle)
		_expect(not coordinator.report_module_destroyed(EXPECTED_MODULE_IDS[0], stale_generation), "cycle %d stale module callback is ignored" % cycle)
		_expect(_completion_signal_count == completion_target - 1, "cycle %d has no prior completion signal" % cycle)

		for phase_index in range(PHASE_COUNT):
			var at_stop := await _drive_to_stop(runtime, phase_index)
			_expect(at_stop, "cycle %d reaches stop %d" % [cycle, phase_index])
			if not at_stop:
				failures.append("cycle %d could not reach stop %d" % [cycle, phase_index])
				_cleanup(runtime, mission_runtime, coordinator)
				return

			var runtime_state := runtime.current_state()
			var expected_health_before := _expected_health_after_phases_completed(phase_index)
			_expect(int(runtime_state.get("active_phase_index", -1)) == phase_index, "cycle %d tracks active phase %d" % [cycle, phase_index])
			_expect(int(runtime_state.get("next_stop_index", -1)) == phase_index + 1, "cycle %d tracks next stop index %d" % [cycle, phase_index + 1])
			_expect(is_equal_approx(float(runtime_state.get("current_boss_health", 0.0)), expected_health_before), "cycle %d starts phase %d with canonical boss health" % [cycle, phase_index])

			var module_id := EXPECTED_MODULE_IDS[phase_index]
			var module_first := cycle % 2 == 0
			if module_first:
				_expect(coordinator.report_module_destroyed(module_id, cycle_generation), "cycle %d marks module-first gate for phase %d" % [cycle, phase_index])
				_expect(not coordinator.report_module_destroyed(module_id, cycle_generation), "cycle %d rejects duplicate module gate for phase %d" % [cycle, phase_index])
				_expect(_kill_active_wave(mission_runtime, ENCOUNTER_ZONE_ID), "cycle %d completes wave %d" % [cycle, phase_index])
			else:
				_expect(_kill_active_wave(mission_runtime, ENCOUNTER_ZONE_ID), "cycle %d completes wave %d" % [cycle, phase_index])
				_expect(coordinator.report_module_destroyed(module_id, cycle_generation), "cycle %d marks module gate for phase %d" % [cycle, phase_index])
				_expect(not coordinator.report_module_destroyed(module_id, cycle_generation), "cycle %d rejects duplicate module gate for phase %d" % [cycle, phase_index])

			if phase_index == PHASE_COUNT - 1:
				_expect(await _drive_to_path_end(runtime), "cycle %d reaches path end after final gate resolution" % cycle)
				_expect(await _wait_for_completion_count(completion_target), "cycle %d emits exactly one completion callback" % cycle)
				_expect(_completion_signal_count == completion_target, "cycle %d has one completion signal" % cycle)
				_expect(_completion_generations.size() == _completion_signal_count, "cycle %d completion list is synced" % cycle)
				_expect(_completion_generations.has(cycle_generation), "cycle %d reports completion on the active generation" % cycle)

				var final_state := runtime.current_state()
				var completed_phases: Variant = final_state.get("completed_phase_ids", [])
				var completed_phase_ids: Array[StringName] = completed_phases as Array[StringName]
				_expect(completed_phase_ids == EXPECTED_PHASE_IDS, "cycle %d marks all phases complete in order" % cycle)
				_expect(bool(final_state.get("path_completed", false)), "cycle %d marks path as completed" % cycle)
				_expect(bool(final_state.get("completion_emitted", false)), "cycle %d emits completion state" % cycle)
				_expect(is_equal_approx(float(final_state.get("current_boss_health", 0.0)), 0.0), "cycle %d drains full boss health budget" % cycle)
			else:
				var next_stop_ok := await _drive_to_stop(runtime, phase_index + 1)
				_expect(next_stop_ok, "cycle %d reaches next stop after phase %d" % [cycle, phase_index])
				var progressed_state := runtime.current_state()
				_expect(progressed_state.get("path_completed", false) == false, "cycle %d stays active before final phase" % cycle)
				_expect(progressed_state.get("completion_emitted", false) == false, "cycle %d does not complete early" % cycle)
				var expected_health_after := _expected_health_after_phases_completed(phase_index + 1)
				_expect(is_equal_approx(float(progressed_state.get("current_boss_health", 0.0)), expected_health_after), "cycle %d drains phase %d health by module gate" % [cycle, phase_index])

		if cycle + 1 < CYCLE_COUNT:
			_expect(coordinator.reset(), "cycle %d resets runtime and encounter zone" % cycle)
			await process_frame
			var reset_state := runtime.current_state()
			_expect(int(reset_state.get("generation", -1)) == cycle_generation + 1, "cycle %d advances generation on reset" % cycle)
			_expect(int(reset_state.get("active_phase_index", -1)) == 0, "cycle %d returns to phase index 0" % cycle)
			_expect(int(reset_state.get("next_stop_index", -1)) == 0, "cycle %d returns to stop index 0" % cycle)
			_expect(bool(reset_state.get("path_completed", false)) == false, "cycle %d clears path_completed" % cycle)
			_expect(bool(reset_state.get("completion_emitted", true)) == false, "cycle %d clears completion_emitted" % cycle)
			_expect(_float_arrays_match(reset_state.get("phase_health", []), EXPECTED_HEALTH_ALLOCATION), "cycle %d restores phase health buckets" % cycle)
			_expect(is_equal_approx(float(reset_state.get("current_boss_health", 0.0)), BOSS_HEALTH_BUDGET), "cycle %d restores boss health budget" % cycle)
			_expect(runtime.get_child_count() == 1, "cycle %d keeps single runtime actor through reset" % cycle)
			_expect(not mission_runtime.encounters.active.has(ENCOUNTER_ZONE_ID), "cycle %d clears active encounter zone on reset" % cycle)
			_expect(_completion_signal_count == completion_target, "cycle %d does not emit completion during reset" % cycle)

	_cleanup(runtime, mission_runtime, coordinator)


func _make_set_piece_runtime() -> MovingSetPieceRuntime:
	var runtime := MovingSetPieceRuntime.new() as MovingSetPieceRuntime
	var result := runtime.configure(CONVOY_DEFINITION)
	if result != MovingSetPieceRuntime.ERROR_NONE:
		failures.append("convoy runtime configure failed: %s" % result)
		runtime.queue_free()
		return null
	root.add_child(runtime)
	return runtime


func _make_mission_runtime() -> MissionRuntime:
	if VANCOUVER_MANIFEST == null:
		failures.append("vancouver manifest failed to load")
		return null
	var mission_runtime := MissionRuntime.new() as MissionRuntime
	mission_runtime.configure(VANCOUVER_MANIFEST, Callable(self, "_spawn_wave_probe"))
	root.add_child(mission_runtime)
	return mission_runtime


func _make_coordinator(runtime: MovingSetPieceRuntime, mission_runtime: MissionRuntime) -> MovingSetPieceEncounterCoordinator:
	if runtime == null or mission_runtime == null:
		failures.append("coordinator missing runtime dependencies")
		return null
	var coordinator := MovingSetPieceEncounterCoordinator.new() as MovingSetPieceEncounterCoordinator
	var configured := coordinator.configure(runtime, mission_runtime, CONVOY_DEFINITION, ENCOUNTER_ZONE_ID)
	if configured != MovingSetPieceEncounterCoordinator.ERROR_NONE:
		failures.append("coordinator configure failed: %s" % configured)
		coordinator.queue_free()
		return null
	root.add_child(coordinator)
	return coordinator


func _spawn_wave_probe(_scene_path: String, position: Vector3) -> Node:
	var probe := TestWaveProbe.new() as TestWaveProbe
	probe.position = position
	root.add_child(probe)
	return probe


func _drive_to_stop(runtime: MovingSetPieceRuntime, stop_index: int, timeout_steps := 260, delta := 0.25) -> bool:
	for _step in range(timeout_steps):
		if int(runtime.current_state().get("next_stop_index", 0)) > stop_index:
			return true
		runtime._physics_process(delta)
	return int(runtime.current_state().get("next_stop_index", 0)) > stop_index


func _drive_to_path_end(runtime: MovingSetPieceRuntime, timeout_steps := 360, delta := 0.25) -> bool:
	for _step in range(timeout_steps):
		if bool(runtime.current_state().get("path_completed", false)):
			return true
		runtime._physics_process(delta)
	return bool(runtime.current_state().get("path_completed", false))


func _wait_for_completion_count(target_count: int, timeout_frames := 120) -> bool:
	if _completion_signal_count >= target_count:
		return true
	for _frame in range(timeout_frames):
		await process_frame
		if _completion_signal_count >= target_count:
			return true
	return _completion_signal_count >= target_count


func _kill_active_wave(mission_runtime: MissionRuntime, zone_id: StringName) -> bool:
	if mission_runtime == null or mission_runtime.encounters == null:
		return false
	if not mission_runtime.encounters.active.has(zone_id):
		return false
	var active_state := mission_runtime.encounters.active.get(zone_id) as Dictionary
	var actors: Array = active_state.get("actors", []).duplicate()
	var timer := active_state.get("timer") as Timer
	if actors.is_empty() and timer != null and is_instance_valid(timer):
		timer.timeout.emit()
		actors = active_state.get("actors", []).duplicate()
	if actors.is_empty():
		return false
	var killed := 0
	for actor in actors:
		if not is_instance_valid(actor):
			continue
		if actor.has_signal("died"):
			actor.emit_signal("died", actor, mission_runtime)
		else:
			actor.queue_free()
		killed += 1
	return killed > 0


func _expected_health_after_phases_completed(completed_phases: int) -> float:
	var remaining := BOSS_HEALTH_BUDGET
	for index in range(completed_phases):
		remaining -= EXPECTED_HEALTH_ALLOCATION[index]
	return remaining


func _float_arrays_match(a: Array, b: Array[float], tolerance := 0.0005) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if absf(float(a[index]) - float(b[index])) > tolerance:
			return false
	return true


func _on_convoy_completed(_id: StringName, generation: int) -> void:
	if _seen_completion_generations.has(generation):
		failures.append("duplicate completion callback for generation %s" % generation)
	else:
		_seen_completion_generations[generation] = true
	_completion_signal_count += 1
	_completion_generations.append(generation)


func _cleanup(runtime: MovingSetPieceRuntime, mission_runtime: MissionRuntime, coordinator: MovingSetPieceEncounterCoordinator) -> void:
	if is_instance_valid(runtime):
		runtime.queue_free()
	if is_instance_valid(mission_runtime):
		mission_runtime.queue_free()
	if is_instance_valid(coordinator):
		coordinator.queue_free()
	for child in root.get_children():
		if child is TestWaveProbe:
			child.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
