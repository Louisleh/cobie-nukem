class_name LevelSelectController
extends Control

@export var levels: Array[LevelCardData] = []
@export var episode_definition: EpisodeDefinition
@export_file("*.tscn") var menu_scene_path := "res://scenes/menus/main_menu.tscn"
@export var campaign_unlock_override := false
@export var threaded_warmup_enabled := true

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
var _mission_group := ButtonGroup.new()
var _launching := false
var _warmup_paths := PackedStringArray()
var _warmup_resources: Array[Resource] = []
var _warmup_requests: Dictionary = {}
var _warmup_cache: Dictionary = {}
var _warmup_failures: Dictionary = {}
var _warmup_ready := false
var _warmup_failed := false
var _warmup_locked := false
var _back_pending := false
var _pending_launch_index := -1
var _warmup_error_announced := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if episode_definition != null:
		levels = episode_definition.cards.duplicate()
	%BuildLabel.text = BuildInfo.label()
	GameState._set_phase(GameState.Phase.MENU)
	_prepare_campaign_progress()
	_build_cards()
	_build_difficulty_selector()
	play_button.pressed.connect(_activate_selected)
	%BackButton.pressed.connect(_back)
	play_button.focus_neighbor_bottom = play_button.get_path_to(%BackButton)
	%BackButton.focus_neighbor_top = %BackButton.get_path_to(play_button)
	var first_available := _first_available_index()
	if first_available >= 0:
		_select(first_available)
		_cards[first_available].grab_focus()
	elif not _cards.is_empty():
		_selected = -1
		play_button.disabled = true
		play_button.focus_mode = Control.FOCUS_NONE
		play_button.text = "NO MISSIONS AVAILABLE"
		status_label.text = "CAMPAIGN ROUTES LOCKED"
		%BackButton.grab_focus()


func _process(_delta: float) -> void:
	if _warmup_requests.is_empty():
		if _pending_launch_index >= 0:
			_commit_launch(_pending_launch_index)
		elif _back_pending:
			_finish_pending_back()
		return
	# Godot does not expose cancellation for threaded resource requests. Keep
	# polling every request we started, including requests from a card the player
	# previewed and then left, so each result is consumed exactly once rather than
	# leaking a loader record across menu churn or scene teardown.
	for path_variant in _warmup_requests.keys():
		var path := String(path_variant)
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_warmup_requests.erase(path)
			_warmup_failures[path] = true
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			_warmup_requests.erase(path)
			if resource == null:
				_warmup_failures[path] = true
			else:
				_warmup_cache[path] = resource
	_refresh_current_warmup()
	if _warmup_requests.is_empty():
		if _pending_launch_index >= 0:
			_commit_launch(_pending_launch_index)
		elif _back_pending:
			_finish_pending_back()


func _refresh_current_warmup() -> void:
	if _launching or _back_pending or _warmup_paths.is_empty():
		return
	var completed := 0.0
	_warmup_failed = false
	for path in _warmup_paths:
		if _warmup_failures.has(path):
			_warmup_failed = true
			break
		if _warmup_cache.has(path):
			completed += 1.0
			continue
		var progress: Array = []
		ResourceLoader.load_threaded_get_status(path, progress)
		completed += float(progress[0]) if not progress.is_empty() else 0.0
	if _warmup_failed:
		_warmup_ready = false
		play_button.disabled = true
		play_button.focus_mode = Control.FOCUS_NONE
		play_button.text = "LOAD FAILED"
		status_label.text = "MISSION ASSETS OFFLINE // SELECT AGAIN TO RETRY"
		if not _warmup_error_announced:
			_warmup_error_announced = true
			sounds.play(ProceduralAudio.Cue.ERROR)
		return
	if completed < float(_warmup_paths.size()):
		_warmup_ready = false
		if _selected >= 0 and _selected < levels.size():
			status_label.text = "PREPARING %s // %d%%" % [levels[_selected].title.to_upper(), roundi(completed / float(_warmup_paths.size()) * 100.0)]
		return
	_warmup_resources.clear()
	for path in _warmup_paths:
		var resource := _warmup_cache.get(path) as Resource
		if resource == null:
			_warmup_failed = true
			_warmup_ready = false
			return
		_warmup_resources.append(resource)
	_warmup_ready = true
	_refresh_selected_action()


func _finish_pending_back() -> void:
	_back_pending = false
	_launching = true
	_set_launch_controls_disabled(true)
	var result := SceneRouter.go_to(menu_scene_path)
	if result != OK:
		_launching = false
		_set_launch_controls_disabled(false)
		status_label.text = "MENU ROUTE OFFLINE"
		sounds.play(ProceduralAudio.Cue.ERROR)


