extends SceneTree

const SCENE_PATH := "res://scenes/levels/episode_1_vancouver_waterfront.tscn"
const MISSION_ID := &"episode_1_vancouver_waterfront"
const CURRENT_REVISION := 2
const KNOWN_CHECKPOINT := &"checkpoint_terminal_service"
const KNOWN_POSITION := Vector3(7.0, 1.1, -98.0)
const RAIN_CITY_CARD := preload("res://resources/level/rain_city_card.tres") as LevelCardData

var failures: Array[String] = []


class FakeGameState extends Node:
	var continue_requested := true
	var restore_calls := 0
	var restored_tags := 0
	var restored_mode := &""

	func restore_progression_checkpoint(pending_tags: int, run_mode: String) -> void:
		restore_calls += 1
		restored_tags = pending_tags
		restored_mode = StringName(run_mode)


class FakeSaveManager extends Node:
	var payload: Dictionary = {}

	func load_slot(_slot: StringName) -> Dictionary:
		return payload.duplicate(true)


class CompletionSaveManager extends Node:
	var delete_calls := 0
	var delete_error := OK

	func delete_slot(_slot: StringName) -> Error:
		delete_calls += 1
		return delete_error


class CompletionProbeMission extends EpisodeOneVancouverWaterfront:
	var save_manager_override: Node
	var campaign_error := OK
	var campaign_calls := 0
	var transition_calls := 0
	var failure_reports: Array[String] = []

	func _get_save_manager() -> Node:
		return save_manager_override

	func _completion_difficulty_id() -> StringName:
		return &"classic"

	func get_level_summary() -> Dictionary:
		return {"level_id": "episode_1_vancouver_waterfront", "completion_time_msec": 1234}

	func _persist_campaign_completion(_summary: Dictionary, _save_manager: Node, _difficulty_id: StringName) -> Error:
		campaign_calls += 1
		return campaign_error

	func _start_completion_transition() -> void:
		transition_calls += 1

	func _report_persistence_failure(context: String, _save_error: Error) -> void:
		failure_reports.append(context)


class CheckpointProbeMission extends EpisodeOneVancouverWaterfront:
	var save_manager_override: Node
	var write_error := OK
	var write_calls := 0
	var failure_reports: Array[String] = []

	func _get_save_manager() -> Node:
		return save_manager_override

	func _build_checkpoint_payload(_checkpoint_id: StringName, _position_value: Vector3) -> Dictionary:
		return {"probe": true}

	func _write_checkpoint(_save_manager: Node, _payload: Dictionary) -> Error:
		write_calls += 1
		return write_error

	func _report_persistence_failure(context: String, _save_error: Error) -> void:
		failure_reports.append(context)


class SecretProbeMission extends EpisodeOneVancouverWaterfront:
	var checkpoint_writes := 0
	var last_announce := true

	func _save_checkpoint(_checkpoint_id: StringName, _position_value: Vector3, announce := true) -> Error:
		checkpoint_writes += 1
		last_announce = announce
		return OK


class ControlMethodProbeMission extends EpisodeOneVancouverWaterfront:
	func _active_control_method() -> StringName:
		return &"touch"


