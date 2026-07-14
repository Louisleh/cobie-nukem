extends SceneTree

## Adversarial state-transition coverage: stale timers, restart pressure,
## suppressed pause, stuck synthetic input, reload interruption, and running
## the complete level lifecycle twice in one process.

const LevelScene := preload("res://scenes/levels/episode_1_level_1.tscn")
const PlayerScene := preload("res://scenes/player/cobie_player.tscn")
const PauseScene := preload("res://scenes/ui/pause_menu.tscn")
const ControlsScene := preload("res://scenes/ui/mobile_controls.tscn")

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_opening_grace_timer_lifecycle()
	await _test_finale_completion_and_checkpoint_clear()
	await _test_checkpoint_save_without_presentation()
	await _test_repeated_fall_death_and_restart()
	await _test_pause_suppression_during_death_and_victory()
	await _test_mobile_input_release_on_exit_and_focus_loss()
	await _test_weapon_switch_spam_during_reload()
	await _test_pause_freezes_reload_and_grace()
	await _test_level_lifecycle_twice_in_one_process()
	await _test_failed_encounter_retry_marker_clear()
	await _test_enemy_drop_contract()
	if failures.is_empty():
		print("ADVERSARIAL STATE TESTS: PASS")
		quit(0)
	else:
		for failure in failures: push_error("ADVERSARIAL: " + failure)
		quit(1)


func _make_level() -> EpisodeOneLevel:
	var level := LevelScene.instantiate() as EpisodeOneLevel
	level.spawn_player = false
	level.start_run_automatically = false
	level.setup_presentation = false
	root.add_child(level)
	return level


func _test_opening_grace_timer_lifecycle() -> void:
	var level := _make_level()
	await process_frame
	var timer := level.get_node_or_null("OpeningGraceTimer") as Timer
	_expect(timer != null, "opening grace timer is owned by the level scene")
	if timer == null:
		level.free(); return
	_expect(not timer.is_stopped(), "entering the forbidden field starts the grace window")
	_expect(not level._opening_encounter_active, "grace window keeps the opening encounter passive")
	timer.stop()
	level._reset_active_encounter_for_checkpoint()
	_expect(not timer.is_stopped(), "checkpoint restart re-arms a single grace window")
	_expect(not level._opening_encounter_active, "checkpoint restart does not activate the opening encounter early")
	level._activate_opening_encounter()
	level._activate_opening_encounter()
	_expect(level._opening_encounter_active, "grace timeout activates the opening encounter")
	var active_enemies := 0
	for enemy in level._opening_enemies:
		if is_instance_valid(enemy) and enemy.process_mode == Node.PROCESS_MODE_INHERIT:
			active_enemies += 1
	_expect(active_enemies == 3, "activation wakes each respawned opening enemy exactly once")
	level.free()
	await process_frame


func _test_finale_completion_and_checkpoint_clear() -> void:
	var game_state := root.get_node("GameState")
	var save_manager := root.get_node("SaveManager")
	var level := _make_level()
	await process_frame
	game_state.begin_run(&"episode_1_level_1")
	save_manager.save_slot(&"checkpoint", {
		"scene_path": "res://scenes/levels/episode_1_level_1.tscn",
		"level_id": "episode_1_level_1",
		"checkpoint_id": "lab_entry",
		"position": [0.0, 1.5, -87.0],
		"difficulty_id": "classic",
	})
	var completions := [0]
	level.level_completed.connect(func(_summary: Dictionary) -> void: completions[0] += 1)
	level._on_golden_ball_claimed(null)
	level._on_golden_ball_claimed(null)
	_expect(level.completion_started, "finale claim starts completion")
	_expect(save_manager.load_slot(&"checkpoint").is_empty(), "finishing the level clears the stale checkpoint")
	await create_timer(1.5).timeout
	_expect(completions[0] == 1, "double finale claims complete the level exactly once")
	_expect(game_state.phase == game_state.Phase.VICTORY, "finale finishes the run")
	level.free()
	await process_frame


func _test_checkpoint_save_without_presentation() -> void:
	var game_state := root.get_node("GameState")
	var save_manager := root.get_node("SaveManager")
	var level := _make_level()
	await process_frame
	game_state.begin_run(&"episode_1_level_1")
	level._on_checkpoint(&"lab_entry", Vector3(0.0, 1.5, -87.0))
	await process_frame
	var checkpoint: Dictionary = save_manager.load_slot(&"checkpoint") if save_manager != null else {}
	_expect(not checkpoint.is_empty(), "checkpoint saves while setup_presentation is false")
	if checkpoint != {}:
		_expect(checkpoint.get("scene_path", "") == "res://scenes/levels/episode_1_level_1.tscn", "checkpoint saves the expected scene path")
		_expect(checkpoint.has("objective_snapshot"), "checkpoint save includes objective snapshot")
		_expect(checkpoint.has("encounter_snapshot"), "checkpoint save includes encounter snapshot")
		_expect(checkpoint.has("position"), "checkpoint save includes position payload")
		_expect(int(checkpoint.get("position")[0]) == 0, "checkpoint payload preserves integer position x")
	if save_manager != null:
		save_manager.delete_slot(&"checkpoint")
	level.free()
	await process_frame


