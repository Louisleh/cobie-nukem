class_name EnemyGroundRecovery
extends RefCounted

const NONE := &"none"
const RECOVERED := &"recovered"
const DEFEAT := &"defeat"

var last_safe_position := Vector3.ZERO
var has_safe_position := false
var consecutive_recoveries := 0


func configure(initial_position: Vector3) -> void:
	last_safe_position = initial_position
	has_safe_position = initial_position.is_finite()
	consecutive_recoveries = 0


func stabilize(body: CharacterBody3D, drop_distance: float, retry_limit: int) -> StringName:
	if body.is_on_floor():
		last_safe_position = body.global_position
		has_safe_position = true
		consecutive_recoveries = 0
		return NONE
	if not has_safe_position or body.global_position.y > last_safe_position.y - drop_distance:
		return NONE
	if consecutive_recoveries >= retry_limit:
		return DEFEAT
	consecutive_recoveries += 1
	body.global_position = last_safe_position + Vector3.UP * 0.05
	body.velocity = Vector3.ZERO
	return RECOVERED
