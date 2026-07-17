extends SceneTree

var failures: Array[String] = []
const GULL_SCENE := preload("res://scenes/enemies/compliance_gull.tscn")

var fake_pressure: FakeCombatPressure
var fake_target: FakePlayerTarget
var test_scene: Node3D


func _initialize() -> void:
	test_scene = Node3D.new()
	test_scene.name = &"ComplianceGullTestScene"
	root.add_child(test_scene)
	set_current_scene(test_scene)
	fake_pressure = FakeCombatPressure.new()
	fake_pressure.name = &"CombatPressure"
	test_scene.add_child(fake_pressure)
	fake_target = FakePlayerTarget.new()
	fake_target.name = &"FakeTarget"
	test_scene.add_child(fake_target)
	call_deferred("_run")

func _run() -> void:
	_test_visible_telegraph()
	_test_interrupt_clears_telegraph()
	_test_attack_mark_signal_emission()
	_test_commit_does_not_deal_instant_damage()
	_test_dive_hits_then_recovers()
	_test_locked_dive_can_miss()
	_test_committed_dive_is_interruptible()
	_test_state_change_cleanup()
	_test_dive_retains_pressure_token()

	if fake_pressure != null:
		fake_pressure.queue_free()
	if fake_target != null:
		fake_target.queue_free()
	if test_scene != null:
		test_scene.queue_free()

	if failures.is_empty():
		print("COMPLIANCE GULL TEST: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_visible_telegraph() -> void:
	var gull := _spawn_gull()
	var searchlight := gull.get_node_or_null("Visual/Searchlight") as GeometryInstance3D

	gull._begin_attack()
	_expect(gull.is_mark_telegraph_active(), "Compliance Gull toggles telegraph state when attack starts")
	_expect(searchlight != null and searchlight.visible, "Compliance Gull renders visible telegraph searchlight during attack wind-up")
	_expect(gull._telegraph_active == true, "Internal telegraph state mirrors visible searchlight")
	gull.queue_free()


func _test_interrupt_clears_telegraph() -> void:
	var gull := _spawn_gull()
	var interrupted := [false]
	gull.dive_interrupted.connect(func() -> void:
		interrupted[0] = true
	)

	gull._begin_attack()
	gull.apply_damage(1.0, fake_target, Vector3.ZERO)
	_expect(gull.is_mark_telegraph_active() == false, "Damage during wind-up clears gull telegraph")
	_expect(interrupted[0], "Damage during wind-up emits dive interruption")
	gull.queue_free()


func _test_attack_mark_signal_emission() -> void:
	var gull := _spawn_gull()
	var marked := [false]
	gull.target_marked.connect(func(_target: Node, _duration: float) -> void:
		marked[0] = true
	)
	gull._perform_attack()
	_expect(marked[0], "Compliance Gull emits searchlight marking when attack executes")
	gull.queue_free()


func _test_commit_does_not_deal_instant_damage() -> void:
	var gull := _spawn_gull()
	var started := [false]
	gull.dive_started.connect(func(_position: Vector3) -> void:
		started[0] = true
	)
	gull._perform_attack()
	_expect(started[0] and gull.is_dive_active(), "Attack commit begins a physical Gull dive")
	_expect(is_zero_approx(fake_target.damage_received), "Gull commit never deals instant unavoidable damage")
	gull.queue_free()


func _test_dive_hits_then_recovers() -> void:
	var gull := _spawn_gull()
	var results: Array[bool] = []
	gull.dive_resolved.connect(func(hit: bool) -> void:
		results.append(hit)
	)
	gull._perform_attack()
	for _step in 24:
		gull._advance_dive(0.05)
		if not gull.is_dive_active():
			break
	_expect(not results.is_empty() and results[0], "Gull resolves a physical hit only after reaching the marked point")
	_expect(fake_target.damage_received > 0.0, "Physical Gull contact applies authored damage")
	_expect(gull.is_dive_recovering(), "Gull exposes a readable recovery window after contact")
	for _step in 48:
		gull._advance_dive(0.05)
		if not gull.is_dive_recovering():
			break
	_expect(not gull.is_dive_recovering(), "Gull recovery ends deterministically")
	gull.queue_free()


func _test_locked_dive_can_miss() -> void:
	var gull := _spawn_gull()
	var results: Array[bool] = []
	gull.dive_resolved.connect(func(hit: bool) -> void:
		results.append(hit)
	)
	gull._perform_attack()
	fake_target.position.x = 6.0
	for _step in 24:
		gull._advance_dive(0.05)
		if not gull.is_dive_active():
			break
	_expect(not results.is_empty() and results[0] == false, "Moving away from the marked point makes the readable dive miss")
	_expect(is_zero_approx(fake_target.damage_received), "A missed Gull dive applies no damage")
	gull.queue_free()


func _test_committed_dive_is_interruptible() -> void:
	var gull := _spawn_gull()
	var interrupted := [false]
	gull.dive_interrupted.connect(func() -> void:
		interrupted[0] = true
	)
	gull._perform_attack()
	_expect(gull.is_dive_active(), "Gull is in committed dive before interruption")
	gull.apply_damage(1.0, fake_target, gull.global_position)
	_expect(interrupted[0], "Damage interrupts a committed Gull dive")
	_expect(not gull.is_dive_active(), "Interrupted Gull cannot continue its damage path")
	for _step in 24:
		gull._advance_dive(0.05)
	_expect(is_zero_approx(fake_target.damage_received), "Interrupted Gull never applies stale dive damage")
	gull.queue_free()


func _test_state_change_cleanup() -> void:
	var gull := _spawn_gull()
	gull._begin_attack()
	gull._die(fake_target)
	_expect(gull.is_mark_telegraph_active() == false, "Dead gull never retains visible telegraph state")
	gull.queue_free()


func _test_dive_retains_pressure_token() -> void:
	var pressure := root.get_node_or_null("CombatPressure")
	if pressure == null:
		failures.append("CombatPressure autoload is available for Gull pressure test")
		return
	pressure.reset()
	pressure.configure_limit(1)
	var gull := _spawn_gull()
	_expect(pressure.request_attack(gull, 1), "Gull acquires the only attack-pressure token")
	gull._set_state(ComplianceGull.State.ATTACK)
	gull._perform_attack()
	# Repeated base recovery attempts used to release the token even though the
	# Gull override correctly held ATTACK through its physical dive.
	for _step in 8:
		gull._state_time = gull.definition.telegraph_seconds + 0.3
		gull._physics_process(0.016)
	var blocked_actor := Node.new()
	test_scene.add_child(blocked_actor)
	_expect(not pressure.request_attack(blocked_actor, 1), "Gull retains its token until dive and recovery finish")
	for _step in 80:
		gull._advance_dive(0.05)
		if not gull.is_dive_active() and not gull.is_dive_recovering():
			break
	_expect(pressure.request_attack(blocked_actor, 1), "Gull releases its token exactly when recovery exits ATTACK")
	pressure.release_attack(blocked_actor)
	blocked_actor.queue_free()
	gull.queue_free()


func _spawn_gull() -> ComplianceGull:
	var gull := GULL_SCENE.instantiate() as ComplianceGull
	gull.name = &"ComplianceGull"
	gull.position = Vector3.ZERO
	gull.target = fake_target
	gull.initial_target = fake_target
	test_scene.add_child(gull)
	fake_target.is_dead = false
	fake_target.position = Vector3(0.0, 0.0, -6.0)
	fake_target.damage_received = 0.0
	return gull


class FakeCombatPressure extends Node:
	func request_attack(_source: Node, _priority: int) -> bool:
		return true

	func release_attack(_source: Node) -> void:
		pass


class FakePlayerTarget extends Node3D:
	var is_dead := false
	var damage_received := 0.0

	func apply_damage(amount: float, _source: Node = null, _hit_position: Vector3 = Vector3.ZERO) -> float:
		damage_received += amount
		return amount


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
