extends Control

const PipelinePrewarmer := preload("res://scripts/core/runtime_pipeline_prewarmer.gd")

const _WIDE_ASPECT_RATIO := 1.55
const _NON_WIDE_FONT_SCALE_MIN := 0.75
const _NON_WIDE_FONT_SCALE_MAX := 1.0
const _NON_WIDE_FONT_BASE_WIDTH := 1120.0
const _NON_WIDE_FONT_BASE_HEIGHT := 760.0
const _NON_WIDE_FOLD := 0.56
const _NON_WIDE_COMPACT_FOLD := 0.44
const _NON_WIDE_COMPACT_THRESHOLD := 560.0
const _NON_WIDE_COMPACT_PANEL_BOTTOM := 5.0
const _NON_WIDE_BRAND_OVERLAP := 0.03
const _TITLE_BAR_HEIGHT_WIDE := 10.0
const _TITLE_BAR_HEIGHT_COMPACT := 7.0
const _TITLE_FONT_SIZES_WIDE := {
	&"eyebrow": 10,
	&"title": 26,
	&"mission_brief": 10,
	&"prompt": 12,
	&"build": 6,
}

enum Readiness { WARMING, READY, FAILED, TRANSITIONING }

@export_file("*.tscn") var menu_scene_path := "res://scenes/menus/main_menu.tscn"
@export var minimum_warmup_seconds := 0.35
@export var play_intro_audio := true
@export var runtime_warmup_enabled := true

var readiness := Readiness.WARMING
var _accepting := false
var _warmup_elapsed := 0.0
var _stable_frames := 0
var _prompt_tween: Tween
var _preloaded_menu: PackedScene
var _layout_frames_remaining := 2
var _pipeline_warmup_started := false
var _pipeline_prewarmer: Node
@onready var _art_cover: TextureRect = %ArtColumn.get_node("Cover") as TextureRect


func _ready() -> void:
	modulate.a = 0.0
	%BuildLabel.text = BuildInfo.label()
	_art_cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	if _pipeline_warmup_started:
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
			_start_pipeline_warmup()


func _start_warmup() -> void:
	readiness = Readiness.WARMING
	_accepting = false
	_warmup_elapsed = 0.0
	_stable_frames = 0
	_pipeline_warmup_started = false
	%LoadingBar.visible = true
	%LoadingBar.value = 0.0
	%Prompt.modulate.a = 1.0
	%Prompt.text = "PREPARING COBIE… 0%"
	if not runtime_warmup_enabled:
		if ResourceLoader.exists(menu_scene_path):
			call_deferred("_set_ready")
		else:
			call_deferred("_set_failed")
		return
	var error := ResourceLoader.load_threaded_request(menu_scene_path, "PackedScene", true)
	if error != OK:
		_set_failed()


func _start_pipeline_warmup() -> void:
	# Finalize the threaded request. Polling LOADED without retrieving the
	# Resource leaves its loader request alive through SceneTree teardown.
	_preloaded_menu = ResourceLoader.load_threaded_get(menu_scene_path) as PackedScene
	if _preloaded_menu == null:
		_set_failed()
		return
	_pipeline_warmup_started = true
	%LoadingBar.value = 96.0
	%Prompt.text = "WARMING COMBAT SYSTEMS…"
	%ProceduralAudio.prewarm_runtime()
	_pipeline_prewarmer = PipelinePrewarmer.new()
	_pipeline_prewarmer.name = "RuntimePipelinePrewarmer"
	add_child(_pipeline_prewarmer)
	_pipeline_prewarmer.completed.connect(_set_ready, CONNECT_ONE_SHOT)
	_pipeline_prewarmer.warm(PackedStringArray([
		"res://scenes/enemies/enemy_bolt.tscn",
		"res://scenes/weapons/fetch_projectile.tscn",
		"res://scenes/enemies/mutant_groundskeeper.tscn",
		"res://scenes/enemies/leash_enforcement_drone.tscn",
		"res://scenes/enemies/compliance_hound.tscn",
		"res://scenes/enemies/squirrel_trooper.tscn",
		"res://scenes/enemies/animal_control_walker.tscn",
	]))


