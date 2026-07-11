class_name LevelCheckpoint
extends Area3D

signal activated(checkpoint_id: StringName, respawn_position: Vector3)

@export var checkpoint_id: StringName = &"checkpoint"
@export var respawn_offset := Vector3(0, 1, 1)
var used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if get_child_count() == 0:
		var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(8, 3, 2); shape.shape = box; add_child(shape)


func _on_body_entered(body: Node) -> void:
	if used or not body.is_in_group(&"player"): return
	used = true
	activated.emit(checkpoint_id, global_position + respawn_offset)
