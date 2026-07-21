class_name PlayerRuntimeSettings
extends RefCounted


static func apply(player: Node, settings: Node) -> void:
	if player == null or settings == null or not settings.has_method("get_value"):
		return
	player.mouse_sensitivity = player._base_mouse_sensitivity * clampf(float(settings.get_value(&"gameplay", &"mouse_sensitivity", 1.0)), 0.25, 3.0)
	player.camera.fov = clampf(float(settings.get_value(&"video", &"fov", 90.0)), 70.0, 110.0)
	player.head_bob_amount = player._base_head_bob_amount * clampf(float(settings.get_value(&"accessibility", &"head_bob", 1.0)), 0.0, 1.0)
	if bool(settings.get_value(&"accessibility", &"reduced_motion", false)):
		player.head_bob_amount = 0.0
	var touch_fallback := float(settings.get_value(&"gameplay", &"touch_sensitivity", 1.0))
	player._touch_horizontal_sensitivity = clampf(float(settings.get_value(&"gameplay", &"touch_horizontal_sensitivity", touch_fallback)), 0.25, 3.0)
	player._touch_vertical_sensitivity = clampf(float(settings.get_value(&"gameplay", &"touch_vertical_sensitivity", touch_fallback)), 0.25, 3.0)
	player._touch_invert_y = bool(settings.get_value(&"gameplay", &"touch_invert_y", false))
	player._touch_aim.select_profile(String(settings.get_value(&"gameplay", &"touch_aim_preset", "balanced")))
	player.touch_aim_profile = player._touch_aim.profile
	player._touch_turn_boost = bool(settings.get_value(&"gameplay", &"touch_turn_boost", true))
	player._touch_aim.turn_boost = player._touch_turn_boost
	player._touch_aim_friction = TouchAimProfile.friction_strength(String(settings.get_value(&"gameplay", &"touch_aim_friction", "standard")))
	player._surface_movement_mode = String(settings.get_value(&"gameplay", &"surface_movement", "full"))
	player._movement_environment_mode = String(settings.get_value(&"gameplay", &"movement_environment", "full"))
