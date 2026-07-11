extends Node

signal entry_added(level: StringName, message: String, context: Dictionary)

const REPORT_PATH := "user://diagnostics_report.txt"
var _entries: Array[Dictionary] = []

func info(message: String, context: Dictionary = {}) -> void:
	_record(&"INFO", message, context)

func warn(message: String, context: Dictionary = {}) -> void:
	_record(&"WARN", message, context)

func error(message: String, context: Dictionary = {}) -> void:
	_record(&"ERROR", message, context)

func entries() -> Array[Dictionary]:
	return _entries.duplicate(true)

func export_report(path: String = REPORT_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	for entry in _entries:
		file.store_line(JSON.stringify(entry))
	return OK

func _record(level: StringName, message: String, context: Dictionary) -> void:
	var entry := {
		"timestamp_msec": Time.get_ticks_msec(),
		"level": String(level),
		"message": message,
		"context": context.duplicate(true),
	}
	_entries.append(entry)
	if level == &"ERROR":
		push_error("%s %s" % [message, context])
	elif level == &"WARN":
		push_warning("%s %s" % [message, context])
	else:
		print("[Cobie] %s %s" % [message, context])
	entry_added.emit(level, message, context)

