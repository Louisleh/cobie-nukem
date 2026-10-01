extends SceneTree

var failures := PackedStringArray()


func _initialize() -> void:
	var player := preload("res://scenes/player/cobie_player.tscn").instantiate() as CobiePlayer
	var controls := preload("res://scenes/ui/mobile_controls.tscn").instantiate() as MobileControls
	controls.force_visible = true
	controls.set_anchors_preset(Control.PRESET_TOP_LEFT)
	controls.size = Vector2(320, 180)
	root.add_child(player)
	root.add_child(controls)
	controls.bind_player(player)
	await process_frame

	_expect(MobileControls.BUTTONS.has(&"fire_secondary"), "BUTTONS includes fire_secondary")
	if MobileControls.BUTTONS.has(&"fire_secondary"):
		var secondary_data: Dictionary = MobileControls.BUTTONS[&"fire_secondary"]
		var secondary_label := String(secondary_data.get("label", ""))
		_expect(not secondary_label.is_empty(), "fire_secondary has a non-empty label")
		var primary_label := String(MobileControls.BUTTONS[&"fire_primary"].get("label", ""))
		_expect(secondary_label != primary_label, "fire_secondary label is distinct from fire_primary")

		var fire_secondary_center := Vector2(secondary_data.get("center", Vector2.ZERO))
		_expect(controls._button_at(fire_secondary_center) == &"fire_secondary", "_button_at resolves fire_secondary at its center")
		var fire_primary_data: Dictionary = MobileControls.BUTTONS[&"fire_primary"]
		var fire_primary_center := Vector2(fire_primary_data.get("center", Vector2.ZERO))
		var primary_radius := float(fire_primary_data.get("radius", 0.0))
		var secondary_radius := float(secondary_data.get("radius", 0.0))
		var min_distance := (primary_radius + secondary_radius) * 1.25 + 0.01
		_expect(fire_secondary_center.distance_to(fire_primary_center) > min_distance, "fire_secondary touch target does not overlap fire_primary")
		_test_secondary_fire_lifecycle(controls, fire_secondary_center)

	controls.free()
	await _test_ammo_reservation(player)
	player.free()

	if failures.is_empty():
		print("SECONDARY FIRE TOUCH HUD TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_secondary_fire_lifecycle(controls: MobileControls, fire_secondary_center: Vector2) -> void:
	var fire_primary_center := Vector2(MobileControls.BUTTONS[&"fire_primary"].get("center", Vector2.ZERO))
	var fire_down := InputEventScreenTouch.new()
	fire_down.index = 1
	fire_down.position = controls._from_design(fire_primary_center)
	fire_down.pressed = true
	controls._handle_touch(fire_down)
	Input.flush_buffered_events()

	var alt_down := InputEventScreenTouch.new()
	alt_down.index = 2
	alt_down.position = controls._from_design(fire_secondary_center)
	alt_down.pressed = true
	controls._handle_touch(alt_down)
	Input.flush_buffered_events()

	_expect(Input.is_action_pressed(&"fire_primary"), "primary fire remains active while secondary is pressed")
	_expect(Input.is_action_pressed(&"fire_secondary"), "secondary touch press reaches Input")
	_expect(controls._button_fingers.get(2) == &"fire_secondary", "secondary touch owns a distinct active finger")

	var alt_up := InputEventScreenTouch.new()
	alt_up.index = 2
	alt_up.position = controls._from_design(fire_secondary_center)
	alt_up.pressed = false
	controls._handle_touch(alt_up)
	Input.flush_buffered_events()
	_expect(not Input.is_action_pressed(&"fire_secondary"), "secondary touch press releases exactly fire_secondary")
	_expect(Input.is_action_pressed(&"fire_primary"), "releasing secondary does not affect primary fire state")
	var fire_up := InputEventScreenTouch.new()
	fire_up.index = 1
	fire_up.position = controls._from_design(fire_primary_center)
	fire_up.pressed = false
	controls._handle_touch(fire_up)
	Input.flush_buffered_events()
	_expect(not Input.is_action_pressed(&"fire_primary"), "primary touch release clears primary")


func _test_ammo_reservation(player: CobiePlayer) -> void:
	var detached_hud := preload("res://scenes/ui/hud.tscn").instantiate() as GameHUD
	_expect(detached_hud._touch_ammo_layout == null, "detached pre-ready HUD allocates no touch helper")
	detached_hud.free()
	var original_targets := {
		&"fire_primary": Vector3(292, 111, 20), &"fire_secondary": Vector3(292, 152, 11),
		&"use": Vector3(257, 92, 12), &"jump": Vector3(291, 71, 13),
		&"reload": Vector3(259, 61, 11), &"weapon_previous": Vector3(274, 35, 10),
		&"weapon_next": Vector3(303, 35, 10), &"pause": Vector3(304, 13, 10),
	}
	for action in original_targets:
		var target: Vector3 = original_targets[action]
		var data: Dictionary = MobileControls.BUTTONS[action]
		_expect(Vector2(data.center).is_equal_approx(Vector2(target.x, target.y)) and is_equal_approx(float(data.radius), target.z), "original touch target preserved: %s" % action)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	root.add_child(viewport)
	var hud := preload("res://scenes/ui/hud.tscn").instantiate() as GameHUD
	viewport.add_child(hud)
	var controls := preload("res://scenes/ui/mobile_controls.tscn").instantiate() as MobileControls
	controls.force_visible = true
	hud.get_node("Root").add_child(controls)
	controls.bind_player(player)
	controls._on_setting_changed(&"gameplay", &"left_handed_touch", false)
	await process_frame
	# This reproduces the actual pre-binding footer geometry, not a copied
	# expected constant: the production ALT paint overlaps the real AmmoLabel.
	var initial_bounds: Dictionary = controls.get_paint_bounds()
	var initial_alt: Rect2 = initial_bounds[&"fire_secondary"]
	initial_alt.position += controls.global_position
	_expect(hud.ammo_label.get_global_rect().intersects(initial_alt), "unreserved instantiated footer reproduces ALT/ammo overlap")
	hud.bind_mobile_controls(controls)
	_expect(hud._touch_ammo_layout.get_parent() == hud, "bound touch helper is parented to HUD")
	var protected_paths := [
		"Root/BottomBar/HealthLabel", "Root/BottomBar/ArmorLabel", "Root/ObjectiveLabel",
		"Root/CaptionLabel", "Root/BossPanel", "Root/NotificationLabel", "Root/InteractionLabel",
		"Root/BottomBar/WeaponLabel", "Root/BottomBar/AccessLabel", "Root/BottomBar/ReloadHint",
		"Root/BottomBar/CobiePortrait",
	]
	for width in [640, 576, 480, 860]:
		viewport.size = Vector2i(width, 360)
		await process_frame
		await process_frame
		for text_scale in [1.0, 1.5]:
			hud._on_setting_changed(&"accessibility", &"text_scale", text_scale)
			hud.ammo_label.text = "99 / 99"
			for handedness in [false, true]:
				controls._on_setting_changed(&"gameplay", &"left_handed_touch", handedness)
				for stick_size in MobileControls.STICK_SIZE_SCALE:
					controls._on_setting_changed(&"gameplay", &"touch_stick_size", stick_size)
					for stick_position in MobileControls.STICK_CENTERS:
						controls._on_setting_changed(&"gameplay", &"touch_stick_position", stick_position)
						controls._onboarding_remaining = 6.0
						await process_frame
						var label := "%s hand=%s font=%s stick=%s/%s" % [width, handedness, text_scale, stick_size, stick_position]
						_check_ammo_geometry(hud, controls, viewport, protected_paths, label)
						var idle_bounds := controls.get_paint_bounds()
						_test_secondary_fire_lifecycle(controls, Vector2(MobileControls.BUTTONS[&"fire_secondary"].center))
						var press := InputEventScreenTouch.new()
						press.index = 8; press.pressed = true
						press.position = controls._from_design(MobileControls.BUTTONS[&"fire_secondary"].center)
						controls._handle_touch(press)
						Input.flush_buffered_events()
						controls._move_value = Vector2.RIGHT
						controls._look_value = Vector2.LEFT
						_expect(Input.is_action_pressed(&"fire_secondary"), "held ALT reaches named input: " + label)
						_expect(controls.get_paint_bounds() == idle_bounds, "pressed/held paint stays inside conservative envelope: " + label)
						_check_ammo_geometry(hud, controls, viewport, protected_paths, label + " held")
						controls.release_all()
						Input.flush_buffered_events()
						_expect(not Input.is_action_pressed(&"fire_secondary"), "release clears held ALT: " + label)
		controls.hide()
		await process_frame
		_expect_desktop_ammo(hud, Vector2(width, 360), "hidden controls restore desktop")
		viewport.size = Vector2i(width + 1, 360)
		await process_frame
		await process_frame
		_expect_desktop_ammo(hud, Vector2(width + 1, 360), "hidden resize preserves desktop")
		controls.show()
		controls._on_setting_changed(&"gameplay", &"left_handed_touch", false)
		await process_frame
		_expect(hud.ammo_label.get_global_rect().position.is_equal_approx(Vector2((width + 1) * 0.25, 200)), "show/settings restore reserved lane after resize")
	# Rebinding disconnects every signal on the old controls, and exiting the
	# bound controls restores the desktop layout without stale references.
	hud.bind_mobile_controls(null)
	_expect_desktop_ammo(hud, Vector2(861, 360), "unbind restores desktop")
	_expect(not controls.layout_settings_changed.is_connected(Callable(hud._touch_ammo_layout, &"_on_layout_changed")), "unbind disconnects layout settings signal")
	controls._on_setting_changed(&"gameplay", &"left_handed_touch", true)
	_expect_desktop_ammo(hud, Vector2(861, 360), "old controls cannot update unbound HUD")
	hud.bind_mobile_controls(controls)
	controls.queue_free()
	await process_frame
	_expect(not bool(hud._touch_ammo_layout.call(&"has_bound_controls")), "control teardown clears HUD binding")
	_expect_desktop_ammo(hud, Vector2(861, 360), "control teardown restores desktop")
	var owned_helper := hud._touch_ammo_layout
	viewport.queue_free()
	await process_frame
	_expect(not is_instance_valid(owned_helper), "HUD teardown frees its owned touch helper")


func _check_ammo_geometry(hud: GameHUD, controls: MobileControls, viewport: SubViewport, protected_paths: Array, label: String) -> void:
	var ammo_rect := hud.ammo_label.get_global_rect()
	var minimum_size := hud.ammo_label.get_combined_minimum_size()
	_expect(ammo_rect.size.x >= minimum_size.x and ammo_rect.size.y >= minimum_size.y, "ammo text fits at " + label)
	_expect(Rect2(Vector2.ZERO, Vector2(viewport.size)).encloses(ammo_rect), "ammo stays in viewport at " + label)
	var expected_left := viewport.size.x * 0.25
	if controls.left_handed: expected_left = viewport.size.x - expected_left - 148.0
	_expect(ammo_rect.is_equal_approx(Rect2(expected_left, 200, 148, 40)), "actual reserved ammo rect at " + label)
	var paint_bounds := controls.get_paint_bounds()
	_expect(paint_bounds.size() == MobileControls.BUTTONS.size() + 3, "all actions/sticks/onboarding have paint bounds at " + label)
	for key in paint_bounds:
		var bounds: Rect2 = paint_bounds[key]
		bounds.position += controls.global_position
		_expect(not ammo_rect.intersects(bounds), "ammo avoids control %s at %s" % [key, label])
	for path in protected_paths:
		var protected := hud.get_node(path) as Control
		_expect(not ammo_rect.intersects(protected.get_global_rect()), "ammo avoids HUD %s at %s" % [path, label])
	# Named hit targets retain their original design-space capture multiplier.
	for action in MobileControls.BUTTONS:
		var target: Dictionary = MobileControls.BUTTONS[action]
		var inside: Vector2 = target.center + Vector2.RIGHT * float(target.radius) * 1.24
		_expect(controls._button_at(inside) == action, "capture radius preserved for %s at %s" % [action, label])


func _expect_desktop_ammo(hud: GameHUD, viewport_size: Vector2, label: String) -> void:
	var layout := hud._bottom_bar_layout_for(viewport_size)
	var expected: Rect2 = layout[&"ammo"]
	_expect(Rect2(hud.ammo_label.position, hud.ammo_label.size).is_equal_approx(expected), label)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
