class_name DeathScreen
extends CanvasLayer

signal retry_requested
var _retrying := false

func _ready() -> void:
	visible = false
	%RetryButton.pressed.connect(_retry)
	%MainMenuButton.pressed.connect(func() -> void: _route("res://scenes/menus/main_menu.tscn"))

func show_death(quips: Array[String] = []) -> void:
	_retrying = false
	%RetryButton.disabled = false
	%MainMenuButton.disabled = false
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var fallback: Array[String] = ["GOOD DOGS GET BACK UP.", "INCIDENT REPORT: INCOMPLETE.", "THE SIGN IS STILL WRONG."]
	var choices: Array[String] = quips if not quips.is_empty() else fallback
	%QuipLabel.text = choices.pick_random()
	%RetryButton.grab_focus()

func _retry() -> void:
	if _retrying:
		return
	_retrying = true
	%RetryButton.disabled = true
	%MainMenuButton.disabled = true
	if not MobileControls.touchscreen_expected():
		PointerCaptureController.request_from_launch_gesture()
	retry_requested.emit()

func _route(path: String) -> void:
	var router := get_node_or_null("/root/SceneRouter")
	if router: router.go_to(path)
