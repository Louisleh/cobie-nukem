class_name RuntimePipelinePrewarmer
extends Node

signal completed

var _viewport: SubViewport
var _frames_remaining := 0


func warm(scene_paths: PackedStringArray) -> void:
	_viewport = SubViewport.new()
	_viewport.name = "PipelineWarmupViewport"
	_viewport.size = Vector2i(64, 64)
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var camera := Camera3D.new()
	camera.current = true
	_viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	_viewport.add_child(light)
	var column := 0
	for path in scene_paths:
		var packed := load(path) as PackedScene if ResourceLoader.exists(path, "PackedScene") else null
		if packed == null:
			continue
		var instance := packed.instantiate() as Node3D
		if instance == null:
			continue
		instance.process_mode = Node.PROCESS_MODE_DISABLED
		if instance is CollisionObject3D:
			instance.collision_layer = 0
			instance.collision_mask = 0
		_viewport.add_child(instance)
		instance.position = Vector3(float(column) * 0.45 - 0.25, 0.0, -2.0)
		# Telegraphs, health bars, and fallback geometry are intentionally hidden
		# during ordinary idle presentation. Rendering them here compiles those
		# material variants while the title still says WARMING, not on first fire.
		for visual in instance.find_children("*", "GeometryInstance3D", true, false):
			visual.visible = true
		column += 1
	_frames_remaining = 3
	set_process(true)


func _process(_delta: float) -> void:
	_frames_remaining -= 1
	if _frames_remaining > 0:
		return
	set_process(false)
	if _viewport != null:
		_viewport.queue_free()
		_viewport = null
	completed.emit()
