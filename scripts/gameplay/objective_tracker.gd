class_name ObjectiveTracker
extends Node

signal objective_activated(definition: ObjectiveDefinition)
signal objective_progressed(definition: ObjectiveDefinition, current: int, required: int)
signal objective_completed(definition: ObjectiveDefinition)
signal all_required_completed()

var definitions: Array[ObjectiveDefinition] = []
var progress: Dictionary = {}
var completed: Dictionary = {}
var activated: Dictionary = {}


func configure(values: Array[ObjectiveDefinition]) -> void:
	definitions = values.duplicate()
	progress.clear()
	completed.clear()
	activated.clear()
	_emit_available()


func record(kind: ObjectiveDefinition.Kind, target_id: StringName, amount := 1) -> Array[StringName]:
	var newly_completed: Array[StringName] = []
	for definition in definitions:
		if completed.has(definition.id) or definition.kind != kind or definition.target_id != target_id:
			continue
		if not _prerequisites_met(definition):
			continue
		var value := mini(definition.required_count, int(progress.get(definition.id, 0)) + maxi(amount, 0))
		progress[definition.id] = value
		objective_progressed.emit(definition, value, definition.required_count)
		if value >= definition.required_count:
			completed[definition.id] = true
			newly_completed.append(definition.id)
			objective_completed.emit(definition)
	_emit_available()
	if is_complete(): all_required_completed.emit()
	return newly_completed


func active_objectives() -> Array[ObjectiveDefinition]:
	var result: Array[ObjectiveDefinition] = []
	for definition in definitions:
		if not completed.has(definition.id) and _prerequisites_met(definition): result.append(definition)
	return result


func is_complete() -> bool:
	for definition in definitions:
		if not definition.optional and not completed.has(definition.id): return false
	return not definitions.is_empty()


func snapshot() -> Dictionary:
	var serialized_progress := {}
	for id in progress: serialized_progress[String(id)] = int(progress[id])
	var serialized_completed: Array[String] = []
	for id in completed: serialized_completed.append(String(id))
	return {"progress": serialized_progress, "completed": serialized_completed}


func restore(data: Dictionary) -> void:
	progress.clear()
	var restored_progress: Dictionary = data.get("progress", {})
	for id in restored_progress: progress[StringName(id)] = int(restored_progress[id])
	completed.clear()
	activated.clear()
	for id in data.get("completed", []): completed[StringName(id)] = true
	_emit_available()


func _prerequisites_met(definition: ObjectiveDefinition) -> bool:
	for prerequisite in definition.prerequisite_ids:
		if not completed.has(prerequisite): return false
	return true


func _emit_available() -> void:
	for definition in active_objectives():
		if activated.has(definition.id): continue
		activated[definition.id] = true
		objective_activated.emit(definition)
