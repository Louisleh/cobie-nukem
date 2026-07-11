extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	for bus_name in [&"Master", &"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			failures.append("Missing audio bus: %s" % bus_name)
	for path in [
		"res://scenes/menus/title_screen.tscn",
		"res://scenes/menus/main_menu.tscn",
		"res://scenes/menus/options_menu.tscn",
		"res://scenes/menus/credits.tscn",
		"res://scenes/ui/hud.tscn",
		"res://scenes/ui/pause_menu.tscn",
		"res://scenes/ui/death_screen.tscn",
		"res://scenes/ui/victory_screen.tscn",
		"res://scenes/ui/end_rank_screen.tscn",
		"res://scenes/ui/retro_overlay.tscn",
		"res://scenes/ui/weapon_overlay.tscn",
		"res://scenes/ui/combat_audio_bridge.tscn",
	]:
		_check_scene(path)
	if failures.is_empty():
		print("UI SCENE TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check_scene(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Could not load: " + path)
		return
	var instance := packed.instantiate()
	if instance == null:
		failures.append("Could not instantiate: " + path)
	else:
		instance.free()
