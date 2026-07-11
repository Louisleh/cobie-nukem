class_name ObjectiveDefinition
extends Resource

enum Kind { REACH_ZONE, COLLECT_ITEM, ACTIVATE, DEFEAT, SURVIVE, COMPLETE_LEVEL }

@export var id: StringName = &"objective"
@export var title := "COMPLETE THE OBJECTIVE"
@export_multiline var description := ""
@export var kind: Kind = Kind.REACH_ZONE
@export var target_id: StringName = &""
@export_range(1, 999, 1) var required_count := 1
@export var prerequisite_ids: Array[StringName] = []
@export var optional := false


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("objective id is empty")
	if title.strip_edges().is_empty(): errors.append("objective %s has no title" % id)
	if target_id == &"": errors.append("objective %s has no target_id" % id)
	if id in prerequisite_ids: errors.append("objective %s depends on itself" % id)
	return errors
