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
	mission.build_navigation = false
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
	var navigation_status := mission._world_builder.navigation_bake_status()
	_expect(not bool(navigation_status.get("requested", true)), "mission-host test explicitly disables production navigation baking")
	_expect(not bool(navigation_status.get("started", true)), "mission-host test does not schedule a deferred navigation bake")

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
			_expect(mission._mission_runtime.encounters.active.has(zone_id), "route zone %s activates its current encounter" % zone_id)
			_expect(not mission._world_builder.is_route_gate_open(zone_id), "route zone %s remains gated while enemies are active" % zone_id)
			await _defeat_zone_encounter(mission, zone_id)
			_expect(mission._mission_runtime.encounters.completed.has(zone_id), "route zone %s completes every authored wave" % zone_id)
			_expect(mission._world_builder.is_route_gate_open(zone_id), "route zone %s opens only after encounter completion" % zone_id)
			if zone_id == &"downtown_alley":
				mission.restart_from_checkpoint()
				_expect(mission._mission_runtime.encounters.active.has(zone_id), "checkpoint retry reactivates the last combat encounter")
				_expect(not mission._world_builder.is_route_gate_open(zone_id), "checkpoint retry re-closes the encounter gate")
				await _defeat_zone_encounter(mission, zone_id)
				_expect(mission._world_builder.is_route_gate_open(zone_id), "replayed encounter reopens its gate only after second completion")

	_expect(mission._mission_runtime.encounters.active.size() <= 1, "completed route encounters leave no abandoned active actors")
	_expect(not mission._mission_runtime.encounters.active.has(&"harbour_pier"), "convoy encounter waits for set-piece coordination")
	_expect(mission._route_runtime.current_checkpoint_id == &"checkpoint_harbour_pier", "route exposes ordered harbour checkpoint")
	_expect(mission._world_builder.terminal_switch != null, "terminal objective switch exists")
	_expect(mission._world_builder.departure_switch != null, "harbour departure switch exists")
	mission._world_builder.departure_switch.interact(null)
	_expect(not mission._world_builder.departure_switch.is_active, "departure switch cannot be consumed before convoy completion")
	_expect(not mission._mission_runtime.objectives.completed.has(&"complete_harbour_pier"), "early departure interaction cannot bypass prerequisites")
	_expect(not mission._world_builder.is_route_gate_open(&"rainline_return"), "Rain Line return remains closed before terminal power")
	mission._mission_runtime.record_objective(ObjectiveDefinition.Kind.ACTIVATE, &"terminal_power")
	_expect(mission._mission_runtime.objectives.completed.has(&"restore_terminal"), "terminal objective completes before convoy")
	_expect(mission._world_builder.is_route_gate_open(&"rainline_return"), "terminal objective opens the Rain Line return")
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
	await _test_completed_checkpoint_rehydrates_wreck()
	await _test_restored_terminal_secret_keeps_interactions()
	await _test_stale_route_snapshot_fallback()
	if failures.is_empty():
		print("VANCOUVER MISSION HOST TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_harbour_checkpoint_rehydration() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.build_navigation = false
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
	var restored_convoy := _find_convoy(mission._world_builder.actors)
	_expect(restored_convoy != null and not restored_convoy.is_combat_enabled(), "harbour Continue keeps combat disabled while the convoy restarts its path")
	_expect(not mission._world_builder.departure_switch.enabled, "restored departure remains locked until convoy objective completes")
	_expect(mission._world_builder.is_route_gate_open(&"rainline_return"), "restored terminal objective reopens the Rain Line return")
	mission.queue_free()
	await process_frame


func _test_completed_checkpoint_rehydrates_wreck() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.build_navigation = false
	mission.spawn_player = false
	mission.start_run_automatically = false
	mission.setup_presentation = false
	mission._restored_checkpoint = {
		"objective_snapshot": {
			"progress": {"reach_waterfront": 1, "restore_terminal": 1, "stop_citation_convoy": 1},
			"completed": ["reach_waterfront", "restore_terminal", "stop_citation_convoy"],
		},
		"encounter_snapshot": {"completed": ["harbour_pier"]},
		"route_snapshot": {
			"route_id": "vancouver_mission2_route",
			"current_zone": "harbour_pier",
			"current_index": 4,
			"visited_zones": ["downtown_alley", "ruse_block", "waterfront_seawall", "terminal_service", "harbour_pier"],
			"checkpoint_id": "checkpoint_harbour_clear",
			"is_completed": true,
		},
		"secrets": {},
	}
	root.add_child(mission)
	await process_frame
	var state := mission._set_piece_runtime.current_state()
	_expect(bool(state.get("completion_emitted", false)), "Completed Continue restores terminal convoy state without replaying the boss")
	_expect(is_equal_approx(float(state.get("current_boss_health", -1.0)), 0.0), "Completed Continue restores zero boss health")
	var wreck := _find_convoy(mission._world_builder.actors)
	_expect(wreck != null and wreck.defeat_started(), "Completed Continue restores the persistent defeated wreck")
	_expect(mission._world_builder.departure_switch.enabled, "Completed Continue keeps departure control enabled")
	_expect(mission._world_builder.is_route_gate_open(&"rainline_return"), "completed Continue preserves the Rain Line return")
	var generation := mission._set_piece_runtime.generation()
	mission.restart_from_checkpoint()
	_expect(mission._set_piece_runtime.generation() == generation, "Post-victory retry never resets or resurrects the convoy")
	_expect(bool(mission._set_piece_runtime.current_state().get("completion_emitted", false)), "Post-victory retry preserves terminal convoy state")
	mission.queue_free()
	await process_frame


func _test_restored_terminal_secret_keeps_interactions() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.build_navigation = false
	mission.spawn_player = false
	mission.start_run_automatically = false
	mission.setup_presentation = false
	mission._restored_checkpoint = {
		"checkpoint_id": "checkpoint_terminal_service",
		"objective_snapshot": {"progress": {}, "completed": []},
		"encounter_snapshot": {"completed": [], "active": {}},
		"route_snapshot": {
			"route_id": "vancouver_mission2_route",
			"current_zone": "terminal_service",
			"current_index": 3,
			"visited_zones": ["downtown_alley", "ruse_block", "waterfront_seawall", "terminal_service"],
			"checkpoint_id": "checkpoint_terminal_service",
			"is_completed": false,
		},
		"secrets": {"secret_terminal_service": "DOCK LEAK MODE OFF"},
	}
	root.add_child(mission)
	await process_frame
	_expect(mission._interaction_runtime != null, "restored terminal secret keeps the mission interaction runtime active")
	if mission._interaction_runtime != null:
		_expect(mission._interaction_runtime.interaction_count() == mission.content_manifest.interaction_catalog.placements.size(), "restored terminal secret preserves every authored interaction")
	_expect(mission._terminal_reinforcement_disabled, "restored terminal secret reapplies only its finale reinforcement reward")
	mission.queue_free()
	await process_frame


func _test_stale_route_snapshot_fallback() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.build_navigation = false
	mission.spawn_player = false
	mission.start_run_automatically = false
	mission.setup_presentation = false
	mission._restored_checkpoint = {
		"checkpoint_id": "checkpoint_terminal_service",
		"objective_snapshot": {"progress": {}, "completed": []},
		"encounter_snapshot": {"completed": [], "active": {}},
		"route_snapshot": {
			"route_id": "obsolete_vancouver_beta_route",
			"current_zone": "obsolete_terminal",
			"current_index": 3,
			"visited_zones": ["obsolete_terminal"],
			"checkpoint_id": "checkpoint_terminal_service",
			"is_completed": false,
		},
		"secrets": {},
	}
	root.add_child(mission)
	await process_frame
	_expect(mission.current_zone == &"terminal_service", "stale route snapshot falls back to the authoritative checkpoint zone")
	_expect(mission._route_runtime.current_checkpoint_id == &"checkpoint_terminal_service", "fallback keeps the authoritative checkpoint id")
	_expect(mission._route_runtime.visited_zones == [&"downtown_alley", &"ruse_block", &"waterfront_seawall", &"terminal_service"], "fallback reconstructs authored route order")
	mission.queue_free()
	await process_frame


func _test_opening_safety_window() -> void:
	var mission := MissionScene.instantiate() as EpisodeOneVancouverWaterfront
	mission.build_navigation = false
	mission.start_run_automatically = false
	mission.setup_presentation = false
	root.add_child(mission)
	await process_frame
	var player := mission.player as CobiePlayer
	_expect(player != null, "public Vancouver beta spawns its player")
	if player != null:
		_expect(player.health_armor.invulnerable_remaining >= mission.opening_protection_seconds - 0.1, "public beta grants time to establish pointer or touch control before opening damage")
		player.health_armor.armor = 0.0
		mission._on_secret_requested(&"secret_downtown_alley", "SIREN ROUTE DISABLED", null)
		_expect(player.health_armor.armor >= 40.0, "downtown secret awards the authored armor cache")
		player.health_armor.health = 20.0
		mission._on_secret_requested(&"secret_ruse_block", "NOISE BARGE SILENCED", null)
		_expect(is_equal_approx(player.health_armor.health, player.health_armor.max_health), "Rain City Slice secret restores full health")
		var fetch_weapon: WeaponBase
		for weapon in player.weapons:
			if weapon.definition != null and weapon.definition.ammo_type == "tennis_balls":
				fetch_weapon = weapon
				break
		_expect(fetch_weapon != null, "Vancouver loadout contains Fetch Launcher for secret reward")
		if fetch_weapon != null:
			fetch_weapon.reserve_ammo = 0
			mission._on_secret_requested(&"secret_waterfront_seawall", "DOCK SECURITY LOOP CLOSED", null)
			_expect(fetch_weapon.reserve_ammo == 6, "waterfront secret grants six Fetch balls")
			var save_manager := mission.get_node_or_null("/root/SaveManager")
			var saved_checkpoint: Dictionary = save_manager.load_slot(&"checkpoint") if save_manager != null else {}
			var saved_loadout: Dictionary = saved_checkpoint.get("active_mission_upgrades", {})
			var saved_ammo: Dictionary = saved_loadout.get("weapon_ammo", {})
			var fetch_id := String(fetch_weapon.definition.id)
			_expect(int((saved_ammo.get(fetch_id, {}) as Dictionary).get("reserve", -1)) == 6, "waterfront secret checkpoint captures the rewarded Fetch reserve")
			var saved_player_state: Dictionary = saved_checkpoint.get("player_state", {})
			_expect(float(saved_player_state.get("armor", -1.0)) >= 65.0, "waterfront secret checkpoint captures accumulated secret armor")
		var harbour_definition := mission._mission_runtime.encounters.definitions.get(&"harbour_pier") as EncounterDefinition
		var reinforcement_before: int = (harbour_definition.effective_waves()[1].get("spawns", []) as Array).size()
		mission._on_secret_requested(&"secret_terminal_service", "DOCK LEAK MODE OFF", null)
		harbour_definition = mission._mission_runtime.encounters.definitions.get(&"harbour_pier") as EncounterDefinition
		var reinforcement_after: int = (harbour_definition.effective_waves()[1].get("spawns", []) as Array).size()
		_expect(reinforcement_after == reinforcement_before - 1, "terminal secret removes one finale reinforcement")
		mission._on_secret_requested(&"secret_terminal_service", "DOCK LEAK MODE OFF", null)
		_expect((harbour_definition.effective_waves()[1].get("spawns", []) as Array).size() == reinforcement_after, "terminal secret reward is idempotent")
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
	_expect(not convoy.is_combat_enabled(), "convoy combat stays disabled while moving toward the first stop")
	var module_ids: Array[StringName] = [&"citation_drive_left", &"citation_signal_dish", &"citation_drive_right", &"citation_core"]
	for wave_index in 4:
		mission._set_piece_runtime._physics_process(100.0)
		_expect(convoy.is_combat_enabled(), "convoy combat enables at authored stop %d" % wave_index)
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
		_expect(not convoy.is_combat_enabled(), "convoy combat disables after phase %d resumes movement or defeat" % wave_index)
	mission._set_piece_runtime._physics_process(100.0)
	await process_frame
	var final_state := mission._set_piece_runtime.current_state()
	_expect(bool(final_state.get("path_completed", false)), "convoy reaches the authored path end")
	_expect(bool(final_state.get("completion_emitted", false)), "convoy emits completion after waves and modules")
	_expect(not mission._mission_runtime.encounters.active.has(&"harbour_pier"), "convoy encounter leaves no active harbour actors")


func _defeat_zone_encounter(mission: EpisodeOneVancouverWaterfront, zone_id: StringName) -> void:
	var safety := 0
	while mission._mission_runtime.encounters.active.has(zone_id) and safety < 16:
		var state := mission._mission_runtime.encounters.active.get(zone_id, {}) as Dictionary
		var timer := state.get("timer") as Timer
		if timer != null and not timer.is_stopped():
			timer.timeout.emit()
		var actors: Array = state.get("actors", []).duplicate()
		for actor in actors:
			if actor is EnemyAgent and not (actor as EnemyAgent).is_dead:
				(actor as EnemyAgent).apply_damage(99999.0)
		await process_frame
		safety += 1
	_expect(safety < 16, "route zone %s resolves within the bounded wave budget" % zone_id)


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
