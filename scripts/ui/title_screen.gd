extends Control

@export_file("*.tscn") var menu_scene_path := "res://scenes/menus/main_menu.tscn"
var _accepting := false

func _ready() -> void:
	modulate.a = 0.0
	%BuildLabel.text = BuildInfo.label()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if OS.has_feature("web"):
		%Prompt.text = "CLICK / PRESS A KEY TO DISOBEY"
	%ProceduralAudio.play(ProceduralAudio.Cue.SECRET, -3.0)
	var tween := create_tween().set_loops()
	tween.tween_property(%Prompt, "modulate:a", 0.28, 0.55)
	tween.tween_property(%Prompt, "modulate:a", 1.0, 0.55)
	_reveal_after_layout()
	_resized()
	resized.connect(_resized)

func _resized() -> void:
	# The cover is portrait art. A dedicated art column preserves Cobie's face and
	# weapon instead of using full-screen "cover" cropping on wide displays.
	var wide := size.x / maxf(size.y, 1.0) >= 1.55
	%ArtColumn.anchor_right = 0.56 if wide else 1.0
	%ArtColumn.anchor_bottom = 1.0 if wide else 0.76
	%BrandPanel.anchor_left = 0.56 if wide else 0.0
	%BrandPanel.anchor_top = 0.0 if wide else 0.70
	%BrandPanel.offset_left = 0.0
	%BrandPanel.offset_top = 0.0

func _reveal_after_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	modulate.a = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if _accepting or not event.is_pressed():
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		_accepting = true
		%ProceduralAudio.play(ProceduralAudio.Cue.ACCEPT)
		SceneRouter.go_to(menu_scene_path)
