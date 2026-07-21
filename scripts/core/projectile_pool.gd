extends Node

const BOLT := preload("res://scenes/enemies/enemy_bolt.tscn")
const FETCH_PROJECTILE := preload("res://scenes/weapons/fetch_projectile.tscn")
const BOLT_CAPACITY := 16
const FETCH_PROJECTILE_CAPACITY := 8

const SUPPORTED_SCENE_CAPACITY: Dictionary = {
	BOLT.resource_path: BOLT_CAPACITY,
	FETCH_PROJECTILE.resource_path: FETCH_PROJECTILE_CAPACITY,
}

var _available_by_scene: Dictionary = {}
var _active_by_scene: Dictionary = {}
var _created_by_scene: Dictionary = {}


func _ready() -> void:
	var scene_by_path := {
		BOLT.resource_path: BOLT,
		FETCH_PROJECTILE.resource_path: FETCH_PROJECTILE,
	}
	for scene_path in SUPPORTED_SCENE_CAPACITY.keys():
		var capacity: int = int(SUPPORTED_SCENE_CAPACITY[scene_path])
		var scene: PackedScene = scene_by_path.get(scene_path, null)
		if scene == null:
			continue
		_available_by_scene[scene_path] = []
		_active_by_scene[scene_path] = []
		_created_by_scene[scene_path] = 0
		for _index in capacity:
			var projectile := _create_projectile(scene, scene_path)
			if projectile == null:
				continue
			_available_by_scene[scene_path].append(projectile)
	var router := get_node_or_null("/root/SceneRouter")
	if router != null:
		router.transition_started.connect(_release_all)


func acquire(scene: PackedScene) -> Node3D:
	if scene == null:
		return null
	var scene_path := scene.resource_path
	if scene_path.is_empty() or not SUPPORTED_SCENE_CAPACITY.has(scene_path):
		return scene.instantiate() as Node3D
	_prune_scene(scene_path)
	var available: Array = []
	var active: Array = []
	if _available_by_scene.has(scene_path):
		available = _available_by_scene[scene_path]
	if _active_by_scene.has(scene_path):
		active = _active_by_scene[scene_path]
	var projectile: Node3D
	if not available.is_empty():
		projectile = available.pop_back()
	elif scene_path == BOLT.resource_path:
		# Preserve the original enemy-bolt overflow behavior. Fetch projectiles are
		# hard-bounded and recycle the oldest active shot instead.
		projectile = _create_projectile(scene, scene_path)
	elif not active.is_empty():
		projectile = active.pop_front() as Node3D
		if projectile != null and projectile.has_method("deactivate_for_pool"):
			projectile.call("deactivate_for_pool")
	if projectile == null:
		return null
	if not active.has(projectile):
		active.append(projectile)
	if projectile != null and projectile.has_method("activate_from_pool"):
		projectile.call("activate_from_pool")
	return projectile


func release_projectile(projectile: Node3D) -> void:
	if not is_instance_valid(projectile):
		return
	if not bool(projectile.get_meta(&"projectile_pool", false)):
		return
	var scene_path: String = projectile.get_meta(&"projectile_pool_scene_path", "")
	if scene_path.is_empty() or not _available_by_scene.has(scene_path):
		return
	var active: Array = []
	var available: Array = []
	if _active_by_scene.has(scene_path):
		active = _active_by_scene[scene_path]
	if _available_by_scene.has(scene_path):
		available = _available_by_scene[scene_path]
	active.erase(projectile)
	if projectile.has_method("deactivate_for_pool"):
		projectile.call("deactivate_for_pool")
	if not available.has(projectile):
		available.append(projectile)


func available_count() -> int:
	var count := 0
	for scene_path in _available_by_scene.keys():
		count += available_count_for_scene_path(scene_path)
	return count


func available_count_for_scene(scene: PackedScene) -> int:
	if scene == null:
		return 0
	return available_count_for_scene_path(scene.resource_path)


func active_count() -> int:
	var count := 0
	for scene_path in _active_by_scene.keys():
		count += active_count_for_scene_path(scene_path)
	return count


func active_count_for_scene(scene: PackedScene) -> int:
	if scene == null:
		return 0
	return active_count_for_scene_path(scene.resource_path)


func created_count_for_scene(scene: PackedScene) -> int:
	if scene == null:
		return 0
	return int(_created_by_scene.get(scene.resource_path, 0))


func _create_projectile(scene: PackedScene, scene_path: String) -> Node3D:
	if scene == null:
		return null
	var projectile := scene.instantiate() as Node3D
	if projectile == null:
		return null
	add_child(projectile)
	projectile.set_meta(&"projectile_pool_scene_path", scene_path)
	projectile.set_meta(&"projectile_pool", true)
	if projectile.has_method("deactivate_for_pool"):
		projectile.call("deactivate_for_pool")
	else:
		projectile.process_mode = Node.PROCESS_MODE_DISABLED
		projectile.visible = false
	var created: int = int(_created_by_scene.get(scene_path, 0))
	_created_by_scene[scene_path] = created + 1
	return projectile


func available_count_for_scene_path(scene_path: String) -> int:
	if scene_path.is_empty() or not _available_by_scene.has(scene_path):
		return 0
	_prune_scene(scene_path)
	return _available_by_scene[scene_path].size()


func active_count_for_scene_path(scene_path: String) -> int:
	if scene_path.is_empty() or not _active_by_scene.has(scene_path):
		return 0
	_prune_scene(scene_path)
	return _active_by_scene[scene_path].size()


func _prune_scene(scene_path: String) -> void:
	var available: Array = []
	if _available_by_scene.has(scene_path):
		available = _available_by_scene[scene_path]
	for index in range(available.size() - 1, -1, -1):
		if not is_instance_valid(available[index]):
			available.remove_at(index)
	var active: Array = []
	if _active_by_scene.has(scene_path):
		active = _active_by_scene[scene_path]
	for index in range(active.size() - 1, -1, -1):
		if not is_instance_valid(active[index]):
			active.remove_at(index)


func _release_all(_scene_path := "") -> void:
	if not _scene_path.is_empty() and _active_by_scene.has(_scene_path):
		var active: Array = []
		active = _active_by_scene[_scene_path]
		for projectile in active.duplicate():
			if is_instance_valid(projectile):
				release_projectile(projectile)
		return
	for scene_path in _active_by_scene.keys():
		var scene_active: Array = []
		if _active_by_scene.has(scene_path):
			scene_active = _active_by_scene[scene_path]
		for projectile in scene_active.duplicate():
			if is_instance_valid(projectile):
				release_projectile(projectile)
