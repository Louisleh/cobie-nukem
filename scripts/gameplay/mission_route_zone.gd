class_name MissionRouteZone
extends Resource

@export var zone_id: StringName = &"zone"
@export var zone_title := "ROUTE ZONE"
@export var bounds := AABB(Vector3(0.0, 0.0, 0.0), Vector3(16.0, 6.0, 24.0))
@export var spawn_volumes: Array[AABB] = []
@export var patrol_paths: Array = []
@export var prop_set_id: StringName = &"vancouver_zone_props"
@export var surface_ids: Array[StringName] = []
@export var checkpoint_ids: Array[StringName] = []
@export var secret_ids: Array[StringName] = []
@export var outgoing_edge_ids: Array[StringName] = []

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if zone_id == &"":
		errors.append("route zone has empty zone_id")
	if zone_title.strip_edges().is_empty():
		errors.append("route zone %s has no title" % zone_id)
	if not bounds.position.is_finite() or not bounds.size.is_finite():
		errors.append("route zone %s has non-finite bounds" % zone_id)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or bounds.size.z <= 0.0:
		errors.append("route zone %s has empty bounds" % zone_id)
	if spawn_volumes.is_empty():
		errors.append("route zone %s has no spawn volumes" % zone_id)
	for volume_index in range(spawn_volumes.size()):
		var volume: AABB = spawn_volumes[volume_index]
		if not volume.position.is_finite() or not volume.size.is_finite():
			errors.append("route zone %s spawn volume %d has non-finite bounds" % [zone_id, volume_index])
		if volume.size.x <= 0.0 or volume.size.y <= 0.0 or volume.size.z <= 0.0:
			errors.append("route zone %s spawn volume %d is empty" % [zone_id, volume_index])
	if patrol_paths.is_empty():
		errors.append("route zone %s has no patrol paths" % zone_id)
	for path_index in range(patrol_paths.size()):
		var path: Variant = patrol_paths[path_index]
		if not path is Array:
			errors.append("route zone %s patrol path %d is not an array" % [zone_id, path_index])
			continue
		var waypoints: Array = path as Array
		if waypoints.size() < 2:
			errors.append("route zone %s patrol path %d has fewer than two points" % [zone_id, path_index])
			continue
		for point_index in range(waypoints.size()):
			var waypoint: Variant = waypoints[point_index]
			if not waypoint is Vector3:
				errors.append("route zone %s patrol path %d point %d is not Vector3" % [zone_id, path_index, point_index])
				continue
			if not (waypoint as Vector3).is_finite():
				errors.append("route zone %s patrol path %d point %d is non-finite" % [zone_id, path_index, point_index])
	if prop_set_id == &"":
		errors.append("route zone %s has empty prop_set_id" % zone_id)
	if surface_ids.is_empty():
		errors.append("route zone %s has no surface_ids" % zone_id)
	for index in range(surface_ids.size()):
		if surface_ids[index] == &"":
			errors.append("route zone %s surface_ids[%d] is empty" % [zone_id, index])
	if checkpoint_ids.is_empty():
		errors.append("route zone %s has no checkpoint ids" % zone_id)
	for index in range(checkpoint_ids.size()):
		if checkpoint_ids[index] == &"":
			errors.append("route zone %s checkpoint_ids[%d] is empty" % [zone_id, index])
	for index in range(secret_ids.size()):
		if secret_ids[index] == &"":
			errors.append("route zone %s secret_ids[%d] is empty" % [zone_id, index])
	return errors
