extends SceneTree

const Profile := preload("res://scripts/ai/enemy_presentation_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_test_validation()
	_test_lookup_and_bounds()
	_test_reaction_uniqueness()
	if failures.is_empty():
		print("PASS: enemy presentation profile contract and frame validation")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_validation() -> void:
	var profile := Profile.new()
	_expect(not profile.validate().is_empty(), "Validation fails on missing id and atlas")

	profile.id = &"alpha8_validation"
	profile.atlas_texture = _fixture_texture(257, 128)
	_expect(not profile.validate().is_empty(), "Validation fails when width is not divisible by eight columns")

	profile.atlas_texture = _fixture_texture(2048, 686)
	_expect(not profile.validate().is_empty(), "Validation fails when height is not divisible by four rows")

	profile.atlas_texture = _fixture_texture(2048, 684)
	profile.alert_frame_column = 0
	profile.telegraph_frame_column = 1
	profile.attack_frame_column = 2
	profile.hurt_frame_column = 3
	profile.stagger_frame_column = 4
	profile.milestone_frame_column = 5
	profile.death_frame_column = 6
	profile.id = &"alpha8_profile"
	_expect(profile.validate().is_empty(), "Valid atlas and unique reaction columns pass validation")


func _test_lookup_and_bounds() -> void:
	var profile := Profile.new()
	profile.id = &"alpha8_profile_lookup"
	profile.atlas_texture = _fixture_texture(2048, 684)
	profile.alert_frame_column = 0
	profile.telegraph_frame_column = 1
	profile.attack_frame_column = 2
	profile.hurt_frame_column = 3
	profile.stagger_frame_column = 4
	profile.milestone_frame_column = 5
	profile.death_frame_column = 6

	_expect(profile.frame_budget() == 32, "Profile reports 32 total atlas fragments")
	_expect(profile.direction_count() == 8, "Profile reports eight direction octants")
	_expect(profile.direction_row_idle() == 0, "Profile idle row is top row")
	_expect(profile.direction_row_a() == 1, "Profile locomotion-A row is row one")
	_expect(profile.direction_row_b() == 2, "Profile locomotion-B row is row two")
	_expect(profile.frame_for_row_and_column(-1, 0) == -1, "Frame lookup rejects negative rows")
	_expect(profile.frame_for_row_and_column(0, 12) == -1, "Frame lookup rejects out-of-range columns")
	_expect(profile.frame_for_row_and_column(3, 0) == 24, "Frame lookup resolves reaction row index")


func _test_reaction_uniqueness() -> void:
	var profile := Profile.new()
	profile.id = &"alpha8_profile_reactions"
	profile.atlas_texture = _fixture_texture(2048, 684)
	profile.alert_frame_column = 0
	profile.telegraph_frame_column = 1
	profile.attack_frame_column = 2
	profile.hurt_frame_column = 3
	profile.stagger_frame_column = 4
	profile.milestone_frame_column = 5
	profile.death_frame_column = 6

	_expect(profile.reaction_alert_frame() == 24, "Alert reaction is row 3, column 0")
	_expect(profile.reaction_telegraph_frame() == 25, "Telegraph reaction is row 3, column 1")
	_expect(profile.reaction_attack_frame() == 26, "Attack reaction is row 3, column 2")
	_expect(profile.reaction_hurt_frame() == 27, "Hurt reaction is row 3, column 3")
	_expect(profile.reaction_stagger_frame() == 28, "Stagger reaction is row 3, column 4")
	_expect(profile.reaction_milestone_frame() == 29, "Milestone reaction is row 3, column 5")
	_expect(profile.reaction_death_frame() == 30, "Death reaction is row 3, column 6")

	var distinct := {}
	distinct[profile.reaction_alert_frame()] = true
	distinct[profile.reaction_telegraph_frame()] = true
	distinct[profile.reaction_attack_frame()] = true
	distinct[profile.reaction_hurt_frame()] = true
	distinct[profile.reaction_stagger_frame()] = true
	distinct[profile.reaction_milestone_frame()] = true
	distinct[profile.reaction_death_frame()] = true
	_expect(distinct.size() == 7, "Reaction mapping assigns seven distinct atlas columns")

	# Duplicate reaction columns should fail validation.
	profile.telegraph_frame_column = 0
	_expect(not profile.validate().is_empty(), "Duplicate reaction columns fail validation")


func _fixture_texture(width: int, height: int) -> Texture2D:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.2, 0.2, 1.0))
	return ImageTexture.create_from_image(image)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
