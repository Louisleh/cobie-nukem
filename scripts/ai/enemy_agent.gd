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
@export var death_linger_seconds := 0.62
@export var attack_kind: StringName = &"attack"
@export var uses_gravity := true
@export var ground_height := 0.0

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
var _health_bar: Node3D
var _health_bar_fill_mesh: QuadMesh
var _health_bar_fill_material: StandardMaterial3D
var _health_label: Label3D
var _health_bar_width := 1.4
var _damage_scale := 1.0
var _speed_scale := 1.0
var _max_health := 1.0
var _aggression_scale := 1.0
var _stagger_accumulator := 0.0
var _visual_base_position := Vector3.ZERO
var _presentation_tween: Tween

func _ready() -> void:
	floor_snap_length = 0.45
	add_to_group(&"enemies")
	add_to_group(&"auto_aim_targets")
	if definition == null:
		push_error("Enemy requires an EnemyDefinition: %s" % name)
		return
	var game_state := get_node_or_null("/root/GameState")
	var profile: DifficultyProfile = game_state.get_difficulty_profile() if game_state != null and game_state.has_method("get_difficulty_profile") else null
	apply_difficulty(profile)
	auto_aim_threat = definition.threat_weight
	target = initial_target
	_build_health_bar()
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null: _visual_base_position = visual.position

func _physics_process(delta: float) -> void:
	if definition == null or is_dead:
		return
	_stabilize_ground_height()
	_update_locomotion_presentation()
	_update_health_bar_presentation()
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
			if distance <= definition.detection_range * _aggression_scale:
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
				var pressure := get_node_or_null("/root/CombatPressure")
				if pressure != null: pressure.release_attack(self)
				_cooldown = definition.attack_cooldown / maxf(_aggression_scale, 0.1)
				_set_state(State.CHASE)

func set_target(value: Node3D) -> void:
	target = value
	if _target_valid() and state == State.IDLE:
		_set_state(State.ALERT)
		get_tree().call_group(&"enemies", &"receive_alert", value, global_position, 12.0)


func receive_alert(value: Node3D, source_position: Vector3, radius: float) -> void:
	if is_dead or not is_instance_valid(value) or global_position.distance_to(source_position) > radius: return
	target = value
	if state == State.IDLE: _set_state(State.ALERT)


func apply_difficulty(profile: DifficultyProfile) -> void:
	_damage_scale = profile.enemy_damage_multiplier if profile != null else 1.0
	_speed_scale = profile.enemy_speed_multiplier if profile != null else 1.0
	_aggression_scale = profile.enemy_aggression_multiplier if profile != null else 1.0
	_max_health = profile.scaled_enemy_health(definition.max_health) if profile != null else definition.max_health
	health = _max_health

func apply_damage(amount: float, source: Node = null, hit_position := Vector3.ZERO) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var applied := minf(health, amount * _damage_multiplier(hit_position))
	health -= applied
	_update_health_bar()
	var actor := _actor_from(source)
	if actor != null:
		set_target(actor)
	damaged.emit(applied, source, hit_position)
	_on_damaged(applied, hit_position)
	_apply_reaction(applied)
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
	return 0.0 if definition == null else health / maxf(_max_health, 0.001)


