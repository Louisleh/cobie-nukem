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

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return
	var receiver := _damage_receiver(collision.get_collider())
	if receiver != null and receiver != instigator:
		receiver.apply_damage(damage, instigator, collision.get_position())
	if splash_radius > 0.0:
		_apply_splash(collision.get_position())
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
			receiver.apply_damage(damage * 0.55, instigator, center)

func _damage_receiver(value: Variant) -> Node:
	var node := value as Node
	while node != null:
		if node.has_method("apply_damage"):
			return node
		node = node.get_parent()
	return null

