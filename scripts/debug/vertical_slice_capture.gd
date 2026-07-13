extends Node

@onready var level: EpisodeOneLevel = $Episode1Level1

var _frame := 0
var _ready_for_capture := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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


func _process(_delta: float) -> void:
	if get_tree().paused:
		get_tree().paused = false
	if not _ready_for_capture:
		return
	match _frame:
		5:
			_stage_zone(Vector3(0.0, 1.1, 10.0), &"forbidden_field", "CAPTURE: FORBIDDEN FIELD")
		35:
			_stage_zone(Vector3(0.0, 1.1, -30.0), &"equipment_shed", "CAPTURE: EQUIPMENT SHED")
		65:
			_stage_zone(Vector3(0.0, 1.1, -60.0), &"maintenance_tunnels", "CAPTURE: MAINTENANCE TUNNELS")
		95:
			_stage_zone(Vector3(0.0, 1.1, -100.0), &"compliance_lab", "CAPTURE: COMPLIANCE LAB")
		125:
			_stage_zone(Vector3(0.0, 1.1, -139.0), &"walker_arena", "CAPTURE: WALKER ARENA")
		155:
			level.player.global_position.y = -20.0
			level.player._check_out_of_bounds()
		185:
			level.restart_from_checkpoint()
			level._finalize_level_completion()
		210:
			_ready_for_capture = false
			level.queue_free()
	_frame += 1


func _stage_zone(position_value: Vector3, zone_id: StringName, label: String) -> void:
	var player := level.player as CobiePlayer
	player.global_position = position_value
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	player.reset_physics_interpolation()
	level._enter_zone(zone_id, label, player)


func _silence_capture_audio() -> void:
	# Evidence capture verifies visual state. Keeping generated AudioStreamWAV
	# playbacks alive while MovieWriter tears down would add false-positive leak
	# noise unrelated to the scene state being captured.
	for sound in level.find_children("*", "ProceduralAudio", true, false):
		sound.set("_player", null)
