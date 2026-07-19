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
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return false
	return normalized_id in _progress.get("completed_missions", [])


func is_mission_unlocked(mission_id: StringName) -> bool:
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return false
	return normalized_id in _progress.get("unlocked_missions", [])


func mission_record(mission_id: StringName) -> Dictionary:
	var normalized_id := _mission_id(mission_id)
	var records: Dictionary = _progress.get("mission_records", {})
	return records.get(normalized_id, {}).duplicate(true)


func unlock_mission(mission_id: StringName) -> Error:
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return ERR_INVALID_PARAMETER
	var unlocked: Array = _progress.get("unlocked_missions", [])
	if normalized_id in unlocked:
		return OK
	var candidate := _progress.duplicate(true)
	unlocked = _string_set(unlocked)
	unlocked.append(normalized_id)
	candidate["unlocked_missions"] = unlocked
	return _persist(candidate)


func record_completion(mission_id: StringName, result: Dictionary, unlocked_missions: Array = [], campaign_upgrades: Array = []) -> Error:
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return ERR_INVALID_PARAMETER
	var completion_count := _nonnegative_int(result.get("completion_count"))
	if completion_count < 0 and result.has("completion_count"):
		return ERR_INVALID_PARAMETER
	if completion_count < 0:
		completion_count = 1
	if completion_count == 0:
		completion_count = 1
	var incoming := _sanitize_record(normalized_id, result)
	incoming["completion_count"] = completion_count
	var candidate := _progress.duplicate(true)
	var apply_error := _apply_completion(candidate, normalized_id, incoming, unlocked_missions, campaign_upgrades)
	if apply_error != OK:
		return apply_error
	var save_error := _persist(candidate)
	if save_error == OK:
		mission_completed.emit(StringName(normalized_id), mission_record(StringName(normalized_id)))
	return save_error


func commit_run_result(result: Dictionary) -> Error:
	if result == null:
		return ERR_INVALID_PARAMETER
	var normalized_id := _mission_id(result.get("mission_id"))
	if normalized_id.is_empty():
		return ERR_INVALID_PARAMETER
	var completion_count := _nonnegative_int(result.get("completion_count"))
	if completion_count < 0 and result.has("completion_count"):
		return ERR_INVALID_PARAMETER
	if completion_count < 0:
		completion_count = 1
	if completion_count == 0:
		completion_count = 1
	var raw_record := result.duplicate(true)
	raw_record.erase("mission_id")
	var unlocked_missions := _string_set(raw_record.get("unlocked_missions", []))
	var campaign_upgrades := _string_set(raw_record.get("campaign_upgrades", []))
	raw_record.erase("unlocked_missions")
	raw_record.erase("campaign_upgrades")
	raw_record.erase("mission_collectibles")
	raw_record.erase("completed_challenges")
	raw_record.erase("completion_count")
	raw_record.erase("run_mode")
	var incoming := _sanitize_record(normalized_id, raw_record)
	incoming["completion_count"] = completion_count
	if _run_mode(result.get("run_mode")) == "off_leash":
		var best_modes: Dictionary = incoming.get("best_modes", {})
		if best_modes is not Dictionary:
			best_modes = {}
		var off_leash := _nonnegative_int(best_modes.get("off_leash"))
		if off_leash < 0:
			off_leash = 0
		best_modes["off_leash"] = max(1, off_leash)
		incoming["best_modes"] = best_modes

	var candidate := _progress.duplicate(true)
	var apply_error := _apply_completion(candidate, normalized_id, incoming, unlocked_missions, campaign_upgrades)
	if apply_error != OK:
		return apply_error

	if result.has("mission_collectibles"):
		var mission_collectibles: Variant = result.get("mission_collectibles")
		var collectible_ids := _string_set(mission_collectibles)
		var collected: Dictionary = candidate.get("mission_collectibles", {}).duplicate(true)
		if _string_set_is_empty(collectible_ids):
			# skip malformed mission collectibles payloads
			pass
		else:
			var existing: Array = collected.get(normalized_id, [])
			var normalized_existing := _string_set(existing)
			for collectible_id: String in collectible_ids:
				if collectible_id not in normalized_existing:
					normalized_existing.append(collectible_id)
			normalized_existing.sort()
			collected[normalized_id] = normalized_existing
			candidate["mission_collectibles"] = collected

	if result.has("completed_challenges"):
		var added := _string_set(result.get("completed_challenges"))
		var current_challenges := _string_set(candidate.get("completed_challenges", []))
		if not _string_set_is_empty(added):
			for challenge_id: String in added:
				if challenge_id not in current_challenges:
					current_challenges.append(challenge_id)
			current_challenges.sort()
			candidate["completed_challenges"] = current_challenges

	var save_error := _persist(candidate)
	if save_error == OK:
		mission_completed.emit(StringName(normalized_id), mission_record(StringName(normalized_id)))
	return save_error


