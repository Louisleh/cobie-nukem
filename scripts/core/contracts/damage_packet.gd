class_name DamagePacket
extends RefCounted

var amount: float
var source: Node
var hit_position: Vector3
var hit_normal: Vector3
var damage_type: StringName

func _init(
	p_amount: float,
	p_source: Node = null,
	p_hit_position := Vector3.ZERO,
	p_hit_normal := Vector3.ZERO,
	p_damage_type: StringName = &"generic"
) -> void:
	amount = maxf(0.0, p_amount)
	source = p_source
	hit_position = p_hit_position
	hit_normal = p_hit_normal
	damage_type = p_damage_type

