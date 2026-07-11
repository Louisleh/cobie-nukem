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
	_expect(controls._button_at(Vector2(287, 139)) == &"fire_primary", "fire hit target maps correctly")
	var move_down := InputEventScreenTouch.new(); move_down.index = 1; move_down.position = Vector2(52, 112); move_down.pressed = true
	controls._handle_touch(move_down)
	_expect(controls._move_finger == 1 and player._touch_move.y < -0.9, "left thumb drives forward movement")
	var look_down := InputEventScreenTouch.new(); look_down.index = 2; look_down.position = Vector2(170, 90); look_down.pressed = true
	controls._handle_touch(look_down)
	var start_yaw := player.rotation.y
	var look_drag := InputEventScreenDrag.new(); look_drag.index = 2; look_drag.position = Vector2(200, 90); look_drag.relative = Vector2(30, 0)
	controls._handle_drag(look_drag)
	_expect(controls._look_finger == 2 and not is_equal_approx(player.rotation.y, start_yaw), "right thumb looks while movement finger remains owned")
	controls.release_all()
	_expect(player._touch_move == Vector2.ZERO and controls._move_finger == -1 and controls._look_finger == -1, "touch release clears movement and finger ownership")
	controls.size = Vector2(1024, 768)
	var design_point := controls._to_design(Vector2(512, 384))
	_expect(design_point.is_equal_approx(Vector2(160, 90)), "touch coordinates scale across tablet viewport")
	controls.free(); player.free()
	if failures.is_empty():
		print("MOBILE CONTROLS TESTS: PASS")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _expect(condition: bool, label: String) -> void:
	if not condition: failures.append(label)
