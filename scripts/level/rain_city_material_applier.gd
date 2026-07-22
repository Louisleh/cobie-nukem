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
	"RC_Skyline": preload("res://assets/materials/rain_city/skyline_silhouette.tres"),
	"RC_Mountain": preload("res://assets/materials/rain_city/mountain_silhouette.tres"),
}


func _ready() -> void:
	var unmapped := validate_material_contract(self)
	for material_name in unmapped:
		push_error("Rain City foundry material is not manifested: %s" % material_name)
	_apply_to(self)
	# The gameplay builder runs from the parent mission's _ready(), after this
	# presentation child enters the tree. Defer the render-only dressing pass so
	# authored barriers can replace the builder's collision-debug slabs without
	# changing any collision shape, layer, route state, or navigation source.
	call_deferred("apply_route_gate_presentation", get_parent())


func apply_route_gate_presentation(mission_root: Node) -> int:
	if mission_root == null or not is_instance_valid(mission_root):
		return 0
	var decorated := 0
	for group_id in [&"rain_city_encounter_gates", &"rain_city_route_state_gates"]:
		for raw_gate in get_tree().get_nodes_in_group(group_id):
			var gate := raw_gate as StaticBody3D
			if gate == null or not mission_root.is_ancestor_of(gate):
				continue
			if _decorate_route_gate(gate, group_id == &"rain_city_route_state_gates"):
				decorated += 1
	return decorated


func _decorate_route_gate(gate: StaticBody3D, route_state_gate: bool) -> bool:
	if gate.has_node("WCB008Presentation"):
		return false
	var shape_size := Vector3.ZERO
	for child in gate.get_children():
		if child is MeshInstance3D:
			# The builder's opaque emissive slab is collision visualization, not final
			# art. Keep the body and shape authoritative while replacing only its mesh.
			(child as MeshInstance3D).visible = false
		elif child is CollisionShape3D:
			var box_shape := (child as CollisionShape3D).shape as BoxShape3D
			if box_shape != null:
				shape_size = box_shape.size
	if shape_size == Vector3.ZERO:
		return false

	var presentation := Node3D.new()
	presentation.name = "WCB008Presentation"
	presentation.set_meta(&"render_only", true)
	presentation.set_meta(&"collision_size_snapshot", shape_size)
	gate.add_child(presentation)

	var structural_material := MATERIALS["RC_Charcoal"] as Material
	var accent_material := (MATERIALS["RC_WayfindingCyan"] if route_state_gate else MATERIALS["RC_ComplianceYellow"]) as Material
	var post_width := minf(0.32, shape_size.x * 0.08)
	var beam_height := minf(0.16, shape_size.y * 0.1)
	_add_gate_box(presentation, "PostLeft", Vector3(-shape_size.x * 0.5 + post_width * 0.5, 0.0, 0.0), Vector3(post_width, shape_size.y, shape_size.z * 1.18), structural_material)
	_add_gate_box(presentation, "PostRight", Vector3(shape_size.x * 0.5 - post_width * 0.5, 0.0, 0.0), Vector3(post_width, shape_size.y, shape_size.z * 1.18), structural_material)
	_add_gate_box(presentation, "TopRail", Vector3(0.0, shape_size.y * 0.5 - beam_height * 0.5, 0.0), Vector3(shape_size.x, beam_height, shape_size.z * 1.18), structural_material)
	_add_gate_box(presentation, "BottomRail", Vector3(0.0, -shape_size.y * 0.5 + beam_height * 0.5, 0.0), Vector3(shape_size.x, beam_height, shape_size.z * 1.18), structural_material)
	for index in range(3):
		var fraction := -0.28 + float(index) * 0.28
		_add_gate_box(presentation, "SignalRail%d" % index, Vector3(0.0, shape_size.y * fraction, shape_size.z * 0.16), Vector3(maxf(0.4, shape_size.x - post_width * 2.0), beam_height, shape_size.z * 0.34), accent_material)
	_add_gate_label(presentation, route_state_gate)
	return true


func _add_gate_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = position
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)


func _add_gate_label(parent: Node3D, route_state_gate: bool) -> void:
	var label := Label3D.new()
	label.name = "WarningLabel"
	label.text = "RAIN LINE // POWER LOCK" if route_state_gate else "COMPLIANCE HOLD // CLEAR AREA"
	label.position = Vector3(0.0, 0.34, 0.29)
	label.modulate = Color("6fe8ff") if route_state_gate else Color("ffd06a")
	label.outline_modulate = Color("111820")
	label.font_size = 34
	label.outline_size = 7
	label.pixel_size = 0.006
	label.double_sided = false
	label.no_depth_test = false
	parent.add_child(label)


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
