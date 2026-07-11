class_name LeashEnforcementDrone
extends EnemyAgent

const BOLT := preload("res://scenes/enemies/enemy_bolt.tscn")
var _hover_time := 0.0
var _base_height := 0.0

func _ready() -> void:
	super._ready()
	attack_kind = &"compliance_bolt"
	_base_height = global_position.y

func _physics_process(delta: float) -> void:
	_hover_time += delta
	super._physics_process(delta)
	if not is_dead and state != State.HURT:
		global_position.y = _base_height + sin(_hover_time * 2.2) * 0.18

func _move_for_combat(distance: float, delta: float) -> void:
	if distance < definition.attack_range * 0.62:
		var away := target.global_position.direction_to(global_position)
		_move_toward(global_position + away * 3.0, definition.move_speed, delta)
	elif distance > definition.attack_range * 0.9:
		_move_toward(target.global_position, definition.move_speed, delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, definition.acceleration * delta)
		move_and_slide()

func _perform_attack() -> void:
	_spawn_projectile(BOLT, 10.5)

