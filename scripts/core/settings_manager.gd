extends Node

signal setting_changed(section: StringName, key: StringName, value: Variant)
signal settings_loaded()
signal settings_saved()

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULTS := {
	"audio": {"master": 1.0, "music": 0.8, "sfx": 0.9},
	"video": {"fov": 90.0, "render_scale": "640x360", "quality": "auto", "reduced_flashes": false, "particle_density": 1.0},
	"accessibility": {"camera_shake": 1.0, "head_bob": 1.0, "gore": "cartoon", "auto_aim": "classic", "subtitles": true, "text_scale": 1.0, "high_contrast": false, "reduced_motion": false},
	"gameplay": {"run_mode": "hold", "mouse_sensitivity": 1.0, "touch_sensitivity": 1.0, "touch_horizontal_sensitivity": 1.0, "touch_vertical_sensitivity": 1.0, "touch_invert_y": false, "touch_aim_preset": "balanced", "touch_turn_boost": true, "touch_aim_friction": "standard", "touch_stick_size": "medium", "touch_stick_position": "standard", "surface_movement": "full", "horizontal_sensitivity": 1.0, "vertical_sensitivity": 1.0, "control_opacity": 0.75, "left_handed_touch": false},
}

var _config := ConfigFile.new()

func _ready() -> void:
	load_settings()

func load_settings() -> Error:
	_config = ConfigFile.new()
	var error := _config.load(SETTINGS_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		DebugLog.warn("Could not load settings", {"error": error})
	_apply_defaults()
	settings_loaded.emit()
	return OK if error == ERR_FILE_NOT_FOUND else error

func save_settings() -> Error:
	var error := _config.save(SETTINGS_PATH)
	if error == OK:
		settings_saved.emit()
	else:
		DebugLog.error("Could not save settings", {"error": error})
	return error

func get_value(section: StringName, key: StringName, fallback: Variant = null) -> Variant:
	return _config.get_value(String(section), String(key), fallback)

func set_value(section: StringName, key: StringName, value: Variant, persist: bool = true) -> Error:
	_config.set_value(String(section), String(key), value)
	setting_changed.emit(section, key, value)
	return save_settings() if persist else OK

func reset_to_defaults() -> Error:
	_config = ConfigFile.new()
	_apply_defaults()
	return save_settings()

func _apply_defaults() -> void:
	# Existing 0.5 settings stored one swipe-look speed. Preserve that preference
	# when the 0.6 twin-stick axes are introduced instead of silently resetting it.
	var legacy_touch := float(_config.get_value("gameplay", "touch_sensitivity", 1.0))
	if not _config.has_section_key("gameplay", "touch_horizontal_sensitivity"):
		_config.set_value("gameplay", "touch_horizontal_sensitivity", legacy_touch)
	if not _config.has_section_key("gameplay", "touch_vertical_sensitivity"):
		_config.set_value("gameplay", "touch_vertical_sensitivity", legacy_touch)
	for section: String in DEFAULTS:
		var values: Dictionary = DEFAULTS[section]
		for key: String in values:
			if not _config.has_section_key(section, key):
				_config.set_value(section, key, values[key])
