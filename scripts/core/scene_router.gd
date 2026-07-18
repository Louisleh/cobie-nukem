extends Node

signal transition_started(scene_path: String)
signal transition_finished(scene_path: String)
signal transition_failed(scene_path: String, error: Error)

var current_scene_path := ""
var is_transitioning := false

func go_to(scene_path: String) -> Error:
	if is_transitioning:
		return ERR_BUSY
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		transition_failed.emit(scene_path, ERR_FILE_NOT_FOUND)
		return ERR_FILE_NOT_FOUND
	is_transitioning = true
	_release_transition_input()
	transition_started.emit(scene_path)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		is_transitioning = false
		transition_failed.emit(scene_path, error)
		return error
	current_scene_path = scene_path
	_finish_when_ready.call_deferred(scene_path)
	return OK

func reload_current() -> Error:
	if is_transitioning:
		return ERR_BUSY
	var scene := get_tree().current_scene
	var path := scene.scene_file_path if scene != null else current_scene_path
	if path.is_empty():
		return ERR_DOES_NOT_EXIST
	return go_to(path)


func _finish_when_ready(scene_path: String) -> void:
	# change_scene_to_file() only schedules the replacement. Publishing completion
	# in the same call frame let menus re-enable input while the old scene was
	# still tearing down and the destination had not reached _ready().
	await get_tree().process_frame
	var destination := get_tree().current_scene
	if destination == null:
		is_transitioning = false
		transition_failed.emit(scene_path, ERR_CANT_CREATE)
		return
	if not destination.is_node_ready():
		await destination.ready
	is_transitioning = false
	transition_finished.emit(scene_path)


func _release_transition_input() -> void:
	get_tree().call_group(&"mobile_controls", &"release_all")
	for action in [
		&"move_forward", &"move_backward", &"strafe_left", &"strafe_right",
		&"look_left", &"look_right", &"look_up", &"look_down",
		&"fire_primary", &"fire_secondary", &"use", &"jump", &"run",
		&"weapon_next", &"weapon_previous", &"reload", &"pause",
		&"menu_accept", &"menu_back",
	]:
		Input.action_release(action)
