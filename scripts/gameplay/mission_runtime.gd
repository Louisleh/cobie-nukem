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
signal wave_started(definition: EncounterDefinition, wave_index: int)
signal wave_completed(definition: EncounterDefinition, wave_index: int)
signal zone_entered(zone_id: StringName, title: String)
signal route_progressed(previous: StringName, current: StringName, index: int)
signal checkpoint_available(checkpoint_id: StringName, zone_id: StringName)
signal route_completed(final_zone: StringName)

var manifest: ContentManifest
var objectives: ObjectiveTracker
var encounters: EncounterRunner
var route: MissionRouteRuntime
var _announced_objectives: Dictionary = {}
var _has_announced_available_objectives := false


func configure(manifest: ContentManifest, spawner: Callable) -> void:
	self.manifest = manifest
	if is_instance_valid(objectives):
		objectives.free()
	if is_instance_valid(encounters):
		encounters.free()
	if is_instance_valid(route):
		route.free()
	objectives = ObjectiveTracker.new()
	objectives.name = "ObjectiveTracker"
	add_child(objectives)
	encounters = EncounterRunner.new()
	encounters.name = "EncounterRunner"
	add_child(encounters)
	objectives.configure(manifest.objectives if manifest != null else [])
	encounters.configure(manifest.encounters if manifest != null else [], spawner)
	if manifest != null and manifest.route_definition != null:
		route = MissionRouteRuntime.new()
		route.name = "MissionRouteRuntime"
		add_child(route)
		if not route.configure(manifest.route_definition):
			push_error("MissionRuntime rejected route definition for %s" % manifest.level_id)
			route.free()
			route = null
	else:
		route = null
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


func advance_external_wave(zone_id: StringName) -> bool:
	if encounters == null:
		return false
	return encounters.advance_external_wave(zone_id)


func submit_actor_position(position: Vector3) -> StringName:
	return route.submit_actor_position(position) if route != null else &""


func activate_checkpoint(checkpoint_id: StringName) -> bool:
	return route.activate_checkpoint(checkpoint_id) if route != null else false


func record_campaign_completion(level_id: StringName, summary: Dictionary, save_manager: Node, difficulty_id: StringName, unlocks: Array = []) -> Error:
	if save_manager == null:
		return ERR_UNCONFIGURED
	var campaign := CampaignProgressRuntime.new()
	add_child(campaign)
	if not campaign.configure(save_manager):
		campaign.queue_free()
		return ERR_INVALID_PARAMETER
	campaign.load_progress()
	var error := campaign.record_completion(level_id, {
		"best_time_msec": int(summary.get("completion_time_msec", 0)),
		"rank": "A" if int(summary.get("secrets_found", 0)) >= int(summary.get("secrets_total", 1)) else "B",
		"difficulty": String(difficulty_id),
		"best_secrets": int(summary.get("secrets_found", 0)),
		"total_secrets": int(summary.get("secrets_total", 0)),
	}, unlocks)
	campaign.queue_free()
	return error


func snapshot() -> Dictionary:
	if objectives == null or encounters == null:
		return {"objective_snapshot": {}, "encounter_snapshot": {}, "route_snapshot": {}}
	var data := {
		"objective_snapshot": objectives.snapshot(),
		"encounter_snapshot": encounters.snapshot(),
	}
	data["route_snapshot"] = route.snapshot() if route != null else {}
	return data


func restore(data: Dictionary) -> void:
	if objectives == null or encounters == null:
		return
	_announced_objectives.clear()
	_has_announced_available_objectives = false
	objectives.restore(data.get("objective_snapshot", {}))
	encounters.restore(data.get("encounter_snapshot", {}))
	if route != null and data.get("route_snapshot", {}) is Dictionary and not data.get("route_snapshot", {}).is_empty():
		route.restore(data.get("route_snapshot", {}))


func _bind_signal_forwards() -> void:
	if objectives == null or encounters == null:
		return
	objectives.objective_activated.connect(_on_objective_activated)
	objectives.objective_completed.connect(_on_objective_completed)
	encounters.actor_spawned.connect(_on_actor_spawned)
	encounters.actor_defeated.connect(_on_actor_defeated)
	encounters.wave_started.connect(_on_encounter_wave_started)
	encounters.wave_completed.connect(_on_encounter_wave_completed)
	encounters.encounter_completed.connect(_on_encounter_completed)
	encounters.encounter_failed.connect(_on_encounter_failed)
	if route != null:
		route.zone_entered.connect(zone_entered.emit)
		route.route_progressed.connect(route_progressed.emit)
		route.checkpoint_available.connect(checkpoint_available.emit)
		route.route_completed.connect(route_completed.emit)


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


func _on_encounter_wave_started(definition: EncounterDefinition, wave_index: int) -> void:
	wave_started.emit(definition, wave_index)


func _on_encounter_wave_completed(definition: EncounterDefinition, wave_index: int) -> void:
	wave_completed.emit(definition, wave_index)


func _on_encounter_completed(definition: EncounterDefinition) -> void:
	encounter_completed.emit(definition)


func _on_encounter_failed(definition: EncounterDefinition, reason: String) -> void:
	encounter_failed.emit(definition, reason)
