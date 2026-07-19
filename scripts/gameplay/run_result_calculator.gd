class_name RunResultCalculator
extends RefCounted

## Pure run-result projection used by mission progression and persistence layers.

const RANK_BY_MEDAL_COUNT := {
	0: "D",
	1: "D",
	2: "C",
	3: "B",
	4: "A",
	5: "S",
}
const RANK_TITLES := {
	"S": "TOP DOG",
	"A": "BEST IN SHOW",
	"B": "GOOD DOG",
	"C": "KEEP FETCHING",
	"D": "RUFF RUN",
}


static func calculate(run: Dictionary, profile: MissionProgressionProfile) -> Dictionary:
	var normalized_profile := _normalize_profile(profile)
	var normalized_run := _normalize_run(run, normalized_profile)
	var par_time_msec := int(normalized_profile.get("par_time_msec", 0))
	var completion_time_msec := int(normalized_run.get("completion_time_msec", 0))
	var enemies_total := int(normalized_run.get("enemies_total", 0))
	var enemies_defeated := int(normalized_run.get("enemies_defeated", 0))
	var secrets_total := int(normalized_run.get("secrets_total", 0))
	var secrets_found := int(normalized_run.get("secrets_found", 0))
	var shots_fired := int(normalized_run.get("shots_fired", 0))
	var shots_hit := int(normalized_run.get("shots_hit", 0))
	var deaths := int(normalized_run.get("deaths", 0))
	var collectible_total := int(normalized_run.get("collectible_total", 0))
	var collectibles_found := int(normalized_run.get("collectibles_found", 0))
	var accuracy := _safe_divide(float(shots_hit), float(shots_fired))
	var all_medals := {
		"par_time": par_time_msec > 0 and completion_time_msec <= par_time_msec,
		"all_secrets": secrets_found >= secrets_total,
		"all_enemies": enemies_defeated >= enemies_total,
		"accuracy": accuracy >= 0.5,
		"zero_deaths": deaths == 0,
	}
	var medal_count := 0
	for medal_value in all_medals.values():
		if medal_value:
			medal_count += 1
	var rank: String = RANK_BY_MEDAL_COUNT.get(clampi(medal_count, 0, 5), "D") as String

	return {
		"mission_id": normalized_profile.get("mission_id", ""),
		"rank": rank,
		"rank_title": RANK_TITLES.get(rank, "RUFF RUN"),
		"medal_count": medal_count,
		"medals": all_medals,
		"completion_time_msec": completion_time_msec,
		"duration_msec": completion_time_msec,
		"accuracy": accuracy,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"deaths": deaths,
		"enemies_defeated": enemies_defeated,
		"enemies_total": enemies_total,
		"secrets_found": secrets_found,
		"secrets_total": secrets_total,
		"collectibles_found": collectibles_found,
		"collectible_total": collectible_total,
		"collection_status": normalized_profile.get("collection_status", "coming_soon"),
	}


static func _normalize_profile(profile: MissionProgressionProfile) -> Dictionary:
	var normalized := {
		"mission_id": "",
		"par_time_msec": 0,
		"enemies_total": 0,
		"secrets_total": 0,
		"collectible_total": 0,
		"collection_status": "coming_soon",
	}
	if profile == null or not (profile is MissionProgressionProfile):
		return normalized
	var mission_id := _stable_id(profile.mission_id)
	if mission_id.is_empty():
		return normalized
	normalized["mission_id"] = mission_id
	normalized["par_time_msec"] = maxi(0, int(profile.par_time_msec))
	normalized["enemies_total"] = maxi(0, int(profile.enemies_total))
	normalized["secrets_total"] = maxi(0, int(profile.secrets_total))
	normalized["collectible_total"] = maxi(0, int(profile.collectible_total))
	var status := String(profile.collection_status).strip_edges()
	if status == "active" or status == "coming_soon":
		normalized["collection_status"] = status
	return normalized


static func _normalize_run(raw_run: Dictionary, normalized_profile: Dictionary) -> Dictionary:
	var completion_time_msec := _to_nonnegative_int(raw_run.get("completion_time_msec", raw_run.get("duration_msec", 0)))
	var run_mission_id := _stable_id(raw_run.get("mission_id", raw_run.get("level_id", "")))
	var profile_enemies_total := int(normalized_profile.get("enemies_total", 0))
	var profile_secrets_total := int(normalized_profile.get("secrets_total", 0))
	var profile_collectible_total := int(normalized_profile.get("collectible_total", 0))
	var enemies_total := _to_nonnegative_int(raw_run.get("enemies_total", profile_enemies_total), profile_enemies_total)
	var enemies_defeated := _to_nonnegative_int(raw_run.get("enemies_defeated", normalized_profile.get("enemies_defeated", 0)), int(normalized_profile.get("enemies_defeated", 0)))
	var secrets_total := _to_nonnegative_int(raw_run.get("secrets_total", profile_secrets_total), profile_secrets_total)
	var secrets_found := _to_nonnegative_int(raw_run.get("secrets_found", 0), 0)
	var shots_fired := _to_nonnegative_int(raw_run.get("shots_fired", raw_run.get("shots", 0)), 0)
	var shots_hit := _to_nonnegative_int(raw_run.get("shots_hit", raw_run.get("shots_landed", 0)), 0)
	var deaths := _to_nonnegative_int(raw_run.get("deaths", raw_run.get("death_count", 0)), 0)
	var collectible_total := _to_nonnegative_int(raw_run.get("collectible_total", profile_collectible_total), profile_collectible_total)
	var collectibles_found := _to_nonnegative_int(raw_run.get("collectibles_found", 0))
	return {
		"mission_id": run_mission_id if run_mission_id != "" else normalized_profile.get("mission_id", ""),
		"completion_time_msec": completion_time_msec,
		"enemies_total": enemies_total,
		"enemies_defeated": enemies_defeated,
		"secrets_total": secrets_total,
		"secrets_found": secrets_found,
		"shots_fired": shots_fired,
		"shots_hit": shots_hit,
		"deaths": deaths,
		"collectible_total": collectible_total,
		"collectibles_found": collectibles_found,
	}


static func _safe_divide(numerator: float, denominator: float) -> float:
	if not is_finite(denominator) or denominator <= 0.0:
		return 0.0
	if not is_finite(numerator) or numerator <= 0.0:
		return 0.0
	var value := numerator / denominator
	if not is_finite(value):
		return 0.0
	return clampf(value, 0.0, 1.0)


static func _to_nonnegative_int(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return value if value >= 0 else max(0, fallback)
	if value is float:
		if not is_finite(value):
			return max(0, fallback)
		return int(value) if value >= 0.0 else max(0, fallback)
	return max(0, fallback)


static func _stable_id(value: Variant) -> String:
	if value is not String and value is not StringName:
		return ""
	var id := String(value).strip_edges()
	if id.is_empty() or id.find(" ") != -1 or id.find("\t") != -1 or id.find("\n") != -1 or id.find("\r") != -1:
		return ""
	return id
