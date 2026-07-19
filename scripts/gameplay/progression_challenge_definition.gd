class_name ProgressionChallengeDefinition
extends Resource

@export var id: StringName = &""
@export var mission_id: StringName = &""
@export var title := ""
@export_multiline var description := ""
@export var tag_reward := 0
@export var requirements: Dictionary = {}


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not _stable(id): errors.append("challenge has invalid id")
	if not _stable(mission_id): errors.append("challenge %s has invalid mission_id" % id)
	if title.strip_edges().is_empty(): errors.append("challenge %s has no title" % id)
	if tag_reward < 0: errors.append("challenge %s has negative tag reward" % id)
	if requirements.is_empty(): errors.append("challenge %s has no requirements" % id)
	return errors


func _stable(value: StringName) -> bool:
	var text := String(value).strip_edges()
	return not text.is_empty() and text.find(" ") == -1
