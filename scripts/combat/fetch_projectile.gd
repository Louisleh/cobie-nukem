class_name FetchProjectile
extends CharacterBody3D

signal exploded(position: Vector3)
signal recalled(projectile: FetchProjectile)
signal shot_resolved(kind: StringName, position: Vector3)

@export var speed := 18.0
@export var fuse_seconds := 2.5
@export var damage := 55.0
@export var blast_radius := 4.0
@export var collision_mask_for_blast := 4
@export var recall_damage := 32.0
@export var max_bounces := 8
@export_range(1.0, 3.0, 0.05) var recall_speed_multiplier := 1.0
@export_range(1.0, 3.0, 0.05) var recall_stagger_multiplier := 1.0

var instigator: Node3D
var direction := Vector3.FORWARD
var recalling := false
var bounces := 0
var _age := 0.0
var _damaged_on_recall: Dictionary = {}
var _damaged_on_bounce: Dictionary = {}
var _is_active := false
var _shot_token := 0

@onready var _ball := get_node_or_null("Ball") as MeshInstance3D
@onready var _trail := get_node_or_null("GoldenTrail") as GPUParticles3D
@onready var _glow := get_node_or_null("Glow") as OmniLight3D
@onready var _collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D

var _base_collision_layer := 0
var _base_collision_mask := 0
var _base_max_bounces := 0
var _base_process_mode := Node.PROCESS_MODE_INHERIT
var _base_speed := 0.0
var _base_fuse_seconds := 0.0
var _base_damage := 0.0
var _base_blast_radius := 0.0
var _base_collision_mask_for_blast := 0
var _base_recall_damage := 0.0
var _base_recall_speed_multiplier := 1.0
var _base_recall_stagger_multiplier := 1.0
var _base_ball_material: Material
var _base_glow_color := Color.WHITE
var _trail_enabled := false
var _golden_ball_material := StandardMaterial3D.new()


func _ready() -> void:
	_base_collision_layer = collision_layer
	_base_collision_mask = collision_mask
	_base_max_bounces = max_bounces
	_base_process_mode = process_mode
	_base_speed = speed
	_base_fuse_seconds = fuse_seconds
	_base_damage = damage
	_base_blast_radius = blast_radius
	_base_collision_mask_for_blast = collision_mask_for_blast
	_base_recall_damage = recall_damage
	_base_recall_speed_multiplier = recall_speed_multiplier
	_base_recall_stagger_multiplier = recall_stagger_multiplier
	_base_ball_material = _ball.material_override if _ball != null else null
	_base_glow_color = _glow.light_color if _glow != null else Color.WHITE
	_golden_ball_material.albedo_color = Color("ffd34d")
	_golden_ball_material.emission_enabled = true
	_golden_ball_material.emission = Color("ffb21f")
	_golden_ball_material.emission_energy_multiplier = 3.2
	_golden_ball_material.roughness = 0.28


func begin_shot(shot_token: int, owner_node: Node3D, bounce_bonus: int = 0) -> void:
	_shot_token = shot_token
	_is_active = true
	recalling = false
	_age = 0.0
	instigator = owner_node
	bounces = 0
	direction = Vector3.FORWARD
	velocity = Vector3.ZERO
	_damaged_on_recall.clear()
	_damaged_on_bounce.clear()
	max_bounces = _base_max_bounces + maxi(0, bounce_bonus)


func can_recall(shot_token: int) -> bool:
	return _is_active and shot_token > 0 and shot_token == _shot_token


func set_golden_trail(enabled: bool) -> void:
	_trail_enabled = enabled
	if _trail != null:
		_trail.emitting = enabled
	if _ball != null:
		_ball.material_override = _golden_ball_material if enabled else _base_ball_material
	if _glow != null:
		_glow.light_color = Color("ffd34d") if enabled else _base_glow_color


func launch(origin: Vector3, launch_direction: Vector3, owner_node: Node3D) -> void:
	global_position = origin
	reset_physics_interpolation()
	direction = launch_direction.normalized()
	instigator = owner_node
	velocity = direction * speed
	if not _is_active:
		begin_shot(_shot_token + 1, owner_node)


func activate_from_pool() -> void:
	_is_active = false
	_shot_token = 0
	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", false)
	process_mode = _base_process_mode
	collision_layer = _base_collision_layer
	collision_mask = _base_collision_mask
	visible = true
	global_transform = Transform3D.IDENTITY
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	direction = Vector3.FORWARD
	recalling = false
	bounces = 0
	_age = 0.0
	speed = _base_speed
	fuse_seconds = _base_fuse_seconds
	damage = _base_damage
	blast_radius = _base_blast_radius
	collision_mask_for_blast = _base_collision_mask_for_blast
	recall_damage = _base_recall_damage
	recall_speed_multiplier = _base_recall_speed_multiplier
	recall_stagger_multiplier = _base_recall_stagger_multiplier
	max_bounces = _base_max_bounces
	_damaged_on_recall.clear()
	_damaged_on_bounce.clear()
	instigator = null
	set_golden_trail(false)


