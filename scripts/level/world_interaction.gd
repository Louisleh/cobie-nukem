extends Area3D
class_name WorldInteraction

signal interaction_activated(interaction: WorldInteraction)
signal interaction_completed(interaction_id: StringName, kind: int)
signal secret_requested(secret_id: StringName, title: String, source: Node)
signal loot_requested(loot_scene: String, count: int, source: Node)
signal explosion_fired(origin: Vector3, damage: float)
signal chain_reaction_dispatched(from_interaction: StringName, to_interaction: StringName, remaining_budget: int)
signal hazardous_tick_damaged(targets: int)

@export var definition: WorldInteractionDefinition

var _validation_errors: PackedStringArray = PackedStringArray()
var _activated := false
var _current_health := 0.0
var _hazard_timer: Timer
var _hazard_targets: Dictionary = {}
var _collision_shape_added := false


func _ready() -> void:
	add_to_group(&"interactables")
	_apply_definition()


func _exit_tree() -> void:
	if _hazard_timer != null and is_instance_valid(_hazard_timer):
		_hazard_timer.queue_free()
	_hazard_bodies_clear()


func get_interaction_label() -> String:
	if not _can_interact(null):
		return ""
	if definition.kind == WorldInteractionDefinition.Kind.HAZARD_ZONE:
		return ""
	if _activated:
		return ""
	return definition.prompt


func can_interact(_actor: Node) -> bool:
	return _can_interact(_actor)


func interact(actor: Node) -> bool:
	if not _can_interact(actor):
		return false
	match definition.kind:
		WorldInteractionDefinition.Kind.BREAKABLE_PROP:
			_activate_breakable(actor)
			return true
		WorldInteractionDefinition.Kind.EXPLOSIVE_PROP:
			_activate_explosive(actor, global_position)
			return true
		WorldInteractionDefinition.Kind.LOOT_CONTAINER:
			_activate_loot(actor)
			return true
		WorldInteractionDefinition.Kind.SECRET_TRIGGER:
			_activate_secret(actor)
			return true
		WorldInteractionDefinition.Kind.HAZARD_ZONE:
			return false
	return false


func apply_damage(amount: float, source: Node = null, hit_position: Vector3 = Vector3.ZERO) -> float:
	if not _is_authorized() or amount <= 0.0 or _activated:
		return 0.0
	match definition.kind:
		WorldInteractionDefinition.Kind.BREAKABLE_PROP:
			var applied := minf(_current_health, amount)
			_current_health -= applied
			if _current_health <= 0.0:
				_activate_breakable(source)
			return applied
		WorldInteractionDefinition.Kind.EXPLOSIVE_PROP:
			_current_health -= amount
			if _current_health <= 0.0:
				_activate_explosive(source, hit_position)
			return amount
		_:
			return 0.0
	return 0.0


func receive_chain_reaction(source: Node, remaining_budget: int) -> void:
	if remaining_budget <= 0:
		return
	if not _is_authorized() or definition.kind != WorldInteractionDefinition.Kind.EXPLOSIVE_PROP:
		return
	if _activated:
		return
	_activate_explosive(source, global_position, remaining_budget - 1)


func snapshot_state() -> Dictionary:
	if definition == null:
		return {}
	var payload := {
		"id": String(definition.id),
		"kind": int(definition.kind),
		"activated": _activated,
	}
	if definition.kind in [WorldInteractionDefinition.Kind.BREAKABLE_PROP, WorldInteractionDefinition.Kind.EXPLOSIVE_PROP]:
		payload["current_health"] = _current_health
	if definition.kind == WorldInteractionDefinition.Kind.SECRET_TRIGGER and definition.persists_across_reset:
		payload["persistence_id"] = String(definition.canonical_persistence_id())
	return payload


func restore_state(payload: Dictionary) -> void:
	if definition == null or String(payload.get("id", "")) != String(definition.id):
		return
	if int(payload.get("kind", -1)) != int(definition.kind):
		return
	if definition.kind == WorldInteractionDefinition.Kind.SECRET_TRIGGER and definition.persists_across_reset:
		_activated = bool(payload.get("activated", false))
	else:
		_activated = false
	_current_health = definition.reset_health() if definition.kind in [WorldInteractionDefinition.Kind.BREAKABLE_PROP, WorldInteractionDefinition.Kind.EXPLOSIVE_PROP] else 0.0
	_apply_authoring_state()


func reset_interaction() -> void:
	if definition == null:
		return
	if definition.kind != WorldInteractionDefinition.Kind.SECRET_TRIGGER or not definition.persists_across_reset:
		_activated = false
	_current_health = definition.reset_health() if definition.kind in [WorldInteractionDefinition.Kind.BREAKABLE_PROP, WorldInteractionDefinition.Kind.EXPLOSIVE_PROP] else 0.0
	if definition.kind == WorldInteractionDefinition.Kind.HAZARD_ZONE:
		_hazard_bodies_clear()
		_setup_hazard_timer()
	_apply_authoring_state()


