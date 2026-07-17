class_name ComplianceHound
extends EnemyAgent

signal shield_broken

@onready var directional_shield := $DirectionalShieldComponent as DirectionalShieldComponent


func _ready() -> void:
	super._ready()
	attack_kind = &"hound_dash"
	if directional_shield != null:
		directional_shield.shield_broken.connect(_on_directional_shield_broken)


func apply_damage(amount: float, source: Node = null, hit_position := Vector3.ZERO) -> float:
	var multiplier := 1.0
	if directional_shield != null:
		multiplier = directional_shield.damage_multiplier(self, hit_position, amount)
	return super.apply_damage(amount * multiplier, source, hit_position)


func _on_directional_shield_broken() -> void:
	shield_broken.emit()


func apply_recall_stagger(multiplier: float) -> void:
	if is_dead:
		return
	if directional_shield != null:
		directional_shield.apply_stagger_multiplier(multiplier)
	stun(0.7 * maxf(multiplier, 1.0))

func _perform_attack() -> void:
	if not _target_valid():
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = Vector3(direction.x, 0.0, direction.z).normalized() * definition.move_speed * 4.0
	move_and_slide()
	if _can_damage_target(definition.attack_range * 1.7) and target.has_method("apply_damage"):
		target.apply_damage(definition.attack_damage * _damage_scale, self, target.global_position)
