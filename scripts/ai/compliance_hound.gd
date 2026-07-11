class_name ComplianceHound
extends EnemyAgent

signal shield_broken

@export var shield_health := 70.0
var shield_active := true

func _ready() -> void:
	super._ready()
	attack_kind = &"hound_dash"

func _damage_multiplier(hit_position: Vector3) -> float:
	if not shield_active:
		return 1.0
	var local_hit := to_local(hit_position)
	if local_hit.z > 0.15:
		shield_health -= 35.0
		if shield_health <= 0.0:
			shield_active = false
			shield_broken.emit()
			var shield := get_node_or_null("Visual/Shield") as Node3D
			if shield != null:
				shield.visible = false
		return 1.35
	return 0.25

func _perform_attack() -> void:
	if not _target_valid():
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = Vector3(direction.x, 0.0, direction.z).normalized() * definition.move_speed * 4.0
	move_and_slide()
	if global_position.distance_to(target.global_position) < definition.attack_range * 1.7 and target.has_method("apply_damage"):
		target.apply_damage(definition.attack_damage, self, target.global_position)

