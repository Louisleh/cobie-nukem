extends SceneTree

class FakeInteractable extends StaticBody3D:
	var interacted := false

	func interact(_actor: Node = null) -> void:
		interacted = true

	func get_interaction_label() -> String:
		return "INTERACTABLE"

const PROFILE_BINDINGS: Dictionary[StringName, int] = {
	&"move_forward": KEY_I,
	&"move_backward": KEY_K,
	&"strafe_left": KEY_J,
	&"strafe_right": KEY_L,
	&"look_left": KEY_U,
	&"look_right": KEY_O,
	&"jump": KEY_Y,
	&"fire_primary": KEY_H,
	&"fire_secondary": KEY_M,
	&"use": KEY_G,
	&"run": KEY_R,
	&"weapon_next": KEY_N,
	&"weapon_previous": KEY_B,
	&"reload": KEY_T,
	&"pause": KEY_P,
}

const PLAYER_SCENE := preload("res://scenes/player/cobie_player.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")

var failures: Array[String] = []
var manager: Node
var player: CobiePlayer
var pause_menu: PauseMenu
var interactable: FakeInteractable
var custom_profile: InputProfile
var default_profile: InputProfile


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup()
	if manager == null or player == null or pause_menu == null:
		failures.append("Input boundary fixtures failed to initialize")
		_finish(1)
		return
	var original_profile: InputProfile = manager.active_profile
	if original_profile != null:
		default_profile = original_profile.duplicate(true)
	else:
		default_profile = InputProfile.new()
		default_profile.profile_id = "keyboard_mouse"
		default_profile.preset = "keyboard_mouse"
		default_profile.ensure_defaults()
	custom_profile = _build_custom_profile()
	manager.set_active_profile(custom_profile)
	await _custom_profile_reaches_player_and_pause()
	if not failures.is_empty():
		_finish(1)
		return
	_default_profile_still_reaches_player()
	manager.set_active_profile(default_profile)
	_finish()


func _setup() -> void:
	manager = get_root().get_node_or_null("/root/InputManager")
	player = PLAYER_SCENE.instantiate() as CobiePlayer
	pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	root.add_child(player)
	root.add_child(pause_menu)
	interactable = _make_interactable()
	root.add_child(interactable)
	interactable.global_position = player.camera.global_position + -player.camera.global_basis.z * 1.4


func _build_custom_profile() -> InputProfile:
	var profile := InputProfile.new()
	profile.profile_id = "wcb-002-boundary"
	profile.preset = "keyboard_mouse"
	profile.ensure_defaults()
	var unique_keys: Dictionary = {}
	for action in PROFILE_BINDINGS.keys():
		unique_keys[PROFILE_BINDINGS[action]] = true
		profile.set_binding(action, {
			"type": "key",
			"index": PROFILE_BINDINGS[action],
			"direction": 1.0,
			"range": "directional",
		})
	_expect(unique_keys.size() == PROFILE_BINDINGS.size(), "Custom input fixture uses unique bindings")
	return profile


