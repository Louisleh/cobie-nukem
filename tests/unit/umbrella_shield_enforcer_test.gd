extends SceneTree

var failures: Array[String] = []

class DummyTarget:
	extends Node3D

	var hit_count := 0
	var last_damage := 0.0

	func apply_damage(amount: float, source: Node = null, hit_position: Vector3 = Vector3.ZERO) -> float:
		hit_count += 1
		last_damage = amount
		return amount


func _initialize() -> void:
	var harness := Node3D.new()
	root.add_child(harness)
	await process_frame
	_test_attack_opening_and_recovery(harness)
	_test_difficulty_and_death_lock(harness)
	_test_timer_generation_safety(harness)
	harness.free()

	if failures.is_empty():
		print("PASS: umbrella shield enforcer contract")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_attack_opening_and_recovery(harness: Node3D) -> void:
	var enemy := _build_umbrella()
	harness.add_child(enemy)
	var target := DummyTarget.new()
	harness.add_child(target)
	enemy.set_target(target)
	await process_frame

	enemy._set_state(UmbrellaShieldEnforcer.State.CHASE)
	await process_frame
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.GUARDING, "chase starts guarded")

	enemy._set_state(UmbrellaShieldEnforcer.State.ATTACK)
	var open_delay := maxf(enemy.definition.telegraph_seconds - enemy.get_opening_window_seconds(), 0.0)
	await create_timer(open_delay * 0.4).timeout
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.GUARDING, "attack enters with guard closed")
	await create_timer(open_delay * 0.75).timeout
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.OPENING, "guard opens during attack opening")

	enemy._perform_attack()
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.RECOVERING, "attack enters recovery after opening fire")
	enemy._set_state(UmbrellaShieldEnforcer.State.CHASE)
	var baseline_timer_count := _guard_timer_count(enemy)
	await create_timer(enemy.get_recovery_window_seconds() + 0.04).timeout
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.GUARDING, "guard returns after recovery")
	_expect(_guard_timer_count(enemy) == baseline_timer_count, "guard uses shared timer node")
	enemy.free()
	target.free()


func _test_timer_generation_safety(harness: Node3D) -> void:
	var enemy := _build_umbrella()
	harness.add_child(enemy)
	var target := DummyTarget.new()
	harness.add_child(target)
	enemy.set_target(target)
	await process_frame

	# Opening timer should not apply after leaving ATTACK before timeout.
	enemy._set_state(UmbrellaShieldEnforcer.State.ATTACK)
	var open_delay := maxf(enemy.definition.telegraph_seconds - enemy.get_opening_window_seconds(), 0.0)
	await create_timer(open_delay * 0.5).timeout
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.GUARDING, "attack begins guarded before opening")
	enemy._set_state(UmbrellaShieldEnforcer.State.IDLE)
	await create_timer(open_delay + 0.08).timeout
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.GUARDING, "stale opening timer cannot reopen guard after attack cancel")

	# Recovery timer should not re-arm after switching states.
	enemy._start_guard_recovery()
	enemy._set_state(UmbrellaShieldEnforcer.State.ATTACK)
	var recovery_window := enemy.get_recovery_window_seconds()
	await create_timer(recovery_window * 0.35).timeout
	enemy._set_state(UmbrellaShieldEnforcer.State.IDLE)
	await create_timer(recovery_window + 0.08).timeout
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.GUARDING, "stale recovery timer cannot reopen guard")

	enemy.free()
	target.free()


func _test_difficulty_and_death_lock(harness: Node3D) -> void:
	var enemy := _build_umbrella()
	harness.add_child(enemy)
	var target := DummyTarget.new()
	harness.add_child(target)
	enemy.set_target(target)
	await process_frame

	var baseline_open := enemy.get_opening_window_seconds()
	var hard_profile := DifficultyProfile.new()
	hard_profile.enemy_aggression_multiplier = 2.0
	enemy.apply_difficulty(hard_profile)
	_expect(enemy.get_opening_window_seconds() < baseline_open, "hard aggression shortens opening window")

	while enemy.directional_shield != null and not enemy.directional_shield.shield_is_broken:
		enemy.directional_shield.damage_multiplier(enemy, enemy.global_position + Vector3.BACK * -1.0 * 2.0, 20.0)
	_expect(enemy.directional_shield.is_permanently_broken(), "front-facing hits can still break shield")
	enemy._set_state(UmbrellaShieldEnforcer.State.CHASE)
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.BROKEN, "broken shield transitions to broken guard state")
	enemy.apply_damage(enemy.health, null, enemy.global_position)
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.DISABLED, "death disables guard state")
	enemy._set_state(UmbrellaShieldEnforcer.State.IDLE)
	_expect(enemy.guard_state == UmbrellaShieldEnforcer.GuardState.DISABLED, "death state persists after state changes")
	enemy.free()
	target.free()


func _build_umbrella() -> UmbrellaShieldEnforcer:
	var definition := EnemyDefinition.new()
	definition.max_health = 70.0
	definition.move_speed = 3.5
	definition.attack_range = 16.0
	definition.telegraph_seconds = 0.45
	definition.attack_cooldown = 0.5
	definition.attack_damage = 12.0

	var enemy := UmbrellaShieldEnforcer.new()
	enemy.definition = definition
	enemy.base_opening_window_seconds = 0.20
	enemy.base_recovery_window_seconds = 0.14

	var shield := DirectionalShieldComponent.new()
	shield.name = "DirectionalShieldComponent"
	shield.maximum_shield_health = 45.0
	enemy.add_child(shield)

	return enemy


func _guard_timer_count(enemy: UmbrellaShieldEnforcer) -> int:
	var count := 0
	for child in enemy.get_children():
		if child is Timer and child.name == "UmbrellaGuardTimer":
			count += 1
	return count


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
