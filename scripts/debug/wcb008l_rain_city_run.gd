extends Node
signal run_finished(success: bool, telemetry: Dictionary)
signal invariant_failed(reason: String)
const PRODUCTION_SCENE_PATH := "res://scenes/levels/episode_1_vancouver_waterfront.tscn"
const PRODUCTION_SCENE: PackedScene = preload(PRODUCTION_SCENE_PATH)
const TARGET_RENDER_FPS := 30
const TARGET_PHYSICS_TPS := 60
const TARGET_SECONDS := 90
const TARGET_RENDER_FRAMES := TARGET_RENDER_FPS * TARGET_SECONDS
const TARGET_PHYSICS_TICKS := TARGET_PHYSICS_TPS * TARGET_SECONDS
const MAX_JUMP_DISTANCE_M := 2.0
const WAYPOINT_TOLERANCE_M := 2.5
const FIRE_COOLDOWN_TICKS := 7
const LOOK_TURN_THRESHOLD_RAD := 0.06
const OPENING_GRACE_BUFFER_SECONDS := 0.6
const KEYFRAME_FRAMES: PackedInt32Array = [0, 180, 900, 1600, 2200, 2699]
const KEYFRAME_NAMES: PackedStringArray = [
	"opening_hold",
	"downtown_entry",
	"slice_entry",
	"slice_midline",
	"waterfront_entry",
	"waterfront_midpoint",
]
const ACTION_ALLOWLIST: Array[StringName] = [
	&"move_forward", &"move_backward", &"strafe_left", &"strafe_right",
	&"look_left", &"look_right", &"look_up", &"look_down", &"jump", &"run",
	&"fire_primary", &"fire_secondary", &"reload", &"use",
]
const WAYPOINT_PLAN: Array[Dictionary] = [
	{"zone": &"downtown_alley", "label": "downtown", "phase": 1},
	{"zone": &"ruse_block", "label": "slice", "phase": 2},
	{"zone": &"waterfront_seawall", "label": "waterfront", "phase": 3},
]
const REQUIRED_WAYPOINT_ZONES: PackedStringArray = ["downtown_alley", "ruse_block", "waterfront_seawall"]
var _mission: EpisodeOneVancouverWaterfront
var _player: CobiePlayer
var _player_camera: Camera3D
var _telemetry: Dictionary = {}
var _target_waypoints: Array[Dictionary] = []
var _current_waypoint_index := 0
var _run_started := false
var _run_finished := false
var _run_ready_tick := -1
var _run_reason := ""
var _physics_ticks := 0
var _render_frames := 0
var _failure_reasons: Array[String] = []
var _action_state: Dictionary = {}
var _action_event_log: Array[Dictionary] = []
var _edge_release_queue: Array[StringName] = []
var _opening_protection_remaining := -1.0
var _next_fire_tick := 0
var _last_player_position := Vector3.ZERO
var _has_last_player_position := false
var _keyframe_hits: Array[Dictionary] = []
var _next_keyframe_index := 0
var _waypoint_hits: Array[Dictionary] = []
var _waypoint_observations: Array[Dictionary] = []
var _max_player_displacement_m := 0.0
static func render_fps() -> int:
	return TARGET_RENDER_FPS
static func physics_tps() -> int:
	return TARGET_PHYSICS_TPS
static func run_seconds() -> int:
	return TARGET_SECONDS
static func expected_render_frames() -> int:
	return TARGET_RENDER_FRAMES
static func expected_physics_ticks() -> int:
	return TARGET_PHYSICS_TICKS
static func action_allowlist() -> Array[StringName]:
	var actions: Array[StringName] = []
	for action in ACTION_ALLOWLIST:
		actions.append(action)
	return actions
static func conservative_displacement_bound() -> float:
	return MAX_JUMP_DISTANCE_M
static func keyframe_frames() -> PackedInt32Array:
	return KEYFRAME_FRAMES.duplicate()
static func keyframe_plan() -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	for i in range(KEYFRAME_FRAMES.size()):
		plan.append({"name": KEYFRAME_NAMES[i], "frame": int(KEYFRAME_FRAMES[i])})
	return plan
static func required_waypoint_zones() -> PackedStringArray:
	return REQUIRED_WAYPOINT_ZONES.duplicate()
