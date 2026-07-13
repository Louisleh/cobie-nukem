extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	var packed := load("res://scenes/levels/episode_1_level_1.tscn") as PackedScene
	var save_manager := get_root().get_node_or_null("SaveManager")
	var game_state := get_root().get_node_or_null("GameState")
	if packed == null:
		fail("Level scene does not load")
		finish(); return
	var level := packed.instantiate() as EpisodeOneLevel
	level.spawn_player = false
	level.start_run_automatically = false
	level.setup_presentation = false
	root.add_child.call_deferred(level)
	await process_frame
	await process_frame
	check(level.metadata.level_id == &"episode_1_level_1", "Wrong level metadata id")
	check(level.metadata.target_minutes_min == 12 and level.metadata.target_minutes_max == 20, "Pacing target must be 12–20 minutes")
	check(level.get_node_or_null("Geometry") != null, "Procedural geometry missing")
	check(level.get_node_or_null("Actors") != null, "Actor container missing")
	check(level.get_node_or_null("Interactables") != null, "Interactable container missing")
	var bridge := level.get_node_or_null("Geometry/SecretDogParkBridge") as CSGBox3D
	check(bridge != null and bridge.size.x >= 2.0 and bridge.size.z >= 5.0, "Secret dog park has no continuous floor bridge")
	check(level.get_node_or_null("Geometry/LabEastBoundaryRear") != null, "Rear lab boundary segment missing")
	check(level.get_node_or_null("Geometry/LabEastBoundaryFront") != null, "Front lab boundary segment missing")
	var runtime := level._interaction_runtime
	check(runtime != null, "Mission interaction runtime is initialized")
	if runtime != null:
		var catalog := load("res://resources/interactions/salmon_creek_interactions.tres") as InteractionCatalog
		check(catalog != null, "Salmon interaction catalog loads for runtime validation")
		if catalog != null:
			var runtime_interactions := runtime.interaction_nodes()
			check(runtime_interactions.size() == catalog.placements.size(), "One live interaction exists for every catalog placement")
			var seen_ids: Dictionary = {}
			var expected_by_id: Dictionary = {}
			for placement in catalog.placements:
				expected_by_id[String(placement.id)] = placement
			for interaction in runtime_interactions:
				var definition := interaction.definition
				check(definition != null, "Catalog interactions are initialized with definitions")
				if definition == null:
					continue
				var placement_id := String(definition.id)
				check(not seen_ids.has(placement_id), "Duplicate runtime interaction id: %s" % placement_id)
				seen_ids[placement_id] = true
				check(expected_by_id.has(placement_id), "Runtime interaction id %s comes from catalog placement data" % placement_id)
				var placement := expected_by_id[placement_id] as InteractionPlacement
				if placement != null:
					check(_transform_matches(interaction.transform, placement.transform), "Runtime interaction %s uses catalog transform" % placement_id)
	var hover_origins_ok := true
	var drone_origins_ok := true
	var combat_pickup_count := 0
	for actor in level.get_node("Actors").get_children():
		if actor is CombatPickup:
			combat_pickup_count += 1
			hover_origins_ok = hover_origins_ok and actor._anchor.y > 0.6
		elif actor is LeashEnforcementDrone:
			drone_origins_ok = drone_origins_ok and actor._base_height > 1.5 and not actor.uses_gravity
	check(hover_origins_ok, "Pickup hover origins were captured before spawn placement")
	check(combat_pickup_count == 10, "Salmon Creek should author exactly 10 pickups")
	check(drone_origins_ok, "Drone hover height was captured before spawn placement")
	var doors := 0; var signs := 0; var checkpoints := 0; var finale := 0
	for child in level.get_node("Interactables").get_children():
		if child is LevelDoor: doors += 1
		elif child is NarrativeSign: signs += 1
		elif child is LevelCheckpoint: checkpoints += 1
		elif child is GoldenBallFinale: finale += 1
	check(doors >= 4, "Expected four progression gates")
	check(signs >= 7, "Environmental joke/sign density is below requirement")
	check(checkpoints == 1, "Exactly one checkpoint expected")
	check(finale == 1, "Golden Ball finale missing")
	level._discover_secret(&"optional_sign", "SIGN SEEMS OPTIONAL")
	level._discover_secret(&"cracked_wall", "MAINTENANCE LOOPHOLE")
	level._discover_secret(&"ball_return", "AUTHORIZED FETCHING")
	level._discover_secret(&"ball_return", "AUTHORIZED FETCHING")
	check(level.secrets.size() == 3, "Secrets must be unique and total three")
	var player := preload("res://scenes/player/cobie_player.tscn").instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	check(player.is_in_group(&"player"), "Player identity group missing; zone progression cannot trigger")
	check(player.is_in_group(&"damageable_player"), "Player damageable identity group missing")
	level.player = player
	player.health_armor.health = 1.0
	level.restart_from_checkpoint()
	var runtime_loot_interaction := _find_interaction_by_kind(level, WorldInteractionDefinition.Kind.LOOT_CONTAINER)
	var actor_children_before := level.get_node("Actors").get_children()
	if runtime_loot_interaction != null:
		var actor_position := Vector3(2.1, 1.1, -11.2)
		player.global_position = actor_position
		runtime_loot_interaction.interact(player)
		await process_frame
		var actor_children_after := level.get_node("Actors").get_children()
		var spawned_pickups: Array[Node3D] = []
		for actor in actor_children_after:
			if actor is CombatPickup and actor not in actor_children_before:
				spawned_pickups.append(actor)
		var expected_count := clampi(runtime_loot_interaction.definition.loot_drop_count, 1, 8)
		check(spawned_pickups.size() == expected_count, "Loot interaction spawned expected bounded pickup count")
		for pickup in spawned_pickups:
			check(is_instance_valid(pickup), "Loot pickup remains alive after interaction frame")
			var distance_to_source := pickup.global_position.distance_to(runtime_loot_interaction.global_position)
			check(distance_to_source > 0.2, "Runtime loot spawn stays offset from its interaction source")
	var secret_interaction := _find_interaction_by_kind(level, WorldInteractionDefinition.Kind.SECRET_TRIGGER)
	if secret_interaction != null:
		var before := level.secrets.size()
		secret_interaction.interact(player)
		secret_interaction.interact(player)
		check(level.secrets.size() == before + 1, "Secret interactions call the level contract exactly once")
	var audio_level := packed.instantiate() as EpisodeOneLevel
	audio_level.spawn_player = false
	audio_level.start_run_automatically = false
	audio_level.setup_presentation = true
	root.add_child(audio_level)
	await process_frame
	await process_frame
	var audio_bridge: CombatAudioBridge = audio_level._combat_audio
	check(audio_bridge != null, "Episode level restores runtime audio bridge in presentation setup")
	if audio_bridge != null:
		audio_bridge.sounds.play(ProceduralAudio.Cue.PAWSTOL)
		audio_bridge.sounds.play(ProceduralAudio.Cue.HURT)
		if audio_bridge.samples != null:
			check(audio_bridge.samples.play(&"pawstol_shot"), "Imported sample cue can be started for bridge reset coverage")
		await process_frame
		check(_active_voice_count(audio_bridge.sounds) >= 1, "Checkpoint restart test has active procedural voices before reset")
		if audio_bridge.samples != null:
			check(_active_voice_count(audio_bridge.samples) >= 1, "Checkpoint restart test has active sample voices before reset")
		audio_level.restart_from_checkpoint()
		await process_frame
		check(_active_voice_count(audio_bridge.sounds) == 0, "Combat audio reset clears procedural gameplay voices")
		if audio_bridge.samples != null:
			check(_active_voice_count(audio_bridge.samples) == 0, "Combat audio reset clears sample gameplay voices")
	audio_level.queue_free()
	await process_frame
	check(player.health_armor.health == player.health_armor.max_health, "Checkpoint restart does not restore player health")
	check(player.health_armor.invulnerable_remaining > 0.0, "Checkpoint restart lacks immediate spawn protection")
	var reset_actors: Array = level._encounter_runner.active.get(&"forbidden_field", {}).get("actors", [])
	check(reset_actors.size() == 3, "Checkpoint restart does not respawn the active encounter")
	var authored_positions: Array[Vector3] = [Vector3(-5, 2, -4), Vector3(5, 2, -9), Vector3(0, 0, -14)]
	for actor in reset_actors:
		check(actor.position in authored_positions, "Restarted enemy did not return to an authored spawn")
	var compliance_trigger: LevelZoneTrigger
	for child in level.get_node("Interactables").get_children():
		if child is LevelZoneTrigger and child.zone_id == &"compliance_lab":
			compliance_trigger = child
			break
	check(compliance_trigger != null, "Compliance Lab trigger missing")
	if compliance_trigger != null:
		check(compliance_trigger.collision_mask == 2, "Progression trigger does not detect the player physics layer")
		player.global_position.z = -90.0
		level._check_route_recovery()
		check(level.spawned_zones.has(&"equipment_shed"), "Spatial fallback missed Equipment Shed progression")
		check(level.spawned_zones.has(&"maintenance_tunnels"), "Spatial fallback missed Maintenance Tunnels progression")
		check(level.spawned_zones.has(&"compliance_lab"), "Spatial fallback missed Compliance Lab progression")
		compliance_trigger._on_body_entered(player)
	for zone in [&"walker_arena"]:
		level._enter_zone(zone, String(zone), null)
	var fetch_guard := level.get_node_or_null("Actors/FetchGuard") as ComplianceHound
	check(fetch_guard != null, "Compliance Lab did not spawn the Fetch Guard")
	if fetch_guard != null:
		check(fetch_guard.global_position.z > -112.0, "Fetch Guard spawned too far behind the launcher encounter")
	check(level.spawned_zones.has(&"walker_arena"), "Boss encounter does not arm")
	check(level.enemies_total == 12, "Route activation must count all 12 initial-wave actors without double-counting checkpoint respawns")
	player.health_armor.invulnerable_remaining = 0.0
	player.global_position.y = player.out_of_bounds_y - 1.0
	check(player._check_out_of_bounds(), "Player crossing the kill plane triggers out-of-bounds death")
	check(player.is_dead and player.health_armor.is_dead, "Out-of-bounds fall uses the normal death state")
	level.player = null
	for actor in level.get_node("Actors").get_children():
		actor.process_mode = Node.PROCESS_MODE_DISABLED
	player.free()
	var summary := level.get_level_summary()
	check(summary.secrets_total == 3, "Summary secret total incorrect")
	check(summary.level_id == &"episode_1_level_1", "Summary level id incorrect")
	if game_state != null and save_manager != null:
		game_state.continue_requested = true
		save_manager.save_slot(&"checkpoint", {
			"scene_path": "res://scenes/levels/episode_1_level_1.tscn",
			"level_id": "episode_1_level_1",
			"checkpoint_id": "lab_entry",
			"difficulty_id": "classic",
			"position": [1.0, 1.1, -87.0],
			"objective_snapshot": {"progress": {}, "completed": []},
			"encounter_snapshot": {"completed": []},
			"secrets": {"optional_sign": "SIGN SEEMS OPTIONAL"},
		})
		var continue_level := packed.instantiate() as EpisodeOneLevel
		continue_level.spawn_player = false
		continue_level.start_run_automatically = true
		continue_level.setup_presentation = false
		root.add_child(continue_level)
		await process_frame
		await process_frame
		check(not game_state.continue_requested, "Continue request flag is consumed during checkpoint restore")
		check(game_state.run_stats.get("checkpoint_id", "") == "lab_entry", "Continue restore applies sanitized checkpoint identity to run stats")
		continue_level.queue_free()
		save_manager.delete_slot(&"checkpoint")
	else:
		check(false, "SaveManager and GameState are available for continue checkpoint identity coverage")
	level.free()
	await process_frame
	await process_frame
	finish()


func _active_voice_count(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
			if child.playing:
				count += 1
	return count


func _find_interaction_by_kind(level: EpisodeOneLevel, kind: WorldInteractionDefinition.Kind) -> WorldInteraction:
	if level._interaction_runtime == null:
		return null
	var runtime := level._interaction_runtime
	for interaction in runtime.interaction_nodes():
		if interaction.definition != null and interaction.definition.kind == kind:
			return interaction
	return null


func _transform_matches(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.is_equal_approx(b.origin) and a.basis.x.is_equal_approx(b.basis.x) and a.basis.y.is_equal_approx(b.basis.y) and a.basis.z.is_equal_approx(b.basis.z)


func check(condition: bool, message: String) -> void:
	if not condition: fail(message)


func fail(message: String) -> void:
	failures.append(message)


func finish() -> void:
	if failures.is_empty():
		print("PASS: Episode 1 Level 1 route, gates, secrets, pacing metadata, encounter wiring, and finale")
		quit(0)
	else:
		for message in failures: push_error(message)
		quit(1)
