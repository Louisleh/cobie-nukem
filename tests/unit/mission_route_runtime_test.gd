extends SceneTree

const VANCOUVER_ROUTE := preload("res://resources/routes/vancouver_route_definition.tres") as MissionRouteDefinition
const REUSE_ROUTE_ID := &"vancouver_mission2_route"
const RUNTIME_SCRIPT: GDScript = preload("res://scripts/gameplay/mission_route_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(_runtime_script_is_loaded(), "MissionRouteRuntime script is loadable")
	_test_ordered_zone_contract()
	_test_configure_bool_and_unconfigured_state()
	_test_ordered_transitions()
	_test_boundary_overlap_tolerance()
	_test_vertical_aisle_transition()
	_test_illegal_skip()
	_test_recovery_policy()
	_test_recovery_regression_for_directed_route()
	_test_restore_and_corrupt_reject()
	_test_reset_and_reconfigure_idempotent()
	_test_checkpoint_mapping_and_completion()
	_test_stress_simulation_hundred_steps()
	_cleanup_runtime_nodes()

	if failures.is_empty():
		print("MISSION ROUTE RUNTIME TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _runtime_script_is_loaded() -> bool:
	if not (RUNTIME_SCRIPT != null):
		failures.append("MissionRouteRuntime script preload is null")
		return false
	var runtime: MissionRouteRuntime = RUNTIME_SCRIPT.new()
	if runtime == null:
		failures.append("MissionRouteRuntime script could not be instantiated")
		return false
	runtime.free()
	return true


func _test_ordered_zone_contract() -> void:
	var ordered := VANCOUVER_ROUTE.ordered_zone_ids()
	_expect(ordered == [
		&"downtown_alley",
		&"ruse_block",
		&"waterfront_seawall",
		&"terminal_service",
		&"harbour_pier",
	], "route definition has exactly five Vancouver zones in expected order")


func _test_configure_bool_and_unconfigured_state() -> void:
	var runtime := _new_runtime()
	if runtime == null:
		return
	_expect(runtime.configure(VANCOUVER_ROUTE) == true, "configure(valid definition) returns true")

	var bad_route := _bad_route_missing_zone_id()
	_expect(runtime.configure(bad_route) == false, "configure(invalid definition) returns false")
	_expect(runtime.snapshot().get("route_id", "") == "", "configure failure leaves unconfigured route state")
	_expect(runtime.current_zone == &"", "configure failure clears current_zone")

	_expect(runtime.configure(VANCOUVER_ROUTE) == true, "runtime can reconfigure after failed configure")
	_expect(runtime.snapshot().get("route_id", "") == String(REUSE_ROUTE_ID), "runtime reconfigure recovers to valid route")
	runtime.free()


func _test_ordered_transitions() -> void:
	var runtime := _prepared_runtime(VANCOUVER_ROUTE)
	if runtime == null:
		return
	var entered: Array[StringName] = []
	runtime.zone_entered.connect(func(zone_id: StringName, _title: String) -> void:
		entered.append(zone_id)
	)
	var ordered := VANCOUVER_ROUTE.ordered_zone_ids()

	for zone_id in ordered:
		runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, zone_id))

	_expect(runtime.current_zone == &"harbour_pier", "ordered transitions reach harbour_pier")
	_expect(runtime.current_zone_index == 4, "ordered transitions update index to final")
	_expect(entered == ordered, "zone_entered emitted once for each ordered zone")

	runtime.free()


func _test_boundary_overlap_tolerance() -> void:
	var route := _new_overlap_route()
	var runtime := _prepared_runtime(route)
	if runtime == null:
		return
	runtime.submit_actor_position(_route_center(route, &"zone_a"))
	_expect(runtime.current_zone == &"zone_a", "runtime starts in zone_a")
	runtime.submit_actor_position(Vector3(2.1, 1.0, 1.0))
	_expect(runtime.current_zone == &"zone_b", "overlap boundary transition uses tolerance")
	runtime.free()


