extends SceneTree

class ProbeEncounterActor extends Node3D:
	signal died(actor: Node, source: Node)

	var encounter_role_id: StringName
	var encounter_approach_id: StringName
	var encounter_transition_id: StringName


var failures: Array[String] = []
var runner: EncounterRunner
var spawned: Array[ProbeEncounterActor] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_profile_validation()
	_test_definition_schema_compatibility_and_requirements()
	await _test_runner_context_and_restore()
	if failures.is_empty():
		print("ENCOUNTER CHOREOGRAPHY PROFILE TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_profile_validation() -> void:
	var profile := _make_profile(&"valid_profile", 2)
	_assert(profile.validate(2).is_empty(), "valid profile passes validation for wave count")

	var valid_context := profile.context_for_wave(0)
	var repeated_context := profile.context_for_wave(0)
	_assert(_contexts_match(valid_context, repeated_context), "profile context lookup is deterministic for repeated lookup")

	var duplicated_context := profile.context_for_wave(2)
	var base_context := profile.context_for_wave(0)
	_assert(duplicated_context.get("encounter_transition_id") == base_context.get("encounter_transition_id"), "context for overflowed wave indexes is duplicated deterministically")

	var invalid_profile := EncounterChoreographyProfile.new()
	invalid_profile.id = &"invalid_profile"
	invalid_profile.intent = ""
	invalid_profile.role_ids = [&"alpha", &"alpha", &""]
	invalid_profile.approach_ids = [&"left", &""]
	invalid_profile.recovery_position = Vector3(1.0 / 0.0, 0.0, 0.0)
	invalid_profile.environment_choice_ids = []
	invalid_profile.wave_transition_ids = [&"enter"]
	invalid_profile.counterplay_ids = []
	var errors := invalid_profile.validate(2)
	_assert(not errors.is_empty(), "invalid profile rejects malformed profile metadata")
	_assert(_contains_error(errors, "fewer than three unique nonempty roles"), "invalid profile rejects insufficient unique roles")
	_assert(_contains_error(errors, "fewer than two unique nonempty approaches"), "invalid profile rejects insufficient unique approaches")
	_assert(_contains_error(errors, "invalid non-finite recovery_position"), "invalid profile rejects non-finite recovery_position")
	_assert(_contains_error(errors, "no nonempty environment_choice_ids"), "invalid profile rejects empty environment choices")
	_assert(_contains_error(errors, "no nonempty counterplay_ids"), "invalid profile rejects empty counterplay ids")
	invalid_profile.wave_transition_ids = [&"", &"phase_shift"]
	_assert(_contains_error(invalid_profile.validate(2), "empty wave transition id"), "invalid profile rejects empty wave transition ids")


func _test_definition_schema_compatibility_and_requirements() -> void:
	var legacy := EncounterDefinition.new()
	legacy.id = &"legacy_definition"
	legacy.zone_id = &"legacy_zone"
	legacy.schema_version = 2
	legacy.spawns = [{"scene": "res://scenes/enemies/squirrel_trooper.tscn", "position": Vector3.ZERO}]
	_assert(legacy.validate().is_empty(), "schema v2 definitions still validate with legacy spawns and no choreography profile")

	var profile := _make_profile(&"modern_profile", 2)
	var modern := _make_schema_definition(profile, &"modern_zone", "res://scenes/enemies/squirrel_trooper.tscn")
	_assert(modern.validate().is_empty(), "schema v3 definition validates with complete choreography profile and usage")

	var missing_profile := _make_schema_definition(profile, &"missing_profile_zone", "res://scenes/enemies/squirrel_trooper.tscn")
	missing_profile.choreography_profile = null
	_assert(not missing_profile.validate().is_empty(), "schema v3 requires a non-null choreography profile")
	(missing_profile.waves[0].get("spawns", [])[0] as Dictionary).erase("role_id")
	_assert(_contains_error(missing_profile.validate(), "missing or invalid role_id"), "schema v3 still validates spawn role ids when the profile is missing")

	var unsupported_schema := _make_schema_definition(profile, &"unsupported_schema_zone", "res://scenes/enemies/squirrel_trooper.tscn")
	unsupported_schema.schema_version = 4
	_assert(_contains_error(unsupported_schema.validate(), "unsupported schema_version 4"), "unknown future schema versions fail closed")

	var undeclared_role := _make_schema_definition(profile, &"undeclared_role_zone", "res://scenes/enemies/squirrel_trooper.tscn")
	(undeclared_role.waves[0].get("spawns", [])[0] as Dictionary)["role_id"] = &"rogue"
	_assert(not undeclared_role.validate().is_empty(), "schema v3 rejects role_id not listed on the profile")

	var missing_role_usage := _make_schema_definition(profile, &"missing_role_usage_zone", "res://scenes/enemies/squirrel_trooper.tscn")
	# Keep all spawns within the profile but omit one declared role intentionally.
	(missing_role_usage.waves[0].get("spawns", [])[0] as Dictionary)["role_id"] = profile.role_ids[0]
	(missing_role_usage.waves[0].get("spawns", [])[1] as Dictionary)["role_id"] = profile.role_ids[0]
	(missing_role_usage.waves[1].get("spawns", [])[0] as Dictionary)["role_id"] = profile.role_ids[1]
	_assert(not missing_role_usage.validate().is_empty(), "schema v3 requires all declared roles to be used by at least one spawn")


func _test_runner_context_and_restore() -> void:
	var profile := _make_profile(&"runner_profile", 2)
	var definition := _make_schema_definition(profile, &"runner_zone", "res://tests/unit/missing")
	runner = _build_runner(definition)
	var wave0_context := profile.context_for_wave(0)
	var wave1_context := profile.context_for_wave(1)

	var wave0_actors := runner.activate_zone(&"runner_zone")
	_assert(wave0_actors.size() == 2, "runner activates schema v3 wave and tags actors with wave 0 choreography context")
	_expect_actor_metadata(wave0_actors[0], profile.role_ids[0], profile.approach_ids[0], wave0_context)
	_expect_actor_metadata(wave0_actors[1], profile.role_ids[1], profile.approach_ids[1], wave0_context)

	(wave0_actors[0] as ProbeEncounterActor).died.emit(wave0_actors[0], runner)
	(wave0_actors[1] as ProbeEncounterActor).died.emit(wave0_actors[1], runner)
	await process_frame
	var active_wave_one := runner.active.get(&"runner_zone", {}).get("actors", []) as Array
	_assert(active_wave_one.size() == 1, "runner advances schema v3 waves and updates choreography context")
	_expect_actor_metadata(active_wave_one[0], profile.role_ids[2], profile.approach_ids[0], wave1_context)

	_assert(runner.reset_zone(&"runner_zone"), "runner reset clears active encounter")
	var reset_wave := runner.activate_zone(&"runner_zone")
	_assert(reset_wave.size() == 2, "runner reset allows wave0 reactivation")
	_expect_actor_metadata(reset_wave[0], profile.role_ids[0], profile.approach_ids[0], wave0_context)

	# Restore should re-derive context from the restored wave index, not persist it.
	(reset_wave[0] as ProbeEncounterActor).died.emit(reset_wave[0], runner)
	(reset_wave[1] as ProbeEncounterActor).died.emit(reset_wave[1], runner)
	await process_frame
	var restored_snapshot := runner.snapshot()
	_assert(int(restored_snapshot.get("active", {}).get(&"runner_zone", {}).get("wave", -1)) == 1, "snapshot records the restored wave index for active encounters")
	_assert(runner.reset_zone(&"runner_zone"), "runner supports deterministic restore replay reset")
	runner.restore(restored_snapshot)
	var restored_wave := runner.activate_zone(&"runner_zone")
	await process_frame
	_assert(restored_wave.size() == 1, "restore respawns the same active wave index")
	_expect_actor_metadata(restored_wave[0], profile.role_ids[2], profile.approach_ids[0], wave1_context)
	_cleanup()


func _build_runner(definition: EncounterDefinition) -> EncounterRunner:
	var new_runner := EncounterRunner.new()
	runner = new_runner
	get_root().add_child(new_runner)
	new_runner.configure([definition], Callable(self, "_spawn_encounter_actor"))
	return new_runner


func _make_profile(profile_id: StringName, wave_count: int) -> EncounterChoreographyProfile:
	var profile := EncounterChoreographyProfile.new()
	profile.id = profile_id
	profile.intent = "test encounter intent"
	profile.role_ids = [&"alpha", &"bravo", &"charlie"]
	profile.approach_ids = [&"left", &"right"]
	profile.recovery_position = Vector3(2.5, 3.75, -1.25)
	profile.environment_choice_ids = [&"open", &"covered"]
	profile.counterplay_ids = [&"smoke", &"flank"]
	profile.wave_transition_ids = [&"phase_enter", &"phase_shift"]
	profile.wave_transition_ids.resize(wave_count)
	if profile.wave_transition_ids.size() < wave_count:
		for index in range(profile.wave_transition_ids.size(), wave_count):
			profile.wave_transition_ids.append(&"phase_%d" % index)
	return profile


func _make_schema_definition(profile: EncounterChoreographyProfile, zone_id: StringName, scene_path: String) -> EncounterDefinition:
	var definition := EncounterDefinition.new()
	definition.id = StringName("%s_definition" % zone_id)
	definition.zone_id = zone_id
	definition.schema_version = 3
	definition.choreography_profile = profile
	definition.maximum_simultaneous_attackers = 1
	definition.waves = [
		{"spawns": [
			{"scene": scene_path, "position": Vector3.ZERO, "role_id": profile.role_ids[0], "approach_id": profile.approach_ids[0]},
			{"scene": scene_path, "position": Vector3(1.0, 0.0, 0.0), "role_id": profile.role_ids[1], "approach_id": profile.approach_ids[1]},
		]},
		{"spawns": [
			{"scene": scene_path, "position": Vector3(2.0, 0.0, 0.0), "role_id": profile.role_ids[2], "approach_id": profile.approach_ids[0]},
		]},
	]
	definition.enemy_budget = 3
	return definition


func _spawn_encounter_actor(_scene_path: String, position: Vector3) -> Node:
	var actor := ProbeEncounterActor.new()
	actor.position = position
	get_root().add_child(actor)
	spawned.append(actor)
	return actor


func _expect_actor_metadata(actor: Node, role_id: StringName, approach_id: StringName, context: Dictionary) -> void:
	if actor is not ProbeEncounterActor:
		_assert(false, "spawned encounter actor uses ProbeEncounterActor contract")
		return
	var encountered := actor as ProbeEncounterActor
	encountered.encounter_role_id = actor.get_meta(&"encounter_role_id", &"")
	encountered.encounter_approach_id = actor.get_meta(&"encounter_approach_id", &"")
	encountered.encounter_transition_id = actor.get_meta(&"encounter_transition_id", &"")
	_assert(encountered.encounter_role_id == role_id, "actor metadata includes encounter_role_id %s" % role_id)
	_assert(encountered.encounter_approach_id == approach_id, "actor metadata includes encounter_approach_id %s" % approach_id)
	_assert(encountered.encounter_transition_id == context.get("encounter_transition_id"), "actor metadata includes encounter_transition_id")
	_assert(actor.get_meta(&"encounter_recovery_position", Vector3.ZERO) == context.get("encounter_recovery_position"), "actor metadata includes encounter_recovery_position")
	var environment_choices: Array = actor.get_meta(&"encounter_environment_choice_ids", [])
	_assert(environment_choices == context.get("encounter_environment_choice_ids", []), "actor metadata includes encounter_environment_choice_ids")
	var counterplay_ids: Array = actor.get_meta(&"encounter_counterplay_ids", [])
	_assert(counterplay_ids == context.get("encounter_counterplay_ids", []), "actor metadata includes encounter_counterplay_ids")
	_assert(actor.get_meta(&"encounter_counterplay_id", &"") == context.get("encounter_counterplay_id", &""), "actor metadata includes encounter_counterplay_id")


func _contains_error(errors: PackedStringArray, needle: String) -> bool:
	for error in errors:
		if String(error).find(needle) >= 0:
			return true
	return false


func _contexts_match(left: Dictionary, right: Dictionary) -> bool:
	return left.get("encounter_role_id") == right.get("encounter_role_id") \
		and left.get("encounter_approach_id") == right.get("encounter_approach_id") \
		and left.get("encounter_transition_id") == right.get("encounter_transition_id") \
		and left.get("encounter_recovery_position") == right.get("encounter_recovery_position") \
		and left.get("encounter_environment_choice_ids") == right.get("encounter_environment_choice_ids") \
		and left.get("encounter_counterplay_id") == right.get("encounter_counterplay_id")


func _cleanup() -> void:
	if runner != null and is_instance_valid(runner):
		runner.queue_free()
	runner = null
	for actor in spawned:
		if is_instance_valid(actor):
			actor.queue_free()
	spawned.clear()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
