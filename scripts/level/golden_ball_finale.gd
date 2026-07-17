class_name GoldenBallFinale
extends StaticBody3D

signal claimed(actor: Node)
signal unavailable(message: String)

@export var prompt := "FETCH THE GOLDEN TENNIS BALL"
var enabled := false
var claimed_once := false


func _ready() -> void:
	if get_child_count() == 0: _build_visual()
	visible = enabled
	collision_layer = 1 if enabled else 0


func enable_as_reward() -> void:
	enabled = true
	claimed_once = false
	visible = true
	collision_layer = 1
	# Joining the proximity-interaction group only once claimable keeps the
	# hidden ball from answering the use key before the complete boss defeat.
	if not is_in_group(&"interactables"):
		add_to_group(&"interactables")
	var registry := get_node_or_null("/root/WorldRegistry")
	if registry != null:
		registry.register_interactable(self)


func enable_for_boss(_target: Node = null) -> void:
	# Compatibility alias for development routes created before the finale reward
	# was decoupled from boss damage.
	enable_as_reward()


func reset_reward() -> void:
	enabled = false
	claimed_once = false
	visible = false
	collision_layer = 0
	remove_from_group(&"interactables")
	var registry := get_node_or_null("/root/WorldRegistry")
	if registry != null:
		registry.unregister(self)


func get_interaction_label() -> String:
	return prompt if enabled and not claimed_once else ""


func interact(actor: Node) -> void:
	if not enabled or claimed_once:
		unavailable.emit("THE BALL IS STILL CONTAINED.")
		return
	claimed_once = true
	enabled = false
	visible = false
	collision_layer = 0
	remove_from_group(&"interactables")
	var registry := get_node_or_null("/root/WorldRegistry")
	if registry != null:
		registry.unregister(self)
	claimed.emit(actor)


func _build_visual() -> void:
	var mesh := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = 0.55; sphere.height = 1.1; mesh.mesh = sphere
	var material := StandardMaterial3D.new(); material.albedo_color = Color("ffd60a"); material.emission_enabled = true; material.emission = Color("b88600"); material.emission_energy_multiplier = 2.5; mesh.material_override = material; add_child(mesh)
	var shape := CollisionShape3D.new(); var sphere_shape := SphereShape3D.new(); sphere_shape.radius = 0.7; shape.shape = sphere_shape; add_child(shape)
	var light := OmniLight3D.new(); light.light_color = Color("ffd60a"); light.omni_range = 5.0; light.light_energy = 2.5; add_child(light)