func _test_vertical_aisle_transition() -> void:
	var route := _new_vertical_route()
	var runtime := _prepared_runtime(route)
	if runtime == null:
		return
	runtime.submit_actor_position(_route_center(route, &"lower_lane"))
	_expect(runtime.current_zone == &"lower_lane", "runtime starts in lower lane")
	runtime.submit_actor_position(Vector3(1.5, 2.0, 1.5))
	_expect(runtime.current_zone == &"lower_lane", "vertical tolerance cannot promote an actor still inside the lower lane")
	runtime.submit_actor_position(Vector3(1.5, 2.59, 1.5))
	_expect(runtime.current_zone == &"lower_lane", "upper-lane transition waits for strict vertical entry")
	runtime.submit_actor_position(Vector3(1.5, 2.65, 1.5))
	_expect(runtime.current_zone == &"upper_lane", "transition enters upper lane via vertical AABB")
	runtime.free()


func _test_illegal_skip() -> void:
	var runtime := _prepared_runtime(VANCOUVER_ROUTE)
	if runtime == null:
		return
	var ordered := VANCOUVER_ROUTE.ordered_zone_ids()
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, ordered[0]))
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, ordered[2]))
	_expect(runtime.current_zone == &"downtown_alley", "non-adjacent skip to zone 3 is blocked")
	runtime.free()
	var graph_route := _new_directed_recovery_route()
	graph_route.zones[0].outgoing_edge_ids.append(&"route_end")
	var graph_runtime := _prepared_runtime(graph_route)
	graph_runtime.submit_actor_position(_route_center(graph_route, &"route_start"))
	graph_runtime.submit_actor_position(_route_center(graph_route, &"route_end"))
	_expect(graph_runtime.current_zone == &"route_start", "non-adjacent graph edge cannot bypass ordered progression")
	graph_runtime.free()


func _test_recovery_policy() -> void:
	var runtime := _prepared_runtime(VANCOUVER_ROUTE)
	if runtime == null:
		return
	var ordered := VANCOUVER_ROUTE.ordered_zone_ids()
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, ordered[0]))

	var recovery_blocked := runtime.recovery_query(_zone_center(VANCOUVER_ROUTE, ordered[2]))
	_expect(recovery_blocked == &"downtown_alley", "recovery defaults block skip to zone 3")

	runtime.reset()
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, ordered[0]))
	var recovery_authorized := runtime.recovery_query(
		_zone_center(VANCOUVER_ROUTE, ordered[4]),
		MissionRouteRuntime.RecoveryPolicy.ALLOW_SKIP_INTERMEDIATE
	)
	_expect(recovery_authorized == &"harbour_pier", "explicit skip policy can jump to earliest reachable final zone")
	_expect(runtime.current_zone == &"downtown_alley", "recovery query does not silently mutate mission progression")

	runtime.free()


func _test_recovery_regression_for_directed_route() -> void:
	var route := _new_directed_recovery_route()
	var runtime := _prepared_runtime(route)
	if runtime == null:
		return
	var ordered := route.ordered_zone_ids()
	runtime.submit_actor_position(_route_center(route, ordered[0]))
	runtime.submit_actor_position(_route_center(route, ordered[1]))
	runtime.submit_actor_position(_route_center(route, ordered[2]))
	_expect(runtime.current_zone == ordered[2], "directed route reaches final zone")

	var without_regression := runtime.recovery_query(_route_center(route, ordered[1]), MissionRouteRuntime.RecoveryPolicy.NONE)
	_expect(without_regression == ordered[2], "directed recovery without regression does not move backward")

	runtime.reset()
	runtime.submit_actor_position(_route_center(route, ordered[0]))
	runtime.submit_actor_position(_route_center(route, ordered[1]))
	runtime.submit_actor_position(_route_center(route, ordered[2]))
	var with_regression := runtime.recovery_query(_route_center(route, ordered[1]), MissionRouteRuntime.RecoveryPolicy.ALLOW_REGRESSION)
	_expect(with_regression == ordered[1], "directed recovery with ALLOW_REGRESSION can return to prior route zone")
	_expect(runtime.current_zone == ordered[2], "regression recovery remains a pure query")
	runtime.free()


