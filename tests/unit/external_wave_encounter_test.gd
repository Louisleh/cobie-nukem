extends SceneTree

class ProbeEncounterActor extends Node3D:
	signal died(actor: Node, source: Node)


var failures: PackedStringArray = []
var runner: EncounterRunner
var spawned: Array[Node] = []
var wave_started: Array[int] = []
var wave_completed: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_auto_regression()
	await _test_external_three_waves()
	await _test_advance_rejection_contract()
	await _test_restore_and_timer_invalidation()
	if failures.is_empty():
		print("EXTERNAL WAVE ENCOUNTER TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_auto_regression() -> void:
	var definition := _make_auto_definition()
	runner = _build_runner(definition)
	_connect_wave_listeners()
	var actors: Array = runner.activate_zone(&"auto_regression")
	_assert(actors.size() == 1, "AUTO encounter starts its first wave with its only spawn")
	_assert(wave_started == [0], "AUTO emits wave_started for wave 0")
	_assert(wave_completed.is_empty(), "AUTO does not emit wave_completed before the wave ends")

	(actors[0] as ProbeEncounterActor).died.emit(actors[0], runner)
	await create_timer(0.12).timeout
	_assert(wave_started == [0, 1], "AUTO advances to authored wave 1")
	var active_wave: Array = runner.active.get(&"auto_regression", {}).get("actors", [])
	_assert(active_wave.size() == 1, "AUTO wave 1 spawns its authored actor")
	(active_wave[0] as ProbeEncounterActor).died.emit(active_wave[0], runner)
	await process_frame
	_assert(wave_completed == [0, 1], "AUTO emits wave_completed for every finished wave")
	_assert(runner.completed.has(&"auto_regression"), "AUTO encounter eventually completes")
	await _cleanup_runner()


func _test_external_three_waves() -> void:
	var definition := _make_external_definition(3, 0.0)
	runner = _build_runner(definition)
	_connect_wave_listeners()
	var actors: Array = runner.activate_zone(&"external_three")
	_assert(actors.size() == 1, "EXTERNAL encounters start at wave 0")
	_assert(not runner.advance_external_wave(&"external_three"), "EXTERNAL advance is rejected while the active wave is alive")
	(actors[0] as ProbeEncounterActor).died.emit(actors[0], runner)
	await process_frame
	_assert(wave_completed == [0], "EXTERNAL emits wave_completed for the first wave")
	_assert(runner.advance_external_wave(&"external_three"), "EXTERNAL advance starts wave 1 after wave clear")
	_assert(not runner.advance_external_wave(&"external_three"), "duplicate EXTERNAL advance is rejected until the next completion")
	actors = runner.active.get(&"external_three", {}).get("actors", [])
	_assert(actors.size() == 1, "EXTERNAL advance starts the second authored wave")
	(actors[0] as ProbeEncounterActor).died.emit(actors[0], runner)
	await process_frame
	_assert(wave_completed == [0, 1], "EXTERNAL emits wave_completed for wave 1")
	_assert(runner.advance_external_wave(&"external_three"), "EXTERNAL advance starts wave 2 after second completion")
	actors = runner.active.get(&"external_three", {}).get("actors", [])
	_assert(actors.size() == 1, "EXTERNAL advance starts the third authored wave")
	(actors[0] as ProbeEncounterActor).died.emit(actors[0], runner)
	await process_frame
	_assert(wave_completed == [0, 1, 2], "EXTERNAL emits wave_completed for wave 2")
	_assert(wave_started == [0, 1, 2], "EXTERNAL emits wave_started for all authored waves")
	_assert(runner.completed.has(&"external_three"), "EXTERNAL completes after the final wave is defeated")
	_assert(not runner.advance_external_wave(&"external_three"), "EXTERNAL advance is rejected after the encounter completes")
	await _cleanup_runner()


func _test_advance_rejection_contract() -> void:
	var definition := _make_external_definition(2, 0.0)
	runner = _build_runner(definition)
	_connect_wave_listeners()
	_assert(not runner.advance_external_wave(&"before_activate"), "EXTERNAL advance before activation is rejected")
	var actors: Array = runner.activate_zone(&"external_reject")
	_assert(actors.size() == 1, "EXTERNAL has an initial actor on first activation")
	_assert(not runner.advance_external_wave(&"external_reject"), "EXTERNAL advance is rejected with wave in progress")
	(actors[0] as ProbeEncounterActor).died.emit(actors[0], runner)
	await process_frame
	_assert(runner.advance_external_wave(&"external_reject"), "EXTERNAL advance is accepted after the wave is defeated")
	var pending_actors: Array = runner.active.get(&"external_reject", {}).get("actors", [])
	_assert(pending_actors.size() == 1, "EXTERNAL advance starts the next wave")
	runner.reset_zone(&"external_reject")
	_assert(not runner.advance_external_wave(&"external_reject"), "EXTERNAL advance after reset is rejected")
	await _cleanup_runner()


func _test_restore_and_timer_invalidation() -> void:
	var definition := _make_external_definition(2, 0.25, &"restore_timer")
	runner = _build_runner(definition)
	_connect_wave_listeners()
	var actors: Array = runner.activate_zone(&"restore_timer")
	(actors[0] as ProbeEncounterActor).died.emit(actors[0], runner)
	await process_frame
	var advance_acceptance: bool = runner.advance_external_wave(&"restore_timer")
	_assert(advance_acceptance, "EXTERNAL advance with delayed wave returns a valid advance")
	var snapshot := runner.snapshot()
	await create_timer(0.08).timeout
	runner.reset_zone(&"restore_timer")
	await process_frame
	runner.restore(snapshot)
	actors = runner.activate_zone(&"restore_timer")
	_assert(actors.size() == 1, "restore allows deterministic respawn from the active snapshot seed")
	_assert(is_equal_approx((actors[0] as Node3D).position.x, 1.0), "restore restarts the snapshotted active wave rather than wave zero")
	await create_timer(0.35).timeout
	_assert(not runner.completed.has(&"restore_timer"), "restored delayed timer does not falsely complete encounter")
	_assert(not runner.active.get(&"restore_timer", {}).get("pending_external_advance", true), "restore invalidates restored advance armament")
	(actors[0] as ProbeEncounterActor).died.emit(actors[0], runner)
	await process_frame
	_assert(wave_completed == [0, 1], "restored EXTERNAL wave still completes through normal contract")
	await _cleanup_runner()


func _build_runner(definition: EncounterDefinition) -> EncounterRunner:
	var new_runner := EncounterRunner.new()
	root.add_child(new_runner)
	new_runner.configure([definition], Callable(self, "_spawn_test_actor"))
	return new_runner


func _connect_wave_listeners() -> void:
	runner.wave_started.connect(func(_definition: EncounterDefinition, wave_index: int) -> void: wave_started.append(wave_index))
	runner.wave_completed.connect(func(_definition: EncounterDefinition, wave_index: int) -> void: wave_completed.append(wave_index))


func _make_auto_definition() -> EncounterDefinition:
	var definition := EncounterDefinition.new()
	definition.id = &"auto_regression"
	definition.zone_id = &"auto_regression"
	definition.schema_version = 2
	definition.maximum_simultaneous_attackers = 1
	definition.wave_progression = EncounterDefinition.WaveProgression.AUTO
	definition.waves = [
		{"delay_seconds": 0.0, "spawns": [{"scene": "res://tests/unit/missing", "position": Vector3(0.0, 0.0, 0.0)}]},
		{"delay_seconds": 0.0, "spawns": [{"scene": "res://tests/unit/missing", "position": Vector3(2.0, 0.0, 0.0)}]},
	]
	definition.completion_policy = EncounterDefinition.CompletionPolicy.ALL_DEFEATED
	definition.enemy_budget = 2
	return definition


func _make_external_definition(total_waves: int, wave_delay: float, zone_override: StringName = &"") -> EncounterDefinition:
	var definition := EncounterDefinition.new()
	definition.id = &"external_contract"
	definition.schema_version = 2
	definition.maximum_simultaneous_attackers = 1
	definition.wave_progression = EncounterDefinition.WaveProgression.EXTERNAL
	definition.completion_policy = EncounterDefinition.CompletionPolicy.ALL_DEFEATED
	definition.enemy_budget = total_waves
	var waves: Array[Dictionary] = []
	for wave_index in total_waves:
		waves.append({"delay_seconds": wave_delay, "spawns": [{"scene": "res://tests/unit/missing", "position": Vector3(float(wave_index), 0.0, 0.0)}]})
	definition.waves = waves
	if zone_override != &"":
		definition.zone_id = zone_override
	elif total_waves == 2:
		definition.zone_id = &"external_reject"
	elif total_waves == 3:
		definition.zone_id = &"external_three"
	else:
		definition.zone_id = &"external_contract"
	definition.enemy_budget = total_waves
	return definition


func _spawn_test_actor(_scene_path: String, position: Vector3) -> Node:
	var actor := ProbeEncounterActor.new()
	actor.position = position
	root.add_child(actor)
	spawned.append(actor)
	return actor


func _cleanup_runner() -> void:
	for actor in spawned:
		if is_instance_valid(actor):
			actor.queue_free()
	spawned.clear()
	wave_started.clear()
	wave_completed.clear()
	if runner != null and is_instance_valid(runner):
		runner.queue_free()
	runner = null
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
