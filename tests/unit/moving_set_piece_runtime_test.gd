extends SceneTree

const MovingSetPieceDefinitionClass = preload("res://scripts/gameplay/moving_set_piece_definition.gd")
const MovingSetPieceRuntimeClass = preload("res://scripts/gameplay/moving_set_piece_runtime.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_physics_independent_motion()
	await _test_stop_pause_and_resume()
	await _test_completion_gates_both_orders()
	await _test_stale_generation_cannot_complete()
	await _test_loop_restarts_with_gate_timing_variants()
	await _test_invalid_definition_fails_closed()
	await _test_external_actor_parent_cleanup()
	await _test_reset_cycles_keep_actor_count()
	if failures.is_empty():
		print("MOVING SET PIECE RUNTIME TESTS: PASS")
		quit(0)
	else:
		for item in failures:
			push_error(item)
		quit(1)


func _test_physics_independent_motion() -> void:
	var definition: Object = _make_definition(
		[Vector3.ZERO, Vector3(4.0, 0.0, 0.0)],
		8.0,
		[0.25, 0.5, 0.75],
		[&"enc", &"enc", &"enc"],
		[],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	var results: Array[Dictionary] = []
	for rate in [30, 60, 120]:
		var result: Dictionary = await _simulate_once(definition, rate, 180)
		_expect(result.get("ok", false), "simulation configured at %d fps started" % [rate])
		_expect(result.get("completed", false), "simulation at %d fps reached path end" % [rate])
		results.append(result)
	if results.size() != 3:
		failures.append("fps-independent suite produced wrong result count")
		return

	var pos0: Vector3 = results[0].get("position", Vector3(-99999.0, -99999.0, -99999.0))
	var pos1: Vector3 = results[1].get("position", Vector3(-99999.0, -99999.0, -99999.0))
	var pos2: Vector3 = results[2].get("position", Vector3(-99999.0, -99999.0, -99999.0))
	_expect(pos0.is_equal_approx(Vector3(4.0, 0.0, 0.0)), "positions independent across 30 fps")
	_expect(pos1.is_equal_approx(pos0), "positions independent across 60 fps")
	_expect(pos2.is_equal_approx(pos0), "positions independent across 120 fps")
	var events0: Array = results[0].get("events", [])
	var events1: Array = results[1].get("events", [])
	var events2: Array = results[2].get("events", [])
	_expect(events0.size() >= 5 and events1.size() >= 5 and events2.size() >= 5, "stop/resume path emitted events at all rates")
	_expect(_path_event_sequence_equal(events0, events1), "event sequence independent across 30/60")
	_expect(_path_event_sequence_equal(events1, events2), "event sequence independent across 60/120")


func _test_stop_pause_and_resume() -> void:
	var definition: Object = _make_definition(
		[Vector3.ZERO, Vector3(4.0, 0.0, 0.0)],
		2.0,
		[0.5, 0.75],
		[&"enc_a", &"enc_b"],
		[],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	var runtime: Variant = _make_runtime(definition)
	var state := {
		"stop_indices": [],
		"encounter_ids": []
	}
	runtime.stop_reached.connect(func(index: int, _fraction: float) -> void: state["stop_indices"].append(index))
	runtime.encounter_requested.connect(func(id: StringName, _gen: int) -> void: state["encounter_ids"].append(id))

	if not runtime.start():
		failures.append("runtime.start() for stop pause test")
		runtime.queue_free()
		return
	var first_stop_seen := await _wait_for_stop(runtime, 0)
	_expect(first_stop_seen, "first stop is observed")
	var resumed_once: bool = runtime.resume_from_stop()
	_expect(resumed_once, "resume call succeeds after first stop")
	var second_stop_seen := await _wait_for_stop(runtime, 1)
	_expect(second_stop_seen, "second stop is observed")
	_expect(state["stop_indices"] == [0, 1], "stop markers emitted once each")
	_expect(runtime.resume_from_stop(), "resume from second stop succeeds")
	var path_done := await _wait_for_path_done(runtime)
	_expect(path_done, "path completes after resume")
	_expect(state["encounter_ids"] == [StringName("enc_a"), StringName("enc_b")], "encounter request order matches stop markers")
	runtime.queue_free()


func _test_completion_gates_both_orders() -> void:
	var definition: Object = _make_definition(
		[Vector3.ZERO, Vector3(4.0, 0.0, 0.0)],
		1.0,
		[0.5],
		[&"enc_gate"],
		[&"mod_gate"],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	var first: Variant = _make_runtime(definition)
	var first_state := {
		"events": 0,
		"generated": -1
	}
	first.completed.connect(func(_id: StringName, _gen: int) -> void:
		first_state["events"] += 1
	)
	first.started.connect(func(_actor: Node3D, gen: int) -> void:
		first_state["generated"] = gen
	)
	if first.start():
		var saw := await _wait_for_stop(first, 0)
		_expect(saw, "completion-gate test first order reached stop")
		first.mark_module_destroyed(&"mod_gate")
		first.mark_encounter_completed(&"enc_gate")
		first.resume_from_stop()
		var completed := await _wait_for_completion(first)
		_expect(completed, "completion after module then encounter")
		_expect(first_state["events"] == 1, "first completion order emits once")
	first.queue_free()

	var second: Variant = _make_runtime(definition)
	var second_state := {
		"events": 0
	}
	second.completed.connect(func(_id: StringName, _gen: int) -> void:
		second_state["events"] += 1
	)
	if second.start():
		var saw := await _wait_for_stop(second, 0)
		_expect(saw, "completion-gate test second order reached stop")
		second.mark_encounter_completed(&"enc_gate")
		second.mark_encounter_completed(&"enc_gate")
		second.resume_from_stop()
		second.mark_module_destroyed(&"mod_gate")
		var completed := await _wait_for_completion(second)
		_expect(completed, "completion after encounter then module")
		second.mark_module_destroyed(&"mod_gate")
		second.mark_encounter_completed(&"enc_gate")
		_expect(second_state["events"] == 1, "completion is idempotent")
	second.queue_free()


func _test_stale_generation_cannot_complete() -> void:
	var definition: Object = _make_definition(
		[Vector3.ZERO, Vector3(4.0, 0.0, 0.0)],
		4.0,
		[0.5],
		[&"enc_stale"],
		[&"mod_stale"],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	var requested_generation: Dictionary = {"value": -1}
	var runtime: Variant = _make_runtime(definition)
	var state := {"completed": false}
	runtime.encounter_requested.connect(func(_id: StringName, gen: int) -> void: requested_generation["value"] = gen)
	runtime.completed.connect(func(_id: StringName, _gen: int) -> void: state["completed"] = true)

	if not runtime.start():
		failures.append("runtime.start() for stale generation test")
		runtime.queue_free()
		return
	var saw := await _wait_for_stop(runtime, 0)
	_expect(saw, "stale test reaches first stop")
	var stale_generation: int = runtime.generation()
	runtime.reset()

	var stale_encounter_ok: bool = runtime.call("mark_encounter_completed", StringName("enc_stale"), stale_generation)
	var stale_module_ok: bool = runtime.call("mark_module_destroyed", StringName("mod_stale"), stale_generation)
	_expect(not stale_encounter_ok, "stale generation encounter mark is ignored")
	_expect(not stale_module_ok, "stale generation module mark is ignored")
	_expect(not state["completed"], "stale completion attempt does not complete synchronously")

	var fresh_generation: int = runtime.generation()
	_expect(fresh_generation != stale_generation, "generation advances on reset")
	var reset_stop := await _wait_for_stop(runtime, 0)
	_expect(reset_stop, "replacement runtime reaches stop")
	runtime.resume_from_stop()
	runtime.call("mark_encounter_completed", StringName("enc_stale"), fresh_generation)
	runtime.call("mark_module_destroyed", StringName("mod_stale"), fresh_generation)
	var completed := await _wait_for_completion(runtime)
	_expect(completed, "replacement completion completes with fresh generation")
	runtime.queue_free()


func _test_loop_restarts_with_gate_timing_variants() -> void:
	var definition: Object = _make_definition(
		[Vector3.ZERO, Vector3(4.0, 0.0, 0.0)],
		2.0,
		[0.5],
		[&"enc_loop"],
		[&"mod_loop"],
		MovingSetPieceDefinitionClass.ResetPolicy.LOOP
	)
	var runtime: Variant = _make_runtime(definition)
	var completed := {
		"count": 0,
		"gens": []
	}
	runtime.completed.connect(func(_id: StringName, gen: int) -> void:
		completed["count"] += 1
		completed["gens"].append(gen)
	)
	if not runtime.start():
		failures.append("runtime.start() for loop-before-end test")
		runtime.queue_free()
		return
	var first_stop := await _wait_for_stop(runtime, 0)
	_expect(first_stop, "loop test reaches first stop")
	var before_mark_enc: bool = runtime.call("mark_encounter_completed", StringName("enc_loop"))
	var before_mark_mod: bool = runtime.call("mark_module_destroyed", StringName("mod_loop"))
	_expect(before_mark_enc, "loop-before-end encounter mark succeeds")
	_expect(before_mark_mod, "loop-before-end module mark succeeds")
	_expect(runtime.resume_from_stop(), "resume from first loop stop")
	var first_completion := await _wait_for_completion(runtime)
	_expect(first_completion, "loop completion emits when gates complete at stop")
	var first_generation := int(completed["gens"][0])
	_expect(await _wait_for_stop(runtime, 0, 240), "loop replacement reaches first stop")
	var loop_generation: int = runtime.generation()
	_expect(loop_generation > first_generation, "loop increments generation on replacement")
	runtime.call("mark_encounter_completed", StringName("enc_loop"), loop_generation)
	runtime.call("mark_module_destroyed", StringName("mod_loop"), loop_generation)
	_expect(runtime.resume_from_stop(), "resume replacement stop")
	var second_completion := await _wait_for_completion(runtime)
	_expect(second_completion, "loop replacement also emits completion")

	runtime.queue_free()

	runtime = _make_runtime(definition)
	completed = {
		"count": 0
	}
	runtime.completed.connect(func(_id: StringName, gen: int) -> void:
		completed["count"] += 1
	)
	if not runtime.start():
		failures.append("runtime.start() for loop-after-end test")
		runtime.queue_free()
		return
	var stop_seen := await _wait_for_stop(runtime, 0)
	_expect(stop_seen, "loop after-end path reaches stop")
	runtime.resume_from_stop()
	var path_done := await _wait_for_path_done(runtime)
	_expect(path_done, "loop after-end path reaches path end without gates")
	var post_end_generation: int = runtime.generation()
	var late_mark_enc: bool = runtime.call("mark_encounter_completed", StringName("enc_loop"), post_end_generation)
	var late_mark_mod: bool = runtime.call("mark_module_destroyed", StringName("mod_loop"), post_end_generation)
	_expect(late_mark_enc, "loop-after-end encounter mark succeeds")
	_expect(late_mark_mod, "loop-after-end module mark succeeds")
	_expect(await _wait_for_stop(runtime, 0, 240), "loop replacement reaches stop after late gate completion")
	runtime.queue_free()


func _test_invalid_definition_fails_closed() -> void:
	var duplicate_markers: Object = _make_definition(
		[Vector3.ZERO, Vector3(1.0, 0.0, 0.0)],
		1.0,
		[0.4, 0.4],
		[&"enc_a", &"enc_b"],
		[],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	_assert_invalid_definition(duplicate_markers, "duplicate stop markers fail configure")

	var overflowing_encounters: Object = _make_definition(
		[Vector3.ZERO, Vector3(1.0, 0.0, 0.0)],
		1.0,
		[0.5],
		[&"enc_a", &"enc_b"],
		[],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	_assert_invalid_definition(overflowing_encounters, "extra encounter ids over stop markers fail configure")


func _test_external_actor_parent_cleanup() -> void:
	var parent: Node3D = Node3D.new()
	root.add_child(parent)
	var definition: Object = _make_definition(
		[Vector3.ZERO, Vector3(3.0, 0.0, 0.0)],
		2.0,
		[],
		[],
		[],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	var runtime: Variant = MovingSetPieceRuntimeClass.new()
	var result: StringName = runtime.call("configure", definition, parent)
	_expect(result == MovingSetPieceRuntimeClass.ERROR_NONE, "external parent configure succeeds")
	root.add_child(runtime)
	if runtime.call("start"):
		var started := await _wait_for_next_actor(parent)
		_expect(started, "external parent receives actor")
		_expect(parent.get_child_count() == 1, "external parent receives one actor")
		runtime.queue_free()
		await process_frame
		await process_frame
		_expect(parent.get_child_count() == 0, "external parent cleaned on runtime exit")
	else:
		failures.append("runtime.start() for external parent cleanup")
	if is_instance_valid(runtime):
		runtime.queue_free()
	parent.queue_free()
	await process_frame


func _test_reset_cycles_keep_actor_count() -> void:
	var definition: Object = _make_definition(
		[Vector3.ZERO, Vector3(4.0, 0.0, 0.0)],
		10.0,
		[],
		[],
		[],
		MovingSetPieceDefinitionClass.ResetPolicy.RETURN_TO_START
	)
	var runtime: Variant = _make_runtime(definition)
	if not runtime.start():
		failures.append("runtime.start() for reset-cycle test")
		runtime.queue_free()
		return
	for step in range(50):
		await physics_frame
		var reset_ok: bool = runtime.reset()
		_expect(reset_ok, "reset cycle %d succeeds" % [step])
		await physics_frame
		_expect(runtime.get_child_count() == 1, "reset cycle %d keeps single actor" % [step])
	for _i in range(20):
		await physics_frame
	runtime.queue_free()


func _simulate_once(source_definition: Object, physics_fps: int, max_frames: int) -> Dictionary:
	var definition: Object = source_definition.duplicate(true)
	var runtime: Variant = _make_runtime(definition)
	var events: Array[String] = []
	var observation: Dictionary = {"actor": null, "path_done": false}
	var observed_pos: Vector3 = Vector3.ZERO

	runtime.started.connect(func(actor: Node3D, gen: int) -> void:
		observation["actor"] = actor
		events.append("started:%d" % gen)
	)
	runtime.path_completed.connect(func(gen: int) -> void:
		observation["path_done"] = true
		events.append("path:%d" % gen)
	)
	runtime.stop_reached.connect(func(index: int, fraction: float) -> void:
		events.append("stop:%d:%.4f" % [index, fraction])
		runtime.resume_from_stop()
	)
	runtime.encounter_requested.connect(func(id: StringName, gen: int) -> void:
		events.append("encounter:%s:%d" % [id, gen])
	)
	runtime.completed.connect(func(_id: StringName, gen: int) -> void:
		events.append("completed:%d" % gen)
	)

	var old_fps: float = Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = float(physics_fps)
	if not runtime.start():
		Engine.physics_ticks_per_second = old_fps
		runtime.queue_free()
		return {"ok": false, "completed": false}
	var remaining: int = max_frames
	while remaining > 0 and not bool(observation["path_done"]):
		await physics_frame
		remaining -= 1
	var actor_ref := observation["actor"] as Object
	if actor_ref != null and is_instance_valid(actor_ref as Object):
		observed_pos = (actor_ref as Node3D).position
	Engine.physics_ticks_per_second = old_fps
	var ok: bool = bool(observation["path_done"]) and actor_ref != null
	runtime.queue_free()
	return {"ok": ok, "completed": bool(observation["path_done"]), "position": observed_pos, "events": events, "actor": actor_ref, "remaining_frames": remaining}


func _wait_for_stop(runtime: Variant, index: int, timeout_frames: int = 180) -> bool:
	var saw: bool = false
	while timeout_frames > 0 and not saw:
		await physics_frame
		timeout_frames -= 1
		var state: Dictionary = runtime.call("current_state")
		if int(state.get("next_stop_index", 0)) > index:
			saw = true
			break
	return saw


func _wait_for_path_done(runtime: Variant, timeout_frames: int = 240) -> bool:
	var state := {"done": false}
	runtime.path_completed.connect(func(_gen: int) -> void: state["done"] = true, CONNECT_ONE_SHOT)
	for _i in range(timeout_frames):
		await physics_frame
		if bool(state["done"]):
			return true
	return false


func _wait_for_next_actor(node: Node, timeout_frames: int = 60) -> bool:
	var has_child: bool = false
	for _i in range(timeout_frames):
		await physics_frame
		if node.get_child_count() > 0:
			has_child = true
			break
	return has_child


func _wait_for_completion(runtime: Variant, timeout_frames: int = 240) -> bool:
	var state := {"done": false}
	runtime.completed.connect(func(_id: StringName, _gen: int) -> void: state["done"] = true, CONNECT_ONE_SHOT)
	for _i in range(timeout_frames):
		await physics_frame
		if bool(state["done"]):
			return true
	return false


func _path_event_sequence_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if a[index] != b[index]:
			return false
	return true


func _make_definition(path_points: Array[Vector3], speed: float, stop_markers: Array[float], encounter_ids: Array[StringName], module_ids: Array[StringName], policy: int) -> Object:
	var definition: Object = MovingSetPieceDefinitionClass.new()
	definition.id = &"moving_set_piece_test"
	definition.actor_scene_path = "res://tests/fixtures/moving_set_piece_probe.tscn"
	definition.path_points = path_points
	definition.speed = speed
	definition.stop_markers = stop_markers
	definition.encounter_trigger_ids = encounter_ids
	definition.destructible_module_ids = module_ids
	definition.completion_event = &"moving_set_piece_test_complete"
	definition.reset_policy = policy
	return definition


func _make_runtime(definition: Object) -> Variant:
	var runtime: Variant = MovingSetPieceRuntimeClass.new()
	var result: StringName = runtime.call("configure", definition, runtime)
	if result != MovingSetPieceRuntimeClass.ERROR_NONE:
		failures.append("runtime configure failed: %s" % result)
	root.add_child(runtime)
	return runtime


func _assert_invalid_definition(definition: Object, label: String) -> void:
	var runtime: Variant = MovingSetPieceRuntimeClass.new()
	var result: StringName = runtime.call("configure", definition)
	if result == MovingSetPieceRuntimeClass.ERROR_NONE:
		failures.append("%s: configure returned ERROR_NONE" % label)
	if result != MovingSetPieceRuntimeClass.ERROR_INVALID_DEFINITION:
		failures.append("%s: wrong error code (%s)" % [label, result])
	runtime.queue_free()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
