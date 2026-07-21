extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player/cobie_player.tscn")

var failures: Array[String] = []
var _settings: Node
var _quality: Node
var _combat_pressure: Node
var _settings_snapshot: Dictionary = {}
var _settings_backup_text: String = ""
var _had_settings_file: bool = false
var _settings_backup_valid: bool = false
var _original_fps: int = 60
var _original_scale: float = 1.0
var _original_pressure_limit: int = -1
var _player: CobiePlayer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_settings = root.get_node_or_null("/root/SettingsManager")
	_quality = root.get_node_or_null("QualityManager")
	_combat_pressure = root.get_node_or_null("CombatPressure")
	if _settings == null or _quality == null:
		failures.append("SettingsManager and QualityManager autoloads are required")
		_restore_state()
		_finish()
		return

	_capture_state()
	_player = PLAYER_SCENE.instantiate() as CobiePlayer
	root.add_child(_player)
	_override_settings()
	_expect(is_equal_approx(_player.camera.fov, 87.5), "player receives non-default FOV before reset")
	_expect(_player.feedback.reduced_flashes, "tactile feedback receives non-default flash setting before reset")

	var setting_events: Array[Dictionary] = []
	_settings.setting_changed.connect(func(section: StringName, key: StringName, value: Variant) -> void:
		_record_setting_changed(setting_events, section, key, value)
	)
	var profile_events: Array[QualityProfile] = []
	if _quality.has_signal("profile_changed"):
		_quality.profile_changed.connect(func(profile: QualityProfile) -> void:
			_record_quality_profile_changed(profile_events, profile)
		)

	var error: Error = _settings.reset_to_defaults()
	if error != OK:
		failures.append("settings reset returns an error: %d" % error)

	_validate_reset_notifications(setting_events)
	_validate_runtime_reapply()
	_validate_player_runtime_reapply()
	_validate_single_quality_reapply(profile_events)

	_restore_state()
	_finish()


func _capture_state() -> void:
	_original_fps = Engine.max_fps
	var original_viewport := root as Viewport
	_original_scale = original_viewport.scaling_3d_scale if original_viewport != null else 1.0
	_settings_snapshot = _snapshot_settings()
	_original_pressure_limit = -1
	if _combat_pressure != null and _combat_pressure.has_method("configure_limit"):
		_original_pressure_limit = int(_combat_pressure.maximum_attackers)
	var settings_path := String(_settings.SETTINGS_PATH)
	_had_settings_file = FileAccess.file_exists(settings_path)
	if not _had_settings_file:
		return
	var settings_file := FileAccess.open(settings_path, FileAccess.READ)
	if settings_file == null:
		return
	_settings_backup_text = settings_file.get_as_text()
	settings_file.close()
	_settings_backup_valid = true


func _restore_state() -> void:
	if is_instance_valid(_player):
		_player.free()
	Engine.max_fps = _original_fps
	var viewport := root as Viewport
	if viewport != null:
		viewport.scaling_3d_scale = _original_scale
	if _combat_pressure != null and _combat_pressure.has_method("configure_limit") and _original_pressure_limit >= 0:
		_combat_pressure.configure_limit(_original_pressure_limit)

	if _settings == null:
		return
	var settings_path := String(_settings.SETTINGS_PATH)
	if _settings_backup_valid:
		var settings_file := FileAccess.open(settings_path, FileAccess.WRITE)
		if settings_file != null:
			settings_file.store_string(_settings_backup_text)
			settings_file.close()
			return
	if _had_settings_file:
		# Fallback restore for the canonical contract surface if file read was not
		# possible. This keeps the test from leaving canonical settings values
		# changed when file IO is unavailable in the sandbox.
		for section in _settings_snapshot.keys():
			for key: StringName in _settings_snapshot[section].keys():
				_settings.set_value(section, key, _settings_snapshot[section][key], false)
		if _settings.has_method("save_settings"):
			_settings.save_settings()
	elif FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))


func _snapshot_settings() -> Dictionary:
	var snapshot: Dictionary = {}
	for section: String in _settings.DEFAULTS:
		var section_values: Dictionary = {}
		for key: String in _settings.DEFAULTS[section]:
			section_values[StringName(key)] = _settings.get_value(StringName(section), StringName(key), null)
		snapshot[StringName(section)] = section_values
	return snapshot


func _override_settings() -> void:
	var overrides: Dictionary = {
		"audio": {
			"master": 0.3,
			"music": 0.2,
			"sfx": 0.4,
		},
		"video": {
			"fov": 87.5,
			"render_scale": "1024x768",
			"quality": "native",
			"reduced_flashes": true,
			"particle_density": 0.25,
		},
		"accessibility": {
			"camera_shake": 0.35,
			"head_bob": 0.45,
			"gore": "retro",
			"auto_aim": "heavy",
			"subtitles": false,
			"text_scale": 0.55,
			"high_contrast": true,
			"reduced_motion": true,
		},
		"gameplay": {
			"run_mode": "toggle",
			"mouse_sensitivity": 1.4,
			"touch_sensitivity": 0.8,
			"touch_horizontal_sensitivity": 0.7,
			"touch_vertical_sensitivity": 0.7,
			"touch_invert_y": true,
			"touch_aim_preset": "fast",
			"touch_turn_boost": false,
			"touch_aim_friction": "off",
			"touch_stick_size": "large",
			"touch_stick_position": "compact",
			"surface_movement": "reduced",
			"horizontal_sensitivity": 0.95,
			"vertical_sensitivity": 0.9,
			"control_opacity": 0.6,
			"left_handed_touch": true,
		},
	}
	for section in overrides.keys():
		for key in overrides[section]:
			_settings.set_value(StringName(section), StringName(key), overrides[section][key])


