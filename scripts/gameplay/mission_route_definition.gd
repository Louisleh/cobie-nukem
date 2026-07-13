class_name MissionRouteDefinition
extends Resource

@export var route_id: StringName = &"mission_route"
@export var entry_zone_id: StringName = &""
@export var zones: Array[MissionRouteZone] = []


func ordered_zone_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for zone in zones:
		if zone != null:
			ids.append(zone.zone_id)
	return ids


func zone_for_id(zone_id: StringName) -> MissionRouteZone:
	for zone in zones:
		if zone != null and zone.zone_id == zone_id:
			return zone
	return null


func can_reach(start_zone_id: StringName, goal_zone_id: StringName) -> bool:
	if start_zone_id == goal_zone_id:
		return true
	var adjacency: Dictionary = _build_adjacency()
	if not adjacency.has(start_zone_id):
		return false
	var visited: Dictionary = {}
	var frontier: Array[StringName] = [start_zone_id]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_front()
		if visited.has(current):
			continue
		visited[current] = true
		if current == goal_zone_id:
			return true
		for next_zone_id in adjacency.get(current, []):
			if not visited.has(next_zone_id):
				frontier.append(next_zone_id)
	return false


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if route_id == &"":
		errors.append("route has empty route_id")
	if entry_zone_id == &"":
		errors.append("route %s has empty entry_zone_id" % route_id)
	if zones.is_empty():
		errors.append("route %s has no zones" % route_id)
		return errors
	var zone_ids: Dictionary = {}
	var checkpoint_ids: Dictionary = {}
	var secret_ids: Dictionary = {}
	for zone_index in range(zones.size()):
		var zone: MissionRouteZone = zones[zone_index]
		if zone == null:
			errors.append("route %s has null zone at index %d" % [route_id, zone_index])
			continue
		if zone_ids.has(zone.zone_id):
			errors.append("route %s has duplicate zone_id %s" % [route_id, zone.zone_id])
		zone_ids[zone.zone_id] = true
		errors.append_array(zone.validate())
		for checkpoint_id in zone.checkpoint_ids:
			if checkpoint_id == &"":
				errors.append("route %s zone %s has empty checkpoint id" % [route_id, zone.zone_id])
				continue
			if checkpoint_ids.has(checkpoint_id):
				errors.append("route %s has duplicate checkpoint id %s" % [route_id, checkpoint_id])
			checkpoint_ids[checkpoint_id] = true
		for secret_id in zone.secret_ids:
			if secret_id == &"":
				errors.append("route %s zone %s has empty secret id" % [route_id, zone.zone_id])
				continue
			if secret_ids.has(secret_id):
				errors.append("route %s has duplicate secret id %s" % [route_id, secret_id])
			secret_ids[secret_id] = true
	if not zone_ids.has(entry_zone_id):
		errors.append("route %s entry_zone_id %s is unknown" % [route_id, entry_zone_id])
	var zone_list: Array[StringName] = ordered_zone_ids()
	for zone in zones:
		if zone == null:
			continue
		for target in zone.outgoing_edge_ids:
			if target == &"":
				errors.append("route %s zone %s has empty outgoing edge" % [route_id, zone.zone_id])
				continue
			if not zone_ids.has(target):
				errors.append("route %s zone %s has unknown outgoing edge %s" % [route_id, zone.zone_id, target])
	for next_index in range(zone_list.size() - 1):
		if not can_reach(zone_list[next_index], zone_list[next_index + 1]):
			errors.append("route %s cannot reach ordered successor %s from %s" % [route_id, zone_list[next_index + 1], zone_list[next_index]])
	for zone_index in range(zone_list.size()):
		if zone_list[zone_index] == &"":
			errors.append("route %s has empty zone id at index %d" % [route_id, zone_index])
	var reachable: Dictionary = {}
	var frontier: Array[StringName] = [entry_zone_id]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_front()
		if reachable.has(current):
			continue
		reachable[current] = true
		var current_zone: MissionRouteZone = zone_for_id(current)
		if current_zone == null:
			continue
		for next_zone_id in current_zone.outgoing_edge_ids:
			if not reachable.has(next_zone_id) and zone_ids.has(next_zone_id):
				frontier.append(next_zone_id)
	if reachable.size() != zone_ids.size():
		errors.append("route %s has dead zones unreachable from %s" % [route_id, entry_zone_id])
	if zone_list.size() > 0 and not can_reach(entry_zone_id, zone_list[zone_list.size() - 1]):
		errors.append("route %s cannot reach final zone %s from entry" % [route_id, zone_list[zone_list.size() - 1]])
	return errors


func _build_adjacency() -> Dictionary:
	var adjacency: Dictionary = {}
	for zone in zones:
		if zone == null:
			continue
		var edges: Array[StringName] = []
		for edge in zone.outgoing_edge_ids:
			edges.append(edge)
		adjacency[zone.zone_id] = edges
	return adjacency
