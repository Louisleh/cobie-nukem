class_name MissionRouteRuntime
extends Node

signal zone_entered(zone_id: StringName, title: String)
signal route_progressed(previous: StringName, current: StringName, index: int)
signal checkpoint_available(checkpoint_id: StringName, zone_id: StringName)
signal route_completed(final_zone: StringName)

enum RecoveryPolicy {
	NONE = 0,
	ALLOW_SKIP_INTERMEDIATE = 1 << 0,
	ALLOW_REGRESSION = 1 << 1,
}

@export var boundary_tolerance := 0.12
@export var vertical_tolerance := 0.8

var route_definition: MissionRouteDefinition
var current_zone: StringName = &""
var current_zone_index := -1
var visited_zones: Array[StringName] = []
var is_completed := false
var current_checkpoint_id: StringName = &""

var _configured := false
var _ordered_zone_ids: Array[StringName] = []
var _zone_by_id: Dictionary = {}
var _zone_index_by_id: Dictionary = {}
var _zone_by_checkpoint: Dictionary = {}
var _visited_lookup: Dictionary = {}
var _checkpoint_emitted: Dictionary = {}
var _route_id: StringName = &""
var _entry_zone_id: StringName = &""
var _final_zone_id: StringName = &""
var _completion_emitted := false


func configure(definition: MissionRouteDefinition) -> bool:
	_clear_configuration()
	if definition == null or not definition.validate().is_empty():
		return false
	route_definition = definition
	_route_id = definition.route_id
	_entry_zone_id = definition.entry_zone_id
	_ordered_zone_ids = definition.ordered_zone_ids()
	_final_zone_id = _ordered_zone_ids.back()
	for index in _ordered_zone_ids.size():
		var zone_id := _ordered_zone_ids[index]
		var zone := definition.zone_for_id(zone_id)
		if zone == null:
			_clear_configuration()
			return false
		_zone_by_id[zone_id] = zone
		_zone_index_by_id[zone_id] = index
		for checkpoint_id in zone.checkpoint_ids:
			_zone_by_checkpoint[checkpoint_id] = zone_id
	_configured = true
	return true


func reset() -> void:
	if _configured:
		_reset_progress()


func submit_actor_position(position: Vector3) -> StringName:
	if not _configured:
		return current_zone
	var candidates := _zones_containing_position(position)
	if current_zone == &"":
		if candidates.has(_entry_zone_id):
			return _enter_zone(_entry_zone_id)
		return current_zone
	var current_definition := _zone_by_id.get(current_zone) as MissionRouteZone
	if current_definition == null:
		return current_zone
	for candidate_id in current_definition.outgoing_edge_ids:
		var candidate_index := int(_zone_index_by_id.get(candidate_id, -1))
		if candidate_index == current_zone_index + 1 and candidates.has(candidate_id) and _within_strict_vertical(position, _zone_by_id[candidate_id]):
			return _enter_zone(candidate_id)
	return current_zone


func recovery_query(position: Vector3, policy: int = RecoveryPolicy.NONE) -> StringName:
	## Recovery is deliberately a pure query. The mission host decides whether to
	## teleport, reopen geometry, or submit authored progression; querying a distant
	## recovery zone must never silently complete objectives or checkpoints.
	if not _configured:
		return current_zone
	var candidates := _zones_containing_position(position)
	for zone_id in _ordered_zone_ids:
		if not candidates.has(zone_id):
			continue
		var index := int(_zone_index_by_id[zone_id])
		if current_zone == &"":
			return zone_id if zone_id == _entry_zone_id or policy_has(policy, RecoveryPolicy.ALLOW_SKIP_INTERMEDIATE) else current_zone
		if index < current_zone_index:
			if policy_has(policy, RecoveryPolicy.ALLOW_REGRESSION) and _visited_lookup.has(zone_id):
				return zone_id
			continue
		if index > current_zone_index + 1 and not policy_has(policy, RecoveryPolicy.ALLOW_SKIP_INTERMEDIATE):
			continue
		if index > current_zone_index and not route_definition.can_reach(current_zone, zone_id):
			continue
		return zone_id
	return current_zone