static func required_keyframe_names() -> PackedStringArray:
	return KEYFRAME_NAMES.duplicate()
static func waypoint_plan() -> Array[Dictionary]:
	var waypoints: Array[Dictionary] = []
	for step in WAYPOINT_PLAN:
		waypoints.append(step.duplicate(true))
	return waypoints
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = TARGET_RENDER_FPS
	Engine.physics_ticks_per_second = TARGET_PHYSICS_TPS
	_telemetry = {
		"run_started": false,
		"run_ended": false,
		"success": true,
		"run_reason": "",
		"scene_path": PRODUCTION_SCENE_PATH,
		"physics_ticks": 0,
		"render_frames": 0,
		"render_fps": TARGET_RENDER_FPS,
		"physics_tps": TARGET_PHYSICS_TPS,
		"target_seconds": TARGET_SECONDS,
		"target_render_frames": TARGET_RENDER_FRAMES,
		"target_physics_ticks": TARGET_PHYSICS_TICKS,
		"conservative_jump_bound": MAX_JUMP_DISTANCE_M,
		"action_allowlist": action_allowlist(),
		"waypoint_plan": waypoint_plan(),
		"keyframe_plan": keyframe_plan(),
		"failure_reasons": _failure_reasons,
		"start_tick": -1,
		"end_tick": -1,
		"death_tick": -1,
		"level_completed_tick": -1,
		"start_position": Vector3.ZERO,
		"last_position": Vector3.ZERO,
		"input_event_count": 0,
		"input_events": _action_event_log,
		"final_input_state": {},
		"max_observed_displacement_m": 0.0,
	}
	var failures := _validate_contract_requirements()
	if not failures.is_empty():
		for reason in failures:
			_record_failure(reason)
		_fail_closed()
		return
	_mission = PRODUCTION_SCENE.instantiate() as EpisodeOneVancouverWaterfront
	if _mission == null:
		_record_failure("Could not instantiate the production Rain City scene")
		_fail_closed()
		return
	if _mission.scene_file_path != PRODUCTION_SCENE_PATH:
		_record_failure("Instantiated scene is not the production target")
		_fail_closed()
		return
	_mission.level_ready.connect(_on_level_ready)
	_mission.level_completed.connect(_on_level_completed)
	add_child(_mission)
func _validate_contract_requirements() -> Array[String]:
	var failures: Array[String] = []
	if TARGET_RENDER_FPS != 30:
		failures.append("Render target FPS must be 30")
	if TARGET_PHYSICS_TPS != 60:
		failures.append("Physics target TPS must be 60")
	if TARGET_SECONDS != 90:
		failures.append("Run duration must be 90")
	if TARGET_RENDER_FRAMES != TARGET_RENDER_FPS * TARGET_SECONDS:
		failures.append("Render target-frame math invalid")
	if TARGET_PHYSICS_TICKS != TARGET_PHYSICS_TPS * TARGET_SECONDS:
		failures.append("Physics tick math invalid")
	if KEYFRAME_FRAMES.size() != 6:
		failures.append("Required keyframe count must be 6")
	if not _is_strictly_increasing(KEYFRAME_FRAMES):
		failures.append("Keyframe frame values must be strictly increasing")
	if KEYFRAME_FRAMES != PackedInt32Array([0, 180, 900, 1600, 2200, 2699]):
		failures.append("Keyframe frame values must be canonical")
	for action in action_allowlist():
		if not InputMap.has_action(action):
			failures.append("Missing required action: %s" % action)
	if PRODUCTION_SCENE_PATH != "res://scenes/levels/episode_1_vancouver_waterfront.tscn":
		failures.append("Production scene path constant drift")
	return failures
func runtime_telemetry() -> Dictionary:
	return _telemetry
