extends SceneTree

class FakeDropEnemy extends EnemyAgent:
	func trigger_drop() -> void:
		drop_requested.emit(&"treat", Vector3.ZERO)


class FakeOpeningEnemy extends EnemyAgent:
	var set_target_calls := 0
	var last_target: Node3D

	func set_target(value: Node3D) -> void:
		set_target_calls += 1
		last_target = value


class FakeEnemy extends EnemyAgent:
	pass


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_authoring_pickup_order_and_transform_before_ready()
	_test_pickup_signal_forwarding()
	_test_missing_scene_fail_safe()
	_test_drop_binding_once()
	_test_loot_burst_clamp_and_spacing()
	_test_opening_staging_activation_reset()
	_test_authored_retry_counts()
	_test_defeat_clamp_and_dead_pruning()
	_cleanup_test_nodes()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("MISSION SPAWN REGISTRY TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_authoring_pickup_order_and_transform_before_ready() -> void:
	var parent := _new_parent()
	var registry := _new_registry(parent)
	var pickup_ordered_paths: Array[String] = [
		"res://scenes/pickups/treat.tscn",
		"res://scenes/pickups/barkshot_weapon.tscn",
		"res://scenes/pickups/shells.tscn",
		"res://scenes/pickups/access_collar.tscn",
		"res://scenes/pickups/premium_treat.tscn",
		"res://scenes/pickups/fetch_launcher_weapon.tscn",
		"res://scenes/pickups/tennis_balls.tscn",
		"res://scenes/pickups/leather_padding.tscn",
		"res://scenes/pickups/water_bowl.tscn",
		"res://scenes/pickups/zoomies.tscn",
	]
	var pickup_positions: Array[Vector3] = [
		Vector3(-5, 0.8, 1),
		Vector3(0, 0.8, -34),
		Vector3(4, 0.8, -38),
		Vector3(0, 0.8, -72),
		Vector3(-3, 0.8, -76),
		Vector3(0, 0.8, -105),
		Vector3(6, 0.8, -110),
		Vector3(22, 0.8, -99),
		Vector3(27, 0.8, -102),
		Vector3(-10, 0.8, -132),
	]
	var entered: Array[Vector3] = []
	var enter_handler := func(node: Node) -> void:
		if node is Node3D:
			entered.append((node as Node3D).position)
	parent.child_entered_tree.connect(enter_handler)
	var spawned: Array[Node] = []
	for index in pickup_ordered_paths.size():
		var spawned_pickup := registry.spawn_pickup(pickup_ordered_paths[index], pickup_positions[index])
		_expect(spawned_pickup != null, "pickup %d instance from level-authored contract" % index)
		if spawned_pickup != null:
			spawned.append(spawned_pickup)
	_expect(spawned.size() == pickup_ordered_paths.size(), "all authored pickup spawns materialize")
	for index in spawned.size():
		var expected_position := pickup_positions[index]
		var node := spawned[index]
		_expect(parent.get_child(index) == node, "pickup order %d preserved when instanced" % index)
		_expect(is_instance_of(node, Node3D), "spawned pickup %d is Node3D for transform verification" % index)
		if node is Node3D:
			_expect((node as Node3D).position.is_equal_approx(expected_position), "spawned pickup %d keeps authored transform" % index)
			_expect(entered[index].is_equal_approx(expected_position), "pickup %d enters tree with authored transform pre-ready" % index)
	parent.free()


func _test_pickup_signal_forwarding() -> void:
	var parent := _new_parent()
	var registry := _new_registry(parent)
	var messages: Array[String] = []
	registry.pickup_collected.connect(func(message: String) -> void: messages.append(message))
	var pickup := registry.spawn_pickup("res://scenes/pickups/treat.tscn", Vector3(0.0, 0.8, 0.0))
	_expect(pickup != null, "pickup signal test spawned fixture pickup")
	if pickup == null:
		return
	pickup.emit_signal("collected", pickup, null, "TAKE THIS")
	_expect(messages.size() == 1, "spawned pickup forwards collected signal to registry")
	_expect(messages[0] == "TAKE THIS", "pickup collection preserves message payload")
	pickup.free()
	parent.free()
	registry.free()


func _test_missing_scene_fail_safe() -> void:
	var registry := _new_registry(_new_parent())
	_expect(registry.spawn_scene("res://does_not_exist__mission_spawn_registry.tscn", Vector3.ZERO) == null, "missing scene fails safely when spawning")
	_expect(registry.spawn_pickup("res://does_not_exist__mission_spawn_registry.tscn", Vector3.ZERO) == null, "missing pickup scene fails safely")
	_expect(registry.spawn_enemy_drop(&"does_not_exist__mission_spawn_registry", Vector3.ZERO) == null, "missing drop scene fails safely")


func _test_drop_binding_once() -> void:
	var registry := _new_registry(_new_parent())
	var enemy := FakeDropEnemy.new()
	registry.register_actor(enemy)
	var definition := EncounterDefinition.new()
	definition.zone_id = &"drop_binding"
	registry.register_encounter_actor(enemy, definition)
	enemy.trigger_drop()
	var after_first_drop := int(registry.temporary_counts().get("pickups", 0))
	_expect(after_first_drop == 1, "first enemy drop emits one pickup")
	registry.register_encounter_actor(enemy, definition, true)
	enemy.trigger_drop()
	var after_second_drop := int(registry.temporary_counts().get("pickups", 0))
	_expect(after_second_drop == 2, "drop signal remains single-bound after duplicate registration")
	enemy.free()


func _test_loot_burst_clamp_and_spacing() -> void:
	var parent := _new_parent()
	var registry := _new_registry(parent)
	var fallback_player := Node3D.new()
	parent.add_child(fallback_player)
	var pickups: Array[Node] = registry.spawn_loot_burst("res://scenes/pickups/treat.tscn", 20, null, fallback_player)
	_expect(pickups.size() == 8, "loot burst clamps count to 1..8 maximum")
	for pickup in pickups:
		if pickup is Node3D:
			_expect((pickup as Node3D).global_position.distance_to(fallback_player.global_position) >= 0.28, "spawned loot avoids immediate overlap with fallback player")
		else:
			_expect(false, "spawned loot pickup is Node3D for spacing check")
	parent.free()


func _test_opening_staging_activation_reset() -> void:
	var registry := _new_registry(_new_parent())
	var definition := EncounterDefinition.new()
	definition.zone_id = &"forbidden_field"
	var enemy := FakeOpeningEnemy.new()
	var player := Node3D.new()
	registry.register_encounter_actor(enemy, definition)
	var staged := registry.opening_enemies_snapshot()
	_expect(staged.size() == 1, "forbidden-field enemy is staged for opening activation")
	_expect((enemy as Node3D).process_mode == Node.PROCESS_MODE_DISABLED, "staged opening enemy is initially disabled")
	registry.activate_staged_enemies(player)
	_expect((enemy as Node3D).process_mode == Node.PROCESS_MODE_INHERIT, "opening-stage enemy wakes on activation")
	_expect(enemy.set_target_calls == 1, "opening enemy receives target exactly once when staged actors wake")
	registry.activate_staged_enemies(player)
	_expect(enemy.set_target_calls == 1, "re-activating opening enemy does not re-wake or re-target")
	registry.reset_staged_enemies()
	_expect(registry.opening_enemies_snapshot().is_empty(), "opening-stage reset clears staged list")
	_expect(not registry.opening_enemies_active(), "opening-stage reset clears awaken flag")
	enemy.free()
	player.free()


func _test_authored_retry_counts() -> void:
	var registry := _new_registry(_new_parent())
	var zone_id := &"retry_contract"
	var definition := EncounterDefinition.new()
	definition.zone_id = zone_id
	var first_author := FakeEnemy.new()
	var second_author := FakeEnemy.new()
	var retry_actor := FakeEnemy.new()
	registry.register_encounter_actor(first_author, definition)
	registry.register_encounter_actor(second_author, definition)
	registry.register_encounter_actor(retry_actor, definition, true)
	_expect(registry.enemies_total == 2, "non-retry authored enemy registrations advance total")
	_expect(registry.zone_author_count(zone_id) == 2, "author zone spawn contract tracks non-retry waves")
	_expect(registry.zone_retry_count(zone_id) == 1, "retry zone spawn contract tracks retry wave attempts")
	_expect(registry.record_enemy_defeat() == 1, "first enemy defeat is counted")
	_expect(registry.record_enemy_defeat() == 2, "second enemy defeat is counted")
	_expect(registry.record_enemy_defeat() == 2, "third recorded enemy defeat reaches authored total")
	_expect(registry.record_enemy_defeat() == 2, "defeat clamp holds at authored total")
	first_author.free()
	second_author.free()
	retry_actor.free()


func _test_defeat_clamp_and_dead_pruning() -> void:
	var parent := _new_parent()
	var registry := _new_registry(parent)
	var definition := EncounterDefinition.new()
	definition.zone_id = &"prune_contract"
	var enemy_keep := FakeEnemy.new()
	var enemy_free := FakeEnemy.new()
	var pickup_keep := registry.spawn_pickup("res://scenes/pickups/treat.tscn", Vector3(0, 0.8, 0))
	registry.register_encounter_actor(enemy_keep, definition)
	registry.register_encounter_actor(enemy_free, definition, false)
	var marker := Node3D.new()
	registry.register_critical(&"critical", marker)
	var before := registry.temporary_counts()
	_expect(int(before["enemies"]) == 2, "temporary count captures both registered enemies before pruning")
	_expect(int(before["pickups"]) == 1, "temporary count captures pickup before pruning")
	_expect(int(before["critical"]) == 1, "temporary critical count captures live critical reference")
	enemy_free.free()
	pickup_keep.free()
	marker.free()
	var after := registry.temporary_counts()
	_expect(int(after["enemies"]) == 1, "dead enemy entries are pruned from registry")
	_expect(int(after["pickups"]) == 0, "dead pickups are pruned from registry")
	_expect(int(after["critical"]) == 0, "dead critical references are pruned from registry")
	enemy_keep.free()
	parent.free()


func _new_parent() -> Node3D:
	var parent := Node3D.new()
	get_root().add_child(parent)
	return parent


func _new_registry(parent: Node3D) -> MissionSpawnRegistry:
	var registry := MissionSpawnRegistry.new()
	registry.name = "MissionSpawnRegistryTestHarness"
	get_root().add_child(registry)
	registry.configure(parent)
	return registry


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _cleanup_test_nodes() -> void:
	for child in get_root().get_children():
		child.free()