func _set_ready() -> void:
	if _pipeline_prewarmer != null:
		_pipeline_prewarmer.queue_free()
		_pipeline_prewarmer = null
	readiness = Readiness.READY
	%LoadingBar.visible = false
	%Prompt.text = "TAP / PRESS A KEY TO DISOBEY" if OS.has_feature("web") else "PRESS ANY BUTTON TO DISOBEY"
	if _prompt_tween != null: _prompt_tween.kill()
	_prompt_tween = create_tween().set_loops()
	_prompt_tween.tween_property(%Prompt, "modulate:a", 0.55, 0.55)
	_prompt_tween.tween_property(%Prompt, "modulate:a", 1.0, 0.55)


func _set_failed() -> void:
	readiness = Readiness.FAILED
	%LoadingBar.visible = false
	%Prompt.modulate.a = 1.0
	%Prompt.text = "LOAD FAILED — TAP / PRESS TO RETRY"


func can_accept_input() -> bool:
	return readiness == Readiness.READY and not _accepting


func _resized() -> void:
	var viewport_size := maxf(size.x, 1.0)
	var viewport_height := maxf(size.y, 1.0)
	var wide := viewport_size / viewport_height >= _WIDE_ASPECT_RATIO
	var x_margin := clampf(viewport_size * 0.02, 10.0, 28.0)
	var y_margin := clampf(viewport_height * 0.022, 8.0, 24.0)

	if wide:
		%ArtColumn.anchor_left = 0.0
		%ArtColumn.anchor_top = 0.0
		%ArtColumn.anchor_right = 0.52
		%ArtColumn.anchor_bottom = 1.0
		%ArtColumn.offset_left = 0.0
		%ArtColumn.offset_top = 0.0
		%ArtColumn.offset_right = 0.0
		%ArtColumn.offset_bottom = -y_margin

		%BrandPanel.anchor_left = 0.52
		%BrandPanel.anchor_top = 0.0
		%BrandPanel.anchor_right = 1.0
		%BrandPanel.anchor_bottom = 1.0
		%BrandPanel.offset_left = x_margin
		%BrandPanel.offset_top = y_margin
		%BrandPanel.offset_right = -x_margin
		%BrandPanel.offset_bottom = -y_margin
	else:
		var lower_fold := _non_wide_fold(viewport_height)
		var compact_bottom := y_margin if viewport_height > _NON_WIDE_COMPACT_THRESHOLD else _NON_WIDE_COMPACT_PANEL_BOTTOM
		%ArtColumn.anchor_left = 0.0
		%ArtColumn.anchor_top = 0.0
		%ArtColumn.anchor_right = 1.0
		%ArtColumn.anchor_bottom = lower_fold
		%ArtColumn.offset_left = x_margin
		%ArtColumn.offset_top = y_margin
		%ArtColumn.offset_right = -x_margin
		%ArtColumn.offset_bottom = -compact_bottom

		%BrandPanel.anchor_left = 0.0
		%BrandPanel.anchor_top = max(0.0, lower_fold - _NON_WIDE_BRAND_OVERLAP)
		%BrandPanel.anchor_right = 1.0
		%BrandPanel.anchor_bottom = 1.0
		%BrandPanel.offset_left = x_margin
		%BrandPanel.offset_top = 0.0
		%BrandPanel.offset_right = -x_margin
		%BrandPanel.offset_bottom = -compact_bottom
	_apply_dossier_typography(wide)
	_center_dossier_layout()


func _non_wide_fold(height: float) -> float:
	if height <= _NON_WIDE_COMPACT_THRESHOLD:
		return _NON_WIDE_COMPACT_FOLD
	return _NON_WIDE_FOLD


