extends SceneTree

class SoakEnemy extends Node:
	signal died(enemy: Node, source: Node)
	func set_target(_value: Node3D) -> void: pass

const MANIFEST := preload("res://resources/content/salmon_creek_manifest.tres")
const PLAYER := preload("res://scenes/player/cobie_player.tscn")
const CONTROLS := preload("res://scenes/ui/mobile_controls.tscn")
const CHECKPOINT_SCENE := "res://scenes/levels/episode_1_level_1.tscn"
const ROUTE: Array[StringName] = [&"forbidden_field", &"equipment_shed", &"maintenance_tunnels", &"compliance_lab", &"walker_arena"]

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_seeded_routes(100)
	_test_checkpoint_cycles(50)
	await _test_touch_cancellation_cycles(50)
	await _test_weapon_state_fuzz(300)
	_test_temporary_effect_budget(100)
	if failures.is_empty():
		print("VERTICAL SLICE SOAK: PASS (100 routes, 50 checkpoints, 50 touch cancellations, 300 weapon transitions, 100 effects)")
		quit(0)
	else:
		for failure in failures: push_error("SOAK: " + failure)
		quit(1)


func _test_seeded_routes(count: int) -> void:
	for seed_value in count:
		seed(seed_value)
		var tracker := ObjectiveTracker.new(); root.add_child(tracker); tracker.configure(MANIFEST.objectives)
		var runner := EncounterRunner.new(); runner.log_failures = false; root.add_child(runner)
		var spawned: Array[SoakEnemy] = []
		runner.configure(MANIFEST.encounters, func(_path: String, _position: Vector3) -> Node:
			var enemy := SoakEnemy.new(); root.add_child(enemy); spawned.append(enemy); return enemy
		)
		for zone_id in ROUTE:
			var actors := runner.activate_zone(zone_id)
			for actor in actors.duplicate(): (actor as SoakEnemy).died.emit(actor, null)
		tracker.record(ObjectiveDefinition.Kind.REACH_ZONE, &"compliance_lab")
		tracker.record(ObjectiveDefinition.Kind.ACTIVATE, &"walker_release")
		tracker.record(ObjectiveDefinition.Kind.DEFEAT, &"animal_control_walker")
		tracker.record(ObjectiveDefinition.Kind.COLLECT_ITEM, &"golden_tennis_ball")
		_expect(runner.completed.size() == ROUTE.size(), "route %d leaves an encounter incomplete" % seed_value)
		_expect(tracker.is_complete(), "route %d leaves required progression incomplete" % seed_value)
		for actor in spawned:
			if is_instance_valid(actor): actor.free()
		runner.free(); tracker.free()


func _test_checkpoint_cycles(count: int) -> void:
	for cycle in count:
		var payload := {
			"scene_path": CHECKPOINT_SCENE, "level_id": "episode_1_level_1", "checkpoint_id": "lab_entry",
			"position": [float(cycle % 3), 1.5, -87.0], "difficulty_id": "mayhem" if cycle % 2 else "classic",
			"objective_snapshot": {"progress": {"reach_lab": 1}, "completed": ["reach_lab"]},
			"encounter_snapshot": {"completed": ["forbidden_field", "equipment_shed"]},
			"secrets": {"optional_sign": "SIGN SEEMS OPTIONAL"},
		}
		var round_trip: Variant = JSON.parse_string(JSON.stringify(payload))
		var clean := CheckpointPayload.sanitize(round_trip)
		_expect(not clean.is_empty() and clean.objective_snapshot.completed == ["reach_lab"], "checkpoint cycle %d loses objective state" % cycle)
		_expect(clean.encounter_snapshot.completed.size() == 2 and clean.secrets.size() == 1, "checkpoint cycle %d loses mission state" % cycle)


func _test_touch_cancellation_cycles(count: int) -> void:
	var player := PLAYER.instantiate() as CobiePlayer; root.add_child(player)
	var controls := CONTROLS.instantiate() as MobileControls; controls.force_visible = true; controls.set_anchors_preset(Control.PRESET_TOP_LEFT); controls.size = Vector2(640, 360); root.add_child(controls); controls.bind_player(player)
	await process_frame
	for cycle in count:
		var fire := InputEventScreenTouch.new(); fire.index = cycle * 2; fire.position = controls._from_design(Vector2(291, 122)); fire.pressed = true
		var move := InputEventScreenTouch.new(); move.index = cycle * 2 + 1; move.position = controls._from_design(Vector2(48, 84)); move.pressed = true
		controls._handle_touch(fire); controls._handle_touch(move); Input.flush_buffered_events()
		controls.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT); Input.flush_buffered_events()
		_expect(not Input.is_action_pressed(&"fire_primary") and player._touch_move == Vector2.ZERO, "touch cancellation cycle %d leaves input latched" % cycle)
	controls.free(); player.free()


func _test_weapon_state_fuzz(count: int) -> void:
	var player := PLAYER.instantiate() as CobiePlayer; root.add_child(player); await process_frame
	for weapon in player.weapons: weapon.unlocked = true
	for transition in count:
		player.select_weapon((transition * 17 + 5) % player.weapons.size())
		var current := player.weapons[player.current_weapon_index]
		if transition % 7 == 0: current.request_reload()
		if transition % 11 == 0: current.cancel_reload()
		var enabled_count := 0
		for weapon in player.weapons:
			if weapon.enabled: enabled_count += 1
		_expect(enabled_count == 1 and current.enabled and current.visible, "weapon transition %d creates flicker or multiple active weapons" % transition)
	player.free()


func _test_temporary_effect_budget(count: int) -> void:
	var quality := root.get_node("QualityManager")
	quality.apply_profile(quality.WEB)
	for index in count:
		var effect := Node3D.new(); effect.name = "SoakEffect%d" % index; root.add_child(effect); quality.claim_temporary_effect(effect)
	_expect(quality.temporary_effect_count() <= quality.WEB.decal_budget, "temporary effects exceed the Web quality budget")
	for effect in quality._temporary_effects.duplicate():
		if is_instance_valid(effect): effect.free()
	quality._temporary_effects.clear()
	quality.apply_profile(quality.NATIVE)


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
