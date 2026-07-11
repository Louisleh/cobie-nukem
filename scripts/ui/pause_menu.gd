class_name PauseMenu
extends CanvasLayer

signal restart_requested

const OptionsScene := preload("res://scenes/menus/options_menu.tscn")

var _options_overlay: OptionsMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%ResumeButton.pressed.connect(resume)
	%RestartButton.pressed.connect(func() -> void:
		_set_paused(false)
		restart_requested.emit()
	)
	%OptionsButton.pressed.connect(_open_options)
	%MainMenuButton.pressed.connect(func() -> void:
		_set_paused(false)
		_route("res://scenes/menus/main_menu.tscn")
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_instance_valid(_options_overlay):
			_close_options()
		elif visible:
			resume()
		else:
			open()
		get_viewport().set_input_as_handled()

func close_for_death() -> void:
	if is_instance_valid(_options_overlay):
		_options_overlay.queue_free()
		_options_overlay = null
	visible = false
	_set_paused(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not visible and get_tree() != null and not get_tree().paused:
		open()

func open() -> void:
	visible = true
	_set_paused(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%ResumeButton.grab_focus()

func resume() -> void:
	if is_instance_valid(_options_overlay):
		_options_overlay.queue_free()
		_options_overlay = null
	visible = false
	_set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _set_paused(value: bool) -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state: game_state.set_paused(value)
	else: get_tree().paused = value

func _route(path: String) -> void:
	var router := get_node_or_null("/root/SceneRouter")
	if router: router.go_to(path)

func _open_options() -> void:
	if is_instance_valid(_options_overlay):
		return
	$Dim.visible = false
	$Panel.visible = false
	_options_overlay = OptionsScene.instantiate() as OptionsMenu
	_options_overlay.embedded = true
	add_child(_options_overlay)
	_options_overlay.set_process_unhandled_input(false)
	_options_overlay.back_requested.connect(_close_options)

func _close_options() -> void:
	if is_instance_valid(_options_overlay):
		_options_overlay.queue_free()
	_options_overlay = null
	$Dim.visible = true
	$Panel.visible = true
	%OptionsButton.grab_focus()
