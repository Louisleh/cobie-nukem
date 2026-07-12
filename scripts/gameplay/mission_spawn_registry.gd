class_name MissionSpawnRegistry
extends Node

## Mission-scoped ownership index used for reset, diagnostics, and leak checks.

var completed_zones: Dictionary = {}
var enemies: Dictionary = {}
var pickups: Dictionary = {}
var critical_objects: Dictionary = {}


func mark_zone_spawned(zone_id: StringName) -> bool:
	if completed_zones.has(zone_id): return false
	completed_zones[zone_id] = true
	return true


func clear_zone(zone_id: StringName) -> void:
	completed_zones.erase(zone_id)


func register_actor(actor: Node) -> void:
	if not is_instance_valid(actor): return
	var key := actor.get_instance_id()
	if actor is EnemyAgent: enemies[key] = actor
	elif actor is CombatPickup: pickups[key] = actor


func register_critical(id: StringName, object: Node) -> void:
	if is_instance_valid(object): critical_objects[id] = object


func temporary_counts() -> Dictionary:
	_prune(enemies); _prune(pickups); _prune(critical_objects)
	return {"enemies": enemies.size(), "pickups": pickups.size(), "critical": critical_objects.size()}


func _prune(index: Dictionary) -> void:
	for key: Variant in index.keys():
		if not is_instance_valid(index[key]): index.erase(key)
