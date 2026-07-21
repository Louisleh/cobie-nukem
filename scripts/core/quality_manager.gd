extends Node

signal profile_changed(profile: QualityProfile)

const WEB := preload("res://resources/quality/web_ipad.tres")
const NATIVE := preload("res://resources/quality/native_enhanced.tres")

var current: QualityProfile
var _temporary_effects: Array[Node] = []

func _ready() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_signal("setting_changed"):
		settings.setting_changed.connect(_on_setting_changed)
	apply_auto_profile()

func apply_auto_profile() -> void:
	var setting := "auto"
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null: setting = String(settings.get_value(&"video", &"quality", "auto"))
	if setting == "web": apply_profile(WEB)
	elif setting == "native": apply_profile(NATIVE)
	else: apply_profile(WEB if OS.has_feature("web") or OS.has_feature("mobile") else NATIVE)

func apply_profile(profile: QualityProfile) -> void:
	current = profile
	Engine.max_fps = profile.target_fps
	var viewport := get_viewport()
	if viewport != null: viewport.scaling_3d_scale = profile.render_scale
	var pressure := get_parent().get_node_or_null("CombatPressure") if get_parent() != null else null
	if pressure != null: pressure.configure_limit(profile.maximum_attackers)
	profile_changed.emit(profile)


func _on_setting_changed(section: StringName, key: StringName, _value: Variant) -> void:
	if section != &"video" or key != &"quality":
		return
	apply_auto_profile()


func claim_temporary_effect(effect: Node) -> void:
	if not is_instance_valid(effect): return
	_prune_effects()
	var budget := current.decal_budget if current != null else 48
	while _temporary_effects.size() >= budget and not _temporary_effects.is_empty():
		var oldest: Node = _temporary_effects.pop_front()
		if is_instance_valid(oldest): oldest.queue_free()
	_temporary_effects.append(effect)
	effect.tree_exiting.connect(func() -> void: _temporary_effects.erase(effect), CONNECT_ONE_SHOT)


func temporary_effect_count() -> int:
	_prune_effects()
	return _temporary_effects.size()


func _prune_effects() -> void:
	for effect in _temporary_effects.duplicate():
		if not is_instance_valid(effect): _temporary_effects.erase(effect)