func _initialize() -> void:
	_test_current_position_is_preserved()
	_test_stale_position_is_remapped()
	_test_missing_position_uses_authored_anchor()
	_test_unknown_stale_checkpoint_is_rejected()
	_test_unknown_positionless_checkpoint_is_rejected()
	_test_checkpoint_restore_is_post_begin_payload()
	_test_completion_persistence_is_transactional_and_retryable()
	_test_checkpoint_success_is_announced_only_after_write()
	_test_secret_discovery_saves_once()
	_test_card_and_summary_metadata()

	if failures.is_empty():
		print("RAIN CITY CHECKPOINT STATE TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _base_payload(checkpoint_id: StringName, revision: int, include_position := true, pending_tags := -1, run_mode := &"standard") -> Dictionary:
	var payload := {
		"scene_path": SCENE_PATH,
		"level_id": String(MISSION_ID),
		"checkpoint_id": String(checkpoint_id),
		"content_revision": revision,
	}
	if include_position:
		payload["position"] = [11.0, 2.0, -77.0]
	if pending_tags >= 0:
		payload["pending_compliance_tags"] = pending_tags
		payload["run_mode"] = String(run_mode)
	return payload


func _test_checkpoint_restore_is_post_begin_payload() -> void:
	var metadata := LevelMetadata.new()
	metadata.level_id = MISSION_ID
	var game_state := FakeGameState.new()
	var save_manager := FakeSaveManager.new()
	save_manager.payload = _base_payload(KNOWN_CHECKPOINT, CURRENT_REVISION, true, 12, &"off_leash")
	var result := RainCityCheckpointState.consume_requested(
		metadata,
		CURRENT_REVISION,
		{KNOWN_CHECKPOINT: KNOWN_POSITION},
		game_state,
		save_manager
	)
	_expect(result.get("payload", {}).get("pending_compliance_tags", 0) == 12, "Payload preserves pending-compliance metadata")
	_expect(result.get("payload", {}).get("run_mode", "") == "off_leash", "Payload preserves run-mode metadata")
	_expect(game_state.restore_calls == 0, "consume_requested does not restore GameState progression before begin_run")
	_expect(not game_state.continue_requested, "continue request is still consumed")
	game_state.free()
	save_manager.free()


func _consume(payload: Dictionary) -> Dictionary:
	var metadata := LevelMetadata.new()
	metadata.level_id = MISSION_ID
	var game_state := FakeGameState.new()
	var save_manager := FakeSaveManager.new()
	save_manager.payload = payload
	var result := RainCityCheckpointState.consume_requested(
		metadata,
		CURRENT_REVISION,
		{KNOWN_CHECKPOINT: KNOWN_POSITION},
		game_state,
		save_manager
	)
	_expect(not game_state.continue_requested, "Continue request is consumed exactly once")
	game_state.free()
	save_manager.free()
	return result


func _test_current_position_is_preserved() -> void:
	var result := _consume(_base_payload(KNOWN_CHECKPOINT, CURRENT_REVISION))
	_expect(result.get("position") == Vector3(11.0, 2.0, -77.0), "Current-revision checkpoint preserves its finite saved position")


func _test_stale_position_is_remapped() -> void:
	var result := _consume(_base_payload(KNOWN_CHECKPOINT, CURRENT_REVISION - 1))
	_expect(result.get("position") == KNOWN_POSITION, "Stale checkpoint ignores obsolete coordinates and uses the authored anchor")


func _test_missing_position_uses_authored_anchor() -> void:
	var result := _consume(_base_payload(KNOWN_CHECKPOINT, CURRENT_REVISION, false))
	_expect(result.get("position") == KNOWN_POSITION, "Positionless known checkpoint uses the authored anchor")


func _test_unknown_stale_checkpoint_is_rejected() -> void:
	var result := _consume(_base_payload(&"removed_beta_checkpoint", CURRENT_REVISION - 1))
	_expect(result.is_empty(), "Unknown stale checkpoint is rejected instead of trusting obsolete coordinates")


func _test_unknown_positionless_checkpoint_is_rejected() -> void:
	var result := _consume(_base_payload(&"unknown_checkpoint", CURRENT_REVISION, false))
	_expect(result.is_empty(), "Unknown positionless checkpoint is rejected instead of spawning at world origin")


func _test_completion_persistence_is_transactional_and_retryable() -> void:
	var save_manager := CompletionSaveManager.new()
	var mission := CompletionProbeMission.new()
	mission.save_manager_override = save_manager
	mission.campaign_error = ERR_CANT_CREATE
	mission._begin_completion()
	_expect(not mission._completion_started, "Failed campaign persistence reopens completion for retry")
	_expect(mission.campaign_calls == 1, "Completion attempts campaign persistence exactly once")
	_expect(save_manager.delete_calls == 0, "Failed campaign persistence preserves the checkpoint")
	_expect(mission.transition_calls == 0, "Failed campaign persistence never starts victory transition")
	_expect(mission.failure_reports == ["campaign completion"], "Failed campaign persistence reports structured context")

	mission.campaign_error = OK
	mission._begin_completion()
	_expect(mission._completion_started, "Successful retry commits completion")
	_expect(mission.campaign_calls == 2, "Retry performs one fresh campaign write")
	_expect(save_manager.delete_calls == 1, "Checkpoint is deleted only after campaign persistence succeeds")
	_expect(mission.transition_calls == 1, "Victory transition starts only after durable campaign completion")
	mission._begin_completion()
	_expect(mission.campaign_calls == 2 and mission.transition_calls == 1, "Committed completion is idempotent")
	mission.free()
	save_manager.free()

	var cleanup_manager := CompletionSaveManager.new()
	cleanup_manager.delete_error = ERR_CANT_CREATE
	var cleanup_mission := CompletionProbeMission.new()
	cleanup_mission.save_manager_override = cleanup_manager
	cleanup_mission._begin_completion()
	_expect(not cleanup_mission._completion_started, "Failed checkpoint cleanup reopens completion for retry")
	_expect(cleanup_mission.campaign_calls == 1 and cleanup_manager.delete_calls == 1, "Checkpoint cleanup failure occurs after one durable campaign write")
	_expect(cleanup_mission.transition_calls == 0, "Checkpoint cleanup failure cannot start victory with a resumable completed checkpoint")
	_expect(cleanup_mission.failure_reports == ["completed checkpoint cleanup"], "Checkpoint cleanup failure reports its exact transaction stage")
	cleanup_manager.delete_error = OK
	cleanup_mission._begin_completion()
	_expect(cleanup_mission._completion_started and cleanup_mission.transition_calls == 1, "Checkpoint cleanup retry completes after the idempotent campaign rewrite")
	cleanup_mission.free()
	cleanup_manager.free()


func _test_checkpoint_success_is_announced_only_after_write() -> void:
	var save_manager := CompletionSaveManager.new()
	var mission := CheckpointProbeMission.new()
	mission.save_manager_override = save_manager
	mission.checkpoint_position = Vector3(0.0, 1.1, 8.0)
	var activations: Array[StringName] = []
	mission.checkpoint_activated.connect(func(checkpoint_id: StringName, _position: Vector3) -> void: activations.append(checkpoint_id))
	mission.write_error = ERR_CANT_CREATE
	_expect(mission._save_checkpoint(&"checkpoint_ruse_block", Vector3(0.0, 1.1, -23.0)) == ERR_CANT_CREATE, "Checkpoint write failure is returned")
	_expect(mission.checkpoint_position == Vector3(0.0, 1.1, 8.0), "Failed checkpoint write does not advance respawn state")
	_expect(activations.is_empty(), "Failed checkpoint write emits no success signal")
	_expect(mission.failure_reports == ["checkpoint"], "Failed checkpoint write reports structured context")

	mission.write_error = OK
	_expect(mission._save_checkpoint(&"checkpoint_ruse_block", Vector3(0.0, 1.1, -23.0)) == OK, "Checkpoint write success is returned")
	_expect(mission.checkpoint_position == Vector3(0.0, 1.1, -23.0), "Successful checkpoint write advances respawn state")
	_expect(activations == [&"checkpoint_ruse_block"], "Successful checkpoint write emits one activation")

	mission.save_manager_override = null
	_expect(mission._save_checkpoint(&"checkpoint_waterfront_seawall", Vector3(0.0, 1.1, -56.0)) == OK, "No-SaveManager test harness preserves checkpoint behavior")
	_expect(activations == [&"checkpoint_ruse_block", &"checkpoint_waterfront_seawall"], "No-SaveManager harness receives deterministic checkpoint signal")
	mission.free()
	save_manager.free()


func _test_secret_discovery_saves_once() -> void:
	var mission := SecretProbeMission.new()
	var discoveries := [0]
	mission.secret_found.connect(func(_id: StringName, _title: String, _found: int, _total: int) -> void: discoveries[0] += 1)
	mission._on_secret_requested(&"secret_downtown_alley", "SIREN ROUTE DISABLED", null)
	mission._on_secret_requested(&"secret_downtown_alley", "SIREN ROUTE DISABLED", null)
	_expect(mission.checkpoint_writes == 1, "Secret discovery immediately saves exactly once")
	_expect(not mission.last_announce, "Secret autosave does not present a duplicate checkpoint banner")
	_expect(discoveries[0] == 1 and mission.secrets.size() == 1, "Repeated secret request cannot duplicate completion or reward")
	mission.free()


func _test_card_and_summary_metadata() -> void:
	_expect(RAIN_CITY_CARD != null and RAIN_CITY_CARD.secrets == 4, "Rain City card advertises its four authored secrets")
	var mission := ControlMethodProbeMission.new()
	var summary := mission.get_level_summary()
	_expect(StringName(summary.get("control_method", &"")) == &"touch", "Rain City summary records the active control method")
	mission.free()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