func is_active() -> bool:
	return _activated


func _apply_definition() -> void:
	if definition == null:
		push_warning("WorldInteraction missing authoring definition")
		set_process(false)
		return
	_validation_errors = definition.validate()
	if not _validation_errors.is_empty():
		for entry in _validation_errors:
			push_warning("WorldInteraction validation failed: %s" % entry)
		set_process(false)
		monitoring = false
		return
	_collision_shape_added = false
	_ensure_collision_shape()
	_ensure_visual_if_empty()
	_current_health = definition.reset_health() if definition.kind in [WorldInteractionDefinition.Kind.BREAKABLE_PROP, WorldInteractionDefinition.Kind.EXPLOSIVE_PROP] else 0.0
	_activated = false
	_apply_authoring_state()
	if definition.kind == WorldInteractionDefinition.Kind.HAZARD_ZONE:
		_setup_hazard_mode()
	else:
		if _hazard_timer != null and is_instance_valid(_hazard_timer):
			_hazard_timer.queue_free()
		_hazard_bodies_clear()
		monitoring = true


func _activate_breakable(actor: Node) -> void:
	if _activated:
		return
	_activated = true
	if definition.breakable_secret_id != &"":
		secret_requested.emit(definition.breakable_secret_id, definition.breakable_secret_title, actor)
	interaction_activated.emit(self)
	interaction_completed.emit(definition.id, WorldInteractionDefinition.Kind.BREAKABLE_PROP)
	_spawn_temporary_effect()
	_apply_authoring_state()


func _activate_explosive(actor: Node, impact_position: Vector3, chain_budget: int = -1) -> void:
	if _activated:
		return
	_activated = true
	interaction_activated.emit(self)
	interaction_completed.emit(definition.id, WorldInteractionDefinition.Kind.EXPLOSIVE_PROP)
	_spawn_temporary_effect()
	explosion_fired.emit(impact_position, definition.explosive_damage)
	_perform_explosive_damage(impact_position)
	_chain_reaction(impact_position, chain_budget)
	_apply_authoring_state()


func _activate_loot(actor: Node) -> void:
	if _activated:
		return
	_activated = true
	interaction_activated.emit(self)
	interaction_completed.emit(definition.id, WorldInteractionDefinition.Kind.LOOT_CONTAINER)
	loot_requested.emit(definition.loot_scene, definition.loot_drop_count, actor)
	_spawn_temporary_effect()
	_apply_authoring_state()


func _activate_secret(actor: Node) -> void:
	if _activated:
		return
	_activated = true
	interaction_activated.emit(self)
	interaction_completed.emit(definition.id, WorldInteractionDefinition.Kind.SECRET_TRIGGER)
	secret_requested.emit(definition.secret_id, definition.secret_title, actor)
	_apply_authoring_state()


func _chain_reaction(origin: Vector3, chain_budget: int = -1) -> void:
	var budget := chain_budget
	if budget < 0:
		budget = definition.chain_reaction_limit
	if budget <= 0:
		return
	var nearby := _query_interactions(origin, definition.chain_reaction_radius)
	for neighbor in nearby:
		if neighbor == null or neighbor == self or not is_instance_valid(neighbor):
			continue
		if neighbor.definition == null or neighbor.definition.kind != WorldInteractionDefinition.Kind.EXPLOSIVE_PROP:
			continue
		if neighbor._activated:
			continue
		chain_reaction_dispatched.emit(definition.id, neighbor.definition.id, budget)
		neighbor.receive_chain_reaction(self, budget)
		return


func _perform_explosive_damage(origin: Vector3) -> void:
	var world := get_world_3d()
	if world == null:
		return
	for target in _query_hits(origin, definition.explosive_blast_radius):
		if target == self or target == null:
			continue
		if target is WorldInteraction and (target as WorldInteraction).definition != null and (target as WorldInteraction).definition.kind == WorldInteractionDefinition.Kind.EXPLOSIVE_PROP:
			continue
		if target.has_method("apply_damage"):
			target.apply_damage(definition.explosive_damage, self, origin)


func _setup_hazard_mode() -> void:
	if not is_connected(&"body_entered", Callable(self, "_on_hazard_body_entered")):
		body_entered.connect(_on_hazard_body_entered)
	if not is_connected(&"body_exited", Callable(self, "_on_hazard_body_exited")):
		body_exited.connect(_on_hazard_body_exited)
	_setup_hazard_timer()


