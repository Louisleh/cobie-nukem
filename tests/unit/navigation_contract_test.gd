extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := preload("res://scenes/levels/episode_1_level_1.tscn").instantiate() as EpisodeOneLevel
	level.spawn_player = false
	level.start_run_automatically = false
	level.setup_presentation = false
	root.add_child(level)
	for _frame in 5:
		await physics_frame
	var region := level.get_node_or_null("GroundNavigation") as NavigationRegion3D
	_expect(region != null, "Salmon Creek owns a production ground navigation region")
	if region != null:
		var mesh := region.navigation_mesh
		var navigation_map := region.get_navigation_map()
		print("NAVIGATION EVIDENCE: polygons=%d vertices=%d bounds=%s map_iteration=%d closest_opening=%s closest_arena=%s" % [mesh.get_polygon_count(), mesh.get_vertices().size(), region.get_bounds(), NavigationServer3D.map_get_iteration_id(navigation_map), NavigationServer3D.map_get_closest_point(navigation_map, Vector3(0.0, 0.5, 10.0)), NavigationServer3D.map_get_closest_point(navigation_map, Vector3(0.0, 0.5, -164.0))])
		_expect(mesh != null and mesh.get_polygon_count() >= 10, "Navigation bake contains representative multi-zone polygons")
		var route := NavigationServer3D.map_get_path(
			region.get_navigation_map(),
			Vector3(0.0, 0.5, 10.0),
			Vector3(0.0, 0.5, -164.0),
			true
		)
		print("NAVIGATION EVIDENCE: cross_zone_path_points=%d" % route.size())
		_expect(route.size() >= 2, "Navigation path connects the opening field to the Walker arena")
		if route.size() >= 2:
			_expect(route[0].distance_to(Vector3(0.0, 0.5, 10.0)) < 2.0, "Route begins near the authored opening")
			_expect(route[-1].distance_to(Vector3(0.0, 0.5, -164.0)) < 2.0, "Route reaches the authored arena conclusion")
		var cover_route := NavigationServer3D.map_get_path(
			region.get_navigation_map(),
			Vector3(-10.0, 0.5, -135.0),
			Vector3(-10.0, 0.5, -161.0),
			true
		)
		var maximum_cover_deviation := 0.0
		for point in cover_route:
			maximum_cover_deviation = maxf(maximum_cover_deviation, absf(point.x + 10.0))
		print("NAVIGATION EVIDENCE: arena_cover_path_points=%d lateral_deviation=%.2f" % [cover_route.size(), maximum_cover_deviation])
		_expect(cover_route.size() >= 3 and maximum_cover_deviation > 1.5, "Arena paths route around authored cover instead of through it")

	var ground_enemy := preload("res://scenes/enemies/mutant_groundskeeper.tscn").instantiate() as EnemyAgent
	ground_enemy.position = Vector3(0.0, 0.1, -140.0)
	level.get_node("Actors").add_child(ground_enemy)
	var drone := preload("res://scenes/enemies/leash_enforcement_drone.tscn").instantiate() as EnemyAgent
	drone.position = Vector3(0.0, 2.0, -140.0)
	level.get_node("Actors").add_child(drone)
	for _frame in 3:
		await physics_frame
	_expect(ground_enemy.get_node_or_null("NavigationAgent3D") is NavigationAgent3D, "Ground enemies receive a NavigationAgent3D")
	_expect(drone.get_node_or_null("EnemyNavigator") == null, "Flying enemies preserve authored flight steering")

	var recoveries := [0]
	ground_enemy.navigation_recovery_requested.connect(func(_enemy: EnemyAgent, reason: StringName) -> void:
		print("NAVIGATION EVIDENCE: recovery_reason=%s" % reason)
		if reason == &"stuck_on_navigation": recoveries[0] += 1
	)
	print("NAVIGATION EVIDENCE: enemy_map_iteration=%d enemy_closest=%s" % [NavigationServer3D.map_get_iteration_id(ground_enemy._navigator.agent.get_navigation_map()), NavigationServer3D.map_get_closest_point(ground_enemy._navigator.agent.get_navigation_map(), ground_enemy.global_position)])
	# Three stationary samples represent three failed repaths. Recovery must be
	# bounded to the nearest valid point and observable through the actor signal.
	for _sample in 3:
		ground_enemy._navigator.observe_motion(true, 0.36)
	_expect(recoveries[0] == 1, "Persistent path stalls emit one bounded recovery event")
	_expect(ground_enemy._navigator.recovery_count == 1, "Navigation recovery is counted for local diagnostics")

	level.free()
	await process_frame
	if failures.is_empty():
		print("PASS: production navigation bake, cross-zone route, ground/flying split, and bounded recovery")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