func _test_restore_and_corrupt_reject() -> void:
	var runtime := _prepared_runtime(VANCOUVER_ROUTE)
	if runtime == null:
		return

	var ordered := VANCOUVER_ROUTE.ordered_zone_ids()
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, ordered[0]))
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, ordered[1]))
	var before_snapshot := runtime.snapshot()
	_expect(runtime.restore(before_snapshot) == true, "restore from deterministic snapshot succeeds")
	_expect(runtime.current_zone == &"ruse_block", "restore returns to snapshot zone")
	var json_snapshot: Variant = JSON.parse_string(JSON.stringify(before_snapshot))
	_expect(json_snapshot is Dictionary and runtime.restore(json_snapshot), "JSON-decoded numeric snapshot restores successfully")

	var checkpoint_restore: Dictionary = {
		"route_id": String(REUSE_ROUTE_ID),
		"checkpoint_id": "checkpoint_terminal_service",
	}
	_expect(runtime.restore(checkpoint_restore) == true, "restore from checkpoint id succeeds")
	_expect(runtime.current_zone == &"terminal_service", "checkpoint restore lands in terminal_service")

	var corrupt_route := {
		"route_id": String(REUSE_ROUTE_ID),
		"current_zone": "missing_zone",
	}
	var before_zone := runtime.current_zone
	_expect(runtime.restore(corrupt_route) == false, "restore rejects unknown current_zone")
	_expect(runtime.current_zone == before_zone, "corrupt restore leaves state unchanged")
	var before_blank := runtime.snapshot()
	_expect(runtime.restore({}) == false, "restore rejects payload without route ownership")
	_expect(runtime.snapshot() == before_blank, "blank restore cannot reset route state")

	var corrupt_payload_before_current_index := {
		"route_id": String(REUSE_ROUTE_ID),
		"current_zone": "terminal_service",
		"current_index": 1,
		"is_completed": true,
	}
	var before_snapshot_for_mismatch := runtime.snapshot()
	_expect(runtime.restore(corrupt_payload_before_current_index) == false, "restore rejects mismatched current_index and is_completed")
	_expect(runtime.snapshot() == before_snapshot_for_mismatch, "restore mismatch keeps prior runtime state")
	for hostile_index: Variant in [[], {}, "2", NAN, 1.5]:
		var hostile := before_snapshot_for_mismatch.duplicate(true)
		hostile.current_index = hostile_index
		var before_hostile := runtime.snapshot()
		_expect(runtime.restore(hostile) == false, "restore rejects hostile current_index %s" % str(hostile_index))
		_expect(runtime.snapshot() == before_hostile, "hostile restore leaves state unchanged")
	for hostile_completed: Variant in [[], {}, 1, "false"]:
		var hostile := before_snapshot_for_mismatch.duplicate(true)
		hostile.is_completed = hostile_completed
		var before_hostile := runtime.snapshot()
		_expect(runtime.restore(hostile) == false, "restore rejects hostile completion value")
		_expect(runtime.snapshot() == before_hostile, "hostile completion leaves state unchanged")

	var corrupt_visited := {
		"route_id": String(REUSE_ROUTE_ID),
		"current_zone": "terminal_service",
		"visited_zones": ["terminal_service", "waterfront_seawall"],
	}
	_expect(runtime.restore(corrupt_visited) == false, "restore rejects non-prefix visited payload")
	runtime.reset()
	var unstarted := runtime.snapshot()
	_expect(runtime.restore(unstarted), "configured but unstarted snapshot round-trips")
	_expect(runtime.current_zone == &"" and runtime.visited_zones.is_empty(), "unstarted restore remains unstarted")

	runtime.free()


func _test_reset_and_reconfigure_idempotent() -> void:
	var runtime := _prepared_runtime(VANCOUVER_ROUTE)
	if runtime == null:
		return
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, &"downtown_alley"))
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, &"ruse_block"))
	runtime.reset()
	runtime.reset()
	_expect(runtime.current_zone == &"", "reset clears current zone")
	_expect(runtime.visited_zones.is_empty(), "reset clears visited state")

	runtime.configure(VANCOUVER_ROUTE)
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, &"downtown_alley"))
	_expect(runtime.current_zone == &"downtown_alley", "reconfigure after reset remains deterministic")
	runtime.free()


