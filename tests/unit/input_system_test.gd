extends SceneTree

const InputMathScript = preload("res://scripts/input/input_math.gd")
const InputProfileScript = preload("res://scripts/input/input_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
	check_close("dead-zone center", InputMathScript.apply_dead_zone(0.08, 0.12), 0.0)
	check_close("dead-zone rescale", InputMathScript.apply_dead_zone(0.56, 0.12), 0.5)
	check_close("negative curve", InputMathScript.apply_response_curve(-0.5, 2.0), -0.25)
	check_close("calibration positive", InputMathScript.normalize_calibrated_axis(0.6, -0.8, 0.1, 0.9), 0.625)
	check_close("calibration negative", InputMathScript.normalize_calibrated_axis(-0.35, -0.8, 0.1, 0.9), -0.5)
	check_profile_round_trip()
	check_default_profiles()
	check_diagnostics_scene()
	check_pointer_capture_policy()
	if failures.is_empty():
		print("PASS: input profiles, calibration math, and diagnostics scene")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func check_profile_round_trip() -> void:
	var source := InputProfileScript.new()
	source.profile_id = "test"
	source.preset = "classic_1996"
	source.ensure_defaults()
	var config := source.axis_config(0)
	config.dead_zone = 0.23
	config.invert = true
	source.set_axis_config(0, config)
	source.set_binding(&"jump", {"type": "button", "index": 9})
	var restored := InputProfileScript.from_dict(JSON.parse_string(JSON.stringify(source.to_dict())))
	check_close("serialized dead zone", restored.axis_config(0).dead_zone, 0.23)
	if not restored.axis_config(0).invert: failures.append("Serialized inversion was lost")
	if int(restored.bindings_for(&"jump")[0].index) != 9: failures.append("Serialized remap was lost")


func check_default_profiles() -> void:
	for preset in ["keyboard_mouse", "classic_1996", "hybrid", "generic_gamepad"]:
		var profile := InputProfileScript.new()
		profile.preset = preset
		profile.ensure_defaults()
		if profile.bindings_for(&"fire_primary").is_empty(): failures.append("%s lacks primary fire" % preset)
		if profile.bindings_for(&"menu_back").is_empty(): failures.append("%s lacks menu back" % preset)
	var keyboard := InputProfileScript.new()
	keyboard.preset = "keyboard_mouse"
	keyboard.ensure_defaults()
	if int(keyboard.bindings_for(&"move_forward")[0].index) != KEY_W: failures.append("Keyboard forward must display W")
	if int(keyboard.bindings_for(&"fire_primary")[0].index) != MOUSE_BUTTON_LEFT: failures.append("Keyboard primary fire must display LMB")
	if int(keyboard.bindings_for(&"weapon_previous")[0].index) != KEY_UP: failures.append("Previous weapon must display Up")
	if int(keyboard.bindings_for(&"weapon_next")[0].index) != KEY_DOWN: failures.append("Next weapon must display Down")
	if int(keyboard.bindings_for(&"reload")[0].index) != KEY_R: failures.append("Reload must display R")
	var classic := InputProfileScript.new()
	classic.preset = "classic_1996"
	classic.ensure_defaults()
	if classic.bindings_for(&"move_forward")[0].index != 1: failures.append("Classic stick Y must drive movement")
	if classic.bindings_for(&"run")[0].range != "full_range": failures.append("Classic throttle must use full range")


func check_diagnostics_scene() -> void:
	var packed := load("res://scenes/debug/input_diagnostics.tscn") as PackedScene
	if packed == null:
		failures.append("Diagnostics scene does not load")
		return
	var instance := packed.instantiate()
	if instance == null: failures.append("Diagnostics scene does not instantiate")
	else: instance.free()


func check_pointer_capture_policy() -> void:
	if PointerCaptureController.needs_capture(true, Input.MOUSE_MODE_VISIBLE):
		failures.append("Touch gameplay must never request desktop pointer capture")
	if PointerCaptureController.needs_capture(false, Input.MOUSE_MODE_CAPTURED):
		failures.append("Captured desktop pointer must not request another activation")
	if not PointerCaptureController.needs_capture(false, Input.MOUSE_MODE_VISIBLE):
		failures.append("Visible desktop pointer must request click-to-aim activation")
	if not PointerCaptureController.needs_capture(false, Input.MOUSE_MODE_CONFINED):
		failures.append("Confined desktop pointer is not sufficient for relative mouse aiming")


func check_close(label: String, actual: float, expected: float, tolerance := 0.0001) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.4f, got %.4f" % [label, expected, actual])
