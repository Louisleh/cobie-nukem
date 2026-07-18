class_name EnemyProjectile
extends CharacterBody3D

@export var lifetime := 5.0

var instigator: Node
var damage := 10.0
var splash_radius := 0.0
var _age := 0.0

func launch(direction: Vector3, source: Node, amount: float, speed: float, radius := 0.0) -> void:
	velocity = direction.normalized() * speed
	instigator = source
	damage = amount
	splash_radius = radius


func activate_from_pool() -> void:
	_age = 0.0
	instigator = null
	damage = 10.0
	splash_radius = 0.0
	velocity = Vector3.ZERO
	visible = true
	collision_layer = 16
	collision_mask = 3
	var shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape != null:
		shape.set_deferred("disabled", false)
	process_mode = Node.PROCESS_MODE_INHERIT


func deactivate_for_pool() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector3.ZERO
	visible = false
	collision_layer = 0
	collision_mask = 0
	var shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape != null:
		shape.set_deferred("disabled", true)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		_finish()
		return
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return
	var receiver := _damage_receiver(collision.get_collider())
	if receiver != null and receiver != instigator:
		receiver.apply_damage(damage, instigator if is_instance_valid(instigator) else null, collision.get_position())
	if splash_radius > 0.0:
		_apply_splash(collision.get_position())
	_finish()


func _finish() -> void:
	if bool(get_meta(&"projectile_pool", false)):
		var pool := get_node_or_null("/root/ProjectilePool")
		if pool != null:
			process_mode = Node.PROCESS_MODE_DISABLED
			pool.release_projectile.call_deferred(self)
			return
	queue_free()

func _apply_splash(center: Vector3) -> void:
	var shape := SphereShape3D.new()
	shape.radius = splash_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = collision_mask
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var receiver := _damage_receiver(hit.get("collider"))
		if receiver != null and receiver != instigator:
			receiver.apply_damage(damage * 0.55, instigator if is_instance_valid(instigator) else null, center)

func _damage_receiver(value: Variant) -> Node:
	var node := value as Node
	while node != null:
		if node.has_method("apply_damage"):
			return node
		node = node.get_parent()
	return null