func activate_checkpoint(checkpoint_id: StringName) -> bool:
	if not _configured or checkpoint_id == &"" or not _zone_by_checkpoint.has(checkpoint_id):
		return false
	var zone_id: StringName = _zone_by_checkpoint[checkpoint_id]
	if zone_id != current_zone or _checkpoint_emitted.has(checkpoint_id):
		return false
	_emit_checkpoint(checkpoint_id, zone_id)
	return true


func snapshot() -> Dictionary:
	if not _configured:
		return _empty_snapshot(&"")
	var visited: Array[String] = []
	for zone_id in visited_zones:
		visited.append(String(zone_id))
	return {
		"route_id": String(_route_id),
		"current_zone": String(current_zone),
		"current_index": current_zone_index,
		"visited_zones": visited,
		"checkpoint_id": String(current_checkpoint_id),
		"is_completed": is_completed,
	}


func restore(data: Dictionary) -> bool:
	if not _configured:
		return false
	var parsed := _parse_restore(data)
	if not bool(parsed.get("ok", false)):
		return false
	if bool(parsed.get("unstarted", false)):
		_reset_progress()
		return true
	current_zone = parsed.zone
	current_zone_index = parsed.index
	visited_zones.assign(parsed.visited)
	_visited_lookup.clear()
	_checkpoint_emitted.clear()
	for zone_id in visited_zones:
		_visited_lookup[zone_id] = true
		var zone := _zone_by_id[zone_id] as MissionRouteZone
		if not zone.checkpoint_ids.is_empty():
			_checkpoint_emitted[zone.checkpoint_ids[0]] = true
	current_checkpoint_id = parsed.checkpoint
	if current_checkpoint_id != &"":
		_checkpoint_emitted[current_checkpoint_id] = true
	is_completed = parsed.completed
	if is_completed:
		_completion_emitted = true
	return true


func policy_has(policy: int, flag: int) -> bool:
	return (policy & flag) == flag


func _enter_zone(zone_id: StringName) -> StringName:
	var next_index := int(_zone_index_by_id.get(zone_id, -1))
	if next_index < 0:
		return current_zone
	var previous := current_zone
	current_zone = zone_id
	current_zone_index = next_index
	if not _visited_lookup.has(zone_id):
		_visited_lookup[zone_id] = true
		visited_zones.append(zone_id)
	route_progressed.emit(previous, zone_id, next_index)
	var zone := _zone_by_id[zone_id] as MissionRouteZone
	zone_entered.emit(zone_id, zone.zone_title if not zone.zone_title.strip_edges().is_empty() else String(zone_id))
	if not zone.checkpoint_ids.is_empty():
		var entry_checkpoint := zone.checkpoint_ids[0]
		if not _checkpoint_emitted.has(entry_checkpoint):
			_emit_checkpoint(entry_checkpoint, zone_id)
	is_completed = zone_id == _final_zone_id
	if is_completed and not _completion_emitted:
		_completion_emitted = true
		route_completed.emit(zone_id)
	return current_zone


func _emit_checkpoint(checkpoint_id: StringName, zone_id: StringName) -> void:
	_checkpoint_emitted[checkpoint_id] = true
	current_checkpoint_id = checkpoint_id
	checkpoint_available.emit(checkpoint_id, zone_id)


