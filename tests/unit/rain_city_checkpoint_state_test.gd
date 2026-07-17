extends SceneTree

const SCENE_PATH := "res://scenes/levels/episode_1_vancouver_waterfront.tscn"
const MISSION_ID := &"episode_1_vancouver_waterfront"
const CURRENT_REVISION := 2
const KNOWN_CHECKPOINT := &"checkpoint_terminal_service"
const KNOWN_POSITION := Vector3(7.0, 1.1, -98.0)

var failures: Array[String] = []


class FakeGameState extends Node:
	var continue_requested := true


class FakeSaveManager extends Node:
	var payload: Dictionary = {}

	func load_slot(_slot: StringName) -> Dictionary:
		return payload.duplicate(true)


func _initialize() -> void:
	_test_current_position_is_preserved()
	_test_stale_position_is_remapped()
	_test_missing_position_uses_authored_anchor()
	_test_unknown_stale_checkpoint_is_rejected()
	_test_unknown_positionless_checkpoint_is_rejected()

	if failures.is_empty():
		print("RAIN CITY CHECKPOINT STATE TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _base_payload(checkpoint_id: StringName, revision: int, include_position := true) -> Dictionary:
	var payload := {
		"scene_path": SCENE_PATH,
		"level_id": String(MISSION_ID),
		"checkpoint_id": String(checkpoint_id),
		"content_revision": revision,
	}
	if include_position:
		payload["position"] = [11.0, 2.0, -77.0]
	return payload


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


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
