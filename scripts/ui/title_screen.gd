extends Control

enum Readiness { WARMING, READY, FAILED, TRANSITIONING }

@export_file("*.tscn") var menu_scene_path := "res://scenes/menus/main_menu.tscn"
@export var minimum_warmup_seconds := 0.35
@export var play_intro_audio := true

var readiness := Readiness.WARMING
var _accepting := false
var _warmup_elapsed := 0.0
var _stable_frames := 0
var _prompt_tween: Tween


func _ready() -> void:
	modulate.a = 0.0
	%BuildLabel.text = BuildInfo.label()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if play_intro_audio:
		%ProceduralAudio.play(ProceduralAudio.Cue.SECRET, -3.0)
	_start_warmup()
	_reveal_after_layout()
	_resized()
	resized.connect(_resized)


func _process(delta: float) -> void:
	if readiness != Readiness.WARMING:
		return
	_warmup_elapsed += delta
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(menu_scene_path, progress)
	var fraction := float(progress[0]) if not progress.is_empty() else 0.0
	%LoadingBar.value = fraction * 100.0
	%Prompt.text = "PREPARING COBIE… %d%%" % roundi(fraction * 100.0)
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_set_failed()
	elif status == ResourceLoader.THREAD_LOAD_LOADED and _warmup_elapsed >= minimum_warmup_seconds:
		_stable_frames += 1
		if _stable_frames >= 2:
			_set_ready()


func _start_warmup() -> void:
	readiness = Readiness.WARMING
	_accepting = false
	_warmup_elapsed = 0.0
	_stable_frames = 0
	%LoadingBar.visible = true
	%LoadingBar.value = 0.0
	%Prompt.modulate.a = 1.0
	%Prompt.text = "PREPARING COBIE… 0%"
	var error := ResourceLoader.load_threaded_request(menu_scene_path, "PackedScene", true)
	if error != OK:
		_set_failed()


func _set_ready() -> void:
	readiness = Readiness.READY
	%LoadingBar.visible = false
	%Prompt.text = "TAP / PRESS A KEY TO DISOBEY" if OS.has_feature("web") else "PRESS ANY BUTTON TO DISOBEY"
	if _prompt_tween != null: _prompt_tween.kill()
	_prompt_tween = create_tween().set_loops()
	_prompt_tween.tween_property(%Prompt, "modulate:a", 0.3, 0.55)
	_prompt_tween.tween_property(%Prompt, "modulate:a", 1.0, 0.55)


func _set_failed() -> void:
	readiness = Readiness.FAILED
	%LoadingBar.visible = false
	%Prompt.modulate.a = 1.0
	%Prompt.text = "LOAD FAILED — TAP / PRESS TO RETRY"


func can_accept_input() -> bool:
	return readiness == Readiness.READY and not _accepting


func _resized() -> void:
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


func _exit_tree() -> void:
	if _prompt_tween != null:
		_prompt_tween.kill()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event is InputEventMouseMotion:
		return
	var supported := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton or event is InputEventScreenTouch
	if not supported:
		return
	if readiness == Readiness.FAILED:
		_start_warmup()
		get_viewport().set_input_as_handled()
		return
	if not can_accept_input():
		return
	_accepting = true
	readiness = Readiness.TRANSITIONING
	if _prompt_tween != null: _prompt_tween.kill()
	%Prompt.modulate.a = 1.0
	%Prompt.text = "OPENING KENNEL…"
	%LoadingBar.visible = true
	%LoadingBar.value = 100.0
	%ProceduralAudio.play(ProceduralAudio.Cue.ACCEPT)
	SceneRouter.go_to(menu_scene_path)
