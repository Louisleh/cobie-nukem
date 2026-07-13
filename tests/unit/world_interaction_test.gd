extends SceneTree

class FakeDamageTarget extends StaticBody3D:
	var damage_calls: Array[float] = []

	func _init() -> void:
		var collision_shape := CollisionShape3D.new()
		collision_shape.shape = BoxShape3D.new()
		collision_shape.shape.size = Vector3.ONE
		add_child(collision_shape)

	func apply_damage(amount: float, _source: Node, _position: Vector3) -> float:
		damage_calls.append(amount)
		return amount


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_definition_validation()
	await _test_breakable_and_loot_activation()
	await _test_explosive_one_shot_chain_reactions()
	await _test_hazard_ticks_with_one_timer()
	await _test_secret_snapshot_and_restore()
	await _test_reset_rewinds_non_persistent()
	if failures.is_empty():
		print("WORLD INTERACTION TESTS: PASS")
		quit(0)
	else:
		for item in failures:
			push_error(item)
		quit(1)


func _test_definition_validation() -> void:
	var breakable := _make_definition(WorldInteractionDefinition.Kind.BREAKABLE_PROP)
	var explosive := _make_definition(WorldInteractionDefinition.Kind.EXPLOSIVE_PROP)
	var hazard := _make_definition(WorldInteractionDefinition.Kind.HAZARD_ZONE)
	var loot := _make_definition(WorldInteractionDefinition.Kind.LOOT_CONTAINER)
	var secret := _make_definition(WorldInteractionDefinition.Kind.SECRET_TRIGGER)
	_expect(breakable.validate().is_empty(), "breakable definition validates")
	_expect(explosive.validate().is_empty(), "explosive definition validates")
	_expect(hazard.validate().is_empty(), "hazard definition validates")
	_expect(loot.validate().is_empty(), "loot definition validates")
	_expect(secret.validate().is_empty(), "secret definition validates")

	breakable.id = &""
	_expect(not breakable.validate().is_empty(), "empty id is rejected")
	breakable.id = &"breakable"
	breakable.breakable_health = 0.0
	_expect(not breakable.validate().is_empty(), "non-positive breakable health is rejected")

	explosive.explosive_blast_radius = 0.0
	expect(not explosive.validate().is_empty(), "non-positive explosive blast radius is rejected")
	hazard.hazard_tick_seconds = 0.0
	expect(not hazard.validate().is_empty(), "non-positive hazard tick is rejected")
	loot.loot_scene = "res://scenes/pickups/does_not_exist.tscn"
	expect(not loot.validate().is_empty(), "missing loot scene is rejected")
	secret.persistence_id = &""
	expect(not secret.validate().is_empty(), "missing secret persistence id is rejected")


func _test_breakable_and_loot_activation() -> void:
	var breakable := _make_definition(WorldInteractionDefinition.Kind.BREAKABLE_PROP)
	breakable.breakable_health = 8.0
	breakable.breakable_secret_id = &"wall_drop"
	var breakable_interaction := _spawn_interaction(breakable)
	await process_frame
	var breakable_secret_events: Array[StringName] = []
	breakable_interaction.secret_requested.connect(func(secret_id: StringName, _title: String, _source: Node) -> void: breakable_secret_events.append(secret_id))
	breakable_interaction.interact(root)
	breakable_interaction.interact(root)
	_expect(breakable_interaction.is_active(), "breakable interaction activates")
	_expect(breakable_secret_events.size() == 1, "breakable interaction emits one bounded secret request")

	var loot := _make_definition(WorldInteractionDefinition.Kind.LOOT_CONTAINER)
	loot.loot_scene = "res://scenes/pickups/treat.tscn"
	loot.loot_drop_count = 3
	var loot_interaction := _spawn_interaction(loot)
	await process_frame
	var loot_events: Array[Dictionary] = []
	loot_interaction.loot_requested.connect(func(scene: String, count: int, _source: Node) -> void: loot_events.append({"scene": scene, "count": count}))
	loot_interaction.interact(root)
	loot_interaction.interact(root)
	_expect(loot_interaction.is_active(), "loot interaction activates")
	_expect(loot_events.size() == 1, "loot interaction emits one bounded loot request")
	_expect(int(loot_events[0].get("count", 0)) == 3, "loot request carries configured count")


