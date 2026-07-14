class_name CampaignProgressPayload
extends RefCounted

## Canonical v4 campaign payload contract.
## {
##   "completed_missions": [String],  # sorted unique mission ids
##   "unlocked_missions": [String],   # sorted unique mission ids
##   "mission_records": {             # mission_id -> record
##     "mission_id": {
##       "best_time_msec": int >= 0,
##       "rank": StringName("S"|"A"|"B"|"C"|"D"|""), 
##       "difficulty": "story"|"classic"|"mayhem",
##       "best_secrets": int >= 0,
##       "total_secrets": int >= 0,
##     }
##   }
## }

const GameStateScript := preload("res://scripts/core/game_state.gd")
const VALID_DIFFICULTIES := ["story", "classic", "mayhem"]
const VALID_RANKS := ["", "S", "A", "B", "C", "D"]

static func sanitize(raw: Variant) -> Dictionary:
	if raw is not Dictionary:
		return {
			"completed_missions": [],
			"unlocked_missions": [],
			"mission_records": {},
		}

	var payload := raw as Dictionary
	return {
		"completed_missions": _string_set(payload.get("completed_missions", [])),
		"unlocked_missions": _string_set(payload.get("unlocked_missions", [])),
		"mission_records": _mission_records(payload.get("mission_records", {})),
	}

static func _string_set(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is not Array:
		return result
	for raw_id: Variant in value:
		if raw_id is String or raw_id is StringName:
			var id := String(raw_id).strip_edges()
			if not id.is_empty() and not id in result:
				result.append(id)
	result.sort()
	return result

static func _mission_records(value: Variant) -> Dictionary:
	var result := {}
	if value is not Dictionary:
		return result
	for raw_id: Variant in value:
		var mission_id := _string_id(raw_id)
		if mission_id.is_empty():
			continue
		var record := _mission_record(value[raw_id])
		if not record.is_empty():
			result[mission_id] = record
	return result

static func _mission_record(value: Variant) -> Dictionary:
	if value is not Dictionary:
		return {}

	var record := {}
	var best_time_msec := -1
	var best_secrets := -1
	var total_secrets := -1
	if value.has("best_time_msec"):
		best_time_msec = _finite_nonnegative_int(value.get("best_time_msec"))
	if best_time_msec >= 0:
		record["best_time_msec"] = best_time_msec
	var rank := _rank(value.get("rank"))
	if not rank.is_empty():
		record["rank"] = rank
	var difficulty := _difficulty(value.get("difficulty"))
	if not difficulty.is_empty():
		record["difficulty"] = difficulty
	if value.has("total_secrets"):
		total_secrets = _finite_nonnegative_int(value.get("total_secrets"))
	if value.has("best_secrets"):
		best_secrets = _finite_nonnegative_int(value.get("best_secrets"))
	if total_secrets >= 0:
		record["total_secrets"] = total_secrets
	if best_secrets >= 0 and total_secrets >= 0 and best_secrets > total_secrets:
		best_secrets = total_secrets
	if best_secrets >= 0:
		record["best_secrets"] = best_secrets
	return record

static func _difficulty(value: Variant) -> String:
	if value is String or value is StringName:
		var difficulty_id := String(value).strip_edges()
		if GameStateScript.DIFFICULTY_PATHS.has(StringName(difficulty_id)):
			return difficulty_id
	return ""

static func _rank(value: Variant) -> String:
	if value is String or value is StringName:
		var candidate := String(value).strip_edges().to_upper()
		if candidate in VALID_RANKS:
			return candidate
	return ""

static func _string_id(raw_id: Variant) -> String:
	if raw_id is String or raw_id is StringName:
		return String(raw_id).strip_edges()
	return ""

static func _finite_nonnegative_int(value: Variant) -> int:
	if value is int:
		return value if value >= 0 else -1
	if value is float and is_finite(value):
		if value < 0.0:
			return -1
		return int(value)
	return -1
