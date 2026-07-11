extends SceneTree

const QATargetScript := preload("res://tests/fixtures/qa_target.gd")
const PROFILE_PATHS := [
	"res://resources/input_profiles/keyboard_mouse.tres",
	"res://resources/input_profiles/classic_1996.tres",
	"res://resources/input_profiles/hybrid.tres",
	"res://resources/input_profiles/generic_gamepad.tres",
]

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_damage_and_armor()
	_test_ammo_and_cooldown()
	_test_save_round_trip()
	_test_profile_round_trip_and_math()
	await _test_auto_aim_filtering()
	await _test_enemy_transition()
	await _test_shot_feedback()
	await _test_paused_options_return()
	await _test_playtest_report()
	await _test_secret_counting_and_exit()
	_test_level_metadata()
	if failures.is_empty():
		print("PASS: integrated combat, persistence, input, aim, enemy, secret, and exit contracts")
		quit(0)
	else:
		for failure in failures:
			push_error("INTEGRATION: " + failure)
		quit(1)

func _test_damage_and_armor() -> void:
	var health := HealthArmor.new()
	health.max_health = 100.0
	health.health = 100.0
	health.max_armor = 100.0
	health.armor = 20.0
	health.armor_absorption = 0.65
	root.add_child(health)
	var health_damage := health.apply_damage(40.0)
	_expect_close(health.armor, 0.0, "armor is depleted before excess reaches health")
	_expect_close(health.health, 80.0, "damage overflow reaches health")
	_expect_close(health_damage, 20.0, "damage return reports health damage")
	health.apply_damage(1000.0)
	_expect(health.is_dead, "lethal damage sets dead state")
	_expect_close(health.heal(20.0), 0.0, "dead actor cannot heal")
	health.free()

func _test_ammo_and_cooldown() -> void:
	var definition := WeaponDefinition.new()
	definition.ammo_type = "qa_ammo"
	definition.magazine_size = 5
	definition.starting_ammo = 2
	definition.reserve_capacity = 5
	definition.primary_cooldown = 0.25
	var weapon := WeaponBase.new()
	weapon.definition = definition
	weapon.enabled = true
	weapon.camera = Camera3D.new()
	weapon.add_child(weapon.camera)
	root.add_child(weapon)
	weapon.ammo = 2
	_expect(weapon._begin_fire(false), "weapon fires with ammunition")
	_expect(weapon.ammo == 1, "primary fire consumes configured ammunition")
	_expect(not weapon._begin_fire(false), "cooldown blocks immediate second shot")
	weapon._process(0.3)
	_expect(weapon._begin_fire(false), "weapon fires after cooldown elapses")
	_expect(weapon.ammo == 0, "last ammunition is consumed")
	weapon._process(0.3)
	_expect(not weapon._begin_fire(false), "empty weapon cannot fire")
	_expect(weapon.add_ammo(99) == 5, "ammo refill clamps and reports actual gain")
	_expect(weapon.ammo == 0 and weapon.reserve_ammo == 5, "ammo refill fills reserve without bypassing reload")
	weapon.free()

func _test_save_round_trip() -> void:
	var slot := &"qa_integration"
	var save_manager := root.get_node_or_null("SaveManager")
	_expect(save_manager != null, "SaveManager autoload is available")
	if save_manager == null:
		return
	save_manager.delete_slot(slot)
	var payload := {
		"checkpoint": "maintenance_tunnels",
		"position": [1.0, 2.0, 3.0],
		"secrets": ["sign", "wall"],
		"best_time_msec": 742000,
	}
	_expect(save_manager.save_slot(slot, payload) == OK, "save slot writes successfully")
	var restored: Dictionary = save_manager.load_slot(slot)
	_expect(restored.get("checkpoint") == payload.checkpoint, "checkpoint survives save/load")
	_expect(restored.get("secrets", []).size() == 2, "secret IDs survive save/load")
	_expect(int(restored.get("best_time_msec", 0)) == payload.best_time_msec, "best time survives save/load")
	_expect(save_manager.delete_slot(slot) == OK, "QA save slot cleanup succeeds")

