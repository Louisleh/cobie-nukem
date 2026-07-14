class_name PointerCaptureController
extends Node

signal capture_required_changed(required: bool)
signal capture_requested

var capture_required := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if MobileControls.touchscreen_expected():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not OS.has_feature("web") or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		request_capture()
	else:
		# Web pointer lock cannot be granted from scene startup. The mission-launch
		# gesture normally captures before this scene arrives; direct routes and
		# keyboard launches deliberately use the visible activation prompt.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	call_deferred("_sync_capture_state")


func _input(event: InputEvent) -> void:
	# _input runs before Control GUI handling, so a full-screen HUD cannot consume
	# the activation click. It is capture-only and must not also fire a weapon.
	if _gameplay_active() and event is InputEventMouseButton and event.pressed \
			and needs_capture(MobileControls.touchscreen_expected(), Input.mouse_mode):
		request_capture()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	_sync_capture_state()
	if capture_required:
		# A direct Web route or keyboard launch can arrive before the browser grants
		# pointer lock. Never let combat kill the player while the game is explicitly
		# waiting for its activation gesture; protection ends on the first grant.
		var player := get_parent() as CobiePlayer
		if player != null:
			player.health_armor.grant_invulnerability(0.25)


static func needs_capture(touch_expected: bool, mouse_mode: Input.MouseMode) -> bool:
	return not touch_expected and mouse_mode != Input.MOUSE_MODE_CAPTURED


func request_capture() -> void:
	if not _gameplay_active():
		return
	capture_requested.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Pointer-lock grants are asynchronous on Web. Reconcile next process tick so
	# a provisional value cannot flash the prompt when the browser rejects it.


func _sync_capture_state() -> void:
	var required := _gameplay_active() and needs_capture(MobileControls.touchscreen_expected(), Input.mouse_mode)
	if required == capture_required:
		return
	capture_required = required
	capture_required_changed.emit(required)


func _gameplay_active() -> bool:
	if MobileControls.touchscreen_expected() or get_tree() == null or get_tree().paused:
		return false
	var player := get_parent() as CobiePlayer
	return player != null and not player.is_dead
