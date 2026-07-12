class_name PauseMenu
extends CanvasLayer

signal restart_requested

const OptionsScene := preload("res://scenes/menus/options_menu.tscn")
const FeedbackScene := preload("res://scenes/ui/playtest_report.tscn")

var _options_overlay: OptionsMenu
var _feedback_overlay: PlaytestReport
# While the death or victory screen owns the UI, the pause menu must not open
# on top of it — neither from the pause action nor from browser focus loss.
var _suppressed := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%ResumeButton.pressed.connect(resume)
	%RestartButton.pressed.connect(func() -> void:
		_set_paused(false)
		restart_requested.emit()
	)
	%OptionsButton.pressed.connect(_open_options)
	%FeedbackButton.pressed.connect(_open_feedback)
	%BuildLabel.text = "v%s • %s" % [BuildInfo.VERSION, BuildInfo.REVISION]
	%MainMenuButton.pressed.connect(func() -> void:
		_set_paused(false)
		_route("res://scenes/menus/main_menu.tscn")
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_instance_valid(_options_overlay):
			_close_options()
		elif is_instance_valid(_feedback_overlay):
			_close_feedback()
		elif visible:
			resume()
		elif not _suppressed:
			open()
		get_viewport().set_input_as_handled()

func set_suppressed(value: bool) -> void:
	_suppressed = value

func close_for_death() -> void:
	_suppressed = true
	if is_instance_valid(_options_overlay):
		_options_overlay.queue_free()
		_options_overlay = null
	if is_instance_valid(_feedback_overlay):
		_feedback_overlay.queue_free()
		_feedback_overlay = null
	visible = false
	_set_paused(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not visible and not _suppressed \
			and get_tree() != null and not get_tree().paused and _gameplay_active():
		open()

func _gameplay_active() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null:
		return true
	return game_state.phase == game_state.Phase.PLAYING

func open() -> void:
	get_tree().call_group(&"mobile_controls", &"release_all")
	visible = true
	_set_paused(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%ResumeButton.grab_focus()

func resume() -> void:
	if is_instance_valid(_options_overlay):
		_options_overlay.queue_free()
		_options_overlay = null
	if is_instance_valid(_feedback_overlay):
		_feedback_overlay.queue_free()
		_feedback_overlay = null
	visible = false
	_set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if MobileControls.touchscreen_expected() else Input.MOUSE_MODE_CAPTURED

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

func _open_feedback() -> void:
	if is_instance_valid(_feedback_overlay):
		return
	$Dim.visible = false
	$Panel.visible = false
	_feedback_overlay = FeedbackScene.instantiate() as PlaytestReport
	add_child(_feedback_overlay)
	_feedback_overlay.closed.connect(_close_feedback)
	_feedback_overlay.open()

func _close_feedback() -> void:
	if is_instance_valid(_feedback_overlay):
		_feedback_overlay.queue_free()
	_feedback_overlay = null
	$Dim.visible = true
	$Panel.visible = true
	%FeedbackButton.grab_focus()
