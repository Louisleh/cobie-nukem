class_name BallReturnSecret
extends Area3D

signal secret_requested(secret_id: StringName, title: String)

@export var secret_id: StringName = &"ball_return"
@export var secret_title := "AUTHORIZED FETCHING"
var activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if get_child_count() == 0: _build_visual()


func get_interaction_label() -> String:
	return "BALL RETURN — PROJECTILES ONLY"


func interact(_actor: Node) -> void:
	# Explains the puzzle without allowing the use key to bypass it.
	pass


func _on_body_entered(body: Node) -> void:
	if activated: return
	if body is FetchProjectile or body.is_in_group(&"fetch_projectiles"):
		activated = true
		secret_requested.emit(secret_id, secret_title)


func _build_visual() -> void:
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = Vector3(2.2, 2.2, 0.4); mesh.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = Color("f0b429"); mesh.material_override = material; add_child(mesh)
	var label := Label3D.new(); label.text = "BALL\nRETURN"; label.font_size = 54; label.outline_size = 8; label.position.z = 0.22; label.pixel_size = 0.006; add_child(label)
	var shape := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = Vector3(1.4, 1.4, 1.3); shape.shape = box_shape; shape.position.z = 0.5; add_child(shape)
