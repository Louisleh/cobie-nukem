extends SceneTree

# Staged native lifecycle diagnostic, never ordinary/human acceptance.
# No awaiting probe coroutine crosses Quit; receipts retain scalar identities.
var _ready_frames := 0
var _records: Array[Dictionary] = []
var _pause_id := 0
var _pause_started_usec := 0
var _mission_history_started := false
var _impact_node_ids := PackedInt64Array()
var _impact_pool_weak: WeakRef


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	var router := root.get_node("SceneRouter")
	var scene_path := "res://scenes/menus/main_menu.tscn"
	if OS.get_environment("COBIE_LIFETIME_HISTORY") == "rain_city_pause":
		scene_path = "res://scenes/levels/episode_1_vancouver_waterfront.tscn"
	if router.go_to(scene_path) != OK:
		push_error("LIFETIME PROBE: main-menu route failed")
		quit(2)
		return
	process_frame.connect(_wait_for_menu)


func _wait_for_menu() -> void:
	if current_scene == null or not current_scene.is_node_ready():
		return
	if current_scene.scene_file_path != "res://scenes/menus/main_menu.tscn":
		if not _mission_history_started and current_scene.get("player") != null:
			_mission_history_started = true
			process_frame.disconnect(_wait_for_menu)
			create_timer(0.25, true, false, true).timeout.connect(_pause_mission)
		return
	_ready_frames += 1
	if _ready_frames < 5:
		return
	process_frame.disconnect(_wait_for_menu)
	if _impact_pool_weak != null and not _check_retired_pool():
		quit(2)
		return
	var settle_seconds := OS.get_environment("COBIE_LIFETIME_SETTLE_SECONDS").to_float()
	if settle_seconds > 0.0:
		create_timer(minf(settle_seconds, 1.0), true, false, true).timeout.connect(_exercise_quit)
	else:
		call_deferred("_exercise_quit")


func _pause_mission() -> void:
	var presentation := current_scene.get("_mission_presentation") as Node
	var pause := presentation.call("get_pause_menu") as Node
	if pause == null:
		push_error("LIFETIME PROBE: shipping pause surface missing")
		quit(2)
		return
	_pause_id = pause.get_instance_id()
	if OS.get_environment("COBIE_LIFETIME_TRACK_POOL") == "1":
		if not _track_impact_pool():
			quit(2)
			return
	pause.call("open")
	if not paused or not bool(pause.get("visible")):
		push_error("LIFETIME PROBE: shipping pause did not engage")
		quit(2)
		return
	_pause_started_usec = Time.get_ticks_usec()
	var hold_seconds := clampf(OS.get_environment("COBIE_LIFETIME_PAUSE_SECONDS").to_float(), 0.25, 520.0)
	print("LIFETIME PROBE: staged Rain City pause begins, requested_seconds=", hold_seconds)
	create_timer(hold_seconds, true, false, true).timeout.connect(_return_to_menu)


func _track_impact_pool() -> bool:
	var player := current_scene.get("player") as Node
	var effects := player.get("_impact_effects") as Node
	var pool := effects.get("pool") as RefCounted
	_impact_pool_weak = weakref(pool)
	var all_ids: PackedInt64Array = pool.call("debug_instance_ids")
	var classes: Dictionary = {}
	for id in all_ids:
		var node := instance_from_id(id) as Node
		if node == null:
			continue
		if node.is_inside_tree():
			push_error("LIFETIME PROBE: expected inactive pool node is in scene tree")
			return false
		_impact_node_ids.append(id)
		classes[node.get_class()] = int(classes.get(node.get_class(), 0)) + 1
	if _impact_node_ids.size() != 88:
		push_error("LIFETIME PROBE: unexpected initial impact pool Node count")
		return false
	print("LIFETIME PROBE: owned detached impact Nodes=", _impact_node_ids.size(), " classes=", JSON.stringify(classes))
	pool = null
	return true


func _check_retired_pool() -> bool:
	var surviving_ids := PackedInt64Array()
	for id in _impact_node_ids:
		if is_instance_id_valid(id):
			surviving_ids.append(id)
	var pool_alive := _impact_pool_weak.get_ref() != null
	print("LIFETIME PROBE: retired impact nodes checked=", _impact_node_ids.size(), " survivors=", surviving_ids.size(), " pool_alive=", pool_alive)
	_impact_pool_weak = null
	if not surviving_ids.is_empty() or pool_alive:
		push_error("LIFETIME PROBE: prior mission impact ownership survives menu readiness")
		return false
	return true


