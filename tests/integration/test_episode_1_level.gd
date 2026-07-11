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
	root.add_child.call_deferred(level)
	await process_frame
	await process_frame
	check(level.metadata.level_id == &"episode_1_level_1", "Wrong level metadata id")
	check(level.metadata.target_minutes_min == 12 and level.metadata.target_minutes_max == 20, "Pacing target must be 12–20 minutes")
	check(level.get_node_or_null("Geometry") != null, "Procedural geometry missing")
	check(level.get_node_or_null("Actors") != null, "Actor container missing")
	check(level.get_node_or_null("Interactables") != null, "Interactable container missing")
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
	for zone in [&"equipment_shed", &"maintenance_tunnels", &"compliance_lab", &"walker_arena"]:
		level._enter_zone(zone, String(zone), null)
	check(level.spawned_zones.has(&"walker_arena"), "Boss encounter does not arm")
	var summary := level.get_level_summary()
	check(summary.secrets_total == 3, "Summary secret total incorrect")
	check(summary.level_id == &"episode_1_level_1", "Summary level id incorrect")
	level.queue_free()
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
