extends SceneTree

## Debug-only sampled native motion. No Movie Maker, teleports, or encounter calls.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
var output := ""
var seconds := 5
var width := 1280
var height := 720
var level: Node3D
var samples: Array[Dictionary] = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		if argument.begins_with("--seconds="): seconds = int(argument.trim_prefix("--seconds="))
		if argument == "--tablet": width = 1024; height = 768
	call_deferred("_run")

func _run() -> void:
	if output.is_empty() or seconds < 1 or seconds > 5:
		quit(1)
		return
	seed(20260919)
	Engine.physics_ticks_per_second = 60
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	root.size = Vector2i(width, height)
	root.content_scale_size = Vector2i(roundi(360.0 * width / height), 360)
	await process_frame
	level = LEVEL.instantiate()
	root.add_child(level)
	for menu in level.find_children("*", "PauseMenu", true, false):
		menu.set_suppressed(true)
	# Let the normal spawn/navigation lifecycle settle; never relocate actors.
	for index in 12: await process_frame
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var start_tick := Engine.get_physics_frames()
	var start_frame := Engine.get_process_frames()
	var start_usec := Time.get_ticks_usec()
	for frame in seconds * 30:
		# Two seconds to read the opening; a short advance and ordinary fire.
		if frame == 60: Input.action_press(&"move_forward")
		if frame == 120: Input.action_release(&"move_forward")
		if frame == 120: Input.action_press(&"fire_primary")
		if frame == 210: Input.action_release(&"fire_primary")
		await process_frame
		await RenderingServer.frame_post_draw
		if frame % 3 != 0: continue
		var image := root.get_texture().get_image()
		var path := output.path_join("frame_%04d.png" % frame)
		if image.get_size() != Vector2i(width, height) or image.save_png(path) != OK:
			push_error("Opening probe image write/dimension failure")
			quit(1)
			return
		var player := level.get("player") as Node3D
		samples.append({"frame": frame, "process_frame": Engine.get_process_frames(),
			"simulation_seconds": float(Engine.get_process_frames() - start_frame) / 30.0,
			"elapsed_usec": Time.get_ticks_usec() - start_usec,
			"physics_ticks": Engine.get_physics_frames() - start_tick,
			"position": [player.position.x, player.position.y, player.position.z],
			"zone": String(level.get("current_zone")), "png_sha256": FileAccess.get_sha256(path),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	Input.action_release(&"move_forward")
	Input.action_release(&"fire_primary")
	var receipt := {"kind": "sampled_automated_native_motion", "movie_maker": false,
		"teleports": false, "direct_encounter_activation": false, "render_fps": 30,
		"sample_fps": 10, "physics_tps": 60, "frames": seconds * 30,
		"start_process_frame": start_frame, "end_process_frame": Engine.get_process_frames(),
		"start_physics_frame": start_tick, "end_physics_frame": Engine.get_physics_frames(),
		"save_directory": root.get_node("SaveManager").call("_save_directory_absolute"),
		"viewport": [width, height], "user_data_dir": OS.get_user_data_dir(), "samples": samples}
	var file := FileAccess.open(output.path_join("runtime.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "\t"))
	file.close()
	for audio in level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
	level.queue_free()
	for index in 12: await process_frame
	print("SALMON OPENING PROBE: COMPLETE")
	quit(0)
