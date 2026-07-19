extends SceneTree

const EPISODE: EpisodeDefinition = preload("res://resources/campaign/episode_one.tres")
const SALMON_BALLS: MiniBallMissionDefinition = preload("res://resources/progression/salmon_creek_mini_balls.tres")
const RAIN_BALLS: MiniBallMissionDefinition = preload("res://resources/progression/rain_city_mini_balls.tres")

var failures: Array[String] = []


func _initialize() -> void:
	_test_catalog_contract()
	_test_collectible_contract()
	_test_challenge_evaluation()
	if failures.is_empty():
		print("PROGRESSION CONTENT TEST: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _test_catalog_contract() -> void:
	var catalog := EPISODE.progression_catalog
	_expect(catalog != null, "episode exposes progression catalog")
	if catalog == null: return
	_expect(catalog.validate().is_empty(), "progression catalog validates")
	_expect(catalog.mission_profiles.size() == 5, "all five missions have result profiles")
	_expect(catalog.challenges.size() == 10, "pilot exposes ten permanent challenges")
	_expect(catalog.weapon_mods.size() == 6, "pilot exposes six weapon sidegrades")
	_expect(catalog.cosmetics.size() == 12, "pilot exposes purchasable and collection cosmetics")
	_expect(catalog.profile_for(&"episode_1_level_1").par_time_msec == 900000, "Salmon Creek par time is canonical")
	_expect(catalog.profile_for(&"episode_1_vancouver_waterfront").collectible_total == 50, "Rain City collection total is canonical")
	_expect(catalog.mod_for(&"fetch_extra_bounce").stat_additions.get("max_bounces") == 2, "Fetch sidegrade is data driven")


func _test_collectible_contract() -> void:
	for definition in [SALMON_BALLS, RAIN_BALLS]:
		_expect(definition != null and definition.validate().is_empty(), "%s collection definition validates" % definition.mission_id)
		_expect(definition.total_count() == 50, "%s contains exactly fifty Mini Balls" % definition.mission_id)
		var zone_total := 0
		var zone_ids := {}
		for zone in definition.zones:
			zone_total += int(zone.get("count", 0))
			var zone_id := String(zone.get("id", ""))
			_expect(not zone_ids.has(zone_id), "%s zone ids are unique" % definition.mission_id)
			zone_ids[zone_id] = true
		_expect(zone_total == 50, "%s zone allocation totals fifty" % definition.mission_id)


func _test_challenge_evaluation() -> void:
	var run := {
		"mission_id": "episode_1_level_1",
		"completion_time_msec": 899999,
		"difficulty": "classic",
		"deaths": 0,
		"damage_taken": 20,
		"shots_fired": 30,
		"shots_hit": 20,
		"weapon_usage": {"pawstol": 30},
		"weapon_hits": {"pawstol": 20},
		"boss_defeated": true,
	}
	var canonical := RunResultCalculator.calculate(run, EPISODE.progression_catalog.profile_for(&"episode_1_level_1"))
	var definitions := EPISODE.progression_catalog.challenges_for(&"episode_1_level_1")
	var earned := ProgressionChallengeEvaluator.newly_completed(run.merged(canonical, true), definitions, [])
	var earned_ids: Array[String] = []
	var earned_tags := 0
	for challenge in earned:
		earned_ids.append(String(challenge.id))
		earned_tags += challenge.tag_reward
	_expect(earned_ids.has("salmon_no_leash"), "zero-death challenge evaluates")
	_expect(earned_ids.has("salmon_field_day"), "time and difficulty challenge evaluates")
	_expect(earned_ids.has("salmon_pawstol_purist"), "single-weapon challenge evaluates")
	_expect(earned_tags >= 185, "challenge definitions sum permanent rewards")
	var repeat := ProgressionChallengeEvaluator.newly_completed(run.merged(canonical, true), definitions, earned_ids)
	_expect(repeat.is_empty(), "completed challenges never pay twice")


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