func _test_checkpoint_mapping_and_completion() -> void:
	var runtime := _prepared_runtime(VANCOUVER_ROUTE)
	if runtime == null:
		return
	var completion_count := [0]
	var checkpoint_events: Dictionary = {}

	runtime.checkpoint_available.connect(func(checkpoint_id: StringName, zone_id: StringName) -> void:
		checkpoint_events[String(checkpoint_id)] = String(zone_id)
	)
	runtime.route_completed.connect(func(_final_zone: StringName) -> void:
		completion_count[0] += 1
	)

	var ordered := VANCOUVER_ROUTE.ordered_zone_ids()
	for index in range(ordered.size()):
		runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, ordered[index]))

	_expect(runtime.current_zone == &"harbour_pier", "route reaches final zone")
	_expect(runtime.is_completed == true, "runtime marks completion state")

	for index in range(20):
		runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, &"harbour_pier"))

	_expect(visited_count(checkpoint_events) == 5, "zone entry emits only the five spatial checkpoints")
	_expect(checkpoint_events.has("checkpoint_downtown_alley"), "downtown checkpoint emitted")
	_expect(checkpoint_events.has("checkpoint_ruse_block"), "ruse checkpoint emitted")
	_expect(checkpoint_events.has("checkpoint_waterfront_seawall"), "waterfront checkpoint emitted")
	_expect(checkpoint_events.has("checkpoint_terminal_service"), "terminal checkpoint emitted")
	_expect(checkpoint_events.has("checkpoint_harbour_pier"), "harbour checkpoint emitted")
	_expect(not checkpoint_events.has("checkpoint_harbour_clear"), "harbour clear checkpoint is not awarded before convoy completion")
	_expect(runtime.activate_checkpoint(&"checkpoint_harbour_clear"), "authored convoy completion activates harbour clear checkpoint")
	_expect(checkpoint_events.has("checkpoint_harbour_clear"), "harbour clear checkpoint emits after explicit activation")
	_expect(not runtime.activate_checkpoint(&"checkpoint_harbour_clear"), "authored checkpoint emits once")
	_expect(completion_count[0] == 1, "route_completed emitted exactly once")
	var pre_final := runtime.snapshot()
	pre_final.current_zone = "terminal_service"
	pre_final.current_index = 3
	pre_final.visited_zones = pre_final.visited_zones.slice(0, 4)
	pre_final.checkpoint_id = "checkpoint_terminal_service"
	pre_final.is_completed = false
	_expect(runtime.restore(pre_final), "restore can return to a pre-final checkpoint within the same cycle")
	runtime.submit_actor_position(_zone_center(VANCOUVER_ROUTE, &"harbour_pier"))
	_expect(completion_count[0] == 1, "final-zone re-entry cannot emit route completion twice in one cycle")

	runtime.free()


func _test_stress_simulation_hundred_steps() -> void:
	var runtime := _prepared_runtime(VANCOUVER_ROUTE)
	if runtime == null:
		return

	var ordered := VANCOUVER_ROUTE.ordered_zone_ids()
	var centers: Array[Vector3] = [
		_zone_center(VANCOUVER_ROUTE, ordered[0]),
		_zone_center(VANCOUVER_ROUTE, ordered[1]),
		_zone_center(VANCOUVER_ROUTE, ordered[2]),
		_zone_center(VANCOUVER_ROUTE, ordered[3]),
		_zone_center(VANCOUVER_ROUTE, ordered[4]),
	]
	var completion_count := [0]
	runtime.route_completed.connect(func(_final_zone: StringName) -> void:
		completion_count[0] += 1
	)

	for simulation in range(100):
		runtime.reset()
		if simulation % 13 == 0:
			runtime.recovery_query(centers[0], MissionRouteRuntime.RecoveryPolicy.NONE)
		for index in range(ordered.size()):
			runtime.submit_actor_position(centers[index])
		if simulation % 17 == 0:
			runtime.recovery_query(centers[2], MissionRouteRuntime.RecoveryPolicy.ALLOW_SKIP_INTERMEDIATE)
		_expect(_snapshot_is_valid(runtime.snapshot()), "snapshot remains valid after stress simulation %d" % simulation)
		_expect(runtime.current_zone == &"harbour_pier", "stress simulation %d reaches final route" % simulation)

	_expect(completion_count[0] == 100, "stress simulation emits route completion once per cycle")

	runtime.free()


