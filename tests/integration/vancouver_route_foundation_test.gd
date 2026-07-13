extends SceneTree

class ProbeEnemy extends Node3D:
	signal died(enemy: Node, source: Node)

const EXPECTED_ROUTE_ZONES: Array[StringName] = [
	&"downtown_alley",
	&"ruse_block",
	&"waterfront_seawall",
	&"terminal_service",
	&"harbour_pier",
]

const OBJECTIVE_ROUTE_ORDER: Array[StringName] = [
	&"reach_waterfront",
	&"restore_terminal",
	&"stop_citation_convoy",
	&"complete_harbour_pier",
]

const OBJECTIVE_ZONE_BY_ID: Dictionary = {
	&"reach_waterfront": &"waterfront_seawall",
	&"restore_terminal": &"terminal_service",
	&"stop_citation_convoy": &"harbour_pier",
	&"complete_harbour_pier": &"harbour_pier",
}

const OBJECTIVE_CHECKPOINT_BY_ID: Dictionary = {
	&"reach_waterfront": &"checkpoint_waterfront_seawall",
	&"restore_terminal": &"checkpoint_terminal_service",
	&"stop_citation_convoy": &"checkpoint_harbour_pier",
	&"complete_harbour_pier": &"checkpoint_harbour_pier",
}

const MANIFEST: ContentManifest = preload("res://resources/content/vancouver_waterfront_manifest.tres")

var failures: Array[String] = []
var failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest: ContentManifest = MANIFEST as ContentManifest
	if manifest == null:
		report_failure("Vancouver manifest preload failed")
		_finish()
		return

	var manifest_errors: PackedStringArray = manifest.validate()
	for error in manifest_errors:
		report_failure("manifest validation: %s" % error)
	assert_true(manifest_errors.is_empty(), "Vancouver manifest validates")

	var route: MissionRouteDefinition = manifest.route_definition
	assert_not_null(route, "Vancouver manifest contains route_definition")
	if route == null:
		_finish()
		return

	_check_route_shape(route)
	_check_encounter_alignment(manifest, route)
	_check_objective_and_checkpoint_contract(manifest, route)
	_check_non_rendered_route_simulation(manifest)
	_check_encounter_reset_contract(manifest)
	_finish()


func report_failure(message: String) -> void:
	failures.append(message)
	failure_count += 1
	push_error(message)


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		report_failure(message)


func assert_not_null(value: Variant, message: String) -> void:
	if value == null:
		report_failure(message)


func _finish() -> void:
	if failure_count == 0:
		print("Vancouver route foundation test PASS")
		quit()
	else:
		push_error("Vancouver route foundation test FAILED (%d issues)" % failure_count)
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_route_shape(route: MissionRouteDefinition) -> void:
	assert_true(route.ordered_zone_ids() == EXPECTED_ROUTE_ZONES, "Vancouver route defines five ordered zones")
	assert_true(route.entry_zone_id == &"downtown_alley", "Vancouver route entry is downtown_alley")
	var route_errors: PackedStringArray = route.validate()
	for error in route_errors:
		report_failure("route validation: %s" % error)
	assert_true(route_errors.is_empty(), "Mission 2 route definition validates")

	assert_true(_can_reach_all(route), "All route zones reachable from entry")
	for index in range(EXPECTED_ROUTE_ZONES.size() - 1):
		assert_true(route.can_reach(EXPECTED_ROUTE_ZONES[index], EXPECTED_ROUTE_ZONES[index + 1]), "Route can progress %s -> %s" % [EXPECTED_ROUTE_ZONES[index], EXPECTED_ROUTE_ZONES[index + 1]])
	assert_true(route.can_reach(route.entry_zone_id, EXPECTED_ROUTE_ZONES.back()), "Route reaches final zone")


