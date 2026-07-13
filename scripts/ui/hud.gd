class_name GameHUD
extends CanvasLayer

@onready var health_label: Label = %HealthLabel
@onready var armor_label: Label = %ArmorLabel
@onready var ammo_label: Label = %AmmoLabel
@onready var weapon_label: Label = %WeaponLabel
@onready var interaction_label: Label = %InteractionLabel
@onready var notification_label: Label = %NotificationLabel
@onready var portrait: CobiePortrait = %CobiePortrait
@onready var crosshair: RetroCrosshair = %Crosshair
@onready var sounds: ProceduralAudio = %ProceduralAudio

var _notification_tween: Tween
var _caption_tween: Tween
var _caption_queue: Array[Dictionary] = []
var _active_caption: Dictionary = {}
var _caption_visible := false
var _base_label_font_sizes: Dictionary[NodePath, int] = {}
var _base_label_colors: Dictionary[NodePath, Color] = {}
var _caption_viewport: Viewport

enum CaptionCategory {
	NARRATIVE,
	OBJECTIVE,
	ENEMY_WARNING,
	BOSS_PHASE,
	CHECKPOINT,
	PA_CUE,
}

const CATEGORY_PRIORITY: Dictionary = {
	CaptionCategory.NARRATIVE: 0,
	CaptionCategory.PA_CUE: 1,
	CaptionCategory.OBJECTIVE: 2,
	CaptionCategory.CHECKPOINT: 3,
	CaptionCategory.ENEMY_WARNING: 4,
	CaptionCategory.BOSS_PHASE: 5,
}
const CAPTION_QUEUE_LIMIT := 4
const CAPTION_DEFAULT_SECONDS := 1.15

func _ready() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null: return
	var text_scale := clampf(float(settings.get_value(&"accessibility", &"text_scale", 1.0)), 0.75, 1.5)
	for label in $Root.find_children("*", "Label", true, false):
		var label_path: NodePath = label.get_path()
		_base_label_font_sizes[label_path] = maxi(7, roundi(label.get_theme_font_size("font_size")))
		_base_label_colors[label_path] = label.get_theme_color("font_color")
		label.add_theme_font_size_override("font_size", maxi(7, roundi(label.get_theme_font_size("font_size") * text_scale)))
	var contrast := bool(settings.get_value(&"accessibility", &"high_contrast", false))
	_apply_high_contrast(contrast)
	if settings.has_signal("setting_changed"):
		settings.setting_changed.connect(_on_setting_changed)
	_caption_viewport = get_viewport()
	if _caption_viewport != null:
		_caption_viewport.size_changed.connect(_update_caption_layout)
	_update_caption_layout()
	_apply_caption_font_settings()

func bind_player(player: Node) -> void:
	if player.has_signal("weapon_changed"):
		player.weapon_changed.connect(_on_weapon_changed)
	if player.has_signal("weapon_ammo_state_changed"):
		player.weapon_ammo_state_changed.connect(_on_weapon_ammo_state_changed)
	if player is CobiePlayer and not player.weapons.is_empty():
		var current: WeaponBase = player.weapons[player.current_weapon_index]
		_on_weapon_ammo_state_changed(current.definition.display_name, current.ammo, current.definition.magazine_size, current.reserve_ammo, current.definition.infinite_reserve)
	if player.has_signal("interaction_available"):
		player.interaction_available.connect(_on_interaction_available)
	if player.has_signal("pickup_message"):
		player.pickup_message.connect(show_notification)
	if player.has_signal("shot_resolved"):
		player.shot_resolved.connect(func(kind: StringName, _position: Vector3) -> void: crosshair.show_shot_result(kind))
	if player.has_signal("access_item_changed"):
		player.access_item_changed.connect(set_access_item)
	set_access_item("ACCESS COLLAR" if player.is_in_group(&"has_access_collar") else "NO ACCESS COLLAR")
	var health_component := player.get_node_or_null("HealthArmor")
	if health_component != null:
		health_component.health_changed.connect(_on_health_changed)
		health_component.armor_changed.connect(_on_armor_changed)
		health_component.damaged.connect(func(_a: float, _h: float, _r: float, source: Node) -> void:
			sounds.play(ProceduralAudio.Cue.HURT)
			%DamageDirection.show_damage(player, source)
		)
		_on_health_changed(health_component.health, health_component.max_health)
		_on_armor_changed(health_component.armor, health_component.max_armor)
	var aim := player.get_node_or_null("AutoAim")
	if aim != null and aim.has_signal("target_changed"):
		aim.target_changed.connect(func(target: Node3D) -> void: crosshair.target_locked = target != null)