func _test_profile_round_trip_and_math() -> void:
	for path in PROFILE_PATHS:
		var profile := load(path) as InputProfile
		_expect(profile != null, "input profile loads: %s" % path)
		if profile == null:
			continue
		profile = profile.duplicate(true)
		profile.ensure_defaults()
		var restored := InputProfile.from_dict(JSON.parse_string(JSON.stringify(profile.to_dict())))
		_expect(restored.profile_id == profile.profile_id, "profile ID round trip: %s" % path)
		_expect(restored.preset == profile.preset, "profile preset round trip: %s" % path)
	_expect_close(InputMath.apply_dead_zone(0.1, 0.2), 0.0, "dead zone removes resting drift")
	_expect_close(InputMath.apply_dead_zone(0.6, 0.2), 0.5, "dead zone rescales remaining range")
	_expect_close(InputMath.apply_response_curve(-0.5, 2.0), -0.25, "curve preserves sign")
	var inverted := InputMath.process_axis(0.6, InputProfile.make_axis_config(0.1, 1.0, 1.0, true))
	_expect(inverted < 0.0, "axis inversion is applied")

func _test_auto_aim_filtering() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	var aim := AutoAimComponent.new()
	var tuning := AutoAimTuning.new()
	tuning.mode = AutoAimTuning.Mode.CLASSIC
	tuning.horizontal_cone_degrees = 35.0
	tuning.vertical_cone_degrees = 30.0
	aim.tuning = tuning
	aim.collision_mask = 0
	world.add_child(aim)
	var visible := QATargetScript.new()
	visible.position = Vector3(1.0, 0.0, -8.0)
	visible.add_to_group(&"auto_aim_targets")
	world.add_child(visible)
	var dead_closer := QATargetScript.new()
	dead_closer.position = Vector3(0.0, 0.0, -3.0)
	dead_closer.is_dead = true
	dead_closer.add_to_group(&"auto_aim_targets")
	world.add_child(dead_closer)
	var behind := QATargetScript.new()
	behind.position = Vector3(0.0, 0.0, 2.0)
	behind.add_to_group(&"auto_aim_targets")
	world.add_child(behind)
	await process_frame
	var direction := aim.get_aim_direction(camera, 30.0)
	_expect(aim.current_target == visible, "auto-aim filters dead and behind-camera targets")
	_expect(direction.x > 0.0 and direction.z < 0.0, "auto-aim bends toward valid visible target")
	world.free()

func _test_enemy_transition() -> void:
	var enemy := preload("res://scenes/enemies/leash_enforcement_drone.tscn").instantiate() as EnemyAgent
	var target := QATargetScript.new()
	target.position = Vector3(0.0, 0.0, -8.0)
	root.add_child(target)
	root.add_child(enemy)
	await process_frame
	enemy.set_target(target)
	_expect(enemy.state == EnemyAgent.State.ALERT, "enemy enters alert when assigned a target")
	enemy._physics_process(0.6)
	_expect(enemy.state == EnemyAgent.State.CHASE, "enemy advances from alert to chase")
	enemy.apply_damage(9999.0)
	_expect(enemy.state == EnemyAgent.State.DEAD and enemy.is_dead, "enemy enters terminal dead state")
	_expect(not enemy.is_in_group(&"auto_aim_targets"), "dead enemy leaves auto-aim group")
	enemy.free()
	target.free()

func _test_shot_feedback() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	var surface := StaticBody3D.new()
	surface.position = Vector3(0.0, 0.0, -3.0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.0, 0.2)
	collision.shape = shape
	surface.add_child(collision)
	world.add_child(surface)
	var definition := WeaponDefinition.new()
	definition.range = 10.0
	var weapon := WeaponBase.new()
	weapon.definition = definition
	weapon.camera = camera
	weapon.enabled = true
	world.add_child(weapon)
	var result_kind := [&""]
	weapon.shot_resolved.connect(func(kind: StringName, _position: Vector3) -> void: result_kind[0] = kind)
	await physics_frame
	var hit := weapon._hitscan(1.0, 10.0, 0.0, 0.0)
	_expect(not hit.is_empty(), "hitscan reports a world impact")
	_expect(result_kind[0] == &"world", "world impact is distinguished from enemy hits and misses")
	var marker := root.find_child("SurfaceImpact", true, false)
	_expect(marker != null, "world impact creates a visible marker")
	if marker != null:
		marker.free()
	world.free()

