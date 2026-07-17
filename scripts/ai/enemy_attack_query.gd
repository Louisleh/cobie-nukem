class_name EnemyAttackQuery
extends RefCounted

static func has_clear_path(actor: CharacterBody3D, target: Node3D, target_height: float, maximum_distance: float) -> bool:
	if not is_instance_valid(target) or actor.global_position.distance_to(target.global_position) > maximum_distance:
		return false
	if not actor.is_inside_tree() or actor.get_world_3d() == null:
		return true
	var origin := actor.global_position + Vector3.UP * maxf(target_height * 0.5, 0.4)
	var destination := target.global_position + Vector3.UP * 0.6
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 3, [actor.get_rid()])
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	while collider != null and collider != target:
		collider = collider.get_parent()
	return collider == target
