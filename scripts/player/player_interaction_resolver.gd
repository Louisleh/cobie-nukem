class_name PlayerInteractionResolver
extends RefCounted


static func resolve(owner: CollisionObject3D, camera: Camera3D, interaction_range: float, interaction_mask: int, required_method: StringName) -> Node:
	var direct := _ray_target(owner, camera, interaction_range, interaction_mask)
	if direct != null and direct.has_method(required_method):
		return direct
	return _nearby_target(camera, interaction_range, required_method)


static func _ray_target(owner: CollisionObject3D, camera: Camera3D, interaction_range: float, interaction_mask: int) -> Node:
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * interaction_range, interaction_mask)
	query.exclude = [owner.get_rid()]
	return camera.get_world_3d().direct_space_state.intersect_ray(query).get("collider") as Node


static func _nearby_target(camera: Camera3D, interaction_range: float, required_method: StringName) -> Node:
	var best: Node
	var best_score := INF
	var registry := camera.get_node_or_null("/root/WorldRegistry")
	var candidates: Array[Node] = registry.interactables_view() if registry != null else []
	for node in candidates:
		if not node is Node3D or not node.has_method(required_method):
			continue
		var offset := (node as Node3D).global_position - camera.global_position
		var distance := offset.length()
		if distance > interaction_range + 0.8:
			continue
		var facing := (-camera.global_basis.z).dot(offset.normalized())
		if facing < 0.45:
			continue
		var score := distance - facing
		if score < best_score:
			best = node
			best_score = score
	return best