func _build_health_bar() -> void:
	_health_bar_width = 2.4 if definition.max_health >= 1000.0 else 1.4
	_health_bar = Node3D.new()
	_health_bar.name = "EnemyHealthBar"
	_health_bar.position.y = maxf(target_height + 0.65, 1.15)
	add_child(_health_bar)

	var background := MeshInstance3D.new()
	background.name = "Background"
	var background_mesh := QuadMesh.new()
	background_mesh.size = Vector2(_health_bar_width + 0.12, 0.18)
	background.mesh = background_mesh
	background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	background.material_override = _health_bar_material(Color("101416"))
	_health_bar.add_child(background)

	var fill := MeshInstance3D.new()
	fill.name = "Fill"
	fill.position.z = 0.008
	_health_bar_fill_mesh = QuadMesh.new()
	_health_bar_fill_mesh.size = Vector2(_health_bar_width, 0.10)
	fill.mesh = _health_bar_fill_mesh
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_health_bar_fill_material = _health_bar_material(Color("65d36e"))
	fill.material_override = _health_bar_fill_material
	_health_bar.add_child(fill)

	_health_label = Label3D.new()
	_health_label.name = "HealthPoints"
	_health_label.position.y = 0.17
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_label.font_size = 32
	_health_label.pixel_size = 0.0022
	_health_label.outline_size = 4
	_health_label.modulate = Color("f4f1de")
	_health_label.no_depth_test = false
	_health_label.fixed_size = true
	_health_bar.add_child(_health_label)
	_update_health_bar()


func _health_bar_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	return material


func _update_health_bar_presentation() -> void:
	if _health_bar == null:
		return
	var view_camera := get_viewport().get_camera_3d()
	if view_camera == null:
		return
	var distance := global_position.distance_to(view_camera.global_position)
	_health_bar.visible = distance >= 2.6 and distance <= 24.0
	_health_bar.scale = Vector3.ONE * clampf(distance * 0.016, 0.08, 0.34)
	if _health_label != null:
		_health_label.visible = distance <= 16.0


func _update_health_bar() -> void:
	if _health_bar_fill_mesh == null or _health_bar_fill_material == null:
		return
	var fraction := clampf(health_fraction(), 0.0, 1.0)
	_health_bar_fill_mesh.size.x = maxf(0.001, _health_bar_width * fraction)
	if _health_label != null:
		var points := "%d / %d HP" % [ceili(maxf(health, 0.0)), ceili(_max_health)]
		_health_label.text = "%s // %s" % [points, definition.display_name] if definition.max_health >= 200.0 else points
	if fraction > 0.55:
		_health_bar_fill_material.albedo_color = Color("65d36e")
	elif fraction > 0.25:
		_health_bar_fill_material.albedo_color = Color("f0b429")
	else:
		_health_bar_fill_material.albedo_color = Color("ef5b4c")
	_health_bar_fill_material.emission = _health_bar_fill_material.albedo_color

func _move_for_combat(distance: float, delta: float) -> void:
	if definition.retreat_distance > 0.0 and distance < definition.retreat_distance:
		var retreat := global_position + target.global_position.direction_to(global_position) * 4.0
		_move_toward(retreat, definition.move_speed, delta)
	elif definition.preferred_distance > 0.0 and distance <= definition.preferred_distance:
		var tangent := global_position.direction_to(target.global_position).cross(Vector3.UP).normalized()
		_move_toward(global_position + tangent * 3.0, definition.move_speed * 0.72, delta)
	else:
		_move_toward(target.global_position, definition.move_speed, delta)

func _move_toward(destination: Vector3, speed: float, delta: float) -> void:
	var flat_direction := global_position.direction_to(Vector3(destination.x, global_position.y, destination.z))
	var desired := flat_direction * speed * _speed_scale
	velocity.x = move_toward(velocity.x, desired.x, definition.acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, definition.acceleration * delta)
	if uses_gravity and not is_on_floor():
		velocity += get_gravity() * delta
	elif not uses_gravity:
		velocity.y = 0.0
	if flat_direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-flat_direction.x, -flat_direction.z), minf(1.0, delta * 9.0))
	move_and_slide()
	_stabilize_ground_height()

func _stabilize_ground_height() -> void:
	if not uses_gravity or global_position.y >= ground_height:
		return
	global_position.y = ground_height
	velocity.y = 0.0

func _face_target(delta: float) -> void:
	if not _target_valid():
		return
	var direction := global_position.direction_to(target.global_position)
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 12.0))

