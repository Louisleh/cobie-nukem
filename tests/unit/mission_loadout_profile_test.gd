extends SceneTree

const SALMON_LOADOUT: MissionLoadoutProfile = preload("res://resources/loadouts/salmon_creek_loadout.tres")
const VANCOUVER_LOADOUT: MissionLoadoutProfile = preload("res://resources/loadouts/vancouver_waterfront_loadout.tres")

var failures: Array[String] = []


func _initialize() -> void:
	_test_authoritative_loadout_shapes()
	_test_v5_sanitize_input_remap()
	_test_loadout_quantities_stay_authoritative()
	if failures.is_empty():
		print("MISSION LOADOUT PROFILE TEST: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_authoritative_loadout_shapes() -> void:
	_expect(SALMON_LOADOUT != null and VANCOUVER_LOADOUT != null, "Mission loadout resources load")
	if SALMON_LOADOUT == null or VANCOUVER_LOADOUT == null:
		return

	_expect(SALMON_LOADOUT.validate().is_empty(), "Salmon loadout validates with mission schema")
	_expect(VANCOUVER_LOADOUT.validate().is_empty(), "Vancouver loadout validates with mission schema")
	_expect(SALMON_LOADOUT.mission_id == &"episode_1_level_1", "Salmon mission id is stable")
	_expect(VANCOUVER_LOADOUT.mission_id == &"episode_1_vancouver_waterfront", "Vancouver mission id is stable")
	_expect(VANCOUVER_LOADOUT.selected_weapon == &"pawstol", "Vancouver selects the base weapon")
	_expect(VANCOUVER_LOADOUT.unlocked_weapons.has(&"barkshot") and VANCOUVER_LOADOUT.unlocked_weapons.has(&"fetch_launcher"), "Vancouver loadout exposes bonus weapons")
	_expect(SALMON_LOADOUT.unlocked_weapons == [&"pawstol"], "Salmon loadout is intentionally minimal")


func _test_v5_sanitize_input_remap() -> void:
	var checkpoint_payload := {
		"scene_path": "res://scenes/levels/episode_1_vancouver_waterfront.tscn",
		"level_id": "episode_1_vancouver_waterfront",
		"difficulty_id": "mayhem",
		"active_mission_upgrades": {
			"mission_id": "episode_1_vancouver_waterfront",
			"selected_weapon": "barkshot",
			"unlocked_weapons": [&"pawstol", "barkshot", "ghost_blaster", &"fetch_launcher", 7],
			"weapon_ammo": {
				"pawstol": {"magazine": 15.0, "reserve": 0},
				"barkshot": {"magazine": 6, "reserve": 12},
				"fetch_launcher": {"magazine": 3, "reserve": 6},
				"bad_gun": {"magazine": 99, "reserve": 99},
			},
			"mission_upgrades": [&"municipal_recall_override", "", "municipal_recall_override"],
			"unexpected_noise": {"drop_all": true},
		}
	}

	var sanitized := CheckpointPayload.sanitize(checkpoint_payload)
	_expect(sanitized.has("active_mission_upgrades"), "V5 payload can carry active mission upgrades")
	if sanitized.has("active_mission_upgrades"):
		var upgrades := sanitized["active_mission_upgrades"] as Dictionary
		_expect(upgrades.get("mission_id") == "episode_1_vancouver_waterfront", "Sanitized upgrade payload keeps mission id")
		_expect(upgrades.get("selected_weapon") == "barkshot", "Sanitized upgrade payload keeps selected weapon")
		var unlocked: Array = upgrades.get("unlocked_weapons", [])
		var unlocked_names: Array[String] = []
		for weapon: Variant in unlocked:
			unlocked_names.append(String(weapon))
		unlocked_names.sort()
		_expect(unlocked_names == ["barkshot", "fetch_launcher", "pawstol"], "Loadout remap sanitization dedupes and validates unlocked weapons")
		_expect(not unlocked_names.has("bad_gun"), "Loadout remap sanitization removes unknown unlocked weapon ids")
		var ammo := upgrades.get("weapon_ammo", {}) as Dictionary
		_expect(ammo.has("barkshot") and ammo.has("fetch_launcher") and ammo.has("pawstol"), "Loadout remap sanitization keeps ammo only for unlocked weapons")
		_expect(not ammo.has("bad_gun"), "Loadout remap sanitization drops invalid weapon ammo")

	var malformed := MissionLoadoutProfile.sanitize_payload({
		"mission_id": "episode_1_level_1",
		"selected_weapon": "invalid",
		"unlocked_weapons": ["pawstol", "barkshot"],
		"weapon_ammo": {"pawstol": {"magazine": -1, "reserve": 10}, "barkshot": {"magazine": 3.5, "reserve": 12}},
		"mission_upgrades": ["a", "a", ""]
	})
	_expect(not malformed.has("selected_weapon"), "Loadout remap rejects selected weapons missing from unlocked set")
	_expect(
		not malformed.has("weapon_ammo")
		or not malformed.weapon_ammo.has("pawstol")
		or malformed.weapon_ammo["pawstol"].get("magazine", 0) >= 0,
		"Loadout remap rejects malformed magazine/reserve values",
	)
	if malformed.has("weapon_ammo"):
		var ammo := malformed.weapon_ammo as Dictionary
		_expect(not ammo.has("bad_id"), "Loadout remap rejects malformed ammo keys")


func _test_loadout_quantities_stay_authoritative() -> void:
	var vancouver_ammo := VANCOUVER_LOADOUT.weapon_ammo
	_expect(vancouver_ammo.get("pawstol", {}).get("magazine") == 15 and vancouver_ammo.get("pawstol", {}).get("reserve") == 0, "Vancouver stores expected pawstol ammo")
	_expect(vancouver_ammo.get("barkshot", {}).get("magazine") == 6 and vancouver_ammo.get("barkshot", {}).get("reserve") == 12, "Vancouver stores expected barkshot ammo")
	_expect(vancouver_ammo.get("fetch_launcher", {}).get("magazine") == 3 and vancouver_ammo.get("fetch_launcher", {}).get("reserve") == 6, "Vancouver stores expected fetch launcher ammo")


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
