class_name PlaytestReport
extends CanvasLayer

signal closed

var _summary: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%CopyButton.pressed.connect(_copy_report)
	%CloseButton.pressed.connect(close)

func open(summary: Dictionary = {}) -> void:
	_summary = _merged_summary(summary)
	%ReportText.text = _format_report(_summary)
	%CopyStatus.text = "SELECTABLE TEXT FALLBACK READY"
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%CopyButton.grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("menu_back"):
		close()
		get_viewport().set_input_as_handled()

func _copy_report() -> void:
	DisplayServer.clipboard_set(%ReportText.text)
	%CopyStatus.text = "COPIED — TEXT IT TO LOUIS WITH YOUR ANSWERS"

func _merged_summary(explicit: Dictionary) -> Dictionary:
	var merged: Dictionary = {}
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		merged = game_state.run_stats.duplicate(true)
		merged["level_id"] = String(game_state.current_level_id)
	merged.merge(explicit, true)
	if not merged.has("duration_msec") and merged.has("started_at_msec"):
		merged["duration_msec"] = Time.get_ticks_msec() - int(merged.started_at_msec)
	return merged

func _format_report(summary: Dictionary) -> String:
	var seconds := int(summary.get("duration_msec", 0)) / 1000
	var session_seed := "%08X" % abs(hash(str(summary) + BuildInfo.BUILD_ID))
	var platform := "%s / %s" % [OS.get_name(), "WEB" if OS.has_feature("web") else "NATIVE"]
	return """COBIE NUKEM PLAYTEST REPORT
Build: %s
Session: %s
Date: %s
Platform: %s
Input: %s
Level: %s
Completion: %s
Play time: %02d:%02d
Deaths: %d
Enemies: %d / %d
Secrets: %d / %d
Last zone: %s
Last checkpoint: %s

1. What was the most fun moment?

2. Where were you confused or stuck?

3. What is the first thing you would change?

Copy this report and text it to Louis with your answers.
""" % [
		BuildInfo.label(), session_seed, Time.get_datetime_string_from_system(), platform,
		String(summary.get("control_method", "keyboard_mouse")), String(summary.get("level_id", "no_dogs_allowed")),
		"COMPLETE" if bool(summary.get("completed", false)) else "IN PROGRESS",
		seconds / 60, seconds % 60, int(summary.get("deaths", 0)),
		int(summary.get("enemies_defeated", 0)), int(summary.get("enemies_total", 12)),
		int(summary.get("secrets_found", 0)), int(summary.get("secrets_total", 3)),
		String(summary.get("last_zone", "forbidden_field")), String(summary.get("checkpoint_id", "start")),
	]
