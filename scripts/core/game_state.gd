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
var difficulty_id: StringName = &"classic"

const DIFFICULTY_PATHS := {
	&"story": "res://resources/difficulty/story.tres",
	&"classic": "res://resources/difficulty/classic.tres",
	&"mayhem": "res://resources/difficulty/mayhem.tres",
}
var _difficulty_cache: Dictionary = {}

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
		"difficulty_id": String(difficulty_id),
	}
	_set_phase(Phase.PLAYING)
	run_started.emit()


func select_difficulty(value: StringName) -> bool:
	if not DIFFICULTY_PATHS.has(value): return false
	difficulty_id = value
	return true


func get_difficulty_profile() -> DifficultyProfile:
	return _profile_for(difficulty_id)


func difficulty_options() -> Array[DifficultyProfile]:
	# DIFFICULTY_PATHS preserves declaration order: story, classic, mayhem.
	var options: Array[DifficultyProfile] = []
	for id: StringName in DIFFICULTY_PATHS:
		options.append(_profile_for(id))
	return options


func _profile_for(id: StringName) -> DifficultyProfile:
	if not DIFFICULTY_PATHS.has(id): id = &"classic"
	if not _difficulty_cache.has(id):
		_difficulty_cache[id] = load(String(DIFFICULTY_PATHS[id])) as DifficultyProfile
	return _difficulty_cache[id]

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
