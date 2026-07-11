extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	for bus_name in [&"Master", &"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			failures.append("Missing audio bus: %s" % bus_name)
	for path in [
		"res://scenes/menus/title_screen.tscn",
		"res://scenes/menus/main_menu.tscn",
		"res://scenes/menus/level_select.tscn",
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
	_check_level_select_contract()
	_check_responsive_title_contract()
	_check_responsive_main_menu_contract()
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

func _check_level_select_contract() -> void:
	var packed := load("res://scenes/menus/level_select.tscn") as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate()
	var levels: Array = instance.get("levels")
	if levels.size() < 4:
		failures.append("Level select needs one active and multiple future cards")
	else:
		var unlocked := 0
		for data in levels:
			if data.unlocked:
				unlocked += 1
				if data.scene_path.is_empty():
					failures.append("Unlocked level card has no route")
			elif not data.scene_path.is_empty():
				failures.append("Locked level card must not route to a scene")
		if unlocked != 1:
			failures.append("Exactly one level must be unlocked in the release candidate")
	var scroll := instance.get_node_or_null("SafeArea/Main/CourseScroll") as ScrollContainer
	if scroll == null or scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		failures.append("Level cards must remain reachable in narrow viewports")
	instance.free()

func _check_responsive_title_contract() -> void:
	var packed := load("res://scenes/menus/title_screen.tscn") as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate()
	var art := instance.get_node_or_null("ArtColumn") as Control
	var cover := instance.get_node_or_null("ArtColumn/Cover") as TextureRect
	var brand := instance.get_node_or_null("BrandPanel") as Control
	if art == null or brand == null or cover == null:
		failures.append("Title needs separate responsive art and brand safe areas")
	elif cover.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		failures.append("Title art must preserve the complete Cobie composition")
	instance.free()

func _check_responsive_main_menu_contract() -> void:
	var packed := load("res://scenes/menus/main_menu.tscn") as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate()
	var cover := instance.get_node_or_null("Cover") as TextureRect
	var menu := instance.get_node_or_null("MenuPanel") as Control
	if cover == null or menu == null:
		failures.append("Main menu needs separate art and interaction columns")
	elif cover.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		failures.append("Main menu must preserve the complete Cobie composition")
	elif menu.anchor_left < 0.4 or menu.anchor_right != 1.0:
		failures.append("Main menu interaction column must use responsive anchors")
	instance.free()
