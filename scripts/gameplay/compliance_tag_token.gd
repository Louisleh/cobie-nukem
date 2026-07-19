class_name ComplianceTagToken
extends Node3D

var amount := 1
var _target: Node3D
var _age := 0.0
var _origin_y := 0.0


func configure(value: int, target: Node3D) -> void:
	amount = maxi(1, value)
	_target = target


func _ready() -> void:
	_origin_y = position.y
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new(); cylinder.top_radius = 0.12; cylinder.bottom_radius = 0.12; cylinder.height = 0.035; cylinder.radial_segments = 10
	mesh.mesh = cylinder
	var material := StandardMaterial3D.new(); material.albedo_color = Color("75d7d0"); material.emission_enabled = true; material.emission = Color("1c6968"); material.emission_energy_multiplier = 0.8
	mesh.material_override = material
	add_child(mesh)


func _process(delta: float) -> void:
	_age += delta
	rotation.y += delta * 6.0
	if _age < 0.28:
		position.y = _origin_y + sin(_age * 11.0) * 0.12
	elif is_instance_valid(_target):
		global_position = global_position.move_toward(_target.global_position + Vector3.UP, delta * 18.0)
		if global_position.distance_to(_target.global_position + Vector3.UP) < 0.35: queue_free()
	if _age >= 1.8: queue_free()
