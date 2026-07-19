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
var local_metrics: Dictionary = {}

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
		"pending_compliance_tags": 0,
		"run_mode": "standard",
		"last_zone": "forbidden_field",
		"checkpoint_id": "start",
		"difficulty_id": String(difficulty_id),
	}
	local_metrics = {
		"frame_time_buckets": {"under_16_7": 0, "under_33_3": 0, "under_100": 0, "over_100": 0},
		"weapon_usage": {}, "weapon_hits": {}, "hit_results": {}, "damage_sources": {},
		"pickups_collected": 0, "navigation_recoveries": 0,
	}
	_set_phase(Phase.PLAYING)
	run_started.emit()


func _process(delta: float) -> void:
	if phase != Phase.PLAYING or local_metrics.is_empty(): return
	var bucket := "under_16_7" if delta <= 0.0167 else ("under_33_3" if delta <= 0.0333 else ("under_100" if delta <= 0.1 else "over_100"))
	local_metrics.frame_time_buckets[bucket] = int(local_metrics.frame_time_buckets.get(bucket, 0)) + 1


func record_shot(weapon_id: StringName) -> void:
	if run_stats.is_empty(): return
	_ensure_local_metrics()
	run_stats.shots_fired = int(run_stats.get("shots_fired", 0)) + 1
	var key := String(weapon_id)
	var usage: Dictionary = local_metrics.get("weapon_usage", {})
	usage[key] = int(usage.get(key, 0)) + 1
	local_metrics["weapon_usage"] = usage


func record_combat_result(event: CombatFeedbackEvent) -> void:
	if run_stats.is_empty(): return
	_ensure_local_metrics()
	var key := String(event.legacy_kind())
	var results: Dictionary = local_metrics.get("hit_results", {})
	results[key] = int(results.get(key, 0)) + 1
	local_metrics["hit_results"] = results
	if event.hit_type == CombatFeedbackEvent.HitType.ENEMY or event.hit_type == CombatFeedbackEvent.HitType.DESTRUCTIBLE:
		run_stats.shots_hit = int(run_stats.get("shots_hit", 0)) + 1
		var weapon_hits: Dictionary = local_metrics.get("weapon_hits", {})
		var weapon_key := String(event.weapon_id)
		weapon_hits[weapon_key] = int(weapon_hits.get(weapon_key, 0)) + 1
		local_metrics["weapon_hits"] = weapon_hits


func record_damage(amount: float, source: Node) -> void:
	if run_stats.is_empty(): return
	_ensure_local_metrics()
	run_stats.damage_taken = float(run_stats.get("damage_taken", 0.0)) + maxf(amount, 0.0)
	var key := "environment" if source == null else String(source.name)
	var sources: Dictionary = local_metrics.get("damage_sources", {})
	sources[key] = float(sources.get(key, 0.0)) + maxf(amount, 0.0)
	local_metrics["damage_sources"] = sources


func record_pickup() -> void:
	_ensure_local_metrics()
	local_metrics["pickups_collected"] = int(local_metrics.get("pickups_collected", 0)) + 1


func record_enemy_tag_value(enemy_definition: EnemyDefinition) -> int:
	if run_stats.is_empty() or enemy_definition == null: return 0
	var amount := clampi(int(ceil(float(enemy_definition.score_value) / 100.0)), 1, 25)
	run_stats["pending_compliance_tags"] = int(run_stats.get("pending_compliance_tags", 0)) + amount
	return amount


func restore_progression_checkpoint(pending_tags: int, run_mode: String) -> void:
	if run_stats.is_empty(): return
	run_stats["pending_compliance_tags"] = maxi(0, pending_tags)
	run_stats["run_mode"] = run_mode if run_mode == "off_leash" else "standard"


func _ensure_local_metrics() -> void:
	if not local_metrics.is_empty(): return
	local_metrics = {
		"frame_time_buckets": {"under_16_7": 0, "under_33_3": 0, "under_100": 0, "over_100": 0},
		"weapon_usage": {}, "weapon_hits": {}, "hit_results": {}, "damage_sources": {},
		"pickups_collected": 0, "navigation_recoveries": 0,
	}


func export_local_playtest_report(path := "user://playtest/latest.json") -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"build": BuildInfo.label(), "run": run_stats, "metrics": local_metrics}, "\t"))
	return OK


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
	summary["local_metrics"] = local_metrics.duplicate(true)
	_set_phase(Phase.VICTORY)
	run_ended.emit(summary)
	return summary

func mark_game_over() -> void:
	# Death is a first-class phase: frame metrics and pause/focus consumers must
	# not treat the death overlay as live gameplay.
	get_tree().paused = false
	_set_phase(Phase.GAME_OVER)

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
