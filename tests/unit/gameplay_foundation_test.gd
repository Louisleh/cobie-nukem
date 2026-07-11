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
	_test_encounter_failures_and_reset()
	_test_manifest()
	_test_respawn_protection()
	if failures.is_empty():
		print("GAMEPLAY FOUNDATION TESTS: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _test_difficulty() -> void:
	var story := load("res://resources/difficulty/story.tres") as DifficultyProfile
	_expect(is_equal_approx(story.scaled_enemy_health(100.0), 75.0), "story health scaling")
	_expect(is_equal_approx(story.scaled_enemy_damage(10.0), 5.5), "story damage scaling")


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


func _test_manifest() -> void:
	var manifest := load("res://resources/content/salmon_creek_manifest.tres") as ContentManifest
	_expect(manifest != null, "Salmon Creek manifest loads")
	if manifest != null:
		_expect(manifest.validate().is_empty(), "Salmon Creek manifest validates: %s" % manifest.validate())
		_expect(manifest.encounters.size() == 5, "Salmon Creek has five data encounters")
		_expect(manifest.objectives.size() == 4, "Salmon Creek has four production objectives")
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


func _spawn_fake(_path: String, _position: Vector3) -> Node:
	var enemy := FakeEnemy.new(); get_root().add_child(enemy); spawned.append(enemy); return enemy


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
