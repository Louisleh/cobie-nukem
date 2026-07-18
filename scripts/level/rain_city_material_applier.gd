class_name RainCityMaterialApplier
extends Node3D

const MATERIALS := {
	"RC_Charcoal": preload("res://assets/materials/rain_city/painted_municipal_metal.tres"),
	"RC_WetConcrete": preload("res://assets/materials/rain_city/seawall_concrete.tres"),
	"RC_RainBrick": preload("res://assets/materials/rain_city/rain_brick.tres"),
	"RC_GlassPanels": preload("res://assets/materials/rain_city/glass_panels.tres"),
	"RC_HarbourSteel": preload("res://assets/materials/rain_city/harbour_steel.tres"),
	"RC_SliceOrange": preload("res://assets/materials/rain_city/slice_tile.tres"),
	"RC_RainWood": preload("res://assets/materials/rain_city/wet_wood.tres"),
	# Supporting foundry palettes intentionally reuse the closest manifested
	# production family instead of shipping flat Blender fallback materials.
	"RC_WarmLight": preload("res://assets/materials/rain_city/slice_tile.tres"),
	"RC_ComplianceYellow": preload("res://assets/materials/rain_city/slice_tile.tres"),
	"RC_Rubber": preload("res://assets/materials/rain_city/wet_wood.tres"),
	"RC_WayfindingCyan": preload("res://assets/materials/rain_city/glass_panels.tres"),
	"RC_Skyline": preload("res://assets/materials/rain_city/glass_panels.tres"),
	"RC_Mountain": preload("res://assets/materials/rain_city/seawall_concrete.tres"),
}


func _ready() -> void:
	var unmapped := validate_material_contract(self)
	for material_name in unmapped:
		push_error("Rain City foundry material is not manifested: %s" % material_name)
	_apply_to(self)


func validate_material_contract(root: Node = self) -> PackedStringArray:
	var unmapped := PackedStringArray()
	_collect_unmapped(root, unmapped)
	return unmapped


func _collect_unmapped(node: Node, unmapped: PackedStringArray) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var source := mesh_instance.mesh.surface_get_material(surface_index)
				if source != null and source.resource_name.begins_with("RC_") and not MATERIALS.has(source.resource_name) and source.resource_name not in unmapped:
					unmapped.append(source.resource_name)
	for child in node.get_children(): _collect_unmapped(child, unmapped)


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
