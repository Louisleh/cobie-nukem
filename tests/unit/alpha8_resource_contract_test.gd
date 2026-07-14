extends SceneTree

const MovingSetPieceDefinitionClass := preload("res://scripts/gameplay/moving_set_piece_definition.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_mission_audio_profile()
	_test_zone_presentation_profile()
	_test_moving_set_piece_definition()
	if failures.is_empty():
		print("ALPHA8 RESOURCE CONTRACT TESTS: PASS")
		quit(0)
	else:
		for item in failures:
			push_error(item)
		quit(1)


func _test_mission_audio_profile() -> void:
	var profile := MissionAudioProfile.new()
	profile.id = &"alpha8_mission_alpha"
	profile.exploration_ambience_cue_id = &"alpha8_explore"
	profile.tension_ambience_cue_id = &"alpha8_tension"
	profile.combat_ambience_cue_id = &"alpha8_combat"
	profile.boss_ambience_cue_id = &"alpha8_boss"
	profile.victory_ambience_cue_id = &"alpha8_victory"
	profile.ambience_cue_ids = [&"alpha8_ambient_a", &"alpha8_ambient_b"]
	_expect(profile.validate().is_empty(), "mission audio profile validates")

	profile.id = &""
	var errors := profile.validate()
	_expect("mission_audio_profile has empty id" in errors, "mission audio rejects empty id")

	var non_finite := MissionAudioProfile.new()
	non_finite.id = &"alpha8_mission_alpha"
	non_finite.exploration_ambience_cue_id = &"alpha8_explore"
	non_finite.tension_ambience_cue_id = &"alpha8_tension"
	non_finite.combat_ambience_cue_id = &"alpha8_combat"
	non_finite.boss_ambience_cue_id = &"alpha8_boss"
	non_finite.victory_ambience_cue_id = &"alpha8_victory"
	non_finite.crossfade_seconds = INF
	non_finite.ambience_cue_ids = [
		&"alpha8_ambient_a",
		&"",
	]
	errors = non_finite.validate()
	_expect("mission_audio_profile alpha8_mission_alpha has invalid crossfade_seconds" in errors, "mission audio rejects non-finite crossfade")
	_expect("mission_audio_profile alpha8_mission_alpha has empty ambience_cue_ids[1]" in errors, "mission audio rejects empty ambience cue")


func _test_zone_presentation_profile() -> void:
	var profile := ZonePresentationProfile.new()
	profile.id = &"alpha8_zone_alpha"
	profile.zone_id = &"zone_alpha"
	profile.palette_id = &"sunset_palette"
	profile.ambience_cue_id = &"alpha8_zone_ambience"
	profile.landmark_ids = [&"beacon", &"sentry_dock"]
	_expect(profile.validate().is_empty(), "zone presentation profile validates")

	var bad := ZonePresentationProfile.new()
	bad.id = &"alpha8_zone_alpha"
	bad.zone_id = &"zone_alpha"
	bad.palette_id = &"sunset_palette"
	bad.ambience_cue_id = &"alpha8_zone_ambience"
	bad.fog_density = -0.1
	var errors := bad.validate()
	_expect("zone_presentation_profile alpha8_zone_alpha has invalid fog_density" in errors, "zone presentation rejects negative fog density")

	bad.weather = &"warp"
	errors = bad.validate()
	_expect("zone_presentation_profile alpha8_zone_alpha has unsupported weather warp" in errors, "zone presentation rejects unsupported weather")


func _test_moving_set_piece_definition() -> void:
	var valid_path_points: Array[Vector3] = [Vector3.ZERO, Vector3(4.0, 0.0, 0.0)]
	var valid_stop_markers: Array[float] = [0.4, 0.8]
	var valid_triggers: Array[StringName] = [&"encounter_1", &"encounter_2"]
	var valid_modules: Array[StringName] = [&"module_1"]
	var definition := MovingSetPieceDefinitionClass.new()
	definition.id = &"alpha8_set_piece"
	definition.actor_scene_path = "res://scenes/enemies/squirrel_trooper.tscn"
	definition.path_points = valid_path_points
	definition.speed = 3.5
	definition.stop_markers = valid_stop_markers
	definition.encounter_trigger_ids = valid_triggers
	definition.destructible_module_ids = valid_modules
	definition.completion_event = &"set_piece_complete"
	var errors: PackedStringArray = definition.validate()
	_expect(errors.is_empty(), "moving set piece definition validates")

	definition.actor_scene_path = ""
	definition.path_points = [Vector3.ZERO]
	errors = definition.validate()
	_expect("moving_set_piece_definition alpha8_set_piece has empty actor_scene_path" in errors, "moving set piece rejects missing actor scene")
	_expect("moving_set_piece_definition alpha8_set_piece must have at least two path points" in errors, "moving set piece rejects too-few path points")

	var ordered_path_points: Array[Vector3] = [Vector3.ZERO, Vector3(1, 0, 0), Vector3(2, 0, 0)]
	var ordered_markers: Array[float] = [0.6, 0.2]
	var ordered := MovingSetPieceDefinitionClass.new()
	ordered.id = &"alpha8_set_piece"
	ordered.actor_scene_path = "res://scenes/enemies/squirrel_trooper.tscn"
	ordered.path_points = ordered_path_points
	ordered.speed = 3.0
	ordered.stop_markers = ordered_markers
	ordered.completion_event = &"set_piece_complete"
	errors = ordered.validate()
	_expect("moving_set_piece_definition alpha8_set_piece stop_markers must be ordered" in errors, "moving set piece rejects out-of-order stop markers")

	var non_finite_path: Array[Vector3] = [Vector3.ZERO, Vector3(NAN, 0.0, 0.0)]
	var non_finite := MovingSetPieceDefinitionClass.new()
	non_finite.id = &"alpha8_set_piece"
	non_finite.actor_scene_path = "res://scenes/enemies/squirrel_trooper.tscn"
	non_finite.path_points = non_finite_path
	non_finite.speed = 0.0
	non_finite.completion_event = &"set_piece_complete"
	errors = non_finite.validate()
	_expect("moving_set_piece_definition alpha8_set_piece speed must be positive and finite" in errors, "moving set piece rejects non-positive speed")
	_expect("moving_set_piece_definition alpha8_set_piece path_points[1] is not finite" in errors, "moving set piece rejects non-finite path points")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
