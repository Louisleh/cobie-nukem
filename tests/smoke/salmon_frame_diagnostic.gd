extends SceneTree

## Debug-only native timing diagnosis with mapped input; not a GPU-time pass.
## Frame intervals include OS/presentation waits; Performance monitors are
## sampled snapshots, not independently measured per-frame CPU/GPU durations.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
const WARMUP := 45
const SAMPLES := 240
var trace_file := ""
var trace_rows: Array[Dictionary] = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--trace-file="):
			trace_file = argument.trim_prefix("--trace-file=")
	call_deferred("_run")

func _run() -> void:
	seed(20260924)
	if "--no-vsync" in OS.get_cmdline_user_args():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await process_frame
	var menu := (load("res://scenes/menus/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await _measure("menu", false)
	menu.queue_free()
	for index in 12: await process_frame
	var level := LEVEL.instantiate() as EpisodeOneLevel
	root.add_child(level)
	for index in 12: await process_frame
	for pause_menu in level.find_children("*", "PauseMenu", true, false):
		pause_menu.set_suppressed(true)
	var player := level.player as CobiePlayer
	if player == null or player.weapons.is_empty():
		push_error("FRAME DIAGNOSTIC: missing real player or weapon")
		quit(1)
		return
	await _measure("opening_idle", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var ammo := (player.weapons[player.current_weapon_index] as WeaponBase).ammo
	await _measure("opening_move_fire", true)
	Input.action_release(&"move_forward")
	var final_ammo := (player.weapons[player.current_weapon_index] as WeaponBase).ammo
	var final_z := player.global_position.z
	print("FRAME DIAGNOSTIC CONTACT: ammo=%d->%d end_z=%.3f" % [ammo, final_ammo, final_z])
	for audio in level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
	level.queue_free()
	for index in 12: await process_frame
	if final_ammo != ammo - 1 or final_z > 8.0:
		push_error("FRAME DIAGNOSTIC: mapped input did not drive player and weapon")
		quit(1)
		return
	if not trace_file.is_empty():
		var output := FileAccess.open(trace_file, FileAccess.WRITE)
		if output == null:
			push_error("FRAME DIAGNOSTIC: trace file could not be opened")
			quit(1)
			return
		output.store_string(JSON.stringify({"source": "salmon_frame_diagnostic", "samples_per_stage": SAMPLES, "rows": trace_rows}))
		output.close()
		print("FRAME DIAGNOSTIC TRACE: %s rows=%d" % [trace_file, trace_rows.size()])
	print("SALMON FRAME DIAGNOSTIC: MEASURED (NOT A PERFORMANCE PASS)")
	quit(0)

func _measure(label: String, active: bool) -> void:
	for index in WARMUP: await process_frame
	var quality := root.get_node_or_null("QualityManager")
	var profile := String(quality.current.id) if quality != null and quality.current != null else "missing"
	var mode := DisplayServer.window_get_vsync_mode()
	if "--uncapped" in OS.get_cmdline_user_args():
		Engine.max_fps = 0
	var cap := Engine.max_fps
	print("FRAME DIAGNOSTIC CONFIG: stage=%s profile=%s cap=%d vsync=%d backend=%s focused=%s physical=%s logical=%s" % [label, profile, cap, mode, DisplayServer.get_name(), DisplayServer.window_is_focused(), root.size, root.content_scale_size])
	var frame_ms: Array[float] = []
	var process_ms: Array[float] = []
	var physics_ms: Array[float] = []
	var draw_calls: Array[float] = []
	var last_tick := Time.get_ticks_usec()
	for index in SAMPLES:
		if active and index == 0: Input.action_press(&"move_forward")
		if active and index == 60:
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			Input.parse_input_event(press)
		if active and index == 63:
			var release := InputEventMouseButton.new()
			release.button_index = MOUSE_BUTTON_LEFT
			release.pressed = false
			Input.parse_input_event(release)
		if active and index == 120: Input.action_release(&"move_forward")
		await process_frame
		var now := Time.get_ticks_usec()
		var interval_ms := float(now - last_tick) / 1000.0
		frame_ms.append(interval_ms)
		last_tick = now
		var process_value := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		var physics_value := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		var draw_value := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		process_ms.append(process_value)
		physics_ms.append(physics_value)
		draw_calls.append(draw_value)
		if not trace_file.is_empty():
			trace_rows.append({"stage": label, "index": index, "tick_usec": now, "interval_ms": interval_ms, "process_monitor_ms": process_value, "physics_monitor_ms": physics_value, "draw_calls": draw_value})
	print("FRAME DIAGNOSTIC: %s frame=%s process=%s physics=%s draw_calls=%s" % [label, _summary(frame_ms), _summary(process_ms), _summary(physics_ms), _summary(draw_calls)])

func _summary(values: Array[float]) -> String:
	var ordered := values.duplicate()
	ordered.sort()
	var total := 0.0
	for value in values: total += value
	return "mean=%.3f p50=%.3f p95=%.3f p99=%.3f max=%.3f" % [total / values.size(), ordered[119], ordered[227], ordered[237], ordered.back()]
