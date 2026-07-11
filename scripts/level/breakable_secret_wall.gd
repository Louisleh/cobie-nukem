class_name BreakableSecretWall
extends StaticBody3D

signal broken(secret_id: StringName, title: String)

@export var secret_id: StringName = &"cracked_wall"
@export var secret_title := "MAINTENANCE LOOPHOLE"
@export var health := 35.0
@export var size := Vector3(4.0, 3.0, 0.5)
var is_broken := false


func _ready() -> void:
	if get_child_count() == 0: _build_visual()


func get_interaction_label() -> String:
	return "SUSPICIOUSLY CRACKED" if not is_broken else ""


func interact(actor: Node) -> void:
	apply_damage(health, actor)


func damage(amount: float) -> float:
	return apply_damage(amount)


func apply_damage(amount: float, _source: Node = null, _hit_position := Vector3.ZERO) -> float:
	if is_broken: return 0.0
	var applied := minf(health, amount); health -= applied
	if health <= 0.0:
		is_broken = true; visible = false; collision_layer = 0; collision_mask = 0
		broken.emit(secret_id, secret_title)
	return applied


func _build_visual() -> void:
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = Color("59636d"); material.roughness = 1.0; mesh.material_override = material; add_child(mesh)
	var crack_a := Label3D.new(); crack_a.text = "╲╱\n╱╲"; crack_a.font_size = 80; crack_a.modulate = Color("20262b"); crack_a.position.z = size.z * 0.52; add_child(crack_a)
	var shape := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = size; shape.shape = box_shape; add_child(shape)
