class_name CitationConvoyActor
extends Node3D

signal module_destroyed(module_id: StringName)
signal module_staggered(module_id: StringName, multiplier: float)

var _destroyed_modules: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		var interaction := child as WorldInteraction
		if interaction == null or interaction.definition == null:
			continue
		interaction.interaction_completed.connect(_on_interaction_completed)
		interaction.recall_staggered.connect(_on_module_staggered)


func _on_interaction_completed(interaction_id: StringName, kind: int) -> void:
	if kind != WorldInteractionDefinition.Kind.BREAKABLE_PROP:
		return
	if _destroyed_modules.has(interaction_id):
		return
	_destroyed_modules[interaction_id] = true
	module_destroyed.emit(interaction_id)


func destroyed_module_count() -> int:
	return _destroyed_modules.size()


func _on_module_staggered(module_id: StringName, multiplier: float) -> void:
	module_staggered.emit(module_id, multiplier)