func _begin_attack() -> void:
	var pressure := get_node_or_null("/root/CombatPressure")
	var priority := 10 if definition.archetype == EnemyDefinition.Archetype.BOSS else definition.threat_value
	if pressure != null and not pressure.request_attack(self, priority):
		_cooldown = 0.15
		return
	_attack_committed = false
	_set_state(State.ATTACK)
	telegraph_started.emit(attack_kind, definition.telegraph_seconds)
	_set_telegraph_visual(true)

func _perform_attack() -> void:
	if not _target_valid():
		return
	if global_position.distance_to(target.global_position) <= definition.attack_range * 1.2 and target.has_method("apply_damage"):
		target.apply_damage(definition.attack_damage * _damage_scale, self, target.global_position)

func _spawn_projectile(scene: PackedScene, speed: float, splash_radius := 0.0) -> Node3D:
	if not _target_valid() or scene == null:
		return null
	var pool := get_node_or_null("/root/ProjectilePool")
	var projectile := pool.acquire(scene) as Node3D if pool != null else scene.instantiate() as Node3D
	if projectile.get_parent() == null:
		var projectile_parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
		projectile_parent.add_child(projectile)
	var origin := get_auto_aim_position()
	var direction := origin.direction_to(target.global_position + Vector3.UP * 0.8)
	projectile.global_position = origin
	if projectile.has_method("launch"):
		projectile.launch(direction, self, definition.attack_damage * _damage_scale, speed, splash_radius)
	return projectile

func _damage_multiplier(hit_position: Vector3) -> float:
	if definition.weak_point_multiplier <= 1.0 or hit_position == Vector3.ZERO: return 1.0
	return definition.weak_point_multiplier if hit_position.y >= global_position.y + target_height * 0.82 else 1.0

func _on_damaged(_amount: float, _hit_position: Vector3) -> void:
	pass

func _set_telegraph_visual(active: bool) -> void:
	var indicator := get_node_or_null("Telegraph") as GeometryInstance3D
	if indicator != null:
		indicator.visible = active
	if not active:
		return
	var timer := indicator.get_node_or_null("TelegraphTimer") as Timer
	if timer == null:
		timer = Timer.new()
		timer.name = "TelegraphTimer"
		timer.one_shot = true
		timer.timeout.connect(indicator.hide)
		indicator.add_child(timer)
	timer.wait_time = maxf(definition.telegraph_seconds, 0.001)
	timer.start()

func _set_state(next: State) -> void:
	if state == next:
		return
	var previous := state
	if previous == State.ATTACK and next != State.ATTACK:
		var pressure := get_node_or_null("/root/CombatPressure")
		if pressure != null: pressure.release_attack(self)
	state = next
	_state_time = 0.0
	state_changed.emit(previous, state)
	_animate_state(previous, next)


func _update_locomotion_presentation() -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null or state == State.DEAD or _presentation_tween != null and _presentation_tween.is_running(): return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.25
	visual.position.y = _visual_base_position.y + (sin(Time.get_ticks_msec() * 0.012) * 0.035 if moving else 0.0)


func _animate_state(_previous: State, next: State) -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null or next == State.DEAD: return
	if _presentation_tween != null: _presentation_tween.kill()
	visual.scale = Vector3.ONE
	visual.position = _visual_base_position
	_presentation_tween = visual.create_tween()
	match next:
		State.ALERT:
			_presentation_tween.tween_property(visual, "scale", Vector3(1.1, 1.1, 1.1), 0.08)
			_presentation_tween.tween_property(visual, "scale", Vector3.ONE, 0.12)
		State.ATTACK:
			_presentation_tween.tween_property(visual, "position", _visual_base_position + Vector3(0.0, 0.08, -0.12), maxf(0.08, definition.telegraph_seconds * 0.75))
			_presentation_tween.tween_property(visual, "position", _visual_base_position, 0.12)
		State.HURT, State.STUNNED:
			_presentation_tween.tween_property(visual, "scale", Vector3(1.12, 0.86, 1.0), 0.05)
			_presentation_tween.tween_property(visual, "scale", Vector3.ONE, 0.14)
		_:
			_presentation_tween.tween_interval(0.01)

