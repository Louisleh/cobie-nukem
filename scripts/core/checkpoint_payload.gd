class_name CheckpointPayload
extends RefCounted

## Canonical v2 checkpoint payload contract.
##
## {
##   "scene_path": "res://…​.tscn"    — must exist as a PackedScene
##   "level_id": String              — non-empty
##   "checkpoint_id": String         — defaults to "start"
##   "position": [x, y, z]           — finite floats; omitted when unusable
##   "difficulty_id": String         — key of GameState.DIFFICULTY_PATHS
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
