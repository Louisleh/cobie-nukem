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
	_test_checkpoint_isolation()
	_test_atomic_replacement_and_recovery()
	_test_corrupt_and_future_save_recovery()
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
	_expect(runtime.record_completion(&"episode_1_level_1", improved, [&"episode_1_vancouver_waterfront"]) == OK, "improved completion persists")
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
	runtime.load_progress()
	_expect(runtime.mission_record(&"episode_1_level_1") == record, "best result survives disk reload")


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