func _test_repeated_fall_death_and_restart() -> void:
	var level := _make_level()
	var player := PlayerScene.instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	level.player = player
	for attempt in 3:
		player.global_position = Vector3(0.0, player.out_of_bounds_y - 2.0, 0.0)
		_expect(player._check_out_of_bounds(), "fall %d crosses the kill plane" % attempt)
		_expect(player.is_dead, "fall %d kills the player even inside respawn protection" % attempt)
		level.restart_from_checkpoint()
		await process_frame
		_expect(not player.is_dead, "restart %d revives the player" % attempt)
		_expect(player.health_armor.invulnerable_remaining > 0.0, "restart %d grants respawn protection" % attempt)
		_expect(player.global_position.distance_to(level.checkpoint_position) < 0.5, "restart %d returns to the checkpoint" % attempt)
	player.free()
	level.free()
	await process_frame


func _test_pause_suppression_during_death_and_victory() -> void:
	var game_state := root.get_node("GameState")
	var pause := PauseScene.instantiate() as PauseMenu
	root.add_child(pause)
	await process_frame
	game_state.begin_run(&"qa_pause")
	pause.close_for_death()
	pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not pause.visible, "focus loss cannot open the pause menu over the death screen")
	pause.set_suppressed(false)
	pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(pause.visible, "focus loss safety pause still works during live gameplay")
	pause.resume()
	game_state.finish_run()
	pause.set_suppressed(true)
	pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not pause.visible, "focus loss cannot open the pause menu over the victory screen")
	_expect(not paused, "suppressed focus loss leaves the tree unpaused")
	pause.free()
	await process_frame


func _test_mobile_input_release_on_exit_and_focus_loss() -> void:
	var player := PlayerScene.instantiate() as CobiePlayer
	root.add_child(player)
	var controls := ControlsScene.instantiate() as MobileControls
	controls.force_visible = true
	controls.set_anchors_preset(Control.PRESET_TOP_LEFT)
	controls.size = Vector2(320, 180)
	root.add_child(controls)
	controls.bind_player(player)
	await process_frame
	var fire_down := InputEventScreenTouch.new(); fire_down.index = 3; fire_down.position = Vector2(292, 111); fire_down.pressed = true
	controls._handle_touch(fire_down)
	var move_down := InputEventScreenTouch.new(); move_down.index = 4; move_down.position = Vector2(48, 80); move_down.pressed = true
	controls._handle_touch(move_down)
	var look_down := InputEventScreenTouch.new(); look_down.index = 5; look_down.position = Vector2(245, 105); look_down.pressed = true
	controls._handle_touch(look_down)
	Input.flush_buffered_events()
	_expect(Input.is_action_pressed(&"fire_primary"), "touch fire press reaches the input singleton")
	_expect(player._touch_move.length() > 0.5, "touch move press drives the player")
	_expect(player._touch_look.length() > 0.5, "touch aim press drives the player")
	controls.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	Input.flush_buffered_events()
	_expect(not Input.is_action_pressed(&"fire_primary"), "focus loss releases held synthetic fire")
	_expect(player._touch_move == Vector2.ZERO, "focus loss releases touch movement")
	_expect(player._touch_look == Vector2.ZERO, "focus loss releases touch aiming")
	controls._handle_touch(fire_down)
	Input.flush_buffered_events()
	root.remove_child(controls)
	Input.flush_buffered_events()
	_expect(not Input.is_action_pressed(&"fire_primary"), "leaving the tree releases held synthetic fire")
	controls.free()
	player.free()
	await process_frame


func _test_weapon_switch_spam_during_reload() -> void:
	var player := PlayerScene.instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	if player.weapons.size() < 2:
		failures.append("player needs at least two mounted weapons for switch spam coverage")
		player.free()
		return
	for weapon in player.weapons:
		weapon.unlocked = true
	player.select_weapon(1)
	var weapon := player.weapons[1]
	weapon.ammo = 0
	weapon.reserve_ammo = maxi(weapon.reserve_ammo, weapon.definition.magazine_size)
	var reserve_before := weapon.reserve_ammo
	_expect(weapon.request_reload(), "empty weapon accepts a reload request")
	for cycle in 4:
		player.select_weapon(player.current_weapon_index + 1)
		player.select_weapon(1)
	_expect(not weapon.is_reloading, "switching away cancels the reload instead of leaving a ghost timer")
	_expect(weapon.ammo == 0 and weapon.reserve_ammo == reserve_before, "cancelled reloads never duplicate or consume ammo")
	_expect(weapon.request_reload(), "weapon accepts a fresh reload after switch spam")
	weapon.cancel_reload()
	player.free()
	await process_frame