func _custom_profile_reaches_player_and_pause() -> void:
	player._coyote_remaining = 0.2
	if player.weapons.is_empty():
		failures.append("Custom-profile boundary test requires player weapons")
		return

	_send_key(PROFILE_BINDINGS[&"move_forward"], true)
	_tick_player(3)
	_send_key(PROFILE_BINDINGS[&"move_forward"], false)
	_expect(Vector2(player.velocity.x, player.velocity.z).length() > 0.01, "Custom profile movement reaches player velocity boundary")
	var yaw_before := player.rotation.y
	_send_key(PROFILE_BINDINGS[&"look_right"], true)
	_tick_player(2)
	_send_key(PROFILE_BINDINGS[&"look_right"], false)
	_expect(not is_equal_approx(player.rotation.y, yaw_before), "Custom profile look binding reaches player rotation boundary")

	player.velocity = Vector3.ZERO
	_send_key(PROFILE_BINDINGS[&"move_forward"], true)
	_tick_player(1)
	var walk_speed := Vector2(player.velocity.x, player.velocity.z).length()
	_send_key(PROFILE_BINDINGS[&"run"], true)
	_tick_player(3)
	_send_key(PROFILE_BINDINGS[&"run"], false)
	_send_key(PROFILE_BINDINGS[&"move_forward"], false)
	var run_speed := Vector2(player.velocity.x, player.velocity.z).length()
	_expect(run_speed >= walk_speed, "Custom run binding reaches player movement speed path")
	player.velocity = Vector3.ZERO

	_send_key(PROFILE_BINDINGS[&"jump"], true)
	_send_key(PROFILE_BINDINGS[&"jump"], false)
	_tick_player(1)
	_expect(player.velocity.y > 0.01, "Custom jump tap is latched through the next player physics boundary")

	var weapon := player.weapons[player.current_weapon_index]
	for candidate in player.weapons:
		candidate.unlocked = true
	weapon.ammo = max(weapon.ammo, 8)
	weapon.reserve_ammo = max(weapon.reserve_ammo, 12)
	var fired := [0]
	var secondary_fired := [false]
	var reload_events := [0]
	weapon.fired.connect(func(_weapon: WeaponBase, secondary: bool) -> void:
		fired[0] += 1
		secondary_fired[0] = secondary_fired[0] or secondary
	)
	weapon.reload_started.connect(func(_weapon: WeaponBase, _duration: float) -> void:
		reload_events[0] += 1
	)
	var fire_event := InputEventKey.new()
	fire_event.keycode = PROFILE_BINDINGS[&"fire_primary"]
	fire_event.physical_keycode = PROFILE_BINDINGS[&"fire_primary"]
	fire_event.pressed = true
	fire_event.echo = false
	_expect(manager.is_action_event_pressed(fire_event, &"fire_primary"), "Service seam does not report custom fire-primary action")
	weapon.ammo = 8
	weapon.reserve_ammo = 4
	weapon.enabled = true
	weapon.lifecycle_state = WeaponBase.LifecycleState.READY
	await process_frame
	_send_key(PROFILE_BINDINGS[&"fire_primary"], true)
	_send_key(PROFILE_BINDINGS[&"fire_primary"], false)
	_expect(fired[0] > 0, "Custom fire-primary binding reaches weapon fire boundary")
	weapon._cooldown_remaining = 0.0
	weapon.lifecycle_state = WeaponBase.LifecycleState.READY
	_send_key(PROFILE_BINDINGS[&"fire_secondary"], true)
	_send_key(PROFILE_BINDINGS[&"fire_secondary"], false)
	_expect(secondary_fired[0], "Custom fire-secondary binding reaches weapon secondary-fire boundary")

	_send_key(PROFILE_BINDINGS[&"reload"], true)
	_send_key(PROFILE_BINDINGS[&"reload"], false)
	_expect(reload_events[0] > 0 or weapon.is_reloading, "Custom reload binding reaches weapon reload boundary")

	var next_weapon := (player.current_weapon_index + 1) % player.weapons.size()
	_send_key(PROFILE_BINDINGS[&"weapon_next"], true)
	_send_key(PROFILE_BINDINGS[&"weapon_next"], false)
	await process_frame
	_expect(int(player._queued_weapon_index) == next_weapon or player.current_weapon_index == next_weapon, "Custom weapon-next binding reaches switching boundary")

	var previous_weapon := posmod(player.current_weapon_index - 1, player.weapons.size())
	_send_key(PROFILE_BINDINGS[&"weapon_previous"], true)
	_send_key(PROFILE_BINDINGS[&"weapon_previous"], false)
	await process_frame
	_expect(int(player._queued_weapon_index) == previous_weapon or player.current_weapon_index == previous_weapon, "Custom weapon-previous binding reaches switching boundary")

	await process_frame
	_send_key(PROFILE_BINDINGS[&"use"], true)
	_send_key(PROFILE_BINDINGS[&"use"], false)
	await process_frame
	_expect(interactable.interacted, "Custom use binding reaches interaction boundary")

	_send_key(PROFILE_BINDINGS[&"pause"], true)
	_send_key(PROFILE_BINDINGS[&"pause"], false)
	await process_frame
	_expect(pause_menu.visible, "Custom pause binding reaches pause menu boundary")
	pause_menu.resume()


func _default_profile_still_reaches_player() -> void:
	manager.set_active_profile(default_profile)
	player.velocity = Vector3.ZERO
	_send_key(KEY_W, true)
	_tick_player(2)
	_send_key(KEY_W, false)
	_expect(Vector2(player.velocity.x, player.velocity.z).length() > 0.01, "Default keyboard profile still reaches player movement boundary")


func _make_interactable() -> FakeInteractable:
	var node := FakeInteractable.new()
	node.add_to_group(&"interactables")
	node.collision_layer = 1
	node.collision_mask = 1
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(0.4, 0.4, 0.4)
	shape.shape = bounds
	node.add_child(shape)
	return node


func _send_key(key: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.echo = false
	if manager != null:
		manager._input(event)
	if player != null:
		player._input(event)
		player._unhandled_input(event)
	if pause_menu != null:
		pause_menu._input(event)


func _tick_player(ticks := 1, delta := 1.0 / 60.0) -> void:
	for _i in range(ticks):
		player._physics_process(delta)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _finish(code := 0) -> void:
	if pause_menu != null and pause_menu.visible:
		pause_menu.resume()
	if code == 0 and failures.is_empty():
		print("INPUT PROFILE SERVICE BOUNDARY TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
