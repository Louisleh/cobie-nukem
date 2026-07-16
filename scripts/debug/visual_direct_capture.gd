extends Node

var _target: Node
var _frame := 0
var _cleanup_frame := 60
var _staging_id := ""
var _staged := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var target_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-size="):
			_apply_capture_size(argument.trim_prefix("--capture-size="))
		elif argument.begins_with("--capture-seed="):
			seed(int(argument.trim_prefix("--capture-seed=")))
		elif argument.begins_with("--target-scene="):
			target_path = argument.trim_prefix("--target-scene=")
		elif argument.begins_with("--cleanup-frame="):
			_cleanup_frame = maxi(10, int(argument.trim_prefix("--cleanup-frame=")))
		elif argument.begins_with("--staging-id="):
			_staging_id = argument.trim_prefix("--staging-id=")
		elif argument.begins_with("--physics-tps="):
			Engine.physics_ticks_per_second = clampi(int(argument.trim_prefix("--physics-tps=")), 10, 240)
	if not target_path.begins_with("res://"):
		push_error("Visual direct capture requires --target-scene=res://...")
		get_tree().quit(1)
		return
	var packed := load(target_path) as PackedScene
	if packed == null:
		push_error("Visual direct capture could not load %s" % target_path)
		get_tree().quit(1)
		return
	_target = packed.instantiate()
	if target_path.ends_with("/title_screen.tscn"):
		_target.set("play_intro_audio", false)
	add_child(_target)
	_suppress_focus_pause()


func _apply_capture_size(size_value: String) -> void:
	var parts := size_value.to_lower().split("x")
	if parts.size() != 2:
		push_error("Invalid direct visual capture size: %s" % size_value)
		return
	var requested := Vector2i(maxi(320, int(parts[0])), maxi(240, int(parts[1])))
	get_window().size = requested
	var logical_width := maxi(320, roundi(360.0 * float(requested.x) / float(requested.y)))
	get_window().content_scale_size = Vector2i(logical_width, 360)


func _process(_delta: float) -> void:
	if get_tree().paused:
		get_tree().paused = false
	_suppress_focus_pause()
	_stage_target_when_ready()
	if _frame == _cleanup_frame and is_instance_valid(_target):
		_stop_target_audio()
		_target.queue_free()
	if _frame >= _cleanup_frame + 12:
		get_tree().quit(0)
	_frame += 1


func _suppress_focus_pause() -> void:
	if not is_instance_valid(_target):
		return
	for pause_menu in _target.find_children("*", "PauseMenu", true, false):
		pause_menu.set_suppressed(true)


func _stop_target_audio() -> void:
	if not is_instance_valid(_target):
		return
	for sound in _target.find_children("*", "ProceduralAudio", true, false):
		sound.stop_all()
	for player in _target.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
		player.stream = null


func _stage_target_when_ready() -> void:
	if _staged or _staging_id != "waterfront_seawall" or not is_instance_valid(_target):
		return
	var player := _target.get("player") as Node3D
	if player == null:
		return
	player.global_position = Vector3(0.0, 1.1, -73.0)
	player.set("velocity", Vector3.ZERO)
	player.rotation = Vector3.ZERO
	var head := player.get_node_or_null("Head") as Node3D
	if head != null:
		head.rotation = Vector3.ZERO
	player.reset_physics_interpolation()
	if _target.has_method("_submit_route_position"):
		_target.call("_submit_route_position", player.global_position)
	_staged = true
