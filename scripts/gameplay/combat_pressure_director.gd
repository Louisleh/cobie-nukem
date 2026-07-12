extends Node

signal pressure_changed(active_attackers: int, maximum_attackers: int)

var maximum_attackers := 3
var _tokens: Dictionary = {}

func request_attack(actor: Node, priority := 0) -> bool:
	_prune()
	if not is_instance_valid(actor): return false
	var id := actor.get_instance_id()
	if _tokens.has(id): return true
	if _tokens.size() >= maximum_attackers and priority < 10: return false
	_tokens[id] = actor
	pressure_changed.emit(_tokens.size(), maximum_attackers)
	return true

func release_attack(actor: Node) -> void:
	if not is_instance_valid(actor): return
	if _tokens.erase(actor.get_instance_id()): pressure_changed.emit(_tokens.size(), maximum_attackers)

func reset() -> void:
	_tokens.clear()
	pressure_changed.emit(0, maximum_attackers)

func _prune() -> void:
	var stale: Array = []
	for id in _tokens:
		if not is_instance_valid(_tokens[id]): stale.append(id)
	for id in stale: _tokens.erase(id)
