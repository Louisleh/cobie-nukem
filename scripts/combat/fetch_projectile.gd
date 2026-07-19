class_name FetchProjectile
extends CharacterBody3D

signal exploded(position: Vector3)
signal recalled(projectile: FetchProjectile)
signal shot_resolved(kind: StringName, position: Vector3)

@export var speed := 18.0
@export var fuse_seconds := 2.5
@export var damage := 55.0
@export var blast_radius := 4.0
@export var recall_damage := 32.0
@export var max_bounces := 8
@export var collision_mask_for_blast := 4
@export_range(1.0, 3.0, 0.05) var recall_speed_multiplier := 1.0
@export_range(1.0, 3.0, 0.05) var recall_stagger_multiplier := 1.0

var instigator: Node3D
var direction := Vector3.FORWARD
var recalling := false
var bounces := 0
var _age := 0.0
var _damaged_on_recall: Dictionary = {}
var _damaged_on_bounce: Dictionary = {}


func set_golden_trail(enabled: bool) -> void:
	var trail := get_node_or_null("GoldenTrail") as GPUParticles3D
	if trail != null:
		trail.emitting = enabled
	var ball := get_node_or_null("Ball") as MeshInstance3D
	if ball != null and enabled:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("ffd34d")
		material.emission_enabled = true
		material.emission = Color("ffb21f")
		material.emission_energy_multiplier = 3.2
		material.roughness = 0.28
		ball.material_override = material
	var glow := get_node_or_null("Glow") as OmniLight3D
	if glow != null and enabled:
		glow.light_color = Color("ffd34d")

func launch(origin: Vector3, launch_direction: Vector3, owner_node: Node3D) -> void:
	global_position = origin
	reset_physics_interpolation()
	direction = launch_direction.normalized()
	instigator = owner_node
	velocity = direction * speed

func _physics_process(delta: float) -> void:
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
			queue_free()
	elif _age >= fuse_seconds:
		explode()

func recall() -> void:
	recalling = true
	_age = 0.0
	set_collision_mask_value(1, false)

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
	queue_free()

func _damage_recall_overlaps() -> void:
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
