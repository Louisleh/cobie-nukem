class_name LevelDoor
extends StaticBody3D

signal opened(door: LevelDoor, actor: Node)
signal access_denied(message: String)

@export var interaction_label := "OPEN"
@export var locked_message := "ACCESS DENIED. COLLAR REQUIRED."
@export var requires_access_collar := false
@export var starts_locked := false
@export var open_height := 4.5
@export var open_seconds := 0.65
@export var size := Vector3(5.0, 4.0, 0.6)
@export var color := Color("b58b32")

var is_open := false
var is_locked := false
var _closed_position: Vector3


func _ready() -> void:
	is_locked = starts_locked
	_closed_position = position
	if get_child_count() == 0: _build_visual()


func get_interaction_label() -> String:
	if is_open: return ""
	if is_locked: return "LOCKED — FIND A SWITCH"
	if requires_access_collar: return "SCAN ACCESS COLLAR"
	return interaction_label


func interact(actor: Node) -> void:
	if is_open: return
	if is_locked:
		access_denied.emit(locked_message)
		return
	if requires_access_collar and not actor.is_in_group(&"has_access_collar"):
		access_denied.emit(locked_message)
		return
	open(actor)


func unlock() -> void:
	is_locked = false


func open(actor: Node = null) -> void:
	if is_open: return
	is_open = true
	set_collision_layer_value(1, false)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", _closed_position + Vector3.UP * open_height, open_seconds)
	opened.emit(self, actor)


func reset_door() -> void:
	is_open = false
	position = _closed_position
	set_collision_layer_value(1, true)


func _build_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = size; mesh.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.metallic = 0.35; material.roughness = 0.7
	mesh.material_override = material
	add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new(); box_shape.size = size; shape.shape = box_shape
	add_child(shape)