func show_notification(message: String, cue := ProceduralAudio.Cue.PICKUP) -> void:
	notification_label.text = message
	notification_label.modulate.a = 1.0
	sounds.play(cue)
	if _notification_tween != null:
		_notification_tween.kill()
	_notification_tween = create_tween()
	_notification_tween.tween_interval(1.5)
	_notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.45)

func clear_captions() -> void:
	if _caption_tween != null:
		_caption_tween.kill()
	_caption_tween = null
	_active_caption.clear()
	_caption_queue.clear()
	_caption_visible = false
	%CaptionLabel.visible = false

func show_caption(message: String, category: int = CaptionCategory.NARRATIVE, seconds: float = CAPTION_DEFAULT_SECONDS, dedupe_key: String = "") -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and not bool(settings.get_value(&"accessibility", &"subtitles", true)):
		clear_captions()
		return
	var cleaned := message.strip_edges().to_upper()
	if cleaned.is_empty():
		return
	var chosen_category := _sanitize_category(category, cleaned)
	var payload := {
		"message": cleaned,
		"category": chosen_category,
		"priority": CATEGORY_PRIORITY[chosen_category],
		"seconds": clampf(seconds, 0.05, 3.0),
		"key": dedupe_key if not dedupe_key.is_empty() else _dedupe_key(cleaned),
	}
	if _caption_matches(payload, _active_caption):
		return
	for queued in _caption_queue:
		if _caption_matches(payload, queued):
			return
	if _caption_visible and payload["priority"] > get_active_caption_priority():
		_queue_caption(_active_caption)
		_active_caption = {}
		_caption_visible = false
		_display_caption_payload(payload)
		return
	_queue_caption(payload)
	_display_next_caption()

func show_objective_caption(message: String, seconds: float = CAPTION_DEFAULT_SECONDS) -> void:
	show_caption(message, CaptionCategory.OBJECTIVE, seconds)

func show_enemy_warning_caption(message: String, seconds: float = CAPTION_DEFAULT_SECONDS) -> void:
	show_caption(message, CaptionCategory.ENEMY_WARNING, seconds)

func show_boss_phase_caption(message: String, seconds: float = CAPTION_DEFAULT_SECONDS) -> void:
	show_caption(message, CaptionCategory.BOSS_PHASE, seconds)

func show_checkpoint_caption(message: String, seconds: float = CAPTION_DEFAULT_SECONDS) -> void:
	show_caption(message, CaptionCategory.CHECKPOINT, seconds)

func show_pa_cue_caption(message: String, seconds: float = CAPTION_DEFAULT_SECONDS) -> void:
	show_caption(message, CaptionCategory.PA_CUE, seconds)

func show_secret(message := "SECRET FOUND. GOOD SNIFFING.") -> void:
	show_notification(message, ProceduralAudio.Cue.SECRET)

func show_objective(message: String) -> void:
	%ObjectiveLabel.text = "OBJECTIVE // " + message.to_upper()
	%ObjectiveLabel.visible = not message.is_empty()

func _sanitize_category(category: int, message: String) -> int:
	var normalized := category
	if normalized < 0 or normalized > int(CaptionCategory.PA_CUE):
		normalized = CaptionCategory.NARRATIVE
	if normalized == CaptionCategory.NARRATIVE:
		var check := message.to_lower()
		if check.contains("warning"):
			normalized = CaptionCategory.ENEMY_WARNING
		elif check.contains("checkpoint"):
			normalized = CaptionCategory.CHECKPOINT
		elif check.contains("boss") or check.contains("phase"):
			normalized = CaptionCategory.BOSS_PHASE
		elif check.begins_with("pa ") or check.begins_with("PA "):
			normalized = CaptionCategory.PA_CUE
	return normalized

func _dedupe_key(message: String) -> String:
	return "caption:%s" % [message.to_lower()]

