class_name TowmasterAttackDefinition
extends Resource

enum AttackShape {
	TARGET_ZONE,
	LANE,
	RING,
}

@export var schema_version: int = 1
@export var id: StringName = &""
@export var shape: AttackShape = AttackShape.TARGET_ZONE
@export var telegraph_seconds: float = 0.85
@export var cooldown_seconds: float = 2.4
@export var base_damage: float = 14.0
@export var radius: float = 2.0
@export var length: float = 0.0
@export var width: float = 0.0
@export var visual_color: Color = Color("f58f20")


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if schema_version != 1:
		errors.append("TowmasterAttackDefinition %s has unsupported schema_version %d" % [id, schema_version])

	if id == &"":
		errors.append("TowmasterAttackDefinition has empty id")

	if int(shape) < int(AttackShape.TARGET_ZONE) or int(shape) > int(AttackShape.RING):
		errors.append("TowmasterAttackDefinition %s has invalid shape %s" % [id, shape])

	if not is_finite(telegraph_seconds) or telegraph_seconds <= 0.0:
		errors.append("TowmasterAttackDefinition %s has invalid telegraph_seconds" % id)

	if not is_finite(cooldown_seconds) or cooldown_seconds <= 0.0:
		errors.append("TowmasterAttackDefinition %s has invalid cooldown_seconds" % id)

	if not is_finite(base_damage) or base_damage <= 0.0:
		errors.append("TowmasterAttackDefinition %s has invalid base_damage" % id)

	if not _is_finite_color(visual_color):
		errors.append("TowmasterAttackDefinition %s has invalid visual_color" % id)

	match shape:
		AttackShape.TARGET_ZONE, AttackShape.RING:
			if not is_finite(radius) or radius <= 0.0:
				errors.append("TowmasterAttackDefinition %s requires a positive radius for shape %s" % [id, shape])
		AttackShape.LANE:
			if not is_finite(length) or length <= 0.0:
				errors.append("TowmasterAttackDefinition %s requires a positive length for LANE shape" % id)
			if not is_finite(width) or width <= 0.0:
				errors.append("TowmasterAttackDefinition %s requires a positive width for LANE shape" % id)

	return errors


func _is_finite_color(color: Color) -> bool:
	return is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and is_finite(color.a)
