class_name MovingSetPieceDefinition
extends Resource

enum ResetPolicy {
	NO_RESET,
	RETURN_TO_START,
	LOOP,
	PAUSE,
}

@export var id: StringName = &"moving_set_piece"
@export_file(".tscn") var actor_scene_path := ""
@export var path_points: Array[Vector3] = []
@export_range(0.05, 120.0, 0.05) var speed := 3.0
@export var stop_markers: Array[float] = []
@export var encounter_trigger_ids: Array[StringName] = []
@export var destructible_module_ids: Array[StringName] = []
@export var completion_event: StringName = &""
@export var reset_policy: ResetPolicy = ResetPolicy.LOOP


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("moving_set_piece_definition has empty id")
	if actor_scene_path.is_empty():
		errors.append("moving_set_piece_definition %s has empty actor_scene_path" % id)
	else:
		if not ResourceLoader.exists(actor_scene_path):
			errors.append("moving_set_piece_definition %s actor_scene_path missing: %s" % [id, actor_scene_path])
		else:
			var packed := load(actor_scene_path)
			if packed == null or not packed is PackedScene:
				errors.append("moving_set_piece_definition %s actor_scene_path is not a PackedScene: %s" % [id, actor_scene_path])
	if path_points.size() < 2:
		errors.append("moving_set_piece_definition %s must have at least two path points" % id)
	for point_index in range(path_points.size()):
		var point: Vector3 = path_points[point_index]
		if not point.is_finite():
			errors.append("moving_set_piece_definition %s path_points[%d] is not finite" % [id, point_index])
	if not is_finite(speed) or speed <= 0.0:
		errors.append("moving_set_piece_definition %s speed must be positive and finite" % id)
	var previous_marker_set := false
	var previous_marker := 0.0
	for marker_index in range(stop_markers.size()):
		var marker := stop_markers[marker_index]
		if not is_finite(marker) or marker < 0.0 or marker > 1.0:
			errors.append("moving_set_piece_definition %s stop_markers[%d] must be finite and within [0.0, 1.0]" % [id, marker_index])
			continue
		if previous_marker_set and marker < previous_marker:
			errors.append("moving_set_piece_definition %s stop_markers must be ordered" % id)
			break
		previous_marker_set = true
		previous_marker = marker
	if completion_event == &"":
		errors.append("moving_set_piece_definition %s missing completion_event" % id)
	for index in encounter_trigger_ids.size():
		if encounter_trigger_ids[index] == &"":
			errors.append("moving_set_piece_definition %s has empty encounter_trigger_ids[%d]" % [id, index])
	for index in destructible_module_ids.size():
		if destructible_module_ids[index] == &"":
			errors.append("moving_set_piece_definition %s has empty destructible_module_ids[%d]" % [id, index])
	var seen: Dictionary = {}
	for module_id in destructible_module_ids:
		var key := String(module_id)
		if key != "" and seen.has(key):
			errors.append("moving_set_piece_definition %s has duplicate destructible_module_id: %s" % [id, module_id])
		else:
			seen[key] = true
	return errors