func _record_setting_changed(events: Array[Dictionary], section: StringName, key: StringName, value: Variant) -> void:
	events.append({"section": section, "key": key, "value": value})


func _record_quality_profile_changed(events: Array[QualityProfile], profile: QualityProfile) -> void:
	events.append(profile)


func _validate_reset_notifications(events: Array[Dictionary]) -> void:
	var expected := _expected_setting_events()
	_expect(events.size() == expected.size(), "reset emits setting_changed once per canonical setting")
	for index in expected.size():
		if index >= events.size():
			return
		var actual := events[index]
		var required := expected[index]
		_expect(actual.get("section") == required["section"], "reset notification section[%d] is %s" % [index, required["section"]])
		_expect(actual.get("key") == required["key"], "reset notification key[%d] is %s" % [index, required["key"]])
		_expect(_values_match(actual.get("value"), required["value"]), "reset notification value[%s.%s] uses canonical default" % [required["section"], required["key"]])


func _expected_setting_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for section: String in _settings.DEFAULTS:
		var values: Dictionary = _settings.DEFAULTS[section]
		for key: String in values:
			result.append({"section": StringName(section), "key": StringName(key), "value": values[key]})
	return result


func _validate_runtime_reapply() -> void:
	var expected_profile := _expected_quality_profile()
	if expected_profile == null:
		failures.append("cannot determine expected quality profile")
		return
	_expect(is_instance_valid(_quality.current), "quality manager keeps a current runtime profile")
	if not is_instance_valid(_quality.current):
		return
	_expect(_quality.current.id == expected_profile.id, "quality manager reselects the expected profile after reset")
	_expect(_quality.current.target_fps == expected_profile.target_fps, "reset reapplies quality target FPS")
	_expect(int(Engine.max_fps) == expected_profile.target_fps, "reset reapplies Engine.max_fps")
	var viewport := _quality.get_viewport()
	if viewport == null:
		failures.append("QualityManager has no viewport for render_scale contract")
		return
	_expect(is_equal_approx(viewport.scaling_3d_scale, expected_profile.render_scale), "reset reapplies quality render scale")
	if _combat_pressure != null:
		_expect(int(_combat_pressure.maximum_attackers) == expected_profile.maximum_attackers, "reset reapplies combat pressure limit")


func _validate_single_quality_reapply(profile_events: Array[QualityProfile]) -> void:
	_expect(profile_events.size() == 1, "quality profile changes once during reset")


func _validate_player_runtime_reapply() -> void:
	if not is_instance_valid(_player):
		failures.append("real player fixture is unavailable after reset")
		return
	var gameplay: Dictionary = _settings.DEFAULTS["gameplay"]
	var video: Dictionary = _settings.DEFAULTS["video"]
	var accessibility: Dictionary = _settings.DEFAULTS["accessibility"]
	var expected_mouse := _player._base_mouse_sensitivity * float(gameplay["mouse_sensitivity"])
	var expected_bob := _player._base_head_bob_amount * float(accessibility["head_bob"])
	if bool(accessibility["reduced_motion"]):
		expected_bob = 0.0
	var expected_shake := _player.feedback._base_shake_scale * float(accessibility["camera_shake"])
	if bool(accessibility["reduced_motion"]):
		expected_shake = 0.0
	_expect(is_equal_approx(_player.mouse_sensitivity, expected_mouse), "reset reapplies player mouse sensitivity immediately")
	_expect(is_equal_approx(_player.camera.fov, float(video["fov"])), "reset reapplies player FOV immediately")
	_expect(is_equal_approx(_player.head_bob_amount, expected_bob), "reset reapplies player head bob immediately")
	_expect(is_equal_approx(_player.feedback.shake_scale, expected_shake), "reset reapplies tactile shake immediately")
	_expect(_player.feedback.reduced_flashes == bool(video["reduced_flashes"]), "reset reapplies reduced flashes immediately")


func _expected_quality_profile() -> QualityProfile:
	if _quality == null:
		return null
	var setting_value := String(_settings.get_value(&"video", &"quality", "auto")).to_lower()
	if setting_value == "web":
		return _quality.WEB
	if setting_value == "native":
		return _quality.NATIVE
	return _quality.WEB if (OS.has_feature("web") or OS.has_feature("mobile")) else _quality.NATIVE


func _values_match(a: Variant, b: Variant) -> bool:
	if a is float and b is float:
		return is_equal_approx(a, b)
	return a == b


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _finish() -> void:
	if failures.is_empty():
		print("PASS: settings reset runtime contract")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
