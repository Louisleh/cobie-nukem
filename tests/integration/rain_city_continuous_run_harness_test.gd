extends SceneTree

const HARNESS_SCENE_PATH := "res://scenes/debug/wcb008l_rain_city_run.tscn"
const HARNESS_SCRIPT_PATH := "res://scripts/debug/wcb008l_rain_city_run.gd"

const FORBIDDEN_DIRECT_CONTROL_TOKENS := [
	" global_position = ",
	"global_position += ",
	" global_transform = ",
	"global_transform += ",
	"respawn(",
	"reset_physics_interpolation(",
	"activate_zone(",
	"set_route_gate_open(",
	"record_objective(",
	"_mission_runtime.activate_zone(",
	"_mission_runtime.encounters",
	"restart_from_checkpoint(",
	"_spawn_registry.clear_zone(",
	"_mark_pending_waypoints",
	"_waypoint_target_tick",
	"_clear_player_impact_effect_pool",
	"_impact_effects",
]

var _telemetry: Dictionary = {}
var _failures: Array[String] = []
var _run_finished := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_contract_math()
	_test_actions_and_tokens()
	_test_waypoint_and_schedule_coverage()
	if _failures.is_empty():
		await _run_harness_and_assert()
	_finish()

func _test_contract_math() -> void:
	var source := FileAccess.get_file_as_string(HARNESS_SCRIPT_PATH)
	var harness_script: GDScript = load(HARNESS_SCRIPT_PATH) as GDScript
	if harness_script == null:
		_failures.append("Could not preload harness script")
		return
	if source == "":
		_failures.append("Could not read harness source")
		return

	var fps := int(harness_script.render_fps())
	var tps := int(harness_script.physics_tps())
	var seconds := int(harness_script.run_seconds())
	var expected_frames := int(harness_script.expected_render_frames())
	var expected_ticks := int(harness_script.expected_physics_ticks())
	_expect(fps == 30, "render_fps() must be exactly 30")
	_expect(tps == 60, "physics_tps() must be exactly 60")
	_expect(seconds == 90, "run_seconds() must be exactly 90")
	_expect(expected_frames == fps * seconds, "expected_render_frames() must equal fps*seconds")
	_expect(expected_ticks == tps * seconds, "expected_physics_ticks() must equal tps*seconds")

	var keyframe_plan: Array[Dictionary] = harness_script.keyframe_plan()
	var keyframe_names: PackedStringArray = harness_script.required_keyframe_names()
	var keyframe_frames: PackedInt32Array = harness_script.keyframe_frames()
	var waypoint_plan: Array[Dictionary] = harness_script.waypoint_plan()
	_expect(keyframe_plan.size() == 6, "keyframe_plan() must define six entries")
	_expect(keyframe_names.size() == 6, "required keyframe names include six entries")
	_expect(waypoint_plan.size() >= 3, "waypoint_plan() must define multiple ordered waypoints")
	_expect(!keyframe_plan.is_empty(), "keyframe_plan() must be non-empty")
	if keyframe_plan.is_empty():
		return
	var previous_frame := -1
	for index in range(keyframe_plan.size()):
		var keyframe := keyframe_plan[index]
		var frame := int(keyframe.get("frame", -1))
		var name := String(keyframe.get("name", ""))
		var expected_name := String(keyframe_names[index])
		_expect(name == expected_name, "keyframe_%d has canonical name: %s" % [index, expected_name])
		_expect(frame > previous_frame, "keyframe frame is strictly increasing: %d at index %d" % [frame, index])
		_expect(frame == keyframe_frames[index], "keyframe_%d uses contract frame index %d" % [index, frame])
		previous_frame = frame

	var action_plan: Array[StringName] = harness_script.action_allowlist()
	_expect(action_plan.size() >= 8, "action_allowlist includes movement, turning, fire, reload, use")
	var required_actions: Dictionary = {
		"move_forward": true,
		"move_backward": true,
		"strafe_left": true,
		"strafe_right": true,
		"look_left": true,
		"look_right": true,
		"jump": true,
		"run": true,
		"fire_primary": true,
		"reload": true,
		"use": true,
	}
	for required in required_actions.keys():
		_expect(action_plan.has(StringName(required)), "action_allowlist contains %s" % required)
	for action in action_plan:
		_expect(not _contains_duplicate(action_plan, action), "action_allowlist has no duplicate entry for %s" % action)