func _die(source: Node) -> void:
	is_dead = true
	velocity = Vector3.ZERO
	set_physics_process(false)
	if _health_bar != null:
		_health_bar.visible = false
	remove_from_group(&"auto_aim_targets")
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null: pressure.release_attack(self)
	_set_state(State.DEAD)
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	died.emit(self, source)
	if definition.drop_id != &"":
		drop_requested.emit(definition.drop_id, global_position)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		_play_death_animation(visual)
	_spawn_death_pop()
	var cleanup := Timer.new()
	cleanup.name = "DeathCleanupTimer"
	cleanup.one_shot = true
	cleanup.wait_time = maxf(death_linger_seconds, 0.001)
	cleanup.timeout.connect(queue_free)
	add_child(cleanup)
	cleanup.start()


func _apply_reaction(amount: float) -> void:
	var profile := definition.reaction_profile
	if profile == null: return
	_stagger_accumulator += amount * (1.0 - profile.stagger_resistance)
	if _stagger_accumulator >= profile.stagger_threshold:
		_stagger_accumulator = 0.0
		stun(0.7)


func _play_death_animation(visual: Node3D) -> void:
	# Billboard enemies used to rotate sideways around their center, which looked
	# like they were falling through the floor. Keep the root grounded and animate
	# only the artwork through a quick recoil, squash, upward pop, and shrink-out.
	visual.rotation = Vector3.ZERO
	var start_position := visual.position
	var position_tween := visual.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	position_tween.tween_property(visual, "position", start_position + Vector3.UP * 0.42, 0.42)
	var scale_tween := visual.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(visual, "scale", Vector3(1.14, 0.82, 1.14), 0.08)
	scale_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	scale_tween.tween_property(visual, "scale", Vector3(0.22, 1.18, 0.22), 0.18)
	scale_tween.tween_property(visual, "scale", Vector3.ZERO, 0.18)

func _spawn_death_pop() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return
	var pop := Node3D.new(); pop.name = "EnemyDeathPop"; parent.add_child(pop); pop.global_position = get_auto_aim_position()
	var quality := get_node_or_null("/root/QualityManager")
	if quality != null: quality.claim_temporary_effect(pop)
	for index in 10:
		var fragment := MeshInstance3D.new(); fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mesh := BoxMesh.new(); mesh.size = Vector3.ONE * randf_range(0.05, 0.11); fragment.mesh = mesh
		var material := StandardMaterial3D.new(); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; material.albedo_color = Color("ffb22e") if index % 2 == 0 else Color("e94b35"); material.emission_enabled = true; material.emission = material.albedo_color; material.emission_energy_multiplier = 3.0; fragment.material_override = material
		pop.add_child(fragment)
		var direction := Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.3), randf_range(-1.0, 1.0)).normalized()
		var tween := fragment.create_tween().set_parallel(); tween.tween_property(fragment, "position", direction * randf_range(0.45, 0.95), 0.38); tween.tween_property(fragment, "scale", Vector3.ZERO, 0.38)
	var cleanup := Timer.new()
	cleanup.name = "CleanupTimer"
	cleanup.one_shot = true
	cleanup.wait_time = 0.42
	cleanup.timeout.connect(pop.queue_free)
	pop.add_child(cleanup)
	cleanup.start()

func _target_valid() -> bool:
	return is_instance_valid(target) and target is Node3D and target.is_inside_tree() and target.get("is_dead") != true

func _acquire_target() -> void:
	if _target_valid():
		return
	var registry := get_node_or_null("/root/WorldRegistry")
	var candidate: Node3D = registry.primary_player() if registry != null else null
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
