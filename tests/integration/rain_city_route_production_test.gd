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
const PRESENTATION_SCENE = preload("res://scenes/levels/vancouver/rain_city_presentation.tscn")
const INTERACTION_CATALOG := preload("res://resources/interactions/vancouver_waterfront_interactions.tres") as InteractionCatalog

var failures: Array[String] = []
var navigation_bake_signal_received := false
var navigation_bake_signal_success := false
var navigation_bake_signal_polygon_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_vancouver_route_contracts()
	_test_manifested_foundry_materials()
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
	var terminal_zone := route.zone_for_id(&"terminal_service")
	_expect(terminal_zone != null and terminal_zone.outgoing_edge_ids.has(&"waterfront_seawall"), "Terminal route graph declares the powered seawall revisit")
	var runtime := MissionRouteRuntime.new()
	_expect(runtime.configure(route), "Runtime configures the route with its optional revisit edge")
	for zone_id in [&"downtown_alley", &"ruse_block", &"waterfront_seawall", &"terminal_service"]:
		var zone := route.zone_for_id(zone_id)
		runtime.submit_actor_position(zone.bounds.get_center())
	runtime.submit_actor_position(route.zone_for_id(&"waterfront_seawall").bounds.get_center())
	_expect(runtime.current_zone == &"terminal_service", "Optional seawall revisit never regresses ordered objective/checkpoint progression")
	runtime.free()

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


func _test_manifested_foundry_materials() -> void:
	var presentation := PRESENTATION_SCENE.instantiate() as RainCityMaterialApplier
	_expect(presentation != null, "Rain City foundry presentation instantiates")
	if presentation == null: return
	_expect(presentation.validate_material_contract(presentation).is_empty(), "Every RC_ foundry material maps to a manifested runtime family")
	presentation.free()


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
	var pre_bake_status := builder.navigation_bake_status()
	_expect(bool(pre_bake_status.get("requested", false)), "Production route explicitly requests navigation baking")
	_expect(not bool(pre_bake_status.get("finished", false)), "Production route does not report a deferred bake as complete before it runs")
	var route_presentation := PRESENTATION_SCENE.instantiate() as RainCityMaterialApplier
	owner.add_child(route_presentation)
	route_presentation.apply_route_gate_presentation(owner)
	_test_route_gate_presentation_contract(owner, route_presentation)
	await physics_frame
	await _test_spatial_route_geometry(owner, builder)

	var pre_bake_sources: Array[Node] = _navigation_source_nodes(owner)
	_expect(not pre_bake_sources.is_empty(), "Vancouver build creates navigation floor bodies")
	var environment := owner.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_expect(environment != null and environment.environment != null, "Rain City exposes the canonical WorldEnvironment for zone fog profiles")
	var connector_count := 0
	for body in pre_bake_sources:
		if not body.is_in_group(&"rain_city_route_connectors"): continue
		connector_count += 1
		var connector_mesh := body.get_child(0) as MeshInstance3D
		var connector_box := connector_mesh.mesh as BoxMesh if connector_mesh != null else null
		_expect(connector_box != null and body.position.y + connector_box.size.y * 0.5 < -0.005, "Rain City connector %d is not coplanar with zone floors" % connector_count)
	_expect(connector_count == 4, "Rain City keeps four non-coplanar route connectors")
	var signs := owner.get_tree().get_nodes_in_group(&"authored_world_signs")
	var sign_ids: Dictionary = {}
	var slice_storefront_sign: AuthoredWorldSign
	_expect(signs.size() == 12, "Rain City registers all twelve authored route signs")
	for raw_sign in signs:
		var sign := raw_sign as AuthoredWorldSign
		_expect(sign != null, "Rain City sign group contains only authored signs")
		if sign == null: continue
		_expect(not sign_ids.has(sign.placement_id), "Rain City sign id %s is unique" % sign.placement_id)
		sign_ids[sign.placement_id] = true
		if sign.placement_id == &"slice_storefront":
			slice_storefront_sign = sign
		for error in sign.validate_authored():
			failures.append("Rain City sign: " + error)
	var slice_awnings := owner.find_children("SliceAwning", "StaticBody3D", true, false)
	_expect(slice_storefront_sign != null and slice_awnings.size() == 1, "Rain City Slice exposes one storefront sign and awning")
	if slice_storefront_sign != null and slice_awnings.size() == 1:
		var slice_awning := slice_awnings[0] as StaticBody3D
		var awning_mesh := slice_awning.get_child(0) as MeshInstance3D
		var awning_box := awning_mesh.mesh as BoxMesh if awning_mesh != null else null
		_expect(awning_box != null and slice_storefront_sign.global_position.x >= slice_awning.global_position.x + awning_box.size.x * 0.5 + slice_storefront_sign.minimum_wall_clearance and is_equal_approx(slice_storefront_sign.global_position.z, slice_awning.global_position.z), "Rain City Slice hero sign is centered on and clears the awning face instead of depth-clipping into it")
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
			_test_elevated_navigation_sources(navigation_map, owner)

	owner.queue_free()
	builder.queue_free()
	await process_frame
	await process_frame


