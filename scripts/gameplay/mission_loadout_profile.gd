class_name MissionLoadoutProfile
extends Resource

## Canonical mission loadout payload used for v5 checkpoint carry state.
## {
##   "mission_id": StringName,
##   "selected_weapon": StringName,
##   "unlocked_weapons": [String],
##   "weapon_ammo": {
##     "weapon_id": {"magazine": int >= 0, "reserve": int >= 0}
##   },
##   "mission_upgrades": [String],
## }

const WEAPON_PATH := "res://resources/weapons/"

static func sanitize_payload(raw: Variant) -> Dictionary:
	if raw is not Dictionary:
		return {}

	var payload := raw as Dictionary
	var mission_id := _string_id(payload.get("mission_id", ""))
	var unlocked_weapons := _weapon_ids(payload.get("unlocked_weapons", []))
	var selected_weapon := _weapon_id(payload.get("selected_weapon", ""))
	var weapon_ammo := _weapon_ammo_map(payload.get("weapon_ammo", {}), unlocked_weapons)
	var mission_upgrades := _string_set(payload.get("mission_upgrades", []))

	var result := {}
	if not mission_id.is_empty():
		result["mission_id"] = mission_id
	if not selected_weapon.is_empty():
		result["selected_weapon"] = selected_weapon
	if not unlocked_weapons.is_empty():
		result["unlocked_weapons"] = unlocked_weapons
	if not weapon_ammo.is_empty():
		result["weapon_ammo"] = weapon_ammo
	if not mission_upgrades.is_empty():
		result["mission_upgrades"] = mission_upgrades
	return result


static func _string_id(raw_id: Variant) -> String:
	if raw_id is String or raw_id is StringName:
		return String(raw_id).strip_edges()
	return ""


static func _weapon_id(value: Variant) -> String:
	if value is String or value is StringName:
		var weapon_id := String(value).strip_edges()
		return weapon_id if _is_valid_weapon_id(weapon_id) else ""
	return ""


static func _string_set(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is not Array:
		return result
	for entry: Variant in value:
		var candidate := _string_id(entry)
		if candidate.is_empty() or candidate in result:
			continue
		result.append(candidate)
	result.sort()
	return result


static func _weapon_ids(value: Variant) -> Array[String]:
	return _string_set(value)


static func _weapon_ammo_map(value: Variant, unlocked_weapons: Array[String]) -> Dictionary:
	if value is not Dictionary:
		return {}
	var result := {}
	for raw_weapon_id: Variant in value:
		var weapon_id := _string_id(raw_weapon_id)
		if weapon_id.is_empty() or not _is_valid_weapon_id(weapon_id):
			continue
		var payload: Variant = value[raw_weapon_id]
		var sanitized := _weapon_ammo_entry(payload)
		if sanitized.is_empty():
			continue
		result[weapon_id] = sanitized
	for weapon_id: String in result.keys():
		if unlocked_weapons.size() > 0 and not weapon_id in unlocked_weapons:
			result.erase(weapon_id)
	return result


static func _weapon_ammo_entry(value: Variant) -> Dictionary:
	if value is not Dictionary:
		return {}
	var magazine := _finite_nonnegative_int(value.get("magazine", 0))
	var reserve := _finite_nonnegative_int(value.get("reserve", 0))
	if magazine < 0 or reserve < 0:
		return {}
	return {"magazine": magazine, "reserve": reserve}


static func _finite_nonnegative_int(value: Variant) -> int:
	if value is int:
		return value if value >= 0 else -1
	if value is float and is_finite(value):
		return int(value) if value >= 0.0 else -1
	return -1


static func _is_valid_weapon_id(weapon_id: String) -> bool:
	return not weapon_id.is_empty() and ResourceLoader.exists("%s%s.tres" % [WEAPON_PATH, weapon_id])
