extends Node

signal save_completed(slot: StringName)
signal load_completed(slot: StringName, data: Dictionary)

# Save-schema history:
#   0 — unversioned prototype files: the checkpoint payload was stored bare,
#       without an envelope. Never written by shipped builds but tolerated so
#       hand-edited or pre-release files cannot break boot.
#   1 — envelope {version, saved_at, payload}; checkpoint payloads carried
#       scene_path/level_id/checkpoint_id/position and no difficulty.
#   2 — current. Envelope unchanged; checkpoint payloads additionally record
#       difficulty_id (see CheckpointPayload for the canonical shape).
const SAVE_VERSION := 2
const SAVE_DIRECTORY := "user://saves"

func save_slot(slot: StringName, payload: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIRECTORY))
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var envelope := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"payload": payload.duplicate(true),
	}
	file.store_string(JSON.stringify(envelope, "\t"))
	save_completed.emit(slot)
	return OK

func load_slot(slot: StringName) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
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
	if not FileAccess.file_exists(path):
		return OK
	return DirAccess.remove_absolute(path)

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
				if migrated.has("scene_path") and not migrated.has("difficulty_id"):
					migrated["difficulty_id"] = "classic"
	return migrated

func _slot_path(slot: StringName) -> String:
	var safe_slot := String(slot).validate_filename()
	return "%s/%s.json" % [SAVE_DIRECTORY, safe_slot]
