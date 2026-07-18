extends SceneTree

class FakeTarget extends CharacterBody3D:
	var damage_calls: Array[float] = []
	var impulse_calls: Array[Vector3] = []
	var is_dead := false

	func _init() -> void:
		add_to_group(&"player")

	func apply_damage(amount: float, _source: Node = null, _position := Vector3.ZERO) -> float:
		damage_calls.append(amount)
		if amount >= 1000000.0:
			is_dead = true
		return amount

	func apply_environment_impulse(impulse: Vector3, horizontal_cap := 14.0, vertical_cap := 9.0) -> Vector3:
		var horizontal := Vector2(impulse.x, impulse.z).limit_length(horizontal_cap)
		var bounded := Vector3(horizontal.x, clampf(impulse.y, -vertical_cap, vertical_cap), horizontal.y)
		impulse_calls.append(bounded)
		return bounded


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_definition_contract()
	_test_player_impulse_cap()
	await _test_phases_and_bounded_effects()
	await _test_generation_safe_reset()
	await _test_assist_policies()
	await _test_lethal_water_uses_damage_path()
	if failures.is_empty():
		print("TIMED HAZARD TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_definition_contract() -> void:
	var definition := _definition()
	_expect(definition.validate().is_empty(), "valid timed hazard definition passes")
	var duplicate := definition.duplicate(true) as TimedHazardDefinition
	var manifest := ContentManifest.new()
	manifest.timed_hazards = [definition, duplicate]
	_expect(Array(manifest.validate()).any(func(error: String) -> bool: return error.contains("duplicate timed hazard id")), "manifest rejects duplicate timed hazard ids")
	definition.id = &""
	_expect(not definition.validate().is_empty(), "empty hazard id is rejected")
	definition.id = &"test_hazard"
	definition.volume_size = Vector3.ZERO
	_expect(not definition.validate().is_empty(), "non-positive hazard volume is rejected")
	definition.volume_size = Vector3.ONE
	definition.damage_per_tick = 0.0
	definition.environment_impulse = Vector3.ZERO
	_expect(not definition.validate().is_empty(), "effectless hazard is rejected")


func _test_player_impulse_cap() -> void:
	var player := CobiePlayer.new()
	player.velocity = Vector3(12.0, 8.0, 0.0)
	player.apply_environment_impulse(Vector3(100.0, 100.0, 100.0), 7.0, 5.0)
	_expect(Vector2(player.velocity.x, player.velocity.z).length() <= 7.001, "CobiePlayer hard-caps resulting horizontal environment velocity")
	_expect(absf(player.velocity.y) <= 5.001, "CobiePlayer hard-caps resulting vertical environment velocity")
	player.free()


func _test_phases_and_bounded_effects() -> void:
	var definition := _definition()
	definition.repeat_cycle = false
	definition.warning_seconds = 0.02
	definition.active_seconds = 0.05
	definition.recovery_seconds = 0.02
	definition.tick_seconds = 0.01
	definition.damage_per_tick = 20.0
	definition.environment_impulse = Vector3(100.0, 100.0, 0.0)
	definition.horizontal_impulse_cap = 7.0
	definition.vertical_impulse_cap = 5.0
	var runtime := _spawn_runtime(definition)
	var target := FakeTarget.new()
	root.add_child(target)
	runtime.register_target(target)
	var phases: Array[TimedHazardRuntime.Phase] = []
	runtime.phase_changed.connect(func(_id: StringName, phase: TimedHazardRuntime.Phase) -> void: phases.append(phase))
	await create_timer(0.16).timeout
	_expect(phases.has(TimedHazardRuntime.Phase.ACTIVE), "warning advances to active")
	_expect(phases.has(TimedHazardRuntime.Phase.RECOVERY), "active advances to recovery")
	_expect(runtime.phase == TimedHazardRuntime.Phase.IDLE, "single cycle returns to idle")
	_expect(not target.damage_calls.is_empty(), "active phase damages a registered target")
	_expect(not target.impulse_calls.is_empty(), "active phase applies an environment impulse")
	if not target.impulse_calls.is_empty():
		var impulse := target.impulse_calls[0]
		_expect(Vector2(impulse.x, impulse.z).length() <= 7.001, "horizontal impulse is hard-capped")
		_expect(absf(impulse.y) <= 5.001, "vertical impulse is hard-capped")
	runtime.queue_free()
	target.queue_free()
	await process_frame


func _test_generation_safe_reset() -> void:
	var definition := _definition()
	definition.warning_seconds = 0.04
	definition.active_seconds = 0.04
	var runtime := _spawn_runtime(definition)
	var target := FakeTarget.new()
	root.add_child(target)
	runtime.register_target(target)
	await create_timer(0.01).timeout
	runtime.reset_hazard(false)
	await create_timer(0.12).timeout
	_expect(runtime.phase == TimedHazardRuntime.Phase.IDLE, "reset invalidates pending phase callbacks")
	_expect(target.damage_calls.is_empty(), "reset prevents stale active effects")
	runtime.queue_free()
	target.queue_free()
	await process_frame


func _test_assist_policies() -> void:
	var definition := _definition()
	definition.assist_policy = TimedHazardDefinition.AssistPolicy.REDUCED
	definition.assisted_intensity = 0.25
	definition.damage_per_tick = 20.0
	var runtime := _spawn_runtime(definition, false)
	var target := FakeTarget.new()
	root.add_child(target)
	runtime.register_target(target)
	runtime.assist_enabled = true
	runtime.phase = TimedHazardRuntime.Phase.ACTIVE
	runtime.apply_active_effects()
	_expect(target.damage_calls == [5.0], "reduced assist scales hazard damage")
	target.damage_calls.clear()
	definition.assist_policy = TimedHazardDefinition.AssistPolicy.DISABLED
	runtime.apply_active_effects()
	_expect(target.damage_calls.is_empty(), "disabled assist suppresses hazard effects")
	runtime.queue_free()
	target.queue_free()
	await process_frame


func _test_lethal_water_uses_damage_path() -> void:
	var water := LethalWaterVolume.new()
	water.volume_size = Vector3(3.0, 1.0, 3.0)
	root.add_child(water)
	var target := FakeTarget.new()
	root.add_child(target)
	water._on_body_entered(target)
	_expect(target.damage_calls == [1000000.0], "lethal water routes through apply_damage")
	_expect(target.is_dead, "lethal water reaches the target's normal death state")
	water.queue_free()
	target.queue_free()
	await process_frame


func _spawn_runtime(definition: TimedHazardDefinition, should_start := true) -> TimedHazardRuntime:
	var runtime := TimedHazardRuntime.new()
	runtime.definition = definition
	runtime.start_on_ready = should_start
	root.add_child(runtime)
	return runtime


func _definition() -> TimedHazardDefinition:
	var definition := TimedHazardDefinition.new()
	definition.id = &"test_hazard"
	definition.warning_seconds = 0.05
	definition.active_seconds = 0.1
	definition.recovery_seconds = 0.05
	definition.tick_seconds = 0.025
	definition.damage_per_tick = 10.0
	definition.environment_impulse = Vector3(4.0, 2.0, 0.0)
	definition.horizontal_impulse_cap = 8.0
	definition.vertical_impulse_cap = 6.0
	definition.volume_size = Vector3.ONE
	definition.collision_mask = 2
	return definition


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
