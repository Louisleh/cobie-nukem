class_name SkiPatrolRanger
extends EnemyAgent

const FLARE := preload("res://scenes/enemies/enemy_bolt.tscn")
var _strafe_sign := 1.0


func _ready() -> void:
	super._ready()
	attack_kind = &"patrol_flare"
	_strafe_sign = -1.0 if randi() % 2 == 0 else 1.0


func _move_for_combat(distance: float, delta: float) -> void:
	if not _target_valid(): return
	var toward := global_position.direction_to(target.global_position)
	var lateral := Vector3(-toward.z, 0.0, toward.x) * _strafe_sign
	if randf() < delta * 0.6: _strafe_sign *= -1.0
	var radial := toward * (1.0 if distance > definition.preferred_distance else -0.45)
	_move_toward(global_position + (lateral + radial).normalized() * 5.0, definition.move_speed, delta)


func _perform_attack() -> void:
	_spawn_projectile(FLARE, 10.5, 1.6)
