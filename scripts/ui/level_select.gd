class_name LevelSelectController
extends Control

@export var levels: Array[LevelCardData] = []
@export_file("*.tscn") var menu_scene_path := "res://scenes/menus/main_menu.tscn"
@export var campaign_unlock_override := false

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
var _campaign_progress: CampaignProgressRuntime
var _difficulty_group := ButtonGroup.new()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%BuildLabel.text = BuildInfo.label()
	GameState._set_phase(GameState.Phase.MENU)
	_prepare_campaign_progress()
	_build_cards()
	_build_difficulty_selector()
	play_button.pressed.connect(_activate_selected)
	%BackButton.pressed.connect(_back)
	play_button.focus_neighbor_bottom = play_button.get_path_to(%BackButton)
	%BackButton.focus_neighbor_top = %BackButton.get_path_to(play_button)
	var first_enabled := _first_selectable_index()
	if not _cards.is_empty():
		_select(first_enabled)
		if not _cards[first_enabled].disabled:
			_cards[first_enabled].grab_focus()
		else:
			%BackButton.grab_focus()

func _prepare_campaign_progress() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	_campaign_progress = CampaignProgressRuntime.new()
	add_child(_campaign_progress)
	if _campaign_progress.configure(save_manager):
		_campaign_progress.load_progress()

func _build_cards() -> void:
	for child in card_row.get_children():
		child.queue_free()
	_cards.clear()
	var focusable_cards: Array[Button] = []
	for index in levels.size():
		var data := levels[index]
		var available := data.is_available(_campaign_progress, campaign_unlock_override)
		var card := Button.new()
		card.custom_minimum_size = Vector2(105.0, 43.0)
		card.add_theme_font_size_override("font_size", 6)
		card.text = "%02d  %s\n%s" % [index + 1, data.status_badge(_campaign_progress, campaign_unlock_override), data.title]
		card.icon = data.preview
		card.expand_icon = true
		card.tooltip_text = data.description
		card.disabled = not available
		card.focus_mode = Control.FOCUS_NONE if card.disabled else Control.FOCUS_ALL
		if not card.disabled:
			focusable_cards.append(card)
		card.mouse_entered.connect(func() -> void:
			card.grab_focus()
			_select(index)
		)
		card.focus_entered.connect(func() -> void: _select(index))
		card.pressed.connect(func() -> void: _activate(index))
		card_row.add_child(card)
		_cards.append(card)
	if focusable_cards.size() == 0:
		return
	for index in focusable_cards.size():
		var current := focusable_cards[index]
		var previous := focusable_cards[(index - 1 + focusable_cards.size()) % focusable_cards.size()]
		var next := focusable_cards[(index + 1) % focusable_cards.size()]
		current.focus_neighbor_left = current.get_path_to(previous)
		current.focus_neighbor_right = current.get_path_to(next)
		if _difficulty_buttons.is_empty():
			current.focus_neighbor_bottom = current.get_path_to(play_button)

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
			var focused := false
			for card in _cards:
				if card.focus_mode == Control.FOCUS_ALL:
					focused = true
					card.focus_neighbor_bottom = card.get_path_to(button)
			if focused:
				play_button.focus_neighbor_top = play_button.get_path_to(button)
	if not _difficulty_buttons.is_empty():
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
	var available := data.is_available(_campaign_progress, campaign_unlock_override)
	episode_label.text = data.episode
	title_label.text = data.title
	description_label.text = data.description
	difficulty_label.text = "DIFFICULTY  %d / 5 PAWS" % clampi(data.difficulty, 1, 5)
	details_label.text = "%s  •  %d SECRETS  •  %s" % [data.expected_minutes, data.secrets, data.encounter]
	preview.texture = data.preview
	play_button.disabled = not available
	play_button.focus_mode = Control.FOCUS_NONE if play_button.disabled else Control.FOCUS_ALL
	play_button.text = ("START %s" % data.status_badge(_campaign_progress, campaign_unlock_override)) if data.is_preview_release(_campaign_progress, campaign_unlock_override) else ("START MISSION" if available else "LOCKED")
	if not play_button.disabled:
		play_button.grab_focus()
	if not available:
		status_label.text = "COMING SOON // FUTURE MISSION"
	elif data.is_preview_release(_campaign_progress, campaign_unlock_override):
		status_label.text = data.launch_notice if not data.launch_notice.strip_edges().is_empty() else "%s // PUBLIC WORK IN PROGRESS" % data.status_badge(_campaign_progress, campaign_unlock_override)
	else:
		status_label.text = "READY"

func _activate_selected() -> void:
	_activate(_selected)

func _activate(index: int) -> void:
	if index < 0 or index >= levels.size():
		return
	var data := levels[index]
	if not data.is_available(_campaign_progress, campaign_unlock_override) or data.scene_path.is_empty():
		status_label.text = "LOCKED // ANIMAL CONTROL SEALED THIS COURSE"
		sounds.play(ProceduralAudio.Cue.ERROR)
		return
	SaveManager.delete_slot(&"checkpoint")
	GameState.continue_requested = false
	GameState.begin_run(data.level_id)
	# Browser pointer lock must be requested synchronously from a trusted click or
	# key activation. Player._ready() runs after that gesture has expired, which
	# made a pause/resume round trip appear to "fix" mouse aiming. Capture here,
	# while the Start button gesture is still active; the player retains a safe
	# click-to-aim fallback for focus loss and keyboard-only launches.
	if not MobileControls.touchscreen_expected():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var result := SceneRouter.go_to(data.scene_path)
	if result != OK:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		status_label.text = "MISSION ROUTE OFFLINE"
		sounds.play(ProceduralAudio.Cue.ERROR)

func _back() -> void:
	SceneRouter.go_to(menu_scene_path)

func _first_selectable_index() -> int:
	for index in _cards.size():
		if not _cards[index].disabled:
			return index
	return 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu_back") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_back()
