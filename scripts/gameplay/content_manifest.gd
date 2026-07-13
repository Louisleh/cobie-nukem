class_name ContentManifest
extends Resource

@export var content_version := 1
@export var level_id: StringName = &"level"
@export var level_scene := ""
@export var difficulty_profiles: Array[DifficultyProfile] = []
@export var objectives: Array[ObjectiveDefinition] = []
@export var encounters: Array[EncounterDefinition] = []
@export var interaction_catalog: InteractionCatalog
@export var route_definition: MissionRouteDefinition


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if level_id == &"": errors.append("manifest level_id is empty")
	if level_scene.is_empty() or not ResourceLoader.exists(level_scene): errors.append("manifest level scene missing: %s" % level_scene)
	var ids := {}
	var encounter_zones := {}
	for objective in objectives:
		if ids.has(objective.id): errors.append("duplicate objective id: %s" % objective.id)
		ids[objective.id] = true
		errors.append_array(objective.validate())
	for objective in objectives:
		for prerequisite in objective.prerequisite_ids:
			if not ids.has(prerequisite): errors.append("objective %s has missing prerequisite %s" % [objective.id, prerequisite])
	if _has_objective_cycle(): errors.append("objective graph contains a dependency cycle")
	var encounter_ids := {}
	for encounter in encounters:
		if encounter_ids.has(encounter.id): errors.append("duplicate encounter id: %s" % encounter.id)
		if encounter_zones.has(encounter.zone_id): errors.append("duplicate encounter zone_id: %s" % encounter.zone_id)
		encounter_ids[encounter.id] = true
		encounter_zones[encounter.zone_id] = encounter
		errors.append_array(encounter.validate())
	var difficulty_ids := {}
	for profile in difficulty_profiles:
		if difficulty_ids.has(profile.id): errors.append("duplicate difficulty id: %s" % profile.id)
		difficulty_ids[profile.id] = true
		errors.append_array(profile.validate())
	if interaction_catalog != null:
		var zones: Array[StringName] = []
		for zone_id in encounter_zones.keys():
			zones.append(zone_id)
		errors.append_array(interaction_catalog.validate(zones, level_id))
	if route_definition != null:
		errors.append_array(route_definition.validate())
		var route_zone_ids := route_definition.ordered_zone_ids()
		if encounter_zones.size() != route_zone_ids.size():
			errors.append("route and encounters have mismatched zone counts (%d vs %d)" % [route_zone_ids.size(), encounter_zones.size()])
		for zone_id in route_zone_ids:
			if not encounter_zones.has(zone_id):
				errors.append("route zone %s has no matching encounter" % zone_id)
		for zone_id in encounter_zones.keys():
			if not route_zone_ids.has(zone_id):
				errors.append("encounter zone %s is not in authored route" % zone_id)
	return errors


func _has_objective_cycle() -> bool:
	var by_id := {}
	for objective in objectives: by_id[objective.id] = objective
	var visiting := {}
	var visited := {}
	for objective in objectives:
		if _visit_objective(objective.id, by_id, visiting, visited): return true
	return false


func _visit_objective(id: StringName, by_id: Dictionary, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(id): return true
	if visited.has(id) or not by_id.has(id): return false
	visiting[id] = true
	var objective: ObjectiveDefinition = by_id[id]
	for prerequisite in objective.prerequisite_ids:
		if _visit_objective(prerequisite, by_id, visiting, visited): return true
	visiting.erase(id)
	visited[id] = true
	return false
