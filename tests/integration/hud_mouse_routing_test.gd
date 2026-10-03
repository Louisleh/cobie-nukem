extends SceneTree

# GUI-routing regression, not OS/browser input evidence. Real mouse events go
# through the viewport and production HUD/player; no player callback is invoked.
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var viewport: SubViewport
var player: CobiePlayer
var hud: GameHUD
var button_presses := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.own_world_3d = true
	viewport.handle_input_locally = true
	root.add_child(viewport)
	player = preload("res://scenes/player/cobie_player.tscn").instantiate() as CobiePlayer
	viewport.add_child(player)
	player.set_physics_process(false)
	# Isolate GUI routing from the OS-specific capture controller. Its real Web
	# ordering is tested separately against the exact exported package.
	var capture := player.get_node("PointerCapture")
	capture.set_process_input(false)
	capture.set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_expect(player.apply_mission_loadout(preload("res://resources/loadouts/vancouver_waterfront_loadout.tres")), "Production Rain City loadout applies")
	hud = preload("res://scenes/ui/hud.tscn").instantiate() as GameHUD
	viewport.add_child(hud)
	hud.bind_player(player)
	await process_frame
	await process_frame
	var weapon := player.weapons[player.current_weapon_index]
	var targets := {
		"play area": Vector2(320, 180),
		"portrait": hud.get_node("Root/BottomBar/CobiePortrait").get_global_rect().get_center(),
		"footer": hud.get_node("Root/BottomBar").get_global_rect().get_center(),
	}
	hud.boss_panel.show()
	targets["boss panel"] = hud.boss_panel.get_global_rect().get_center()
	targets["boss health"] = hud.boss_health_bar.get_global_rect().get_center()
	for label in targets:
		for mouse_button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			await _wait_ready(weapon)
			var before := weapon.ammo
			_click(targets[label], mouse_button)
			await process_frame
			var cost := weapon.definition.ammo_per_primary if mouse_button == MOUSE_BUTTON_LEFT else weapon.definition.ammo_per_secondary
			observations.append({"target": label, "button": mouse_button, "before": before, "after": weapon.ammo})
			_expect(weapon.ammo == before - cost, "%s button %s reaches the real weapon through the HUD" % [label, mouse_button])
	# A separate interactive overlay must still own its own clicks. The HUD fix
	# must not move weapon firing ahead of Godot GUI event consumption.
	var button := Button.new()
	button.position = Vector2(270, 150)
	button.size = Vector2(100, 60)
	button.text = "INTERACTIVE OVERLAY"
	button.pressed.connect(func() -> void: button_presses += 1)
	viewport.add_child(button)
	await process_frame
	await _wait_ready(weapon)
	var before_overlay := weapon.ammo
	_click(Vector2(320, 180), MOUSE_BUTTON_LEFT)
	await process_frame
	_expect(button_presses == 1, "Interactive overlay still receives its click")
	_expect(weapon.ammo == before_overlay, "Interactive overlay consumes the click before weapon firing")
	viewport.queue_free()
	await process_frame
	await process_frame
	print("HUD MOUSE ROUTING OBSERVATIONS: " + JSON.stringify(observations))
	for failure in failures:
		push_error(failure)
	print("HUD MOUSE ROUTING TEST: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _wait_ready(weapon: WeaponBase) -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while not weapon.can_fire() and Time.get_ticks_msec() < deadline:
		await process_frame
	_expect(weapon.can_fire(), "Weapon recovers before the next independent input")


func _click(position: Vector2, mouse_button: MouseButton) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	viewport.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.device = 0
		event.button_index = mouse_button
		event.button_mask = (MOUSE_BUTTON_MASK_LEFT if mouse_button == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if pressed else 0
		event.position = position
		event.global_position = position
		event.pressed = pressed
		viewport.push_input(event, true)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