func _on_level_ready(player_node: Node3D) -> void:
	if _run_finished:
		return
	if not is_instance_valid(player_node) or not (player_node is CobiePlayer):
		_record_failure("level_ready emitted invalid player")
		_fail_closed()
		return
	_player = player_node as CobiePlayer
	_player_camera = _player.get_node_or_null("Head/Camera") as Camera3D
	if _player_camera == null:
		_record_failure("Production player camera is missing")
		_fail_closed()
		return
	if not _bind_waypoints_to_mission():
		_fail_closed()
		return
	_player.died.connect(_on_player_died)
	_run_started = true
	_run_ready_tick = _physics_ticks
	_run_reason = "running"
	_telemetry["run_started"] = true
	_telemetry["start_tick"] = _physics_ticks
	_telemetry["start_position"] = _player.global_position
	_last_player_position = _player.global_position
	_has_last_player_position = true
	_opening_protection_remaining = maxf(_player.health_armor.invulnerable_remaining, 0.0) + OPENING_GRACE_BUFFER_SECONDS
	_next_fire_tick = 0
	_max_player_displacement_m = 0.0
	_next_keyframe_index = 0
	for action in action_allowlist():
		_action_state[action] = false
func _physics_process(_delta: float) -> void:
	if _run_finished:
		return
	_telemetry["physics_ticks"] = _physics_ticks
	_render_frames = _projected_render_frame(_physics_ticks)
	_telemetry["render_frames"] = _render_frames
	_update_keyframe_hits()
	if not _run_started:
		return
	if _physics_ticks >= TARGET_PHYSICS_TICKS:
		_finish_run()
		return
	if _player == null or not is_instance_valid(_player):
		_record_failure("Player became invalid")
		_fail_closed()
		return
	if _opening_protection_remaining > 0.0:
		_opening_protection_remaining -= 1.0 / float(TARGET_PHYSICS_TPS)
	if _player.is_dead:
		if _telemetry["death_tick"] == -1:
			_telemetry["death_tick"] = _physics_ticks
		_record_failure("Player died before completion")
		_fail_closed()
		return
	if _check_displacement_invariant():
		_record_failure("Displacement invariant exceeded %0.2f m per physics tick" % MAX_JUMP_DISTANCE_M)
		_fail_closed()
		return
	_flush_edge_releases()
	_apply_inputs(_compute_desired_actions())
	_last_player_position = _player.global_position
	_has_last_player_position = true
	_telemetry["last_position"] = _last_player_position
	_telemetry["current_zone_plan_index"] = _current_waypoint_index
	_telemetry["waypoint_hits"] = _waypoint_hits
	_telemetry["waypoint_observations"] = _waypoint_observations
	_telemetry["max_observed_displacement_m"] = _max_player_displacement_m
	_physics_ticks += 1
func _on_level_completed(summary: Dictionary) -> void:
	if _telemetry["level_completed_tick"] < 0:
		_telemetry["level_completed_tick"] = _physics_ticks
		_telemetry["level_completed_summary"] = summary
func _on_player_died(_source: Node) -> void:
	if _telemetry["death_tick"] == -1:
		_telemetry["death_tick"] = _physics_ticks
func _bind_waypoints_to_mission() -> bool:
	_target_waypoints = []
	_current_waypoint_index = 0
	_waypoint_hits = []
	_waypoint_observations = []
	var manifest := _mission.content_manifest
	if manifest == null or manifest.route_definition == null:
		_record_failure("Mission manifest route definition is missing")
		return false
	var route_def := manifest.route_definition
	var y_axis := _player.global_position.y
	for step in waypoint_plan():
		var zone_id: StringName = step.get("zone", &"")
		var zone := route_def.zone_for_id(zone_id)
		if zone == null:
			_record_failure("Waypoint zone missing from route: %s" % zone_id)
			return false
		var target = zone.bounds.get_center()
		target.y = y_axis
		var record := step.duplicate(true)
		record["target_position"] = target
		_target_waypoints.append(record)
	var required := required_waypoint_zones()
	for i in range(required.size()):
		if i >= _target_waypoints.size() or _target_waypoints[i].get("zone", &"") != StringName(required[i]):
			_record_failure("Waypoint schedule does not match required Rain City order at index %d: expected %s" % [i, required[i]])
			return false
	return true
