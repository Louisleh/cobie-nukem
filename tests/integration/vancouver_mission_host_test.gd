extends SceneTree

const MissionScene := preload("res://scenes/levels/episode_1_vancouver_waterfront.tscn")
const EXPECTED_ZONES: Array[StringName] = [
	&"downtown_alley",
	&"ruse_block",
	&"waterfront_seawall",
	&"terminal_service",
	&"harbour_pier",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.spawn_player = false
	mission.start_run_automatically = false
	mission.setup_presentation = false
	root.add_child(mission)
	await process_frame
	_expect(mission.content_manifest.validate().is_empty(), "production manifest validates")
	_expect(mission._world_builder != null, "mission owns a world builder")
	_expect(mission._mission_runtime != null, "mission owns shared MissionRuntime")
	_expect(mission._route_runtime != null, "mission owns shared MissionRouteRuntime")
	_expect(mission._spawn_registry != null, "mission owns shared MissionSpawnRegistry")
	_expect(mission._world_builder.geometry.get_child_count() >= 30, "five-zone world contains authored environment and landmarks")
	_expect(mission._world_builder.navigation_region != null, "world owns production navigation region")

	var route := mission.content_manifest.route_definition
	for zone_id in EXPECTED_ZONES:
		var zone := route.zone_for_id(zone_id)
		_expect(zone != null, "route zone %s resolves" % zone_id)
		if zone == null:
			continue
		var center := zone.bounds.get_center()
		center.y = 1.0
		mission._submit_route_position(center)
		_expect(mission.current_zone == zone_id, "mission progresses into %s" % zone_id)
		if zone_id != &"harbour_pier":
			_expect(mission._mission_runtime.encounters.active.has(zone_id), "route zone %s activates only its current encounter" % zone_id)

	_expect(mission._mission_runtime.encounters.active.size() <= 1, "advancing the route clears abandoned prior-zone encounters")
	_expect(not mission._mission_runtime.encounters.active.has(&"harbour_pier"), "convoy encounter waits for set-piece coordination")
	_expect(mission._route_runtime.current_checkpoint_id == &"checkpoint_harbour_pier", "route exposes ordered harbour checkpoint")
	_expect(mission._world_builder.terminal_switch != null, "terminal objective switch exists")
	_expect(mission._world_builder.departure_switch != null, "harbour departure switch exists")
	mission._world_builder.departure_switch.interact(null)
	_expect(not mission._world_builder.departure_switch.is_active, "departure switch cannot be consumed before convoy completion")
	_expect(not mission._mission_runtime.objectives.completed.has(&"complete_harbour_pier"), "early departure interaction cannot bypass prerequisites")
	mission._mission_runtime.record_objective(ObjectiveDefinition.Kind.ACTIVATE, &"terminal_power")
	_expect(mission._mission_runtime.objectives.completed.has(&"restore_terminal"), "terminal objective completes before convoy")
	await _exercise_convoy(mission)
	_expect(mission._mission_runtime.objectives.completed.has(&"stop_citation_convoy"), "convoy completion satisfies objective exactly once")
	_expect(mission._route_runtime.current_checkpoint_id == &"checkpoint_harbour_clear", "convoy completion promotes the clear checkpoint")
	mission._world_builder.departure_switch.interact(null)
	_expect(mission._world_builder.departure_switch.is_active, "departure switch unlocks after convoy completion")
	_expect(mission._mission_runtime.objectives.completed.has(&"complete_harbour_pier"), "harbour departure completes the mission chain")

	mission.queue_free()
	await process_frame
	await _test_opening_safety_window()
	await _test_harbour_checkpoint_rehydration()
	if failures.is_empty():
		print("VANCOUVER MISSION HOST TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_harbour_checkpoint_rehydration() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.spawn_player = false
	mission.start_run_automatically = false
	mission.setup_presentation = false
	mission._restored_checkpoint = {
		"objective_snapshot": {
			"progress": {"reach_waterfront": 1, "restore_terminal": 1},
			"completed": ["reach_waterfront", "restore_terminal"],
		},
		"encounter_snapshot": {"completed": [], "active": {}},
		"route_snapshot": {
			"route_id": "vancouver_mission2_route",
			"current_zone": "harbour_pier",
			"current_index": 4,
			"visited_zones": ["downtown_alley", "ruse_block", "waterfront_seawall", "terminal_service", "harbour_pier"],
			"checkpoint_id": "checkpoint_harbour_pier",
			"is_completed": true,
		},
		"secrets": {},
	}
	root.add_child(mission)
	await process_frame
	_expect(mission.current_zone == &"harbour_pier", "harbour Continue restores controller zone truth")
	_expect(mission._set_piece_runtime != null and bool(mission._set_piece_runtime.current_state().get("has_actor", false)), "harbour Continue rehydrates the citation convoy")
	_expect(not mission._world_builder.departure_switch.enabled, "restored departure remains locked until convoy objective completes")
	mission.queue_free()
	await process_frame


func _test_opening_safety_window() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.start_run_automatically = false
	mission.setup_presentation = false
	root.add_child(mission)
	await process_frame
	var player := mission.player as CobiePlayer
	_expect(player != null, "public Vancouver beta spawns its player")
	if player != null:
		_expect(player.health_armor.invulnerable_remaining >= mission.opening_protection_seconds - 0.1, "public beta grants time to establish pointer or touch control before opening damage")
	mission.queue_free()
	await process_frame


func _exercise_convoy(mission: EpisodeOneVancouverWaterfront) -> void:
	_expect(mission._set_piece_runtime != null, "convoy runtime exists")
	_expect(mission._convoy_coordinator != null, "convoy coordinator exists")
	if mission._set_piece_runtime == null or mission._convoy_coordinator == null:
		return
	var convoy := _find_convoy(mission._world_builder.actors)
	_expect(convoy != null, "convoy actor remains available through all boss phases")
	if convoy == null:
		return
	var module_ids: Array[StringName] = [&"citation_drive_left", &"citation_signal_dish", &"citation_drive_right", &"citation_core"]
	for wave_index in 4:
		mission._set_piece_runtime._physics_process(100.0)
		var coordinator_state := mission._convoy_coordinator.current_state()
		_expect(int(coordinator_state.get("active_wave_index", -1)) == wave_index, "convoy stop %d starts wave %d" % [wave_index, wave_index])
		if wave_index > 0:
			_flush_pending_wave_timer(mission, wave_index)
		_defeat_active_wave(mission, wave_index)
		await process_frame
		_expect(bool(mission._convoy_coordinator.current_state().waves_completed[wave_index]), "convoy wave %d completes" % wave_index)
		var module := _find_convoy_module(convoy, module_ids[wave_index])
		_expect(module != null and module.visible, "convoy phase %d exposes only its authored module" % wave_index)
		if module != null:
			module.apply_damage(9999.0)
		await process_frame
		_expect(convoy.destroyed_module_count() == wave_index + 1, "convoy phase %d records one module destruction" % wave_index)
	mission._set_piece_runtime._physics_process(100.0)
	await process_frame
	var final_state := mission._set_piece_runtime.current_state()
	_expect(bool(final_state.get("path_completed", false)), "convoy reaches the authored path end")
	_expect(bool(final_state.get("completion_emitted", false)), "convoy emits completion after waves and modules")
	_expect(not mission._mission_runtime.encounters.active.has(&"harbour_pier"), "convoy encounter leaves no active harbour actors")


func _flush_pending_wave_timer(mission: EpisodeOneVancouverWaterfront, wave_index: int) -> void:
	var state := mission._mission_runtime.encounters.active.get(&"harbour_pier", {}) as Dictionary
	var timer := state.get("timer") as Timer
	_expect(timer != null, "convoy wave %d owns its bounded delay timer" % wave_index)
	if timer != null:
		timer.timeout.emit()


func _defeat_active_wave(mission: EpisodeOneVancouverWaterfront, wave_index: int) -> void:
	var state := mission._mission_runtime.encounters.active.get(&"harbour_pier", {}) as Dictionary
	var actors: Array = state.get("actors", []).duplicate()
	_expect(not actors.is_empty(), "convoy wave %d spawns combatants" % wave_index)
	for actor in actors:
		var enemy := actor as EnemyAgent
		_expect(enemy != null, "convoy wave %d actor uses EnemyAgent contract" % wave_index)
		if enemy != null:
			enemy.apply_damage(99999.0)


func _find_convoy(parent: Node) -> CitationConvoyActor:
	for child in parent.get_children():
		if child is CitationConvoyActor:
			return child as CitationConvoyActor
	return null


func _find_convoy_module(convoy: CitationConvoyActor, module_id: StringName) -> WorldInteraction:
	for child in convoy.get_children():
		var module := child as WorldInteraction
		if module != null and module.definition != null and module.definition.id == module_id:
			return module
	return null


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
