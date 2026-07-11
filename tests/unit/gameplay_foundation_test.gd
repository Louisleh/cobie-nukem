extends SceneTree

class FakeEnemy extends Node:
	signal died(enemy: Node, source: Node)
	var target: Node3D
	func set_target(value: Node3D) -> void: target = value

var failures := PackedStringArray()
var spawned: Array[FakeEnemy] = []


func _initialize() -> void:
	_test_difficulty()
	_test_objectives()
	_test_encounter()
	_test_manifest()
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
	var tracker := ObjectiveTracker.new(); get_root().add_child(tracker); tracker.configure([first, second])
	_expect(tracker.record(ObjectiveDefinition.Kind.ACTIVATE, &"switch").is_empty(), "prerequisite blocks early objective")
	_expect(tracker.record(ObjectiveDefinition.Kind.REACH_ZONE, &"zone") == [&"first"], "first objective completes")
	_expect(tracker.record(ObjectiveDefinition.Kind.REACH_ZONE, &"zone").is_empty(), "objective completion is idempotent")
	_expect(tracker.record(ObjectiveDefinition.Kind.ACTIVATE, &"switch") == [&"second"], "unlocked objective completes")
	_expect(tracker.is_complete(), "required objective chain completes")
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


func _spawn_fake(_path: String, _position: Vector3) -> Node:
	var enemy := FakeEnemy.new(); get_root().add_child(enemy); spawned.append(enemy); return enemy


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
