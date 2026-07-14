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
	fire_down.position = fire_primary_center
	fire_down.pressed = true
	controls._handle_touch(fire_down)
	Input.flush_buffered_events()

	var alt_down := InputEventScreenTouch.new()
	alt_down.index = 2
	alt_down.position = fire_secondary_center
	alt_down.pressed = true
	controls._handle_touch(alt_down)
	Input.flush_buffered_events()

	_expect(Input.is_action_pressed(&"fire_primary"), "primary fire remains active while secondary is pressed")
	_expect(Input.is_action_pressed(&"fire_secondary"), "secondary touch press reaches Input")
	_expect(controls._button_fingers.get(2) == &"fire_secondary", "secondary touch owns a distinct active finger")

	var alt_up := InputEventScreenTouch.new()
	alt_up.index = 2
	alt_up.position = fire_secondary_center
	alt_up.pressed = false
	controls._handle_touch(alt_up)
	Input.flush_buffered_events()
	_expect(not Input.is_action_pressed(&"fire_secondary"), "secondary touch press releases exactly fire_secondary")
	_expect(Input.is_action_pressed(&"fire_primary"), "releasing secondary does not affect primary fire state")
	var fire_up := InputEventScreenTouch.new()
	fire_up.index = 1
	fire_up.position = fire_primary_center
	fire_up.pressed = false
	controls._handle_touch(fire_up)
	Input.flush_buffered_events()
	_expect(not Input.is_action_pressed(&"fire_primary"), "primary touch release clears primary")


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
