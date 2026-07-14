class_name MissionRuntime
extends Node

## Reusable mission truth. Level scripts author narrative and geometry; this node
## owns objective/encounter lifecycle and the checkpoint-safe snapshot contract.

signal objective_activated(definition: ObjectiveDefinition)
signal objective_completed(definition: ObjectiveDefinition)
signal actor_spawned(actor: Node, definition: EncounterDefinition)
signal actor_defeated(actor: Node, definition: EncounterDefinition)
signal encounter_completed(definition: EncounterDefinition)
signal encounter_failed(definition: EncounterDefinition, reason: String)

var objectives: ObjectiveTracker
var encounters: EncounterRunner
var _announced_objectives: Dictionary = {}
var _has_announced_available_objectives := false


func configure(manifest: ContentManifest, spawner: Callable) -> void:
	if is_instance_valid(objectives):
		objectives.free()
	if is_instance_valid(encounters):
		encounters.free()
	objectives = ObjectiveTracker.new()
	objectives.name = "ObjectiveTracker"
	add_child(objectives)
	encounters = EncounterRunner.new()
	encounters.name = "EncounterRunner"
	add_child(encounters)
	objectives.configure(manifest.objectives if manifest != null else [])
	encounters.configure(manifest.encounters if manifest != null else [], spawner)
	_bind_signal_forwards()
	_announced_objectives.clear()
	_has_announced_available_objectives = false


func announce_available_objectives() -> Array[StringName]:
	var announced: Array[StringName] = []
	if objectives == null:
		return announced
	for definition in objectives.active_objectives():
		if _announced_objectives.has(definition.id):
			continue
		_announced_objectives[definition.id] = true
		objective_activated.emit(definition)
		announced.append(definition.id)
	_has_announced_available_objectives = true
	return announced


func record_objective(kind: ObjectiveDefinition.Kind, target_id: StringName, amount := 1) -> Array[StringName]:
	if objectives == null:
		return []
	return objectives.record(kind, target_id, amount)


func activate_zone(zone_id: StringName, target: Node3D = null) -> Array[Node]:
	if encounters == null:
		return []
	return encounters.activate_zone(zone_id, target)


func reset_zone(zone_id: StringName) -> bool:
	if encounters == null:
		return false
	return encounters.reset_zone(zone_id)


func snapshot() -> Dictionary:
	if objectives == null or encounters == null:
		return {"objective_snapshot": {}, "encounter_snapshot": {}}
	return {
		"objective_snapshot": objectives.snapshot(),
		"encounter_snapshot": encounters.snapshot(),
	}


func restore(data: Dictionary) -> void:
	if objectives == null or encounters == null:
		return
	_announced_objectives.clear()
	_has_announced_available_objectives = false
	objectives.restore(data.get("objective_snapshot", {}))
	encounters.restore(data.get("encounter_snapshot", {}))


func _bind_signal_forwards() -> void:
	if objectives == null or encounters == null:
		return
	objectives.objective_activated.connect(_on_objective_activated)
	objectives.objective_completed.connect(_on_objective_completed)
	encounters.actor_spawned.connect(_on_actor_spawned)
	encounters.actor_defeated.connect(_on_actor_defeated)
	encounters.encounter_completed.connect(_on_encounter_completed)
	encounters.encounter_failed.connect(_on_encounter_failed)


func _on_objective_activated(definition: ObjectiveDefinition) -> void:
	if _announced_objectives.has(definition.id):
		return
	if not _has_announced_available_objectives:
		return
	_announced_objectives[definition.id] = true
	objective_activated.emit(definition)


func _on_objective_completed(definition: ObjectiveDefinition) -> void:
	objective_completed.emit(definition)


func _on_actor_spawned(actor: Node, definition: EncounterDefinition) -> void:
	actor_spawned.emit(actor, definition)


func _on_actor_defeated(actor: Node, definition: EncounterDefinition) -> void:
	actor_defeated.emit(actor, definition)


func _on_encounter_completed(definition: EncounterDefinition) -> void:
	encounter_completed.emit(definition)


func _on_encounter_failed(definition: EncounterDefinition, reason: String) -> void:
	encounter_failed.emit(definition, reason)
