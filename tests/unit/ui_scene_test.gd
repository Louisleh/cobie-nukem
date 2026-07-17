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
	await _check_level_select_activation_contract()
	await _check_difficulty_selector_contract()
	await _check_responsive_title_contract()
	_check_responsive_main_menu_contract()
	_check_cobie_portrait_contract()
	await _check_death_screen_contract()
	await _check_caption_contracts()
	await _check_boss_hud_contract()
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
		failures.append("Level select needs two playable and three future cards")
	else:
		var always_available := 0
		var campaign_routes := 0
		var locked_teasers := 0
		var beta_cards := 0
		for data in levels:
			if data.preview == null:
				failures.append("Every level card needs illustrated preview art: %s" % data.level_id)
			match data.unlock_policy:
				LevelCardData.UnlockPolicy.ALWAYS:
					always_available += 1
					if data.scene_path.is_empty():
						failures.append("Always-available level card has no route")
				LevelCardData.UnlockPolicy.CAMPAIGN:
					campaign_routes += 1
					if data.scene_path.is_empty() or data.prerequisite_mission_id == &"":
						failures.append("Campaign level card needs a route and prerequisite")
				LevelCardData.UnlockPolicy.LOCKED_TEASER:
					locked_teasers += 1
					if not data.scene_path.is_empty():
						failures.append("Locked teaser card must not route to a scene")
			if data.release_badge.strip_edges().to_upper() == "BETA":
				beta_cards += 1
				if data.launch_notice.strip_edges().is_empty():
					failures.append("Beta level card needs a visible work-in-progress notice")
		if always_available != 2 or campaign_routes != 0 or locked_teasers != 3:
			failures.append("Level select must expose Salmon Creek and public Rain City plus three locked teasers")
		if beta_cards != 1:
			failures.append("Exactly one public route must carry the BETA badge")
	var scroll := instance.get_node_or_null("SafeArea/Main/CourseScroll") as ScrollContainer
	if scroll == null or scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		failures.append("Level cards must remain reachable in narrow viewports")
	instance.free()


