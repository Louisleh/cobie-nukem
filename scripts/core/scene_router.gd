extends Node

signal transition_started(scene_path: String)
signal transition_finished(scene_path: String)
signal transition_failed(scene_path: String, error: Error)

var current_scene_path := ""

func go_to(scene_path: String) -> Error:
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		transition_failed.emit(scene_path, ERR_FILE_NOT_FOUND)
		return ERR_FILE_NOT_FOUND
	transition_started.emit(scene_path)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		transition_failed.emit(scene_path, error)
		return error
	current_scene_path = scene_path
	transition_finished.emit(scene_path)
	return OK

func reload_current() -> Error:
	return get_tree().reload_current_scene()

