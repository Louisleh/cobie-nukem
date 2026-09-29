extends SceneTree

const GROUNDSKEEPER := preload("res://scenes/enemies/mutant_groundskeeper.tscn")
const PLAYER := preload("res://scenes/player/cobie_player.tscn")
var failures: Array[String] = []

class DamageTarget extends CharacterBody3D:
	var damage_events := 0
	func apply_damage(_amount: float, _source: Node = null, _position := Vector3.ZERO) -> float:
		damage_events += 1
		return _amount

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(30.0, 0.5, 30.0)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.25
	root.add_child(floor_body)
	await _exercise_charge(false)
	await _exercise_charge(true)
	await _exercise_charge(false, true)
	await _exercise_charge(true, false, true)
	await _exercise_player_dodge()
	floor_body.free()
	await process_frame
	if failures.is_empty():
		print("GROUNDSKEEPER CHARGE COUNTERPLAY: PASS")
		quit(0)
	else:
		for failure in failures: push_error("CHARGE: " + failure)
		quit(1)

func _exercise_charge(dodge: bool, blocked := false, interrupt := false) -> void:
	var enemy := GROUNDSKEEPER.instantiate() as MutantGroundskeeper
	var target := DamageTarget.new()
	var target_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.78
	target_shape.position.y = 0.89
	target_shape.shape = capsule
	target.add_child(target_shape)
	target.collision_layer = 2
	root.add_child(target)
	root.add_child(enemy)
	target.global_position = Vector3(0.0, 0.0, -2.0)
	enemy.global_position = Vector3.ZERO
	var wall: StaticBody3D
	if blocked:
		wall = StaticBody3D.new()
		wall.collision_layer = 1
		var wall_shape := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = Vector3(3.0, 3.0, 0.35)
		wall_shape.shape = wall_box
		wall.add_child(wall_shape)
		wall.position = Vector3(0.0, 1.0, -1.0)
		root.add_child(wall)
	enemy.set_target(target)
	await physics_frame
	enemy._begin_attack()
	var start := enemy.global_position
	var maximum_travel := 0.0
	var observed_charge := false
	var landing_x := INF
	for tick in 100:
		if dodge and tick == 22:
			target.global_position.x = 3.5
		if interrupt and tick == 62:
			_expect(enemy._charging, "charge active before damage interruption")
			enemy.apply_damage(1.0)
			_expect(not enemy._charging and enemy.state != EnemyAgent.State.ATTACK, "damage interrupts charge and releases attack state")
		await physics_frame
		if dodge and tick == 50:
			_expect(absf(enemy.rotation.y) < 0.2, "telegraph faces the locked charge lane after a dodge")
		maximum_travel = maxf(maximum_travel, enemy.global_position.distance_to(start))
		if observed_charge and not enemy._charging and is_inf(landing_x):
			landing_x = enemy.global_position.x
		observed_charge = observed_charge or enemy._charging
	_expect(observed_charge, "charge persists beyond the telegraph in %s case" % ("dodge" if dodge else "stationary"))
	_expect(not enemy._charging and enemy.state != EnemyAgent.State.ATTACK, "charge terminates and releases attack state")
	if blocked:
		_expect(maximum_travel < 0.6 and target.damage_events == 0, "solid cover blocks movement and charge damage")
	elif dodge:
		_expect(maximum_travel > 2.0, "charge crosses the emptied dodge lane")
		_expect(target.damage_events == 0, "moving sideways during warning escapes the committed lane")
		_expect(absf(landing_x) < 1.0, "dodge does not retarget charge sideways")
	else:
		_expect(maximum_travel > 0.8, "charge reaches stationary contact")
		_expect(target.damage_events == 1, "stationary target in charge lane takes exactly one hit")
	print("CHARGE RECEIPT: case=%s travel=%.3f landing_x=%.3f hits=%d" % ["blocked" if blocked else "dodge" if dodge else "stationary", maximum_travel, landing_x, target.damage_events])
	enemy.free()
	target.free()
	if wall != null:
		wall.free()
	await physics_frame

func _exercise_player_dodge() -> void:
	var player := PLAYER.instantiate() as CobiePlayer
	var enemy := GROUNDSKEEPER.instantiate() as MutantGroundskeeper
	root.add_child(player)
	root.add_child(enemy)
	player.global_position = Vector3(0.0, 0.0, -2.0)
	enemy.global_position = Vector3.ZERO
	enemy.set_target(player)
	await physics_frame
	enemy._begin_attack()
	var first_health := player.health_armor.health
	var strafe := InputEventKey.new()
	strafe.physical_keycode = KEY_D
	strafe.pressed = true
	_expect(InputMap.event_is_action(strafe, &"strafe_right"), "physical D maps to right strafe")
	for tick in 90:
		if tick == 22:
			Input.parse_input_event(strafe)
		if tick == 60:
			strafe.pressed = false
			Input.parse_input_event(strafe)
		await physics_frame
	strafe.pressed = false
	Input.parse_input_event(strafe)
	_expect(player.global_position.x > 2.0, "real player moved laterally on mapped input")
	_expect(player.health_armor.health == first_health, "real player dodges locked charge during warning")
	print("CHARGE RECEIPT: case=mapped_player x=%.3f health_before=%.1f health_after=%.1f" % [player.global_position.x, first_health, player.health_armor.health])
	enemy.free()
	player.free()
	await physics_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