func collect_mini_ball(mission_id: StringName, collectible_id: StringName) -> Error:
	var normalized_mission := _mission_id(mission_id)
	var normalized_collectible := _mission_id(collectible_id)
	if normalized_mission.is_empty() or normalized_collectible.is_empty():
		return ERR_INVALID_PARAMETER
	var candidate := _progress.duplicate(true)
	var mission_collectibles: Dictionary = candidate.get("mission_collectibles", {}).duplicate(true)
	var collectibles: Array = mission_collectibles.get(normalized_mission, [])
	var normalized_collectibles := _string_set(collectibles)
	if normalized_collectible in normalized_collectibles:
		return OK
	normalized_collectibles.append(normalized_collectible)
	normalized_collectibles.sort()
	mission_collectibles[normalized_mission] = normalized_collectibles
	candidate["mission_collectibles"] = mission_collectibles
	return _persist(candidate)


func has_campaign_upgrade(upgrade_id: StringName) -> bool:
	var normalized_id := _mission_id(upgrade_id)
	if normalized_id.is_empty():
		return false
	var upgrades: Dictionary = _progress.get("campaign_upgrades", {})
	for raw_mission: Variant in upgrades:
		var mission_upgrades: Variant = upgrades[raw_mission]
		if mission_upgrades is Array and normalized_id in mission_upgrades:
			return true
	return false


func collection_count(mission_id: StringName) -> int:
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return 0
	var mission_collectibles: Dictionary = _progress.get("mission_collectibles", {})
	var collected: Variant = mission_collectibles.get(normalized_id, [])
	if collected is Array:
		return _string_set(collected).size()
	return 0


func challenge_count() -> int:
	return _string_set(_progress.get("completed_challenges", [])).size()


func mission_upgrades(mission_id: StringName) -> Array[String]:
	var normalized_id := _mission_id(mission_id)
	if normalized_id.is_empty():
		return []
	var upgrades: Dictionary = _progress.get("campaign_upgrades", {})
	var result: Array[String] = []
	for raw_upgrade: Variant in upgrades.get(normalized_id, []):
		var upgrade_id := _mission_id(raw_upgrade)
		if not upgrade_id.is_empty():
			result.append(upgrade_id)
	return result


func purchase_reward(reward_id: StringName, cost: int) -> Error:
	if cost < 0:
		return ERR_INVALID_PARAMETER
	var normalized_reward := _mission_id(reward_id)
	if normalized_reward.is_empty():
		return ERR_INVALID_PARAMETER
	var candidate := _progress.duplicate(true)
	var purchased: Array = _string_set(candidate.get("purchased_rewards", []))
	if normalized_reward in purchased:
		return OK
	var wallet: Dictionary = candidate.get("wallet", {}).duplicate(true)
	if wallet is not Dictionary:
		wallet = {"compliance_tags": 0}
	var tags := _nonnegative_int(wallet.get("compliance_tags"))
	if tags < 0 or cost > tags:
		return ERR_INVALID_DATA
	purchased.append(normalized_reward)
	wallet["compliance_tags"] = tags - cost
	candidate["purchased_rewards"] = purchased
	candidate["wallet"] = wallet
	return _persist(candidate)


func equip_weapon_mod(weapon_id: StringName, mod_id: StringName) -> Error:
	var normalized_weapon := _mission_id(weapon_id)
	var normalized_mod := _mission_id(mod_id)
	if normalized_weapon.is_empty() or normalized_mod.is_empty():
		return ERR_INVALID_PARAMETER
	if not _owns_reward(normalized_mod):
		return ERR_UNAUTHORIZED
	var candidate := _progress.duplicate(true)
	var equipped: Dictionary = candidate.get("equipped_weapon_mods", {}).duplicate(true)
	if not equipped is Dictionary:
		equipped = {}
	if equipped.get(normalized_weapon, "") == normalized_mod:
		return OK
	equipped[normalized_weapon] = normalized_mod
	candidate["equipped_weapon_mods"] = equipped
	return _persist(candidate)


func select_cosmetic(slot: StringName, reward_id: StringName) -> Error:
	var slot_id := _mission_id(slot)
	var normalized_reward := _mission_id(reward_id)
	if slot_id.is_empty() or normalized_reward.is_empty():
		return ERR_INVALID_PARAMETER
	if not _owns_reward(normalized_reward):
		return ERR_UNAUTHORIZED
	var candidate := _progress.duplicate(true)
	var selected: Dictionary = candidate.get("selected_cosmetics", {}).duplicate(true)
	if not selected is Dictionary:
		selected = {}
	if selected.get(slot_id, "") == normalized_reward:
		return OK
	selected[slot_id] = normalized_reward
	candidate["selected_cosmetics"] = selected
	return _persist(candidate)


