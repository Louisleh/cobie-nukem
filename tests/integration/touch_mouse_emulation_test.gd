extends SceneTree

# Service/player intent boundary. Emulated mouse is supplied explicitly here;
# actual ScreenTouch/DOM dispatch, GUI and physical hardware require follow-up.
const PLAYER_SCENE := preload("res://scenes/player/cobie_player.tscn")
const RAIN_LOADOUT := preload("res://resources/loadouts/vancouver_waterfront_loadout.tres")

var failures: Array[String] = []
var service: InputManagerService
var player: CobiePlayer
var shots := 0
var observations: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	service = InputManagerService.new()
	service.name = "TouchMouseIntentServiceFixture"
	var profile := InputProfile.new()
	profile.preset = "keyboard_mouse"
	profile.ensure_defaults()
	service.starting_profile = profile
	root.add_child(service)
	service.set_process(false)
	service.set_process_input(false)
	player = PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(player)
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player._input_manager = service
	_expect(player.apply_mission_loadout(RAIN_LOADOUT), "Production Rain City loadout initializes the real player")
	await physics_frame
	await process_frame
	if player.weapons.is_empty():
		failures.append("Fixture requires the real player weapon")
		await _finish()
		return
	var weapon := player.weapons[player.current_weapon_index]
	weapon.fired.connect(func(_weapon: WeaponBase, _secondary: bool) -> void: shots += 1)
	if not await _ready_weapon(weapon):
		await _finish()
		return

	var emulated := _mouse(InputEvent.DEVICE_ID_EMULATION, MOUSE_BUTTON_LEFT, true)
	_expect(PlayerInputAdapter.event_action(service, emulated) == &"", "Touch-derived LEFT mouse has no player intent")
	var before := weapon.ammo
	var shots_before := shots
	_dispatch(emulated)
	_dispatch(_mouse(InputEvent.DEVICE_ID_EMULATION, MOUSE_BUTTON_LEFT, false))
	observations.append({"input": "emulated_mouse", "before": before, "after": weapon.ammo, "shots": shots - shots_before})
	_expect(weapon.ammo == before, "Emulated mouse leaves real player weapon ammo unchanged")
	_expect(shots == shots_before, "Emulated mouse emits no accepted real player shot")

	if not await _ready_weapon(weapon):
		await _finish()
		return
	var genuine := _mouse(0, MOUSE_BUTTON_LEFT, true)
	_expect(PlayerInputAdapter.event_action(service, genuine) == &"fire_primary", "Non-emulated LEFT mouse still resolves primary fire")
	before = weapon.ammo
	shots_before = shots
	_dispatch(genuine)
	_dispatch(_mouse(0, MOUSE_BUTTON_LEFT, false))
	observations.append({"input": "non_emulated_mouse", "before": before, "after": weapon.ammo, "shots": shots - shots_before})
	_expect(weapon.ammo == before - 1 and shots == shots_before + 1, "Non-emulated mouse consumes exactly one real player round")

	if not await _ready_weapon(weapon):
		await _finish()
		return
	var touch_fire := _action(&"fire_primary", true)
	_expect(PlayerInputAdapter.event_action(service, touch_fire) == &"fire_primary", "Explicit named touch FIRE retains intent")
	before = weapon.ammo
	shots_before = shots
	_dispatch(touch_fire)
	_dispatch(_action(&"fire_primary", false))
	observations.append({"input": "named_touch_fire", "before": before, "after": weapon.ammo, "shots": shots - shots_before})
	_expect(weapon.ammo == before - 1 and shots == shots_before + 1, "Named touch FIRE consumes exactly one real player round")
	_expect(PlayerInputAdapter.event_action(service, _action(&"use", true)) == &"use", "Named touch USE remains available")
	_expect(PlayerInputAdapter.event_action(service, _action(&"weapon_next", true)) == &"weapon_next", "Named touch NEXT remains available")
	_expect(PlayerInputAdapter.event_action(service, _mouse(0, MOUSE_BUTTON_RIGHT, true)) == &"fire_secondary", "Non-emulated secondary mouse fire remains available")
	_expect(PlayerInputAdapter.event_action(service, _mouse(InputEvent.DEVICE_ID_EMULATION, MOUSE_BUTTON_RIGHT, true)) == &"", "Emulated mouse buttons never produce player gameplay intent")

	var number := InputEventKey.new()
	number.physical_keycode = KEY_2
	number.keycode = KEY_2
	number.pressed = true
	_expect(int(PlayerInputAdapter.weapon_shortcut(number, -1000).get("slot", -1)) == 1, "Existing number-key weapon shortcut remains intact")
	var wheel := _mouse(0, MOUSE_BUTTON_WHEEL_DOWN, true)
	_expect(int(PlayerInputAdapter.weapon_shortcut(wheel, -1000).get("delta", 0)) == 1, "Existing mouse-wheel weapon shortcut remains intact")
	# The intent filter must not rewrite the project-wide GUI emulation policy.
	_expect(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false)), "Project GUI touch-to-mouse emulation remains enabled")
	await _finish()

func _ready_weapon(weapon: WeaponBase) -> bool:
	var deadline := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < deadline:
		if weapon.can_fire():
			return true
		await process_frame
	failures.append("Real weapon did not finish its production raise/recovery")
	return false

func _dispatch(event: InputEvent) -> void:
	service._input(event)
	player._input(event)
	player._unhandled_input(event)

func _mouse(device: int, button: int, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = device
	event.button_index = button
	event.pressed = pressed
	return event

func _action(action: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	player.queue_free()
	service.queue_free()
	await process_frame
	await process_frame
	print("TOUCH MOUSE INTENT OBSERVATIONS: " + JSON.stringify(observations))
	for failure in failures:
		push_error(failure)
	print("TOUCH MOUSE EMULATION TEST: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
