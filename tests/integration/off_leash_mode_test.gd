extends SceneTree

const LEVEL_SCENE := preload("res://scenes/levels/episode_1_level_1.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node("GameState")
	game_state.request_run_mode("off_leash")
	game_state.begin_run(&"episode_1_level_1")
	var level := LEVEL_SCENE.instantiate() as EpisodeOneLevel
	level.spawn_player = false
	level.setup_presentation = false
	root.add_child(level)
	await process_frame
	await process_frame
	_expect(String(game_state.run_stats.get("run_mode", "")) == "off_leash", "scene handoff preserves requested remix mode")
	var expected_counts := {
		&"forbidden_field": 4,
		&"equipment_shed": 4,
		&"maintenance_tunnels": 6,
		&"compliance_lab": 6,
	}
	for zone_id in expected_counts:
		var definition := level._encounter_runner.definitions.get(zone_id) as EncounterDefinition
		_expect(definition != null, "%s remix definition exists" % zone_id)
		if definition != null:
			_expect(_spawn_count(definition) == expected_counts[zone_id], "%s receives exactly one remix reinforcement" % zone_id)
			_expect(definition.validate().is_empty(), "%s remix remains valid encounter data" % zone_id)
	var source_manifest := load("res://resources/content/salmon_creek_manifest.tres") as ContentManifest
	_expect(_spawn_count(source_manifest.encounters[0]) == 3, "remix never mutates the shared Salmon Creek resources")
	level.queue_free()
	await process_frame
	game_state.request_run_mode("standard")
	game_state._set_phase(game_state.Phase.MENU)
	if failures.is_empty():
		print("OFF-LEASH MODE TEST: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _spawn_count(definition: EncounterDefinition) -> int:
	var total := 0
	for wave in definition.effective_waves(): total += (wave.get("spawns", []) as Array).size()
	return total


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
