class_name MissionWarmupProfile
extends Resource

@export var id: StringName = &"mission_warmup"
@export var critical_paths: PackedStringArray = []


func effective_paths(scene_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not scene_path.is_empty():
		result.append(scene_path)
	for path in critical_paths:
		if not path.is_empty() and path not in result:
			result.append(path)
	return result


func validate(scene_path: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("mission warmup profile has empty id")
	var paths := effective_paths(scene_path)
	if paths.is_empty():
		errors.append("mission warmup profile %s has no critical paths" % id)
	for path in paths:
		if not ResourceLoader.exists(path):
			errors.append("mission warmup profile %s is missing %s" % [id, path])
	return errors
