class_name PhasedModuleActor
extends Node3D

signal module_destroyed(module_id: StringName)
signal module_staggered(module_id: StringName, multiplier: float)
signal module_health_changed(module_id: StringName, current_health: float, maximum_health: float, applied_amount: float)

@export var phase_module_ids: Array[StringName] = []

var _destroyed_modules: Dictionary = {}
var _modules_by_id: Dictionary = {}
var _phase_module_collision_layers: Dictionary = {}
var _active_phase_index := 0


func configure_phase_modules(module_ids: Array[StringName]) -> bool:
	var normalized: Array[StringName] = []
	var seen: Dictionary = {}
	for module_id in module_ids:
		var key := String(module_id).strip_edges()
		if key.is_empty() or seen.has(key):
			return false
		seen[key] = true
		normalized.append(StringName(key))
	phase_module_ids = normalized
	if is_inside_tree():
		_apply_phase_activation()
	return not phase_module_ids.is_empty()


func _ready() -> void:
	for child in get_children():
		var interaction := child as WorldInteraction
		if interaction == null or interaction.definition == null:
			continue
		var interaction_id := interaction.definition.id
		var key := String(interaction_id)
		if key.is_empty():
			continue
		if not _modules_by_id.has(key):
			_modules_by_id[key] = interaction
			_phase_module_collision_layers[key] = interaction.collision_layer
		interaction.interaction_completed.connect(_on_interaction_completed)
		interaction.recall_staggered.connect(_on_module_staggered)
		interaction.health_changed.connect(_on_module_health_changed)

	_set_all_modules_enabled(false)
	_active_phase_index = 0
	_apply_phase_activation()


func _on_interaction_completed(interaction_id: StringName, kind: int) -> void:
	if kind != WorldInteractionDefinition.Kind.BREAKABLE_PROP:
		return
	var key := String(interaction_id)
	if key.is_empty() or not _modules_by_id.has(key) or _destroyed_modules.has(key):
		return
	_destroyed_modules[key] = true
	module_destroyed.emit(interaction_id)


func _on_module_staggered(module_id: StringName, multiplier: float) -> void:
	module_staggered.emit(module_id, multiplier)


func _on_module_health_changed(module_id: StringName, current_health: float, maximum_health: float, applied_amount: float) -> void:
	module_health_changed.emit(module_id, current_health, maximum_health, applied_amount)


func destroyed_module_count() -> int:
	return _destroyed_modules.size()


func is_module_destroyed(module_id: StringName) -> bool:
	return _destroyed_modules.has(String(module_id))


func phase_module_count() -> int:
	return phase_module_ids.size()


func set_active_phase(phase_index: int) -> void:
	_active_phase_index = clampi(phase_index, 0, phase_module_ids.size())
	_apply_phase_activation()


func _apply_phase_activation() -> void:
	_set_all_modules_enabled(false)
	var next_required := _required_module_for_phase(_active_phase_index)
	if next_required != &"" and _modules_by_id.has(String(next_required)):
		_set_module_enabled(next_required, true)


func _required_module_for_phase(phase_index: int) -> StringName:
	if phase_index < 0 or phase_index >= phase_module_ids.size():
		return &""
	return phase_module_ids[phase_index]


func _set_all_modules_enabled(enabled: bool) -> void:
	for key in _modules_by_id.keys():
		var interaction := _modules_by_id[key] as WorldInteraction
		if interaction != null and is_instance_valid(interaction):
			_set_module_enabled(StringName(key), enabled)


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
	interaction.visible = enabled
	interaction.collision_layer = authored_layer if enabled else 0
	interaction.definition.enabled = enabled
