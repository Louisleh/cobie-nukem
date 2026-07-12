class_name OptionsMenu
extends Control

signal back_requested

@export_file("*.tscn") var back_scene_path := "res://scenes/menus/main_menu.tscn"
@export var embedded := false
@onready var sounds: ProceduralAudio = %ProceduralAudio
@onready var settings: Node = get_node_or_null("/root/SettingsManager")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_bind_slider(%MasterSlider, &"audio", &"master")
	_bind_slider(%MusicSlider, &"audio", &"music")
	_bind_slider(%SfxSlider, &"audio", &"sfx")
	_bind_slider(%ShakeSlider, &"accessibility", &"camera_shake")
	_bind_slider(%BobSlider, &"accessibility", &"head_bob")
	_bind_slider(%MouseSensitivitySlider, &"gameplay", &"mouse_sensitivity")
	_bind_slider(%TouchSensitivitySlider, &"gameplay", &"touch_sensitivity")
	_bind_slider(%ControlOpacitySlider, &"gameplay", &"control_opacity")
	_bind_slider(%TextScaleSlider, &"accessibility", &"text_scale")
	%FovSlider.value = float(_setting_value(&"video", &"fov", 90.0))
	%FovSlider.value_changed.connect(func(value: float) -> void: _set_setting(&"video", &"fov", value))
	%ReducedFlashes.button_pressed = bool(_setting_value(&"video", &"reduced_flashes", false))
	%ReducedFlashes.toggled.connect(func(value: bool) -> void: _set_setting(&"video", &"reduced_flashes", value))
	_setup_choice(%AutoAimChoice, ["OFF", "LIGHT", "CLASSIC", "HEAVY"], String(_setting_value(&"accessibility", &"auto_aim", "classic")).to_upper(), func(text: String) -> void: _set_setting(&"accessibility", &"auto_aim", text.to_lower()))
	_setup_choice(%GoreChoice, ["OFF", "CARTOON", "RETRO"], String(_setting_value(&"accessibility", &"gore", "cartoon")).to_upper(), func(text: String) -> void: _set_setting(&"accessibility", &"gore", text.to_lower()))
	_setup_choice(%RunModeChoice, ["HOLD", "TOGGLE"], String(_setting_value(&"gameplay", &"run_mode", "hold")).to_upper(), func(text: String) -> void: _set_setting(&"gameplay", &"run_mode", text.to_lower()))
	%Subtitles.button_pressed = bool(_setting_value(&"accessibility", &"subtitles", true))
	%Subtitles.toggled.connect(func(value: bool) -> void: _set_setting(&"accessibility", &"subtitles", value))
	%HighContrast.button_pressed = bool(_setting_value(&"accessibility", &"high_contrast", false))
	%HighContrast.toggled.connect(func(value: bool) -> void: _set_setting(&"accessibility", &"high_contrast", value))
	%ReducedMotion.button_pressed = bool(_setting_value(&"accessibility", &"reduced_motion", false))
	%ReducedMotion.toggled.connect(func(value: bool) -> void: _set_setting(&"accessibility", &"reduced_motion", value))
	%LeftHandedTouch.button_pressed = bool(_setting_value(&"gameplay", &"left_handed_touch", false))
	%LeftHandedTouch.toggled.connect(func(value: bool) -> void: _set_setting(&"gameplay", &"left_handed_touch", value))
	_setup_choice(%QualityChoice, ["AUTO", "WEB", "NATIVE"], String(_setting_value(&"video", &"quality", "auto")).to_upper(), func(text: String) -> void:
		_set_setting(&"video", &"quality", text.to_lower())
		var quality := get_node_or_null("/root/QualityManager")
		if quality != null: quality.apply_auto_profile()
	)
	for control in %Scroll.find_children("*", "Control", true, false):
		if control.focus_mode != Control.FOCUS_NONE:
			control.focus_entered.connect(func() -> void: %Scroll.ensure_control_visible(control))
	%BackButton.pressed.connect(_back)
	%ResetButton.pressed.connect(_reset)
	%MouseSensitivitySlider.grab_focus()
	_reset_scroll_after_layout()

