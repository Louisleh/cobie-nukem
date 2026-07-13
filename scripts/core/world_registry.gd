extends Node

## Event-driven indexes for frequently queried world actors. Gameplay systems
## must use this registry instead of scanning SceneTree groups every frame.

var _interactables: Dictionary = {}
var _targets: Dictionary = {}
var _players: Dictionary = {}
var _interactable_nodes: Array[Node] = []
var _target_nodes: Array[Node] = []
var _player_nodes: Array[Node] = []


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
	if not is_instance_valid(node): return
	var id := node.get_instance_id()
	if _interactables.has(id): return
	_interactables[id] = node
	_interactable_nodes.append(node)


func register_target(node: Node) -> void:
	if not is_instance_valid(node): return
	var id := node.get_instance_id()
	if _targets.has(id): return
	_targets[id] = node
	_target_nodes.append(node)


func register_player(node: Node) -> void:
	if not is_instance_valid(node): return
	var id := node.get_instance_id()
	if _players.has(id): return
	_players[id] = node
	_player_nodes.append(node)


func unregister(node: Node) -> void:
	if node == null: return
	var id := node.get_instance_id()
	_interactables.erase(id)
	_targets.erase(id)
	_players.erase(id)
	_interactable_nodes.erase(node)
	_target_nodes.erase(node)
	_player_nodes.erase(node)


func interactables() -> Array[Node]:
	return _interactable_nodes.duplicate()


## Read-only hot-path views. Callers must never mutate the returned arrays.
func interactables_view() -> Array[Node]:
	return _interactable_nodes


func targets() -> Array[Node]:
	return _target_nodes.duplicate()


func targets_view() -> Array[Node]:
	return _target_nodes


func players() -> Array[Node]:
	return _player_nodes.duplicate()


func players_view() -> Array[Node]:
	return _player_nodes


func primary_player() -> Node3D:
	for node in _player_nodes:
		if node is Node3D:
			return node
	return null


func clear_scene_indexes() -> void:
	_interactables.clear()
	_targets.clear()
	_players.clear()
	_interactable_nodes.clear()
	_target_nodes.clear()
	_player_nodes.clear()


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
