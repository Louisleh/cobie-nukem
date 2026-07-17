class_name MutantGroundskeeper
extends EnemyAgent

var _charging := false

func _ready() -> void:
	super._ready()
	attack_kind = &"mower_charge"

func _perform_attack() -> void:
	if not _target_valid():
		return
	_charging = true
	var direction := global_position.direction_to(target.global_position)
	velocity = Vector3(direction.x, 0.0, direction.z).normalized() * definition.move_speed * 3.0
	move_and_slide()
	if _can_damage_target(definition.attack_range * 1.5) and target.has_method("apply_damage"):
		target.apply_damage(definition.attack_damage * _damage_scale, self, target.global_position)
	_charging = false

func _on_damaged(_amount: float, _hit_position: Vector3) -> void:
	if _charging:
		_charging = false
