extends SceneTree

## Bounded input-only no-fire approach to the shed threshold.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _use(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"use"):
		failures.append("E is not mapped to use")
	Input.parse_input_event(event)

func _run() -> void:
	seed(20260924)
	Engine.physics_ticks_per_second = 60
	var level := LEVEL.instantiate() as EpisodeOneLevel
	root.add_child(level)
	for index in 12: await process_frame
	var player := level.player as CobiePlayer
	var gate := level.get_node("Interactables/ShedGate") as LevelDoor
	if player == null or gate == null:
		push_error("FIELD EXIT: missing player or gate")
		quit(1)
		return
	for menu in level.find_children("*", "PauseMenu", true, false): menu.set_suppressed(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var weapon := player.weapons[player.current_weapon_index] as WeaponBase
	var ammo := weapon.ammo
	var director := level._mission_presentation.get_audio_director() as MissionAudioDirector
	var shots := [0]
	weapon.fired.connect(func(_source: WeaponBase, _secondary: bool) -> void: shots[0] += 1)
	for frame in 90: await process_frame
	if level._spawn_registry.opening_enemies_active() or level._opening_grace_timer.is_stopped():
		failures.append("waiting at spawn retains the authored twelve-second grace window")
	if director.current_state() == &"combat":
		failures.append("dormant field enemies must not start combat music before contact")
	var observations: Array[String] = []
	var use_frame := -1
	var open_frame := -1
	var awake_frame := -1
	var combat_frame := -1
	var zone_frame := -1
	var telegraphs: Array[int] = []
	var attacks: Array[int] = []
	var start_frame := Engine.get_process_frames()
	# Actors already spawned when the level entered the tree, before this connection.
	for actor in level._opening_enemies:
		if not actor is EnemyAgent: continue
		var enemy := actor as EnemyAgent
		enemy.telegraph_started.connect(func(_kind: StringName, _duration: float) -> void:
			telegraphs.append(Engine.get_process_frames() - start_frame))
		enemy.attack_fired.connect(func(_kind: StringName) -> void:
			attacks.append(Engine.get_process_frames() - start_frame))
	Input.action_press(&"move_forward")
	for frame in 450:
		if frame % 30 == 0:
			observations.append("%d: z=%.2f active=%s gate=%s zone=%s" % [frame, player.global_position.z, level._spawn_registry.opening_enemies_active(), gate.is_open, level.current_zone])
		if use_frame == -1 and player.global_position.z < -15.8:
			use_frame = frame
			_use(true)
		if use_frame >= 0 and frame == use_frame + 3: _use(false)
		await process_frame
		if gate.is_open and open_frame == -1: open_frame = frame
		if level._spawn_registry.opening_enemies_active() and awake_frame == -1: awake_frame = frame
		if director.current_state() == &"combat" and combat_frame == -1: combat_frame = frame
		if level.current_zone == &"equipment_shed" and zone_frame == -1: zone_frame = frame
		if zone_frame != -1: break
	Input.action_release(&"move_forward")
	_use(false)
	print("FIELD EXIT RECEIPT: use=%d open=%d awake=%d telegraphs=%s attacks=%s shed=%d ammo=%d->%d shots=%d dead=%s\n%s" % [use_frame, open_frame, awake_frame, telegraphs, attacks, zone_frame, ammo, weapon.ammo, shots[0], player.is_dead, "\n".join(observations)])
	if use_frame == -1 or open_frame == -1 or zone_frame == -1:
		failures.append("ordinary forward/use input must reach the unchanged shed gate")
	if awake_frame == -1 or awake_frame >= zone_frame or telegraphs.is_empty() or telegraphs[0] >= zone_frame or attacks.is_empty() or attacks[0] >= zone_frame:
		failures.append("no-fire approach must wake, telegraph and attack before entering the shed")
	if combat_frame < awake_frame or combat_frame >= zone_frame:
		failures.append("combat music must begin on field wake and before shed entry")
	if shots[0] != 0 or weapon.ammo != ammo:
		failures.append("no shot must be required for field contact")
	for audio in level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
	level.queue_free()
	for index in 12: await process_frame
	# The original timeout still wakes a player who does not move or shoot.
	var waiting_level := LEVEL.instantiate() as EpisodeOneLevel
	root.add_child(waiting_level)
	var waiting_director := waiting_level._mission_presentation.get_audio_director() as MissionAudioDirector
	if waiting_director.current_state() == &"combat":
		failures.append("initial field spawn cannot start combat music")
	for index in 361: await process_frame
	if not waiting_level._spawn_registry.opening_enemies_active():
		failures.append("waiting at spawn still activates the authored grace timeout")
	if waiting_director.current_state() != &"combat":
		failures.append("grace timeout must start combat music when enemies wake")
	for audio in waiting_level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
	waiting_level.queue_free()
	for index in 12: await process_frame
	if failures.is_empty():
		print("SALMON FIELD EXIT: PASS")
		quit(0)
	else:
		for failure in failures: push_error("FIELD EXIT: " + failure)
		quit(1)
