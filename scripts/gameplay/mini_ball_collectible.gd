class_name MiniBallCollectible
extends Area3D

signal collected(collectible_id: StringName)

var collectible_id: StringName = &""
var _visual: Node3D
var _origin_y := 0.0
var _phase := 0.0
var _claimed := false


func configure(id: StringName) -> void:
	collectible_id = id


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = true
	_origin_y = position.y
	_phase = float(abs(hash(String(collectible_id))) % 628) / 100.0
	_build_visual()
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if _visual == null: return
	_visual.position.y = sin(Time.get_ticks_msec() * 0.003 + _phase) * 0.08
	_visual.rotation.y += 0.018


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new(); sphere.radius = 0.13; sphere.height = 0.26; sphere.radial_segments = 12; sphere.rings = 6
	mesh.mesh = sphere
	var material := StandardMaterial3D.new(); material.albedo_color = Color("d8f14d"); material.emission_enabled = true; material.emission = Color("6a7d16"); material.emission_energy_multiplier = 0.65
	mesh.material_override = material
	_visual.add_child(mesh)
	var shape := CollisionShape3D.new(); var sphere_shape := SphereShape3D.new(); sphere_shape.radius = 0.42; shape.shape = sphere_shape; add_child(shape)


func _on_body_entered(body: Node) -> void:
	if _claimed or body is not CobiePlayer: return
	_claimed = true
	monitoring = false
	collected.emit(collectible_id)
	queue_free()
