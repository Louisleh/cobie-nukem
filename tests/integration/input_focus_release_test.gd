extends SceneTree

# Deterministic service/player boundary; not OS focus or hardware evidence.
# Omitted releases model focus loss. Global/joystick owners remain independent.
class AxisOwnershipService extends InputManagerService:
	var axis_strength := 0.75

	func processed_axis(_axis: int, _device_id := -999) -> float:
		return axis_strength

const PLAYER_SCENE := preload("res://scenes/player/cobie_player.tscn")
const CHECK_ACTIONS: Array[StringName] = [&"move_forward", &"run", &"fire_primary"]

var failures: Array[String] = []
var observations: Dictionary = {}
var service: InputManagerService
var player: CobiePlayer

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	service = InputManagerService.new()
	service.name = "FocusReleaseRealServiceFixture"
	service.starting_profile = _keyboard_profile()
	root.add_child(service)
	# The fixture controls this instance explicitly; do not race polled hardware
	# or global event delivery while inspecting its actual production methods.
	service.set_process(false)
	service.set_process_input(false)
	await process_frame
	var profile_before := service.active_profile
	var device_before := service.active_device_id
	var axis_latch_before := service._axis_event_latch
	_expect(_strengths(service) == [0.0, 0.0, 0.0], "PRECONDITION: no external movement/run/fire action is already active")
	if not failures.is_empty():
		await _finish()
		return
	player = PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(player)
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player._input_manager = service
	await process_frame

	_key(service, KEY_W, true)
	_key(service, KEY_SHIFT, true)
	_mouse(service, MOUSE_BUTTON_LEFT, true)
	observations["pressed_strengths"] = _strengths(service)
	_expect(_strengths(service) == [1.0, 1.0, 1.0], "Real key/mouse events activate movement/run/fire service strengths")
	# Prime each discrete latch without consuming the player's shooting path.
	for action in CHECK_ACTIONS:
		_expect(service.get_action_just_pressed(action), "First physical press is just-pressed: " + String(action))
	# Deliberately omit all release events: this is the missing-release boundary.
	service.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	observations["focus_out_strengths"] = _strengths(service)
	for action in CHECK_ACTIONS:
		_expect(is_zero_approx(service.get_action_strength(action)), "Focus-out clears lost physical release: " + String(action))
	observations["focus_out_vector"] = str(service.get_vector(&"strafe_left", &"strafe_right", &"move_forward", &"move_backward"))
	_expect(service.get_vector(&"strafe_left", &"strafe_right", &"move_forward", &"move_backward").is_zero_approx(), "Focus-out returns real movement vector to neutral")
	if player != null:
		# Zero momentum distinguishes stale input acceleration from ordinary coast.
		player.velocity = Vector3.ZERO
		player._physics_process(1.0 / 60.0)
		observations["player_after_focus_horizontal_velocity"] = str(Vector2(player.velocity.x, player.velocity.z))
		_expect(Vector2(player.velocity.x, player.velocity.z).is_zero_approx(), "Player has no new horizontal acceleration from lost W release")
	_expect(service.active_profile == profile_before, "Focus-out preserves active profile identity")
	_expect(service.active_device_id == device_before, "Focus-out preserves active joystick selection")
	_expect(service._axis_event_latch == axis_latch_before, "Focus-out preserves joystick event-latch owner")

	# Fresh press must rearm immediately, without requiring a neutral poll first.
	_key(service, KEY_W, true)
	_key(service, KEY_SHIFT, true)
	_mouse(service, MOUSE_BUTTON_LEFT, true)
	for action in CHECK_ACTIONS:
		_expect(service.get_action_just_pressed(action), "Fresh physical press rearms immediately after focus-out: " + String(action))
	_expect(_strengths(service) == [1.0, 1.0, 1.0], "Fresh press reaches all service strengths after focus-out")
	_key(service, KEY_W, false)
	_key(service, KEY_SHIFT, false)
	_mouse(service, MOUSE_BUTTON_LEFT, false)
	_expect(_strengths(service) == [0.0, 0.0, 0.0], "Fresh release returns movement/run/fire strengths to zero")
	observations["fresh_release_strengths"] = _strengths(service)
	for action in CHECK_ACTIONS:
		_expect(not service.get_action_just_pressed(action), "Released physical action is not just-pressed: " + String(action))
	await _external_owner_guard()
	await _mixed_source_guard()
	await _paused_notification_guard()
	await _finish()

