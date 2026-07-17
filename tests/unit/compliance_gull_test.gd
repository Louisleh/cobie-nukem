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
	_test_state_change_cleanup()

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


func _test_state_change_cleanup() -> void:
	var gull := _spawn_gull()
	gull._begin_attack()
	gull._die(fake_target)
	_expect(gull.is_mark_telegraph_active() == false, "Dead gull never retains visible telegraph state")
	gull.queue_free()


func _spawn_gull() -> ComplianceGull:
	var gull := GULL_SCENE.instantiate() as ComplianceGull
	gull.name = &"ComplianceGull"
	gull.position = Vector3.ZERO
	gull.target = fake_target
	gull.initial_target = fake_target
	test_scene.add_child(gull)
	fake_target.is_dead = false
	fake_target.position = Vector3.ZERO
	return gull


class FakeCombatPressure extends Node:
	func request_attack(_source: Node, _priority: int) -> bool:
		return true

	func release_attack(_source: Node) -> void:
		pass


class FakePlayerTarget extends Node3D:
	var is_dead := false

	func apply_damage(_amount: float, _source: Node = null, _hit_position: Vector3 = Vector3.ZERO) -> float:
		return _amount


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
