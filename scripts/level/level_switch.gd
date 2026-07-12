class_name LevelSwitch
extends StaticBody3D

signal activated(switch_id: StringName, actor: Node)

@export var switch_id: StringName = &"switch"
@export var prompt := "USE SWITCH"
@export var one_shot := true
@export var target_path: NodePath
var is_active := false


func _ready() -> void:
	# Group membership keeps switches reachable through the proximity-interaction
	# fallback that touch players rely on when precise aiming is hard.
	add_to_group(&"interactables")
	if get_child_count() == 0: _build_visual()


func get_interaction_label() -> String:
	return "" if is_active and one_shot else prompt


func interact(actor: Node) -> void:
	if is_active and one_shot: return
	is_active = true
	var target := get_node_or_null(target_path)
	if target:
		if target.has_method("unlock"): target.unlock()
		if target.has_method("open"): target.open(actor)
	activated.emit(switch_id, actor)


func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = Vector3(0.7, 1.0, 0.25); mesh.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = Color("f0b429"); material.emission_enabled = true; material.emission = Color("7b4f00")
	mesh.material_override = material; add_child(mesh)
	var shape := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = box.size; shape.shape = box_shape; add_child(shape)
