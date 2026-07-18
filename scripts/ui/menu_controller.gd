class_name MainMenuController
extends Control

@export_file("*.tscn") var level_scene_path := "res://scenes/levels/episode_1_level_1.tscn"
@export_file("*.tscn") var level_select_scene_path := "res://scenes/menus/level_select.tscn"
@export_file("*.tscn") var options_scene_path := "res://scenes/menus/options_menu.tscn"
@export_file("*.tscn") var credits_scene_path := "res://scenes/menus/credits.tscn"
@export_file("*.tscn") var input_setup_scene_path := "res://scenes/debug/input_diagnostics.tscn"

@onready var status_label: Label = %StatusLabel
@onready var continue_button: Button = %ContinueButton
@onready var sounds: ProceduralAudio = %ProceduralAudio
@onready var music: AudioStreamPlayer = %Music
var _layout_frames_remaining := 2
var _routing := false

func _ready() -> void:
	modulate.a = 0.0
	GameState._set_phase(GameState.Phase.MENU)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_wire_button(%NewGameButton, _new_game)
	_wire_button(continue_button, _continue_game)
	_wire_button(%InputSetupButton, func() -> void: _route(input_setup_scene_path))
	_wire_button(%OptionsButton, func() -> void: _route(options_scene_path))
	_wire_button(%CreditsButton, func() -> void: _route(credits_scene_path))
	_wire_button(%QuitButton, _quit)
	%QuitButton.text = "RETURN TO SITE" if OS.has_feature("web") else "QUIT"
	%QuitButton.visible = true
	continue_button.disabled = CheckpointPayload.sanitize(SaveManager.load_slot(&"checkpoint")).is_empty()
	continue_button.focus_mode = Control.FOCUS_NONE if continue_button.disabled else Control.FOCUS_ALL
	%NewGameButton.grab_focus()
	music.stream = sounds.create_menu_music()
	music.play()
	_reveal_after_layout()


func _exit_tree() -> void:
	# Menu music is synthesized at runtime. Release both the playback and stream
	# explicitly so headless scene churn and real menu transitions cannot retain
	# WAV playback resources until engine shutdown.
	if is_instance_valid(music):
		music.stop()
		music.stream = null

func _reveal_after_layout() -> void:
	if _layout_frames_remaining > 0:
		_layout_frames_remaining -= 1
		get_tree().process_frame.connect(_reveal_after_layout, CONNECT_ONE_SHOT)
		return
	modulate.a = 1.0

func _wire_button(button: Button, callback: Callable) -> void:
	button.pressed.connect(func() -> void:
		sounds.play(ProceduralAudio.Cue.ACCEPT)
		callback.call()
	)
	button.focus_entered.connect(func() -> void: sounds.play(ProceduralAudio.Cue.MOVE, -5.0))
	button.mouse_entered.connect(button.grab_focus)

func _new_game() -> void:
	if _route(level_select_scene_path):
		GameState.continue_requested = false

func _continue_game() -> void:
	var checkpoint := CheckpointPayload.sanitize(SaveManager.load_slot(&"checkpoint"))
	if checkpoint.is_empty():
		continue_button.disabled = true
		continue_button.focus_mode = Control.FOCUS_NONE
		status_label.visible = true
		status_label.text = "CHECKPOINT UNREADABLE // START A NEW RUN"
		sounds.play(ProceduralAudio.Cue.ERROR)
		return
	if not MobileControls.touchscreen_expected():
		PointerCaptureController.request_from_launch_gesture()
	if _route(String(checkpoint.scene_path)):
		GameState.select_difficulty(StringName(String(checkpoint.difficulty_id)))
		GameState.continue_requested = true
		GameState.begin_run(StringName(String(checkpoint.level_id)))
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _route(path: String) -> bool:
	if _routing:
		return false
	var result := SceneRouter.go_to(path)
	if result != OK:
		status_label.visible = true
		status_label.text = "ROUTE OFFLINE // %s" % path.get_file()
		sounds.play(ProceduralAudio.Cue.ERROR)
		return false
	_routing = true
	_set_buttons_disabled(true)
	return true

func _set_buttons_disabled(value: bool) -> void:
	for button in [%NewGameButton, continue_button, %InputSetupButton, %OptionsButton, %CreditsButton, %QuitButton]:
		button.disabled = value

func _quit() -> void:
	if OS.has_feature("web"):
		# Derive the game landing page from the deployed path. This works for the
		# public /play/ subdirectory, previews, and custom mount points without a
		# hard-coded production URL.
		JavaScriptBridge.eval("(() => { const here = new URL(window.location.href); const parts = here.pathname.split('/').filter(Boolean); if (parts.at(-1) === 'play') parts.pop(); const target = '/' + parts.join('/') + '/'; if (window.top !== window) window.top.location.href = target; else window.location.href = target; })();", true)
		return
	get_tree().quit()
