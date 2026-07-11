class_name QATarget
extends Node3D

var is_dead := false
var auto_aim_threat := 0.0
var damage_received := 0.0
var golden_ball_strikes := 0

func apply_damage(amount: float, _source: Node = null, _hit_position := Vector3.ZERO) -> float:
	if is_dead:
		return 0.0
	damage_received += amount
	return amount

func strike_with_golden_ball(_source: Node = null) -> void:
	golden_ball_strikes += 1

func get_auto_aim_position() -> Vector3:
	return global_position

