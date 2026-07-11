extends SceneTree

const REQUIRED_ACTIONS := [
	"move_forward", "move_backward", "strafe_left", "strafe_right",
	"look_left", "look_right", "look_up", "look_down", "fire_primary",
	"fire_secondary", "use", "jump", "run", "weapon_next",
	"weapon_previous", "pause", "menu_accept", "menu_back",
]

var failures: Array[String] = []

func _initialize() -> void:
	_check_project_contract()
	_check_scene("res://scenes/boot/boot.tscn")
	if failures.is_empty():
		print("PASS: core contract checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_project_contract() -> void:
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("Missing input action: %s" % action)
	if ProjectSettings.get_setting("rendering/renderer/rendering_method") != "gl_compatibility":
		failures.append("Compatibility renderer is not configured")
	if ProjectSettings.get_setting("display/window/size/viewport_width") != 320:
		failures.append("Internal viewport width must be 320")
	if ProjectSettings.get_setting("display/window/size/viewport_height") != 180:
		failures.append("Internal viewport height must be 180")

func _check_scene(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Could not load critical scene: %s" % path)
		return
	var instance := packed.instantiate()
	if instance == null:
		failures.append("Could not instantiate critical scene: %s" % path)
	else:
		instance.free()