func _test_route_gate_presentation_contract(owner: Node3D, route_presentation: RainCityMaterialApplier) -> void:
	var gates: Array[Node] = []
	for group_id in [&"rain_city_encounter_gates", &"rain_city_route_state_gates"]:
		for candidate in owner.get_tree().get_nodes_in_group(group_id):
			if owner.is_ancestor_of(candidate):
				gates.append(candidate)
	_expect(gates.size() == 5, "Rain City dresses four encounter gates and one route-state gate")
	for raw_gate in gates:
		var gate := raw_gate as StaticBody3D
		var collision := gate.get_child(1) as CollisionShape3D if gate != null and gate.get_child_count() > 1 else null
		var original_mesh := gate.get_child(0) as MeshInstance3D if gate != null and gate.get_child_count() > 0 else null
		var presentation := gate.get_node_or_null("WCB008Presentation") as Node3D if gate != null else null
		_expect(collision != null and collision.shape is BoxShape3D and not collision.disabled, "%s retains its authoritative closed collision shape" % gate.name)
		_expect(original_mesh != null and not original_mesh.visible, "%s hides the collision-debug slab" % gate.name)
		_expect(presentation != null and bool(presentation.get_meta(&"render_only", false)), "%s owns explicit render-only authored barrier dressing" % gate.name)
		_expect(presentation != null and presentation.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s barrier dressing adds no collision ownership" % gate.name)
	_expect(route_presentation.apply_route_gate_presentation(owner) == 0, "Rain City barrier dressing is idempotent")


func _test_spatial_route_geometry(owner: Node3D, builder: VancouverWaterfrontWorldBuilder) -> void:
	var loop_roles: Dictionary = {}
	var shortcut_found := false
	for raw_node in owner.get_tree().get_nodes_in_group(&"rain_city_route_features"):
		var node := raw_node as Node3D
		if node == null or not owner.is_ancestor_of(node):
			continue
		var feature_id := StringName(node.get_meta(&"route_feature_id", &""))
		var kind := StringName(node.get_meta(&"route_feature_kind", &""))
		var role := StringName(node.get_meta(&"route_feature_role", &""))
		if kind == &"loop":
			if not loop_roles.has(feature_id):
				loop_roles[feature_id] = {}
			(loop_roles[feature_id] as Dictionary)[role] = true
		elif kind == &"shortcut" and feature_id == &"rainline_return":
			shortcut_found = node.get_meta(&"revisit_zone_id", &"") == &"waterfront_seawall"
	var expected_loops := [&"seawall_overlook", &"terminal_control", &"pier_crane_flank"]
	_expect(loop_roles.size() == expected_loops.size(), "Rain City builds exactly three authored vertical loops")
	for loop_id in expected_loops:
		var roles := loop_roles.get(loop_id, {}) as Dictionary
		_expect(roles.has(&"entry") and roles.has(&"path") and roles.has(&"exit"), "Route loop %s reconnects through entry, elevated path, and exit" % loop_id)
	_expect(shortcut_found, "Rain Line return declares a terminal-to-seawall revisit shortcut")

	var state_gates: Array[Node] = []
	for gate in owner.get_tree().get_nodes_in_group(&"rain_city_route_state_gates"):
		if owner.is_ancestor_of(gate): state_gates.append(gate)
	_expect(state_gates.size() == 1, "Rain City owns one explicit route-state gate")
	if state_gates.size() == 1:
		var gate := state_gates[0] as StaticBody3D
		_expect(gate != null and gate.collision_layer != 0 and gate.get_meta(&"unlocked_by", &"") == &"terminal_power", "Rain Line return starts collision-closed and binds to terminal power")
		builder.set_route_gate_open(&"rainline_return", true)
		await physics_frame
		_expect(gate.collision_layer == 0 and _all_gate_shapes_disabled(gate), "Terminal power opens the Rain Line return collision gate")
		builder.set_route_gate_open(&"rainline_return", false)
		await physics_frame
		_expect(gate.collision_layer != 0 and not _all_gate_shapes_disabled(gate), "Route-state reset closes the Rain Line return gate")

	var sightlines: Array[Node] = []
	for marker in owner.get_tree().get_nodes_in_group(&"rain_city_sightline_windows"):
		if owner.is_ancestor_of(marker): sightlines.append(marker)
	_expect(sightlines.size() == 2, "Rain City declares two cross-area sightline windows")
	for raw_marker in sightlines:
		var marker := raw_marker as Node3D
		var target: Vector3 = marker.get_meta(&"target_position", marker.global_position)
		var query := PhysicsRayQueryParameters3D.create(marker.global_position, target)
		query.collision_mask = 1
		var hit := owner.get_world_3d().direct_space_state.intersect_ray(query)
		_expect(hit.is_empty(), "Sightline %s is unobstructed across authored route geometry" % marker.get_meta(&"sightline_id", &""))

	var landmark_roles: Dictionary = {}
	for raw_anchor in owner.get_tree().get_nodes_in_group(&"rain_city_landmark_anchors"):
		var anchor := raw_anchor as Node3D
		if anchor != null and owner.is_ancestor_of(anchor):
			landmark_roles[anchor.get_meta(&"canonical_role", &"")] = anchor.get_meta(&"landmark_id", &"")
	_expect(landmark_roles == {
		&"opening": &"vancouver_downtown_waypoint",
		&"mid_route": &"vancouver_waterfront_pier",
		&"finale": &"vancouver_harbour_mast",
	}, "Opening, mid-route, and finale anchors bind to manifested landmark ids")
	_test_return_route_secret()


func _test_return_route_secret() -> void:
	var placement: InteractionPlacement
	for candidate: InteractionPlacement in INTERACTION_CATALOG.placements:
		if candidate != null and candidate.definition != null and candidate.definition.secret_id == &"secret_waterfront_seawall":
			placement = candidate
			break
	_expect(placement != null, "Waterfront revisit owns an interaction-backed secret")
	if placement == null:
		return
	var position_value := placement.transform.origin
	_expect(position_value.y > 1.5 and position_value.z < -89.3, "Waterfront secret sits on the elevated terminal side of the locked return gate")
	_expect(placement.definition.prompt.contains("RAIN LINE"), "Waterfront revisit secret provides an observation/interaction clue")


func _all_gate_shapes_disabled(gate: StaticBody3D) -> bool:
	for child in gate.get_children():
		if child is CollisionShape3D and not (child as CollisionShape3D).disabled:
			return false
	return true


func _test_elevated_navigation_sources(navigation_map: RID, owner: Node3D) -> void:
	var elevated_paths := 0
	for raw_node in owner.get_tree().get_nodes_in_group(&"rain_city_route_features"):
		var node := raw_node as Node3D
		if node == null or not owner.is_ancestor_of(node):
			continue
		if node.get_meta(&"route_feature_kind", &"") != &"loop" or node.get_meta(&"route_feature_role", &"") != &"path":
			continue
		elevated_paths += 1
		var closest := NavigationServer3D.map_get_closest_point(navigation_map, node.global_position + Vector3.UP * 0.25)
		_expect(closest.distance_to(node.global_position + Vector3.UP * 0.25) <= 1.0, "Elevated loop %s contributes baked navigation" % node.get_meta(&"route_feature_id", &""))
	_expect(elevated_paths >= 2, "Rain City provides at least two baked combat elevations")


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
