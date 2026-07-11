extends Node

signal save_completed(slot: StringName)
signal load_completed(slot: StringName, data: Dictionary)

const SAVE_VERSION := 1
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
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or parsed.get("version", -1) != SAVE_VERSION:
		DebugLog.warn("Rejected incompatible save", {"slot": String(slot)})
		return {}
	var payload: Dictionary = parsed.get("payload", {})
	load_completed.emit(slot, payload)
	return payload

func delete_slot(slot: StringName) -> Error:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return OK
	return DirAccess.remove_absolute(path)

func _slot_path(slot: StringName) -> String:
	var safe_slot := String(slot).validate_filename()
	return "%s/%s.json" % [SAVE_DIRECTORY, safe_slot]