func _external_owner_guard() -> void:
	# Hardware axis source is simulated; all other methods are the real service.
	# This cannot prove physical joystick support. It catches an overbroad reset
	# of independently held axis/action state when only physical cache is stale.
	var owned := AxisOwnershipService.new()
	owned.name = "FocusReleaseExternalOwnerFixture"
	var profile := _keyboard_profile()
	profile.set_binding(&"look_right", {"type": "axis", "index": 0, "direction": 1.0, "range": "directional"})
	owned.starting_profile = profile
	root.add_child(owned)
	owned.set_process(false)
	owned.set_process_input(false)
	_expect(is_equal_approx(owned.get_action_strength(&"look_right"), 0.75), "Simulated independently owned joystick axis is held")
	_expect(owned.get_action_just_pressed(&"look_right"), "Joystick latch primed before focus")
	_expect(InputMap.has_action(&"use"), "PRECONDITION: registered use action for external-action ownership guard")
	if InputMap.has_action(&"use"):
		# Targeted synthetic action only: never call global release_pressed_events,
		# clear InputMap, or inject key/mouse state into the engine singleton.
		Input.action_press(&"use", 0.6)
		# Let the engine-global just-pressed edge expire before testing whether
		# the service independently preserves its own discrete latch.
		await process_frame
		await process_frame
		_expect(is_equal_approx(owned.get_action_strength(&"use"), 0.6), "Externally owned synthetic action is held")
		_expect(owned.get_action_just_pressed(&"use"), "External action latch primed before focus")
		_key(owned, KEY_W, true)
		owned.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		_expect(is_equal_approx(owned.get_action_strength(&"look_right"), 0.75), "Local keyboard cleanup preserves held joystick-axis strength")
		_expect(not owned.get_action_just_pressed(&"look_right"), "Local keyboard cleanup does not retrigger held joystick action")
		_expect(is_equal_approx(Input.get_action_strength(&"use"), 0.6), "Local keyboard cleanup does not release external synthetic/touch action")
		_expect(not owned.get_action_just_pressed(&"use"), "Local keyboard cleanup does not retrigger external action")
		Input.action_release(&"use")
	_key(owned, KEY_W, false)
	owned.queue_free()
	await process_frame

func _mixed_source_guard() -> void:
	var mixed := AxisOwnershipService.new()
	mixed.name = "MixedSourceFocusFixture"
	var profile := _keyboard_profile()
	profile.set_binding(&"move_forward", {"type": "axis", "index": 0, "direction": 1.0, "range": "directional"}, false)
	mixed.starting_profile = profile
	root.add_child(mixed)
	mixed.set_process(false)
	mixed.set_process_input(false)
	mixed.active_device_id = 73
	_expect(_axis_edge(mixed, 73, 1.0), "Real axis-event latch emits its first matching device/action/axis edge")
	_expect(not _axis_edge(mixed, 73, 1.0), "Real axis-event latch suppresses a repeated held edge")
	_expect(mixed.get_action_just_pressed(&"move_forward"), "Mixed-source joystick action edge is primed")
	_key(mixed, KEY_W, true)
	_expect(is_equal_approx(mixed.get_action_strength(&"move_forward"), 1.0), "Physical W raises mixed-source strength")
	mixed.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not _axis_edge(mixed, 73, 1.0), "Local physical focus cleanup does not clear held REAL axis-event latch in place")
	_expect(not _axis_edge(mixed, 73, 0.0), "Real axis release rearms without emitting a press")
	_expect(_axis_edge(mixed, 73, 1.0), "Real axis repress after release emits a new edge")
	_expect(not _axis_edge(mixed, 73, 1.0), "Real axis repress remains latched after its first edge")
	_expect(is_equal_approx(mixed.get_action_strength(&"move_forward"), 0.75), "Focus removes W while preserving SAME-action joystick strength")
	_expect(not mixed.get_action_just_pressed(&"move_forward"), "Focus does not retrigger SAME-action held joystick edge")
	mixed.axis_strength = 0.0
	_expect(is_zero_approx(mixed.get_action_strength(&"move_forward")), "Releasing remaining axis exposes neutral physical cache")
	_expect(not mixed.get_action_just_pressed(&"move_forward"), "Released mixed action rearms without a spurious edge")
	_key(mixed, KEY_W, true)
	_expect(mixed.get_action_just_pressed(&"move_forward"), "New W after mixed-source release reaches fresh edge")
	_key(mixed, KEY_W, false)
	_expect(is_zero_approx(mixed.get_action_strength(&"move_forward")), "New mixed-source W release reaches neutral")
	_expect(not mixed.get_action_just_pressed(&"move_forward"), "New mixed-source W release resets its edge normally")

	# Same action supplied by a synthetic/touch owner must also retain its latch.
	_expect(InputMap.has_action(&"move_forward"), "Move action exists for synthetic same-action guard")
	if InputMap.has_action(&"move_forward"):
		Input.action_press(&"move_forward", 0.6)
		await process_frame
		await process_frame
		_expect(mixed.get_action_just_pressed(&"move_forward"), "Synthetic same-action edge is primed")
		_key(mixed, KEY_W, true)
		mixed.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		_expect(is_equal_approx(mixed.get_action_strength(&"move_forward"), 0.6), "Focus preserves SAME-action external synthetic strength")
		_expect(not mixed.get_action_just_pressed(&"move_forward"), "Focus preserves SAME-action synthetic latch")
		Input.action_release(&"move_forward")
		_expect(is_zero_approx(mixed.get_action_strength(&"move_forward")), "Synthetic release leaves no stale W")
		_expect(not mixed.get_action_just_pressed(&"move_forward"), "Synthetic release resets its edge normally")
	_key(mixed, KEY_W, false)
	mixed.queue_free()
	await process_frame