func _prepared_runtime(route: MissionRouteDefinition) -> MissionRouteRuntime:
	if not _runtime_script_is_loaded():
		return null
	var runtime := _new_runtime()
	if runtime == null:
		return null
	var configured := runtime.configure(route)
	_expect(configured == true, "runtime.configure(route) succeeds")
	if not configured:
		runtime.free()
		return null
	return runtime


func _new_runtime() -> MissionRouteRuntime:
	if not _runtime_script_is_loaded():
		return null
	var runtime := MissionRouteRuntime.new()
	if runtime == null:
		failures.append("MissionRouteRuntime instantiation returned null")
		return null
	runtime.name = "MissionRouteRuntimeTest"
	get_root().add_child(runtime)
	return runtime


func _new_overlap_route() -> MissionRouteDefinition:
	var route := MissionRouteDefinition.new()
	route.route_id = &"overlap_route"
	route.entry_zone_id = &"zone_a"

	var zone_a := MissionRouteZone.new()
	zone_a.zone_id = &"zone_a"
	zone_a.zone_title = "ZONE A"
	zone_a.bounds = AABB(Vector3(0.0, 0.0, 0.0), Vector3(4.0, 2.0, 2.0))
	zone_a.spawn_volumes = [AABB(Vector3(0.0, 0.0, 0.0), Vector3(4.0, 2.0, 2.0))]
	zone_a.patrol_paths = [[Vector3(1.0, 0.0, 1.0), Vector3(3.0, 0.0, 1.0)]]
	zone_a.checkpoint_ids = [&"checkpoint_zone_a"]
	zone_a.surface_ids = [&"surface_a"]
	zone_a.secret_ids = [&"secret_zone_a"]
	zone_a.outgoing_edge_ids = [&"zone_b"]

	var zone_b := MissionRouteZone.new()
	zone_b.zone_id = &"zone_b"
	zone_b.zone_title = "ZONE B"
	zone_b.bounds = AABB(Vector3(2.2, 0.0, 0.0), Vector3(4.0, 2.0, 2.0))
	zone_b.spawn_volumes = [AABB(Vector3(2.2, 0.0, 0.0), Vector3(4.0, 2.0, 2.0))]
	zone_b.patrol_paths = [[Vector3(3.2, 0.0, 1.0), Vector3(5.2, 0.0, 1.0)]]
	zone_b.checkpoint_ids = [&"checkpoint_zone_b"]
	zone_b.surface_ids = [&"surface_b"]
	zone_b.secret_ids = [&"secret_zone_b"]
	zone_b.outgoing_edge_ids = []

	route.zones = [zone_a, zone_b]
	return route


func _new_vertical_route() -> MissionRouteDefinition:
	var route := MissionRouteDefinition.new()
	route.route_id = &"vertical_route"
	route.entry_zone_id = &"lower_lane"

	var lower := MissionRouteZone.new()
	lower.zone_id = &"lower_lane"
	lower.zone_title = "LOWER"
	lower.bounds = AABB(Vector3(0.0, 0.0, 0.0), Vector3(3.0, 2.0, 3.0))
	lower.spawn_volumes = [AABB(Vector3(0.0, 0.0, 0.0), Vector3(3.0, 2.0, 3.0))]
	lower.patrol_paths = [[Vector3(1.0, 0.0, 1.0), Vector3(2.0, 0.0, 2.0)]]
	lower.checkpoint_ids = [&"checkpoint_lower_lane"]
	lower.surface_ids = [&"surface_lower"]
	lower.secret_ids = [&"secret_lower_lane"]
	lower.outgoing_edge_ids = [&"upper_lane"]

	var upper := MissionRouteZone.new()
	upper.zone_id = &"upper_lane"
	upper.zone_title = "UPPER"
	upper.bounds = AABB(Vector3(0.0, 2.6, 0.0), Vector3(3.0, 2.0, 3.0))
	upper.spawn_volumes = [AABB(Vector3(0.0, 2.6, 0.0), Vector3(3.0, 2.0, 3.0))]
	upper.patrol_paths = [[Vector3(1.0, 2.6, 1.0), Vector3(2.0, 3.4, 2.0)]]
	upper.checkpoint_ids = [&"checkpoint_upper_lane"]
	upper.surface_ids = [&"surface_upper"]
	upper.secret_ids = [&"secret_upper_lane"]
	upper.outgoing_edge_ids = []

	route.zones = [lower, upper]
	return route


