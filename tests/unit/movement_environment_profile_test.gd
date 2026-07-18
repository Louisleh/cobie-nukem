extends SceneTree

var failures := 0


func _init() -> void:
	var profile := MovementEnvironmentProfile.new()
	profile.id = &"lunar"
	profile.gravity_multiplier = 0.34
	profile.jump_multiplier = 1.42
	profile.air_control_multiplier = 1.18
	profile.terminal_fall_speed = 18.0
	_check(profile.validate().is_empty(), "valid lunar profile")
	_check(is_equal_approx(profile.multiplier(0.34, "full"), 0.34), "full strength")
	_check(is_equal_approx(profile.multiplier(0.34, "reduced"), 0.67), "reduced halfway")
	_check(is_equal_approx(profile.multiplier(0.34, "assisted"), 1.0), "assisted normalizes")
	profile.gravity_multiplier = 0.0
	_check(not profile.validate().is_empty(), "invalid gravity rejected")
	if failures == 0:
		print("MOVEMENT ENVIRONMENT PROFILE TEST: PASS")
		quit(0)
	else:
		push_error("MOVEMENT ENVIRONMENT PROFILE TEST: %d failure(s)" % failures)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
