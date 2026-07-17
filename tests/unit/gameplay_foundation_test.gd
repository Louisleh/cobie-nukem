extends SceneTree

class FakeEnemy extends Node:
	signal died(enemy: Node, source: Node)
	var target: Node3D
	func set_target(value: Node3D) -> void: target = value

class FakeActorWithoutDeath extends Node:
	var target: Node3D
	func set_target(value: Node3D) -> void: target = value

var failures := PackedStringArray()
var spawned: Array[FakeEnemy] = []


func _initialize() -> void:
	_test_difficulty()
	_test_objectives()
	_test_encounter()
	await _test_boss_encounter_contracts()
	_test_encounter_failures_and_reset()
	_test_manifest()
	_test_respawn_protection()
	_test_quality_profiles()
	await _test_projectile_pool()
	await _test_world_registry_player_index()
	if failures.is_empty():
		print("GAMEPLAY FOUNDATION TESTS: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _test_difficulty() -> void:
	var story := load("res://resources/difficulty/story.tres") as DifficultyProfile
	var classic := load("res://resources/difficulty/classic.tres") as DifficultyProfile
	var mayhem := load("res://resources/difficulty/mayhem.tres") as DifficultyProfile
	_expect(is_equal_approx(story.scaled_enemy_health(100.0), 75.0), "story health scaling")
	_expect(is_equal_approx(story.scaled_enemy_damage(10.0), 5.5), "story damage scaling")
	_expect(is_equal_approx(story.scaled_pickup_amount(25.0), 35.0), "story pickup scaling")
	_expect(is_equal_approx(classic.scaled_pickup_amount(25.0), 25.0), "classic pickup scaling is neutral")
	_expect(is_equal_approx(mayhem.scaled_pickup_amount(25.0), 20.0), "mayhem pickup scaling")
	_expect(mayhem.scaled_pickup_ammo(1) == 1, "ammo pickups never scale down to zero")
	_expect(story.scaled_pickup_ammo(10) == 14, "story ammo pickup scaling rounds sensibly")
	_expect(is_equal_approx(classic.aim_assist_scale(), 1.0), "classic aim assist is the tuned baseline")
	_expect(story.aim_assist_scale() > 1.0 and mayhem.aim_assist_scale() < 1.0, "aim assist orders story > classic > mayhem")
	_test_difficulty_selection()


func _test_difficulty_selection() -> void:
	var game_state := get_root().get_node_or_null("GameState")
	_expect(game_state != null, "GameState autoload available")
	if game_state == null: return
	var initial: StringName = game_state.difficulty_id
	_expect(initial == &"classic", "classic is the boot default difficulty")
	_expect(not game_state.select_difficulty(&"nightmare"), "invalid difficulty id is rejected")
	_expect(game_state.difficulty_id == initial, "rejected id leaves selection unchanged")
	_expect(game_state.select_difficulty(&"mayhem"), "valid difficulty id is accepted")
	_expect(game_state.difficulty_id == &"mayhem", "selection persists in run state")
	var options: Array = game_state.difficulty_options()
	_expect(options.size() == 3, "three difficulty options are offered")
	if options.size() == 3:
		_expect(options[0].id == &"story" and options[1].id == &"classic" and options[2].id == &"mayhem", "difficulty options preserve story/classic/mayhem order")
		for profile in options:
			_expect(profile.validate().is_empty(), "difficulty option %s validates" % profile.id)
	_expect(game_state.get_difficulty_profile() == game_state.get_difficulty_profile(), "difficulty profile load is cached")
	game_state.begin_run(&"qa_difficulty")
	_expect(String(game_state.run_stats.get("difficulty_id", "")) == "mayhem", "run stats record the selected difficulty")
	game_state.select_difficulty(&"classic")


func _test_objectives() -> void:
	var first := ObjectiveDefinition.new(); first.id = &"first"; first.title = "FIRST"; first.target_id = &"zone"; first.kind = ObjectiveDefinition.Kind.REACH_ZONE
	var second := ObjectiveDefinition.new(); second.id = &"second"; second.title = "SECOND"; second.target_id = &"switch"; second.kind = ObjectiveDefinition.Kind.ACTIVATE; second.prerequisite_ids = [&"first"]
	var tracker := ObjectiveTracker.new(); get_root().add_child(tracker)
	var activation_count := [0]
	tracker.objective_activated.connect(func(_definition: ObjectiveDefinition) -> void: activation_count[0] += 1)
	tracker.configure([first, second])
	_expect(tracker.record(ObjectiveDefinition.Kind.ACTIVATE, &"switch").is_empty(), "prerequisite blocks early objective")
	_expect(tracker.record(ObjectiveDefinition.Kind.REACH_ZONE, &"zone") == [&"first"], "first objective completes")
	_expect(tracker.record(ObjectiveDefinition.Kind.REACH_ZONE, &"zone").is_empty(), "objective completion is idempotent")
	_expect(activation_count[0] == 2, "objective activation emits once per newly available objective")
	_expect(tracker.record(ObjectiveDefinition.Kind.ACTIVATE, &"switch") == [&"second"], "unlocked objective completes")
	_expect(tracker.is_complete(), "required objective chain completes")
	var round_trip: Variant = JSON.parse_string(JSON.stringify(tracker.snapshot()))
	var restored := ObjectiveTracker.new(); get_root().add_child(restored); restored.configure([first, second]); restored.restore(round_trip)
	_expect(restored.completed.has(&"first") and restored.completed.has(&"second"), "objective snapshot survives JSON round trip")
	restored.queue_free()
	tracker.queue_free()


func _test_encounter() -> void:
	var definition := EncounterDefinition.new(); definition.id = &"test"; definition.zone_id = &"arena"; definition.spawns = [{"scene": "res://scenes/enemies/squirrel_trooper.tscn", "position": Vector3.ZERO}]
	var runner := EncounterRunner.new(); get_root().add_child(runner); runner.configure([definition], _spawn_fake)
	var target := Node3D.new(); get_root().add_child(target)
	var actors := runner.activate_zone(&"arena", target)
	_expect(actors.size() == 1, "encounter spawns configured actor")
	_expect((actors[0] as FakeEnemy).target == target, "encounter assigns target")
	_expect(runner.activate_zone(&"arena", target).is_empty(), "encounter activation is one-shot")
	(actors[0] as FakeEnemy).died.emit(actors[0], null)
	_expect(runner.completed.has(&"arena"), "encounter completes after all actors die")
	runner.queue_free(); target.queue_free()
	var multi := EncounterDefinition.new(); multi.id = &"multi"; multi.zone_id = &"multi"; multi.enemy_budget = 2
	multi.waves = [
		{"spawns": [{"scene": "res://scenes/enemies/squirrel_trooper.tscn", "position": Vector3.ZERO}]},
		{"delay_seconds": 0.0, "spawns": [{"scene": "res://scenes/enemies/squirrel_trooper.tscn", "position": Vector3.ONE}]},
	]
	var wave_runner := EncounterRunner.new(); get_root().add_child(wave_runner); wave_runner.configure([multi], _spawn_fake)
	var first_wave := wave_runner.activate_zone(&"multi")
	_expect(first_wave.size() == 1, "multi-wave encounter starts only its first wave")
	(first_wave[0] as FakeEnemy).died.emit(first_wave[0], null)
	_expect(wave_runner.active.has(&"multi") and wave_runner.active[&"multi"].actors.size() == 1, "defeating a wave advances to the next authored wave")
	wave_runner.queue_free()


func _test_encounter_failures_and_reset() -> void:
	var definition := EncounterDefinition.new(); definition.id = &"failure"; definition.zone_id = &"failure_zone"; definition.spawns = [{"scene": "res://scenes/enemies/squirrel_trooper.tscn", "position": Vector3.ZERO}]
	var null_runner := EncounterRunner.new(); null_runner.log_failures = false; get_root().add_child(null_runner); null_runner.configure([definition], func(_path: String, _position: Vector3) -> Node: return null)
	null_runner.activate_zone(&"failure_zone")
	_expect(null_runner.failed.has(&"failure_zone") and not null_runner.completed.has(&"failure_zone"), "all-null encounter fails loudly instead of completing")
	null_runner.queue_free()
	var invalid_runner := EncounterRunner.new(); invalid_runner.log_failures = false; get_root().add_child(invalid_runner); invalid_runner.configure([definition], func(_path: String, _position: Vector3) -> Node:
		var actor := FakeActorWithoutDeath.new(); get_root().add_child(actor); return actor
	)
	invalid_runner.activate_zone(&"failure_zone")
	_expect(invalid_runner.failed.has(&"failure_zone"), "ALL_DEFEATED rejects actors without died signal")
	invalid_runner.queue_free()
	var reset_runner := EncounterRunner.new(); get_root().add_child(reset_runner); reset_runner.configure([definition], _spawn_fake)
	_expect(reset_runner.activate_zone(&"failure_zone").size() == 1, "reset test encounter activates")
	_expect(reset_runner.reset_zone(&"failure_zone"), "active encounter resets")
	_expect(reset_runner.activate_zone(&"failure_zone").size() == 1, "reset encounter can respawn")
	reset_runner.queue_free()


func _test_boss_encounter_contracts() -> void:
	var marker_missing := EncounterDefinition.new(); marker_missing.id = &"boss_missing"; marker_missing.zone_id = &"boss_missing"
	marker_missing.completion_policy = EncounterDefinition.CompletionPolicy.BOSS_DEFEATED
	marker_missing.waves = [{"spawns": [{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.ZERO}]}]
	_expect(not marker_missing.validate().is_empty(), "BOSS_DEFEATED rejects missing completion marker")
	var marker_multiple := EncounterDefinition.new(); marker_multiple.id = &"boss_multiple"; marker_multiple.zone_id = &"boss_multiple"
	marker_multiple.completion_policy = EncounterDefinition.CompletionPolicy.BOSS_DEFEATED
	marker_multiple.waves = [{"spawns": [
		{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.ZERO, "completion_marker": "boss"},
		{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.ONE, "completion_marker": "boss"}
	]}]
	_expect(not marker_multiple.validate().is_empty(), "BOSS_DEFEATED rejects multiple completion targets")
	var marker_type_invalid := EncounterDefinition.new(); marker_type_invalid.id = &"boss_type"; marker_type_invalid.zone_id = &"boss_type"
	marker_type_invalid.completion_policy = EncounterDefinition.CompletionPolicy.BOSS_DEFEATED
	marker_type_invalid.waves = [{"spawns": [{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.UP, "completion_marker": 7}]}]
	_expect(not marker_type_invalid.validate().is_empty(), "BOSS_DEFEATED rejects invalid completion marker type")
	var marker_policy_mismatch := EncounterDefinition.new(); marker_policy_mismatch.id = &"boss_mismatch"; marker_policy_mismatch.zone_id = &"boss_mismatch"
	marker_policy_mismatch.waves = [{"spawns": [{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.BACK, "completion_marker":"boss"}]}]
	_expect(not marker_policy_mismatch.validate().is_empty(), "completion marker requires BOSS_DEFEATED policy")

	var boss_definition := EncounterDefinition.new(); boss_definition.id = &"boss_runtime"; boss_definition.zone_id = &"boss_runtime"
	boss_definition.completion_policy = EncounterDefinition.CompletionPolicy.BOSS_DEFEATED
	boss_definition.waves = [
		{"spawns": [{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.ZERO}], "delay_seconds": 0.0},
		{"delay_seconds": 0.12, "spawns": [
			{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.ONE, "completion_marker":"boss"},
			{"scene":"res://scenes/enemies/squirrel_trooper.tscn","position":Vector3.RIGHT},
		]},
	]
	var boss_runner := EncounterRunner.new(); get_root().add_child(boss_runner)
	boss_runner.configure([boss_definition], _spawn_fake)
	var boss_events := [0]
	boss_runner.encounter_completed.connect(func(_definition: EncounterDefinition) -> void: boss_events[0] += 1)
	var first_wave := boss_runner.activate_zone(&"boss_runtime")
	_expect(first_wave.size() == 1, "boss policy spawns authored first wave")
	var first_target: FakeEnemy = first_wave[0] as FakeEnemy
	(first_target as FakeEnemy).died.emit(first_target, null)
	_expect(boss_runner.completed.is_empty(), "non-target defeat does not complete boss encounter")
	_expect(boss_runner.active.has(&"boss_runtime"), "boss encounter remains active after non-target defeat")
	await create_timer(0.13).timeout
	var second_wave: Array = boss_runner.active.get(&"boss_runtime", {}).get("actors", [])
	_expect(second_wave.size() == 2, "boss encounter advances into authored boss wave while target still alive")
	var boss_target: FakeEnemy = boss_runner.active[&"boss_runtime"].boss_target as FakeEnemy
	var remaining_guard: FakeEnemy = second_wave[1] as FakeEnemy
	(boss_target as FakeEnemy).died.emit(boss_target, null)
	await process_frame
	_expect(boss_events[0] == 1, "boss completion is emitted exactly once")
	_expect(boss_runner.completed.has(&"boss_runtime"), "defeating authored boss target completes encounter")
	_expect(not boss_runner.active.has(&"boss_runtime"), "boss completion clears all active encounter tracking")
	_expect(is_instance_valid(first_target), "already-defeated actors remain owned by their own death lifecycle")
	_expect(not is_instance_valid(remaining_guard), "boss completion cleans surviving runner-owned actors")
	first_target.free()
	boss_target.free()
	boss_runner.queue_free()


func _test_manifest() -> void:
	var manifest := load("res://resources/content/salmon_creek_manifest.tres") as ContentManifest
	_expect(manifest != null, "Salmon Creek manifest loads")
	if manifest != null:
		_expect(manifest.validate().is_empty(), "Salmon Creek manifest validates: %s" % manifest.validate())
		_expect(manifest.encounters.size() == 5, "Salmon Creek has five data encounters")
		_expect(manifest.objectives.size() == 4, "Salmon Creek has four production objectives")
	var mission_2 := load("res://resources/content/vancouver_waterfront_manifest.tres") as ContentManifest
	_expect(mission_2 != null, "Mission 2 manifest skeleton loads")
	if mission_2 != null:
		_expect(mission_2.validate().is_empty(), "Mission 2 manifest validates: %s" % mission_2.validate())
		_expect(mission_2.level_id == &"episode_1_vancouver_waterfront", "Mission 2 manifest uses the documented level id")
		_expect(mission_2.objectives.size() == 4 and mission_2.encounters.size() == 5, "Mission 2 skeleton covers four objectives and five zones")
	var mission_2_card := load("res://resources/level/rain_city_card.tres") as LevelCardData
	_expect(mission_2_card != null and mission_2_card.unlock_policy == LevelCardData.UnlockPolicy.CAMPAIGN and mission_2_card.prerequisite_mission_id == &"episode_1_salmon_creek" and mission_2_card.release_badge == "BETA" and mission_2_card.scene_path == "res://scenes/levels/episode_1_vancouver_waterfront.tscn", "Mission 2 is campaign-gated after Salmon Creek with an explicit BETA badge and production route")
	var cycle_a := ObjectiveDefinition.new(); cycle_a.id = &"a"; cycle_a.title = "A"; cycle_a.target_id = &"a"; cycle_a.prerequisite_ids = [&"b"]
	var cycle_b := ObjectiveDefinition.new(); cycle_b.id = &"b"; cycle_b.title = "B"; cycle_b.target_id = &"b"; cycle_b.prerequisite_ids = [&"a"]
	var invalid := ContentManifest.new(); invalid.level_id = &"invalid"; invalid.level_scene = "res://scenes/levels/episode_1_level_1.tscn"; invalid.objectives = [cycle_a, cycle_b]
	_expect("objective graph contains a dependency cycle" in invalid.validate(), "manifest detects objective cycles")
	var duplicate_profile := DifficultyProfile.new(); duplicate_profile.id = &"same"
	var duplicate_profile_2 := DifficultyProfile.new(); duplicate_profile_2.id = &"same"
	invalid.objectives = []; invalid.difficulty_profiles = [duplicate_profile, duplicate_profile_2]
	_expect("duplicate difficulty id: same" in invalid.validate(), "manifest detects duplicate difficulty ids")
	var bad_encounter := EncounterDefinition.new(); bad_encounter.id = &"bad"; bad_encounter.zone_id = &"bad"; bad_encounter.spawns = [{"scene": "res://scenes/ui/hud.tscn", "position": Vector3.ZERO}]
	_expect(not bad_encounter.validate().is_empty(), "encounter validator rejects scenes without enemy contract")


func _test_respawn_protection() -> void:
	var health := HealthArmor.new(); get_root().add_child(health); health.restore_full(); health.grant_invulnerability(1.5)
	_expect(health.apply_damage(50.0) == 0.0 and health.health == health.max_health, "respawn protection blocks immediate damage")
	health.invulnerable_remaining = 0.0
	_expect(health.apply_damage(10.0) > 0.0, "damage resumes after respawn protection")
	health.queue_free()


func _test_quality_profiles() -> void:
	var quality := get_root().get_node_or_null("QualityManager")
	var pressure := get_root().get_node_or_null("CombatPressure")
	_expect(quality != null and pressure != null, "quality and pressure services are available")
	if quality == null or pressure == null: return
	quality.apply_profile(quality.WEB)
	_expect(quality.current.id == &"web" and pressure.maximum_attackers == quality.WEB.maximum_attackers, "Web quality applies its pressure budget")
	_expect(Engine.max_fps == quality.WEB.target_fps, "Web quality applies its frame cap")
	quality.apply_profile(quality.NATIVE)
	_expect(quality.current.id == &"native" and pressure.maximum_attackers == quality.NATIVE.maximum_attackers, "native quality applies its enhanced budget")


func _test_projectile_pool() -> void:
	var pool := get_root().get_node_or_null("ProjectilePool")
	_expect(pool != null, "bounded enemy projectile pool is available")
	if pool == null:
		return
	if int(pool.available_count()) == 0:
		await process_frame
	var initial: int = int(pool.available_count())
	_expect(initial > 0, "projectile pool prewarms a bounded bolt reserve")
	var bolt_scene := load("res://scenes/enemies/enemy_bolt.tscn") as PackedScene
	var bolt := pool.acquire(bolt_scene) as EnemyProjectile
	_expect(bolt != null and bolt.visible and bolt.process_mode != Node.PROCESS_MODE_DISABLED, "pooled bolt activates without runtime instantiation")
	_expect(pool.available_count() == initial - 1, "acquiring a pooled bolt consumes one available instance")
	pool.release_projectile(bolt)
	await process_frame
	_expect(pool.available_count() == initial, "released bolt returns to the bounded pool")


func _test_world_registry_player_index() -> void:
	var registry := get_root().get_node_or_null("WorldRegistry")
	_expect(registry != null, "WorldRegistry autoload is available")
	if registry == null:
		return
	var indexed_player := Node3D.new()
	indexed_player.add_to_group(&"player")
	indexed_player.add_to_group(&"auto_aim_targets")
	indexed_player.add_to_group(&"interactables")
	get_root().add_child(indexed_player)
	await process_frame
	await process_frame
	_expect(registry.primary_player() == indexed_player, "WorldRegistry indexes the primary player without hot-path SceneTree scans")
	_expect(indexed_player in registry.targets_view(), "WorldRegistry exposes an allocation-free target view")
	_expect(indexed_player in registry.interactables_view(), "WorldRegistry exposes an allocation-free interaction view")
	indexed_player.queue_free()
	await process_frame
	_expect(registry.primary_player() == null, "WorldRegistry removes freed player entries")
	_expect(registry.targets_view().all(func(node: Node) -> bool: return is_instance_valid(node)), "WorldRegistry removes freed targets from the hot-path view")
	_expect(registry.interactables_view().all(func(node: Node) -> bool: return is_instance_valid(node)), "WorldRegistry removes freed interactables from the hot-path view")


func _spawn_fake(_path: String, _position: Vector3) -> Node:
	var enemy := FakeEnemy.new(); get_root().add_child(enemy); spawned.append(enemy); return enemy


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
