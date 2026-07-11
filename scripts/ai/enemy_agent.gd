class_name EnemyAgent
extends CharacterBody3D

signal state_changed(previous: State, current: State)
signal telegraph_started(kind: StringName, duration: float)
signal attack_fired(kind: StringName)
signal damaged(amount: float, source: Node, hit_position: Vector3)
signal died(enemy: EnemyAgent, source: Node)
signal drop_requested(drop_id: StringName, position: Vector3)

enum State { IDLE, ALERT, CHASE, ATTACK, HURT, STUNNED, DEAD }

@export var definition: EnemyDefinition
@export var initial_target: Node3D
@export var target_height := 1.0
@export var death_linger_seconds := 1.25
@export var attack_kind: StringName = &"attack"

var state := State.IDLE
var health := 1.0
var is_dead := false
var auto_aim_threat := 0.5
var target: Node3D
var _state_time := 0.0
var _cooldown := 0.0
var _attack_committed := false
var _reacquire_time := 0.0
var _distraction_position := Vector3.ZERO
var _distraction_time := 0.0

func _ready() -> void:
	add_to_group(&"enemies")
	add_to_group(&"auto_aim_targets")
	if definition == null:
		push_error("Enemy requires an EnemyDefinition: %s" % name)
		return
	health = definition.max_health
	auto_aim_threat = definition.threat_weight
	target = initial_target

func _physics_process(delta: float) -> void:
	if definition == null or is_dead:
		return
	_state_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_distraction_time = maxf(0.0, _distraction_time - delta)
	_reacquire_time -= delta
	if _reacquire_time <= 0.0:
		_reacquire_time = 0.4
		_acquire_target()
	if state == State.STUNNED:
		velocity = velocity.move_toward(Vector3.ZERO, definition.acceleration * delta)
		move_and_slide()
		if _state_time >= 0.7:
			_set_state(State.CHASE)
		return
	if _distraction_time > 0.0:
		_move_toward(_distraction_position, definition.move_speed * 0.6, delta)
		return
	if not _target_valid():
		velocity = velocity.move_toward(Vector3.ZERO, definition.acceleration * delta)
		move_and_slide()
		_set_state(State.IDLE)
		return
	var distance := global_position.distance_to(target.global_position)
	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, definition.acceleration * delta)
			move_and_slide()
			if distance <= definition.detection_range:
				_set_state(State.ALERT)
		State.ALERT:
			_face_target(delta)
			if _state_time >= minf(0.45, definition.telegraph_seconds):
				_set_state(State.CHASE)
		State.CHASE, State.HURT:
			if state == State.HURT and _state_time < 0.12:
				velocity = velocity.move_toward(Vector3.ZERO, definition.acceleration * delta)
				move_and_slide()
			elif distance <= definition.attack_range and _cooldown <= 0.0:
				_begin_attack()
			else:
				_move_for_combat(distance, delta)
		State.ATTACK:
			_face_target(delta)
			velocity = velocity.move_toward(Vector3.ZERO, definition.acceleration * delta)
			move_and_slide()
			if not _attack_committed and _state_time >= definition.telegraph_seconds:
				_attack_committed = true
				_perform_attack()
				attack_fired.emit(attack_kind)
			if _state_time >= definition.telegraph_seconds + 0.2:
				_cooldown = definition.attack_cooldown
				_set_state(State.CHASE)

func set_target(value: Node3D) -> void:
	target = value
	if _target_valid() and state == State.IDLE:
		_set_state(State.ALERT)

func apply_damage(amount: float, source: Node = null, hit_position := Vector3.ZERO) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var applied := minf(health, amount * _damage_multiplier(hit_position))
	health -= applied
	var actor := _actor_from(source)
	if actor != null:
		set_target(actor)
	damaged.emit(applied, source, hit_position)
	_on_damaged(applied, hit_position)
	if health <= 0.0:
		_die(source)
	else:
		_set_state(State.HURT)
	return applied

func damage(amount: float) -> float:
	return apply_damage(amount)

func apply_knockback(force: Vector3) -> void:
	if not is_dead:
		velocity += force

func stun(duration := 0.7) -> void:
	if is_dead:
		return
	_set_state(State.STUNNED)
	_state_time = minf(_state_time, -maxf(0.0, duration - 0.7))

