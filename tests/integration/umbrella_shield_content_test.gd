extends SceneTree

const TEST_SCENE_PATH := "res://scenes/enemies/umbrella_shield_enforcer.tscn"
const DIFFICULTY_PROFILES := [
	"res://resources/difficulty/classic.tres",
	"res://resources/difficulty/story.tres",
	"res://resources/difficulty/mayhem.tres",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(TEST_SCENE_PATH) as PackedScene
	_expect(packed != null, "Umbrella enforcer scene loads")
	if packed == null:
		_finish()
		return

	var enemy := packed.instantiate() as UmbrellaShieldEnforcer
	_expect(enemy != null, "Umbrella enforcer instantiates as UmbrellaShieldEnforcer")
	if enemy == null:
		_finish()
		return

	root.add_child(enemy)
	await process_frame

	var definition := enemy.definition
	_expect(definition != null, "EnemyDefinition is assigned")
	if definition == null:
		_finish()
		return

	_expect(definition.id == &"umbrella_shield_enforcer", "Enemy resource ID is stable")
	_expect(definition.max_health >= 120.0 and definition.max_health <= 180.0, "Base HP is in the 120-180 window")
	_expect(is_finite(definition.max_health), "Max health is finite")
	_expect(is_finite(definition.attack_range), "Attack range is finite")
	_expect(definition.attack_range > 0.0, "Ranged attack window has positive distance")
	_expect(definition.preferred_distance > definition.retreat_distance, "Ranged preferred distance remains readable")
	_expect(definition.preferred_distance > 0.0 and definition.retreat_distance > 0.0, "Ranged distance values are non-zero")

	var visual_shield := enemy.get_node_or_null("Visual/Shield") as Node3D
	_expect(visual_shield != null, "Shield visual path exists")

	var shield := enemy.get_node_or_null("DirectionalShieldComponent") as DirectionalShieldComponent
	_expect(shield != null, "Directional shield component is present")
	_expect(enemy.directional_shield == shield, "Script references authored shield node")
	if shield != null:
		_expect(is_finite(shield.maximum_shield_health) and shield.maximum_shield_health > 0.0, "Shield health is finite and bounded")
		_expect(shield.visual_target_path == NodePath("Visual/Shield"), "Shield visual target path is stable")
		shield.reset()
		_expect(is_finite(shield.current_shield_health) and shield.current_shield_health == shield.maximum_shield_health, "Shield resets to full health")
		var hit_position := enemy.global_position + Vector3.FORWARD * 2.2
		shield.damage_multiplier(enemy, hit_position, 20.0)
		_expect(shield.current_shield_health < shield.maximum_shield_health, "Shield takes bounded directional damage")

		var guard_hits := 0
		while not shield.is_permanently_broken() and guard_hits < 20:
			shield.damage_multiplier(enemy, hit_position, 20.0)
			guard_hits += 1
		_expect(shield.is_permanently_broken(), "Shield can enter permanently broken state")

		var health_bar := enemy.get_node_or_null("EnemyHealthBar") as Node3D
		var health_label := enemy.get_node_or_null("EnemyHealthBar/HealthPoints") as Label3D
		_expect(health_bar != null, "Health bar node exists")
		if health_label != null:
			_expect(not health_label.text.is_empty(), "Health label is populated")
			_expect(health_label.fixed_size, "Health label is fixed-size")

	_expect(enemy.get_node_or_null("AutoAimTarget") != null, "AutoAimTarget marker exists")
	_expect(enemy.get_node_or_null("Telegraph") != null, "Telegraph node exists")

	var target := Node3D.new()
	root.add_child(target)
	enemy.set_target(target)
	enemy._set_state(EnemyAgent.State.CHASE)
	await process_frame

	var profile_ok := true
	for path in DIFFICULTY_PROFILES:
		var profile := load(path) as DifficultyProfile
		if profile == null:
			profile_ok = false
			break
		enemy.apply_difficulty(profile)
		if not (is_finite(enemy.get_opening_window_seconds()) and is_finite(enemy.get_recovery_window_seconds())):
			profile_ok = false
			break
		if enemy.get_opening_window_seconds() <= 0.0 or enemy.get_recovery_window_seconds() <= 0.0:
			profile_ok = false
			break
		if not is_finite(enemy.health):
			profile_ok = false
			break
	_expect(profile_ok, "Difficulty timing and scaled health remain finite and valid")

	enemy.apply_damage(enemy.health, enemy, enemy.global_position)
	await process_frame
	_expect(enemy.is_dead, "Damage application can finish the enforcer")
	_expect(enemy.state == EnemyAgent.State.DEAD, "Dead enemy transitions to DEAD state")
	_expect(not enemy.is_in_group(&"auto_aim_targets"), "Auto-aim group removed on death")

	for _i in 3:
		await create_timer(0.2).timeout

	target.queue_free()
	enemy.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: umbrella shield enforcer integration contract")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

