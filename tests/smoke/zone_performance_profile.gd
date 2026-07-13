extends SceneTree

const PipelinePrewarmer := preload("res://scripts/core/runtime_pipeline_prewarmer.gd")
const WARMUP_FRAMES := 24
const SAMPLE_FRAMES := 120
const MAX_RENDERED_P95_MSEC := 33.0
const MAX_RENDERED_P99_MSEC := 100.0

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	await _warm_runtime_pipelines()
	await _profile_menu()
	await _profile_mission()
	AudioServer.set_bus_mute(0, false)
	if failures.is_empty():
		print("ZONE PERFORMANCE PROFILE: PASS")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _warm_runtime_pipelines() -> void:
	var audio := ProceduralAudio.new()
	root.add_child(audio)
	audio.prewarm_runtime()
	audio.queue_free()
	await process_frame
	var prewarmer := PipelinePrewarmer.new()
	root.add_child(prewarmer)
	prewarmer.warm(PackedStringArray([
		"res://scenes/enemies/enemy_bolt.tscn",
		"res://scenes/weapons/fetch_projectile.tscn",
		"res://scenes/enemies/mutant_groundskeeper.tscn",
		"res://scenes/enemies/leash_enforcement_drone.tscn",
		"res://scenes/enemies/compliance_hound.tscn",
		"res://scenes/enemies/squirrel_trooper.tscn",
		"res://scenes/enemies/animal_control_walker.tscn",
	]))
	await prewarmer.completed
	prewarmer.queue_free()
	await process_frame


func _profile_menu() -> void:
	var packed := load("res://scenes/menus/main_menu.tscn") as PackedScene
	var menu := packed.instantiate()
	root.add_child(menu)
	await _measure("main_menu")
	menu.queue_free()
	await process_frame


func _profile_mission() -> void:
	var packed := load("res://scenes/levels/episode_1_level_1.tscn") as PackedScene
	var level := packed.instantiate() as EpisodeOneLevel
	root.add_child(level)
	for _frame in 4:
		await process_frame
	var stages := [
		["opening_field", Vector3(0.0, 1.1, 10.0), &"forbidden_field", "PROFILE: OPENING FIELD"],
		["lab", Vector3(0.0, 1.1, -100.0), &"compliance_lab", "PROFILE: LAB"],
		["tunnels", Vector3(0.0, 1.1, -60.0), &"maintenance_tunnels", "PROFILE: TUNNELS"],
		["walker_arena", Vector3(0.0, 1.1, -139.0), &"walker_arena", "PROFILE: WALKER ARENA"],
	]
	for stage in stages:
		_stage_level(level, stage[1], stage[2], stage[3])
		await _measure(stage[0])
	level._finalize_level_completion()
	await _measure("victory")
	level.queue_free()
	await process_frame
	await process_frame


func _stage_level(level: EpisodeOneLevel, position_value: Vector3, zone_id: StringName, label: String) -> void:
	var player := level.player as CobiePlayer
	player.global_position = position_value
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	player.reset_physics_interpolation()
	if "--profile-invulnerable" in OS.get_cmdline_user_args():
		player.health_armor.invulnerable_remaining = 999.0
	level._enter_zone(zone_id, label, player)
	if "--profile-static" in OS.get_cmdline_user_args():
		for enemy in level.get_tree().get_nodes_in_group(&"enemies"):
			enemy.process_mode = Node.PROCESS_MODE_DISABLED


func _measure(label: String) -> void:
	for _frame in WARMUP_FRAMES:
		await process_frame
	var samples: Array[float] = []
	var maximum_draw_calls := 0
	var maximum_objects := 0
	var maximum_nodes := 0
	var maximum_memory := 0
	var maximum_sample := 0
	for sample_index in SAMPLE_FRAMES:
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := float(Time.get_ticks_usec() - started) / 1000.0
		samples.append(elapsed)
		if elapsed >= samples[maximum_sample]:
			maximum_sample = sample_index
		maximum_draw_calls = maxi(maximum_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		maximum_objects = maxi(maximum_objects, int(Performance.get_monitor(Performance.OBJECT_COUNT)))
		maximum_nodes = maxi(maximum_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		maximum_memory = maxi(maximum_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	var ordered := samples.duplicate()
	ordered.sort()
	var total := 0.0
	for sample in samples:
		total += sample
	var average := total / samples.size()
	var p95 := _percentile(ordered, 0.95)
	var p99 := _percentile(ordered, 0.99)
	var maximum: float = ordered.back()
	print("ZONE PROFILE: %s average=%.3fms p95=%.3fms p99=%.3fms max=%.3fms@sample%d draw_calls=%d objects=%d nodes=%d memory=%d" % [label, average, p95, p99, maximum, maximum_sample, maximum_draw_calls, maximum_objects, maximum_nodes, maximum_memory])
	if DisplayServer.get_name() != "headless" and (p95 > MAX_RENDERED_P95_MSEC or p99 > MAX_RENDERED_P99_MSEC):
		failures.append("%s exceeded rendered frame budget (p95 %.3fms, p99 %.3fms)" % [label, p95, p99])


func _percentile(ordered: Array[float], fraction: float) -> float:
	if ordered.is_empty():
		return 0.0
	var index := clampi(ceili(fraction * ordered.size()) - 1, 0, ordered.size() - 1)
	return ordered[index]
