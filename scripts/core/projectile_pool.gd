extends Node

const BOLT := preload("res://scenes/enemies/enemy_bolt.tscn")
const BOLT_CAPACITY := 16

var _available_bolts: Array[EnemyProjectile] = []
var _active_bolts: Array[EnemyProjectile] = []


func _ready() -> void:
	for _index in BOLT_CAPACITY:
		_available_bolts.append(_create_bolt())
	var router := get_node_or_null("/root/SceneRouter")
	if router != null:
		router.transition_started.connect(_release_all)


func acquire(scene: PackedScene) -> Node3D:
	if scene == null or scene.resource_path != BOLT.resource_path:
		return scene.instantiate() as Node3D if scene != null else null
	_prune()
	var projectile: EnemyProjectile = _available_bolts.pop_back() if not _available_bolts.is_empty() else _create_bolt()
	if not _active_bolts.has(projectile):
		_active_bolts.append(projectile)
	projectile.activate_from_pool()
	return projectile


func release_projectile(projectile: EnemyProjectile) -> void:
	if not is_instance_valid(projectile):
		return
	projectile.deactivate_for_pool()
	_active_bolts.erase(projectile)
	if not _available_bolts.has(projectile):
		_available_bolts.append(projectile)


func available_count() -> int:
	_prune()
	return _available_bolts.size()


func _create_bolt() -> EnemyProjectile:
	var projectile := BOLT.instantiate() as EnemyProjectile
	add_child(projectile)
	projectile.set_meta(&"projectile_pool", true)
	projectile.deactivate_for_pool()
	return projectile


func _prune() -> void:
	for index in range(_available_bolts.size() - 1, -1, -1):
		if not is_instance_valid(_available_bolts[index]):
			_available_bolts.remove_at(index)
	for index in range(_active_bolts.size() - 1, -1, -1):
		if not is_instance_valid(_active_bolts[index]):
			_active_bolts.remove_at(index)


func _release_all(_scene_path := "") -> void:
	for projectile in _active_bolts.duplicate():
		if is_instance_valid(projectile):
			release_projectile(projectile)
