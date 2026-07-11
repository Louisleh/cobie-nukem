extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	var packed := load("res://scenes/levels/episode_1_level_1.tscn") as PackedScene
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
	var hover_origins_ok := true
	var drone_origins_ok := true
	for actor in level.get_node("Actors").get_children():
		if actor is CombatPickup:
			hover_origins_ok = hover_origins_ok and actor._anchor.y > 0.6
		elif actor is LeashEnforcementDrone:
			drone_origins_ok = drone_origins_ok and actor._base_height > 1.5 and not actor.uses_gravity
	check(hover_origins_ok, "Pickup hover origins were captured before spawn placement")
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
		level._physics_process(0.0)
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
	check(level.enemies_total == 12, "Complete route must count all 12 authored enemies without double-counting checkpoint respawns")
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
	level.free()
	await process_frame
	await process_frame
	finish()


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