func replace_profile_from_import(raw: Variant) -> Error:
	if _save_manager == null:
		return ERR_UNCONFIGURED
	var sanitized := CampaignProgressPayload.sanitize(raw)
	if _progress == sanitized:
		return OK
	return _persist(sanitized)


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


func _apply_completion(candidate: Dictionary, mission_id: String, incoming: Dictionary, unlocked_missions: Array = [], campaign_upgrades: Array = []) -> Error:
	if mission_id.is_empty():
		return ERR_INVALID_PARAMETER
	var completion_count := _nonnegative_int(incoming.get("completion_count"))
	if completion_count < 0:
		return ERR_INVALID_PARAMETER
	var completed: Array = candidate.get("completed_missions", [])
	completed = _string_set(completed)
	if mission_id not in completed:
		completed.append(mission_id)
	candidate["completed_missions"] = completed

	var unlocked: Array = _string_set(candidate.get("unlocked_missions", []))
	if mission_id not in unlocked:
		unlocked.append(mission_id)
	for raw_id: String in unlocked_missions:
		var unlock_id := _mission_id(raw_id)
		if not unlock_id.is_empty() and unlock_id not in unlocked:
			unlocked.append(unlock_id)
	candidate["unlocked_missions"] = unlocked

	var upgrades_by_mission: Dictionary = candidate.get("campaign_upgrades", {}).duplicate(true)
	var durable_upgrades: Array = _string_set(upgrades_by_mission.get(mission_id, []))
	for raw_upgrade: String in campaign_upgrades:
		var upgrade_id := _mission_id(raw_upgrade)
		if not upgrade_id.is_empty() and upgrade_id not in durable_upgrades:
			durable_upgrades.append(upgrade_id)
	durable_upgrades.sort()
	upgrades_by_mission[mission_id] = durable_upgrades
	candidate["campaign_upgrades"] = upgrades_by_mission

	var records: Dictionary = candidate.get("mission_records", {}).duplicate(true)
	var current: Dictionary = records.get(mission_id, {}).duplicate(true)
	var merged_record := _merge_best_record(current, incoming)
	var completion := _nonnegative_int(merged_record.get("completion_count"))  # ensure explicit typed copy
	merged_record["completion_count"] = completion
	records[mission_id] = merged_record
	candidate["mission_records"] = records

	return OK


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
	if incoming.has("best_modes"):
		var merged_modes: Dictionary = merged.get("best_modes", {}).duplicate(true)
		if merged_modes is not Dictionary:
			merged_modes = {}
		var incoming_modes: Dictionary = incoming.best_modes
		if incoming_modes is Dictionary:
			var incoming_off := _nonnegative_int(incoming_modes.get("off_leash"))
			var merged_off := _nonnegative_int(merged_modes.get("off_leash"))
			if merged_off < 0:
				merged_off = 0
			if incoming_off >= 0:
				merged_modes["off_leash"] = maxi(merged_off, incoming_off)
			merged["best_modes"] = merged_modes
	if incoming.has("completion_count"):
		var completion_delta := _nonnegative_int(incoming.get("completion_count"))
		var current_count := _nonnegative_int(merged.get("completion_count"))
		if current_count < 0:
			current_count = 0
		if completion_delta > 0:
			merged["completion_count"] = current_count + completion_delta
	return merged


func mission_completed_count(mission_id: StringName) -> int:
	var record := mission_record(mission_id)
	return _nonnegative_int(record.get("completion_count"))


func _owns_reward(reward_id: String) -> bool:
	var purchased: Array = _progress.get("purchased_rewards", [])
	return reward_id in _string_set(purchased)


func _mission_id(value: Variant) -> String:
	if value is not String and value is not StringName:
		return ""
	var normalized := String(value).strip_edges()
	return normalized if _is_stable_id(normalized) else ""


func _is_stable_id(id: String) -> bool:
	if id.is_empty():
		return false
	if id.find(" ") != -1 or id.find("\t") != -1 or id.find("\n") != -1 or id.find("\r") != -1:
		return false
	return true


func _string_set(raw_value: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_value is not Array:
		return result
	for raw_id: Variant in raw_value:
		var stable_id := _mission_id(raw_id)
		if not stable_id.is_empty() and not stable_id in result:
			result.append(stable_id)
	return result


func _string_set_is_empty(value: Array[String]) -> bool:
	for raw_id: Variant in value:
		if _is_stable_id(String(raw_id).strip_edges()):
			return false
	return true


func _nonnegative_int(value: Variant) -> int:
	if value is int:
		return value if value >= 0 else -1
	if value is float and is_finite(value):
		var converted := int(value)
		return converted if converted >= 0 else -1
	return -1


func _run_mode(value: Variant) -> String:
	if value is String or value is StringName:
		var candidate := String(value).strip_edges().to_lower()
		if candidate == "standard" or candidate == "off_leash":
			return candidate
	return ""