func _test_pause_freezes_reload_and_grace() -> void:
	var level := _make_level()
	var player := PlayerScene.instantiate() as CobiePlayer
	root.add_child(player)
	await process_frame
	var grace_timer := level.get_node_or_null("OpeningGraceTimer") as Timer
	var weapon := player.weapons[0]
	weapon.unlocked = true
	weapon.ammo = 0
	if weapon.definition.magazine_size > 0 and (weapon.definition.infinite_reserve or weapon.reserve_ammo > 0):
		weapon.request_reload()
	var reload_before: float = weapon._reload_remaining
	var grace_before := grace_timer.time_left if grace_timer != null else 0.0
	paused = true
	await create_timer(0.25, true).timeout
	_expect(is_equal_approx(weapon._reload_remaining, reload_before), "pause freezes reload progress")
	if grace_timer != null:
		_expect(is_equal_approx(grace_timer.time_left, grace_before), "pause freezes the opening grace window")
	paused = false
	await process_frame
	player.free()
	level.free()
	await process_frame


func _test_level_lifecycle_twice_in_one_process() -> void:
	var game_state := root.get_node("GameState")
	for lifecycle in 2:
		var level := _make_level()
		await process_frame
		_expect(level.enemies_total > 0, "lifecycle %d spawns the opening encounter" % lifecycle)
		_expect(not level.completion_started, "lifecycle %d starts with a fresh completion state" % lifecycle)
		_expect(level._objective_tracker.completed.is_empty(), "lifecycle %d starts with no completed objectives" % lifecycle)
		game_state.begin_run(&"episode_1_level_1")
		for milestone in EpisodeOneLevel.ROUTE_PROGRESS:
			level._enter_zone(StringName(milestone[1]), String(milestone[2]), null)
		_expect(level.spawned_zones.has(&"walker_arena"), "lifecycle %d arms the boss encounter" % lifecycle)
		level._on_golden_ball_claimed(null)
		await create_timer(1.4).timeout
		_expect(game_state.phase == game_state.Phase.VICTORY, "lifecycle %d reaches victory" % lifecycle)
		level.free()
		await process_frame


func _test_enemy_drop_contract() -> void:
	var level := _make_level()
	await process_frame
	level._enter_zone(&"compliance_lab", "ANIMAL COMPLIANCE LAB", null)
	var fetch_guard := level.get_node_or_null("Actors/FetchGuard") as ComplianceHound
	_expect(fetch_guard != null, "compliance lab spawns the fetch guard")
	if fetch_guard != null:
		var pickups_before := _count_pickups(level)
		fetch_guard.apply_damage(1000000.0)
		_expect(fetch_guard.is_dead, "fetch guard dies to overwhelming damage")
		_expect(_count_pickups(level) == pickups_before + 1, "authored drop_id spawns its pickup on death")
	level.free()
	await process_frame


func _test_failed_encounter_retry_marker_clear() -> void:
	var level := _make_level()
	await process_frame
	var zone_id := &"maintenance_tunnels"
	if not level._encounter_runner.definitions.has(zone_id):
		_expect(false, "maintenance_tunnels encounter exists for failure-retry coverage")
		level.free()
		await process_frame
		return
	var original_definition: EncounterDefinition = level._encounter_runner.definitions[zone_id] as EncounterDefinition
	level._encounter_runner.definitions[zone_id] = _make_missing_scene_encounter(zone_id)
	level.spawned_zones.erase(zone_id)
	level._spawn_registry.clear_zone(zone_id)
	level._enter_zone(zone_id, "MAINTENANCE TUNNELS", null)
	await process_frame
	_expect(not level.spawned_zones.has(zone_id), "zone suppression is rolled back after encounter activation failure")
	level._enter_zone(zone_id, "MAINTENANCE TUNNELS", null)
	await process_frame
	_expect(not level.spawned_zones.has(zone_id), "failed encounter can be retried on subsequent entry")
	level._encounter_runner.definitions[zone_id] = original_definition
	level.free()
	await process_frame


func _count_pickups(level: EpisodeOneLevel) -> int:
	var count := 0
	for actor in level.get_node("Actors").get_children():
		if actor is CombatPickup: count += 1
	return count


func _make_missing_scene_encounter(zone_id: StringName) -> EncounterDefinition:
	var encounter := EncounterDefinition.new()
	encounter.id = &"adversarial_missing_scene"
	encounter.zone_id = zone_id
	encounter.schema_version = 2
	encounter.maximum_simultaneous_attackers = 1
	encounter.waves = [
		{
			"spawns": [
				{"scene": "res://does_not_exist__mission_runtime_bug.tscn", "position": Vector3(0.0, 1.0, 0.0)},
			],
		},
	]
	encounter.completion_policy = EncounterDefinition.CompletionPolicy.ALL_DEFEATED
	encounter.enemy_budget = 1
	return encounter


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
