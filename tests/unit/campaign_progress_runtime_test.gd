extends SceneTree

const CAMPAIGN_SLOT := &"campaign_progress"
const CHECKPOINT_SLOT := &"checkpoint"

var failures := PackedStringArray()
var save_manager: Node
var runtime: CampaignProgressRuntime


func _initialize() -> void:
	save_manager = get_root().get_node_or_null("SaveManager")
	if save_manager == null:
		push_error("SaveManager autoload unavailable")
		quit(1)
		return
	save_manager.delete_slot(CAMPAIGN_SLOT)
	save_manager.delete_slot(CHECKPOINT_SLOT)
	runtime = CampaignProgressRuntime.new()
	get_root().add_child(runtime)
	_expect(runtime.configure(save_manager), "runtime accepts the injected save service")
	_test_empty_and_unlock_round_trip()
	_test_completion_merges_best_results()
	_test_v6_completion_runtime_extensions()
	_test_v6_profile_import_rewards_collections()
	_test_v6_commit_run_result_tracking()
	_test_checkpoint_isolation()
	_test_atomic_replacement_and_recovery()
	_test_corrupt_and_future_save_recovery()
	_test_v4_preview_completion_retains_access()
	_test_reset_is_campaign_only()
	runtime.queue_free()
	save_manager.delete_slot(CAMPAIGN_SLOT)
	save_manager.delete_slot(CHECKPOINT_SLOT)
	if failures.is_empty():
		print("CAMPAIGN PROGRESS RUNTIME TEST: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_empty_and_unlock_round_trip() -> void:
	var loaded := runtime.load_progress()
	_expect(loaded == CampaignProgressPayload.sanitize({}), "missing campaign save loads canonical empty progress")
	_expect(runtime.unlock_mission(&"episode_1_level_1") == OK, "first mission unlock persists")
	_expect(runtime.unlock_mission(&"episode_1_level_1") == OK, "duplicate unlock is an idempotent success")
	_expect(runtime.unlock_mission(&"") == ERR_INVALID_PARAMETER, "empty mission id is rejected")
	loaded = runtime.load_progress()
	_expect(loaded.unlocked_missions == ["episode_1_level_1"], "unlocked mission survives reload exactly once")


func _test_completion_merges_best_results() -> void:
	var first := {
		"best_time_msec": 900000,
		"rank": "C",
		"difficulty": "story",
		"best_secrets": 1,
		"total_secrets": 4,
	}
	_expect(runtime.record_completion(&"episode_1_level_1", first, [&"episode_1_vancouver_waterfront"]) == OK, "first completion persists")
	var improved := {
		"best_time_msec": 720000,
		"rank": "A",
		"difficulty": "mayhem",
		"best_secrets": 3,
		"total_secrets": 4,
	}
	_expect(runtime.record_completion(&"episode_1_level_1", improved, [&"episode_1_vancouver_waterfront"], [&"municipal_recall_override", &"municipal_recall_override"]) == OK, "improved completion persists")
	var worse := {
		"best_time_msec": 800000,
		"rank": "B",
		"difficulty": "classic",
		"best_secrets": 2,
		"total_secrets": 3,
	}
	_expect(runtime.record_completion(&"episode_1_level_1", worse) == OK, "later non-best completion is accepted")
	var record := runtime.mission_record(&"episode_1_level_1")
	_expect(runtime.is_mission_completed(&"episode_1_level_1"), "completion is recorded")
	_expect(runtime.is_mission_unlocked(&"episode_1_vancouver_waterfront"), "completion unlock is recorded")
	_expect(record.get("best_time_msec") == 720000, "fastest completion remains best")
	_expect(record.get("rank") == "A", "highest rank remains best")
	_expect(record.get("difficulty") == "mayhem", "highest completed difficulty remains best")
	_expect(record.get("best_secrets") == 3 and record.get("total_secrets") == 4, "best secret result and authored total remain stable")
	_expect(record.get("completion_count") == 3, "completion count tracks number of recorded completions")
	_expect(runtime.mission_upgrades(&"episode_1_level_1") == ["municipal_recall_override"], "campaign upgrades persist uniquely by mission")
	runtime.load_progress()
	_expect(runtime.mission_record(&"episode_1_level_1") == record, "best result survives disk reload")


func _test_v6_completion_runtime_extensions() -> void:
	_expect(runtime.collection_count(&"episode_1_level_1") == 0, "collection count reads zero when no collectibles are tracked")
	_expect(runtime.challenge_count() == 0, "challenge count reads zero with no completed challenges")
	_expect(runtime.commit_run_result({"mission_id": "episode_1_level_1", "best_time_msec": 710000, "run_mode": "off_leash"}) == OK, "commit_run_result increments mission completion")
	var record := runtime.mission_record(&"episode_1_level_1")
	_expect(record.get("completion_count") == 4, "commit_run_result advances completion count")
	_expect(record.get("best_modes").get("off_leash", 0) >= 1, "commit_run_result persists off-leash mode best")
	_expect(runtime.has_campaign_upgrade(&"municipal_recall_override") == true, "upgrade queries scan mission upgrade map")


func _test_v6_profile_import_rewards_collections() -> void:
	var imported := {
		"wallet": {"compliance_tags": 2},
		"purchased_rewards": ["reward_one"],
		"mission_collectibles": {"episode_1_level_1": ["mini_ball_1", 1, "mini_ball_1"]},
		"completed_challenges": ["challenge_a", "challenge_a", ""],
		"selected_cosmetics": {"head_slot": "skin_one", "bad slot": "invalid"},
	}
	_expect(runtime.replace_profile_from_import(imported) == OK, "replace_profile_from_import stores sanitized content")
	_expect(runtime.collection_count(&"episode_1_level_1") == 1, "collection count uses persisted profile data")
	_expect(runtime.challenge_count() == 1, "challenge_count sanitizes and dedupes completed challenges")
	_expect(runtime.has_campaign_upgrade(&"reward_one") == false, "has_campaign_upgrade is upgrade-specific")
	_expect(runtime.purchase_reward(&"reward_two", 3) == ERR_INVALID_DATA, "reward purchases enforce sufficient balance")
	_expect(runtime.purchase_reward(&"reward_two", -1) == ERR_INVALID_PARAMETER, "reward purchases reject negative cost")
	_expect(runtime.equip_weapon_mod(&"weapon_alpha", &"reward_two") == ERR_UNAUTHORIZED, "equipping locked mods requires reward ownership")
	_expect(runtime.select_cosmetic(&"head_slot", &"skin_one") == ERR_UNAUTHORIZED, "selecting locked cosmetics requires reward ownership")
	_expect(runtime.purchase_reward(&"reward_two", 2) == OK, "valid reward purchase subtracts balance")
	_expect(runtime.purchase_reward(&"reward_two", 1) == OK, "reward purchases are idempotent after ownership")
	_expect(runtime.equip_weapon_mod(&"weapon_alpha", &"reward_two") == OK, "equipped mods persist after ownership")
	_expect(runtime.select_cosmetic(&"head_slot", &"reward_two") == OK, "selected cosmetics persist from purchased rewards")
	_expect(runtime.select_cosmetic(&"head_slot", &"reward_two") == OK, "selecting the same cosmetic is idempotent")


func _test_v6_commit_run_result_tracking() -> void:
	_expect(runtime.record_completion(&"episode_2_level_1", {"best_time_msec": 810000, "best_modes": {"off_leash": 2}}, [&"episode_2_level_2"], [&"mission_skip", &"mission_skip"]) == OK, "record_completion ignores duplicate upgrades")
	var record := runtime.mission_record(&"episode_2_level_1")
	_expect(record.get("completion_count") == 1, "record_completion includes completion counter")
	_expect(runtime.commit_run_result({"mission_id": "episode_2_level_1", "best_modes": {"off_leash": 1}, "completion_count": 2}) == OK, "commit_run_result merges completion counters")
	record = runtime.mission_record(&"episode_2_level_1")
	_expect(record.get("completion_count") == 3, "commit_run_result merges repeated completion data")
	_expect(record.get("best_modes").get("off_leash") == 2, "best mode metrics keep the best off-leash completion value")


func _test_checkpoint_isolation() -> void:
	var checkpoint := {
		"scene_path": "res://scenes/levels/episode_1_level_1.tscn",
		"level_id": "episode_1_level_1",
		"checkpoint_id": "lab_entry",
		"difficulty_id": "classic",
		"position": [0.0, 1.5, -87.0],
	}
	_expect(save_manager.save_slot(CHECKPOINT_SLOT, checkpoint) == OK, "checkpoint fixture writes atomically")
	var before := CheckpointPayload.sanitize(save_manager.load_slot(CHECKPOINT_SLOT))
	_expect(runtime.record_completion(&"episode_1_level_1", {"best_time_msec": 700000}) == OK, "campaign update succeeds beside checkpoint")
	var after := CheckpointPayload.sanitize(save_manager.load_slot(CHECKPOINT_SLOT))
	_expect(before == after and not after.is_empty(), "campaign update never mutates checkpoint slot")
	_expect(not CheckpointPayload.sanitize(save_manager.load_slot(CAMPAIGN_SLOT)), "campaign slot cannot be consumed as checkpoint")


func _test_atomic_replacement_and_recovery() -> void:
	var campaign_path := _slot_path(CAMPAIGN_SLOT)
	var checkpoint_path := _slot_path(CHECKPOINT_SLOT)
	_expect(save_manager.save_slot(CAMPAIGN_SLOT, {"unlocked_missions": ["mission_a"]}) == OK, "campaign slot first atomic write succeeds")
	_expect(save_manager.save_slot(CAMPAIGN_SLOT, {"unlocked_missions": ["mission_b"]}) == OK, "campaign slot atomic replacement succeeds")
	_expect(save_manager.save_slot(CHECKPOINT_SLOT, {"level_id": "episode_1_level_1"}) == OK, "checkpoint slot atomic replacement succeeds")
	_expect(not FileAccess.file_exists(campaign_path + ".tmp") and not FileAccess.file_exists(campaign_path + ".bak"), "successful campaign commit removes transaction files")
	_expect(not FileAccess.file_exists(checkpoint_path + ".tmp") and not FileAccess.file_exists(checkpoint_path + ".bak"), "successful checkpoint commit removes transaction files")

	var live_text := _read_path(campaign_path)
	_expect(DirAccess.rename_absolute(campaign_path, campaign_path + ".bak") == OK, "interrupted transaction fixture moves live campaign to backup")
	_expect(save_manager.load_slot(CAMPAIGN_SLOT).get("unlocked_missions") == ["mission_b"], "load recovers a complete transaction backup")
	_expect(FileAccess.file_exists(campaign_path) and not FileAccess.file_exists(campaign_path + ".bak"), "backup recovery restores canonical path")
	_expect(_read_path(campaign_path) == live_text, "backup recovery is byte preserving")


func _test_corrupt_and_future_save_recovery() -> void:
	var path := _slot_path(CAMPAIGN_SLOT)
	_write_path(path, "{not json")
	_expect(runtime.load_progress() == CampaignProgressPayload.sanitize({}), "corrupt campaign save falls back to empty progress")
	var future := JSON.stringify({"version": 99, "payload": {"completed_missions": ["future"]}})
	_write_path(path, future)
	_expect(runtime.load_progress() == CampaignProgressPayload.sanitize({}), "future campaign schema is rejected safely")
	_expect(_read_path(path) == future, "future campaign save remains untouched for the newer build")


func _test_v4_preview_completion_retains_access() -> void:
	var path := _slot_path(CAMPAIGN_SLOT)
	_write_path(path, JSON.stringify({
		"version": 4,
		"payload": {
			"completed_missions": ["episode_1_vancouver_waterfront"],
			"unlocked_missions": ["episode_1_vancouver_waterfront"],
			"mission_records": {"episode_1_vancouver_waterfront": {"rank": "C"}},
		},
	}))
	runtime.load_progress()
	var rain_city_card: LevelCardData = preload("res://resources/level/rain_city_card.tres")
	_expect(runtime.is_mission_completed(&"episode_1_vancouver_waterfront"), "v4 Vancouver completion migrates without requiring Salmon")
	_expect(rain_city_card.is_available(runtime), "migrated Alpha.10 Vancouver completion retains Rain City access")
	runtime.reset_progress()


func _test_reset_is_campaign_only() -> void:
	var checkpoint := {"level_id": "episode_1_level_1", "scene_path": "res://scenes/levels/episode_1_level_1.tscn"}
	save_manager.save_slot(CHECKPOINT_SLOT, checkpoint)
	save_manager.save_slot(CAMPAIGN_SLOT, {"completed_missions": ["episode_1_level_1"]})
	_expect(runtime.reset_progress() == OK, "campaign reset succeeds")
	_expect(save_manager.load_slot(CAMPAIGN_SLOT).is_empty(), "campaign reset deletes campaign slot")
	_expect(not save_manager.load_slot(CHECKPOINT_SLOT).is_empty(), "campaign reset leaves checkpoint slot intact")


func _slot_path(slot: StringName) -> String:
	return "user://saves/%s.json" % String(slot).validate_filename()


func _read_path(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _write_path(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
