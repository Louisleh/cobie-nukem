class_name PointerCaptureController
extends Node

signal capture_required_changed(required: bool)
signal capture_requested

const LAUNCH_CAPTURE_GRACE_MSEC := 2000

enum StartupPolicy { TOUCH_VISIBLE, NATIVE_CAPTURE, WEB_PRESERVE }

static var _launch_capture_requested_msec := -1

var capture_required := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	match startup_policy(MobileControls.touchscreen_expected(), OS.has_feature("web")):
		StartupPolicy.TOUCH_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		StartupPolicy.NATIVE_CAPTURE:
			request_capture()
		StartupPolicy.WEB_PRESERVE:
			# Never write VISIBLE here. A Start-button request can still be pending in
			# the browser while the gameplay scene enters the tree; forcing visibility
			# at that instant cancels the trusted pointer-lock request and produces the
			# familiar "pause, then resume to fix the mouse" failure. Direct routes are
			# already visible and will naturally expose the click-to-aim prompt.
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_launch_capture_requested_msec = -1
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


static func startup_policy(touch_expected: bool, web_build: bool) -> StartupPolicy:
	if touch_expected:
		return StartupPolicy.TOUCH_VISIBLE
	return StartupPolicy.WEB_PRESERVE if web_build else StartupPolicy.NATIVE_CAPTURE


static func request_from_launch_gesture() -> void:
	# Called synchronously by an explicit mission Start action. This timestamp is
	# intentionally process-local: it only protects the handoff into the next
	# scene and is never save data.
	_launch_capture_requested_msec = Time.get_ticks_msec()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


static func launch_capture_pending(now_msec := -1) -> bool:
	if _launch_capture_requested_msec < 0:
		return false
	var now := Time.get_ticks_msec() if now_msec < 0 else now_msec
	return now - _launch_capture_requested_msec <= LAUNCH_CAPTURE_GRACE_MSEC


func request_capture() -> void:
	if not _gameplay_active():
		return
	capture_requested.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Pointer-lock grants are asynchronous on Web. Reconcile next process tick so
	# a provisional value cannot flash the prompt when the browser rejects it.


func _sync_capture_state() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_launch_capture_requested_msec = -1
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
