extends Node

@onready var level: EpisodeOneLevel = $Episode1Level1

var _frame := 0
var _ready_for_capture := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_capture_settings()
	get_tree().paused = false
	# The level suppresses presentation during its child _ready() so startup
	# notifications cannot begin audio before this visual-only harness can mute
	# it. Build the real HUD/death/victory layer now, then silence it.
	level._setup_presentation()
	var pause_menu := level.find_child("PauseMenu", true, false) as PauseMenu
	if pause_menu != null:
		# MovieWriter causes an application-focus notification on macOS. Suppress
		# that input-only pause path so the evidence runner can advance through
		# the real mission states without changing production pause behavior.
		pause_menu.set_suppressed(true)
	level.level_ready.connect(func(_player: Node3D) -> void:
		_silence_capture_audio()
		_ready_for_capture = true
	)
	if level.player != null:
		_silence_capture_audio()
		_ready_for_capture = true
	if _force_touch_requested():
		for controls in level.find_children("*", "MobileControls", true, false):
			controls.force_visible = true
			controls.set("_touch_enabled", true)
			controls.visible = true
			controls.queue_redraw()


func _apply_capture_settings() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-size="):
			_apply_capture_size(argument.trim_prefix("--capture-size="))
		elif argument.begins_with("--capture-seed="):
			seed(int(argument.trim_prefix("--capture-seed=")))
		elif argument.begins_with("--physics-tps="):
			var requested := int(argument.trim_prefix("--physics-tps="))
			Engine.physics_ticks_per_second = clampi(requested, 10, 240)


func _apply_capture_size(size_value: String) -> void:
	var parts := size_value.to_lower().split("x")
	if parts.size() != 2:
		push_error("Invalid visual capture size: %s" % size_value)
		return
	var requested := Vector2i(maxi(320, int(parts[0])), maxi(240, int(parts[1])))
	get_window().size = requested
	# Preserve the game's 360 logical-pixel art direction while exposing the
	# requested aspect ratio to anchors and responsive layout code.
	var logical_width := maxi(320, roundi(360.0 * float(requested.x) / float(requested.y)))
	get_window().content_scale_size = Vector2i(logical_width, 360)


func _force_touch_requested() -> bool:
	return OS.get_cmdline_user_args().has("--force-touch")


func _process(_delta: float) -> void:
	if get_tree().paused:
		get_tree().paused = false
	if not _ready_for_capture:
		# A warm import/cache can complete the level's ready path between this
		# harness's child-ready notification and signal connection. Recover from
		# that ordering deterministically instead of recording hundreds of copies
		# of frame zero.
		if level.player == null:
			return
		_silence_capture_audio()
		_ready_for_capture = true
	match _frame:
		5:
			_stage_player_only(Vector3(0.0, 1.1, 10.0))
		15:
			_stage_zone(Vector3(0.0, 1.1, 10.0), &"forbidden_field", "CAPTURE: FORBIDDEN FIELD")
		35:
			_stage_zone(Vector3(0.0, 1.1, -30.0), &"equipment_shed", "CAPTURE: EQUIPMENT SHED")
		65:
			_stage_zone(Vector3(0.0, 1.1, -60.0), &"maintenance_tunnels", "CAPTURE: MAINTENANCE TUNNELS")
		95:
			_stage_zone(Vector3(0.0, 1.1, -100.0), &"compliance_lab", "CAPTURE: COMPLIANCE LAB")
		125:
			_stage_zone(Vector3(0.0, 1.1, -139.0), &"walker_arena", "CAPTURE: WALKER ARENA")
		146:
			_stage_walker_defeat()
		155:
			level.player.global_position.y = -20.0
			level.player._check_out_of_bounds()
		185:
			level.restart_from_checkpoint()
			level._finalize_level_completion()
		210:
			_ready_for_capture = false
			level.queue_free()
			set_process(false)
	_frame += 1


func _stage_player_only(position_value: Vector3) -> void:
	var player := level.player as CobiePlayer
	player.global_position = position_value
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	player.reset_physics_interpolation()


func _stage_zone(position_value: Vector3, zone_id: StringName, label: String) -> void:
	var player := level.player as CobiePlayer
	player.global_position = position_value
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	player.reset_physics_interpolation()
	level._enter_zone(zone_id, label, player)


func _stage_walker_defeat() -> void:
	var walker := level._walker as AnimalControlWalker
	if not is_instance_valid(walker):
		push_error("Walker defeat capture requires a live Walker")
		return
	# One deterministic hit per authored boundary, followed by the authoritative
	# final hit. This preserves the active-arena frame while adding evidence that
	# the HUD reaches zero and the bounded defeat spectacle actually renders.
	for _phase in range(4):
		walker.apply_damage(10000.0, level.player, walker.get_auto_aim_position())


func _silence_capture_audio() -> void:
	# Evidence capture verifies visual state. Keeping generated AudioStreamWAV
	# playbacks alive while MovieWriter tears down would add false-positive leak
	# noise unrelated to the scene state being captured.
	for sound in level.find_children("*", "ProceduralAudio", true, false):
		sound.set("_player", null)
