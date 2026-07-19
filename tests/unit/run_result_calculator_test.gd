extends SceneTree

const Profile := preload("res://scripts/gameplay/mission_progression_profile.gd")
const Calculator := preload("res://scripts/gameplay/run_result_calculator.gd")

const PAR_TIME_FIXTURES_MINUTES := [15, 18, 22, 24, 24]

var failures: Array[String] = []


func _initialize() -> void:
	_test_profile_validation()
	_test_par_time_exact_boundaries()
	_test_rank_all_levels()
	_test_each_medal()
	_test_zero_shots_accuracy_safe()
	_test_malformed_input()
	if failures.is_empty():
		print("RUN RESULT CALCULATOR TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_profile_validation() -> void:
	var valid := _profile("episode_1_level_1", 18, 12, 4, 3, "active")
	_expect(valid.validate().is_empty(), "valid mission progression profile validates")
	var malformed_ids := [
		"",
		"mission with spaces",
		"mission\twith\ttabs",
	]
	for malformed in malformed_ids:
		var broken := _profile("episode_1_level_1", 18, 12, 4, 3, "active")
		broken.mission_id = &"" if malformed.is_empty() else StringName(malformed)
		_expect(not broken.validate().is_empty(), "profile validation rejects malformed mission id: %s" % malformed if not malformed.is_empty() else "empty mission id")
	var negative_time := _profile("episode_1_level_1", -1, 12, 4, 3, "active")
	_expect(not negative_time.validate().is_empty(), "profile validation rejects non-positive par_time")
	var negative_total := _profile("episode_1_level_1", 18, 12, 4, 3, "active")
	negative_total.enemies_total = -1
	_expect(not negative_total.validate().is_empty(), "profile validation rejects negative enemies_total")
	negative_total = _profile("episode_1_level_1", 18, 12, -1, 3, "active")
	_negative_total("secrets_total", negative_total)
	negative_total = _profile("episode_1_level_1", 18, 12, 4, -1, "active")
	_negative_total("collectible_total", negative_total)
	var bad_status := _profile("episode_1_level_1", 18, 12, 4, 3, "coming_soon")
	bad_status.collection_status = "invalid"
	_expect(not bad_status.validate().is_empty(), "profile validation rejects unknown collection status")


func _test_par_time_exact_boundaries() -> void:
	for i in PAR_TIME_FIXTURES_MINUTES.size():
		var minutes: int = PAR_TIME_FIXTURES_MINUTES[i]
		var profile := _profile("mission_par_boundary_%d" % i, minutes, 1, 1, 0, "active")
		var run_at_par := {
			"completion_time_msec": minutes * 60 * 1000,
			"enemies_total": 1,
			"enemies_defeated": 1,
			"secrets_total": 1,
			"secrets_found": 1,
			"shots_fired": 2,
			"shots_hit": 1,
			"deaths": 0,
		}
		var on_time := Calculator.calculate(run_at_par, profile)
		_expect(on_time.medals.get("par_time", false), "exact par-time boundary is a pass for %d-minute fixture" % minutes)
		run_at_par["completion_time_msec"] = minutes * 60 * 1000 + 1
		var over_time := Calculator.calculate(run_at_par, profile)
		_expect(not over_time.medals.get("par_time", false), "par-time boundary +1ms is a fail for %d-minute fixture" % minutes)


func _test_rank_all_levels() -> void:
	var profile := _profile("episode_1_level_1", 18, 6, 3, 0, "active")
	var all_five := Calculator.calculate(_base_run_with_flags(profile, {
		"par_time": true,
		"all_secrets": true,
		"all_enemies": true,
		"accuracy": true,
		"zero_deaths": true,
	}), profile)
	_expect(all_five.rank == "S" and all_five.rank_title == "TOP DOG", "all medals produce S")
	_expect(all_five.medal_count == 5, "all medals count as five")

	var four := Calculator.calculate(_base_run_with_flags(profile, {
		"par_time": false,
		"all_secrets": true,
		"all_enemies": true,
		"accuracy": true,
		"zero_deaths": true,
	}), profile)
	_expect(four.rank == "A" and four.rank_title == "BEST IN SHOW", "four medals produce A")
	_expect(four.medal_count == 4, "four medals count as four")

	var three := Calculator.calculate(_base_run_with_flags(profile, {
		"par_time": false,
		"all_secrets": true,
		"all_enemies": true,
		"accuracy": false,
		"zero_deaths": true,
	}), profile)
	_expect(three.rank == "B" and three.rank_title == "GOOD DOG", "three medals produce B")
	_expect(three.medal_count == 3, "three medals count as three")

	var two := Calculator.calculate(_base_run_with_flags(profile, {
		"par_time": false,
		"all_secrets": true,
		"all_enemies": false,
		"accuracy": false,
		"zero_deaths": true,
	}), profile)
	_expect(two.rank == "C" and two.rank_title == "KEEP FETCHING", "two medals produce C")
	_expect(two.medal_count == 2, "two medals count as two")

	var one := Calculator.calculate(_base_run_with_flags(profile, {
		"par_time": false,
		"all_secrets": false,
		"all_enemies": false,
		"accuracy": false,
		"zero_deaths": true,
	}), profile)
	_expect(one.rank == "D" and one.rank_title == "RUFF RUN", "one medal produces D")
	_expect(one.medal_count == 1, "one medal counts as one")

	var zero := Calculator.calculate(_base_run_with_flags(profile, {
		"par_time": false,
		"all_secrets": false,
		"all_enemies": false,
		"accuracy": false,
		"zero_deaths": false,
	}), profile)
	_expect(zero.rank == "D" and zero.rank_title == "RUFF RUN", "zero medals produce D")
	_expect(zero.medal_count == 0, "zero medals count as zero")


func _test_each_medal() -> void:
	var profile := _profile("episode_1_level_1", 12, 10, 4, 0, "active")
	var par := Calculator.calculate({
		"completion_time_msec": 12 * 60 * 1000,
		"enemies_total": 10,
		"enemies_defeated": 0,
		"secrets_total": 4,
		"secrets_found": 0,
		"shots_fired": 4,
		"shots_hit": 0,
		"deaths": 1,
	}, profile)
	_expect(par.medals.par_time, "par_time medal evaluates true for exact target")

	var secret_true := Calculator.calculate({
		"completion_time_msec": 999999999,
		"enemies_total": 10,
		"enemies_defeated": 0,
		"secrets_total": 4,
		"secrets_found": 4,
		"shots_fired": 4,
		"shots_hit": 0,
		"deaths": 1,
	}, profile)
	_expect(secret_true.medals.all_secrets, "all_secrets medal evaluates true when all secrets found")

	var enemies_true := Calculator.calculate({
		"completion_time_msec": 999999999,
		"enemies_total": 10,
		"enemies_defeated": 10,
		"secrets_total": 4,
		"secrets_found": 0,
		"shots_fired": 4,
		"shots_hit": 0,
		"deaths": 1,
	}, profile)
	_expect(enemies_true.medals.all_enemies, "all_enemies medal evaluates true when defeated count reaches total")

	var accuracy_true := Calculator.calculate({
		"completion_time_msec": 999999999,
		"enemies_total": 10,
		"enemies_defeated": 0,
		"secrets_total": 4,
		"secrets_found": 0,
		"shots_fired": 10,
		"shots_hit": 5,
		"deaths": 1,
	}, profile)
	_expect(accuracy_true.medals.accuracy, "accuracy medal evaluates true at 50%+")
	_expect(accuracy_true.accuracy >= 0.5, "accuracy output is normalized and numeric")

	var deaths_true := Calculator.calculate({
		"completion_time_msec": 999999999,
		"enemies_total": 10,
		"enemies_defeated": 0,
		"secrets_total": 4,
		"secrets_found": 0,
		"shots_fired": 10,
		"shots_hit": 0,
		"deaths": 0,
	}, profile)
	_expect(deaths_true.medals.zero_deaths, "zero_deaths medal evaluates true when deaths are zero")


func _test_zero_shots_accuracy_safe() -> void:
	var profile := _profile("episode_1_level_1", 18, 6, 3, 0, "active")
	var result := Calculator.calculate({
		"completion_time_msec": 1000,
		"enemies_total": 6,
		"enemies_defeated": 6,
		"secrets_total": 3,
		"secrets_found": 3,
		"shots_fired": 0,
		"shots_hit": 2,
		"deaths": 0,
	}, profile)
	_expect(result.accuracy == 0.0, "zero shots yields zero accuracy without divide-by-zero")
	_expect(not is_nan(result.accuracy), "zero shots produces non-NaN accuracy")
	_expect(result.accuracy <= 1.0 and result.accuracy >= 0.0, "zero shots produces bounded accuracy")
	_expect(not result.medals.accuracy, "accuracy medal is false when zero shots were fired")


func _test_malformed_input() -> void:
	var malformed_profile := _profile("episode_1_level_1", 18, 10, 4, 3, "active")
	malformed_profile.collection_status = "active"
	var malformed_run := {
		"mission_id": "",
		"completion_time_msec": "not-a-number",
		"enemies_total": -9,
		"enemies_defeated": "ten",
		"secrets_total": -1,
		"secrets_found": "all",
		"shots_fired": "three",
		"shots_hit": "five",
		"deaths": -12,
		"collectibles_found": -1,
	}
	var result := Calculator.calculate(malformed_run, malformed_profile)
	_expect(result.get("mission_id") == String(malformed_profile.mission_id), "malformed run fields do not prevent mission id normalization")
	_expect(result.get("completion_time_msec") == 0, "non-numeric completion time falls back to zero")
	_expect(result.get("enemies_total") == 10, "profile total is preferred when run total is malformed")
	_expect(result.get("secrets_found") == 0, "malformed discovered-secrets count falls back to zero")
	_expect(result.get("collectibles_found") == 0, "malformed collectible count falls back to zero")
	_expect(result.get("shots_fired") == 0, "malformed shot count falls back to zero")
	_expect(result.get("accuracy") == 0.0, "malformed hit stats produce zero accuracy")


func _negative_total(label: String, profile: MissionProgressionProfile) -> void:
	_expect(not profile.validate().is_empty(), "profile validation rejects negative %s" % label)


func _base_run_with_flags(profile: MissionProgressionProfile, medals: Dictionary) -> Dictionary:
	var par_time := int(profile.par_time_msec)
	var run := {
		"completion_time_msec": par_time if medals.get("par_time", false) else par_time + 1,
		"enemies_total": int(profile.enemies_total),
		"enemies_defeated": int(profile.enemies_total) if medals.get("all_enemies", false) else int(profile.enemies_total) - 1,
		"secrets_total": int(profile.secrets_total),
		"secrets_found": int(profile.secrets_total) if medals.get("all_secrets", false) else int(profile.secrets_total) - 1,
		"shots_fired": 2,
		"shots_hit": 1 if medals.get("accuracy", false) else 0,
		"deaths": 0 if medals.get("zero_deaths", false) else 1,
	}
	return run


func _profile(mission_id: String, par_minutes: int, enemies_total: int, secrets_total: int, collectible_total: int, collection_status: String) -> MissionProgressionProfile:
	var profile := Profile.new()
	profile.mission_id = mission_id
	profile.par_time_msec = par_minutes * 60 * 1000
	profile.enemies_total = enemies_total
	profile.secrets_total = secrets_total
	profile.collectible_total = collectible_total
	profile.collection_status = collection_status
	return profile


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
