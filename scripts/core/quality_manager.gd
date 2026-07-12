extends Node

signal profile_changed(profile: QualityProfile)

const WEB := preload("res://resources/quality/web_ipad.tres")
const NATIVE := preload("res://resources/quality/native_enhanced.tres")

var current: QualityProfile

func _ready() -> void:
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
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null: pressure.maximum_attackers = profile.maximum_attackers
	profile_changed.emit(profile)