func deactivate_for_pool() -> void:
	_is_active = false
	_shot_token = 0
	recalling = false
	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", true)
	process_mode = Node.PROCESS_MODE_DISABLED
	collision_layer = 0
	collision_mask = 0
	visible = false
	global_transform = Transform3D.IDENTITY
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	direction = Vector3.FORWARD
	_age = 0.0
	speed = _base_speed
	fuse_seconds = _base_fuse_seconds
	damage = _base_damage
	blast_radius = _base_blast_radius
	collision_mask_for_blast = _base_collision_mask_for_blast
	recall_damage = _base_recall_damage
	recall_speed_multiplier = _base_recall_speed_multiplier
	recall_stagger_multiplier = _base_recall_stagger_multiplier
	max_bounces = _base_max_bounces
	_damaged_on_recall.clear()
	_damaged_on_bounce.clear()
	instigator = null
	set_golden_trail(false)


func recall() -> void:
	if not _is_active or recalling:
		return
	recalling = true
	_age = 0.0
	set_collision_mask_value(1, false)


func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	_age += delta
	if recalling and is_instance_valid(instigator):
		direction = global_position.direction_to(instigator.global_position + Vector3.UP * 1.0)
		velocity = direction * speed * 1.65 * recall_speed_multiplier
	elif not is_on_floor():
		velocity.y -= 9.8 * delta * 0.35
	var collision := move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)
	if recalling:
		_damage_recall_overlaps()
		if is_instance_valid(instigator) and global_position.distance_to(instigator.global_position) < 1.15:
			recalled.emit(self)
			_return_to_pool()
	elif _age >= fuse_seconds:
		explode()


func _handle_collision(collision: KinematicCollision3D) -> void:
	var receiver := _find_damage_receiver(collision.get_collider())
	if receiver != null and receiver != instigator:
		if recalling:
			if not _damaged_on_recall.has(receiver):
				_damaged_on_recall[receiver] = true
				_damage_receiver(receiver, recall_damage)
				_apply_recall_stagger(receiver)
				shot_resolved.emit(&"enemy", global_position)
			global_position += direction * 0.24
		else:
			_bounce_off_enemy(receiver, collision.get_normal())
		return
	_bounce(collision.get_normal())


func _bounce_off_enemy(receiver: Node, normal: Vector3) -> void:
	if not _is_active:
		return
	if not _damaged_on_bounce.has(receiver):
		_damaged_on_bounce[receiver] = true
		_damage_receiver(receiver, damage)
		shot_resolved.emit(&"enemy", global_position)
	_bounce(normal, 0.9)


func _bounce(normal: Vector3, retention := 0.82) -> void:
	bounces += 1
	velocity = velocity.bounce(normal) * retention
	velocity.y = maxf(velocity.y, 2.4)
	direction = velocity.normalized()
	if bounces >= max_bounces and not recalling:
		explode()


func explode() -> void:
	if is_queued_for_deletion():
		return
	var shape := SphereShape3D.new()
	shape.radius = blast_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = collision_mask_for_blast
	query.exclude = [get_rid()]
	var hit_enemy := false
	for result in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var receiver := _find_damage_receiver(result.get("collider"))
		if receiver == null or receiver == instigator:
			continue
		hit_enemy = true
		var receiver_position: Vector3 = receiver.global_position if receiver is Node3D else global_position
		var falloff := 1.0 - clampf(global_position.distance_to(receiver_position) / blast_radius, 0.0, 0.8)
		_damage_receiver(receiver, damage * falloff)
	shot_resolved.emit(&"enemy" if hit_enemy else (&"world" if bounces > 0 else &"miss"), global_position)
	exploded.emit(global_position)
	_return_to_pool()


func _damage_recall_overlaps() -> void:
	if not _is_active:
		return
	for index in get_slide_collision_count():
		var receiver := _find_damage_receiver(get_slide_collision(index).get_collider())
		if receiver != null and receiver != instigator and not _damaged_on_recall.has(receiver):
			_damaged_on_recall[receiver] = true
			_damage_receiver(receiver, recall_damage)
			_apply_recall_stagger(receiver)
			shot_resolved.emit(&"enemy", global_position)


func _damage_receiver(receiver: Node, amount: float) -> void:
	if receiver.has_method("apply_damage"):
		receiver.apply_damage(amount, instigator, global_position)
	elif receiver.has_method("damage"):
		receiver.damage(amount)


func _apply_recall_stagger(receiver: Node) -> void:
	if recall_stagger_multiplier <= 1.0:
		return
	if receiver.has_method("apply_recall_stagger"):
		receiver.apply_recall_stagger(recall_stagger_multiplier)
	elif receiver.has_method("stun"):
		receiver.stun(0.7 * recall_stagger_multiplier)


func _find_damage_receiver(value: Variant) -> Node:
	var node := value as Node
	while node != null:
		if node.has_method("apply_damage") or node.has_method("damage"):
			return node
		node = node.get_parent()
	return null


func _return_to_pool() -> void:
	if not _is_active:
		if _shot_token == 0:
			return
	deactivate_for_pool()
	if bool(get_meta(&"projectile_pool", false)):
		var pool := get_node_or_null("/root/ProjectilePool")
		if pool != null:
			pool.release_projectile(self)
			return
	queue_free()
