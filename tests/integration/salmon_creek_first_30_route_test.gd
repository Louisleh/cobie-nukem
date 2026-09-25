extends SceneTree

## Thirty simulated seconds on the native renderer; mapped input only, no teleports.
const LEVEL := preload("res://scenes/levels/episode_1_level_1.tscn")
const FRAMES := 900
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _key_use(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"use"):
		failures.append("mapped use key missing")
	Input.parse_input_event(event)

func _mouse_fire(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"fire_primary"):
		failures.append("mapped fire button missing")
	Input.parse_input_event(event)

func _menu_accept(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.physical_keycode = KEY_ENTER
	event.pressed = pressed
	if not InputMap.event_is_action(event, &"menu_accept"):
		failures.append("mapped menu accept key missing")
	Input.parse_input_event(event)

func _run() -> void:
	seed(20260924)
	Engine.physics_ticks_per_second = 60
	var level := LEVEL.instantiate() as EpisodeOneLevel
	root.add_child(level)
	for index in 12: await process_frame
	var player := level.player as CobiePlayer
	var gate := level.get_node_or_null("Interactables/ShedGate") as LevelDoor
	if player == null or gate == null:
		push_error("FIRST 30: missing real player or shed gate")
		quit(1)
		return
	for menu in level.find_children("*", "PauseMenu", true, false): menu.set_suppressed(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var weapon := player.weapons[player.current_weapon_index] as WeaponBase
	var director := level._mission_presentation.get_audio_director() as MissionAudioDirector
	var initial_ammo := weapon.ammo
	var shots: Array[int] = []
	var warnings: Array[int] = []
	var attacks: Array[int] = []
	var awake := -1
	var combat := -1
	var use_frame := -1
	var opened := -1
	var shed := -1
	var death := -1
	var recovered := -1
	var ammo_at_shed := -1
	var starting_process := Engine.get_process_frames()
	var starting_physics := Engine.get_physics_frames()
	weapon.fired.connect(func(_source: WeaponBase, _secondary: bool) -> void:
		shots.append(Engine.get_process_frames() - starting_process))
	for actor in level._opening_enemies:
		if not actor is EnemyAgent: continue
		var enemy := actor as EnemyAgent
		enemy.telegraph_started.connect(func(_kind: StringName, _duration: float) -> void:
			warnings.append(Engine.get_process_frames() - starting_process))
		enemy.attack_fired.connect(func(_kind: StringName) -> void:
			attacks.append(Engine.get_process_frames() - starting_process))
	if director.current_state() == &"combat": failures.append("combat music starts before player contact")
	Input.action_press(&"move_forward")
	for frame in FRAMES:
		if frame == 60: _mouse_fire(true)
		if frame == 63: _mouse_fire(false)
		if use_frame == -1 and player.global_position.z < -15.8:
			use_frame = frame
			_key_use(true)
		if use_frame >= 0 and frame == use_frame + 3: _key_use(false)

		if death >= 0 and frame == death + 30: _menu_accept(true)
		if death >= 0 and frame == death + 33: _menu_accept(false)
		await process_frame
		if awake == -1 and level._spawn_registry.opening_enemies_active(): awake = frame
		if combat == -1 and director.current_state() == &"combat": combat = frame
		if opened == -1 and gate.is_open: opened = frame
		if shed == -1 and level.current_zone == &"equipment_shed":
			shed = frame
			ammo_at_shed = weapon.ammo
			Input.action_release(&"move_forward")
		if death == -1 and player.is_dead: death = frame
		if death >= 0 and recovered == -1 and not player.is_dead: recovered = frame
	Input.action_release(&"move_forward")
	_key_use(false)
	_mouse_fire(false)
	_menu_accept(false)
	var elapsed_process := Engine.get_process_frames() - starting_process
	var elapsed_physics := Engine.get_physics_frames() - starting_physics
	print("FIRST 30 RECEIPT: process=%d physics=%d shot=%s awake=%d combat=%d warning=%s attack=%s use=%d gate=%d shed=%d death=%d recovered=%d ammo_at_shed=%d health=%.1f" % [elapsed_process, elapsed_physics, shots, awake, combat, warnings, attacks, use_frame, opened, shed, death, recovered, ammo_at_shed, player.health_armor.health])
	if elapsed_process != FRAMES or abs(elapsed_physics - FRAMES * 2) > 2:
		failures.append("30 simulated seconds must contain 900 rendered and 1800 physics frames")
	if shots.size() != 1 or shots[0] < 60 or shots[0] > 63 or ammo_at_shed != initial_ammo - weapon.definition.ammo_per_primary:
		failures.append("real mapped mouse input must consume exactly one Pawstol shot")
	if awake < 0 or combat < awake or warnings.is_empty() or attacks.is_empty() or warnings[0] <= awake or attacks[0] <= warnings[0]:
		failures.append("field contact must wake staged enemies, cue combat, telegraph and attack")
	if use_frame < 0 or opened < use_frame or shed < opened or shed >= FRAMES:
		failures.append("mapped forward/use must open unchanged gate and enter shed")
	if death >= 0 and death <= shed:
		failures.append("player must be alive on first shed entry")
	if death >= 0 and (recovered < death or recovered >= FRAMES or player.is_dead):
		failures.append("death during first 30 must permit focused Retry via mapped menu accept")
	for audio in level.find_children("*", "ProceduralAudio", true, false): audio.stop_all()
	level.queue_free()
	for index in 12: await process_frame
	if failures.is_empty():
		print("SALMON FIRST 30 ROUTE: PASS (simulated native input, not human play)")
		quit(0)
	else:
		for failure in failures: push_error("FIRST 30: " + failure)
		quit(1)