func _compute_desired_actions() -> Dictionary:
	var desired: Dictionary = {}
	for action in action_allowlist():
		desired[action] = false
	if _target_waypoints.is_empty():
		desired[&"run"] = true
		return desired
	while _current_waypoint_index < _target_waypoints.size():
		var step := _target_waypoints[_current_waypoint_index]
		var distance := _distance_to_waypoint(step)
		if distance <= WAYPOINT_TOLERANCE_M:
			_record_waypoint_hit(step, distance)
			_current_waypoint_index += 1
			continue
		break
	if _current_waypoint_index >= _target_waypoints.size():
		desired[&"run"] = true
		return desired
	var target := (_target_waypoints[_current_waypoint_index].get("target_position", Vector3.ZERO) as Vector3) - _player.global_position
	target.y = 0.0
	if target.is_equal_approx(Vector3.ZERO):
		desired[&"run"] = true
		return desired
	var local := _player.global_transform.basis.inverse() * target.normalized()
	if local.z < -0.2:
		desired[&"move_forward"] = true
	if local.z > 0.2:
		desired[&"move_backward"] = true
	if local.x > 0.2:
		desired[&"strafe_right"] = true
	if local.x < -0.2:
		desired[&"strafe_left"] = true
	var forward_flat := (-_player.global_basis.z).normalized()
	var yaw_delta := forward_flat.signed_angle_to(target.normalized(), Vector3.UP)
	if absf(yaw_delta) > LOOK_TURN_THRESHOLD_RAD:
		desired[&"look_right"] = yaw_delta > 0.0
		desired[&"look_left"] = yaw_delta < 0.0
	desired[&"run"] = true
	if _opening_protection_remaining <= 0.0 and _physics_ticks >= _next_fire_tick:
		desired[&"fire_primary"] = true
		_next_fire_tick = _physics_ticks + FIRE_COOLDOWN_TICKS
	if _opening_protection_remaining <= 0.0 and _physics_ticks == TARGET_PHYSICS_TICKS / 2:
		desired[&"use"] = true
	if _opening_protection_remaining <= 0.0 and _physics_ticks % 1200 == 0:
		desired[&"reload"] = true
	return desired
func _record_waypoint_hit(step: Dictionary, distance: float) -> void:
	if step.is_empty() or _player == null or not is_instance_valid(_player):
		return
	if distance > WAYPOINT_TOLERANCE_M:
		return
	_waypoint_hits.append({
		"frame": _render_frames,
		"tick": _physics_ticks,
		"zone": step.get("zone", &""),
		"label": step.get("label", ""),
		"phase": step.get("phase", 0),
		"distance": float(distance),
		"status": "waypoint_hit",
	})
	_telemetry["waypoint_hits"] = _waypoint_hits
func _record_waypoint_miss(step: Dictionary, distance: float) -> void:
	if step.is_empty():
		return
	_waypoint_observations.append({
		"frame": _render_frames,
		"tick": _physics_ticks,
		"zone": step.get("zone", &""),
		"label": step.get("label", ""),
		"phase": step.get("phase", 0),
		"distance": float(distance),
		"status": "waypoint_miss",
	})
	_telemetry["waypoint_observations"] = _waypoint_observations
func _distance_to_waypoint(step: Dictionary) -> float:
	if _player == null or not is_instance_valid(_player):
		return INF
	return _player.global_position.distance_to(step.get("target_position", Vector3.ZERO))
func _apply_inputs(desired: Dictionary) -> void:
	var edge_actions: Array[StringName] = [&"fire_primary", &"reload", &"use", &"fire_secondary"]
	for action in action_allowlist():
		var want := bool(desired.get(action, false))
		var prev := bool(_action_state.get(action, false))
		if edge_actions.has(action):
			if want and not prev:
				_set_action_pressed(action, true)
				_action_state[action] = true
				_edge_release_queue.append(action)
		elif want != prev:
			_set_action_pressed(action, want)
			_action_state[action] = want
func _flush_edge_releases() -> void:
	if _edge_release_queue.is_empty():
		return
	for action in _edge_release_queue:
		if bool(_action_state.get(action, false)):
			_set_action_pressed(action, false)
		_action_state[action] = false
	_edge_release_queue = []
func _update_keyframe_hits() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	while _next_keyframe_index < KEYFRAME_FRAMES.size():
		var keyframe_frame := int(KEYFRAME_FRAMES[_next_keyframe_index])
		if _render_frames < keyframe_frame:
			break
		_keyframe_hits.append({
			"frame": keyframe_frame,
			"name": String(KEYFRAME_NAMES[_next_keyframe_index]),
			"position": _player.global_position,
			"tick": _physics_ticks,
		})
		_next_keyframe_index += 1
	_telemetry["keyframe_hits"] = _keyframe_hits
