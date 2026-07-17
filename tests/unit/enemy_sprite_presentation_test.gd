extends SceneTree

const Presentation := preload("res://scripts/ai/enemy_sprite_presentation.gd")
const Profile := preload("res://scripts/ai/enemy_presentation_profile.gd")

const STATE_IDLE := 0
const STATE_ALERT := 1
const STATE_CHASE := 2
const STATE_ATTACK := 3
const STATE_HURT := 4
const STATE_STUNNED := 5
const STATE_DEAD := 6
const REGULAR_SCENES := [
	"res://scenes/enemies/leash_enforcement_drone.tscn",
	"res://scenes/enemies/mutant_groundskeeper.tscn",
	"res://scenes/enemies/squirrel_trooper.tscn",
]
const ELITE_BOSS_SCENES := [
	"res://scenes/enemies/compliance_hound.tscn",
	"res://scenes/enemies/animal_control_walker.tscn",
	"res://scenes/enemies/umbrella_shield_enforcer.tscn",
]


class FakeEnemyAgent extends EnemyAgent:
	signal shield_broken()
	signal boss_phase_changed(previous, current)

	func _ready() -> void:
		pass

	func _physics_process(_delta: float) -> void:
		pass


class FakeWorldRegistry extends Node:
	var player := Node3D.new()

	func _init() -> void:
		player.name = "WorldRegistryPlayer"
		add_child(player)

	func primary_player() -> Node3D:
		return player


class FakeQualityProfile extends Resource:
	var distant_animation_hz: float = 12.0


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_test_direction_quantization()
	_test_state_frame_vocabulary()
	await _test_legacy_atlas_vocabulary()
	await _test_profile_atlas_contract()
	await _test_profile_overrides_and_fps()
	for scene_path in REGULAR_SCENES:
		await _test_production_scene(scene_path, true)
	for scene_path in ELITE_BOSS_SCENES:
		await _test_production_scene(scene_path, true, true)
	if failures.is_empty():
		print("PASS: authored enemy atlases, deterministic direction/state selection, elite/boss vocabulary")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_direction_quantization() -> void:
	var presentation := _presentation_node()
	var forward := Vector3.FORWARD
	_expect(presentation.call("direction_index_from_vectors", forward, Vector3.FORWARD) == 0, "Front direction maps to octant 0")
	_expect(presentation.call("direction_index_from_vectors", forward, Vector3.LEFT) == 2, "Left direction maps to octant 2")
	_expect(presentation.call("direction_index_from_vectors", forward, Vector3.BACK) == 4, "Back direction maps to octant 4")
	_expect(presentation.call("direction_index_from_vectors", forward, Vector3.RIGHT) == 6, "Right direction maps to octant 6")
	_expect(presentation.call("direction_index_from_vectors", Vector3.ZERO, Vector3.RIGHT) == 0, "Degenerate direction has stable fallback")
	presentation.free()


func _test_state_frame_vocabulary() -> void:
	var presentation := _presentation_node()
	_expect(presentation.call("atlas_frame_for", STATE_IDLE, 0) == 0, "Idle uses authored front frame")
	_expect(presentation.call("atlas_frame_for", STATE_CHASE, 2) == 2, "Chase uses authored side frame")
	_expect(presentation.call("atlas_frame_for", STATE_ALERT, 7) == 4, "Alert uses explicit pose")
	_expect(presentation.call("atlas_frame_for", STATE_ATTACK, 3) == 5, "Attack uses explicit pose")
	_expect(presentation.call("atlas_frame_for", STATE_HURT, 0) == 6, "Hurt uses explicit pose")
	_expect(presentation.call("atlas_frame_for", STATE_STUNNED, 0) == 6, "Stagger uses explicit pose")
	_expect(presentation.call("atlas_frame_for", STATE_DEAD, 0) == 7, "Death uses explicit pose")
	presentation.free()


