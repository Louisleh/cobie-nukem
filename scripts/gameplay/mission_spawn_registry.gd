class_name MissionSpawnRegistry
extends Node

signal pickup_collected(message: String)

const MIN_LOOT_DROPS := 1
const MAX_LOOT_DROPS := 8

@export var actor_parent: Node3D

## Mission-scoped ownership index used for reset, diagnostics, and leak checks.
var completed_zones: Dictionary = {}
var enemies: Dictionary = {}
var pickups: Dictionary = {}
var critical_objects: Dictionary = {}
var _drop_connected_actors: Dictionary = {}
var _opening_enemies: Array[Node] = []
var _opening_enemies_awake := false
var _opening_target: Node3D
var _staged_zone_id: StringName = &""
var enemies_total := 0
var enemies_defeated := 0
var retry_encounter_spawns: Dictionary = {}
var zone_author_spawns: Dictionary = {}
var _counted_spawn_slots: Dictionary = {}
var _retry_zones: Dictionary = {}
var _scene_cache: Dictionary = {}
var _counted_encounter_enemies: Dictionary = {}


func _init() -> void:
	_clear_runtime_state()


func configure(parent: Node3D = null, encounter_definitions: Array[EncounterDefinition] = []) -> void:
	actor_parent = parent
	_clear_runtime_state()
	prewarm_encounters(encounter_definitions)


func configure_staged_zone(zone_id: StringName) -> void:
	_staged_zone_id = zone_id


func prepare_encounter(definition: EncounterDefinition, is_retry: bool) -> void:
	if definition == null:
		return
	var zone_id := definition.zone_id
	if is_retry:
		_retry_zones[zone_id] = true
		return
	_retry_zones.erase(zone_id)


func finish_encounter(zone_id: StringName) -> void:
	_retry_zones.erase(zone_id)


func clear_runtime_state() -> void:
	_clear_runtime_state()
	_scene_cache.clear()


func prewarm_encounters(definitions: Array[EncounterDefinition]) -> void:
	# Encounter actors must be ready before combat begins. Resolving these scene
	# strings during the mission's load phase avoids first-shot/first-wave stalls
	# when a new enemy family or the Walker is instantiated later in the route.
	for definition in definitions:
		for wave in definition.effective_waves():
			for spawn in wave.get("spawns", []):
				var path := String(spawn.get("scene", ""))
				if not path.is_empty():
					resolve_scene(path)


func resolve_scene(path: String) -> PackedScene:
	if _scene_cache.has(path):
		return _scene_cache[path] as PackedScene
	var packed := load(path) as PackedScene if ResourceLoader.exists(path, "PackedScene") else null
	if packed != null:
		_scene_cache[path] = packed
	return packed


func mark_zone_spawned(zone_id: StringName) -> bool:
	if completed_zones.has(zone_id): return false
	completed_zones[zone_id] = true
	return true


func clear_zone(zone_id: StringName) -> void:
	completed_zones.erase(zone_id)


func register_actor(actor: Node) -> bool:
	# Actor registration is centralised so restart and cleanup routines can
	# prune and account defeated enemies safely across respawns.
	if not is_instance_valid(actor):
		return false
	var key := actor.get_instance_id()
	if actor is EnemyAgent:
		if enemies.has(key):
			return false
		enemies[key] = actor
		return true
	if actor is CombatPickup:
		if pickups.has(key):
			return false
		pickups[key] = actor
		return true
	return false


func register_critical(id: StringName, object: Node) -> void:
	if is_instance_valid(object): critical_objects[id] = object


func register_encounter_actor(actor: Node, definition: EncounterDefinition, is_retry: bool = false) -> void:
	if actor == null:
		return
	register_actor(actor)
	var zone_id := String(definition.zone_id if definition != null else &"")
	var effective_retry := is_retry or _retry_zones.has(definition.zone_id if definition != null else &"")
	if effective_retry:
		retry_encounter_spawns[zone_id] = int(retry_encounter_spawns.get(zone_id, 0)) + 1
	if actor is EnemyAgent:
		var enemy_key := actor.get_instance_id()
		var was_counted := _counted_encounter_enemies.has(enemy_key)
		_bind_enemy_drop_once(actor)
		if not was_counted:
			_counted_encounter_enemies[enemy_key] = true
		var spawn_slot := String(actor.get_meta(&"encounter_spawn_slot", ""))
		if not spawn_slot.is_empty() and not _counted_spawn_slots.has(spawn_slot):
			_counted_spawn_slots[spawn_slot] = true
			enemies_total += 1
			zone_author_spawns[zone_id] = int(zone_author_spawns.get(zone_id, 0)) + 1
	if actor is EnemyAgent and definition != null and definition.zone_id == _staged_zone_id:
		if _opening_enemies_awake:
			_activate_opening_enemy(actor, _opening_target)
			return
		if actor is Node3D:
			(actor as Node3D).process_mode = Node.PROCESS_MODE_DISABLED
		_stage_opening_enemy(actor)


func spawn_scene(path: String, position_value: Vector3) -> Node:
	if not is_instance_valid(actor_parent):
		push_warning("MissionSpawnRegistry actor parent missing; cannot place spawn %s" % path)
		return null
	if not ResourceLoader.exists(path):
		push_warning("Optional level dependency missing: " + path)
		return null
	var packed := resolve_scene(path)
	if packed == null:
		return null
	var instance := packed.instantiate()
	# Place actors before _ready() so hover origins, drone flight heights,
	# and physics interpolation all begin at the intended world transform.
	if instance is Node3D:
		instance.position = position_value
	actor_parent.add_child(instance)
	register_actor(instance)
	return instance


