extends Control

@export_file("*.tscn") var back_scene_path := "res://scenes/menus/main_menu.tscn"

func _ready() -> void:
	%BackButton.pressed.connect(_back)
	%BackButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back"):
		_back()

func _back() -> void:
	%ProceduralAudio.play(ProceduralAudio.Cue.BACK)
	SceneRouter.go_to(back_scene_path)