func _test_legacy_atlas_vocabulary() -> void:
	var setup := await _build_legacy_fixture()
	var actor := setup["actor"] as Node3D
	var presentation := setup["presentation"] as Node
	var sprite := setup["sprite"] as Sprite3D
	_expect(int(presentation.call("debug_current_frame")) == int(presentation.call("atlas_frame_for", STATE_IDLE, 0)), "Legacy actor initializes at idle")

	actor.call("_set_state", STATE_ALERT)
	_expect(presentation.call("debug_current_frame") == 4, "Legacy alert pose maps to frame 4")

	actor.call("_set_state", STATE_ATTACK)
	_expect(presentation.call("debug_current_frame") == 5, "Legacy attack pose maps to frame 5")

	actor.call("_set_state", STATE_STUNNED)
	_expect(presentation.call("debug_current_frame") == 6, "Legacy stagger pose maps to frame 6")

	actor.call("_set_state", STATE_DEAD)
	_expect(presentation.call("debug_current_frame") == 7, "Legacy death pose maps to frame 7")
	_expect(sprite.hframes == 4 and sprite.vframes == 2, "Legacy atlas remains constrained to 4x2")

	actor.free()


func _test_profile_atlas_contract() -> void:
	var profile := _build_profile()
	var setup := await _build_profile_fixture(profile)
	var presentation := setup["presentation"] as Node
	var actor := setup["actor"] as Node

	actor.call("_set_state", STATE_CHASE)
	var direction_count := int(profile.call("direction_count"))
	var seen := {}
	for direction in range(direction_count):
		presentation.set("_direction_index", direction)
		presentation.set("_pose_step", 0)
		presentation.call("_apply_pose")
		var frame := int(presentation.call("debug_current_frame"))
		seen[frame] = true
		var row_a: int = int(profile.call("direction_row_a"))
		_expect(frame == int(profile.call("direction_frame", direction, row_a)), "Profile chase A maps directional frame to row 1 for octant %d" % direction)

	_expect(seen.size() == direction_count, "Profile chase A retains eight unique octant columns")

	presentation.set("_pose_step", 1)
	presentation.set("_direction_index", 0)
	presentation.call("_apply_pose")
	_expect(presentation.call("debug_current_frame") == profile.direction_frame(0, profile.direction_row_b()), "Profile chase alternates to B-row locomotion")

	actor.call("_set_state", STATE_IDLE)
	presentation.set("_direction_index", 0)
	presentation.set("_pose_step", 0)
	presentation.call("_apply_pose")
	_expect(presentation.call("debug_current_frame") == profile.direction_frame(0, profile.direction_row_idle()), "Profile idle reads row 0 for front octant")
	actor.free()


func _test_profile_overrides_and_fps() -> void:
	var profile := _build_profile()
	profile.telegraph_hold_seconds = 0.4
	profile.attack_hold_seconds = 0.4
	var setup := await _build_profile_fixture(profile)
	var actor := setup["actor"] as Node3D
	var presentation := setup["presentation"] as Node
	var registry_proxy := Node3D.new()
	actor.set(&"target", registry_proxy)

	actor.call("_set_state", STATE_CHASE)
	actor.global_position = Vector3(2.0, 0.0, 0.0)
	_expect(actor.get("target") != null, "Profile override test has target fallback for distant detection")
	await process_frame
	presentation.call("_on_quality_profile_changed", _build_quality_profile(12.0))
	presentation.call("_physics_process", 0.2)
	_expect(is_equal_approx(float(presentation.call("debug_effective_fps")), 12.0), "Near actor uses profile animation rate")

	actor.global_position = Vector3(120.0, 0.0, 0.0)
	presentation.call("_on_quality_profile_changed", _build_quality_profile(6.0))
	var profile_distance_hz := float(presentation.call("_read_profile_distant_hz", _build_quality_profile(6.0)))
	_expect(is_equal_approx(profile_distance_hz, 6.0), "Distance quality profile resolves distant hz")
	_expect(presentation.call("_is_distant"), "Actor enters distant mode when moved away from target")
	presentation.call("_physics_process", 0.2)
	_expect(is_equal_approx(float(presentation.call("debug_effective_fps")), 4.0), "Far actor clamps animation rate to profile and quality limits")

	actor.emit_signal(&"telegraph_started", &"attack", 0.03)
	presentation.call("_physics_process", 0.2)
	_expect(presentation.call("debug_current_pose") == &"telegraph", "Telegraph signal forces telegraph reaction pose")
	_expect(int(presentation.call("debug_current_frame")) == int(profile.reaction_telegraph_frame()), "Telegraph pose reads from reaction profile frame")

	actor.emit_signal(&"attack_fired", &"attack")
	presentation.call("_physics_process", 0.2)
	_expect(presentation.call("debug_current_pose") == &"attack", "Attack signal overrides telegraph pose")
	_expect(int(presentation.call("debug_current_frame")) == int(profile.reaction_attack_frame()), "Attack pose reads from reaction profile frame")

	presentation.call("_physics_process", 1.0)
	_expect(presentation.call("debug_current_pose") == &"chase", "Override expiry returns to broad movement pose")

	registry_proxy.free()
	actor.free()


