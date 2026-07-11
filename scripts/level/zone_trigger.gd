class_name LevelZoneTrigger
extends Area3D

signal entered(zone_id: StringName, title: String, actor: Node)

@export var zone_id: StringName = &"zone"
@export var title := "ZONE"
@export var trigger_size := Vector3(14, 4, 3)
@export var one_shot := true
var triggered := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player physics layer.
	monitoring = true
	body_entered.connect(_on_body_entered)
	if get_child_count() == 0:
		var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = trigger_size; shape.shape = box; add_child(shape)


func _physics_process(_delta: float) -> void:
	# Recover initial overlaps and body-enter events skipped during a busy frame.
	if triggered and one_shot:
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		if triggered and one_shot:
			return


func _on_body_entered(body: Node) -> void:
	if (triggered and one_shot) or not body.is_in_group(&"player"): return
	triggered = true
	entered.emit(zone_id, title, body)
