extends SceneTree

const EXPECTED_ZONE_IDS: Array[StringName] = [
	&"downtown_alley",
	&"ruse_block",
	&"waterfront_seawall",
	&"terminal_service",
	&"harbour_pier",
]
const EXPECTED_SECRET_COUNT := 4
const EXPECTED_ENEMY_TOTAL := 26
const EXPECTED_MAX_PRESSURE := 4
const NAVIGATION_BAKE_TIMEOUT_MSEC := 20_000

const MANIFEST := preload("res://resources/content/vancouver_waterfront_manifest.tres") as ContentManifest
const WORLD_BUILDER_SCRIPT = preload("res://scripts/level/vancouver_waterfront_world_builder.gd")

var failures: Array[String] = []
var navigation_bake_signal_received := false
var navigation_bake_signal_success := false
var navigation_bake_signal_polygon_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_vancouver_route_contracts()
	await _test_world_builder_navigation_contract()

	if failures.is_empty():
		print("VANCOUVER ROUTE PRODUCTION TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_vancouver_route_contracts() -> void:
	_expect(MANIFEST != null, "Vancouver content manifest loads")
	if MANIFEST == null:
		return
	_expect(MANIFEST.validate().is_empty(), "Vancouver manifest validates")
	var route := MANIFEST.route_definition as MissionRouteDefinition
	_expect(route != null, "Vancouver route definition loads")
	if route == null:
		return
	_expect(route.ordered_zone_ids() == EXPECTED_ZONE_IDS, "Vancouver uses five canonical zones")

	var encountered_secret_ids: Dictionary = {}
	var total_secrets := 0
	for zone in route.zones:
		if zone == null:
			continue
		for secret_id: StringName in zone.secret_ids:
			_expect(not encountered_secret_ids.has(String(secret_id)), "Vancouver secret ids are unique")
			encountered_secret_ids[String(secret_id)] = true
			total_secrets += 1
	_expect(total_secrets == EXPECTED_SECRET_COUNT, "Vancouver authored exactly four secrets")

	var total_spawned := 0
	var max_pressure := 0
	for encounter in MANIFEST.encounters:
		if encounter == null:
			continue
		var validation := encounter.validate()
		_expect(validation.is_empty(), "Encounter %s validates: %s" % [encounter.id, validation])
		for wave in encounter.effective_waves():
			var spawns: Array = wave.get("spawns", []) as Array
			total_spawned += spawns.size()
		_expect(max_pressure >= 0, "Encounter pressure contract is inspectable")
		max_pressure = maxi(max_pressure, int(encounter.maximum_simultaneous_attackers))
	_expect(total_spawned == EXPECTED_ENEMY_TOTAL, "Vancouver route includes exactly 26 authored enemies")
	_expect(max_pressure == EXPECTED_MAX_PRESSURE, "Vancouver encounter pressure cap is 4")


func _test_world_builder_navigation_contract() -> void:
	var owner := Node3D.new()
	var builder := WORLD_BUILDER_SCRIPT.new() as VancouverWaterfrontWorldBuilder
	builder.build_navigation = true
	builder.navigation_bake_completed.connect(_on_navigation_bake_completed)
	root.add_child(owner)
	root.add_child(builder)
	var built := builder.build(owner)
	_expect(built, "Vancouver world builder reports a successful build")
	if not built:
		owner.queue_free()
		builder.queue_free()
		return

	var pre_bake_sources: Array[Node] = _navigation_source_nodes(owner)
	_expect(not pre_bake_sources.is_empty(), "Vancouver build creates navigation floor bodies")
	var pre_bake_status := builder.navigation_bake_status()
	_expect(bool(pre_bake_status.get("requested", false)), "Production route explicitly requests navigation baking")
	_expect(not bool(pre_bake_status.get("finished", false)), "Production route does not report a deferred bake as complete before it runs")

	var bake_finished := await _wait_for_navigation_bake(builder)
	_expect(bake_finished, "Vancouver navigation bake completes within the bounded timeout")
	var post_bake_status := builder.navigation_bake_status()
	_expect(bool(post_bake_status.get("started", false)), "Vancouver navigation bake records that work started")
	_expect(bool(post_bake_status.get("finished", false)), "Vancouver navigation bake records a terminal state")
	_expect(bool(post_bake_status.get("succeeded", false)), "Vancouver navigation bake produces navigable polygons")
	_expect(int(post_bake_status.get("polygon_count", 0)) > 0, "Vancouver navigation mesh contains baked polygons")
	_expect(navigation_bake_signal_received, "Vancouver navigation bake emits an explicit terminal signal")
	_expect(navigation_bake_signal_success, "Vancouver navigation bake signal reports success")
	_expect(navigation_bake_signal_polygon_count == int(post_bake_status.get("polygon_count", 0)), "Navigation signal and status report the same polygon count")
	# NavigationServer synchronizes regions on physics frames after the bake callback.
	await physics_frame
	await physics_frame

	var post_bake_sources: Array[Node] = _navigation_source_nodes(owner)
	_expect(pre_bake_sources.size() == post_bake_sources.size(), "Navigation-floor bodies are retained after navigation baking")
	for body in post_bake_sources:
		_expect(body != null and body.get_parent() != null, "Baked floor body remains in tree")
		_expect(body.is_in_group(&"vancouver_navigation_source"), "Navigation source body keeps navigation group ownership")
		var floor_mesh := body.get_child(0) as MeshInstance3D
		var floor_material := floor_mesh.material_override as StandardMaterial3D if floor_mesh != null else null
		_expect(floor_material != null and floor_material.albedo_texture != null, "Critical-route floor retains its manifested production albedo after navigation baking")
		_expect(floor_material != null and not floor_material.normal_enabled and floor_material.orm_texture == null, "Full-screen route floors use the bounded Web-safe material tier")

	if is_instance_valid(builder.navigation_region):
		var navigation_map := builder.navigation_region.get_navigation_map()
		_expect(navigation_map.is_valid(), "Vancouver navigation region owns a valid map")
		if navigation_map.is_valid():
			var path_snapshot := await _wait_for_route_path(navigation_map)
			var route_start: Vector3 = path_snapshot.get("start", Vector3.ZERO)
			var route_end: Vector3 = path_snapshot.get("end", Vector3.ZERO)
			var baked_path: PackedVector3Array = path_snapshot.get("path", PackedVector3Array())
			_expect(baked_path.size() >= 2, "Baked navigation connects the opening checkpoint to harbour departure")
			_expect(route_start.distance_to(Vector3(0.0, 0.0, 8.0)) <= 2.0, "Opening checkpoint resolves onto baked navigation")
			_expect(route_end.distance_to(Vector3(0.0, 0.0, -173.0)) <= 2.0, "Harbour departure resolves onto baked navigation")

	owner.queue_free()
	builder.queue_free()
	await process_frame
	await process_frame


func _wait_for_navigation_bake(builder: VancouverWaterfrontWorldBuilder) -> bool:
	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < NAVIGATION_BAKE_TIMEOUT_MSEC:
		if bool(builder.navigation_bake_status().get("finished", false)):
			return true
		await process_frame
	return false


func _wait_for_route_path(navigation_map: RID) -> Dictionary:
	var expected_start := Vector3(0.0, 0.0, 8.0)
	var expected_end := Vector3(0.0, 0.0, -173.0)
	var snapshot := {
		"start": Vector3.ZERO,
		"end": Vector3.ZERO,
		"path": PackedVector3Array(),
	}
	var started_at := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_at < NAVIGATION_BAKE_TIMEOUT_MSEC:
		var route_start := NavigationServer3D.map_get_closest_point(navigation_map, expected_start)
		var route_end := NavigationServer3D.map_get_closest_point(navigation_map, expected_end)
		var baked_path := NavigationServer3D.map_get_path(navigation_map, route_start, route_end, true)
		snapshot = {"start": route_start, "end": route_end, "path": baked_path}
		if baked_path.size() >= 2 and route_start.distance_to(expected_start) <= 2.0 and route_end.distance_to(expected_end) <= 2.0:
			return snapshot
		await physics_frame
	return snapshot


func _on_navigation_bake_completed(succeeded: bool, polygon_count: int) -> void:
	navigation_bake_signal_received = true
	navigation_bake_signal_success = succeeded
	navigation_bake_signal_polygon_count = polygon_count


func _navigation_source_nodes(owner: Node) -> Array[Node]:
	var bodies: Array[Node] = []
	for node: Node in owner.find_children("*", "StaticBody3D", true, false):
		if node.is_in_group(&"vancouver_navigation_source"):
			bodies.append(node)
	return bodies


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