func _check_displacement_invariant() -> bool:
	if not _has_last_player_position or _physics_ticks == _run_ready_tick or _player == null or not is_instance_valid(_player):
		return false
	var delta := _player.global_position - _last_player_position
	var displacement := delta.length()
	if displacement > _max_player_displacement_m:
		_max_player_displacement_m = displacement
	if displacement > MAX_JUMP_DISTANCE_M:
		return true
	return false
func _route_completion_state() -> bool:
	var complete := true
	var hit_by_zone: Dictionary = {}
	for hit in _waypoint_hits:
		hit_by_zone[StringName(hit.get("zone", &""))] = true
	for zone_id in REQUIRED_WAYPOINT_ZONES:
		if hit_by_zone.has(StringName(zone_id)):
			continue
		complete = false
		_record_failure("Route checkpoint missed: %s" % zone_id)
		var miss_record := {}
		for step in _target_waypoints:
			if StringName(step.get("zone", &"")) == StringName(zone_id):
				miss_record = step
				break
		var miss_distance := INF
		if is_instance_valid(_player):
			miss_distance = _distance_to_waypoint(miss_record)
		_record_waypoint_miss(miss_record, miss_distance)
	return complete
func _finish_run() -> void:
	if _run_finished:
		return
	if _physics_ticks != TARGET_PHYSICS_TICKS:
		_record_failure("Run ended at unexpected tick")
		_fail_closed()
		return
	_run_reason = "duration_complete"
	var route_complete := _route_completion_state()
	_release_all_actions()
	_render_frames = TARGET_RENDER_FRAMES
	_telemetry["render_frames"] = _render_frames
	_emit_telemetry_signal(route_complete)
func _release_all_actions() -> void:
	for action in action_allowlist():
		if bool(_action_state.get(action, false)):
			_set_action_pressed(action, false)
		_action_state[action] = false
	for action in _edge_release_queue:
		_set_action_pressed(action, false)
		_action_state[action] = false
	_edge_release_queue = []
func _fail_closed(reason := "") -> void:
	if reason != "":
		_record_failure(reason)
	if _run_reason == "":
		_run_reason = "fail_closed"
	release_and_finish(false)
func _emit_telemetry_signal(success: bool) -> void:
	if _run_finished:
		return
	_run_finished = true
	_run_started = false
	_telemetry["run_ended"] = true
	_telemetry["success"] = success
	_telemetry["end_tick"] = _physics_ticks
	_telemetry["run_reason"] = _run_reason
	_telemetry["final_input_state"] = _snapshot_action_state()
	_telemetry["failure_reasons"] = _failure_reasons
	run_finished.emit(success, _telemetry)
	if not success and not _is_route_only_failure():
		for reason in _failure_reasons:
			invariant_failed.emit(reason)
func release_and_finish(success: bool) -> void:
	_release_all_actions()
	_emit_telemetry_signal(success)
func _snapshot_action_state() -> Dictionary:
	var state: Dictionary = {}
	for action in action_allowlist():
		state[action] = bool(_action_state.get(action, false))
	return state
func _set_action_pressed(action: StringName, pressed: bool) -> void:
	var input_event := InputEventAction.new()
	input_event.action = action
	input_event.pressed = pressed
	Input.parse_input_event(input_event)
	_action_event_log.append({"tick": _physics_ticks, "action": action, "pressed": pressed})
	_telemetry["input_events"] = _action_event_log
	_telemetry["input_event_count"] = _action_event_log.size()
func _record_failure(reason: String) -> void:
	if _failure_reasons.has(reason):
		return
	_failure_reasons.append(reason)
func _projected_render_frame(tick: int) -> int:
	return min(TARGET_RENDER_FRAMES, int(floor(float(tick) * float(TARGET_RENDER_FPS) / float(TARGET_PHYSICS_TPS))))
func _is_route_only_failure() -> bool:
	if _failure_reasons.is_empty():
		return false
	for reason in _failure_reasons:
		if not reason.begins_with("Route checkpoint missed:"):
			return false
	return true
func _is_strictly_increasing(values: PackedInt32Array) -> bool:
	if values.size() < 2:
		return false
	for index in range(values.size() - 1):
		if values[index] >= values[index + 1]:
			return false
	return true
func _exit_tree() -> void:
	_release_all_actions()
