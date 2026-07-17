class_name CitationConvoyActor
extends Node3D

signal module_destroyed(module_id: StringName)
signal module_staggered(module_id: StringName, multiplier: float)

const PHASE_MODULE_IDS: Array[StringName] = [
	&"citation_drive_left",
	&"citation_signal_dish",
	&"citation_drive_right",
	&"citation_core",
]

var _destroyed_modules: Dictionary = {}
var _modules_by_id: Dictionary = {}
var _phase_module_collision_layers: Dictionary = {}
var _active_phase_index := 0
var _defeat_started := false


func _ready() -> void:
	for child in get_children():
		var interaction := child as WorldInteraction
		if interaction == null or interaction.definition == null:
			continue
		var interaction_id := interaction.definition.id
		var key := String(interaction_id)
		if key == &"":
			continue
		if not _modules_by_id.has(key):
			_modules_by_id[key] = interaction
			_phase_module_collision_layers[key] = interaction.collision_layer
		interaction.interaction_completed.connect(_on_interaction_completed)
		interaction.recall_staggered.connect(_on_module_staggered)

	_set_module_enabled(&"", false)
	_active_phase_index = 0
	_apply_phase_activation()


func _on_interaction_completed(interaction_id: StringName, kind: int) -> void:
	if kind != WorldInteractionDefinition.Kind.BREAKABLE_PROP:
		return
	var key := String(interaction_id)
	if key.is_empty():
		return
	if not _modules_by_id.has(key):
		return
	if _destroyed_modules.has(key):
		return
	_destroyed_modules[key] = true
	module_destroyed.emit(interaction_id)


func _on_module_staggered(module_id: StringName, multiplier: float) -> void:
	module_staggered.emit(module_id, multiplier)


func destroyed_module_count() -> int:
	return _destroyed_modules.size()


func is_module_destroyed(module_id: StringName) -> bool:
	return _destroyed_modules.has(String(module_id))


func set_active_phase(phase_index: int) -> void:
	_active_phase_index = clampi(phase_index, 0, PHASE_MODULE_IDS.size())
	_apply_phase_activation()


func play_defeat_sequence() -> bool:
	if _defeat_started:
		return false
	_defeat_started = true
	set_active_phase(PHASE_MODULE_IDS.size())
	var tickets := get_node_or_null("TicketDebris") as CPUParticles3D
	if tickets != null:
		tickets.amount = maxi(8, roundi(28.0 * _particle_density()))
		tickets.restart()
		tickets.emitting = true
	var sparks := get_node_or_null("DefeatSparks") as CPUParticles3D
	if sparks != null and not _reduced_flashes():
		sparks.amount = maxi(6, roundi(18.0 * _particle_density()))
		sparks.restart()
		sparks.emitting = true
	if not _reduced_motion():
		var lead := get_node_or_null("LeadVehicle") as Node3D
		var left := get_node_or_null("EscortLeft") as Node3D
		var right := get_node_or_null("EscortRight") as Node3D
		var tween := create_tween().set_parallel(true)
		if lead != null:
			tween.tween_property(lead, "rotation:z", deg_to_rad(7.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(lead, "position:y", -0.16, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if left != null:
			tween.tween_property(left, "rotation:y", deg_to_rad(-11.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if right != null:
			tween.tween_property(right, "rotation:y", deg_to_rad(12.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return true


func defeat_started() -> bool:
	return _defeat_started


func _particle_density() -> float:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return 1.0
	return clampf(float(settings.get_value(&"video", &"particle_density", 1.0)), 0.25, 1.0)


func _reduced_flashes() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"video", &"reduced_flashes", false))


func _reduced_motion() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"accessibility", &"reduced_motion", false))


func _apply_phase_activation() -> void:
	for key in _modules_by_id.keys():
		var interaction := _modules_by_id[key] as WorldInteraction
		if interaction != null and is_instance_valid(interaction):
			_set_module_enabled(StringName(key), false)
	var next_required := _required_module_for_phase(_active_phase_index)
	if not next_required == &"" and _modules_by_id.has(String(next_required)):
		_set_module_enabled(next_required, true)


func _required_module_for_phase(phase_index: int) -> StringName:
	if phase_index < 0 or phase_index >= PHASE_MODULE_IDS.size():
		return &""
	return PHASE_MODULE_IDS[phase_index]


func _set_module_enabled(module_id: StringName, enabled: bool) -> void:
	if String(module_id).is_empty():
		return
	var key := String(module_id)
	if not _modules_by_id.has(key):
		return
	var interaction := _modules_by_id[key] as WorldInteraction
	if interaction == null or not is_instance_valid(interaction):
		return
	var authored_layer := int(_phase_module_collision_layers.get(key, 1))
	interaction.visible = bool(enabled)
	interaction.collision_layer = authored_layer if enabled else 0
	interaction.definition.enabled = enabled
