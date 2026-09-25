extends SceneTree

## Thirty simulated seconds on the native renderer; mapped input only, no teleports.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
const FRAMES := 900
const CAPTURE_FRAMES := [0, 75, 105, 132, 163, 300, 429, 462, 899]
var failures: Array[String] = []
var capture_dir := ""
var capture_size := Vector2i.ZERO

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
		if argument.begins_with("--capture-size="):
			var dimensions := argument.trim_prefix("--capture-size=").split("x")
			if dimensions.size() == 2:
				capture_size = Vector2i(int(dimensions[0]), int(dimensions[1]))
	call_deferred("_run")

func _key_use(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"use"):
		failures.append("mapped use key missing")
	Input.parse_input_event(event)

func _mouse_fire(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"fire_primary"):
		failures.append("mapped fire button missing")
	Input.parse_input_event(event)

func _menu_accept(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.physical_keycode = KEY_ENTER
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"menu_accept"):
		failures.append("mapped menu accept key missing")
	Input.parse_input_event(event)

func _run() -> void:
	if not capture_dir.is_empty():
		if capture_size.x < 640 or capture_size.y < 360:
			push_error("FIRST 30: capture needs an explicit safe viewport")
			quit(1)
			return
		root.size = capture_size
		root.content_scale_size = Vector2i(roundi(360.0 * capture_size.x / capture_size.y), 360)
	seed(20260924)
	Engine.physics_ticks_per_second = 60
	var level := LEVEL.instantiate() as EpisodeOneLevel
	root.add_child(level)
	var pause_menus := level.find_children("*", "PauseMenu", true, false)
	if pause_menus.size() != 1:
		push_error("FIRST 30: expected one pause menu immediately after level entry")
		quit(1)
		return
	var pause_menu := pause_menus[0] as PauseMenu
	if pause_menu == null:
		push_error("FIRST 30: invalid pause menu")
		quit(1)
		return
	# Real play pauses on focus loss. Scripted capture has no human to resume:
	# suppress synchronously after scene entry, before the first warmup frame.
	pause_menu.set_suppressed(true)
	pause_menu.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if paused or pause_menu.visible:
		push_error("FIRST 30: focus-loss suppression failed before warmup")
		quit(1)
		return
	for index in 12: await process_frame
	var player := level.player as CobiePlayer
	var gate := level.get_node_or_null("Interactables/ShedGate") as LevelDoor
	if player == null or gate == null:
		push_error("FIRST 30: missing real player or shed gate")
		quit(1)
		return
	var paused_at_start := paused
	var pause_menu_visible := pause_menu.visible
	if paused_at_start or pause_menu_visible:
		push_error("FIRST 30: route started paused after warmup (paused=%s menu=%s focus=%s)" % [paused_at_start, pause_menu_visible, root.has_focus()])
		quit(1)
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var weapon := player.weapons[player.current_weapon_index] as WeaponBase
	var director := level._mission_presentation.get_audio_director() as MissionAudioDirector
	var hud := level._mission_presentation.get_hud() as GameHUD
	var viewport := hud.get_viewport().get_visible_rect().size
	if viewport.x / viewport.y <= 1.5 and (hud.get_node("Root/CaptionLabel") as Control).get_global_rect().position.x < viewport.x * 0.25 - 1.0:
		failures.append("tablet warning caption overlaps the portrait lane")
	var initial_ammo := weapon.ammo
	var shots: Array[int] = []
	var warnings: Array[int] = []
	var warning_captions: Array[String] = []
	var captures: Array[Dictionary] = []
	var attacks: Array[int] = []
	var awake := -1
	var combat := -1
	var use_frame := -1
	var opened := -1
	var shed := -1
	var death := -1
	var recovered := -1
	var ammo_at_shed := -1
	var starting_process := Engine.get_process_frames()
	var starting_physics := Engine.get_physics_frames()
	weapon.fired.connect(func(_source: WeaponBase, _secondary: bool) -> void:
		shots.append(Engine.get_process_frames() - starting_process))
	for actor in level._opening_enemies:
		if not actor is EnemyAgent: continue
		var enemy := actor as EnemyAgent
		enemy.telegraph_started.connect(func(_kind: StringName, _duration: float) -> void:
			warnings.append(Engine.get_process_frames() - starting_process)
			warning_captions.append(hud.get_caption_text()))
		enemy.attack_fired.connect(func(_kind: StringName) -> void:
			attacks.append(Engine.get_process_frames() - starting_process))
	if director.current_state() == &"combat": failures.append("combat music starts before player contact")
	Input.action_press(&"move_forward")
	for frame in FRAMES:
		if frame == 60: _mouse_fire(true)
		if frame == 63: _mouse_fire(false)
		if use_frame == -1 and player.global_position.z < -15.8:
			use_frame = frame
			_key_use(true)
		if use_frame >= 0 and frame == use_frame + 3: _key_use(false)

		if death >= 0 and frame == death + 30: _menu_accept(true)
		if death >= 0 and frame == death + 33: _menu_accept(false)
		await process_frame
		if awake == -1 and level._spawn_registry.opening_enemies_active(): awake = frame
		if combat == -1 and director.current_state() == &"combat": combat = frame
		if opened == -1 and gate.is_open: opened = frame
		if shed == -1 and level.current_zone == &"equipment_shed":
			shed = frame
			ammo_at_shed = weapon.ammo
			Input.action_release(&"move_forward")
		if death == -1 and player.is_dead:
			death = frame
			var death_screen := level.find_children("*", "DeathScreen", true, false)
			if death_screen.size() != 1:
				failures.append("death must show exactly one death screen")
			else:
				var panel := death_screen[0].get_node("Panel") as Control
				var logical_width := roundi(float(root.content_scale_size.y) * root.size.x / root.size.y)
				var viewport_bounds := Rect2(Vector2.ZERO, Vector2(logical_width, root.content_scale_size.y))
				for path in [".", "VBox/Buttons/RetryButton", "VBox/Buttons/MainMenuButton"]:
					var control := panel.get_node(path) as Control
					if not viewport_bounds.encloses(control.get_global_rect()):
						failures.append("death %s clipped at %s" % [path, viewport_bounds.size])
		if death >= 0 and recovered == -1 and not player.is_dead:
			recovered = frame
			if hud.notification_label.text.contains("GOOD DOG DOWN") or hud.get_caption_text().contains("GOOD DOG DOWN"):
				failures.append("focused Retry leaves stale death instruction over live play")
			if level.current_zone != &"forbidden_field":
				failures.append("focused Retry leaves shed zone active after field respawn")
		if not capture_dir.is_empty() and frame in CAPTURE_FRAMES:
			await RenderingServer.frame_post_draw
			var path := capture_dir.path_join("frame_%04d.png" % frame)
			var image := root.get_texture().get_image()
			if image.get_size() != Vector2i(root.size) or image.save_png(path) != OK:
				failures.append("bounded route capture failed at frame %d" % frame)
			else:
				captures.append({"frame": frame, "sha256": FileAccess.get_sha256(path), "zone": String(level.current_zone), "process_frame": Engine.get_process_frames() - starting_process})
	Input.action_release(&"move_forward")
	_key_use(false)
	_mouse_fire(false)
	_menu_accept(false)
	var elapsed_process := Engine.get_process_frames() - starting_process
	var elapsed_physics := Engine.get_physics_frames() - starting_physics
	print("FIRST 30 RECEIPT: process=%d physics=%d shot=%s awake=%d combat=%d warning=%s caption=%s attack=%s use=%d gate=%d shed=%d death=%d recovered=%d ammo_at_shed=%d health=%.1f" % [elapsed_process, elapsed_physics, shots, awake, combat, warnings, warning_captions.slice(0, 2), attacks, use_frame, opened, shed, death, recovered, ammo_at_shed, player.health_armor.health])
	if shots.is_empty() and use_frame < 0:
		print("FIRST 30 INPUT DIAGNOSTIC: paused_start=%s paused_end=%s menu_start=%s focus_end=%s player_physics=%s player_pos=%s move_strength=%.1f phase=%s" % [paused_at_start, paused, pause_menu_visible, root.has_focus(), player.is_physics_processing(), player.global_position, Input.get_action_strength(&"move_forward"), root.get_node_or_null("/root/GameState").phase])
	if elapsed_process != FRAMES or abs(elapsed_physics - FRAMES * 2) > 2:
		failures.append("30 simulated seconds must contain 900 rendered and 1800 physics frames")
	if shots.size() != 1 or shots[0] < 60 or shots[0] > 63 or ammo_at_shed != initial_ammo - weapon.definition.ammo_per_primary:
		failures.append("real mapped mouse input must consume exactly one Pawstol shot")
	if awake < 0 or combat < awake or warnings.is_empty() or attacks.is_empty() or warnings[0] <= awake or attacks[0] <= warnings[0]:
		failures.append("field contact must wake staged enemies, cue combat, telegraph and attack")
	var named_warning := false
	for caption in warning_captions:
		if caption.contains(":") and caption.contains(" WARNING") and (caption.contains("LEASH ENFORCEMENT DRONE") or caption.contains("MUTANT GROUNDSKEEPER")):
			named_warning = true
	if not named_warning:
		failures.append("real opening telegraph must caption both attacker and attack")
	if use_frame < 0 or opened < use_frame or shed < opened or shed >= FRAMES:
		failures.append("mapped forward/use must open unchanged gate and enter shed")
	if death >= 0 and death <= shed:
		failures.append("player must be alive on first shed entry")
	if death >= 0 and (recovered < death or recovered >= FRAMES or player.is_dead):
		failures.append("death during first 30 must permit focused Retry via mapped menu accept")
	if not capture_dir.is_empty():
		var file := FileAccess.open(capture_dir.path_join("captures.json"), FileAccess.WRITE)
		if file == null:
			failures.append("bounded route capture receipt could not be written")
		else:
			file.store_string(JSON.stringify({"viewport": [root.size.x, root.size.y], "frames": captures, "process": elapsed_process, "physics": elapsed_physics, "shot": shots, "warning": warnings, "attack": attacks, "gate": opened, "shed": shed, "death": death, "recovered": recovered}, "	"))
			file.close()
	for audio in level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
	level.queue_free()
	for index in 12: await process_frame
	if failures.is_empty():
		print("SALMON FIRST 30 ROUTE: PASS (simulated native input, not human play)")
		quit(0)
	else:
		for failure in failures: push_error("FIRST 30: " + failure)
		quit(1)