func _check_level_select_activation_contract() -> void:
	var packed := load("res://scenes/menus/level_select.tscn") as PackedScene
	if packed == null:
		return
	# Keep the test dynamically typed so loading this scene does not force its
	# global class ahead of the project's autoload names in a fresh headless HOME.
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	var sounds := instance.get_node_or_null("ProceduralAudio")
	if sounds != null:
		sounds.set("_player", null)
	var row := instance.get_node_or_null("SafeArea/Main/CourseScroll/CardRow") as HBoxContainer
	if row == null or row.get_child_count() == 0:
		failures.append("Level select needs selectable mission cards")
	else:
		var first_card := row.get_child(0) as Button
		var rain_city_card := row.get_child(1) as Button
		var locked_card := row.get_child(2) as Button
		var title := instance.get_node_or_null("SafeArea/Main/MissionPanel/MissionMargin/Mission/Info/LevelTitle") as Label
		var play := instance.get_node_or_null("SafeArea/Main/Footer/PlayButton") as Button
		var selects_only := false
		for connection in first_card.pressed.get_connections():
			var callable: Callable = connection.get("callable", Callable())
			if callable.is_valid() and callable.get_method() == &"_on_card_pressed":
				selects_only = true
				break
		if not selects_only:
			failures.append("Mission-card press must select only; explicit Start owns scene launch")
		var initial_title := title.text if title != null else ""
		var initial_action := play.text if play != null else ""
		locked_card.emit_signal("mouse_entered")
		locked_card.emit_signal("focus_entered")
		if int(instance.get("_selected")) != 0 or (title != null and title.text != initial_title) or (play != null and play.text != initial_action):
			failures.append("Hover and focus must not commit a different mission selection")
		locked_card.emit_signal("pressed")
		if int(instance.get("_selected")) != 2 or (play != null and (play.text != "LOCKED" or not play.disabled)):
			failures.append("Activating a locked teaser must commit its details and a disabled LOCKED action")
		rain_city_card.emit_signal("pressed")
		if int(instance.get("_selected")) != 1 or (play != null and (play.text != "START BETA" or play.disabled)):
			failures.append("Rain City must be an immediately launchable public BETA selection")
		locked_card.emit_signal("mouse_entered")
		if int(instance.get("_selected")) != 1 or (play != null and play.text != "START BETA"):
			failures.append("Crossing a locked card on the way to Start must preserve the committed Rain City selection")
		first_card.emit_signal("pressed")
		if int(instance.get("_selected")) != 0 or bool(instance.get("_launching")):
			failures.append("Mission-card click must update selection without entering launch state")
		var status := instance.get_node_or_null("SafeArea/Main/Footer/StatusLabel") as Label
		if status == null or "PRESS START" not in status.text:
			failures.append("Selected mission must clearly instruct the player to press Start")
	instance.free()
	await process_frame

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
	# Threaded resource completion is scheduler-dependent. Poll the product state
	# with a strict bound instead of assuming Linux and macOS finish in six frames.
	for _frame in 60:
		if instance.can_accept_input():
			break
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
		"res://assets/ui/portraits/cobie_critical.png",
	]:
		var texture := load(path) as Texture2D
		if texture == null or texture.get_width() != 512 or texture.get_height() != 512:
			failures.append("Cobie HUD portrait must be a loadable 512x512 Retina-ready texture: " + path)
	if ResourceLoader.exists("res://assets/ui/portraits/cobie_hurt.png"):
		failures.append("Cobie HUD must expose only the selected healthy and critical portrait assets")
	var portrait := CobiePortrait.new()
	portrait.health_ratio = 1.0
	if portrait.portrait_state() != CobiePortrait.State.HEALTHY: failures.append("65-100% health must use healthy Cobie portrait")
	portrait.health_ratio = 0.65
	if portrait.portrait_state() != CobiePortrait.State.HEALTHY: failures.append("65% boundary must remain healthy")
	portrait.health_ratio = 0.649
	if portrait.portrait_state() != CobiePortrait.State.CRITICAL: failures.append("Below 65% health must use critical Cobie portrait")
	portrait.free()
	var packed := load("res://scenes/ui/hud.tscn") as PackedScene
	if packed != null:
		var hud := packed.instantiate()
		var runtime_portrait := hud.get_node_or_null("Root/BottomBar/CobiePortrait") as Control
		if runtime_portrait == null or minf(runtime_portrait.size.x, runtime_portrait.size.y) < 100.0:
			failures.append("Cobie portrait must retain at least a 100px logical edge for 4:3 iPad readability")
		hud.free()


func _check_boss_hud_contract() -> void:
	var packed := load("res://scenes/ui/hud.tscn") as PackedScene
	if packed == null:
		failures.append("HUD scene must load for boss presentation contracts")
		return
	var hud := packed.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame
	hud.set_boss_state("ANIMAL CONTROL WALKER", &"cannons", 1.0)
	if not hud.boss_panel.visible or not is_equal_approx(hud.boss_health_bar.value, 1.0):
		failures.append("Boss HUD shows the live Walker at full health")
	var viewport_width := root.get_visible_rect().size.x
	if hud.boss_panel.size.x > 461.0 or hud.boss_panel.position.x < viewport_width * 0.5:
		failures.append("Boss HUD remains compact and anchored to the right half of the viewport")
	var tablet_layout := hud._boss_layout_for(Vector2(480.0, 360.0))
	if tablet_layout.position.x > 20.0 or tablet_layout.size.x > 221.0 or tablet_layout.end.x > 240.0 or tablet_layout.position.y < 96.0:
		failures.append("Boss HUD uses the compact left safety lane at tablet 4:3 instead of overlapping right actions: %s" % tablet_layout)
	hud.set_boss_state("ANIMAL CONTROL WALKER", &"defeated", 0.0)
	if not hud.boss_panel.visible or not is_zero_approx(hud.boss_health_bar.value) or hud.boss_health_label.text != "0% HEALTH":
		failures.append("Boss HUD visibly reaches zero during the defeat spectacle")
	hud._hide_boss_panel()
	hud.queue_free()
	await process_frame