func _test_actions_and_tokens() -> void:
	var harness_script: GDScript = load(HARNESS_SCRIPT_PATH) as GDScript
	var source := FileAccess.get_file_as_string(HARNESS_SCRIPT_PATH)
	if source == "":
		_failures.append("Harness script body is empty or unreadable")
		return
	for action in harness_script.action_allowlist():
		_expect(InputMap.has_action(action), "InputMap contains allowlisted action: %s" % action)
	for token in FORBIDDEN_DIRECT_CONTROL_TOKENS:
		_expect(source.find(token) == -1, "Forbidden direct-control source token must be absent: %s" % token)

func _test_waypoint_and_schedule_coverage() -> void:
	var harness_script: GDScript = load(HARNESS_SCRIPT_PATH) as GDScript
	var waypoints: Array[Dictionary] = harness_script.waypoint_plan()
	var zone_hits: PackedStringArray = harness_script.required_waypoint_zones()
	_expect(waypoints.size() == zone_hits.size(), "Waypoint schedule length matches required Rain City route checkpoints")
	for index in range(zone_hits.size()):
		var step: Dictionary = waypoints[index]
		_expect(step.get("zone", &"") == StringName(zone_hits[index]), "Waypoint %d keeps canonical zone order %s" % [index, zone_hits[index]])

