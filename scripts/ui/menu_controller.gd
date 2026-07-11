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
	%QuitButton.visible = not OS.has_feature("web")
	continue_button.disabled = SaveManager.load_slot(&"checkpoint").is_empty()
	continue_button.focus_mode = Control.FOCUS_NONE if continue_button.disabled else Control.FOCUS_ALL
	%NewGameButton.grab_focus()
	music.stream = sounds.create_menu_music()
	music.play()
	_reveal_after_layout()

func _reveal_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	modulate.a = 1.0

func _wire_button(button: Button, callback: Callable) -> void:
	button.pressed.connect(func() -> void:
		sounds.play(ProceduralAudio.Cue.ACCEPT)
		callback.call()
	)
	button.focus_entered.connect(func() -> void: sounds.play(ProceduralAudio.Cue.MOVE, -5.0))
	button.mouse_entered.connect(button.grab_focus)

func _new_game() -> void:
	GameState.continue_requested = false
	_route(level_select_scene_path)

func _continue_game() -> void:
	var checkpoint := SaveManager.load_slot(&"checkpoint")
	GameState.continue_requested = true
	var scene_path := String(checkpoint.get("scene_path", level_scene_path))
	GameState.begin_run(StringName(checkpoint.get("level_id", "no_dogs_allowed")))
	_route(scene_path)

func _route(path: String) -> void:
	var result := SceneRouter.go_to(path)
	if result != OK:
		status_label.visible = true
		status_label.text = "ROUTE OFFLINE // %s" % path.get_file()
		sounds.play(ProceduralAudio.Cue.ERROR)

func _quit() -> void:
	get_tree().quit()
