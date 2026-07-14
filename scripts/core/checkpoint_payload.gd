class_name CheckpointPayload
extends RefCounted

## Canonical v3 checkpoint payload contract (v4 envelope-compatible).
##
## {
##   "scene_path": "res://…​.tscn"    — must exist as a PackedScene
##   "level_id": String              — non-empty
##   "checkpoint_id": String         — defaults to "start"
##   "position": [x, y, z]           — finite floats; omitted when unusable
##   "difficulty_id": String         — key of GameState.DIFFICULTY_PATHS
##   "objective_snapshot": Dictionary — sanitized ObjectiveTracker state
##   "encounter_snapshot": Dictionary — completed encounter ids only
##   "secrets": Dictionary            — discovered secret id → title
## }
##
## sanitize() is the single gate between persisted data and runtime state:
## boot, continue, and level restore must all pass loaded payloads through it.

const GameStateScript := preload("res://scripts/core/game_state.gd")
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
		"objective_snapshot": _objective_snapshot(raw.get("objective_snapshot", {})),
		"encounter_snapshot": _encounter_snapshot(raw.get("encounter_snapshot", {})),
		"secrets": _secrets(raw.get("secrets", {})),
	}
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
