class_name LevelZoneTrigger
extends Area3D

signal entered(zone_id: StringName, title: String, actor: Node)

@export var zone_id: StringName = &"zone"
@export var title := "ZONE"
@export var trigger_size := Vector3(14, 4, 3)
@export var one_shot := true
var triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if get_child_count() == 0:
		var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = trigger_size; shape.shape = box; add_child(shape)


func _on_body_entered(body: Node) -> void:
	if (triggered and one_shot) or not body.is_in_group(&"player"): return
	triggered = true
	entered.emit(zone_id, title, body)