func _test_explosive_one_shot_chain_reactions() -> void:
	var explosive_a := _make_definition(WorldInteractionDefinition.Kind.EXPLOSIVE_PROP)
	explosive_a.explosive_health = 7.0
	explosive_a.explosive_blast_radius = 5.0
	explosive_a.explosive_damage = 18.0
	explosive_a.chain_reaction_radius = 6.0
	explosive_a.chain_reaction_limit = 1
	var explosive_b := _make_definition(WorldInteractionDefinition.Kind.EXPLOSIVE_PROP)
	explosive_b.id = &"explosive_b"
	explosive_b.explosive_health = 9.0
	explosive_b.explosive_blast_radius = 5.0
	explosive_b.explosive_damage = 18.0
	explosive_b.chain_reaction_radius = 6.0
	explosive_b.chain_reaction_limit = 1
	var explosive_c := _make_definition(WorldInteractionDefinition.Kind.EXPLOSIVE_PROP)
	explosive_c.id = &"explosive_c"
	explosive_c.explosive_health = 12.0
	explosive_c.explosive_blast_radius = 5.0
	explosive_c.explosive_damage = 18.0
	explosive_c.chain_reaction_radius = 6.0
	explosive_c.chain_reaction_limit = 1

	var a := _spawn_interaction(explosive_a)
	var b := _spawn_interaction(explosive_b)
	var c := _spawn_interaction(explosive_c)
	a.position = Vector3(-0.4, 0.0, 0.0)
	b.position = Vector3(1.0, 0.0, 0.0)
	c.position = Vector3(3.5, 0.0, 0.0)
	await process_frame

	var events := 0
	a.explosion_fired.connect(func(_origin: Vector3, _damage: float) -> void: events += 1)
	b.explosion_fired.connect(func(_origin: Vector3, _damage: float) -> void: events += 1)
	c.explosion_fired.connect(func(_origin: Vector3, _damage: float) -> void: events += 1)
	a.interact(root)
	await process_frame
	_expect(a.is_active(), "initial explosive activates")
	_expect(b.is_active(), "chain-reactive explosive activates")
	_expect(not c.is_active(), "chain reaction limit prevents third-order detonation")
	var pre_events := events
	a.interact(root)
	b.interact(root)
	_expect(events == pre_events, "explosive activations are idempotent")


func _test_hazard_ticks_with_one_timer() -> void:
	var hazard := _make_definition(WorldInteractionDefinition.Kind.HAZARD_ZONE)
	hazard.hazard_tick_seconds = 0.05
	hazard.hazard_damage = 5.0
	hazard.hazard_radius = 1.5
	var hazard_interaction := _spawn_interaction(hazard)
	var target := FakeDamageTarget.new()
	target.position = Vector3(0.2, 0.0, 0.0)
	root.add_child(target)
	await process_frame
	await create_timer(0.22).timeout
	_expect(target.damage_calls.size() >= 1, "hazard timer applies periodic overlap damage")
	var timer := hazard_interaction.get_node_or_null("HazardTick")
	_expect(timer is Timer, "hazard owns a dedicated periodic timer")
	if timer != null:
		hazard_interaction.reset_interaction()
		hazard_interaction.queue_free()
		await process_frame
		_expect(not is_instance_valid(timer), "hazard timer is cleaned on exit")


