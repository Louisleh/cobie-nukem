class_name SquirrelTrooper
extends EnemyAgent

const ACORN := preload("res://scenes/enemies/explosive_acorn.tscn")
var _strafe_sign := 1.0

func _ready() -> void:
	super._ready()
	attack_kind = &"explosive_acorn"
	_strafe_sign = -1.0 if randi() % 2 == 0 else 1.0

func _move_for_combat(distance: float, delta: float) -> void:
	if not _target_valid():
		return
	var toward := global_position.direction_to(target.global_position)
	var lateral := Vector3(-toward.z, 0.0, toward.x) * _strafe_sign
	if randf() < delta * 0.8:
		_strafe_sign *= -1.0
	var radial := toward * (1.0 if distance > definition.attack_range * 0.8 else -0.35)
	_move_toward(global_position + (lateral + radial).normalized() * 4.0, definition.move_speed, delta)

func _perform_attack() -> void:
	_spawn_projectile(ACORN, 8.0, 2.4)