func _test_paused_options_return() -> void:
	var pause_menu := preload("res://scenes/ui/pause_menu.tscn").instantiate() as PauseMenu
	root.add_child(pause_menu)
	await process_frame
	pause_menu.open()
	pause_menu._open_options()
	_expect(paused, "opening in-game options keeps the run paused")
	_expect(is_instance_valid(pause_menu._options_overlay) and pause_menu._options_overlay.embedded, "pause options open as an embedded overlay")
	pause_menu._close_options()
	_expect(paused and pause_menu.visible, "back from options returns to the pause menu")
	pause_menu.close_for_death()
	_expect(not paused and not pause_menu.visible, "death forcibly closes pause/options without stacking modals")
	pause_menu.open()
	pause_menu.resume()
	_expect(not paused, "resume remains available after closing options")
	pause_menu.free()

func _test_playtest_report() -> void:
	var report := preload("res://scenes/ui/playtest_report.tscn").instantiate() as PlaytestReport
	root.add_child(report)
	await process_frame
	var summary := {
		"completed": true, "duration_msec": 125000, "deaths": 2,
		"enemies_defeated": 12, "enemies_total": 12,
		"secrets_found": 3, "secrets_total": 3,
		"last_zone": "walker_arena", "checkpoint_id": "lab_entry",
	}
	report.open(summary)
	var text := (report.get_node("Panel/VBox/ReportText") as TextEdit).text
	_expect(report.visible and BuildInfo.VERSION in text, "playtest report exposes traceable build version")
	_expect("What was the most fun moment?" in text and "text it to Louis" in text, "playtest report contains the three-question handoff")
	_expect("Enemies: 12 / 12" in text and "Completion: COMPLETE" in text, "playtest report summarizes completion evidence")
	report.close()
	report.free()

func _test_secret_counting_and_exit() -> void:
	var found: Dictionary = {}
	var sign := preload("res://scenes/interactables/narrative_sign.tscn").instantiate() as NarrativeSign
	sign.secret_after_reads = 3
	sign.secret_id = &"sign"
	sign.secret_requested.connect(func(id: StringName, _title: String) -> void: found[id] = true)
	root.add_child(sign)
	await process_frame
	sign.interact(null)
	sign.interact(null)
	_expect(found.size() == 0, "sign secret does not trigger early")
	sign.interact(null)
	_expect(found.has(&"sign"), "sign secret triggers on third read")
	sign.interact(null)
	_expect(found.size() == 1, "sign secret counts only once")
	var wall := preload("res://scenes/interactables/breakable_secret_wall.tscn").instantiate() as BreakableSecretWall
	wall.broken.connect(func(id: StringName, _title: String) -> void: found[id] = true)
	root.add_child(wall)
	await process_frame
	wall.apply_damage(999.0)
	wall.apply_damage(999.0)
	_expect(found.size() == 2, "breakable secret counts once")
	var walker := QATargetScript.new()
	root.add_child(walker)
	var finale := preload("res://scenes/interactables/golden_ball_finale.tscn").instantiate() as GoldenBallFinale
	root.add_child(finale)
	await process_frame
	finale.enable_for_boss(walker)
	finale.interact(null)
	finale.interact(null)
	_expect(walker.golden_ball_strikes == 1, "Golden Ball exit condition can trigger only once")
	sign.free()
	wall.free()
	finale.free()
	walker.free()

func _test_level_metadata() -> void:
	var metadata := load("res://resources/level/episode_1_level_1.tres") as LevelMetadata
	_expect(metadata != null, "level metadata loads")
	if metadata != null:
		_expect(metadata.total_secrets >= 3, "level declares at least three secrets")
		_expect(metadata.target_minutes_min == 12 and metadata.target_minutes_max == 20, "level target is 12–20 minutes")

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _expect_close(actual: float, expected: float, label: String, tolerance := 0.001) -> void:
	_expect(absf(actual - expected) <= tolerance, "%s (expected %.3f, got %.3f)" % [label, expected, actual])
