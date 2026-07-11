extends Node

signal phase_changed(previous: Phase, current: Phase)
signal run_started()
signal run_ended(summary: Dictionary)
signal diagnostics_requested()

enum Phase { BOOT, MENU, PLAYING, PAUSED, VICTORY, GAME_OVER, DIAGNOSTICS }

var phase: Phase = Phase.BOOT
var current_level_id: StringName = &""
var run_stats: Dictionary = {}
var continue_requested := false

func begin_boot() -> void:
	_set_phase(Phase.BOOT)

func begin_run(level_id: StringName) -> void:
	current_level_id = level_id
	run_stats = {
		"started_at_msec": Time.get_ticks_msec(),
		"enemies_defeated": 0,
		"secrets_found": 0,
		"shots_fired": 0,
		"shots_hit": 0,
		"damage_taken": 0.0,
		"deaths": 0,
		"last_zone": "forbidden_field",
		"checkpoint_id": "start",
	}
	_set_phase(Phase.PLAYING)
	run_started.emit()

func finish_run(extra_summary: Dictionary = {}) -> Dictionary:
	var summary := run_stats.duplicate(true)
	summary.merge(extra_summary, true)
	summary["finished_at_msec"] = Time.get_ticks_msec()
	summary["duration_msec"] = summary.finished_at_msec - summary.get("started_at_msec", summary.finished_at_msec)
	summary["completed"] = true
	_set_phase(Phase.VICTORY)
	run_ended.emit(summary)
	return summary

func request_diagnostics() -> void:
	_set_phase(Phase.DIAGNOSTICS)
	diagnostics_requested.emit()

func set_paused(value: bool) -> void:
	get_tree().paused = value
	_set_phase(Phase.PAUSED if value else Phase.PLAYING)

func _set_phase(next_phase: Phase) -> void:
	if phase == next_phase:
		return
	var previous := phase
	phase = next_phase
	phase_changed.emit(previous, phase)
