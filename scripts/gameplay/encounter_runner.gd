class_name EncounterRunner
extends Node

signal encounter_started(definition: EncounterDefinition)
signal actor_spawned(actor: Node, definition: EncounterDefinition)
signal actor_defeated(actor: Node, definition: EncounterDefinition)
signal encounter_completed(definition: EncounterDefinition)

var definitions: Dictionary = {}
var active: Dictionary = {}
var completed: Dictionary = {}
var spawn_callable: Callable


func configure(values: Array[EncounterDefinition], spawner: Callable) -> void:
	definitions.clear()
	active.clear()
	completed.clear()
	spawn_callable = spawner
	for definition in values: definitions[definition.zone_id] = definition


func activate_zone(zone_id: StringName, target: Node3D = null) -> Array[Node]:
	if active.has(zone_id) or completed.has(zone_id) or not definitions.has(zone_id): return []
	var definition: EncounterDefinition = definitions[zone_id]
	active[zone_id] = {"remaining": 0}
	encounter_started.emit(definition)
	var actors: Array[Node] = []
	for spawn in definition.spawns:
		var actor: Node = spawn_callable.call(String(spawn.scene), spawn.position) if spawn_callable.is_valid() else null
		if actor == null: continue
		actors.append(actor)
		active[zone_id].remaining = int(active[zone_id].remaining) + 1
		if target != null and actor.has_method("set_target"): actor.set_target(target)
		if actor.has_signal("died"):
			actor.died.connect(func(dead_actor: Node, _source: Node) -> void: _on_actor_died(dead_actor, definition), CONNECT_ONE_SHOT)
		actor_spawned.emit(actor, definition)
	if int(active[zone_id].remaining) == 0 or definition.completion_policy == EncounterDefinition.CompletionPolicy.FIRE_AND_FORGET:
		_complete(definition)
	return actors


func _on_actor_died(actor: Node, definition: EncounterDefinition) -> void:
	actor_defeated.emit(actor, definition)
	if not active.has(definition.zone_id): return
	active[definition.zone_id].remaining = maxi(0, int(active[definition.zone_id].remaining) - 1)
	if int(active[definition.zone_id].remaining) == 0: _complete(definition)


func _complete(definition: EncounterDefinition) -> void:
	active.erase(definition.zone_id)
	completed[definition.zone_id] = true
	encounter_completed.emit(definition)