func _reset_scroll_after_layout() -> void:
	await get_tree().process_frame
	%Scroll.scroll_vertical = 0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		%Scroll.scroll_vertical += direction * 24
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back"):
		_back()

func _bind_slider(slider: HSlider, section: StringName, key: StringName) -> void:
	slider.value = float(_setting_value(section, key, 1.0)) * 100.0
	slider.value_changed.connect(func(value: float) -> void:
		_set_setting(section, key, value / 100.0)
	)

func _setup_choice(choice: OptionButton, values: Array[String], selected: String, callback: Callable) -> void:
	for value in values:
		choice.add_item(value)
	choice.select(maxi(0, values.find(selected)))
	choice.item_selected.connect(func(index: int) -> void: callback.call(choice.get_item_text(index)))

func _reset() -> void:
	if settings != null and settings.has_method("reset_to_defaults"):
		settings.call("reset_to_defaults")
	sounds.play(ProceduralAudio.Cue.ACCEPT)
	if embedded:
		_refresh_values()
	else:
		get_tree().reload_current_scene()

func _back() -> void:
	sounds.play(ProceduralAudio.Cue.BACK)
	if embedded:
		back_requested.emit()
		queue_free()
	else:
		var router := get_node_or_null("/root/SceneRouter")
		if router != null and router.has_method("go_to"):
			router.call("go_to", back_scene_path)

func _refresh_values() -> void:
	%MasterSlider.value = float(_setting_value(&"audio", &"master", 1.0)) * 100.0
	%MusicSlider.value = float(_setting_value(&"audio", &"music", 0.8)) * 100.0
	%SfxSlider.value = float(_setting_value(&"audio", &"sfx", 0.9)) * 100.0
	%ShakeSlider.value = float(_setting_value(&"accessibility", &"camera_shake", 1.0)) * 100.0
	%BobSlider.value = float(_setting_value(&"accessibility", &"head_bob", 1.0)) * 100.0
	%MouseSensitivitySlider.value = float(_setting_value(&"gameplay", &"mouse_sensitivity", 1.0)) * 100.0
	%TouchSensitivitySlider.value = float(_setting_value(&"gameplay", &"touch_sensitivity", 1.0)) * 100.0
	%ControlOpacitySlider.value = float(_setting_value(&"gameplay", &"control_opacity", 0.75)) * 100.0
	%TextScaleSlider.value = float(_setting_value(&"accessibility", &"text_scale", 1.0)) * 100.0
	%FovSlider.value = float(_setting_value(&"video", &"fov", 90.0))
	%ReducedFlashes.button_pressed = bool(_setting_value(&"video", &"reduced_flashes", false))
	_select_choice(%AutoAimChoice, String(_setting_value(&"accessibility", &"auto_aim", "classic")).to_upper())
	_select_choice(%GoreChoice, String(_setting_value(&"accessibility", &"gore", "cartoon")).to_upper())
	_select_choice(%RunModeChoice, String(_setting_value(&"gameplay", &"run_mode", "hold")).to_upper())
	%Subtitles.button_pressed = bool(_setting_value(&"accessibility", &"subtitles", true))
	%HighContrast.button_pressed = bool(_setting_value(&"accessibility", &"high_contrast", false))
	%ReducedMotion.button_pressed = bool(_setting_value(&"accessibility", &"reduced_motion", false))
	%LeftHandedTouch.button_pressed = bool(_setting_value(&"gameplay", &"left_handed_touch", false))
	_select_choice(%QualityChoice, String(_setting_value(&"video", &"quality", "auto")).to_upper())

func _select_choice(choice: OptionButton, selected: String) -> void:
	for index in choice.item_count:
		if choice.get_item_text(index) == selected:
			choice.select(index)
			return

func _setting_value(section: StringName, key: StringName, fallback: Variant) -> Variant:
	if settings != null and settings.has_method("get_value"):
		return settings.call("get_value", section, key, fallback)
	return fallback

func _set_setting(section: StringName, key: StringName, value: Variant) -> void:
	if settings != null and settings.has_method("set_value"):
		settings.call("set_value", section, key, value)
