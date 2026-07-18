class_name LethalWaterVolume
extends Area3D

signal victim_killed(victim: Node)

@export var volume_size := Vector3(20.0, 2.0, 20.0)
@export_flags_3d_physics var player_collision_mask := 2

var _victims: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = player_collision_mask
	monitorable = false
	_ensure_collision_shape()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	# Retry while a protected player remains submerged. Damage still travels through
	# CobiePlayer/HealthArmor, preserving the normal death screen and checkpoint path.
	for instance_id in _victims.keys():
		var victim := _victims.get(instance_id) as Node
		if victim == null or not is_instance_valid(victim):
			_victims.erase(instance_id)
			continue
		_apply_lethal_damage(victim)


func _on_body_entered(body: Node) -> void:
	if body == null or not (body.is_in_group(&"player") or body.is_in_group(&"damageable_player")):
		return
	_victims[body.get_instance_id()] = body
	_apply_lethal_damage(body)


func _on_body_exited(body: Node) -> void:
	if body != null:
		_victims.erase(body.get_instance_id())


func _apply_lethal_damage(victim: Node) -> void:
	if not victim.has_method("apply_damage"):
		return
	var was_dead := bool(victim.get("is_dead")) if "is_dead" in victim else false
	victim.call("apply_damage", 1000000.0, self, global_position)
	var is_now_dead := bool(victim.get("is_dead")) if "is_dead" in victim else true
	if not was_dead and is_now_dead:
		victim_killed.emit(victim)


func _ensure_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	if not (collision_shape.shape is BoxShape3D):
		collision_shape.shape = BoxShape3D.new()
	(collision_shape.shape as BoxShape3D).size = Vector3(
		maxf(0.1, volume_size.x),
		maxf(0.1, volume_size.y),
		maxf(0.1, volume_size.z)
	)
