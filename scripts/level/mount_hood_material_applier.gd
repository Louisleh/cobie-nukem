class_name MountHoodMaterialApplier
extends Node3D

const MATERIALS := {
	"MH_FreshPowder": preload("res://assets/materials/mount_hood/fresh_powder.tres"),
	"MH_PackedSnow": preload("res://assets/materials/mount_hood/packed_snow.tres"),
	"MH_PlowedAsphalt": preload("res://assets/materials/mount_hood/plowed_asphalt.tres"),
	"MH_LodgeTimber": preload("res://assets/materials/mount_hood/lodge_timber.tres"),
	"MH_LodgeStone": preload("res://assets/materials/mount_hood/lodge_stone.tres"),
	"MH_LiftSteel": preload("res://assets/materials/mount_hood/lift_steel.tres"),
	"MH_WarmWindows": preload("res://assets/materials/mount_hood/warm_windows.tres"),
	"MH_ExposedRock": preload("res://assets/materials/mount_hood/exposed_rock.tres"),
}


func _ready() -> void:
	_apply_to(self)


func _apply_to(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_mesh(node as MeshInstance3D)
	for child in node.get_children():
		_apply_to(child)


func _apply_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var source := mesh_instance.mesh.surface_get_material(surface_index)
		if source == null:
			continue
		var replacement: Material = MATERIALS.get(source.resource_name)
		if replacement != null:
			mesh_instance.set_surface_override_material(surface_index, replacement)