func _return_to_menu() -> void:
	var pause := instance_from_id(_pause_id) as Node
	if pause == null or not paused:
		push_error("LIFETIME PROBE: pause owner/state changed during hold")
		quit(2)
		return
	var player := current_scene.get("player") as Node
	var health := player.get_node("HealthArmor")
	var state := {"phase": "mission_before_menu", "pause_elapsed_seconds": float(Time.get_ticks_usec() - _pause_started_usec) / 1000000.0, "health": health.get("health"), "armor": health.get("armor"), "mission_node_id": str(current_scene.get_instance_id()), "orphan_node_count": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)}
	_records.append(state)
	print("LIFETIME PROBE: ", JSON.stringify(state))
	_ready_frames = 0
	process_frame.connect(_wait_for_menu)
	(pause.get_node("%MainMenuButton") as Button).pressed.emit()
	if paused:
		push_error("LIFETIME PROBE: accepted Main Menu route did not release pause")
		quit(2)


func _exercise_quit() -> void:
	var menu := current_scene
	if menu == null or menu.scene_file_path != "res://scenes/menus/main_menu.tscn":
		push_error("LIFETIME PROBE: actual main menu missing")
		quit(2)
		return
	if OS.get_environment("COBIE_LIFETIME_RECEIPT") != "0":
		_snapshot("menu_ready", menu)
	# Shipping handler was connected first: ACCEPT then _quit(), then our
	# synchronous observation before the event loop begins final teardown.
	if OS.get_environment("COBIE_LIFETIME_RECEIPT") != "0":
		(menu.get_node("%QuitButton") as Button).pressed.connect(_observe_quit_requested)
	(menu.get_node("%QuitButton") as Button).pressed.emit()
	if OS.get_environment("COBIE_LIFETIME_REPEAT_QUIT") == "1":
		# Adversarial duplicate emission/direct call within the same dispatch.
		(menu.get_node("%QuitButton") as Button).pressed.emit()
		menu.call("_quit")


func _observe_quit_requested() -> void:
	_snapshot("quit_button_callback_returned", current_scene)
	var destination := OS.get_environment("COBIE_LIFETIME_OUTPUT")
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		push_error("LIFETIME PROBE: scalar receipt could not be written")
		quit(2)
		return
	var history := OS.get_environment("COBIE_LIFETIME_HISTORY")
	if history.is_empty(): history = "main_menu_only"
	file.store_string(JSON.stringify({"scope": "staged native real playback; exact source and configured history define coverage", "history": history, "records": _records}, "\t") + "\n")
	if file.get_error() != OK:
		push_error("LIFETIME PROBE: scalar receipt write failed")
		file.close()
		quit(2)
		return
	file.close()
	print("LIFETIME PROBE: scalar receipt written; actual shipping Quit requested")


func _snapshot(phase: String, menu: Node) -> void:
	var rows: Array[Dictionary] = []
	if OS.get_environment("COBIE_LIFETIME_OBSERVE") != "0":
		_collect_nodes(menu, rows)
		for cue in ProceduralAudio._shared_cache:
			rows.append(_identity(ProceduralAudio._shared_cache[cue], "static procedural cue %s" % cue))
		if ProceduralAudio._menu_music_cache != null:
			rows.append(_identity(ProceduralAudio._menu_music_cache, "static menu music"))
	_records.append({"phase": phase, "tick_usec": Time.get_ticks_usec(), "node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "orphan_node_count": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), "resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), "objects": rows})


func _collect_nodes(node: Node, rows: Array[Dictionary]) -> void:
	var label := String(node.get_path())
	rows.append(_identity(node, label))
	if node is AudioStreamPlayer:
		var voice := node as AudioStreamPlayer
		if voice.stream != null:
			rows.append(_identity(voice.stream, label + " stream"))
		if voice.has_stream_playback():
			var playback := voice.get_stream_playback()
			rows.append(_identity(playback, label + " playback"))
			playback = null
	for child in node.get_children():
		_collect_nodes(child, rows)


func _identity(object: Object, owner_label: String) -> Dictionary:
	var result := {"owner_label": owner_label, "id": str(object.get_instance_id()), "class": object.get_class()}
	if object is Resource:
		result["resource_path"] = (object as Resource).resource_path
	if object is RefCounted:
		result["sampled_refcount_observer_influenced"] = (object as RefCounted).get_reference_count()
	var script := object.get_script() as Script
	if script != null:
		result["script_path"] = script.resource_path
	return result
