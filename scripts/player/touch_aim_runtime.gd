class_name TouchAimRuntime
extends RefCounted

var profile: TouchAimProfile
var turn_boost := true
var filtered := Vector2.ZERO
var outer_hold := 0.0

func reset() -> void:
	filtered = Vector2.ZERO
	outer_hold = 0.0

func select_profile(value: String) -> void:
	var paths := {
		"precision": "res://resources/player/touch_aim_precision.tres",
		"balanced": "res://resources/player/touch_aim_balanced.tres",
		"fast": "res://resources/player/touch_aim_fast.tres",
	}
	profile = load(paths.get(value.to_lower(), paths["balanced"])) as TouchAimProfile
	reset()

func resolve(raw: Vector2, delta: float, friction: float) -> Vector2:
	if profile == null or raw.length_squared() <= 0.0001:
		reset()
		return Vector2.ZERO
	var shaped := profile.shape(raw)
	if shaped == Vector2.ZERO:
		reset()
		return Vector2.ZERO
	filtered = filtered.lerp(shaped, profile.smoothing_weight(delta))
	outer_hold = outer_hold + delta if raw.length() >= profile.boost_threshold else 0.0
	var boost := profile.boost_multiplier if turn_boost and outer_hold >= profile.boost_delay else 1.0
	return filtered * boost * friction