func _check_caption_contracts() -> void:
	var packed := load("res://scenes/ui/hud.tscn") as PackedScene
	if packed == null:
		failures.append("HUD scene must load for caption contracts")
		return
	var settings := root.get_node_or_null("/root/SettingsManager")
	if settings == null:
		failures.append("SettingsManager autoload required for caption contract")
		return
	var old_subtitles := bool(settings.get_value("accessibility", "subtitles", true))
	var old_text_scale := float(settings.get_value("accessibility", "text_scale", 1.0))
	var hud := packed.instantiate()
	var pointer_prompt := hud.get_node_or_null("Root/PointerCapturePrompt") as Control
	if pointer_prompt == null:
		failures.append("HUD needs a click-to-aim pointer recovery prompt")
	elif pointer_prompt.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		failures.append("Pointer recovery prompt must not consume its activation click")
	root.add_child(hud)
	await process_frame
	hud.show_caption("storyline cue", 0, 0.05, "caption-story")
	hud.show_caption("enemy telegraph warning", 2, 0.05, "caption-warning")
	if not hud.get_caption_text().contains("ENEMY TELEGRAPH WARNING"):
		failures.append("Higher-priority enemy warning should preempt narrative cue")
	hud.show_caption("enemy telegraph warning", 2, 0.05, "caption-warning")
	if hud.get_caption_queue_size() > 4 - 1:
		failures.append("Duplicate dedupe key should not overfill caption queue")
	for index in 6:
		hud.show_caption("CAPTION SPAM %d" % index, 0, 0.05, "caption-spam-%d" % index)
	if hud.get_caption_queue_size() > 4:
		failures.append("Caption queue must remain within hard cap")
	hud.clear_captions()
	settings.set_value("accessibility", "subtitles", false, false)
	hud.show_caption("subtitles disabled", 0, 0.05, "caption-disabled")
	if hud.get_caption_queue_size() != 0 or hud.is_caption_visible():
		failures.append("Captions should hide and stop when subtitles are disabled")
	settings.set_value("accessibility", "subtitles", old_subtitles, false)
	settings.set_value("accessibility", "text_scale", old_text_scale, false)
	for viewport in [Vector2i(1280, 720), Vector2i(1680, 1050), Vector2i(1024, 768), Vector2i(3440, 1440)]:
		root.size = viewport
		hud.clear_captions()
		await process_frame
		hud.show_caption("VIEWPORT CAPTION BOUNDS CHECK", 0, 0.05, "caption-viewport-%s" % viewport)
		await process_frame
		var caption: Control = hud.get_node_or_null("Root/CaptionLabel")
		if caption == null:
			failures.append("HUD caption label should exist for bounds checks")
			continue
		var bounds: Rect2 = caption.get_global_rect()
		var viewport_rect := Rect2(Vector2.ZERO, viewport)
		if not viewport_rect.encloses(bounds):
			failures.append("Caption label must stay within viewport in bounds %s: x=%s y=%s w=%s h=%s" % [viewport, bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y])
	root.size = Vector2i(1280, 720)
	hud.queue_free()
	await process_frame


func _check_death_screen_contract() -> void:
	var packed := load("res://scenes/ui/death_screen.tscn") as PackedScene
	if packed == null:
		failures.append("Death screen scene must load")
		return
	var screen := packed.instantiate() as DeathScreen
	root.add_child(screen)
	await process_frame
	screen.show_death()
	var fallback_text := String(screen.get_node("Panel/VBox/QuipLabel").text)
	if not screen.visible or fallback_text.is_empty():
		failures.append("Default death path must show a fallback quip")
	var authored: Array[String] = ["TEST QUIP"]
	screen.show_death(authored)
	if screen.get_node("Panel/VBox/QuipLabel").text != "TEST QUIP":
		failures.append("Authored death quips must retain their typed-array contract")
	screen.queue_free()
	await process_frame
