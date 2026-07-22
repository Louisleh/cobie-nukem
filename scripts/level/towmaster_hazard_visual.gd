class_name TowmasterHazardVisual
extends Node3D

const _VISUAL_HEIGHT: float = 0.03
const _INVALID_RADIUS: float = 0.0001

var _mesh_instance := MeshInstance3D.new()


func _init() -> void:
	_mesh_instance.name = "HazardMesh"
	_mesh_instance.cast_shadow = 0
	var material := StandardMaterial3D.new()
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.42, 0.05, 0.30)
	_mesh_instance.material_override = material
	add_child(_mesh_instance)


func configure_from_attack(attack: TowmasterAttackDefinition, origin: Vector3, target: Vector3) -> bool:
	if attack == null:
		return false
	if _mesh_instance == null or not is_finite(origin.x) or not is_finite(origin.y) or not is_finite(origin.z):
		return false
	if not is_finite(target.x) or not is_finite(target.y) or not is_finite(target.z):
		return false
	var material := _mesh_instance.material_override as StandardMaterial3D
	if material != null:
		var color := attack.visual_color
		color.a = 0.3
		material.albedo_color = color

	top_level = true
	if not is_in_group(&"towmaster_temp_visual"):
		add_to_group(&"towmaster_temp_visual")

	match attack.shape:
		TowmasterAttackDefinition.AttackShape.TARGET_ZONE, TowmasterAttackDefinition.AttackShape.RING:
			var radius := attack.radius
			if not is_finite(radius) or radius <= _INVALID_RADIUS:
				return false
			var ring := CylinderMesh.new()
			ring.top_radius = radius
			ring.bottom_radius = radius
			ring.height = _VISUAL_HEIGHT
			_mesh_instance.mesh = ring
			top_level = true
			global_position = origin if attack.shape == TowmasterAttackDefinition.AttackShape.RING else target
		TowmasterAttackDefinition.AttackShape.LANE:
			if not is_finite(attack.length) or not is_finite(attack.width):
				return false
			if attack.length <= _INVALID_RADIUS or attack.width <= _INVALID_RADIUS:
				return false
			var lane_direction := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
			if lane_direction.length_squared() <= _INVALID_RADIUS * _INVALID_RADIUS:
				lane_direction = Vector3.FORWARD
			else:
				lane_direction = lane_direction.normalized()

			var box := BoxMesh.new()
			box.size = Vector3(attack.width, _VISUAL_HEIGHT, attack.length)
			_mesh_instance.mesh = box
			var center := origin + (lane_direction * (attack.length * 0.5))
			var basis := Basis().looking_at(lane_direction, Vector3.UP)
			global_transform = Transform3D(basis, center)
		_:
			return false

	return true


func expire() -> void:
	queue_free()
