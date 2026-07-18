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
@export var audio_profile: MissionAudioProfile
@export var zone_presentations: Array[ZonePresentationProfile] = []
@export var moving_set_pieces: Array[MovingSetPieceDefinition] = []
@export var timed_hazards: Array[TimedHazardDefinition] = []


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

	var route_zone_ids: Array[StringName] = []
	if route_definition != null:
		errors.append_array(route_definition.validate())
		route_zone_ids = route_definition.ordered_zone_ids()
		if encounter_zones.size() != route_zone_ids.size():
			errors.append("route and encounters have mismatched zone counts (%d vs %d)" % [route_zone_ids.size(), encounter_zones.size()])
		for zone_id in route_zone_ids:
			if not encounter_zones.has(zone_id):
				errors.append("route zone %s has no matching encounter" % zone_id)
		for zone_id in encounter_zones.keys():
			if not route_zone_ids.has(zone_id):
				errors.append("encounter zone %s is not in authored route" % zone_id)

		var zone_presentation_ids := {}
		var zone_presentation_zone_ids := {}
		if zone_presentations.is_empty():
			errors.append("route-authored mission has no zone presentations")
		else:
			for zone_presentation_index in range(zone_presentations.size()):
				var zone_presentation = zone_presentations[zone_presentation_index]
				if zone_presentation == null:
					errors.append("zone presentation at index %d is null" % zone_presentation_index)
					continue
				if zone_presentation_ids.has(zone_presentation.id):
					errors.append("duplicate zone presentation id: %s" % zone_presentation.id)
				else:
					zone_presentation_ids[zone_presentation.id] = true
				errors.append_array(zone_presentation.validate())
				var zone_key := String(zone_presentation.zone_id)
				if zone_key != "":
					if zone_presentation_zone_ids.has(zone_key):
						errors.append("duplicate zone presentation zone_id: %s" % zone_presentation.zone_id)
					else:
						zone_presentation_zone_ids[zone_key] = true
				else:
					errors.append("route-authored mission has zone presentation with empty zone_id")
			if zone_presentation_zone_ids.size() != route_zone_ids.size():
				errors.append("zone presentation and route zone count mismatch (%d vs %d)" % [zone_presentation_zone_ids.size(), route_zone_ids.size()])
			for route_zone_id in route_zone_ids:
				if not zone_presentation_zone_ids.has(String(route_zone_id)):
					errors.append("route zone %s has no zone presentation" % route_zone_id)
			for zone_id in zone_presentation_zone_ids.keys():
				var zone_name := StringName(zone_id)
				if not route_zone_ids.has(zone_name):
					errors.append("zone presentation zone_id %s is not in route" % zone_name)
	else:
		if not zone_presentations.is_empty():
			errors.append("zone presentations require route_definition")

	var set_piece_ids: Dictionary = {}
	var module_owners: Dictionary = {}
	for set_piece in moving_set_pieces:
		if set_piece == null:
			errors.append("moving set piece is null")
			continue
		if set_piece_ids.has(set_piece.id):
			errors.append("duplicate moving set piece id: %s" % set_piece.id)
		else:
			set_piece_ids[set_piece.id] = true
		errors.append_array(set_piece.validate())
		for trigger_id in set_piece.encounter_trigger_ids:
			if trigger_id == &"": continue
			if not encounter_ids.has(trigger_id):
				errors.append("moving set piece %s references missing encounter %s" % [set_piece.id, trigger_id])
		for module_id in set_piece.destructible_module_ids:
			var module_key := String(module_id)
			if module_key.is_empty():
				continue
			if module_owners.has(module_key):
				errors.append("destructible module id %s used by multiple moving set pieces" % module_id)
			else:
				module_owners[module_key] = set_piece.id

	var hazard_ids: Dictionary = {}
	for hazard_index in range(timed_hazards.size()):
		var hazard := timed_hazards[hazard_index]
		if hazard == null:
			errors.append("timed hazard at index %d is null" % hazard_index)
			continue
		if hazard_ids.has(hazard.id):
			errors.append("duplicate timed hazard id: %s" % hazard.id)
		else:
			hazard_ids[hazard.id] = true
		errors.append_array(hazard.validate())

	if audio_profile != null:
		errors.append_array(audio_profile.validate())
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