func spawn_pickup(path: String, position_value: Vector3) -> Node:
	var pickup := spawn_scene(path, position_value)
	var typed_pickup := pickup as CombatPickup
	if typed_pickup == null:
		return pickup
	if not typed_pickup.is_connected(&"collected", _on_pickup_collected):
		typed_pickup.collected.connect(_on_pickup_collected)
	return typed_pickup


func spawn_enemy_drop(drop_id: StringName, position_value: Vector3) -> Node:
	var path := "res://scenes/pickups/%s.tscn" % String(drop_id)
	if not ResourceLoader.exists(path, "PackedScene"):
		push_warning("Enemy drop has no pickup scene: %s" % drop_id)
		return null
	return spawn_pickup(path, position_value + Vector3.UP * 0.8)


func spawn_loot_burst(loot_scene: String, count: int, actor: Node3D, fallback_player: Node3D = null) -> Array[Node]:
	var safe_count := clampi(count, MIN_LOOT_DROPS, MAX_LOOT_DROPS)
	var source_position := Vector3.ZERO
	if is_instance_valid(actor):
		source_position = actor.global_position
	elif is_instance_valid(fallback_player):
		source_position = fallback_player.global_position
	var spawned: Array[Node] = []
	for index in safe_count:
		var angle := TAU * float(index) / float(max(safe_count, 1))
		var radius := 0.72 + 0.14 * float(index % 4)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
		var drop_position := Vector3(source_position.x + offset.x, max(0.8, source_position.y), source_position.z + offset.z)
		var avoid_player := fallback_player if is_instance_valid(fallback_player) else actor
		if avoid_player != null and drop_position.distance_to(avoid_player.global_position) < 0.4:
			drop_position += Vector3(0.36, 0.0, 0.36)
		spawned.append(spawn_pickup(loot_scene, drop_position))
	return spawned


func activate_staged_enemies(target: Node3D) -> void:
	if _opening_enemies_awake:
		return
	_opening_enemies_awake = true
	_opening_target = target
	for enemy in _opening_enemies:
		_activate_opening_enemy(enemy, target)


func reset_staged_enemies() -> void:
	_opening_enemies_awake = false
	_opening_target = null
	_opening_enemies.clear()


func record_enemy_defeat() -> int:
	enemies_defeated = mini(enemies_defeated + 1, enemies_total)
	return enemies_defeated


func temporary_counts() -> Dictionary:
	_prune(enemies)
	_prune(pickups)
	_prune(critical_objects)
	_prune_opening_enemies()
	_prune_drop_bindings()
	return {
		"enemies": enemies.size(),
		"pickups": pickups.size(),
		"critical": critical_objects.size(),
		"opening_enemies": _opening_enemies.size(),
		"enemies_total": enemies_total,
		"enemies_defeated": enemies_defeated,
	}


func opening_enemies_snapshot() -> Array[Node]:
	_prune_opening_enemies()
	return _opening_enemies.duplicate()


func opening_enemies_active() -> bool:
	return _opening_enemies_awake


func zone_author_count(zone_id: StringName) -> int:
	return int(zone_author_spawns.get(String(zone_id), 0))


func zone_retry_count(zone_id: StringName) -> int:
	return int(retry_encounter_spawns.get(String(zone_id), 0))


func _prune(index: Dictionary) -> void:
	for key: Variant in index.keys():
		if not is_instance_valid(index[key]):
			index.erase(key)


func _prune_opening_enemies() -> void:
	if _opening_enemies.is_empty():
		return
	var active: Array[Node] = []
	for enemy in _opening_enemies:
		if is_instance_valid(enemy):
			active.append(enemy)
	_opening_enemies = active
	if _opening_enemies.is_empty():
		_opening_enemies_awake = false


func _prune_drop_bindings() -> void:
	if _drop_connected_actors.is_empty():
		return
	for key in _drop_connected_actors.keys():
		var actor: Variant = _drop_connected_actors[key]
		if not is_instance_valid(actor):
			_drop_connected_actors.erase(key)


func _bind_enemy_drop_once(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy) or not enemy.has_signal(&"drop_requested"):
		return
	var key := str(enemy.get_instance_id())
	if _drop_connected_actors.has(key):
		return
	enemy.drop_requested.connect(spawn_enemy_drop)
	_drop_connected_actors[key] = enemy


func _stage_opening_enemy(enemy: Node) -> void:
	if not _opening_enemies.has(enemy):
		_opening_enemies.append(enemy)


func _activate_opening_enemy(enemy: Node, target: Node3D) -> void:
	if not is_instance_valid(enemy):
		return
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	if is_instance_valid(target) and enemy.has_method("set_target"):
		enemy.set_target(target)


func _on_pickup_collected(_pickup: CombatPickup, _collector: Node, message: String) -> void:
	pickup_collected.emit(message)


func _clear_runtime_state() -> void:
	completed_zones.clear()
	_drop_connected_actors.clear()
	_counted_encounter_enemies.clear()
	_counted_spawn_slots.clear()
	_retry_zones.clear()
	_opening_enemies.clear()
	_opening_enemies_awake = false
	_opening_target = null
	enemies.clear()
	pickups.clear()
	critical_objects.clear()
	retry_encounter_spawns.clear()
	zone_author_spawns.clear()
	enemies_total = 0
	enemies_defeated = 0