func _caption_matches(payload: Dictionary, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	return target["key"] == payload["key"] or target["message"] == payload["message"]

func _queue_caption(payload: Dictionary) -> void:
	var insertion_index := _caption_queue.size()
	for index in range(_caption_queue.size()):
		if _caption_queue[index]["priority"] < payload["priority"]:
			insertion_index = index
			break
	_caption_queue.insert(insertion_index, payload)
	if _caption_queue.size() > CAPTION_QUEUE_LIMIT:
		_caption_queue.resize(CAPTION_QUEUE_LIMIT)

func _display_next_caption() -> void:
	if _caption_visible:
		return
	if _caption_queue.is_empty():
		return
	var next: Dictionary = _caption_queue.pop_front()
	_display_caption_payload(next)

func _display_caption_payload(next: Dictionary) -> void:
	_active_caption = next
	_caption_visible = true
	%CaptionLabel.text = "[ " + next["message"] + " ]"
	%CaptionLabel.visible = true
	if _caption_tween != null:
		_caption_tween.kill()
	_caption_tween = create_tween()
	_caption_tween.tween_interval(float(next.get("seconds", CAPTION_DEFAULT_SECONDS)))
	_caption_tween.tween_callback(func() -> void:
		_caption_visible = false
		%CaptionLabel.visible = false
		_active_caption = {}
		_display_next_caption()
	)

func _apply_caption_font_settings() -> void:
	var caption := %CaptionLabel
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD
	caption.clip_text = true
	_update_caption_layout()

func _apply_high_contrast(enabled: bool) -> void:
	for label in $Root.find_children("*", "Label", true, false):
		var path: NodePath = label.get_path()
		var base_color: Color = _base_label_colors.get(path, Color.WHITE)
		label.add_theme_color_override("font_color", Color.WHITE if enabled else base_color)
	if enabled:
		notification_label.add_theme_color_override("font_color", Color("ffff00"))
	%CaptionLabel.add_theme_color_override("font_outline_color", Color.BLACK)
	crosshair.high_contrast = enabled

func _apply_caption_layout() -> void:
	var caption := %CaptionLabel
	var viewport_size := _caption_viewport.get_visible_rect().size if _caption_viewport != null else get_viewport().get_visible_rect().size
	var viewport_width := maxf(320.0, viewport_size.x)
	var viewport_height := maxf(360.0, viewport_size.y)
	var target_width := clampf(viewport_width * 0.86, 240.0, 900.0)
	var left_margin := maxf(12.0, (viewport_width - target_width) * 0.5)
	caption.anchor_left = 0.0
	caption.anchor_top = 1.0
	caption.anchor_right = 0.0
	caption.anchor_bottom = 1.0
	caption.offset_left = left_margin
	caption.offset_right = left_margin + target_width
	caption.offset_top = -maxf(96.0, roundf(viewport_height * 0.072))
	caption.offset_bottom = caption.offset_top + 36.0

func _update_caption_layout() -> void:
	_apply_caption_layout()

func set_access_item(label: String) -> void:
	%AccessLabel.text = label

func _on_health_changed(current: float, maximum: float) -> void:
	health_label.text = "%03d" % int(ceil(current))
	portrait.health_ratio = current / maxf(maximum, 1.0)

func _on_armor_changed(current: float, _maximum: float) -> void:
	armor_label.text = "%03d" % int(ceil(current))

func _on_weapon_changed(display_name: String, ammo: int, maximum_ammo: int) -> void:
	weapon_label.text = display_name.to_upper()
	ammo_label.text = "∞" if maximum_ammo <= 0 else "%02d" % ammo

func _on_weapon_ammo_state_changed(display_name: String, loaded: int, _capacity: int, reserve: int, infinite_reserve: bool) -> void:
	weapon_label.text = display_name.to_upper()
	ammo_label.text = "%02d / %s" % [loaded, "∞" if infinite_reserve else "%02d" % reserve]

func _on_interaction_available(label: String) -> void:
	interaction_label.visible = not label.is_empty()
	interaction_label.text = "[E] %s" % label.to_upper()

func get_caption_queue_size() -> int:
	return _caption_queue.size()

func get_caption_text() -> String:
	return %CaptionLabel.text

func is_caption_visible() -> bool:
	return %CaptionLabel.visible

func get_active_caption_priority() -> int:
	return _active_caption.get("priority", -1)

func _on_setting_changed(section: StringName, key: StringName, value: Variant) -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	match section:
		&"accessibility":
			match key:
				&"text_scale":
					var text_scale = clampf(float(value), 0.75, 1.5)
					for label in $Root.find_children("*", "Label", true, false):
						var base_size = int(_base_label_font_sizes.get(label.get_path(), label.get_theme_font_size("font_size")))
						label.add_theme_font_size_override("font_size", maxi(7, roundi(base_size * text_scale)))
				&"high_contrast":
					_apply_high_contrast(bool(value))
				&"subtitles":
					if not bool(value):
						clear_captions()
				_:
					pass
		_:
			pass

func _exit_tree() -> void:
	if _caption_viewport != null and _caption_viewport.size_changed.is_connected(_update_caption_layout):
		_caption_viewport.size_changed.disconnect(_update_caption_layout)