func _non_wide_font_scale() -> float:
	var compact_width := clampf(size.x / _NON_WIDE_FONT_BASE_WIDTH, _NON_WIDE_FONT_SCALE_MIN, _NON_WIDE_FONT_SCALE_MAX)
	var compact_height := clampf(size.y / _NON_WIDE_FONT_BASE_HEIGHT, _NON_WIDE_FONT_SCALE_MIN, _NON_WIDE_FONT_SCALE_MAX)
	return minf(compact_width, compact_height)


func _set_node_font_size(node: Label, base_size: int, scale: float) -> void:
	if node == null:
		return
	var scaled := maxi(1, int(round(base_size * scale)))
	node.add_theme_font_size_override("font_size", scaled)


func _apply_dossier_typography(wide: bool) -> void:
	var scale := _NON_WIDE_FONT_SCALE_MAX if wide else _non_wide_font_scale()
	var eyebrow := get_node_or_null("BrandPanel/Margin/VBox/Eyebrow") as Label
	var title := get_node_or_null("BrandPanel/Margin/VBox/Title") as Label
	var mission_brief := get_node_or_null("BrandPanel/Margin/VBox/MissionBrief") as Label
	var prompt := get_node_or_null("BrandPanel/Margin/VBox/Prompt") as Label
	var loading_bar := get_node_or_null("BrandPanel/Margin/VBox/LoadingBar") as ProgressBar
	var build_label := get_node_or_null("BrandPanel/Margin/VBox/BuildLabel") as Label

	if eyebrow != null:
		_set_node_font_size(eyebrow, _TITLE_FONT_SIZES_WIDE[&"eyebrow"], scale)
	if title != null:
		_set_node_font_size(title, _TITLE_FONT_SIZES_WIDE[&"title"], scale)
	if mission_brief != null:
		_set_node_font_size(mission_brief, _TITLE_FONT_SIZES_WIDE[&"mission_brief"], scale)
	if prompt != null:
		_set_node_font_size(prompt, _TITLE_FONT_SIZES_WIDE[&"prompt"], scale)
	if build_label != null:
		_set_node_font_size(build_label, _TITLE_FONT_SIZES_WIDE[&"build"], scale)
	if loading_bar != null:
		var bar_height := _TITLE_BAR_HEIGHT_WIDE * scale
		loading_bar.custom_minimum_size = Vector2(0.0, maxf(_TITLE_BAR_HEIGHT_COMPACT, bar_height))


func _center_dossier_layout() -> void:
	var vbox := get_node_or_null("BrandPanel/Margin/VBox") as VBoxContainer
	var brand := get_node_or_null("BrandPanel") as Control
	if vbox == null or brand == null:
		return
	var panel_available := brand.get_global_rect().size.y
	var min_content := vbox.get_combined_minimum_size().y
	vbox.alignment = 1 if panel_available > min_content + 24.0 else 0


func _reveal_after_layout() -> void:
	if _layout_frames_remaining > 0:
		_layout_frames_remaining -= 1
		get_tree().process_frame.connect(_reveal_after_layout, CONNECT_ONE_SHOT)
		return
	modulate.a = 1.0


func _exit_tree() -> void:
	if _prompt_tween != null:
		_prompt_tween.kill()
	_preloaded_menu = null
	_pipeline_prewarmer = null


# Handled in _input rather than _unhandled_input: with emulate_mouse_from_touch
# enabled, a tap on the brand panel that holds the prompt is consumed by the GUI
# before it can reach _unhandled_input, so "tap to continue" felt dead when the
# player tapped the prompt itself. _input sees the event first, everywhere.
func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event is InputEventMouseMotion or event is InputEventScreenDrag:
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
	get_viewport().set_input_as_handled()
	_accepting = true
	readiness = Readiness.TRANSITIONING
	if _prompt_tween != null: _prompt_tween.kill()
	%Prompt.modulate.a = 1.0
	%Prompt.text = "OPENING KENNEL…"
	%LoadingBar.visible = true
	%LoadingBar.value = 100.0
	%ProceduralAudio.play(ProceduralAudio.Cue.ACCEPT)
	SceneRouter.go_to(menu_scene_path)
