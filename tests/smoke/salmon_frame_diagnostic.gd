extends SceneTree

## Debug-only native timing diagnosis with mapped input; not a GPU-time pass.
## Frame intervals include OS/presentation waits; Performance monitors are
## sampled snapshots, not independently measured per-frame CPU/GPU durations.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
const WARMUP := 45
const SAMPLES := 240

func _initialize() -> void:
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
	print("SALMON FRAME DIAGNOSTIC: MEASURED (NOT A PERFORMANCE PASS)")
	quit(0)

func _measure(label: String, active: bool) -> void:
	for index in WARMUP: await process_frame
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
		frame_ms.append(float(now - last_tick) / 1000.0)
		last_tick = now
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("FRAME DIAGNOSTIC: %s frame=%s process=%s physics=%s draw_calls=%s" % [label, _summary(frame_ms), _summary(process_ms), _summary(physics_ms), _summary(draw_calls)])

func _summary(values: Array[float]) -> String:
	var ordered := values.duplicate()
	ordered.sort()
	var total := 0.0
	for value in values: total += value
	return "mean=%.3f p50=%.3f p95=%.3f p99=%.3f max=%.3f" % [total / values.size(), ordered[119], ordered[227], ordered[237], ordered.back()]