func distract(position: Vector3, duration: float) -> void:
	if is_dead:
		return
	_distraction_position = position
	_distraction_time = maxf(_distraction_time, duration)
	_set_state(State.ALERT)

func get_auto_aim_position() -> Vector3:
	var marker := get_node_or_null("AutoAimTarget") as Node3D
	return marker.global_position if marker != null else global_position + Vector3.UP * target_height

func health_fraction() -> float:
	return 0.0 if definition == null else health / maxf(definition.max_health, 0.001)

func _move_for_combat(_distance: float, delta: float) -> void:
	_move_toward(target.global_position, definition.move_speed, delta)

func _move_toward(destination: Vector3, speed: float, delta: float) -> void:
	var flat_direction := global_position.direction_to(Vector3(destination.x, global_position.y, destination.z))
	var desired := flat_direction * speed
	velocity.x = move_toward(velocity.x, desired.x, definition.acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, definition.acceleration * delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	if flat_direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-flat_direction.x, -flat_direction.z), minf(1.0, delta * 9.0))
	move_and_slide()

func _face_target(delta: float) -> void:
	if not _target_valid():
		return
	var direction := global_position.direction_to(target.global_position)
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 12.0))

func _begin_attack() -> void:
	_attack_committed = false
	_set_state(State.ATTACK)
	telegraph_started.emit(attack_kind, definition.telegraph_seconds)
	_set_telegraph_visual(true)

func _perform_attack() -> void:
	if not _target_valid():
		return
	if global_position.distance_to(target.global_position) <= definition.attack_range * 1.2 and target.has_method("apply_damage"):
		target.apply_damage(definition.attack_damage, self, target.global_position)

func _spawn_projectile(scene: PackedScene, speed: float, splash_radius := 0.0) -> Node3D:
	if not _target_valid() or scene == null:
		return null
	var projectile := scene.instantiate() as Node3D
	get_tree().current_scene.add_child(projectile)
	var origin := get_auto_aim_position()
	var direction := origin.direction_to(target.global_position + Vector3.UP * 0.8)
	projectile.global_position = origin
	if projectile.has_method("launch"):
		projectile.launch(direction, self, definition.attack_damage, speed, splash_radius)
	return projectile

func _damage_multiplier(_hit_position: Vector3) -> float:
	return 1.0

func _on_damaged(_amount: float, _hit_position: Vector3) -> void:
	pass

func _set_telegraph_visual(active: bool) -> void:
	var indicator := get_node_or_null("Telegraph") as GeometryInstance3D
	if indicator != null:
		indicator.visible = active
	if not active:
		return
	get_tree().create_timer(definition.telegraph_seconds).timeout.connect(func() -> void:
		if is_instance_valid(indicator):
			indicator.visible = false
	)

func _set_state(next: State) -> void:
	if state == next:
		return
	var previous := state
	state = next
	_state_time = 0.0
	state_changed.emit(previous, state)

func _die(source: Node) -> void:
	is_dead = true
	remove_from_group(&"auto_aim_targets")
	_set_state(State.DEAD)
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	died.emit(self, source)
	if definition.drop_id != &"":
		drop_requested.emit(definition.drop_id, global_position)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.rotation.z = deg_to_rad(82.0)
	await get_tree().create_timer(death_linger_seconds).timeout
	queue_free()

func _target_valid() -> bool:
	return is_instance_valid(target) and target is Node3D and target.is_inside_tree() and target.get("is_dead") != true

func _acquire_target() -> void:
	if _target_valid():
		return
	var candidate := get_tree().get_first_node_in_group(&"player") as Node3D
	if candidate == null:
		for node in get_tree().get_nodes_in_group(&"damageable_player"):
			if node is Node3D:
				candidate = node
				break
	if candidate == null:
		var matches := get_tree().root.find_children("*", "CobiePlayer", true, false)
		if not matches.is_empty():
			candidate = matches[0] as Node3D
	target = candidate

func _actor_from(source: Node) -> Node3D:
	var current := source
	while current != null:
		if current is CharacterBody3D:
			return current
		current = current.get_parent()
	return source as Node3D

