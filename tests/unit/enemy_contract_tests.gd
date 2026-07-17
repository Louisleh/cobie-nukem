extends SceneTree

const ENEMY_SCENES := [
	"res://scenes/enemies/leash_enforcement_drone.tscn",
	"res://scenes/enemies/mutant_groundskeeper.tscn",
	"res://scenes/enemies/squirrel_trooper.tscn",
	"res://scenes/enemies/compliance_hound.tscn",
	"res://scenes/enemies/animal_control_walker.tscn",
	"res://scenes/enemies/compliance_gull.tscn",
	"res://scenes/enemies/umbrella_shield_enforcer.tscn",
]
const EXPECTED_HEALTH := {
	"leash_enforcement_drone": 40.0,
	"mutant_groundskeeper": 80.0,
	"squirrel_trooper": 30.0,
	"compliance_hound": 220.0,
	"animal_control_walker": 1000.0,
	"compliance_gull": 42.0,
	"umbrella_shield_enforcer": 150.0,
}

var failures: Array[String] = []

class DamageTarget extends CharacterBody3D:
	var damage_received := 0.0
	func apply_damage(amount: float, _source: Node = null, _hit_position := Vector3.ZERO) -> float:
		damage_received += amount
		return amount

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
		# Enemies are sprite-primary (meshes hidden); a wrong pixel_size or an
		# unapplied atlas grid renders them as a sub-meter speck or a full sheet.
		var detailed := enemy.get_node_or_null("Visual/DetailedSprite") as Sprite3D
		if detailed != null and detailed.visible:
			var sprite_height := detailed.get_aabb().size.y * detailed.scale.y
			_expect(sprite_height >= 0.8, "Primary sprite is not a tiny speck: %s (%.2f)" % [scene_path, sprite_height])
			_expect(sprite_height <= 6.0, "Primary sprite is not an oversized sheet: %s (%.2f)" % [scene_path, sprite_height])
		else:
			var visible_extent := _visible_mesh_extent(enemy.get_node_or_null("Visual"))
			_expect(visible_extent >= 0.8, "Mesh-primary enemy is not a tiny speck: %s (%.2f)" % [scene_path, visible_extent])
			_expect(visible_extent <= 6.0, "Mesh-primary enemy is not implausibly oversized: %s (%.2f)" % [scene_path, visible_extent])
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
			_expect(enemy is LeashEnforcementDrone or enemy is ComplianceGull, "Only authored flying enemies bypass gravity: %s" % scene_path)
		var before := enemy.health
		var applied := enemy.apply_damage(5.0, null, enemy.global_position)
		_expect(applied > 0.0, "Damage hook applies: %s" % scene_path)
		_expect(enemy.health < before, "Health decreases: %s" % scene_path)
		if health_label != null:
			_expect(health_label.text.begins_with(str(ceili(enemy.health))), "Numeric HP updates immediately: %s" % scene_path)
		if health_fill != null:
			_expect((health_fill.mesh as QuadMesh).size.x < full_width, "Health bar shrinks immediately: %s" % scene_path)
		enemy.free()
	await _test_hound_shield()
	await _test_charge_obstruction()
	await _test_walker_phases()
	await _test_death_animation()
	if failures.is_empty():
		print("PASS: enemy contracts, damage hooks, shield, and boss phases")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _visible_mesh_extent(visual: Node) -> float:
	if visual == null:
		return 0.0
	var extent := 0.0
	for candidate in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if not mesh_instance.visible or mesh_instance.mesh == null:
			continue
		var bounds := mesh_instance.get_aabb()
		var scaled := bounds.size * mesh_instance.scale.abs()
		extent = maxf(extent, maxf(scaled.x, maxf(scaled.y, scaled.z)))
	return extent

