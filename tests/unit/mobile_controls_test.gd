extends SceneTree

var failures := PackedStringArray()


func _initialize() -> void:
	var player := preload("res://scenes/player/cobie_player.tscn").instantiate() as CobiePlayer
	root.add_child(player)
	var controls := preload("res://scenes/ui/mobile_controls.tscn").instantiate() as MobileControls
	controls.force_visible = true
	controls.set_anchors_preset(Control.PRESET_TOP_LEFT)
	controls.size = Vector2(320, 180)
	root.add_child(controls)
	controls.bind_player(player)
	await process_frame
	_expect(controls.visible and controls.is_touch_enabled(), "forced mobile controls are visible")
	_expect(controls._button_at(Vector2(292, 111)) == &"fire_primary", "fire hit target maps correctly")
	_expect(controls._stick_at(Vector2(48, 105)) == &"move" and controls._stick_at(Vector2(220, 105)) == &"look", "two fixed stick capture zones are distinct")
	_expect(MobileControls._apply_dead_zone(Vector2(0.05, 0.0)).length() > 0.0, "raw stick preserves fine input for the aim profile")
	_expect(MobileControls._apply_dead_zone(Vector2.RIGHT).is_equal_approx(Vector2.RIGHT), "full stick deflection reaches full response")
	_expect(player.touch_aim_profile.shape(Vector2(0.05, 0.0)) == Vector2.ZERO, "aim profile suppresses center drift")
	var move_down := InputEventScreenTouch.new(); move_down.index = 1; move_down.position = Vector2(48, 80); move_down.pressed = true
	controls._handle_touch(move_down)
	_expect(controls._move_finger == 1 and player._touch_move.y < -0.9, "left thumb drives forward movement")
	var look_down := InputEventScreenTouch.new(); look_down.index = 2; look_down.position = Vector2(245, 105); look_down.pressed = true
	controls._handle_touch(look_down)
	var start_yaw := player.rotation.y
	player._apply_touch_stick_look(1.0 / 60.0)
	_expect(controls._look_finger == 2 and not is_equal_approx(player.rotation.y, start_yaw), "right stick looks while movement finger remains owned")
	var fire_down := InputEventScreenTouch.new(); fire_down.index = 3; fire_down.position = Vector2(292, 111); fire_down.pressed = true
	controls._handle_touch(fire_down); Input.flush_buffered_events()
	_expect(Input.is_action_pressed(&"fire_primary") and controls._move_finger == 1 and controls._look_finger == 2, "move, aim, and fire own three independent fingers")
	var yaw_sixty := player.rotation.y
	player.set_touch_look(Vector2.ZERO)
	player.rotation.y = 0.0
	player.set_touch_look(Vector2.RIGHT)
	for frame in 30: player._apply_touch_stick_look(1.0 / 30.0)
	var yaw_thirty := player.rotation.y
	player.set_touch_look(Vector2.ZERO)
	player.rotation.y = 0.0
	player.set_touch_look(Vector2.RIGHT)
	for frame in 120: player._apply_touch_stick_look(1.0 / 120.0)
	var yaw_one_twenty := player.rotation.y
	_expect(absf(yaw_thirty - yaw_one_twenty) < deg_to_rad(4.0), "right-stick aim is render-frame-rate stable within four degrees")
	player.rotation.y = yaw_sixty
	controls.release_all()
	Input.flush_buffered_events()
	_expect(player._touch_move == Vector2.ZERO and player._touch_look == Vector2.ZERO and controls._move_finger == -1 and controls._look_finger == -1 and not Input.is_action_pressed(&"fire_primary"), "touch release clears sticks, actions, and finger ownership")
	controls.size = Vector2(1024, 768)
	var design_point := controls._to_design(Vector2(512, 384))
	_expect(design_point.is_equal_approx(Vector2(160, 90)), "touch coordinates scale across tablet viewport")
	controls.left_handed = true
	_expect(controls._to_design(Vector2(92.8, 520.5)).x > 280.0, "left-handed layout mirrors physical touch coordinates")
	_expect(controls._from_design(Vector2(292, 111)).x < controls.size.x * 0.15, "left-handed layout draws fire on the left edge")
	controls.free(); player.free()
	if failures.is_empty():
		print("MOBILE CONTROLS TESTS: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
