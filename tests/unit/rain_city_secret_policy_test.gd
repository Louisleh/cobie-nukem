extends SceneTree

const HARBOUR_DEFINITION: Resource = preload("res://resources/encounters/vancouver_harbour_pier.tres")
const SECRET_POLICY = preload("res://scripts/level/rain_city_secret_policy.gd")
const TERMINAL_SECRET_REINFORCEMENT_ID := &"terminal_secret_cancelled_reinforcement"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_reduction_preserves_geometry_and_budget()
	_test_reduction_removes_tagged_reinforcement_any_slot()
	_test_reduction_rejects_invalid_tag_multiplicity()
	if failures.is_empty():
		print("RAIN CITY SECRET POLICY TEST: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_reduction_preserves_geometry_and_budget() -> void:
	var source := _load_definition()
	var source_before := source.duplicate(true)
	var reduced := SECRET_POLICY.reduced_harbour_definition(source)
	_assert(reduced != null, "valid reduction returns a reduced harbour definition")
	if reduced == null:
		return
	_assert(_total_spawns(source) == 8, "source starts with 8 actors")
	_assert(_total_spawns(reduced) == 7, "valid reduction removes one actor")
	_assert(source.enemy_budget == 8, "source budget remains at 8")
	_assert(reduced.enemy_budget == 7, "budget decrements by one")
	_assert(_contains_reduction_tag(source) == 1, "source has one tagged reinforcement")
	_assert(_contains_reduction_tag(reduced) == 0, "reduced definition has no tagged reinforcement")
	var tagged := _find_tagged_spawn(source)
	_assert(tagged != null, "tagged spawn can be identified")
	if tagged != null:
		_assert(not _spawn_exists(reduced, tagged[0], tagged[1]), "reduction removes the tagged spawn")
		var reduced_validation := reduced.validate()
		_assert(reduced_validation.is_empty(), "reduced definition validates")
		_assert(_total_spawns(source_before) - _total_spawns(reduced) == 1, "only one actor is removed")
		_assert(_definitions_match_geometry(source_before, source), "reduced_harbour_definition does not mutate source")


func _test_reduction_removes_tagged_reinforcement_any_slot() -> void:
	var base := _load_definition()
	var wave_count := (base.waves as Array).size()
	for wave_index in range(wave_count):
		var wave := (base.waves[wave_index] as Dictionary)
		var spawns := (wave.get("spawns", []) as Array)
		for spawn_index in range(spawns.size()):
			var tagged_source := _load_definition_with_tag_at(wave_index, spawn_index)
			var tagged_before := tagged_source.duplicate(true)
			var reduced := SECRET_POLICY.reduced_harbour_definition(tagged_source)
			_assert(reduced != null, "slot (%d, %d) with reinforcement reduces successfully" % [wave_index, spawn_index])
			if reduced == null:
				continue
			var reduced_definition := reduced
			_assert(_definitions_match_geometry(tagged_before, tagged_source), "slot (%d, %d) reduction does not mutate source" % [wave_index, spawn_index])
			_assert(_total_spawns(tagged_source) == 8, "slot (%d, %d) source actor count unchanged before reduction" % [wave_index, spawn_index])
			_assert(_total_spawns(reduced_definition) == 7, "slot (%d, %d) reduced definition actor count is 7" % [wave_index, spawn_index])
			_assert(reduced_definition.enemy_budget == tagged_source.enemy_budget - 1, "slot (%d, %d) budget decrements by one" % [wave_index, spawn_index])
			_assert(_contains_reduction_tag(reduced_definition) == 0, "slot (%d, %d) removes tagged spawn" % [wave_index, spawn_index])
			_assert(reduced_definition.validate().is_empty(), "slot (%d, %d) reduced definition validates" % [wave_index, spawn_index])


func _test_reduction_rejects_invalid_tag_multiplicity() -> void:
	var no_tag := _clear_all_reinforcement_tags(_load_definition())
	_assert(_contains_reduction_tag(no_tag) == 0, "test fixture has no tagged reinforcements")
	_assert(SECRET_POLICY.reduced_harbour_definition(no_tag) == null, "reduction fails when no reinforcement tag exists")

	var duplicated_tag := _clear_all_reinforcement_tags(_load_definition())
	_set_reinforcement_tag(duplicated_tag, 0, 0)
	_set_reinforcement_tag(duplicated_tag, 1, 1)
	_assert(_contains_reduction_tag(duplicated_tag) == 2, "test fixture has duplicate tagged reinforcements")
	_assert(SECRET_POLICY.reduced_harbour_definition(duplicated_tag) == null, "reduction fails when reinforcement tag duplicates")

	var malformed_source := _load_definition()
	malformed_source.id = &""
	_assert(SECRET_POLICY.reduced_harbour_definition(malformed_source) == null, "reduction fails when source validation fails")


func _load_definition() -> Resource:
	return HARBOUR_DEFINITION.duplicate(true)


func _load_definition_with_tag_at(wave_index: int, spawn_index: int) -> Resource:
	var definition := _clear_all_reinforcement_tags(_load_definition())
	_set_reinforcement_tag(definition, wave_index, spawn_index)
	return definition


func _set_reinforcement_tag(definition: Resource, wave_index: int, spawn_index: int) -> void:
	var waves := definition.waves as Array
	if wave_index < 0 or wave_index >= waves.size():
		return
	var wave := waves[wave_index] as Dictionary
	var spawns := (wave.get("spawns", []) as Array).duplicate(true)
	if spawn_index < 0 or spawn_index >= spawns.size():
		return
	var spawn := (spawns[spawn_index] as Dictionary).duplicate(true)
	spawn["optional_reinforcement_id"] = TERMINAL_SECRET_REINFORCEMENT_ID
	spawns[spawn_index] = spawn
	wave["spawns"] = spawns
	waves[wave_index] = wave
	definition.waves = waves


func _clear_all_reinforcement_tags(definition: Resource) -> Resource:
	var waves := definition.waves as Array
	for wave_index in range(waves.size()):
		var wave := waves[wave_index] as Dictionary
		var spawns := (wave.get("spawns", []) as Array).duplicate(true)
		for spawn_index in range(spawns.size()):
			var spawn := (spawns[spawn_index] as Dictionary).duplicate(true)
			spawn.erase("optional_reinforcement_id")
			spawns[spawn_index] = spawn
		wave["spawns"] = spawns
		waves[wave_index] = wave
	definition.waves = waves
	return definition


func _contains_reduction_tag(definition: Resource) -> int:
	var count := 0
	var waves := definition.waves as Array
	for wave_index in range(waves.size()):
		var wave := waves[wave_index] as Dictionary
		var spawns := (wave.get("spawns", []) as Array)
		for spawn_index in range(spawns.size()):
			if spawns[spawn_index] is not Dictionary:
				continue
			var spawn := spawns[spawn_index] as Dictionary
			if spawn is not Dictionary:
				continue
			if StringName((spawn as Dictionary).get("optional_reinforcement_id", &"")) == TERMINAL_SECRET_REINFORCEMENT_ID:
				count += 1
	return count


func _find_tagged_spawn(definition: Resource) -> Array:
	var waves := definition.waves as Array
	for wave_index in range(waves.size()):
		var wave := waves[wave_index] as Dictionary
		var spawns := (wave.get("spawns", []) as Array)
		for spawn_index in range(spawns.size()):
			if spawns[spawn_index] is not Dictionary:
				continue
			var spawn_dict := (spawns[spawn_index] as Dictionary)
			if StringName(spawn_dict.get("optional_reinforcement_id", &"")) == TERMINAL_SECRET_REINFORCEMENT_ID:
				return [StringName(spawn_dict.get("scene", "")), spawn_dict.get("position", Vector3.ZERO)]
	return []


func _spawn_exists(definition: Resource, scene: StringName, position: Vector3) -> bool:
	var waves := definition.waves as Array
	for wave_index in range(waves.size()):
		var wave := waves[wave_index] as Dictionary
		var spawns := (wave.get("spawns", []) as Array)
		for spawn_index in range(spawns.size()):
			if spawns[spawn_index] is not Dictionary:
				continue
			var spawn_dict := spawns[spawn_index] as Dictionary
			if StringName(spawn_dict.get("scene", "")) == scene and (spawn_dict.get("position", Vector3.ZERO) == position):
				return true
	return false


func _total_spawns(definition: Resource) -> int:
	var count := 0
	var waves := definition.waves as Array
	for wave in waves:
		var spawns := wave.get("spawns", []) as Array
		count += spawns.size()
	return count


func _definitions_match_geometry(left: Resource, right: Resource) -> bool:
	var left_waves := left.waves as Array
	var right_waves := right.waves as Array
	if left_waves.size() != right_waves.size():
		return false
	for wave_index in range(left_waves.size()):
		var left_wave := left_waves[wave_index] as Dictionary
		var right_wave := right_waves[wave_index] as Dictionary
		if left_wave.get("delay_seconds", 0.0) != right_wave.get("delay_seconds", 0.0):
			return false
		var left_spawns := (left_wave.get("spawns", []) as Array)
		var right_spawns := (right_wave.get("spawns", []) as Array)
		if left_spawns.size() != right_spawns.size():
			return false
		for spawn_index in range(left_spawns.size()):
			if left_spawns[spawn_index] != right_spawns[spawn_index]:
				return false
	return true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
