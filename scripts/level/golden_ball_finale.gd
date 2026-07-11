class_name GoldenBallFinale
extends StaticBody3D

signal claimed(actor: Node)
signal unavailable(message: String)

@export var prompt := "FETCH THE GOLDEN TENNIS BALL"
var enabled := false
var claimed_once := false
var walker: Node


func _ready() -> void:
	if get_child_count() == 0: _build_visual()
	visible = enabled
	collision_layer = 1 if enabled else 0


func enable_for_boss(target: Node) -> void:
	walker = target; enabled = true; visible = true; collision_layer = 1


func get_interaction_label() -> String:
	return prompt if enabled and not claimed_once else ""


func interact(actor: Node) -> void:
	if not enabled or claimed_once:
		unavailable.emit("THE BALL IS STILL CONTAINED.")
		return
	claimed_once = true
	if walker and walker.has_method("strike_with_golden_ball"): walker.strike_with_golden_ball(actor)
	claimed.emit(actor)


func _build_visual() -> void:
	var mesh := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = 0.55; sphere.height = 1.1; mesh.mesh = sphere
	var material := StandardMaterial3D.new(); material.albedo_color = Color("ffd60a"); material.emission_enabled = true; material.emission = Color("b88600"); material.emission_energy_multiplier = 2.5; mesh.material_override = material; add_child(mesh)
	var shape := CollisionShape3D.new(); var sphere_shape := SphereShape3D.new(); sphere_shape.radius = 0.7; shape.shape = sphere_shape; add_child(shape)
	var light := OmniLight3D.new(); light.light_color = Color("ffd60a"); light.omni_range = 5.0; light.light_energy = 2.5; add_child(light)