func _build_profile() -> Profile:
	var profile := Profile.new()
	profile.id = &"alpha8_profile"
	profile.atlas_texture = _fixture_texture(2048, 684)
	profile.alert_frame_column = 0
	profile.telegraph_frame_column = 1
	profile.attack_frame_column = 2
	profile.hurt_frame_column = 3
	profile.stagger_frame_column = 4
	profile.milestone_frame_column = 5
	profile.death_frame_column = 6
	profile.animation_fps = 12.0
	_expect(profile.validate().is_empty(), "Profile validates with clean 8x4 artifact contract")
	return profile


func _test_production_scene(scene_path: String, expects_atlas: bool, expects_profile := false) -> void:
	var packed := load(scene_path) as PackedScene
	_expect(packed != null, "Enemy scene loads: %s" % scene_path)
	if packed == null:
		return
	var enemy := packed.instantiate() as EnemyAgent
	root.add_child(enemy)
	await process_frame
	var presentation := enemy.get_node_or_null("EnemySpritePresentation") as EnemySpritePresentation
	var sprite := enemy.get_node_or_null("Visual/DetailedSprite") as Sprite3D
	_expect(presentation != null and sprite != null, "Production enemy presentation is complete: %s" % scene_path)
	if presentation != null and sprite != null:
		if expects_profile:
			_expect(presentation.presentation_profile != null, "Elite/boss owns production presentation profile: %s" % scene_path)
			_expect(sprite.hframes == 8 and sprite.vframes == 4, "Elite/boss production atlas is 8x4: %s" % scene_path)
			if presentation.presentation_profile != null:
				_expect(presentation.presentation_profile.validate().is_empty(), "Elite/boss profile validates: %s" % scene_path)
		elif expects_atlas:
			_expect(presentation.atlas_texture != null and sprite.hframes == 4 and sprite.vframes == 2, "Legacy production atlas remains 4x2: %s" % scene_path)
		enemy._set_state(EnemyAgent.State.ATTACK)
		_expect(presentation.debug_current_pose() == &"attack", "Production enemy exposes attack pose: %s" % scene_path)
	enemy.free()


func _build_legacy_fixture() -> Dictionary:
	var actor := FakeEnemyAgent.new()
	actor.name = "LegacyEnemyActor"
	actor.definition = EnemyDefinition.new()

	var visual := Node3D.new()
	visual.name = "Visual"
	var sprite := Sprite3D.new()
	sprite.name = "DetailedSprite"
	sprite.texture = _fixture_texture(128, 64)
	visual.add_child(sprite)
	actor.add_child(visual)

	var presentation := _presentation_node()
	presentation.name = "EnemySpritePresentation"
	presentation.set(&"atlas_texture", _fixture_texture(128, 64))
	presentation.set(&"animation_fps", 8.0)
	actor.add_child(presentation)

	root.add_child(actor)
	await process_frame
	return {"actor": actor, "presentation": presentation, "sprite": sprite}


func _build_profile_fixture(profile: Profile) -> Dictionary:
	var actor := FakeEnemyAgent.new()
	actor.name = "ProfileEnemyActor"
	actor.state = STATE_IDLE
	actor.definition = EnemyDefinition.new()
	actor.uses_gravity = false

	var visual := Node3D.new()
	visual.name = "Visual"
	var sprite := Sprite3D.new()
	sprite.name = "DetailedSprite"
	visual.add_child(sprite)
	actor.add_child(visual)

	var presentation := _presentation_node()
	presentation.name = "EnemySpritePresentation"
	presentation.set(&"presentation_profile", profile)
	presentation.set(&"atlas_texture", _fixture_texture(256, 128))
	actor.add_child(presentation)

	root.add_child(actor)
	await process_frame
	return {"actor": actor, "presentation": presentation, "sprite": sprite}


func _presentation_node() -> Node:
	var presentation := Node.new()
	presentation.set_script(Presentation)
	return presentation


func _fixture_texture(width: int, height: int) -> Texture2D:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.9, 0.9, 1.0))
	return ImageTexture.create_from_image(image)


func _build_quality_profile(hz: float) -> FakeQualityProfile:
	var profile := FakeQualityProfile.new()
	profile.distant_animation_hz = hz
	return profile


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
