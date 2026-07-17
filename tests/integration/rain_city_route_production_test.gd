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

const MANIFEST := preload("res://resources/content/vancouver_waterfront_manifest.tres") as ContentManifest
const WORLD_BUILDER_SCRIPT = preload("res://scripts/level/vancouver_waterfront_world_builder.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_test_vancouver_route_contracts()
	_test_world_builder_floor_retention()

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


func _test_world_builder_floor_retention() -> void:
	var owner := Node3D.new()
	var builder := WORLD_BUILDER_SCRIPT.new() as VancouverWaterfrontWorldBuilder
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
	var post_bake_sources: Array[Node] = _navigation_source_nodes(owner)
	_expect(pre_bake_sources.size() == post_bake_sources.size(), "Navigation-floor bodies are retained after navigation baking")
	for body in post_bake_sources:
		_expect(body != null and body.get_parent() != null, "Baked floor body remains in tree")
		_expect(body.is_in_group(&"vancouver_navigation_source"), "Navigation source body keeps navigation group ownership")

	owner.queue_free()
	builder.queue_free()


func _navigation_source_nodes(owner: Node) -> Array[Node]:
	var bodies: Array[Node] = []
	for node: Node in owner.find_children("*", "StaticBody3D", true, false):
		if node.is_in_group(&"vancouver_navigation_source"):
			bodies.append(node)
	return bodies


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