func _run_harness_and_assert() -> void:
	var harness_scene: PackedScene = load(HARNESS_SCENE_PATH)
	if harness_scene == null:
		_failures.append("Could not load harness scene")
		return

	var harness_node: Node = harness_scene.instantiate()
	if harness_node == null:
		_failures.append("Could not instantiate harness scene")
		return

	harness_node.connect("run_finished", Callable(self, "_on_harness_run_finished"))
	harness_node.connect("invariant_failed", Callable(self, "_on_harness_invariant_failed"))
	root.add_child(harness_node)

	var harness_script: GDScript = load(HARNESS_SCRIPT_PATH) as GDScript
	var max_frames := int(harness_script.expected_render_frames()) + 240
	var safety := 0
	while not _run_finished and safety < max_frames:
		await process_frame
		safety += 1
	if not _run_finished:
		_failures.append("Harness did not complete within bounded frame budget")
		return
	harness_node.call_deferred("queue_free")
	await process_frame
	await process_frame

	var expected_frames := int(harness_script.expected_render_frames())
	var expected_ticks := int(harness_script.expected_physics_ticks())
	var success := bool(_telemetry.get("success", false))
	var run_reason := String(_telemetry.get("run_reason", ""))
	_expect(_telemetry.get("run_ended", false) == true, "Harness run reports completion")
	_expect(int(_telemetry.get("render_frames", 0)) == expected_frames, "Render frame count matches contract")
	_expect(int(_telemetry.get("physics_ticks", 0)) == expected_ticks, "Physics tick count matches contract")
	_expect(int(_telemetry.get("end_tick", 0)) == expected_ticks, "End tick lands on the contract tick")
	_expect(int(_telemetry.get("max_observed_displacement_m", 0)) >= 0, "Max observed displacement is recorded")

	var failure_reasons: Array = _telemetry.get("failure_reasons", []) as Array
	var route_failure_reasons: Array[String] = []
	var non_route_failure_reasons: Array[String] = []
	for raw in failure_reasons:
		var reason := String(raw)
		if _is_route_only_failure(reason):
			route_failure_reasons.append(reason)
		else:
			non_route_failure_reasons.append(reason)

	if success:
		_expect(route_failure_reasons.is_empty(), "Successful run has no route miss failures")
		_expect(non_route_failure_reasons.is_empty(), "Successful run has no non-route failure reasons")
	else:
		_expect(route_failure_reasons.size() > 0, "Fail-closed run must fail for route incompletion")
		_expect(non_route_failure_reasons.is_empty(), "Fail-closed run cannot include non-route failures")
		_expect(run_reason == "duration_complete", "Fail-closed run must complete at exact duration")
		_expect(int(_telemetry.get("start_tick", -1)) == 0, "Run starts at contract tick 0")
		for reason in route_failure_reasons:
			print("TRUTHFUL_ROUTE_MISS: " + reason)

	var action_state := _telemetry.get("final_input_state", {}) as Dictionary
	for action in action_state.keys():
		_expect(bool(action_state[action]) == false, "Final input state releases all actions (%s)" % action)

	var action_events := _telemetry.get("input_events", []) as Array
	_expect(action_events.size() > 0, "Runtime recorded action events")

	var keyframe_hits := _telemetry.get("keyframe_hits", []) as Array
	var plan: Array[Dictionary] = harness_script.keyframe_plan()
	var keyframe_sample_count := 0
	for plan_entry in plan:
		var key_name := String(plan_entry.get("name", ""))
		var key_frame := int(plan_entry.get("frame", -1))
		var matched := false
		for entry in keyframe_hits:
			if String((entry as Dictionary).get("name", "")) == key_name:
				matched = true
				keyframe_sample_count += 1
				_expect(int((entry as Dictionary).get("frame", -1)) == key_frame, "Keyframe %s recorded at rendered-frame %d" % [key_name, key_frame])
				_expect(int((entry as Dictionary).get("tick", -1)) >= 0, "Keyframe %s recorded with tick" % key_name)
				break
		_expect(matched, "Keyframe reached in runtime telemetry: %s" % key_name)
	_expect(keyframe_sample_count == plan.size(), "Runtime captured all keyframe samples")

	var waypoints: Array[Dictionary] = harness_script.waypoint_plan()
	var required_waypoints: PackedStringArray = harness_script.required_waypoint_zones()
	var waypoint_hits := _telemetry.get("waypoint_hits", []) as Array
	var waypoint_observations := _telemetry.get("waypoint_observations", []) as Array
	var hit_zones: Dictionary = {}
	var observed_misses: Dictionary = {}
	for hit in waypoint_hits:
		var entry := hit as Dictionary
		var hit_zone := StringName(entry.get("zone", &""))
		var status := String(entry.get("status", "waypoint_hit"))
		if status == "waypoint_hit":
			hit_zones[hit_zone] = true
	for observation in waypoint_observations:
		var entry := observation as Dictionary
		if String(entry.get("status", "")) == "waypoint_miss":
			observed_misses[StringName(entry.get("zone", &""))] = true
			var distance := float(entry.get("distance", -1.0))
			var tick := int(entry.get("tick", -1))
			var frame := int(entry.get("frame", -1))
			_expect(distance >= 0.0, "Waypoint miss includes actual distance")
			_expect(tick >= 0, "Waypoint miss includes tick")
			_expect(frame >= 0, "Waypoint miss includes rendered frame")

	for zone in required_waypoints:
		var zone_id := StringName(zone)
		if success:
			_expect(hit_zones.has(zone_id), "Waypoint zone reached during telemetry: %s" % zone)
		else:
			if not hit_zones.has(zone_id):
				_expect(observed_misses.has(zone_id), "Waypoint miss observation for %s present when run is incomplete" % zone)

func _on_harness_run_finished(success: bool, telemetry: Dictionary) -> void:
	_run_finished = true
	_telemetry = telemetry

func _on_harness_invariant_failed(reason: String) -> void:
	if not _is_route_only_failure(reason):
		_failures.append("Harness invariant_failed: " + reason)

func _is_route_only_failure(reason: String) -> bool:
	return reason.begins_with("Route checkpoint missed:")

func _finish() -> void:
	if _failures.is_empty():
		print("RAIN CITY CONTINUOUS RUN HARNESS TEST: PASS")
		call_deferred("quit")
	else:
		for failure in _failures:
			push_error(failure)
		call_deferred("quit", 1)

func _contains_duplicate(values: Array[StringName], target: StringName) -> bool:
	var count := 0
	for value in values:
		if value == target:
			count += 1
	return count > 1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