func _test_hound_shield() -> void:
	var hound := preload("res://scenes/enemies/compliance_hound.tscn").instantiate() as ComplianceHound
	root.add_child(hound)
	await process_frame

	var directional_shield := hound.get_node("DirectionalShieldComponent") as DirectionalShieldComponent
	_expect(directional_shield != null, "Hound has directional shield component")
	if directional_shield == null:
		hound.free()
		return

	var broken_signals: Array[bool] = []
	var reset_signals: Array[bool] = []
	directional_shield.shield_broken.connect(func() -> void: broken_signals.append(true))
	directional_shield.shield_reset.connect(func() -> void: reset_signals.append(true))

	var arc_half := deg_to_rad(directional_shield.shield_arc_degrees * 0.5)
	var arc_inside := Vector3(-sin(arc_half - deg_to_rad(0.25)), 0.0, -cos(arc_half - deg_to_rad(0.25)))
	var arc_outside := Vector3(-sin(arc_half + deg_to_rad(0.25)), 0.0, -cos(arc_half + deg_to_rad(0.25)))
	var arc_probe_health := directional_shield.current_shield_health
	directional_shield.reset()
	_expect(reset_signals.size() == 1, "Hound shield reset emits once")

	var inside_multiplier := directional_shield.damage_multiplier(hound, hound.global_position + arc_inside, 20.0)
	var flank_multiplier := directional_shield.damage_multiplier(hound, hound.global_position + arc_outside, 20.0)
	var rear_multiplier := directional_shield.damage_multiplier(hound, hound.global_position + Vector3.BACK, 20.0)
	_expect(is_equal_approx(inside_multiplier, directional_shield.blocked_damage_multiplier), "Hound directional shield includes arc interior")
	_expect(is_equal_approx(directional_shield.current_shield_health, arc_probe_health - directional_shield.shield_hit_cost), "Shield quantum drains on first blocked hit")
	_expect(flank_multiplier == directional_shield.break_damage_multiplier, "Hound flank bypasses shield arc")
	_expect(rear_multiplier > directional_shield.blocked_damage_multiplier, "Hound rear weak point bypass multiplier is higher than front")
	_expect(flank_multiplier == directional_shield.break_damage_multiplier and rear_multiplier == directional_shield.break_damage_multiplier, "Both flank and rear bypass multiplier are bypass mode")
	_expect(broken_signals.size() == 0, "Arc probes do not break shield")

	directional_shield.reset()
	_expect(reset_signals.size() == 2, "Hound shield reset emits exactly once per shield probe sequence")
	_expect(is_equal_approx(directional_shield.current_shield_health, directional_shield.maximum_shield_health), "Hound shield reset restores full health before frontal sequence")

	var blocked_damage := directional_shield.blocked_damage_multiplier * 20.0
	var first_front_hit := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	var second_front_hit := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	var third_front_hit := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	var fourth_front_hit := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	_expect(first_front_hit == blocked_damage and second_front_hit == blocked_damage, "Shield blocked first two frontal hits before break")
	_expect(broken_signals.size() == 1, "Shield emits broken exactly once after repeated frontal hits")
	_expect(not directional_shield.shield_active, "Shield deactivates after repeated frontal shield hits")
	_expect(third_front_hit == 20.0 and fourth_front_hit == 20.0, "Post-break frontal hit keeps full incoming damage")
	var shield_node := hound.get_node("Visual/Shield") as Node3D
	_expect(shield_node != null, "Hound shield visual exists for reset lifecycle")
	if shield_node != null:
		_expect(shield_node.visible == false, "Hound shield hides when broken")
	_expect(broken_signals.size() == 1, "Hound shield keeps broken emission to one across post-break hits")

	directional_shield.reset()
	_expect(reset_signals.size() == 3, "Shield reset emits exactly once per reset cycle")
	_expect(is_equal_approx(directional_shield.current_shield_health, directional_shield.maximum_shield_health), "Hound shield reset restores full health")
	_expect(shield_node != null and shield_node.visible == true, "Hound shield reset restores visual")

	var front_hit_after_reset := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	var front_hit_after_reset_still_blocked := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	var front_hit_after_reset_break := hound.apply_damage(20.0, null, hound.global_position + Vector3.FORWARD)
	_expect(front_hit_after_reset == blocked_damage and front_hit_after_reset_still_blocked == blocked_damage, "Shield absorbs two blocked hits after reset")
	_expect(front_hit_after_reset_break == 20.0, "Post-break hit after reset keeps full damage")
	_expect(not directional_shield.shield_active, "Hound shield can break again after reset")
	_expect(broken_signals.size() == 2, "Shield emits broken exactly one time after reset cycle")

	hound.free()

func _test_charge_obstruction() -> void:
	var hound := preload("res://scenes/enemies/compliance_hound.tscn").instantiate() as ComplianceHound
	var target := DamageTarget.new()
	var target_shape := CollisionShape3D.new()
	var target_capsule := CapsuleShape3D.new()
	target_capsule.height = 1.8
	target_capsule.radius = 0.4
	target_shape.shape = target_capsule
	target.add_child(target_shape)
	root.add_child(hound)
	root.add_child(target)
	hound.global_position = Vector3(0.0, 0.1, 0.0)
	target.global_position = Vector3(0.0, 0.1, -2.0)
	hound.set_target(target)
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(3.0, 3.0, 0.35)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0.0, 1.0, -1.0)
	root.add_child(wall)
	await physics_frame
	await physics_frame
	hound._perform_attack()
	_expect(is_zero_approx(target.damage_received), "Hound charge cannot damage through solid cover")
	wall.queue_free()
	await physics_frame
	hound._perform_attack()
	_expect(target.damage_received > 0.0, "Hound charge damages a target on a clear path")
	hound.free()
	target.free()

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
