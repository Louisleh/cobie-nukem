extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var title = load("res://scenes/menus/title_screen.tscn").instantiate()
	title.play_intro_audio = false
	title.minimum_warmup_seconds = 0.01
	root.add_child(title)
	current_scene = title
	for frame in 600:
		await process_frame
		if title.readiness == title.Readiness.READY:
			break
	_expect(title.readiness == title.Readiness.READY, "Production title preparation reaches ready")
	_expect(title.get("_preloaded_menu") != null, "Title retains the loaded menu before routing")
	_expect(title.get("_pipeline_prewarmer") == null, "Title releases completed pipeline warmup")
	title.queue_free()
	await process_frame
	var select = load("res://scenes/menus/level_select.tscn").instantiate()
	root.add_child(select)
	current_scene = select
	_expect(not select.get("_warmup_requests").is_empty(), "Default runtime queues real mission resources")
	select.call("_select", 1)
	_expect(select.get("_selected") == 1, "Rain City selection remains responsive while preparation is pending")
	for button in select.get("_cards"):
		_expect(not button.disabled, "Mission cards remain available during preparation")
	for frame in 120:
		await process_frame
		if select.get("_warmup_requests").is_empty():
			break
	_expect(select.get("_warmup_ready"), "Real Rain City preparation reaches ready")
	_expect(not select.get("_warmup_resources").is_empty(), "Prepared mission resources stay resident")
	_expect(not select.get_node("%PlayButton").disabled, "Prepared mission can launch")
	select.call("_select", 3)
	_expect(not select.get("_warmup_requests").is_empty(), "Another mission has pending preparation")
	select.call("_back")
	_expect(select.get("_warmup_requests").is_empty(), "Back cancels unstarted work immediately")
	for frame in 5:
		await process_frame
	_expect(current_scene != null and current_scene.scene_file_path == "res://scenes/menus/main_menu.tscn", "Back returns to the main menu")
	if current_scene != null:
		current_scene.queue_free()
	await process_frame
	await process_frame
	# Let the real menu's stopped audio playback drain on the audio thread.
	await create_timer(0.25).timeout
	if failures.is_empty():
		print("RUNTIME MENU RESOURCE WARMUP: PASS")
		_finish.call_deferred(0)
	else:
		for failure in failures:
			push_error(failure)
		_finish.call_deferred(1)

func _finish(exit_code: int) -> void:
	# Release coroutine locals before ObjectDB cleanup.
	await process_frame
	quit(exit_code)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
