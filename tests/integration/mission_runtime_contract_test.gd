extends SceneTree

class ProbeEncounterActor extends Node3D:
	signal died(actor: Node, source: Node)

	func set_target(_target: Node3D) -> void:
		pass


const TEST_ZONE_ID := &"contract_zone"
const TEST_GOAL_ID := &"forbidden_zone"
const TEST_COIN_ID := &"collector_token"

var failures: Array[String] = []
var runtime: MissionRuntime
var spawned_actors: Array[Node] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_reconfigure_idempotence()
	await _teardown_runtime()
	await _test_configure_and_objective_contract()
	await _test_encounter_completion_snapshot()
	await _test_restore_idempotence_and_teardown()
	await _teardown_runtime()
	if failures.is_empty():
		print("MISSION RUNTIME CONTRACT TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_configure_and_objective_contract() -> void:
	var manifest := _make_manifest(true)
	runtime = _new_runtime(manifest)
	if runtime == null:
		_fail("runtime could not be configured")
		return

	var activated: Array[StringName] = []
	var completed: Array[StringName] = []
	runtime.objective_activated.connect(func(definition: ObjectiveDefinition) -> void: activated.append(definition.id))
	runtime.objective_completed.connect(func(definition: ObjectiveDefinition) -> void: completed.append(definition.id))
	runtime.announce_available_objectives()

	await process_frame
	_assert(activated == [&"reach_forbidden_zone"], "runtime announces initial objective to post-wiring consumers")
	_assert(_active_objective_ids() == [&"reach_forbidden_zone"], "configure exposes exactly one prerequisite-free objective")

	var first_wave := runtime.record_objective(ObjectiveDefinition.Kind.REACH_ZONE, TEST_GOAL_ID)
	_assert(first_wave == [&"reach_forbidden_zone"], "first objective reaches required count and emits completed")
	_assert(activated.has(&"collect_two_tokens"), "completing prerequisite objective activates dependent objective")

	var first_progress := runtime.record_objective(ObjectiveDefinition.Kind.COLLECT_ITEM, TEST_COIN_ID)
	_assert(first_progress.is_empty(), "partially completed dependent objective does not emit completion")
	_assert(
		int(runtime.objectives.snapshot().progress.get("collect_two_tokens", 0)) == 1,
		"objective progress advances when action target matches"
	)

	var second_progress := runtime.record_objective(ObjectiveDefinition.Kind.COLLECT_ITEM, TEST_COIN_ID)
	_assert(second_progress == [&"collect_two_tokens"], "dependent objective completes when its second progress point lands")
	_assert(runtime.objectives.is_complete(), "objective graph reaches terminal complete state")


func _test_reconfigure_idempotence() -> void:
	runtime = _new_runtime(_make_manifest(true))
	if runtime == null:
		_fail("runtime could not be configured for idempotence coverage")
		return
	var base_snapshot := _normalize_snapshot(runtime.snapshot())
	runtime.configure(_make_manifest(true), Callable(self, "_spawn_encounter_actor"))
	await process_frame
	_assert(runtime.get_children().size() == 2, "reconfigure replaces old runtime children synchronously")
	_assert(runtime.objectives != null, "configure preserves objective tracker reference")
	_assert(runtime.encounters != null, "configure preserves encounter runner reference")
	var reconfigured_snapshot := _normalize_snapshot(runtime.snapshot())
	_assert(base_snapshot == reconfigured_snapshot, "configure-reconfiguration starts from a clean deterministic snapshot")
	_assert(runtime.objectives.active_objectives().size() >= 1, "reconfigured runtime exposes objective seed data")


func _test_encounter_completion_snapshot() -> void:
	var snapshot_before_runtime: Dictionary = runtime.snapshot()
	var zone_id := TEST_ZONE_ID
	var actor_spawned_events: Array[bool] = []
	var actor_defeated_events: Array[bool] = []
	var encounter_completed_events: Array[bool] = []
	runtime.actor_spawned.connect(func(_actor: Node, _definition: EncounterDefinition) -> void: actor_spawned_events.append(true))
	runtime.actor_defeated.connect(func(_actor: Node, _definition: EncounterDefinition) -> void: actor_defeated_events.append(true))
	runtime.encounter_completed.connect(func(_definition: EncounterDefinition) -> void: encounter_completed_events.append(true))

	var active_actors := runtime.activate_zone(zone_id)
	_assert(active_actors.size() == 2, "encounter activation spawns the authored wave actor count")
	_assert(runtime.encounters.active.has(zone_id), "activated encounter appears in active state map")

	for actor in active_actors:
		if actor is ProbeEncounterActor:
			actor.died.emit(actor, runtime)

	await process_frame
	_assert(runtime.encounters.completed.has(zone_id), "encounter reaches completed state after all wave actors die")
	var snapshot_after_runtime := runtime.snapshot()

	_assert(snapshot_after_runtime.has("objective_snapshot"), "snapshot contains objective subcontract")
	_assert(snapshot_after_runtime.has("encounter_snapshot"), "snapshot contains encounter subcontract")
	_assert(_is_primitive_snapshot(snapshot_after_runtime), "snapshot values remain primitive-only across both subcontracts")
	var encounter_snapshot: Dictionary = snapshot_after_runtime.get("encounter_snapshot", {})
	_assert(encounter_snapshot is Dictionary, "encounter snapshot is dictionary")
	var completed_ids: Array = encounter_snapshot.get("completed", [])
	_assert(completed_ids.has(String(zone_id)) or completed_ids.has(StringName(zone_id)), "completed encounter persists in checkpoint snapshot")
	_assert(actor_spawned_events.size() == 2, "runtime forwards actor_spawned events")
	_assert(actor_defeated_events.size() == 2, "runtime forwards actor_defeated events")
	_assert(encounter_completed_events.size() == 1, "runtime forwards encounter_completed events")
	_assert(snapshot_before_runtime != snapshot_after_runtime, "objective progress and encounter completion change snapshot between pre/post runtime states")


func _test_restore_idempotence_and_teardown() -> void:
	var baseline_snapshot := _normalize_snapshot(runtime.snapshot())
	runtime.restore(baseline_snapshot)
	await process_frame
	runtime.restore(baseline_snapshot)
	await process_frame
	var restored_snapshot := _normalize_snapshot(runtime.snapshot())
	_assert(restored_snapshot == baseline_snapshot, "restoring identical snapshot twice is idempotent")

	var replay := runtime.activate_zone(TEST_ZONE_ID)
	_assert(replay.is_empty(), "restored completed encounter is correctly suppressed")
	var completed_progress := runtime.record_objective(ObjectiveDefinition.Kind.REACH_ZONE, TEST_GOAL_ID)
	_assert(completed_progress.is_empty(), "restored completed objectives cannot be re-progressed")

func _new_runtime(manifest: ContentManifest) -> MissionRuntime:
	runtime = MissionRuntime.new()
	runtime.name = "MissionRuntimeContractTest"
	root.add_child(runtime)
	runtime.configure(manifest, Callable(self, "_spawn_encounter_actor"))
	return runtime


func _make_manifest(enable_zone: bool) -> ContentManifest:
	var manifest := ContentManifest.new()
	manifest.level_id = &"mission_runtime_contract_level"
	manifest.objectives = [
		_make_objective(&"reach_forbidden_zone", &"Reach the forbidden zone", ObjectiveDefinition.Kind.REACH_ZONE, TEST_GOAL_ID, 1, false, []),
		_make_objective(&"collect_two_tokens", &"Collect two collector tokens", ObjectiveDefinition.Kind.COLLECT_ITEM, TEST_COIN_ID, 2, false, [&"reach_forbidden_zone"]),
	]
	if enable_zone:
		manifest.encounters = [_make_encounter(TEST_ZONE_ID)]
	return manifest


func _make_objective(
	id: StringName,
	title: String,
	kind: ObjectiveDefinition.Kind,
	target_id: StringName,
	required_count: int,
	optional: bool,
	prerequisites: Array[StringName],
) -> ObjectiveDefinition:
	var definition := ObjectiveDefinition.new()
	definition.id = id
	definition.title = title
	definition.kind = kind
	definition.target_id = target_id
	definition.required_count = required_count
	definition.optional = optional
	definition.prerequisite_ids = prerequisites
	return definition


func _active_objective_ids() -> Array[StringName]:
	if runtime == null:
		return []
	var ids: Array[StringName] = []
	for objective in runtime.objectives.active_objectives():
		ids.append(objective.id)
	return ids


func _make_encounter(zone_id: StringName) -> EncounterDefinition:
	var encounter := EncounterDefinition.new()
	encounter.id = &"contract_encounter"
	encounter.zone_id = zone_id
	encounter.schema_version = 2
	encounter.maximum_simultaneous_attackers = 2
	encounter.waves = [
		{
			"delay_seconds": 0.0,
			"spawns": [
				{"scene": "tests://mission_runtime_contract_actor", "position": Vector3(0.0, 0.0, 0.0), "completion_marker": EncounterDefinition.BOSS_COMPLETION_MARKER},
				{"scene": "tests://mission_runtime_contract_actor", "position": Vector3(1.0, 0.0, 0.0)},
			],
		},
		{
			"delay_seconds": 0.0,
			"spawns": [
				{"scene": "tests://mission_runtime_contract_actor", "position": Vector3(2.0, 0.0, 0.0)},
			],
		},
	]
	encounter.completion_policy = EncounterDefinition.CompletionPolicy.BOSS_DEFEATED
	encounter.enemy_budget = 3
	return encounter


func _spawn_encounter_actor(_scene_path: String, position: Vector3) -> Node:
	var actor := ProbeEncounterActor.new()
	actor.position = position
	actor.add_to_group("mission_runtime_contract_actor")
	actor.name = "MissionRuntimeContractActor"
	root.add_child(actor)
	spawned_actors.append(actor)
	return actor


func _normalize_snapshot(data: Dictionary) -> Dictionary:
	var objective_data := data.get("objective_snapshot", {}) as Dictionary
	var normalized_objective_progress := {}
	for objective_id: Variant in objective_data.get("progress", {}):
		var objective_progress: Dictionary = objective_data.get("progress", {})
		normalized_objective_progress[String(objective_id)] = int(objective_progress[objective_id])
	var normalized_objective_completed: Array[String] = []
	for raw_id: Variant in objective_data.get("completed", []):
		normalized_objective_completed.append(String(raw_id))
	normalized_objective_completed.sort()

	var encounter_data := data.get("encounter_snapshot", {}) as Dictionary
	var normalized_encounter_completed: Array[String] = []
	for raw_id: Variant in encounter_data.get("completed", []):
		normalized_encounter_completed.append(String(raw_id))
	normalized_encounter_completed.sort()

	return {
		"objective_snapshot": {
			"progress": normalized_objective_progress,
			"completed": normalized_objective_completed,
		},
		"encounter_snapshot": {
			"completed": normalized_encounter_completed,
		},
	}


func _is_primitive_snapshot(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_NIL:
			return true
		TYPE_DICTIONARY:
			for key: Variant in value:
				if typeof(key) != TYPE_STRING and typeof(key) != TYPE_STRING_NAME:
					_fail("snapshot key %s is not primitive-string keyed" % str(key))
					return false
				if not _is_primitive_snapshot(value[key]):
					_fail("snapshot contains non-primitive payload at key %s" % String(key))
					return false
			return true
		TYPE_ARRAY:
			for index in range(value.size()):
				if not _is_primitive_snapshot(value[index]):
					_fail("snapshot contains non-primitive array value at index %d" % index)
					return false
			return true
		_:
			_fail("snapshot contains forbidden non-primitive type %s" % type_string(typeof(value)))
			return false
	return false


func _teardown_runtime() -> void:
	var lingering := get_nodes_in_group("mission_runtime_contract_actor")
	for actor in spawned_actors:
		if is_instance_valid(actor):
			actor.queue_free()
	spawned_actors.clear()
	if runtime != null and is_instance_valid(runtime):
		runtime.free()
		runtime = null
	await process_frame
	lingering = get_nodes_in_group("mission_runtime_contract_actor")
	_assert(lingering.is_empty(), "spawned encounter actors are returned to a quiescent state before cleanup")
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)