func _new_directed_recovery_route() -> MissionRouteDefinition:
	var route := MissionRouteDefinition.new()
	route.route_id = &"directed_recovery_route"
	route.entry_zone_id = &"route_start"

	var start := MissionRouteZone.new()
	start.zone_id = &"route_start"
	start.zone_title = "Start"
	start.bounds = AABB(Vector3(0.0, 0.0, 0.0), Vector3(4.0, 2.0, 2.0))
	start.spawn_volumes = [start.bounds]
	start.patrol_paths = [[Vector3(1.0, 0.0, 1.0), Vector3(3.0, 0.0, 1.0)]]
	start.checkpoint_ids = [&"checkpoint_route_start"]
	start.secret_ids = [&"secret_route_start"]
	start.surface_ids = [&"surface_route_start"]
	start.outgoing_edge_ids = [&"route_mid"]

	var mid := MissionRouteZone.new()
	mid.zone_id = &"route_mid"
	mid.zone_title = "Mid"
	mid.bounds = AABB(Vector3(5.0, 0.0, 0.0), Vector3(4.0, 2.0, 2.0))
	mid.spawn_volumes = [mid.bounds]
	mid.patrol_paths = [[Vector3(6.0, 0.0, 1.0), Vector3(8.0, 0.0, 1.0)]]
	mid.secret_ids = [&"secret_route_mid"]
	mid.checkpoint_ids = [&"checkpoint_route_mid"]
	mid.surface_ids = [&"surface_route_mid"]
	mid.outgoing_edge_ids = [&"route_end"]

	var end := MissionRouteZone.new()
	end.zone_id = &"route_end"
	end.zone_title = "End"
	end.bounds = AABB(Vector3(10.0, 0.0, 0.0), Vector3(4.0, 2.0, 2.0))
	end.spawn_volumes = [end.bounds]
	end.patrol_paths = [[Vector3(11.0, 0.0, 1.0), Vector3(13.0, 0.0, 1.0)]]
	end.checkpoint_ids = [&"checkpoint_route_end"]
	end.secret_ids = [&"secret_route_end"]
	end.surface_ids = [&"surface_route_end"]
	end.outgoing_edge_ids = []

	route.zones = [start, mid, end]
	return route


func _bad_route_missing_zone_id() -> MissionRouteDefinition:
	var route := MissionRouteDefinition.new()
	route.route_id = &""
	route.entry_zone_id = &"zone_a"
	return route


func _route_center(route: MissionRouteDefinition, zone_id: StringName) -> Vector3:
	var zone := route.zone_for_id(zone_id)
	_expect(zone != null, "route center resolves for %s" % zone_id)
	if zone == null:
		return Vector3.ZERO
	return zone.bounds.position + (zone.bounds.size * 0.5)


func _zone_center(route: MissionRouteDefinition, zone_id: StringName) -> Vector3:
	return _route_center(route, zone_id)


func _snapshot_is_valid(snapshot: Dictionary) -> bool:
	if snapshot.get("route_id", "") == "":
		return false
	if not snapshot.has("visited_zones") or not (snapshot.get("visited_zones", []) is Array):
		return false
	if not (snapshot.get("is_completed", false) is bool):
		return false
	if int(snapshot.get("current_index", -1)) < -1:
		return false
	if int(snapshot.get("current_index", -1)) >= snapshot.get("visited_zones", []).size():
		return false
	return true


func visited_count(values: Dictionary) -> int:
	var result := 0
	for _value in values.values():
		result += 1
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _cleanup_runtime_nodes() -> void:
	for child in get_root().get_children():
		if child is MissionRouteRuntime:
			child.free()