func _parse_restore(data: Dictionary) -> Dictionary:
	var route_id: Variant = _string_id(data.get("route_id", ""))
	var zone_id: Variant = _string_id(data.get("current_zone", ""))
	var checkpoint_id: Variant = _string_id(data.get("checkpoint_id", ""))
	if route_id == null or zone_id == null or checkpoint_id == null:
		return {"ok": false}
	if route_id != _route_id:
		return {"ok": false}
	var visited_variant: Variant = data.get("visited_zones", [])
	if not (visited_variant is Array):
		return {"ok": false}
	var visited_result := _normalize_visited(visited_variant)
	if not visited_result.ok:
		return {"ok": false}
	var visited: Array[StringName] = visited_result.zones
	var unstarted: bool = zone_id == &"" and checkpoint_id == &"" and visited.is_empty()
	var index_result := _parse_index(data.get("current_index", -1))
	if not index_result.ok:
		return {"ok": false}
	if unstarted:
		return {"ok": index_result.value == -1 and data.get("is_completed", false) == false, "unstarted": true}
	if zone_id == &"" and checkpoint_id != &"":
		zone_id = _zone_by_checkpoint.get(checkpoint_id, &"")
	if not _zone_by_id.has(zone_id):
		return {"ok": false}
	var expected_index := int(_zone_index_by_id[zone_id])
	if visited.is_empty():
		visited = _ordered_zone_ids.slice(0, expected_index + 1)
	if visited.back() != zone_id or visited.size() != expected_index + 1:
		return {"ok": false}
	if data.has("current_index") and index_result.value != expected_index:
		return {"ok": false}
	if checkpoint_id != &"" and _zone_by_checkpoint.get(checkpoint_id, &"") != zone_id:
		return {"ok": false}
	var completed := expected_index == _ordered_zone_ids.size() - 1
	if data.has("is_completed"):
		if not (data.is_completed is bool) or data.is_completed != completed:
			return {"ok": false}
	return {"ok": true, "zone": zone_id, "index": expected_index, "visited": visited, "checkpoint": checkpoint_id, "completed": completed}


func _normalize_visited(raw: Array) -> Dictionary:
	var zones: Array[StringName] = []
	for index in raw.size():
		var zone_id: Variant = _string_id(raw[index])
		if zone_id == null or not _zone_index_by_id.has(zone_id) or int(_zone_index_by_id[zone_id]) != index:
			return {"ok": false, "zones": zones}
		zones.append(zone_id)
	return {"ok": true, "zones": zones}


func _parse_index(value: Variant) -> Dictionary:
	if value is int:
		return {"ok": true, "value": value}
	if value is float and is_finite(value) and is_equal_approx(value, round(value)):
		return {"ok": true, "value": int(value)}
	return {"ok": false, "value": -1}


func _string_id(value: Variant) -> Variant:
	if value is String or value is StringName:
		return StringName(value)
	return null


func _zones_containing_position(position: Vector3) -> Dictionary:
	var result := {}
	for zone_id in _ordered_zone_ids:
		var zone := _zone_by_id[zone_id] as MissionRouteZone
		var expanded := zone.bounds.grow(boundary_tolerance)
		expanded.position.y -= vertical_tolerance - boundary_tolerance
		expanded.size.y += (vertical_tolerance - boundary_tolerance) * 2.0
		if expanded.has_point(position):
			result[zone_id] = true
	return result


func _within_strict_vertical(position: Vector3, zone: MissionRouteZone) -> bool:
	return position.y >= zone.bounds.position.y and position.y <= zone.bounds.end.y


func _empty_snapshot(route_id: StringName) -> Dictionary:
	return {"route_id": String(route_id), "current_zone": "", "current_index": -1, "visited_zones": [], "checkpoint_id": "", "is_completed": false}


func _clear_configuration() -> void:
	route_definition = null
	_configured = false
	_ordered_zone_ids.clear()
	_zone_by_id.clear()
	_zone_index_by_id.clear()
	_zone_by_checkpoint.clear()
	_route_id = &""
	_entry_zone_id = &""
	_final_zone_id = &""
	_reset_progress()


func _reset_progress() -> void:
	current_zone = &""
	current_zone_index = -1
	visited_zones.clear()
	is_completed = false
	current_checkpoint_id = &""
	_visited_lookup.clear()
	_checkpoint_emitted.clear()
	_completion_emitted = false
