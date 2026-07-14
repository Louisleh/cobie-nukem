extends SceneTree

## Save-schema versioning, migration, and corrupt-payload recovery contract.
## Boot must never crash on any file in user://saves, and corrupt data must
## read as "no checkpoint" rather than invented progression.

const SLOT := &"qa_schema"
const CAMPAIGN_SLOT := &"qa_schema_campaign"
const CHECKPOINT_SCENE := "res://scenes/levels/episode_1_level_1.tscn"

var failures := PackedStringArray()
var save_manager: Node


func _initialize() -> void:
	save_manager = get_root().get_node_or_null("SaveManager")
	if save_manager == null:
		push_error("SaveManager autoload unavailable")
		quit(1)
		return
	_test_new_save_creation()
	_test_current_version_round_trip()
	_test_campaign_round_trip()
	_test_campaign_migration_from_v3()
	_test_campaign_sanitize_shape()
	_test_checkpoint_and_campaign_slot_isolation()
	_test_unversioned_legacy_payload()
	_test_v1_schema_migration()
	_test_v2_schema_migration()
	_test_missing_fields()
	_test_wrong_field_types()
	_test_invalid_difficulty()
	_test_truncated_json()
	_test_non_dictionary_json()
	_test_future_schema_version()
	_test_route_snapshot_sanitization()
	_test_sanitize_canonical_shape()
	save_manager.delete_slot(SLOT)
	save_manager.delete_slot(CAMPAIGN_SLOT)
	if failures.is_empty():
		print("SAVE SCHEMA TESTS: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _test_new_save_creation() -> void:
	save_manager.delete_slot(SLOT)
	_expect(save_manager.save_slot(SLOT, _checkpoint_payload()) == OK, "new save writes cleanly")
	var raw := _read_raw()
	var parsed: Variant = JSON.parse_string(raw)
	_expect(parsed is Dictionary and int(parsed.get("version", -1)) == save_manager.SAVE_VERSION, "new save carries the current schema version")
	_expect(parsed is Dictionary and parsed.get("payload") is Dictionary, "new save nests the payload in the envelope")


func _test_current_version_round_trip() -> void:
	var payload := _checkpoint_payload()
	save_manager.save_slot(SLOT, payload)
	var loaded: Dictionary = save_manager.load_slot(SLOT)
	_expect(CheckpointPayload.sanitize(loaded) == CheckpointPayload.sanitize(payload), "current-version payload round trips semantically unchanged")
	var sanitized := CheckpointPayload.sanitize(loaded)
	_expect(sanitized.get("difficulty_id") == "mayhem", "round trip preserves a valid selected difficulty")
	_expect(sanitized.get("position") == [1.0, 2.0, 3.0], "round trip preserves the respawn position")


func _test_campaign_round_trip() -> void:
	var payload := _campaign_payload()
	save_manager.save_slot(CAMPAIGN_SLOT, payload)
	var loaded: Dictionary = save_manager.load_slot(CAMPAIGN_SLOT)
	_expect(CampaignProgressPayload.sanitize(loaded) == CampaignProgressPayload.sanitize(payload), "campaign payload round trips to canonical shape")


func _test_campaign_migration_from_v3() -> void:
	var checkpoint_payload := _checkpoint_payload()
	var checkpoint_pre := CheckpointPayload.sanitize(checkpoint_payload)
	_write_raw(JSON.stringify({"version": 3, "payload": checkpoint_payload}), SLOT)
	var checkpoint_loaded: Dictionary = CheckpointPayload.sanitize(save_manager.load_slot(SLOT))
	_expect(checkpoint_loaded == checkpoint_pre, "v3 checkpoint payload is migration semantic no-op")

	var raw_payload := {
		"completed_missions": ["mission_2", "mission_1", "mission_2"],
		"mission_records": {"mission_1": {"best_time_msec": 742000.0, "difficulty": "mayhem", "rank": "S", "best_secrets": 3, "total_secrets": 3}},
	}
	_write_raw(JSON.stringify({"version": 3, "payload": raw_payload}), CAMPAIGN_SLOT)
	var loaded: Dictionary = save_manager.load_slot(CAMPAIGN_SLOT)
	var expected := CampaignProgressPayload.sanitize(raw_payload)
	_expect(CampaignProgressPayload.sanitize(loaded) == expected, "v3 campaign migration preserves values")


func _test_campaign_sanitize_shape() -> void:
	var noisy := {
		"completed_missions": ["mission_b", "mission_a", "mission_a", 7],
		"unlocked_missions": ["unlock_2", "unlock_1", "", 9],
		"mission_records": {
			"mission_a": {"best_time_msec": 120.75, "rank": "s", "difficulty": "story", "best_secrets": 9, "total_secrets": 5},
			"mission_b": {"best_time_msec": -11.0, "rank": "Q", "difficulty": "ultra", "best_secrets": -2, "total_secrets": 4},
			"mission_c": "bad record",
			"mission_d": {"best_time_msec": 400.0, "difficulty": "classic", "best_secrets": 5, "total_secrets": 3},
		},
		"telemetry": {"bad": true},
	}
	var sanitized := CampaignProgressPayload.sanitize(noisy)
	_expect(sanitized.get("completed_missions") == ["mission_a", "mission_b"], "campaign sanitizer uniques and sorts completed missions")
	_expect(sanitized.get("unlocked_missions") == ["unlock_1", "unlock_2"], "campaign sanitizer uniques and sorts unlocked missions")
	var records: Dictionary = sanitized["mission_records"]
	_expect(records is Dictionary and records.size() == 3, "campaign sanitizer keeps only known top-level keys and mission ids")
	_expect(records["mission_a"]["best_time_msec"] == 120 and records["mission_a"]["rank"] == "S" and records["mission_a"]["difficulty"] == "story", "campaign sanitizer validates rank and difficulty")
	_expect(records["mission_a"]["best_secrets"] == 5 and records["mission_a"]["total_secrets"] == 5, "campaign sanitizer clamps best_secrets by total_secrets")
	var mission_b: Dictionary = records["mission_b"]
	_expect(not records.has("mission_c"), "malformed mission dictionary payloads are dropped")
	_expect(mission_b.get("total_secrets") == 4 and not mission_b.has("best_time_msec") and not mission_b.has("best_secrets") and not mission_b.has("rank") and not mission_b.has("difficulty"), "campaign sanitizer drops malformed mission values instead of inventing zero defaults")
	_expect(records["mission_d"]["best_time_msec"] == 400 and records["mission_d"]["best_secrets"] == 3 and records["mission_d"]["difficulty"] == "classic", "campaign sanitizer normalizes mission record values")


func _test_checkpoint_and_campaign_slot_isolation() -> void:
	var checkpoint := _checkpoint_payload()
	var campaign := _campaign_payload()
	save_manager.save_slot(SLOT, checkpoint)
	save_manager.save_slot(CAMPAIGN_SLOT, campaign)

	var checkpoint_loaded := CheckpointPayload.sanitize(save_manager.load_slot(SLOT))
	var campaign_loaded := CampaignProgressPayload.sanitize(save_manager.load_slot(CAMPAIGN_SLOT))
	var checkpoint_as_campaign := CampaignProgressPayload.sanitize(save_manager.load_slot(SLOT))
	var campaign_as_checkpoint := CheckpointPayload.sanitize(save_manager.load_slot(CAMPAIGN_SLOT))

	_expect(not checkpoint_loaded.is_empty(), "checkpoint slot remains readable as checkpoint")
	_expect(campaign_loaded == CampaignProgressPayload.sanitize(campaign), "campaign slot remains readable as campaign")
	_expect(campaign_as_checkpoint.is_empty(), "campaign data does not contaminate checkpoint restore")
	_expect(checkpoint_as_campaign.get("completed_missions") == [] and checkpoint_as_campaign.get("unlocked_missions") == [] and checkpoint_as_campaign.get("mission_records") == {}, "checkpoint payload does not inflate campaign state")


func _test_unversioned_legacy_payload() -> void:
	var legacy := _checkpoint_payload()
	legacy.erase("difficulty_id")
	_write_raw(JSON.stringify(legacy))
	var loaded: Dictionary = save_manager.load_slot(SLOT)
	_expect(loaded.get("difficulty_id") == "classic", "bare unversioned payload migrates with the safe default difficulty")
	_expect(loaded.get("scene_path") == CHECKPOINT_SCENE, "unversioned migration preserves the scene path")
	_expect(not CheckpointPayload.sanitize(loaded).is_empty(), "migrated legacy payload remains resumable")


func _test_v1_schema_migration() -> void:
	var v1_payload := _checkpoint_payload()
	v1_payload.erase("difficulty_id")
	_write_raw(JSON.stringify({"version": 1, "saved_at": "2026-01-01T00:00:00", "payload": v1_payload}))
	var loaded: Dictionary = save_manager.load_slot(SLOT)
	_expect(loaded.get("difficulty_id") == "classic", "v1 payload gains the default difficulty")
	_expect(loaded.get("checkpoint_id") == "lab_entry", "v1 migration preserves campaign progress")
	var non_checkpoint := {"best_time_msec": 742000.0}
	_write_raw(JSON.stringify({"version": 1, "payload": non_checkpoint}))
	_expect(save_manager.load_slot(SLOT) == non_checkpoint, "migration does not fabricate fields on non-checkpoint payloads")


func _test_v2_schema_migration() -> void:
	var v2_payload := _checkpoint_payload()
	v2_payload.erase("objective_snapshot")
	v2_payload.erase("encounter_snapshot")
	v2_payload.erase("secrets")
	_write_raw(JSON.stringify({"version": 2, "payload": v2_payload}))
	var loaded: Dictionary = save_manager.load_slot(SLOT)
	_expect(loaded.get("objective_snapshot") == {"progress": {}, "completed": []}, "v2 gains an empty objective snapshot")
	_expect(loaded.get("encounter_snapshot") == {"completed": []}, "v2 gains an empty encounter snapshot")
	_expect(loaded.get("secrets") == {}, "v2 gains an empty secret snapshot")


func _test_missing_fields() -> void:
	_expect(CheckpointPayload.sanitize({}) == {}, "empty payload is not resumable")
	var no_level := _checkpoint_payload(); no_level.erase("level_id")
	_expect(CheckpointPayload.sanitize(no_level) == {}, "missing level id is not resumable")
	var no_position := _checkpoint_payload(); no_position.erase("position")
	var sanitized := CheckpointPayload.sanitize(no_position)
	_expect(not sanitized.is_empty() and not sanitized.has("position"), "missing position falls back to the level default spawn")


func _test_wrong_field_types() -> void:
	var wrong := _checkpoint_payload()
	wrong["position"] = "over there"
	wrong["checkpoint_id"] = 7
	var sanitized := CheckpointPayload.sanitize(wrong)
	_expect(not sanitized.has("position"), "non-array position is dropped")
	_expect(sanitized.get("checkpoint_id") == "start", "non-string checkpoint id falls back to start")
	var wrong_level := _checkpoint_payload(); wrong_level["level_id"] = 42
	_expect(CheckpointPayload.sanitize(wrong_level) == {}, "non-string level id is not resumable")
	var bad_numbers := _checkpoint_payload(); bad_numbers["position"] = [1.0, "two", 3.0]
	_expect(not CheckpointPayload.sanitize(bad_numbers).has("position"), "mixed-type position is dropped")
	var non_finite := _checkpoint_payload(); non_finite["position"] = [1.0, INF, 3.0]
	_expect(not CheckpointPayload.sanitize(non_finite).has("position"), "non-finite position is dropped")


func _test_invalid_difficulty() -> void:
	var payload := _checkpoint_payload()
	payload["difficulty_id"] = "nightmare"
	_expect(CheckpointPayload.sanitize(payload).get("difficulty_id") == "classic", "unknown difficulty id falls back to classic")
	payload["difficulty_id"] = 3
	_expect(CheckpointPayload.sanitize(payload).get("difficulty_id") == "classic", "non-string difficulty falls back to classic")
	_expect(CheckpointPayload.valid_difficulty("story") == "story", "known difficulty ids pass through")


func _test_truncated_json() -> void:
	_write_raw("{\"version\": 2, \"payload\": {\"scene_pa")
	_expect(save_manager.load_slot(SLOT) == {}, "truncated JSON reads as no save")


func _test_non_dictionary_json() -> void:
	_write_raw("[1, 2, 3]")
	_expect(save_manager.load_slot(SLOT) == {}, "non-dictionary JSON reads as no save")
	_write_raw("null")
	_expect(save_manager.load_slot(SLOT) == {}, "null JSON reads as no save")


func _test_future_schema_version() -> void:
	var future := JSON.stringify({"version": 99, "payload": _checkpoint_payload()})
	_write_raw(future)
	_expect(save_manager.load_slot(SLOT) == {}, "future schema version is rejected cleanly")
	_expect(_read_raw() == future, "rejected future save is left on disk for the newer build")


func _test_sanitize_canonical_shape() -> void:
	var noisy := _checkpoint_payload()
	noisy["telemetry"] = {"clicks": 9000}
	noisy["cloud_id"] = "nope"
	var sanitized := CheckpointPayload.sanitize(noisy)
	var expected_keys := ["scene_path", "level_id", "checkpoint_id", "difficulty_id", "position", "objective_snapshot", "encounter_snapshot", "route_snapshot", "secrets"]
	for key: String in sanitized:
		_expect(key in expected_keys, "sanitize drops unknown key: %s" % key)
	var missing_scene := _checkpoint_payload()
	missing_scene["scene_path"] = "res://scenes/levels/deleted_level.tscn"
	_expect(CheckpointPayload.sanitize(missing_scene) == {}, "payload naming a missing scene is not resumable")


func _test_route_snapshot_sanitization() -> void:
	var payload := _checkpoint_payload()
	payload["route_snapshot"] = {
		"route_id": "vancouver_mission2_route",
		"current_zone": "terminal_service",
		"current_index": 3,
		"visited_zones": ["downtown_alley", "ruse_block", "waterfront_seawall", "terminal_service"],
		"checkpoint_id": "checkpoint_terminal_service",
		"is_completed": false,
		"injected": true,
	}
	var sanitized := CheckpointPayload.sanitize(payload)
	_expect(sanitized.route_snapshot.visited_zones == ["downtown_alley", "ruse_block", "waterfront_seawall", "terminal_service"], "route sanitizer preserves authored order")
	_expect(not sanitized.route_snapshot.has("injected"), "route sanitizer drops unknown fields")
	payload.route_snapshot["visited_zones"] = ["downtown_alley", "downtown_alley"]
	_expect(CheckpointPayload.sanitize(payload).route_snapshot == {}, "route sanitizer rejects duplicate visited zones")


func _checkpoint_payload() -> Dictionary:
	return {
		"scene_path": CHECKPOINT_SCENE,
		"level_id": "episode_1_level_1",
		"checkpoint_id": "lab_entry",
		"position": [1.0, 2.0, 3.0],
		"difficulty_id": "mayhem",
		"objective_snapshot": {"progress": {"reach_lab": 1}, "completed": ["reach_lab"]},
		"encounter_snapshot": {"completed": ["forbidden_field"]},
		"secrets": {"optional_sign": "SIGN SEEMS OPTIONAL"},
	}


func _campaign_payload() -> Dictionary:
	return {
		"completed_missions": ["mission_2", "mission_1", "mission_2"],
		"unlocked_missions": ["mission_1", "mission_3"],
		"mission_records": {
			"mission_1": {"best_time_msec": 742000.0, "rank": "B", "difficulty": "story", "best_secrets": 2, "total_secrets": 5},
			"mission_2": {"best_time_msec": 120000.0, "rank": "A", "difficulty": "mayhem", "best_secrets": 1, "total_secrets": 3},
		},
	}


func _write_raw(text: String, slot: StringName = SLOT) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open("user://saves/%s.json" % String(slot).validate_filename(), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _read_raw(slot: StringName = SLOT) -> String:
	var file := FileAccess.open("user://saves/%s.json" % String(slot).validate_filename(), FileAccess.READ)
	if file == null: return ""
	return file.get_as_text()


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