func _check_encounter_alignment(manifest: ContentManifest, route: MissionRouteDefinition) -> void:
	var encounter_by_zone: Dictionary = {}
	var seen_ids: Dictionary = {}
	var route_zone_ids: Array[StringName] = route.ordered_zone_ids()
	for encounter in manifest.encounters:
		assert_not_null(encounter, "Manifest encounter entry is non-null")
		if encounter == null:
			continue
		if seen_ids.has(encounter.id):
			report_failure("Duplicate encounter id: %s" % encounter.id)
		seen_ids[encounter.id] = true
		assert_true(encounter.zone_id != &"", "Encounter %s has zone id" % encounter.id)
		assert_true(encounter.schema_version == 2, "Encounter %s is schema_version 2" % encounter.id)
		assert_true(encounter.spawns.is_empty(), "Encounter %s uses schema-v2 waves and no legacy spawns" % encounter.id)
		assert_true(not encounter.waves.is_empty(), "Encounter %s has at least one wave" % encounter.id)
		assert_true(route_zone_ids.has(encounter.zone_id), "Encounter %s zone %s is in route" % [encounter.id, encounter.zone_id])
		for wave in encounter.waves:
			var wave_spawns: Array = wave.get("spawns", []) as Array
			assert_true(wave_spawns is Array and wave_spawns.size() > 0, "Encounter %s wave includes spawns" % encounter.id)
			for spawn in wave_spawns:
				var spawn_data: Dictionary = spawn as Dictionary
				assert_true(spawn_data.has("scene"), "Encounter %s wave spawn has scene" % encounter.id)
				assert_true(spawn_data.get("position", null) is Vector3, "Encounter %s spawn position is Vector3" % encounter.id)
		encounter_by_zone[encounter.zone_id] = encounter

	assert_true(encounter_by_zone.size() == route.ordered_zone_ids().size(), "Every route zone has exactly one encounter")
	for zone_id in EXPECTED_ROUTE_ZONES:
		assert_true(encounter_by_zone.has(zone_id), "Encounter exists for route zone %s" % zone_id)
	var harbour: EncounterDefinition = encounter_by_zone.get(&"harbour_pier", null) as EncounterDefinition
	assert_true(harbour != null, "Harbour-pier encounter exists")
	if harbour != null:
		assert_true(harbour.waves.size() == 3, "Harbour-pier encounter uses exactly three waves")
		var harbour_spawn_count: int = 0
		for wave in harbour.waves:
			harbour_spawn_count += (wave.get("spawns", []) as Array).size()
		assert_true(harbour_spawn_count > 0 and harbour_spawn_count <= harbour.enemy_budget, "Harbour spawn count and budget are finite")

	for zone_id in EXPECTED_ROUTE_ZONES:
		var zone: MissionRouteZone = route.zone_for_id(zone_id)
		var encounter: EncounterDefinition = encounter_by_zone.get(zone_id, null) as EncounterDefinition
		assert_not_null(zone, "Route zone %s resolves" % zone_id)
		if zone == null:
			continue
		assert_true(_wave_spawns_fit_zone(encounter, zone), "Encounter spawns in %s fit zone spawn volumes" % zone_id)


func _check_objective_and_checkpoint_contract(manifest: ContentManifest, route: MissionRouteDefinition) -> void:
	var ordered_zone_ids: Array[StringName] = route.ordered_zone_ids()
	var route_indices: Dictionary = {}
	for index in range(ordered_zone_ids.size()):
		route_indices[ordered_zone_ids[index]] = index

	var checkpoint_order: Array[StringName] = []
	var checkpoint_zone_map: Dictionary = {}
	for zone_id in ordered_zone_ids:
		var zone: MissionRouteZone = route.zone_for_id(zone_id)
		if zone == null:
			continue
		for checkpoint_id in zone.checkpoint_ids:
			assert_true(checkpoint_id != &"", "Zone %s checkpoint id is non-empty" % zone_id)
			if checkpoint_zone_map.has(checkpoint_id):
				report_failure("Duplicate checkpoint id: %s" % checkpoint_id)
			checkpoint_zone_map[checkpoint_id] = zone_id
			checkpoint_order.append(checkpoint_id)

	assert_true(checkpoint_order.size() >= 5, "Route has checkpoint rail entries for every zone")

	var previous_index: int = -1
	for objective_id in OBJECTIVE_ROUTE_ORDER:
		var objective: ObjectiveDefinition = _manifest_objective_by_id(manifest, objective_id)
		assert_true(objective != null, "Objective %s exists" % objective_id)
		if objective == null:
			continue
		var zone_id: StringName = OBJECTIVE_ZONE_BY_ID.get(objective_id, &"")
		assert_true(zone_id != &"", "Objective %s has route zone contract" % objective_id)
		var zone_index: int = route_indices.get(zone_id, -1)
		assert_true(zone_index != -1, "Objective %s zone %s is in route" % [objective_id, zone_id])
		assert_true(zone_index >= previous_index, "Objective %s follows route order" % objective_id)
		previous_index = zone_index
		var checkpoint_id: StringName = OBJECTIVE_CHECKPOINT_BY_ID.get(objective_id, &"")
		assert_true(checkpoint_id != &"", "Objective %s has checkpoint contract" % objective_id)
		assert_true(checkpoint_zone_map.has(checkpoint_id), "Objective checkpoint %s is known" % checkpoint_id)
		assert_true(checkpoint_order.has(checkpoint_id), "Objective checkpoint %s appears in ordered checkpoint rail" % checkpoint_id)