func _setup_hazard_timer() -> void:
	if _hazard_timer != null and is_instance_valid(_hazard_timer):
		_hazard_timer.queue_free()
	if definition == null:
		return
	_hazard_timer = Timer.new()
	_hazard_timer.name = "HazardTick"
	_hazard_timer.one_shot = false
	_hazard_timer.wait_time = maxf(0.05, definition.hazard_tick_seconds)
	_hazard_timer.autostart = true
	_hazard_timer.timeout.connect(_on_hazard_tick)
	add_child(_hazard_timer)
	_hazard_timer.start()


func _on_hazard_body_entered(body: Node) -> void:
	if body is Node3D:
		_hazard_targets[body.get_instance_id()] = body


func _on_hazard_body_exited(body: Node) -> void:
	if body is Node3D:
		_hazard_targets.erase(body.get_instance_id())


func _on_hazard_tick() -> void:
	if definition == null or not _is_authorized() or definition.kind != WorldInteractionDefinition.Kind.HAZARD_ZONE:
		return
	var hit_count := 0
	for key in _hazard_targets.keys():
		var body := _hazard_targets[key] as Node3D
		if body == null or not is_instance_valid(body):
			_hazard_targets.erase(key)
			continue
		if body.global_position.distance_to(global_position) > definition.hazard_radius:
			continue
		if body.has_method("apply_damage"):
			body.apply_damage(definition.hazard_damage, self, global_position)
			hit_count += 1
	hazardous_tick_damaged.emit(hit_count)


func _query_hits(origin: Vector3, radius: float) -> Array:
	var world := get_world_3d()
	if world == null:
		return []
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis(), origin)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	var raw_hits := world.direct_space_state.intersect_shape(query, 64)
	var dedupe := Dictionary()
	var result: Array = []
	for hit in raw_hits:
		var node := hit.get("collider") as Node
		if node == null:
			continue
		var key := node.get_instance_id()
		if dedupe.has(key):
			continue
		dedupe[key] = true
		result.append(node)
	return result


func _query_interactions(origin: Vector3, radius: float) -> Array[WorldInteraction]:
	var interactions: Array[WorldInteraction] = []
	for node in get_tree().get_nodes_in_group(&"interactables"):
		var interaction := node as WorldInteraction
		if interaction == null or interaction == self or not is_instance_valid(interaction):
			continue
		if interaction.global_position.distance_to(origin) > radius:
			continue
		interactions.append(interaction)
	return interactions


func _apply_authoring_state() -> void:
	if definition == null:
		return
	if definition.kind == WorldInteractionDefinition.Kind.HAZARD_ZONE:
		monitoring = true
		return
	if _activated:
		monitoring = false
	else:
		monitoring = true


func _can_interact(_actor: Node) -> bool:
	if definition == null:
		return false
	if not _validation_errors.is_empty():
		return false
	if not definition.enabled:
		return false
	if definition.kind == WorldInteractionDefinition.Kind.HAZARD_ZONE:
		return false
	if _activated:
		return false
	return true


func _is_authorized() -> bool:
	return definition != null and _validation_errors.is_empty() and definition.enabled


func _ensure_collision_shape() -> void:
	if _collision_shape_added:
		return
	for child in get_children():
		if child is CollisionShape3D:
			_collision_shape_added = true
			return
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(1.1, 1.1, 1.1)
	add_child(shape)
	_collision_shape_added = true


func _ensure_visual_if_empty() -> void:
	var has_mesh := false
	for child in get_children():
		if child is MeshInstance3D:
			has_mesh = true
			break
	if has_mesh:
		return
	var visual := MeshInstance3D.new()
	visual.mesh = BoxMesh.new()
	visual.position = Vector3.ZERO
	add_child(visual)
	(visual.mesh as BoxMesh).size = Vector3(1.1, 1.1, 1.1)


func _spawn_temporary_effect() -> void:
	if definition == null:
		return
	var marker := MeshInstance3D.new()
	marker.mesh = SphereMesh.new()
	(marker.mesh as SphereMesh).radius = 0.35
	(marker.mesh as SphereMesh).height = 0.7
	marker.position = Vector3.ZERO
	add_child(marker)
	var quality := get_node_or_null("/root/QualityManager")
	if quality != null:
		quality.claim_temporary_effect(marker)
	else:
		var cleanup := Timer.new()
		cleanup.name = "TemporaryEffectCleanup"
		cleanup.one_shot = true
		cleanup.wait_time = 0.45
		cleanup.timeout.connect(marker.queue_free)
		cleanup.timeout.connect(cleanup.queue_free)
		add_child(cleanup)
		cleanup.start()


func _hazard_bodies_clear() -> void:
	_hazard_targets.clear()
