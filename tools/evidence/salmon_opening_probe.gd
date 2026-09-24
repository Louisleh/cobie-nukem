extends SceneTree

## Debug-only sampled native motion. No Movie Maker, teleports, or encounter calls.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
var output := ""
var seconds := 5
var width := 1280
var height := 720
var level: Node3D
var samples: Array[Dictionary] = []
var fired_events: Array[Dictionary] = []
var input_events: Array[Dictionary] = []
var observed_weapon: WeaponBase

func _on_weapon_fired(weapon: WeaponBase, secondary: bool) -> void:
	if weapon == observed_weapon and not secondary:
		fired_events.append({"process_frame": Engine.get_process_frames(),
			"weapon_id": String(weapon.definition.id), "ammo_after": weapon.ammo})

func _send_fire_event(pressed: bool, frame: int) -> bool:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = Vector2(width, height) * 0.5
	event.global_position = event.position
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"fire_primary") or (pressed and not event.is_action_pressed(&"fire_primary")):
		return false
	Input.parse_input_event(event)
	input_events.append({"frame": frame, "pressed": pressed, "button_index": event.button_index})
	return true

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
	var player := level.get("player") as CobiePlayer
	if player == null or player.weapons.is_empty():
		push_error("Opening probe missing real player/weapon")
		quit(1)
		return
	observed_weapon = player.weapons[player.current_weapon_index]
	var initial_ammo := observed_weapon.ammo
	var ammo_cost := observed_weapon.definition.ammo_per_primary
	observed_weapon.fired.connect(_on_weapon_fired)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var start_tick := Engine.get_physics_frames()
	var start_frame := Engine.get_process_frames()
	var start_usec := Time.get_ticks_usec()
	var fire_frame := mini(90, maxi(12, seconds * 30 - 30))
	for frame in seconds * 30:
		# Ordinary movement polling; fire requires a real event at the player's edge.
		if frame == 60 and seconds >= 5: Input.action_press(&"move_forward")
		if frame == 120 and seconds >= 5: Input.action_release(&"move_forward")
		if frame == fire_frame or frame == fire_frame + 3:
			if not _send_fire_event(frame == fire_frame, frame):
				push_error("Opening probe fire event does not match named action")
				quit(1)
				return
		await process_frame
		await RenderingServer.frame_post_draw
		if frame % 3 != 0: continue
		var image := root.get_texture().get_image()
		var path := output.path_join("frame_%04d.png" % frame)
		if image.get_size() != Vector2i(width, height) or image.save_png(path) != OK:
			push_error("Opening probe image write/dimension failure")
			quit(1)
			return
		samples.append({"frame": frame, "process_frame": Engine.get_process_frames(),
			"simulation_seconds": float(Engine.get_process_frames() - start_frame) / 30.0,
			"elapsed_usec": Time.get_ticks_usec() - start_usec,
			"physics_ticks": Engine.get_physics_frames() - start_tick,
			"position": [player.position.x, player.position.y, player.position.z],
			"zone": String(level.get("current_zone")), "png_sha256": FileAccess.get_sha256(path),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	Input.action_release(&"move_forward")
	if fired_events.size() != 1 or ammo_cost <= 0 or initial_ammo - observed_weapon.ammo != ammo_cost or fired_events[0]["ammo_after"] != observed_weapon.ammo:
		push_error("Opening probe did not observe one ammo-consuming primary shot")
		quit(1)
		return
	var receipt := {"kind": "sampled_automated_native_motion", "movie_maker": false,
		"teleports": false, "direct_encounter_activation": false, "render_fps": 30,
		"sample_fps": 10, "physics_tps": 60, "frames": seconds * 30,
		"start_process_frame": start_frame, "end_process_frame": Engine.get_process_frames(),
		"start_physics_frame": start_tick, "end_physics_frame": Engine.get_physics_frames(),
		"save_directory": root.get_node("SaveManager").call("_save_directory_absolute"),
		"viewport": [width, height], "user_data_dir": OS.get_user_data_dir(), "samples": samples,
		"fire_input": {"action": "fire_primary", "method": "Input.parse_input_event",
			"events": input_events},
		"primary_fire": {"weapon_id": String(observed_weapon.definition.id),
			"initial_ammo": initial_ammo, "final_ammo": observed_weapon.ammo,
			"ammo_cost": ammo_cost, "fired_events": fired_events}}
	var file := FileAccess.open(output.path_join("runtime.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "\t"))
	file.close()
	for audio in level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
	level.queue_free()
	for index in 12: await process_frame
	print("SALMON OPENING PROBE: COMPLETE")
	quit(0)
