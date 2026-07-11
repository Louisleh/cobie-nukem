extends SceneTree

const ENEMY_SCENES := [
	"res://scenes/enemies/leash_enforcement_drone.tscn",
	"res://scenes/enemies/mutant_groundskeeper.tscn",
	"res://scenes/enemies/squirrel_trooper.tscn",
	"res://scenes/enemies/compliance_hound.tscn",
	"res://scenes/enemies/animal_control_walker.tscn",
]
const EXPECTED_HEALTH := {
	"leash_enforcement_drone": 40.0,
	"mutant_groundskeeper": 80.0,
	"squirrel_trooper": 30.0,
	"compliance_hound": 220.0,
	"animal_control_walker": 1000.0,
}

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for scene_path in ENEMY_SCENES:
		var packed := load(scene_path) as PackedScene
		_expect(packed != null, "Scene loads: %s" % scene_path)
		if packed == null:
			continue
		var enemy := packed.instantiate() as EnemyAgent
		_expect(enemy != null, "Scene root is EnemyAgent: %s" % scene_path)
		if enemy == null:
			continue
		root.add_child(enemy)
		await process_frame
		_expect(enemy.definition != null, "Definition assigned: %s" % scene_path)
		_expect(is_equal_approx(enemy.definition.max_health, float(EXPECTED_HEALTH.get(String(enemy.definition.id), -1.0))), "Calibrated HP: %s" % scene_path)
		if enemy.definition.id == &"mutant_groundskeeper":
			_expect(enemy.definition.attack_damage <= 15.0 and enemy.definition.attack_cooldown >= 2.8, "Groundskeeper damage budget remains survivable")
		if enemy.definition.id == &"leash_enforcement_drone":
			_expect(enemy.definition.attack_damage <= 5.0 and enemy.definition.attack_cooldown >= 2.2, "Opening drone chip damage stays fair")
		_expect(enemy.is_in_group(&"enemies"), "Enemy group: %s" % scene_path)
		_expect(enemy.is_in_group(&"auto_aim_targets"), "Auto-aim group: %s" % scene_path)
		_expect(enemy.get_auto_aim_position().is_finite(), "Finite aim point: %s" % scene_path)
		var health_bar := enemy.get_node_or_null("EnemyHealthBar") as Node3D
		_expect(health_bar != null, "World-space health bar exists: %s" % scene_path)
		var health_fill := enemy.get_node_or_null("EnemyHealthBar/Fill") as MeshInstance3D
		var health_label := enemy.get_node_or_null("EnemyHealthBar/HealthPoints") as Label3D
		_expect(health_label != null and "HP" in health_label.text, "Numeric health points are visible: %s" % scene_path)
		_expect(health_label != null and health_label.fixed_size, "HP text uses constant screen sizing: %s" % scene_path)
		var full_width := (health_fill.mesh as QuadMesh).size.x if health_fill != null else 0.0
		if enemy.uses_gravity:
			enemy.global_position.y = -2.0
			enemy._stabilize_ground_height()
			_expect(enemy.global_position.y >= 0.0, "Ground enemy recovers above floor: %s" % scene_path)
		else:
			_expect(enemy is LeashEnforcementDrone, "Only flying enemies bypass gravity: %s" % scene_path)
		var before := enemy.health
		var applied := enemy.apply_damage(5.0, null, enemy.global_position)
		_expect(applied > 0.0, "Damage hook applies: %s" % scene_path)
		_expect(enemy.health < before, "Health decreases: %s" % scene_path)
		if health_label != null:
			_expect(health_label.text.begins_with(str(ceili(enemy.health))), "Numeric HP updates immediately: %s" % scene_path)
		if health_fill != null:
			_expect((health_fill.mesh as QuadMesh).size.x < full_width, "Health bar shrinks immediately: %s" % scene_path)
		enemy.free()
	_test_hound_shield()
	_test_walker_phases()
	await _test_death_animation()
	if failures.is_empty():
		print("PASS: enemy contracts, damage hooks, shield, and boss phases")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_hound_shield() -> void:
	var hound := preload("res://scenes/enemies/compliance_hound.tscn").instantiate() as ComplianceHound
	root.add_child(hound)
	await process_frame
	var front_damage := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	var back_damage := hound.apply_damage(20.0, null, hound.global_position + Vector3.BACK)
	_expect(back_damage > front_damage, "Hound rear weak point bypasses shield")
	hound.free()

func _test_walker_phases() -> void:
	var walker := preload("res://scenes/enemies/animal_control_walker.tscn").instantiate() as AnimalControlWalker
	root.add_child(walker)
	await process_frame
	_expect(walker.definition.max_health == 1000.0, "Walker health ceiling is 1000 HP")
	_expect(walker.definition.move_speed >= 4.0 and walker.definition.attack_range <= 7.0, "Walker closes distance at combat speed")
	walker.apply_damage(450.0)
	_expect(walker.boss_phase == AnimalControlWalker.BossPhase.EXPOSED_CORE, "Walker exposes core below 75%")
	walker.apply_damage(300.0)
	_expect(walker.boss_phase == AnimalControlWalker.BossPhase.CHARGE, "Walker charges below 45%")
	walker.apply_damage(300.0)
	_expect(walker.boss_phase == AnimalControlWalker.BossPhase.GOLDEN_BALL, "Walker requires Golden Ball below 15%")
	var protected_health := walker.health
	walker.apply_damage(999.0)
	_expect(is_equal_approx(walker.health, protected_health), "Regular damage cannot finish Walker")
	walker.strike_with_golden_ball()
	_expect(walker.is_dead, "Golden Ball finishes Walker")
	walker.free()

func _test_death_animation() -> void:
	var enemy := preload("res://scenes/enemies/mutant_groundskeeper.tscn").instantiate() as EnemyAgent
	root.add_child(enemy)
	await process_frame
	var visual := enemy.get_node("Visual") as Node3D
	enemy.velocity = Vector3(4.0, -8.0, 2.0)
	enemy.apply_damage(9999.0)
	_expect(enemy.is_dead and enemy.velocity == Vector3.ZERO, "Defeated enemy stops moving immediately")
	_expect(not enemy.is_physics_processing(), "Defeated enemy physics stops during animation")
	_expect(visual.rotation == Vector3.ZERO, "Death animation does not rotate artwork through the floor")
	await create_timer(0.12).timeout
	_expect(visual.position.y > 0.0, "Death animation pops upward")
	_expect(visual.scale != Vector3.ONE, "Death animation visibly squashes the enemy")
	enemy.free()

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