func _paused_notification_guard() -> void:
	var paused_service := InputManagerService.new()
	paused_service.name = "PausedFocusNotificationFixture"
	paused_service.starting_profile = _keyboard_profile()
	root.add_child(paused_service)
	paused_service.set_process(false)
	paused_service.set_process_input(false)
	_expect(paused_service.process_mode == Node.PROCESS_MODE_ALWAYS, "Real service remains ALWAYS while tree is paused")
	_key(paused_service, KEY_W, true)
	_key(paused_service, KEY_SHIFT, true)
	_mouse(paused_service, MOUSE_BUTTON_LEFT, true)
	for action in CHECK_ACTIONS:
		_expect(paused_service.get_action_just_pressed(action), "Paused fixture initial edge: " + String(action))
	var paused_before := paused
	paused = true
	# Actual Node propagation on this dedicated fixture only. No PauseMenu,
	# OS focus injection or claim of whole-tree/platform dispatch ordering.
	paused_service.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	observations["paused_focus_strengths"] = _strengths(paused_service)
	_expect(_strengths(paused_service) == [0.0, 0.0, 0.0], "Paused notification propagation neutralizes local physical strengths")
	_key(paused_service, KEY_W, true)
	_key(paused_service, KEY_SHIFT, true)
	_mouse(paused_service, MOUSE_BUTTON_LEFT, true)
	for action in CHECK_ACTIONS:
		_expect(paused_service.get_action_just_pressed(action), "Fresh edge rearms while paused: " + String(action))
	_key(paused_service, KEY_W, false)
	_key(paused_service, KEY_SHIFT, false)
	_mouse(paused_service, MOUSE_BUTTON_LEFT, false)
	_expect(_strengths(paused_service) == [0.0, 0.0, 0.0], "Fresh releases remain neutral while paused")
	paused = paused_before
	paused_service.queue_free()
	await process_frame


func _axis_edge(owner: InputManagerService, device: int, value: float) -> bool:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	return owner.is_action_event_pressed(event, &"move_forward")


func _keyboard_profile() -> InputProfile:
	var profile := InputProfile.new()
	profile.profile_id = "focus-release-regression"
	profile.preset = "keyboard_mouse"
	profile.ensure_defaults()
	return profile

func _strengths(owner: InputManagerService) -> Array:
	return [owner.get_action_strength(&"move_forward"), owner.get_action_strength(&"run"), owner.get_action_strength(&"fire_primary")]

func _key(owner: InputManagerService, code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	event.echo = false
	owner._input(event)

func _mouse(owner: InputManagerService, button: int, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	owner._input(event)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	# Cleanup this fixture's own state only. A failed regression stays failed.
	_key(service, KEY_W, false)
	_key(service, KEY_SHIFT, false)
	_mouse(service, MOUSE_BUTTON_LEFT, false)
	if player != null:
		player.queue_free()
	service.queue_free()
	await process_frame
	await process_frame
	print("FOCUS RELEASE OBSERVATIONS: " + JSON.stringify(observations))
	for failure in failures:
		push_error(failure)
	print("FOCUS RELEASE REGRESSION: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
