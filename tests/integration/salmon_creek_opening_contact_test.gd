extends SceneTree

## Thirty simulated seconds of ordinary mapped input, without capture or direct AI calls.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
const FRAMES := 900
var failures := PackedStringArray()
var shot_frames: Array[int] = []
var telegraph_frames: Array[int] = []
var attack_frames: Array[int] = []
var spawned: Array[EnemyAgent] = []
var start_frame := 0

func _initialize() -> void:
	call_deferred("_run")

func _on_spawned(enemy: Node, zone_id: StringName) -> void:
	if zone_id != &"forbidden_field" or not enemy is EnemyAgent:
		return
	var actor := enemy as EnemyAgent
	spawned.append(actor)
	actor.telegraph_started.connect(func(_kind: StringName, _duration: float) -> void:
		telegraph_frames.append(Engine.get_process_frames() - start_frame))
	actor.attack_fired.connect(func(_kind: StringName) -> void:
		attack_frames.append(Engine.get_process_frames() - start_frame))

func _fire(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = Vector2(640, 360)
	event.global_position = event.position
	event.pressed = pressed
	_check(InputMap.event_is_action(event, &"fire_primary"), "mouse button still maps to fire_primary")
	Input.parse_input_event(event)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	seed(20260924)
	Engine.physics_ticks_per_second = 60
	var level := LEVEL.instantiate() as EpisodeOneLevel
	level.enemy_spawned.connect(_on_spawned)
	root.add_child(level)
	for index in 12:
		await process_frame
	var player := level.player as CobiePlayer
	_check(player != null and not player.weapons.is_empty(), "real player and weapon exist")
	if player == null or player.weapons.is_empty():
		_finish(level)
		return
	for menu in level.find_children("*", "PauseMenu", true, false):
		menu.set_suppressed(true)
	var weapon := player.weapons[player.current_weapon_index] as WeaponBase
	var initial_ammo := weapon.ammo
	weapon.fired.connect(func(_weapon: WeaponBase, secondary: bool) -> void:
		if not secondary: shot_frames.append(Engine.get_process_frames() - start_frame))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var initial_position := player.global_position
	var start_physics := Engine.get_physics_frames()
	start_frame = Engine.get_process_frames()
	for frame in FRAMES:
		if frame == 60: Input.action_press(&"move_forward")
		if frame == 150: Input.action_release(&"move_forward")
		if frame == 90: _fire(true)
		if frame == 93: _fire(false)
		await process_frame
		if frame == 100 and shot_frames.is_empty():
			print("OPENING FIRE DIAGNOSTIC: dead=%s paused=%s mouse=%d ammo=%d view=%s" % [player.is_dead, paused, Input.mouse_mode, weapon.ammo, root.size])
			failures.append("mapped fire did not reach the weapon by frame 100")
			break
	Input.action_release(&"move_forward")
	_fire(false)
	var elapsed_physics := Engine.get_physics_frames() - start_physics
	var active := level._spawn_registry.opening_enemies_active()
	var final_position := player.global_position
	print("OPENING CONTACT RECEIPT: frames=%d physics=%d spawned=%d shots=%s telegraphs=%s attacks=%s awake=%s start=%s end=%s ammo=%d->%d" % [Engine.get_process_frames() - start_frame, elapsed_physics, spawned.size(), shot_frames, telegraph_frames, attack_frames, active, initial_position, final_position, initial_ammo, weapon.ammo])
	_check(Engine.get_process_frames() - start_frame == FRAMES, "thirty simulated process seconds elapsed")
	_check(abs(elapsed_physics - 1800) <= 2, "sixty physics ticks per simulated second")
	_check(initial_position.z - final_position.z >= 2.0, "named movement advances down field")
	_check(spawned.size() == 3, "three authored field actors spawn")
	_check(shot_frames.size() == 1 and weapon.ammo == initial_ammo - weapon.definition.ammo_per_primary, "mapped fire reaches real ammo-consuming weapon")
	_check(active and spawned.all(func(actor: EnemyAgent) -> bool: return is_instance_valid(actor) and actor.process_mode != Node.PROCESS_MODE_DISABLED), "real shot wakes staged field actors")
	_check(not shot_frames.is_empty() and not telegraph_frames.is_empty() and telegraph_frames[0] > shot_frames[0] and telegraph_frames[0] < FRAMES, "first attack telegraph follows ordinary fire within thirty seconds")
	_check(not telegraph_frames.is_empty() and not attack_frames.is_empty() and attack_frames[0] > telegraph_frames[0] and attack_frames[0] < FRAMES, "first enemy attack follows its telegraph within thirty seconds")
	_finish(level)

func _finish(level: Node3D) -> void:
	Input.action_release(&"move_forward")
	if is_instance_valid(level):
		for audio in level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
		level.queue_free()
	for index in 12: await process_frame
	if failures.is_empty():
		print("SALMON CREEK OPENING CONTACT: PASS")
		quit(0)
	else:
		for failure in failures: push_error("OPENING CONTACT: " + failure)
		quit(1)
