class_name CampaignProgressRuntime
extends Node

## Mission-independent owner for durable campaign completion and best results.
## The runtime is explicitly configured with SaveManager; it is not an autoload
## and never reads, writes, or deletes the checkpoint slot.

signal progress_loaded(progress: Dictionary)
signal progress_changed(progress: Dictionary)
signal mission_completed(mission_id: StringName, record: Dictionary)

const SLOT := &"campaign_progress"
const RANK_PRIORITY := {"D": 1, "C": 2, "B": 3, "A": 4, "S": 5}
const DIFFICULTY_PRIORITY := {"story": 1, "classic": 2, "mayhem": 3}

var _save_manager: Node
var _progress := CampaignProgressPayload.sanitize({})
var _loaded := false


func configure(save_manager: Node) -> bool:
	if save_manager == null or not save_manager.has_method("load_slot") or not save_manager.has_method("save_slot") or not save_manager.has_method("delete_slot"):
		return false
	_save_manager = save_manager
	return true


func load_progress() -> Dictionary:
	_progress = CampaignProgressPayload.sanitize({})
	if _save_manager != null:
		_progress = CampaignProgressPayload.sanitize(_save_manager.load_slot(SLOT))
	_loaded = true
	var result := snapshot()
	progress_loaded.emit(result)
	return result


func snapshot() -> Dictionary:
	return _progress.duplicate(true)


func is_loaded() -> bool:
	return _loaded


func is_mission_completed(mission_id: StringName) -> bool:
	return String(mission_id) in _progress.get("completed_missions", [])


func is_mission_unlocked(mission_id: StringName) -> bool:
	return String(mission_id) in _progress.get("unlocked_missions", [])


func mission_record(mission_id: StringName) -> Dictionary:
	var records: Dictionary = _progress.get("mission_records", {})
	return records.get(String(mission_id), {}).duplicate(true)


func unlock_mission(mission_id: StringName) -> Error:
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return ERR_INVALID_PARAMETER
	var candidate := snapshot()
	var unlocked: Array = candidate.get("unlocked_missions", [])
	if normalized_id in unlocked:
		return OK
	unlocked.append(normalized_id)
	candidate["unlocked_missions"] = unlocked
	return _persist(candidate)


func record_completion(mission_id: StringName, result: Dictionary, unlocked_missions: Array = [], campaign_upgrades: Array = []) -> Error:
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return ERR_INVALID_PARAMETER

	var candidate := snapshot()
	var completed: Array = candidate.get("completed_missions", [])
	if normalized_id not in completed:
		completed.append(normalized_id)
	candidate["completed_missions"] = completed

	var unlocked: Array = candidate.get("unlocked_missions", [])
	if normalized_id not in unlocked:
		unlocked.append(normalized_id)
	for raw_id: Variant in unlocked_missions:
		var unlock_id := _mission_id(raw_id)
		if not unlock_id.is_empty() and unlock_id not in unlocked:
			unlocked.append(unlock_id)
	candidate["unlocked_missions"] = unlocked
	var upgrades_by_mission: Dictionary = candidate.get("campaign_upgrades", {}).duplicate(true)
	var durable_upgrades: Array = upgrades_by_mission.get(normalized_id, []).duplicate()
	for raw_upgrade: Variant in campaign_upgrades:
		var upgrade_id := _mission_id(raw_upgrade)
		if not upgrade_id.is_empty() and upgrade_id not in durable_upgrades:
			durable_upgrades.append(upgrade_id)
	if not durable_upgrades.is_empty():
		upgrades_by_mission[normalized_id] = durable_upgrades
	candidate["campaign_upgrades"] = upgrades_by_mission

	var records: Dictionary = candidate.get("mission_records", {}).duplicate(true)
	var current: Dictionary = records.get(normalized_id, {}).duplicate(true)
	var incoming := _sanitize_record(normalized_id, result)
	records[normalized_id] = _merge_best_record(current, incoming)
	candidate["mission_records"] = records

	var save_error := _persist(candidate)
	if save_error == OK:
		mission_completed.emit(StringName(normalized_id), mission_record(StringName(normalized_id)))
	return save_error


func mission_upgrades(mission_id: StringName) -> Array[String]:
	var upgrades: Dictionary = _progress.get("campaign_upgrades", {})
	var result: Array[String] = []
	for raw_upgrade: Variant in upgrades.get(String(mission_id), []):
		result.append(String(raw_upgrade))
	return result


func reset_progress() -> Error:
	if _save_manager == null:
		return ERR_UNCONFIGURED
	var delete_error: Error = _save_manager.delete_slot(SLOT)
	if delete_error != OK:
		return delete_error
	_progress = CampaignProgressPayload.sanitize({})
	_loaded = true
	progress_changed.emit(snapshot())
	return OK


func _persist(candidate: Dictionary) -> Error:
	if _save_manager == null:
		return ERR_UNCONFIGURED
	var sanitized := CampaignProgressPayload.sanitize(candidate)
	var save_error: Error = _save_manager.save_slot(SLOT, sanitized)
	if save_error != OK:
		return save_error
	_progress = sanitized
	_loaded = true
	progress_changed.emit(snapshot())
	return OK


func _sanitize_record(mission_id: String, result: Dictionary) -> Dictionary:
	var payload := CampaignProgressPayload.sanitize({
		"mission_records": {mission_id: result},
	})
	return payload.get("mission_records", {}).get(mission_id, {})


func _merge_best_record(current: Dictionary, incoming: Dictionary) -> Dictionary:
	var merged := current.duplicate(true)
	if incoming.has("best_time_msec"):
		var incoming_time := int(incoming.best_time_msec)
		if not merged.has("best_time_msec") or incoming_time < int(merged.best_time_msec):
			merged["best_time_msec"] = incoming_time
	if incoming.has("rank"):
		var incoming_rank := String(incoming.rank)
		if RANK_PRIORITY.get(incoming_rank, 0) > RANK_PRIORITY.get(String(merged.get("rank", "")), 0):
			merged["rank"] = incoming_rank
	if incoming.has("difficulty"):
		var incoming_difficulty := String(incoming.difficulty)
		if DIFFICULTY_PRIORITY.get(incoming_difficulty, 0) > DIFFICULTY_PRIORITY.get(String(merged.get("difficulty", "")), 0):
			merged["difficulty"] = incoming_difficulty
	if incoming.has("total_secrets"):
		merged["total_secrets"] = maxi(int(merged.get("total_secrets", 0)), int(incoming.total_secrets))
	if incoming.has("best_secrets"):
		merged["best_secrets"] = maxi(int(merged.get("best_secrets", 0)), int(incoming.best_secrets))
	if merged.has("best_secrets") and merged.has("total_secrets"):
		merged["best_secrets"] = mini(int(merged.best_secrets), int(merged.total_secrets))
	return merged


func _mission_id(value: Variant) -> String:
	if value is not String and value is not StringName:
		return ""
	return String(value).strip_edges()