func _exit_tree() -> void:
	# Consume requests that have already completed. Normal Back navigation drains
	# all outstanding work before routing; this is the last-resort cleanup path for
	# application shutdown or an external scene replacement.
	for path_variant in _warmup_requests.keys():
		var path := String(path_variant)
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
	_warmup_requests.clear()
	_warmup_cache.clear()
	_warmup_resources.clear()

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
	for index in levels.size():
		var data := levels[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(105.0, 43.0)
		card.add_theme_font_size_override("font_size", 6)
		card.text = "%02d  %s\n%s" % [index + 1, data.status_badge(_campaign_progress, _development_unlock_override()), data.title]
		card.icon = data.preview
		card.expand_icon = true
		card.tooltip_text = data.description
		# Hover and keyboard focus are previews of intent, not committed mission
		# choices. All cards remain activatable so locked teasers can deliberately
		# show their details; only their footer Start action stays disabled.
		card.focus_mode = Control.FOCUS_ALL
		card.toggle_mode = true
		card.button_group = _mission_group
		# A mission card is a selection control, not a disguised Start button.
		# Keeping launch behind the explicit footer action prevents an exploratory
		# click (or a touch used to inspect a card) from dropping into gameplay.
		card.pressed.connect(_on_card_pressed.bind(index))
		card_row.add_child(card)
		_cards.append(card)
	if _cards.is_empty():
		return
	for index in _cards.size():
		var current := _cards[index]
		var previous := _cards[(index - 1 + _cards.size()) % _cards.size()]
		var next := _cards[(index + 1) % _cards.size()]
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
			var first_available := _first_available_index()
			if first_available >= 0:
				button.focus_neighbor_top = button.get_path_to(_cards[first_available])
	if not _difficulty_buttons.is_empty():
		for card in _cards:
			card.focus_neighbor_bottom = card.get_path_to(_difficulty_buttons[0])
		play_button.focus_neighbor_top = play_button.get_path_to(_difficulty_buttons[0])
	_update_difficulty_blurb()

func _on_difficulty_pressed(profile: DifficultyProfile) -> void:
	if _launching or _warmup_locked:
		_sync_difficulty_buttons()
		return
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
	for card_index in _cards.size():
		_cards[card_index].set_pressed_no_signal(card_index == index)
	var data := levels[index]
	var available := data.is_available(_campaign_progress, _development_unlock_override())
	episode_label.text = data.episode
	title_label.text = data.title
	description_label.text = data.description
	difficulty_label.text = "DIFFICULTY  %d / 5 PAWS" % clampi(data.difficulty, 1, 5)
	details_label.text = "%s  •  %d SECRETS  •  %s" % [data.expected_minutes, data.secrets, data.encounter]
	preview.texture = data.preview
	if not available:
		status_label.text = "COMING SOON // FUTURE MISSION"
	elif data.is_preview_release(_campaign_progress, _development_unlock_override()):
		status_label.text = data.launch_notice if not data.launch_notice.strip_edges().is_empty() else "%s // PUBLIC WORK IN PROGRESS" % data.status_badge(_campaign_progress, _development_unlock_override())
	else:
		status_label.text = "SELECTED // PRESS START"
	_begin_warmup(data)


func _begin_warmup(data: LevelCardData) -> void:
	_warmup_resources.clear()
	_warmup_paths = data.warmup_paths() if data != null else PackedStringArray()
	_warmup_ready = _warmup_paths.is_empty()
	_warmup_failed = false
	_warmup_error_announced = false
	# Loading a selected card must not trap the player on it. Other cards,
	# difficulty, and Back stay responsive while prior requests finish in the
	# background; Back itself drains those requests before leaving the scene.
	_set_warmup_controls_locked(false)
	if not data.is_available(_campaign_progress, _development_unlock_override()):
		_refresh_selected_action()
		return
	# Deterministic headless UI tests validate the same paths synchronously and
	# disable the worker queue so Godot 4.7 does not leave ResourceLoader cleanup
	# records alive while the short test process exits. Runtime builds keep this on.
	if not threaded_warmup_enabled:
		for path in _warmup_paths:
			if not ResourceLoader.exists(path):
				_warmup_failed = true
				break
		_warmup_ready = not _warmup_failed
		_set_warmup_controls_locked(false)
		_refresh_selected_action()
		return
	play_button.disabled = true
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.text = "PREPARING…"
	status_label.text = "PREPARING %s // 0%%" % data.title.to_upper()
	for path in _warmup_paths:
		_warmup_failures.erase(path)
		if _warmup_cache.has(path) or _warmup_requests.has(path):
			continue
		var prior_status := ResourceLoader.load_threaded_get_status(path)
		if prior_status == ResourceLoader.THREAD_LOAD_LOADED:
			var loaded_resource := ResourceLoader.load_threaded_get(path)
			if loaded_resource != null:
				_warmup_cache[path] = loaded_resource
				continue
		var error := ResourceLoader.load_threaded_request(path, "", true)
		if error == OK or error == ERR_BUSY:
			_warmup_requests[path] = true
		else:
			_warmup_failed = true
			_warmup_failures[path] = true
			play_button.text = "LOAD FAILED"
			status_label.text = "MISSION ASSETS OFFLINE // %s" % path.get_file()
	_refresh_current_warmup()
	if _warmup_paths.is_empty():
		_set_warmup_controls_locked(false)
		_refresh_selected_action()


func _refresh_selected_action() -> void:
	if _selected < 0 or _selected >= levels.size():
		return
	var data := levels[_selected]
	var available := data.is_available(_campaign_progress, _development_unlock_override())
	play_button.disabled = not available or not _warmup_ready or _warmup_failed or _launching
	play_button.focus_mode = Control.FOCUS_NONE if play_button.disabled else Control.FOCUS_ALL
	if not available:
		play_button.text = "LOCKED"
	elif _warmup_failed:
		play_button.text = "LOAD FAILED"
	elif not _warmup_ready:
		play_button.text = "PREPARING…"
	else:
		play_button.text = ("START %s" % data.status_badge(_campaign_progress, _development_unlock_override())) if data.is_preview_release(_campaign_progress, _development_unlock_override()) else "START MISSION"
		status_label.text = data.launch_notice if data.is_preview_release(_campaign_progress, _development_unlock_override()) and not data.launch_notice.strip_edges().is_empty() else "READY // PRESS START"
	_set_warmup_controls_locked(false)


func _on_card_pressed(index: int) -> void:
	if _launching or _warmup_locked or index < 0 or index >= levels.size():
		return
	_select(index)
	sounds.play(ProceduralAudio.Cue.ACCEPT, -6.0)

func _activate_selected() -> void:
	_activate(_selected)

func _activate(index: int) -> void:
	if _launching or index < 0 or index >= levels.size():
		return
	var data := levels[index]
	if not _warmup_ready or _warmup_failed:
		status_label.text = "MISSION STILL PREPARING"
		sounds.play(ProceduralAudio.Cue.ERROR)
		return
	if not data.is_available(_campaign_progress, _development_unlock_override()) or data.scene_path.is_empty():
		status_label.text = "LOCKED // ANIMAL CONTROL SEALED THIS COURSE"
		sounds.play(ProceduralAudio.Cue.ERROR)
		return
	_launching = true
	_pending_launch_index = index
	_set_launch_controls_disabled(true)
	# Browser pointer lock must be requested synchronously from a trusted click or
	# key activation. Player._ready() runs after that gesture has expired, which
	# made a pause/resume round trip appear to "fix" mouse aiming. Capture here,
	# while the Start button gesture is still active; the player retains a safe
	# click-to-aim fallback for focus loss and keyboard-only launches.
	if not MobileControls.touchscreen_expected():
		PointerCaptureController.request_from_launch_gesture()
	if not _warmup_requests.is_empty():
		status_label.text = "FINALIZING %s..." % data.title.to_upper()
		return
	_commit_launch(index)


func _commit_launch(index: int) -> void:
	if index < 0 or index >= levels.size():
		_pending_launch_index = -1
		_launching = false
		_set_launch_controls_disabled(false)
		return
	var data := levels[index]
	_pending_launch_index = -1
	status_label.text = "LOADING %s..." % data.title.to_upper()
	var result := SceneRouter.go_to(data.scene_path)
	if result != OK:
		_launching = false
		_set_launch_controls_disabled(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		status_label.text = "MISSION ROUTE OFFLINE"
		sounds.play(ProceduralAudio.Cue.ERROR)
		_select(index)
		return
	SaveManager.delete_slot(&"checkpoint")
	GameState.continue_requested = false
	GameState.begin_run(data.level_id)


func _set_launch_controls_disabled(disabled: bool) -> void:
	var selected_available := _selected >= 0 and _selected < levels.size() and levels[_selected].is_available(_campaign_progress, _development_unlock_override())
	play_button.disabled = disabled or not selected_available or not _warmup_ready
	play_button.focus_mode = Control.FOCUS_NONE if play_button.disabled else Control.FOCUS_ALL
	for index in _cards.size():
		_cards[index].disabled = disabled
	for button in _difficulty_buttons:
		button.disabled = disabled
	%BackButton.disabled = disabled

func _set_warmup_controls_locked(value: bool) -> void:
	_warmup_locked = value
	for card in _cards:
		card.disabled = value
	for button in _difficulty_buttons:
		button.disabled = value
	%BackButton.disabled = value

func _back() -> void:
	if _launching or _back_pending:
		return
	if not _warmup_requests.is_empty():
		_back_pending = true
		_set_warmup_controls_locked(true)
		play_button.disabled = true
		play_button.focus_mode = Control.FOCUS_NONE
		status_label.text = "FINISHING PREPARATION…"
		return
	_launching = true
	_set_launch_controls_disabled(true)
	if SceneRouter.go_to(menu_scene_path) != OK:
		_launching = false
		_set_launch_controls_disabled(false)
		status_label.text = "MENU ROUTE OFFLINE"
		sounds.play(ProceduralAudio.Cue.ERROR)

func _first_available_index() -> int:
	for index in levels.size():
		if levels[index].is_available(_campaign_progress, _development_unlock_override()):
			return index
	return -1


func _development_unlock_override() -> bool:
	# The route override is intentionally unavailable to release exports even if a
	# scene was accidentally saved with the inspector toggle enabled.
	return campaign_unlock_override and OS.is_debug_build()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu_back") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_back()