func _check_non_rendered_route_simulation(manifest: ContentManifest) -> void:
	var runner := EncounterRunner.new()
	runner.name = "VancouverRouteRunner"
	runner.log_failures = false
	root.add_child(runner)
	var encounter_by_zone: Dictionary = {}
	for encounter in manifest.encounters:
		if encounter != null:
			encounter_by_zone[encounter.zone_id] = encounter

	runner.configure(manifest.encounters, _spawn_probe)

	for zone_id in EXPECTED_ROUTE_ZONES:
		var definition: EncounterDefinition = encounter_by_zone.get(zone_id, null) as EncounterDefinition
		assert_true(definition != null, "Simulation has encounter for zone %s" % zone_id)
		if definition == null:
			continue

		var wave_spawned: Array[Node] = runner.activate_zone(zone_id)
		assert_true(not wave_spawned.is_empty(), "Zone %s activates at least one actor" % zone_id)
		await _drain_encounter_to_completion(runner, zone_id)
		assert_true(runner.completed.has(zone_id), "Zone %s reaches completed" % zone_id)
		assert_true(runner.reset_zone(zone_id), "Zone %s resets" % zone_id)
		assert_true(not runner.active.has(zone_id), "Zone %s reset clears active state" % zone_id)

		var replay_spawned: Array[Node] = runner.activate_zone(zone_id)
		assert_true(not replay_spawned.is_empty(), "Zone %s respawns after reset" % zone_id)
		await _drain_encounter_to_completion(runner, zone_id)
		assert_true(runner.completed.has(zone_id), "Zone %s reaches completed after reset" % zone_id)
		assert_true(runner.reset_zone(zone_id), "Zone %s resets after replay" % zone_id)

	runner.queue_free()


func _check_encounter_reset_contract(manifest: ContentManifest) -> void:
	var harbour_encounter: EncounterDefinition = _manifest_encounter_by_zone(manifest, &"harbour_pier")
	assert_true(harbour_encounter != null, "Harbour-pier encounter exists")
	if harbour_encounter != null:
		assert_true(harbour_encounter.waves.size() == 3, "Harbour-pier encounter keeps three waves")
		assert_true(harbour_encounter.enemy_budget >= 1 and harbour_encounter.enemy_budget <= 12, "Harbour-pier budget remains bounded")


func _spawn_probe(_path: String, position: Vector3) -> Node:
	var enemy := ProbeEnemy.new()
	enemy.position = position
	root.add_child(enemy)
	return enemy


func _drain_encounter_to_completion(runner: EncounterRunner, zone_id: StringName) -> void:
	var safety_ticks: int = 0
	while not runner.completed.has(zone_id) and safety_ticks < 360:
		await process_frame
		safety_ticks += 1
		var active_state: Dictionary = runner.active.get(zone_id, {}) as Dictionary
		for actor in Array(active_state.get("actors", [])):
			if is_instance_valid(actor):
				actor.died.emit(actor, null)
	if not runner.completed.has(zone_id):
		report_failure("Zone %s did not complete in bounded simulation steps" % zone_id)


func _wave_spawns_fit_zone(encounter: EncounterDefinition, zone: MissionRouteZone) -> bool:
	if encounter == null or zone == null:
		return false
	for wave in encounter.waves:
		var wave_spawns: Array = wave.get("spawns", []) as Array
		for spawn in wave_spawns:
			var spawn_data: Dictionary = spawn as Dictionary
			var spawn_point: Variant = spawn_data.get("position", Vector3.ZERO)
			if not (spawn_point is Vector3):
				return false
			if not _point_within_any_spawn_volume(spawn_point as Vector3, zone):
				return false
	return true


func _point_within_any_spawn_volume(point: Vector3, zone: MissionRouteZone) -> bool:
	for volume: AABB in zone.spawn_volumes:
		if _point_within_volume(point, volume):
			return true
	return false


func _point_within_volume(point: Vector3, volume: AABB) -> bool:
	if not volume.size.is_finite() or not volume.position.is_finite():
		return false
	var min_corner: Vector3 = volume.position
	var max_corner: Vector3 = volume.position + volume.size
	return point.x >= min_corner.x and point.y >= min_corner.y and point.z >= min_corner.z and point.x <= max_corner.x and point.y <= max_corner.y and point.z <= max_corner.z


func _manifest_objective_by_id(manifest: ContentManifest, objective_id: StringName) -> ObjectiveDefinition:
	for objective in manifest.objectives:
		var objective_definition: ObjectiveDefinition = objective as ObjectiveDefinition
		if objective_definition.id == objective_id:
			return objective_definition
	return null


func _manifest_encounter_by_zone(manifest: ContentManifest, zone_id: StringName) -> EncounterDefinition:
	for encounter in manifest.encounters:
		var encounter_definition: EncounterDefinition = encounter as EncounterDefinition
		if encounter_definition.zone_id == zone_id:
			return encounter_definition
	return null


func _can_reach_all(route: MissionRouteDefinition) -> bool:
	var frontier: Array[StringName] = [route.entry_zone_id]
	var seen: Dictionary = {}
	while not frontier.is_empty():
		var zone_id: StringName = frontier.pop_front()
		if seen.has(zone_id):
			continue
		seen[zone_id] = true
		var zone: MissionRouteZone = route.zone_for_id(zone_id)
		if zone == null:
			continue
		for next_zone_id in zone.outgoing_edge_ids:
			if not seen.has(next_zone_id):
				frontier.append(next_zone_id)
	return seen.size() == route.ordered_zone_ids().size()
