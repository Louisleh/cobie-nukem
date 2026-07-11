extends Node

const MANAGED_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX"]

func _ready() -> void:
	SettingsManager.setting_changed.connect(_on_setting_changed)
	apply_saved_levels()

func apply_saved_levels() -> void:
	set_bus_linear(&"Master", float(SettingsManager.get_value(&"audio", &"master", 1.0)))
	set_bus_linear(&"Music", float(SettingsManager.get_value(&"audio", &"music", 0.8)))
	set_bus_linear(&"SFX", float(SettingsManager.get_value(&"audio", &"sfx", 0.9)))

func set_bus_linear(bus_name: StringName, linear: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		DebugLog.warn("Audio bus is not configured", {"bus": String(bus_name)})
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(linear, 0.0001, 1.0)))
	AudioServer.set_bus_mute(bus_index, linear <= 0.0)

func _on_setting_changed(section: StringName, key: StringName, value: Variant) -> void:
	if section != &"audio":
		return
	var bus_name := StringName(String(key).capitalize())
	if bus_name in MANAGED_BUSES:
		set_bus_linear(bus_name, float(value))

