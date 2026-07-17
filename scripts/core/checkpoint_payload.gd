class_name CheckpointPayload
extends RefCounted

## Canonical v3 checkpoint payload contract (v5 envelope-compatible).
##
## {
##   "scene_path": "res://…​.tscn"    — must exist as a PackedScene
##   "level_id": String              — non-empty
##   "checkpoint_id": String         — defaults to "start"
##   "position": [x, y, z]           — finite floats; omitted when unusable
##   "content_revision": int          — non-negative content revision marker
##   "difficulty_id": String          — key of GameState.DIFFICULTY_PATHS
##   "objective_snapshot": Dictionary — sanitized ObjectiveTracker state
##   "encounter_snapshot": Dictionary — completed encounter ids only
##   "route_snapshot": Dictionary     — strict ordered-route restore state
##   "unlocked_weapons": [String]     — valid weapon ids unlocked for this checkpoint
##   "active_mission_upgrades": Dictionary
##     { "mission_id": StringName, "selected_weapon": String,
##       "unlocked_weapons": [String], "weapon_ammo": { "weapon_id":
##       {"magazine": int, "reserve": int} }, "mission_upgrades": [String] }
##   "player_state": {"health": float, "armor": float}
##   "secrets": Dictionary            — discovered secret id → title
## }
##
## sanitize() is the single gate between persisted data and runtime state:
## boot, continue, and level restore must all pass loaded payloads through it.

const GameStateScript := preload("res://scripts/core/game_state.gd")
const MissionLoadoutProfileScript := preload("res://scripts/gameplay/mission_loadout_profile.gd")
const DEFAULT_DIFFICULTY := "classic"

static func sanitize(raw: Dictionary) -> Dictionary:
	# Returns {} when the payload cannot name a resumable scene; a corrupt save
	# must read as "no checkpoint", never as invented progression.
	var scene_path := _string_field(raw, "scene_path")
	if not scene_path.begins_with("res://") or not ResourceLoader.exists(scene_path, "PackedScene"):
		return {}
	var level_id := _string_field(raw, "level_id")
	if level_id.is_empty():
		return {}
	var checkpoint_id := _string_field(raw, "checkpoint_id")
	if checkpoint_id.is_empty():
		checkpoint_id = "start"
	var sanitized := {
		"scene_path": scene_path,
		"level_id": level_id,
		"checkpoint_id": checkpoint_id,
		"difficulty_id": valid_difficulty(raw.get("difficulty_id")),
		"content_revision": _content_revision(raw.get("content_revision")),
		"objective_snapshot": _objective_snapshot(raw.get("objective_snapshot", {})),
		"encounter_snapshot": _encounter_snapshot(raw.get("encounter_snapshot", {})),
		"route_snapshot": _route_snapshot(raw.get("route_snapshot", {})),
		"secrets": _secrets(raw.get("secrets", {})),
	}
	var unlocked := _weapon_ids(raw.get("unlocked_weapons", []))
	if not unlocked.is_empty():
		sanitized["unlocked_weapons"] = unlocked
	var active_upgrades := _active_mission_upgrades(raw.get("active_mission_upgrades", {}))
	if not active_upgrades.is_empty():
		sanitized["active_mission_upgrades"] = active_upgrades
	var player_state := _player_state(raw.get("player_state", {}))
	if not player_state.is_empty():
		sanitized["player_state"] = player_state
	var position := _finite_position(raw.get("position"))
	if not position.is_empty():
		sanitized["position"] = position
	return sanitized

static func valid_difficulty(value: Variant) -> String:
	if value is String or value is StringName:
		var id := StringName(value)
		if GameStateScript.DIFFICULTY_PATHS.has(id):
			return String(id)
	return DEFAULT_DIFFICULTY

static func _content_revision(value: Variant) -> int:
	if value is int:
		return value if value >= 0 else 0
	if value is float and is_finite(value):
		return int(value) if value >= 0.0 else 0
	return 0

static func _string_field(raw: Dictionary, key: String) -> String:
	var value: Variant = raw.get(key)
	if value is String or value is StringName:
		return String(value).strip_edges()
	return ""

static func _finite_position(value: Variant) -> Array:
	if value is not Array or value.size() != 3:
		return []
	var result := []
	for component: Variant in value:
		if component is not float and component is not int:
			return []
		var number := float(component)
		if not is_finite(number):
			return []
		result.append(number)
	return result