func _test_secret_snapshot_and_restore() -> void:
	var secret := _make_definition(WorldInteractionDefinition.Kind.SECRET_TRIGGER)
	secret.persists_across_reset = true
	var interaction := _spawn_interaction(secret)
	await process_frame
	var events: Array[Array] = []
	interaction.secret_requested.connect(func(_id: StringName, _title: String, _source: Node) -> void: events.append([_id]))
	interaction.interact(root)
	_expect(interaction.is_active(), "secret activates")
	_expect(events.size() == 1, "secret emits one request")
	var snapshot := interaction.snapshot_state()
	var replay := _spawn_interaction(secret)
	await process_frame
	replay.restore_state(snapshot)
	replay.secret_requested.connect(func(_id: StringName, _title: String, _source: Node) -> void: events.append([_id]))
	replay.interact(root)
	_expect(events.size() == 1, "restored persistent secret does not re-emit")
	replay.restore_state({"id": String(secret.id), "kind": int(secret.kind), "activated": false})
	replay.interact(root)
	_expect(events.size() == 2, "forced clear snapshot allows replay once")


func _test_reset_rewinds_non_persistent() -> void:
	var breakable := _make_definition(WorldInteractionDefinition.Kind.BREAKABLE_PROP)
	breakable.id = &"resets_breakable"
	var breakable_interaction := _spawn_interaction(breakable)
	await process_frame
	breakable_interaction.interact(root)
	_expect(breakable_interaction.is_active(), "non-persistent breakable activates")
	breakable_interaction.reset_interaction()
	breakable_interaction.interact(root)
	_expect(breakable_interaction.is_active(), "non-persistent breakable rewinds to authored state")

	var secret := _make_definition(WorldInteractionDefinition.Kind.SECRET_TRIGGER)
	secret.id = &"ephemeral_secret"
	secret.persists_across_reset = false
	var secret_interaction := _spawn_interaction(secret)
	await process_frame
	var events: Array[StringName] = []
	secret_interaction.secret_requested.connect(func(id: StringName, _title: String, _source: Node) -> void: events.append(id))
	secret_interaction.interact(root)
	secret_interaction.reset_interaction()
	secret_interaction.interact(root)
	_expect(events.size() == 2, "non-persistent secret interaction rewinds to allow re-discovery")


func _make_definition(kind: WorldInteractionDefinition.Kind) -> WorldInteractionDefinition:
	var definition := WorldInteractionDefinition.new()
	definition.id = &"test_interaction"
	definition.kind = kind
	definition.prompt = "INTERACT"
	definition.enabled = true
	match kind:
		WorldInteractionDefinition.Kind.BREAKABLE_PROP:
			definition.breakable_health = 10.0
			definition.breakable_secret_id = &""
		WorldInteractionDefinition.Kind.EXPLOSIVE_PROP:
			definition.explosive_health = 12.0
			definition.explosive_blast_radius = 1.8
			definition.explosive_damage = 12.0
			definition.detonation_delay = 0.0
			definition.chain_reaction_radius = 0.0
			definition.chain_reaction_limit = 0
		WorldInteractionDefinition.Kind.HAZARD_ZONE:
			definition.hazard_tick_seconds = 0.12
			definition.hazard_damage = 5.0
			definition.hazard_radius = 1.7
		WorldInteractionDefinition.Kind.LOOT_CONTAINER:
			definition.loot_scene = "res://scenes/pickups/treat.tscn"
			definition.loot_drop_count = 1
		WorldInteractionDefinition.Kind.SECRET_TRIGGER:
			definition.secret_id = &"auth_secret"
			definition.secret_title = "AUTH SECRET"
			definition.persistence_id = &"persistent_auth_secret"
			definition.persists_across_reset = true
	return definition

func _spawn_interaction(definition: WorldInteractionDefinition) -> WorldInteraction:
	var interaction := WorldInteraction.new()
	interaction.definition = definition
	interaction.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(interaction)
	return interaction


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func expect(condition: bool, label: String) -> void:
	_expect(condition, label)
