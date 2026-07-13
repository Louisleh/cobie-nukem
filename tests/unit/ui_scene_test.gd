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
	await _check_difficulty_selector_contract()
	await _check_responsive_title_contract()
	_check_responsive_main_menu_contract()
	_check_cobie_portrait_contract()
	if failures.is_empty():
		print("UI SCENE TESTS: PASS")
		call_deferred("_quit_after_cleanup", 0)
	else:
		for failure in failures:
			push_error(failure)
		call_deferred("_quit_after_cleanup", 1)


func _quit_after_cleanup(exit_code: int) -> void:
	# Let _initialize() return so coroutine locals and temporary Resources release
	# before SceneTree teardown. Quitting inside the awaited initializer leaves one
	# RefCounted alive during ObjectDB cleanup on Godot 4.7.
	await process_frame
	quit(exit_code)

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
	if levels.size() != 5:
		failures.append("Level select needs one active and four future cards")
	else:
		var unlocked := 0
		for data in levels:
			if data.preview == null:
				failures.append("Every level card needs illustrated preview art: %s" % data.level_id)
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

func _check_difficulty_selector_contract() -> void:
	var packed := load("res://scenes/menus/level_select.tscn") as PackedScene
	var game_state := root.get_node_or_null("GameState")
	var save_manager := root.get_node_or_null("SaveManager")
	if packed == null or game_state == null:
		failures.append("Difficulty selector contract needs level_select and GameState")
		return
	game_state.select_difficulty(&"classic")
	if save_manager != null:
		save_manager.save_slot(&"qa_difficulty_guard", {"marker": true})
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	var sounds := instance.get_node_or_null("ProceduralAudio")
	if sounds != null:
		# Headless runs never release started WAV playbacks before quit(); keep
		# this contract check silent so the leaked-instance gate stays meaningful.
		sounds.set("_player", null)
	var row := instance.get_node_or_null("SafeArea/Main/DifficultySection/DifficultyRow")
	if row == null:
		failures.append("Level select is missing the difficulty row")
		instance.queue_free()
		return
	var buttons: Array[Button] = []
	for child in row.get_children():
		if child is Button and child.toggle_mode:
			buttons.append(child)
	var options: Array = game_state.difficulty_options()
	if buttons.size() != 3:
		failures.append("Difficulty selector must offer exactly three profiles, found %d" % buttons.size())
	else:
		for index in 3:
			if buttons[index].text != options[index].display_name:
				failures.append("Difficulty button label must come from the profile resource: %s" % options[index].id)
		if not buttons[1].button_pressed:
			failures.append("Classic must be the default pressed difficulty")
		if buttons[0].button_pressed or buttons[2].button_pressed:
			failures.append("Only the selected difficulty may appear pressed")
		for button in buttons:
			if button.focus_mode != Control.FOCUS_ALL:
				failures.append("Difficulty buttons must be keyboard/controller focusable")
		buttons[0].emit_signal("pressed")
		if game_state.difficulty_id != &"story":
			failures.append("Pressing a difficulty button must update GameState")
		buttons[2].emit_signal("pressed")
		if game_state.difficulty_id != &"mayhem":
			failures.append("Difficulty selection must be re-selectable")
		var blurb := instance.get_node_or_null("SafeArea/Main/DifficultySection/DifficultyBlurb") as Label
		if blurb == null or blurb.text.is_empty():
			failures.append("Difficulty selector must describe the selected profile")
	if save_manager != null:
		var guard: Dictionary = save_manager.load_slot(&"qa_difficulty_guard")
		if not bool(guard.get("marker", false)):
			failures.append("Opening or using the difficulty selector must not delete saved runs")
		save_manager.delete_slot(&"qa_difficulty_guard")
	game_state.select_difficulty(&"classic")
	instance.free()
	await process_frame


func _check_responsive_title_contract() -> void:
	var packed := load("res://scenes/menus/title_screen.tscn") as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate()
	instance.minimum_warmup_seconds = 0.0
	instance.play_intro_audio = false
	var art := instance.get_node_or_null("ArtColumn") as Control
	var cover := instance.get_node_or_null("ArtColumn/Cover") as TextureRect
	var brand := instance.get_node_or_null("BrandPanel") as Control
	if art == null or brand == null or cover == null:
		failures.append("Title needs separate responsive art and brand safe areas")
	elif cover.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		failures.append("Title art must preserve the complete Cobie composition")
	root.add_child(instance)
	if instance.can_accept_input() or not instance.get_node("BrandPanel/Margin/VBox/Prompt").text.begins_with("PREPARING COBIE"):
		failures.append("Title must show an honest loading state before accepting input")
	for frame in 6:
		await process_frame
	if not instance.can_accept_input():
		failures.append("Title must become input-ready after menu preload completes")
	elif "PRESS" not in instance.get_node("BrandPanel/Margin/VBox/Prompt").text:
		failures.append("Title may show the continue prompt only after readiness")
	instance.free()
	await process_frame

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


func _check_cobie_portrait_contract() -> void:
	for path in [
		"res://assets/ui/portraits/cobie_healthy.png",
		"res://assets/ui/portraits/cobie_hurt.png",
		"res://assets/ui/portraits/cobie_critical.png",
	]:
		var texture := load(path) as Texture2D
		if texture == null or texture.get_width() != 256 or texture.get_height() != 256:
			failures.append("Cobie HUD portrait must be a loadable 256x256 texture: " + path)
	var portrait := CobiePortrait.new()
	portrait.health_ratio = 1.0
	if portrait.portrait_state() != CobiePortrait.State.HEALTHY: failures.append("70-100% health must use healthy Cobie portrait")
	portrait.health_ratio = 0.7
	if portrait.portrait_state() != CobiePortrait.State.HEALTHY: failures.append("70% boundary must remain healthy")
	portrait.health_ratio = 0.69
	if portrait.portrait_state() != CobiePortrait.State.HURT: failures.append("30-70% health must use hurt Cobie portrait")
	portrait.health_ratio = 0.3
	if portrait.portrait_state() != CobiePortrait.State.HURT: failures.append("30% boundary must remain hurt")
	portrait.health_ratio = 0.29
	if portrait.portrait_state() != CobiePortrait.State.CRITICAL: failures.append("0-30% health must use critical Cobie portrait")
	portrait.free()