static func _objective_snapshot(value: Variant) -> Dictionary:
	if value is not Dictionary:
		return {"progress": {}, "completed": []}
	var clean_progress := {}
	var raw_progress: Variant = value.get("progress", {})
	if raw_progress is Dictionary:
		for raw_id: Variant in raw_progress:
			var id := String(raw_id).strip_edges()
			var raw_count: Variant = raw_progress[raw_id]
			if not id.is_empty() and (raw_count is int or raw_count is float):
				clean_progress[id] = maxi(0, int(raw_count))
	return {"progress": clean_progress, "completed": _string_array(value.get("completed", []))}

static func _encounter_snapshot(value: Variant) -> Dictionary:
	if value is not Dictionary:
		return {"completed": []}
	return {"completed": _string_array(value.get("completed", []))}


static func _route_snapshot(value: Variant) -> Dictionary:
	if value is not Dictionary or value.is_empty():
		return {}
	var route_id := _string_field(value, "route_id")
	var current_zone := _string_field(value, "current_zone")
	var checkpoint_id := _string_field(value, "checkpoint_id")
	var raw_index: Variant = value.get("current_index", -1)
	var raw_completed: Variant = value.get("is_completed", false)
	var raw_visited: Variant = value.get("visited_zones", [])
	if route_id.is_empty() or raw_index is not int or raw_completed is not bool or raw_visited is not Array:
		return {}
	var visited: Variant = _ordered_string_array(raw_visited)
	if visited == null:
		return {}
	# MissionRouteRuntime performs route-ownership, order, checkpoint, and
	# completion validation atomically against the currently configured manifest.
	return {
		"route_id": route_id,
		"current_zone": current_zone,
		"current_index": raw_index,
		"visited_zones": visited,
		"checkpoint_id": checkpoint_id,
		"is_completed": raw_completed,
	}

static func _secrets(value: Variant) -> Dictionary:
	var result := {}
	if value is not Dictionary:
		return result
	for raw_id: Variant in value:
		var id := String(raw_id).strip_edges()
		var title: Variant = value[raw_id]
		if not id.is_empty() and (title is String or title is StringName):
			result[id] = String(title).strip_edges()
	return result

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is not Array:
		return result
	for entry: Variant in value:
		if entry is String or entry is StringName:
			var text := String(entry).strip_edges()
			if not text.is_empty() and text not in result:
				result.append(text)
	result.sort()
	return result


static func _ordered_string_array(value: Variant) -> Variant:
	var result: Array[String] = []
	if value is not Array:
		return null
	for entry: Variant in value:
		if entry is not String and entry is not StringName:
			return null
		var text := String(entry).strip_edges()
		if text.is_empty() or text in result:
			return null
		result.append(text)
	return result

static func _active_mission_upgrades(raw: Variant) -> Dictionary:
	if raw is not Dictionary:
		return {}
	var payload: Dictionary = MissionLoadoutProfileScript.sanitize_payload(raw)
	if payload.has("selected_weapon") or payload.has("unlocked_weapons") or payload.has("weapon_ammo") or payload.has("mission_upgrades") or payload.has("mission_id"):
		return payload
	return {}

static func _player_state(raw: Variant) -> Dictionary:
	if raw is not Dictionary:
		return {}
	var result := {}
	for key in ["health", "armor"]:
		var value: Variant = raw.get(key)
		if value is int or value is float:
			var number := float(value)
			if is_finite(number):
				result[key] = clampf(number, 0.0, 1000.0)
	return result if result.size() == 2 else {}

static func _weapon_ids(raw: Variant) -> Array[String]:
	if raw is not Array:
		return []
	var result: Array[String] = []
	for entry: Variant in raw:
		if entry is String or entry is StringName:
			var weapon_id := String(entry).strip_edges()
			if weapon_id.is_empty():
				continue
			if not _is_valid_weapon_id(weapon_id) or weapon_id in result:
				continue
			result.append(weapon_id)
	result.sort()
	return result

static func _is_valid_weapon_id(weapon_id: String) -> bool:
	return ResourceLoader.exists("res://resources/weapons/%s.tres" % weapon_id)
