extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	var container := Node3D.new()
	root.add_child(container)
	await process_frame
	_test_guarding_toggle(container)
	_test_front_and_rear_arc(container)
	container.free()
	if failures.is_empty():
		print("PASS: directional shield component contract")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_guarding_toggle(container: Node3D) -> void:
	var shield := _build_shield()
	container.add_child(shield)
	await process_frame

	var front := Vector3(0.0, 0.0, -4.0)
	_expect(shield.shield_active, "shield starts active after reset")
	_expect(not shield.shield_is_broken, "shield starts unbroken")
	_expect(shield.current_shield_health == shield.maximum_shield_health, "shield starts full")
	_expect(shield.damage_multiplier(container, container.global_position + front, 20.0) == shield.blocked_damage_multiplier, "front hit is blocked with active guard")
	_expect(is_equal_approx(shield.current_shield_health, 25.0), "front hit drains one hit-cost")

	shield.set_guarding(false)
	_expect(not shield.shield_active, "set_guarding(false) disables frontal guard")
	_expect(shield.damage_multiplier(container, container.global_position + front, 20.0) == 1.0, "open guard bypasses front block and uses full multiplier")
	_expect(is_equal_approx(shield.current_shield_health, 25.0), "open guard does not drain shield health")

	shield.set_guarding(true)
	_expect(shield.shield_active, "set_guarding(true) re-enables frontal guard")
	_expect(shield.damage_multiplier(container, container.global_position + front, 20.0) == shield.blocked_damage_multiplier, "front hit is blocked after re-enable")
	_expect(is_equal_approx(shield.current_shield_health, 10.0), "shield drains while guarding is re-enabled")
	_expect(not shield.shield_is_broken, "shield has not broken yet")

	shield.damage_multiplier(container, container.global_position + front, 20.0)
	_expect(shield.shield_is_broken, "shield breaks when guarded health reaches zero")
	_expect(not shield.shield_active, "broken shield is not active")

	shield.set_guarding(true)
	_expect(not shield.shield_active, "broken shield cannot be re-enabled")
	shield.reset()
	_expect(shield.shield_active and not shield.shield_is_broken, "reset restores guard and clears break")
	_expect(shield.current_shield_health == shield.maximum_shield_health, "reset restores configured health")
	shield.free()


func _test_front_and_rear_arc(container: Node3D) -> void:
	var shield := _build_shield()
	container.add_child(shield)
	await process_frame

	shield.reset()
	shield.shield_arc_degrees = 120.0
	shield.shield_hit_cost = 10.0
	var front := Vector3(0.0, 0.0, -3.0)
	var rear := Vector3(0.0, 0.0, 3.0)
	_expect(shield.damage_multiplier(container, container.global_position + front, 20.0) == shield.blocked_damage_multiplier, "front arc remains guarded")
	_expect(shield.damage_multiplier(container, container.global_position + rear, 20.0) == shield.break_damage_multiplier, "rear arc bypasses guard")

	var loops := 0
	while loops < 10 and not shield.shield_is_broken:
		shield.damage_multiplier(container, container.global_position + front, 20.0)
		loops += 1
	_expect(shield.shield_is_broken, "repeated guarded front hits can still break shield")
	shield.set_guarding(true)
	_expect(not shield.shield_active, "broken shield is permanently non-guarding")
	shield.reset()
	_expect(is_equal_approx(shield.get_health_fraction(), 1.0), "reset restores full fraction")
	shield.free()


func _build_shield() -> DirectionalShieldComponent:
	var shield := DirectionalShieldComponent.new()
	shield.maximum_shield_health = 40.0
	shield.shield_hit_cost = 15.0
	shield.blocked_damage_multiplier = 0.25
	shield.break_damage_multiplier = 1.5
	return shield


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

