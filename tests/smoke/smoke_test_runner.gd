extends SceneTree

var failures: Array[String] = []
var pending: Array[String] = []
var scene_count := 0
var resource_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_scan_scenes("res://scenes")
	_scan_resources("res://resources")
	_expect_resource("res://default_bus_layout.tres")
	_expect_scene("res://scenes/boot/boot.tscn", true)
	_expect_scene("res://scenes/player/cobie_player.tscn", true)
	_expect_scene("res://scenes/debug/input_diagnostics.tscn", true)
	_check_category("res://scenes/menus", "menu")
	_check_category("res://scenes/levels", "playable level")
	_expect(FileAccess.file_exists("res://export_presets.cfg"), "export presets exist")
	await _runtime_boot("res://scenes/boot/boot.tscn")
	for runtime_scene in [
		"res://scenes/menus/main_menu.tscn",
		_first_scene("res://scenes/levels"),
		"res://scenes/debug/input_diagnostics.tscn",
	]:
		if not runtime_scene.is_empty():
			await _runtime_boot(runtime_scene)
	_stop_test_audio()
	await create_timer(0.1).timeout
	for item in pending:
		print("PENDING: " + item)
	if failures.is_empty():
		print("PASS: %d scenes and %d resources load; boot/menu/level/diagnostics enter tree" % [scene_count, resource_count])
		quit(0)
	else:
		for failure in failures:
			push_error("SMOKE: " + failure)
		quit(1)

func _scan_scenes(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		failures.append("Cannot open scene directory: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_scan_scenes(path)
		elif entry.ends_with(".tscn"):
			_expect_scene(path, true)
		entry = directory.get_next()
	directory.list_dir_end()

func _expect_scene(path: String, required: bool) -> void:
	if not ResourceLoader.exists(path, "PackedScene"):
		if required:
			failures.append("Missing scene: %s" % path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Cannot load scene: %s" % path)
		return
	var instance := packed.instantiate()
	if instance == null:
		failures.append("Cannot instantiate scene: %s" % path)
	else:
		scene_count += 1
		instance.free()

func _scan_resources(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		failures.append("Cannot open resource directory: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_scan_resources(path)
		elif entry.ends_with(".tres"):
			_expect_resource(path)
		entry = directory.get_next()
	directory.list_dir_end()

func _expect_resource(path: String) -> void:
	var resource := load(path)
	if resource == null:
		failures.append("Cannot load resource: %s" % path)
	else:
		resource_count += 1

func _check_category(path: String, label: String) -> void:
	if _first_scene(path).is_empty():
		pending.append("No %s scene exists under %s" % [label, path])

func _first_scene(path: String) -> String:
	var directory := DirAccess.open(path)
	if directory == null:
		return ""
	var entries := directory.get_files()
	entries.sort()
	for entry in entries:
		if entry.ends_with(".tscn"):
			return path.path_join(entry)
	return ""

func _runtime_boot(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	if not is_instance_valid(instance) or not instance.is_inside_tree():
		failures.append("Scene does not survive two frames: %s" % path)
	elif is_instance_valid(instance):
		_stop_audio_under(instance)
		instance.queue_free()
		await process_frame

func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _stop_test_audio() -> void:
	_stop_audio_under(root)

func _stop_audio_under(parent: Node) -> void:
	for node in parent.find_children("*", "AudioStreamPlayer", true, false):
		var player := node as AudioStreamPlayer
		player.stop()
		player.stream = null
	for node in parent.find_children("*", "AudioStreamPlayer2D", true, false):
		var player_2d := node as AudioStreamPlayer2D
		player_2d.stop()
		player_2d.stream = null
	for node in parent.find_children("*", "AudioStreamPlayer3D", true, false):
		var player_3d := node as AudioStreamPlayer3D
		player_3d.stop()
		player_3d.stream = null
