extends Node

## Event-driven indexes for frequently queried world actors. Gameplay systems
## must use this registry instead of scanning SceneTree groups every frame.

var _interactables: Dictionary = {}
var _targets: Dictionary = {}
var _players: Dictionary = {}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)
	for node in get_tree().get_nodes_in_group(&"interactables"):
		register_interactable(node)
	for node in get_tree().get_nodes_in_group(&"auto_aim_targets"):
		register_target(node)
	for node in get_tree().get_nodes_in_group(&"player"):
		register_player(node)


func register_interactable(node: Node) -> void:
	if is_instance_valid(node): _interactables[node.get_instance_id()] = node


func register_target(node: Node) -> void:
	if is_instance_valid(node): _targets[node.get_instance_id()] = node


func register_player(node: Node) -> void:
	if is_instance_valid(node): _players[node.get_instance_id()] = node


func unregister(node: Node) -> void:
	if not is_instance_valid(node): return
	var id := node.get_instance_id()
	_interactables.erase(id)
	_targets.erase(id)
	_players.erase(id)


func interactables() -> Array[Node]:
	return _valid_nodes(_interactables)


func targets() -> Array[Node]:
	return _valid_nodes(_targets)


func players() -> Array[Node]:
	return _valid_nodes(_players)


func primary_player() -> Node3D:
	for node in _valid_nodes(_players):
		if node is Node3D:
			return node
	return null


func clear_scene_indexes() -> void:
	_interactables.clear()
	_targets.clear()
	_players.clear()


func _on_node_added(node: Node) -> void:
	# Groups are commonly assigned in _ready(), after node_added is emitted.
	_consider_instance.call_deferred(node.get_instance_id())


func _consider_instance(instance_id: int) -> void:
	var node := instance_from_id(instance_id) as Node
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	if node.is_in_group(&"interactables"): register_interactable(node)
	if node.is_in_group(&"auto_aim_targets"): register_target(node)
	if node.is_in_group(&"player"): register_player(node)


func _on_node_removed(node: Node) -> void:
	if node != null: unregister(node)


func _valid_nodes(index: Dictionary) -> Array[Node]:
	var result: Array[Node] = []
	var stale: Array = []
	for id in index:
		var node := index[id] as Node
		if not is_instance_valid(node) or not node.is_inside_tree():
			stale.append(id)
		else:
			result.append(node)
	for id in stale: index.erase(id)
	return result
