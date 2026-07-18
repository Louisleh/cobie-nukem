class_name MountHoodChairlift
extends AnimatableBody3D

signal ride_started
signal ride_completed

@export var start_position := Vector3.ZERO
@export var end_position := Vector3(0.0, 9.0, -28.0)
@export_range(1.0, 12.0, 0.1) var speed := 4.0

var enabled := false
var riding := false
var _rider: Node3D
var _rider_offset := Vector3(0.0, 0.55, 0.0)


func _ready() -> void:
	sync_to_physics = true
	add_to_group(&"interactables")
	start_position = position
	_build_if_empty()


func get_interaction_label() -> String:
	if not enabled: return "CHAIRLIFT OFFLINE"
	return "RIDE CHAIRLIFT" if not riding else ""


func interact(actor: Node) -> void:
	if not enabled or riding: return
	_rider = actor as Node3D
	if is_instance_valid(_rider):
		if _rider.has_method("begin_external_transport"):
			_rider.call("begin_external_transport")
		_place_rider()
	riding = true
	ride_started.emit()


func set_enabled(value: bool) -> void:
	enabled = value


func reset_lift() -> void:
	_release_rider(global_position + Vector3(0.0, 0.6, 1.8))
	riding = false
	# AnimatableBody3D buffers authored movement when sync_to_physics is enabled.
	# Toggle it only for an authoritative reset so retry/checkpoint restore cannot
	# leave the collision body at its prior ride position for another frame.
	var was_synced := sync_to_physics
	sync_to_physics = false
	position = start_position
	sync_to_physics = was_synced
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if not riding: return
	position = position.move_toward(end_position, speed * delta)
	_place_rider()
	if position.distance_to(end_position) <= 0.02:
		riding = false
		_release_rider(global_position + Vector3(0.0, 0.6, -1.8))
		ride_completed.emit()


func _place_rider() -> void:
	if not is_instance_valid(_rider):
		_rider = null
		return
	# The lift does not rotate, so using the freshly updated local position avoids
	# waiting a frame for a manually-driven test/runtime transform propagation.
	_rider.global_position = get_parent_node_3d().to_global(position + _rider_offset)
	if _rider is CharacterBody3D:
		(_rider as CharacterBody3D).velocity = Vector3.ZERO


func _release_rider(at: Vector3) -> void:
	if not is_instance_valid(_rider):
		_rider = null
		return
	var rider := _rider
	_rider = null
	rider.global_position = at
	if rider.has_method("end_external_transport"):
		rider.call("end_external_transport")
	elif rider is CharacterBody3D:
		(rider as CharacterBody3D).reset_physics_interpolation()


func _build_if_empty() -> void:
	if get_child_count() > 0: return
	var mesh_instance := MeshInstance3D.new()
	var seat := BoxMesh.new(); seat.size = Vector3(2.2, 0.22, 1.2); mesh_instance.mesh = seat
	var material := StandardMaterial3D.new(); material.albedo_color = Color("d14934"); material.metallic = 0.4
	mesh_instance.material_override = material; add_child(mesh_instance)
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(2.2, 0.22, 1.2); shape.shape = box; add_child(shape)
