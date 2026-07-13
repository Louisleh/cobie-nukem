class_name LevelSelectController
extends Control

@export var levels: Array[LevelCardData] = []
@export_file("*.tscn") var menu_scene_path := "res://scenes/menus/main_menu.tscn"

@onready var card_row: HBoxContainer = %CardRow
@onready var preview: TextureRect = %Preview
@onready var episode_label: Label = %EpisodeLabel
@onready var title_label: Label = %LevelTitle
@onready var description_label: Label = %Description
@onready var difficulty_label: Label = %Difficulty
@onready var details_label: Label = %Details
@onready var status_label: Label = %StatusLabel
@onready var play_button: Button = %PlayButton
@onready var sounds: ProceduralAudio = %ProceduralAudio
@onready var difficulty_row: HBoxContainer = %DifficultyRow
@onready var difficulty_blurb: Label = %DifficultyBlurb

var _selected := 0
var _cards: Array[Button] = []
var _difficulty_buttons: Array[Button] = []
var _difficulty_group := ButtonGroup.new()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%BuildLabel.text = BuildInfo.label()
	GameState._set_phase(GameState.Phase.MENU)
	_build_cards()
	_build_difficulty_selector()
	play_button.pressed.connect(_activate_selected)
	%BackButton.pressed.connect(_back)
	play_button.focus_neighbor_bottom = play_button.get_path_to(%BackButton)
	%BackButton.focus_neighbor_top = %BackButton.get_path_to(play_button)
	if not _cards.is_empty():
		_select(0)
		_cards[0].grab_focus()

func _build_cards() -> void:
	for child in card_row.get_children():
		child.queue_free()
	_cards.clear()
	for index in levels.size():
		var data := levels[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(105.0, 43.0)
		card.add_theme_font_size_override("font_size", 6)
		card.text = "%02d  %s\n%s" % [index + 1, "ACTIVE" if data.unlocked else "LOCKED", data.title]
		card.icon = data.preview
		card.expand_icon = true
		card.tooltip_text = data.description
		card.focus_mode = Control.FOCUS_ALL
		card.mouse_entered.connect(func() -> void:
			card.grab_focus()
			_select(index)
		)
		card.focus_entered.connect(func() -> void: _select(index))
		card.pressed.connect(func() -> void: _activate(index))
		card_row.add_child(card)
		_cards.append(card)
	for index in _cards.size():
		var previous := _cards[(index - 1 + _cards.size()) % _cards.size()]
		var next := _cards[(index + 1) % _cards.size()]
		_cards[index].focus_neighbor_left = _cards[index].get_path_to(previous)
		_cards[index].focus_neighbor_right = _cards[index].get_path_to(next)
		_cards[index].focus_neighbor_bottom = _cards[index].get_path_to(play_button)


func _build_difficulty_selector() -> void:
	# Labels, descriptions, and tuning summaries come straight from the
	# DifficultyProfile resources so the UI can never drift from the balance data.
	_difficulty_buttons.clear()
	for profile in GameState.difficulty_options():
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = _difficulty_group
		button.text = profile.display_name
		button.tooltip_text = profile.description
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(58.0, 11.0)
		button.add_theme_font_size_override("font_size", 5)
		button.set_pressed_no_signal(profile.id == GameState.difficulty_id)
		button.pressed.connect(_on_difficulty_pressed.bind(profile))
		button.mouse_entered.connect(button.grab_focus)
		difficulty_row.add_child(button)
		_difficulty_buttons.append(button)
	for index in _difficulty_buttons.size():
		var button := _difficulty_buttons[index]
		var previous := _difficulty_buttons[(index - 1 + _difficulty_buttons.size()) % _difficulty_buttons.size()]
		var next := _difficulty_buttons[(index + 1) % _difficulty_buttons.size()]
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_neighbor_right = button.get_path_to(next)
		button.focus_neighbor_bottom = button.get_path_to(play_button)
		if not _cards.is_empty():
			button.focus_neighbor_top = button.get_path_to(_cards[0])
	if not _difficulty_buttons.is_empty():
		for card in _cards:
			card.focus_neighbor_bottom = card.get_path_to(_difficulty_buttons[0])
		play_button.focus_neighbor_top = play_button.get_path_to(_difficulty_buttons[0])
	_update_difficulty_blurb()


func _on_difficulty_pressed(profile: DifficultyProfile) -> void:
	if GameState.select_difficulty(profile.id):
		sounds.play(ProceduralAudio.Cue.ACCEPT, -6.0)
	else:
		# A profile resource with a broken id must not silently change the run.
		sounds.play(ProceduralAudio.Cue.ERROR)
	_sync_difficulty_buttons()


func _sync_difficulty_buttons() -> void:
	var options := GameState.difficulty_options()
	for index in mini(options.size(), _difficulty_buttons.size()):
		_difficulty_buttons[index].set_pressed_no_signal(options[index].id == GameState.difficulty_id)
	_update_difficulty_blurb()


func _update_difficulty_blurb() -> void:
	var profile := GameState.get_difficulty_profile()
	if profile == null:
		difficulty_blurb.text = ""
		return
	difficulty_blurb.text = "%s  //  ENEMY HP x%.2f • DMG x%.2f • PICKUPS x%.2f • AIM ASSIST %d%%" % [
		profile.description.strip_edges(),
		profile.enemy_health_multiplier,
		profile.enemy_damage_multiplier,
		profile.pickup_amount_multiplier,
		roundi(profile.aim_assist_strength * 100.0),
	]

func _select(index: int) -> void:
	if index < 0 or index >= levels.size():
		return
	_selected = index
	var data := levels[index]
	episode_label.text = data.episode
	title_label.text = data.title
	description_label.text = data.description
	difficulty_label.text = "DIFFICULTY  %d / 5 PAWS" % clampi(data.difficulty, 1, 5)
	details_label.text = "%s  •  %d SECRETS  •  %s" % [data.expected_minutes, data.secrets, data.encounter]
	preview.texture = data.preview
	play_button.disabled = not data.unlocked
	play_button.focus_mode = Control.FOCUS_NONE if play_button.disabled else Control.FOCUS_ALL
	play_button.text = "START MISSION" if data.unlocked else "LOCKED"
	status_label.text = "READY" if data.unlocked else "COMING SOON // FUTURE MISSION"

func _activate_selected() -> void:
	_activate(_selected)

func _activate(index: int) -> void:
	if index < 0 or index >= levels.size():
		return
	var data := levels[index]
	if not data.unlocked or data.scene_path.is_empty():
		status_label.text = "LOCKED // ANIMAL CONTROL SEALED THIS COURSE"
		sounds.play(ProceduralAudio.Cue.ERROR)
		return
	SaveManager.delete_slot(&"checkpoint")
	GameState.continue_requested = false
	GameState.begin_run(data.level_id)
	var result := SceneRouter.go_to(data.scene_path)
	if result != OK:
		status_label.text = "MISSION ROUTE OFFLINE"
		sounds.play(ProceduralAudio.Cue.ERROR)

func _back() -> void:
	SceneRouter.go_to(menu_scene_path)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu_back") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_back()
