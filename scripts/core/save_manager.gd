extends Node

signal save_completed(slot: StringName)
signal load_completed(slot: StringName, data: Dictionary)

# Save-schema history:
#   0 — unversioned prototype files: the checkpoint payload was stored bare,
#       without an envelope. Never written by shipped builds but tolerated so
#       hand-edited or pre-release files cannot break boot.
#   1 — envelope {version, saved_at, payload}; checkpoint payloads carried
#       scene_path/level_id/checkpoint_id/position and no difficulty.
#   2 — checkpoint payloads additionally record difficulty_id.
#   3 — checkpoint payloads persist objective, completed-encounter, and secret
#       snapshots. Active actors are intentionally rebuilt by the mission.
#   4 — campaign payloads are canonicalized in a new envelope-compatible shape.
#   5 — checkpoints and campaign snapshots persist content revision, unlocked weapons,
#       and active/campaign upgrades with deterministic sanitizer defaults.
const SAVE_VERSION := 5
const SAVE_DIRECTORY := "user://saves"

func save_slot(slot: StringName, payload: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(_save_directory_absolute())
	var path := _slot_path(slot)
	var temp_path := _temp_path(path)
	var backup_path := _backup_path(path)
	_remove_if_present(temp_path)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var envelope := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"payload": payload.duplicate(true),
	}
	file.store_string(JSON.stringify(envelope, "\t"))
	file.flush()
	file.close()

	# Godot cannot replace an existing file portably with a single rename. Keep
	# the previous complete file as a transaction backup until the new complete
	# file is in place. load_slot() can read that backup if the process exits in
	# the narrow interval between the two same-directory renames.
	_remove_if_present(backup_path)
	if FileAccess.file_exists(path):
		var backup_error := DirAccess.rename_absolute(path, backup_path)
		if backup_error != OK:
			_remove_if_present(temp_path)
			return backup_error
	var commit_error := DirAccess.rename_absolute(temp_path, path)
	if commit_error != OK:
		_remove_if_present(temp_path)
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, path)
		return commit_error
	_remove_if_present(backup_path)
	save_completed.emit(slot)
	return OK

func load_slot(slot: StringName) -> Dictionary:
	var path := _slot_path(slot)
	var readable_path := _readable_slot_path(path)
	if readable_path.is_empty():
		return {}
	var file := FileAccess.open(readable_path, FileAccess.READ)
	if file == null:
		return {}
	# Instance parsing keeps a corrupt save from spamming engine errors at boot;
	# the warning below is the intentional, structured signal.
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or json.data is not Dictionary:
		DebugLog.warn("Save file is not readable JSON", {"slot": String(slot)})
		return {}
	var parsed: Dictionary = json.data
	var version := _envelope_version(parsed)
	if version > SAVE_VERSION:
		# A newer build wrote this file. Refuse to guess at its contract and
		# leave the file untouched for that build to read again.
		DebugLog.warn("Save schema is newer than this build", {"slot": String(slot), "version": version})
		return {}
	var payload: Variant = parsed if version == 0 else parsed.get("payload", {})
	if payload is not Dictionary:
		DebugLog.warn("Save payload is malformed", {"slot": String(slot), "version": version})
		return {}
	var migrated := _migrate(version, payload)
	load_completed.emit(slot, migrated)
	return migrated

func delete_slot(slot: StringName) -> Error:
	var path := _slot_path(slot)
	var result := OK
	for candidate: String in [path, _temp_path(path), _backup_path(path)]:
		if not FileAccess.file_exists(candidate):
			continue
		var remove_error := DirAccess.remove_absolute(candidate)
		if result == OK and remove_error != OK:
			result = remove_error
	return result

func _envelope_version(parsed: Dictionary) -> int:
	# Version 0 means "unversioned legacy": the dictionary itself is the payload.
	var value: Variant = parsed.get("version")
	if value is int or value is float:
		return maxi(0, int(value))
	return 0

func _migrate(version: int, payload: Dictionary) -> Dictionary:
	# Migrations are deterministic, additive, and never invent progression: a
	# payload that does not look like the slot it claims to be stays untouched
	# and the consumer's sanitizer decides whether it is usable.
	var migrated := payload.duplicate(true)
	for from_version in range(version, SAVE_VERSION):
		match from_version:
			0, 1:
				# v2 makes difficulty_id canonical for checkpoint payloads.
				# Only checkpoint-shaped payloads receive the safe default.
				if _is_checkpoint_payload(migrated) and not migrated.has("difficulty_id"):
					migrated["difficulty_id"] = "classic"
			2:
				if _is_checkpoint_payload(migrated):
					if not migrated.has("objective_snapshot"):
						migrated["objective_snapshot"] = {"progress": {}, "completed": []}
					if not migrated.has("encounter_snapshot"):
						migrated["encounter_snapshot"] = {"completed": []}
					if not migrated.has("secrets"):
						migrated["secrets"] = {}
			3:
				# v4 canonicalizes campaign payload collections while leaving
				# checkpoint payloads semantically unchanged.
				if _is_campaign_payload(migrated):
					if not migrated.has("completed_missions"):
						migrated["completed_missions"] = []
					if not migrated.has("unlocked_missions"):
						migrated["unlocked_missions"] = []
					if not migrated.has("mission_records"):
						migrated["mission_records"] = {}
			4:
				# v5 adds loadout revision/upgrades keys for deterministic payload
				# migration; campaign and checkpoint payloads remain semantically intact.
				if _is_checkpoint_payload(migrated):
					if not migrated.has("content_revision"):
						migrated["content_revision"] = 0
					if not migrated.has("unlocked_weapons"):
						migrated["unlocked_weapons"] = []
					if not migrated.has("active_mission_upgrades"):
						migrated["active_mission_upgrades"] = {}
				if _is_campaign_payload(migrated):
					if not migrated.has("campaign_upgrades"):
						migrated["campaign_upgrades"] = {}
	return migrated

func _is_checkpoint_payload(payload: Dictionary) -> bool:
	return payload.has("scene_path") or payload.has("level_id") or payload.has("checkpoint_id")

func _is_campaign_payload(payload: Dictionary) -> bool:
	return payload.has("completed_missions") or payload.has("unlocked_missions") or payload.has("mission_records")

func _slot_path(slot: StringName) -> String:
	var safe_slot := String(slot).validate_filename()
	return "%s/%s.json" % [_save_directory(), safe_slot]

func _save_directory() -> String:
	var isolated_test_root := OS.get_environment("COBIE_TEST_SAVE_ROOT").strip_edges()
	return isolated_test_root if not isolated_test_root.is_empty() else SAVE_DIRECTORY

func _save_directory_absolute() -> String:
	var directory := _save_directory()
	return ProjectSettings.globalize_path(directory) if directory.begins_with("user://") or directory.begins_with("res://") else directory

func _temp_path(path: String) -> String:
	return "%s.tmp" % path

func _backup_path(path: String) -> String:
	return "%s.bak" % path

func _readable_slot_path(path: String) -> String:
	if FileAccess.file_exists(path):
		return path
	var backup_path := _backup_path(path)
	if not FileAccess.file_exists(backup_path):
		return ""
	# Complete a transaction interrupted after live -> backup. If restoration
	# itself fails, reading the complete backup still preserves player progress.
	if DirAccess.rename_absolute(backup_path, path) == OK:
		return path
	return backup_path

func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
