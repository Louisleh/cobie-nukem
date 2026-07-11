class_name PauseMenu
extends CanvasLayer

signal restart_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%ResumeButton.pressed.connect(resume)
	%RestartButton.pressed.connect(func() -> void:
		_set_paused(false)
		restart_requested.emit()
	)
	%OptionsButton.pressed.connect(func() -> void:
		_set_paused(false)
		_route("res://scenes/menus/options_menu.tscn")
	)
	%MainMenuButton.pressed.connect(func() -> void:
		_set_paused(false)
		_route("res://scenes/menus/main_menu.tscn")
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			resume()
		else:
			open()
		get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	_set_paused(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%ResumeButton.grab_focus()

func resume() -> void:
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
