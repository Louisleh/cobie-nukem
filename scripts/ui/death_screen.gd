class_name DeathScreen
extends CanvasLayer

signal retry_requested
var _retrying := false
var _routing := false

func _ready() -> void:
	visible = false
	get_viewport().size_changed.connect(_layout_panel)
	_layout_panel()
	%RetryButton.pressed.connect(_retry)
	%MainMenuButton.pressed.connect(func() -> void: _route("res://scenes/menus/main_menu.tscn"))

func _layout_panel() -> void:
	var viewport := get_viewport()
	var physical_size := Vector2(viewport.size)
	if physical_size.y <= 0.0:
		return
	var panel := $Panel as Control
	var canvas_height := float(viewport.content_scale_size.y)
	var visible_width := minf(float(viewport.content_scale_size.x), canvas_height * physical_size.x / physical_size.y)
	panel.position.x = maxf(0.0, (visible_width - panel.size.x) * 0.5)

func show_death(quips: Array[String] = []) -> void:
	_retrying = false
	_routing = false
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
	if _retrying or _routing:
		return
	var router := get_node_or_null("/root/SceneRouter")
	if router == null or router.go_to(path) != OK:
		return
	_routing = true
	%RetryButton.disabled = true
	%MainMenuButton.disabled = true
