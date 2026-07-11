class_name OptionsMenu
extends Control

@export_file("*.tscn") var back_scene_path := "res://scenes/menus/main_menu.tscn"
@onready var sounds: ProceduralAudio = %ProceduralAudio

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_bind_slider(%MasterSlider, &"audio", &"master")
	_bind_slider(%MusicSlider, &"audio", &"music")
	_bind_slider(%SfxSlider, &"audio", &"sfx")
	_bind_slider(%ShakeSlider, &"accessibility", &"camera_shake")
	_bind_slider(%BobSlider, &"accessibility", &"head_bob")
	%ReducedFlashes.button_pressed = bool(SettingsManager.get_value(&"video", &"reduced_flashes", false))
	%ReducedFlashes.toggled.connect(func(value: bool) -> void: SettingsManager.set_value(&"video", &"reduced_flashes", value))
	_setup_choice(%AutoAimChoice, ["OFF", "LIGHT", "CLASSIC", "HEAVY"], String(SettingsManager.get_value(&"accessibility", &"auto_aim", "classic")).to_upper(), func(text: String) -> void: SettingsManager.set_value(&"accessibility", &"auto_aim", text.to_lower()))
	_setup_choice(%GoreChoice, ["OFF", "CARTOON", "RETRO"], String(SettingsManager.get_value(&"accessibility", &"gore", "cartoon")).to_upper(), func(text: String) -> void: SettingsManager.set_value(&"accessibility", &"gore", text.to_lower()))
	%BackButton.pressed.connect(_back)
	%ResetButton.pressed.connect(_reset)
	%MasterSlider.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back"):
		_back()

func _bind_slider(slider: HSlider, section: StringName, key: StringName) -> void:
	slider.value = float(SettingsManager.get_value(section, key, 1.0)) * 100.0
	slider.value_changed.connect(func(value: float) -> void:
		SettingsManager.set_value(section, key, value / 100.0)
	)

func _setup_choice(choice: OptionButton, values: Array[String], selected: String, callback: Callable) -> void:
	for value in values:
		choice.add_item(value)
	choice.select(maxi(0, values.find(selected)))
	choice.item_selected.connect(func(index: int) -> void: callback.call(choice.get_item_text(index)))

func _reset() -> void:
	SettingsManager.reset_to_defaults()
	sounds.play(ProceduralAudio.Cue.ACCEPT)
	get_tree().reload_current_scene()

func _back() -> void:
	sounds.play(ProceduralAudio.Cue.BACK)
	SceneRouter.go_to(back_scene_path)

