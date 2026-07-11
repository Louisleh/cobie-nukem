class_name VictoryScreen
extends CanvasLayer

const FeedbackScene := preload("res://scenes/ui/playtest_report.tscn")
var _summary: Dictionary = {}

func _ready() -> void:
	visible = false
	%MainMenuButton.pressed.connect(func() -> void: _route("res://scenes/menus/main_menu.tscn"))
	%ReplayButton.pressed.connect(func() -> void:
		var game_state := get_node_or_null("/root/GameState")
		if game_state: game_state.begin_run(&"no_dogs_allowed")
		_route("res://scenes/levels/episode_1_level_1.tscn")
	)
	%FeedbackButton.pressed.connect(_open_feedback)
	%BuildLabel.text = BuildInfo.label()

func show_summary(summary: Dictionary) -> void:
	_summary = summary.duplicate(true)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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

func _route(path: String) -> void:
	var router := get_node_or_null("/root/SceneRouter")
	if router: router.go_to(path)
