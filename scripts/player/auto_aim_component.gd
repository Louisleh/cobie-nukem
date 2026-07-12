class_name AutoAimComponent
extends Node

signal target_changed(target: Node3D)

@export var tuning: AutoAimTuning
@export var target_group := &"auto_aim_targets"
@export var max_range := 90.0
@export var collision_mask := 1

var current_target: Node3D
var _lock_time_remaining := 0.0

func _process(delta: float) -> void:
	_lock_time_remaining = maxf(0.0, _lock_time_remaining - delta)

func get_aim_direction(camera: Camera3D, range_limit := -1.0) -> Vector3:
	var forward := -camera.global_basis.z.normalized()
	if tuning == null or tuning.mode == AutoAimTuning.Mode.OFF:
		_set_target(null)
		return forward
	var effective_range := max_range if range_limit <= 0.0 else minf(max_range, range_limit)
	if is_instance_valid(current_target) and _lock_time_remaining > 0.0 and _candidate_valid(camera, current_target, effective_range):
		return _corrected_direction(camera, current_target, forward)
	var best := _find_best_target(camera, effective_range)
	_set_target(best)
	if best == null:
		return forward
	_lock_time_remaining = tuning.lock_persistence_seconds
	return _corrected_direction(camera, best, forward)

func _find_best_target(camera: Camera3D, effective_range: float) -> Node3D:
	var best: Node3D
	var best_score := INF
	var registry := get_node_or_null("/root/WorldRegistry")
	var candidates: Array[Node] = registry.targets() if registry != null else []
	for candidate in candidates:
		if candidate is not Node3D or not _candidate_valid(camera, candidate, effective_range):
			continue
		var offset: Vector3 = _target_position(candidate) - camera.global_position
		var distance := offset.length()
		var angle := rad_to_deg((-camera.global_basis.z).angle_to(offset.normalized()))
		var threat := float(candidate.get("auto_aim_threat")) if candidate.get("auto_aim_threat") != null else 0.0
		var score := angle * tuning.reticle_weight + (distance / effective_range) * tuning.distance_weight - threat * tuning.threat_weight
		if score < best_score:
			best_score = score
			best = candidate
	return best

func _candidate_valid(camera: Camera3D, candidate: Node3D, effective_range: float) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_inside_tree():
		return false
	if candidate.get("is_dead") == true:
		return false
	var offset := _target_position(candidate) - camera.global_position
	if offset.length_squared() <= 0.001 or offset.length() > effective_range:
		return false
	var local_direction := camera.global_basis.inverse() * offset.normalized()
	if local_direction.z >= 0.0:
		return false
	var horizontal_angle := absf(rad_to_deg(atan2(local_direction.x, -local_direction.z)))
	var vertical_angle := absf(rad_to_deg(atan2(local_direction.y, -local_direction.z)))
	if horizontal_angle > tuning.horizontal_cone_degrees or vertical_angle > tuning.vertical_cone_degrees:
		return false
	return _has_line_of_sight(camera, candidate)

func _has_line_of_sight(camera: Camera3D, candidate: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, _target_position(candidate), collision_mask)
	# Camera3D is not a CollisionObject3D and therefore has no RID to exclude.
	# The ray begins at the camera and the player is on a separate collision layer,
	# so no exclusion is necessary for this world-geometry visibility test.
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Object = hit.get("collider")
	return collider == candidate or (collider is Node and candidate.is_ancestor_of(collider))

func _corrected_direction(camera: Camera3D, target: Node3D, forward: Vector3) -> Vector3:
	var desired := (_target_position(target) - camera.global_position).normalized()
	var angle := forward.angle_to(desired)
	var max_angle := deg_to_rad(tuning.maximum_correction_degrees) * tuning.strength() * _difficulty_aim_scale()
	if angle <= max_angle:
		return desired
	return forward.slerp(desired, max_angle / maxf(angle, 0.0001)).normalized()


func _difficulty_aim_scale() -> float:
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and game_state.has_method("get_difficulty_profile"):
		var profile: DifficultyProfile = game_state.get_difficulty_profile()
		if profile != null:
			return profile.aim_assist_scale()
	return 1.0

func _target_position(target: Node3D) -> Vector3:
	if target.has_method("get_auto_aim_position"):
		return target.get_auto_aim_position()
	var marker := target.get_node_or_null("AutoAimTarget") as Node3D
	return marker.global_position if marker != null else target.global_position

func _set_target(value: Node3D) -> void:
	if current_target == value:
		return
	current_target = value
	target_changed.emit(value)
