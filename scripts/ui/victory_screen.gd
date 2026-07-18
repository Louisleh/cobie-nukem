class_name VictoryScreen
extends CanvasLayer

const FeedbackScene := preload("res://scenes/ui/playtest_report.tscn")
const Campaign: EpisodeDefinition = preload("res://resources/campaign/episode_one.tres")
const FALLBACK_REPLAY_SCENE := "res://scenes/levels/episode_1_level_1.tscn"
var _summary: Dictionary = {}
var _mission_metadata: LevelMetadata
var _routing := false

func _ready() -> void:
	visible = false
	%MainMenuButton.pressed.connect(func() -> void: _route("res://scenes/menus/main_menu.tscn"))
	%ReplayButton.pressed.connect(_on_replay)
	%FeedbackButton.pressed.connect(_open_feedback)
	%ContinueButton.pressed.connect(_on_continue)
	%ContinueButton.visible = false
	%ContinueButton.focus_mode = Control.FOCUS_NONE
	%BuildLabel.text = BuildInfo.label()

func show_summary(summary: Dictionary) -> void:
	_summary = summary.duplicate(true)
	_mission_metadata = _metadata_for(String(summary.get("level_id", "")))
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_victory_buttons()
	var seconds := int(summary.get("duration_msec", 0)) / 1000
	var shots := maxi(1, int(summary.get("shots_fired", 0)))
	var accuracy := float(summary.get("shots_hit", 0)) / shots
	var secrets := int(summary.get("secrets_found", 0))
	%TimeValue.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	%EnemiesValue.text = str(summary.get("enemies_defeated", 0))
	%SecretsValue.text = "%d / %d" % [secrets, int(summary.get("secrets_total", 3))]
	%AccuracyValue.text = "%d%%" % int(round(accuracy * 100.0))
	%DamageValue.text = str(int(round(float(summary.get("damage_taken", 0.0)))))
	%ControlValue.text = String(summary.get("control_method", "KEYBOARD + MOUSE")).to_upper()
	%RankLabel.text = _rank(seconds, secrets, accuracy)
	%ProceduralAudio.play(ProceduralAudio.Cue.VICTORY)
	%ReplayButton.grab_focus()

func _metadata_for(level_id: String) -> LevelMetadata:
	return Campaign.metadata_for(StringName(level_id))

func _update_victory_buttons() -> void:
	if _mission_metadata == null:
		%ContinueButton.visible = false
		%ContinueButton.focus_mode = Control.FOCUS_NONE
		return
	var has_continue := _mission_metadata.has_next_mission()
	%ContinueButton.visible = has_continue
	%ContinueButton.focus_mode = Control.FOCUS_ALL if has_continue else Control.FOCUS_NONE
	if not has_continue:
		return
	var destination := _mission_metadata.next_mission_title.strip_edges()
	%ContinueButton.text = "CONTINUE %s" % [destination if not destination.is_empty() else _mission_metadata.next_mission_id]

func _on_replay() -> void:
	var replay_scene := FALLBACK_REPLAY_SCENE
	var level_id := &"episode_1_level_1"
	if _mission_metadata != null:
		replay_scene = _mission_metadata.replay_scene if not _mission_metadata.replay_scene.strip_edges().is_empty() else replay_scene
		level_id = _mission_metadata.level_id if _mission_metadata.level_id != &"" else level_id
	if _route_gameplay(replay_scene):
		var game_state := get_node_or_null("/root/GameState")
		if game_state:
			game_state.begin_run(level_id)
			game_state.continue_requested = false

func _on_continue() -> void:
	if _mission_metadata == null or _mission_metadata.next_mission_scene.is_empty() or _mission_metadata.next_mission_id == &"":
		return
	if _route_gameplay(_mission_metadata.next_mission_scene):
		var game_state := get_node_or_null("/root/GameState")
		if game_state:
			game_state.begin_run(_mission_metadata.next_mission_id)
			game_state.continue_requested = false

func _open_feedback() -> void:
	var report := FeedbackScene.instantiate() as PlaytestReport
	add_child(report)
	report.closed.connect(report.queue_free)
	report.open(_summary)

func _rank(seconds: int, secrets: int, accuracy: float) -> String:
	var score := secrets * 2 + int(accuracy >= 0.5) + int(seconds > 0 and seconds < 900)
	if score >= 8:
		return "COBIE NUKEM"
	if score >= 6:
		return "UNLEASHED"
	if score >= 4:
		return "TACTICAL LABRADOODLE"
	if score >= 2:
		return "VERY GOOD DOG"
	return "GOOD DOG"

func _route_gameplay(path: String) -> bool:
	if not MobileControls.touchscreen_expected():
		PointerCaptureController.request_from_launch_gesture()
	var accepted := _route(path)
	if not accepted:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return accepted

func _route(path: String) -> bool:
	if _routing:
		return false
	var router := get_node_or_null("/root/SceneRouter")
	if router == null or router.go_to(path) != OK:
		return false
	_routing = true
	for button in [%MainMenuButton, %ReplayButton, %FeedbackButton, %ContinueButton]:
		button.disabled = true
	return true
