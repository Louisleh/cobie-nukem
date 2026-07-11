extends Node

signal setting_changed(section: StringName, key: StringName, value: Variant)
signal settings_loaded()
signal settings_saved()

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULTS := {
	"audio": {"master": 1.0, "music": 0.8, "sfx": 0.9},
	"video": {"fov": 90.0, "render_scale": "320x180", "reduced_flashes": false},
	"accessibility": {"camera_shake": 1.0, "head_bob": 1.0, "gore": "cartoon", "auto_aim": "classic"},
	"gameplay": {"run_mode": "hold"},
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
	for section: String in DEFAULTS:
		var values: Dictionary = DEFAULTS[section]
		for key: String in values:
			if not _config.has_section_key(section, key):
				_config.set_value(section, key, values[key])

