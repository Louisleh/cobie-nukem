class_name SalmonCreekEnvironmentKit
extends Node3D

## Static, Web-safe production dressing layered over Salmon Creek's proven
## collision route. The kit owns visuals only: no progression or navigation.

const OpeningFoundryScene := preload("res://assets/models/environment/salmon_creek_opening_foundry.glb")

var _materials: Dictionary = {}


func build(parent: Node3D) -> void:
	if parent == null or get_child_count() > 0:
		return
	parent.add_child(self)
	_build_field_landmarks()
	_build_shed_landmarks()
	_build_tunnel_landmarks()
	_build_lab_landmarks()
	_build_arena_landmarks()


func _build_field_landmarks() -> void:
	# Presentation-only Blender kit. The world builder retains every gameplay
	# collider and the baked navigation source, so art can iterate independently.
	var opening_foundry := OpeningFoundryScene.instantiate()
	opening_foundry.name = "SalmonCreekOpeningFoundry"
	add_child(opening_foundry)
	# The scoreboard face points toward the playable field (+X). A -90 degree
	# rotation exposed Label3D's mirrored back face to the player on iPad.
	_label("SALMON CREEK\nHOME  0  •  DOGS  1", Vector3(-10.08, 3.45, -12.5), Vector3(0, 90, 0), 52, Color("ffd05a"))


func _build_shed_landmarks() -> void:
	for z in [-42.0, -36.0, -30.0, -24.0]:
		for x in [-6.5, 6.5]:
			_box("ShedPost", Vector3(x, 2.0, z), Vector3(0.35, 4.0, 0.35), &"wood", Color("76563c"))
		_box("ShedRoofBeam", Vector3(0, 4.05, z), Vector3(13.4, 0.28, 0.38), &"wood", Color("76563c"))
	_box("EquipmentCage", Vector3(4.6, 1.4, -34.0), Vector3(3.0, 2.8, 4.0), &"painted_metal", Color("39484c"))
	_box("Generator", Vector3(-4.7, 0.8, -36.5), Vector3(2.6, 1.6, 1.8), &"hazard", Color("d2912b"))
	for index in 3:
		_cylinder("VentStack", Vector3(-5.4 + index * 1.0, 2.0, -36.5), 0.12, 2.4, &"metal", Color("839095"))
	_box("ShedSafetyStripe", Vector3(0, 0.035, -39.6), Vector3(12.0, 0.04, 0.16), &"hazard", Color("e0a632"))
	_label("EQUIPMENT SHED\nAUTHORIZED GOOD DOGS ONLY", Vector3(0, 3.15, -42.35), Vector3.ZERO, 42, Color("f4dda0"))
	_omni_light("ShedWorkLight", Vector3(0, 3.35, -34.0), Color("ffd18a"), 2.1, 10.0)
	_omni_light("GeneratorStatusLight", Vector3(-4.7, 1.8, -36.5), Color("ff8a38"), 1.3, 5.0)


func _build_tunnel_landmarks() -> void:
	for z in range(-80, -47, 5):
		_box("TunnelRibLeft", Vector3(-4.6, 2.0, z), Vector3(0.32, 4.0, 0.45), &"metal", Color("4b5b60"))
		_box("TunnelRibRight", Vector3(4.6, 2.0, z), Vector3(0.32, 4.0, 0.45), &"metal", Color("4b5b60"))
		_box("TunnelRibTop", Vector3(0, 3.85, z), Vector3(9.5, 0.3, 0.45), &"metal", Color("4b5b60"))
		_box("TunnelLight", Vector3(0, 3.62, z + 0.5), Vector3(2.2, 0.08, 0.28), &"lamp", Color("b7e1d3"))
	for z in [-76.0, -61.0, -50.0]:
		_cylinder("UtilityPipe", Vector3(3.9, 2.6, z), 0.18, 8.0, &"hazard", Color("d08d28"), Vector3(90, 0, 0))
	for z in [-75.0, -63.0, -51.0]:
		_omni_light("TunnelWorkLight", Vector3(0, 3.35, z), Color("a8e3d4"), 1.45, 7.5)
	_box("TunnelGuideStripe", Vector3(-4.42, 1.25, -64.0), Vector3(0.08, 0.18, 34.0), &"hazard", Color("d8982d"))
	_label("MAINTENANCE TUNNEL\nJOY DETECTORS ACTIVE", Vector3(0, 2.7, -79.15), Vector3.ZERO, 40, Color("f4dda0"))


func _build_lab_landmarks() -> void:
	for z in [-116.0, -106.0, -96.0, -88.0]:
		_box("LabLight", Vector3(0, 4.58, z), Vector3(5.8, 0.08, 0.35), &"lamp", Color("d7f2ea"))
	for x in [-9.0, 9.0]:
		for z in [-112.0, -101.0, -90.0]:
			_box("LabConsole", Vector3(x, 0.9, z), Vector3(2.4, 1.8, 1.2), &"painted_metal", Color("415057"))
			_box("LabConsoleGlow", Vector3(x + (-1.22 if x > 0 else 1.22), 1.15, z), Vector3(0.06, 0.65, 0.85), &"display", Color("55d3c4"))
	_box("ComplianceScanner", Vector3(0, 2.2, -110.0), Vector3(5.2, 4.4, 0.55), &"hazard", Color("bf7c25"))
	_sphere("ScannerLens", Vector3(0, 2.35, -109.65), 0.75, &"display", Color("ff5c38"))
	_label("CANINE COMPLIANCE\nLAB 01", Vector3(0, 3.85, -109.62), Vector3.ZERO, 46, Color("f4dda0"))
	for z in [-112.0, -100.0, -89.0]:
		_omni_light("LabCeilingLight", Vector3(0, 4.25, z), Color("b8fff0"), 1.7, 9.0)
	for x in [-10.8, 10.8]:
		_box("LabHazardBand", Vector3(x, 1.2, -103.0), Vector3(0.08, 0.22, 34.0), &"hazard", Color("d4982b"))
	_box("LabCenterGuide", Vector3(0, 0.035, -101.0), Vector3(0.14, 0.04, 25.0), &"display", Color("58c9ba"))


func _build_arena_landmarks() -> void:
	for x in [-14.0, 14.0]:
		_box("ArenaGantryPost", Vector3(x, 4.0, -148), Vector3(0.7, 8.0, 0.7), &"hazard", Color("b77625"))
	_box("ArenaGantry", Vector3(0, 7.6, -148), Vector3(28.5, 0.65, 0.8), &"hazard", Color("b77625"))
	for x in [-11.0, -5.5, 0.0, 5.5, 11.0]:
		_box("ArenaWarningLamp", Vector3(x, 7.15, -147.5), Vector3(0.42, 0.42, 0.3), &"warning", Color("ff3e24"))
	for z in [-136.0, -148.0, -160.0]:
		for x in [-16.5, 16.5]:
			_box("ArenaBarrier", Vector3(x, 0.65, z), Vector3(1.4, 1.3, 5.0), &"hazard", Color("c18127"))
	_label("ANIMAL CONTROL\nFINAL REVIEW", Vector3(0, 6.85, -147.55), Vector3.ZERO, 54, Color("ffd05a"))
	for x in [-11.0, 11.0]:
		_omni_light("ArenaKeyLight", Vector3(x, 5.6, -148.0), Color("ffc05c"), 2.15, 14.0)
	_omni_light("ArenaWeakPointFill", Vector3(0, 3.2, -157.0), Color("54dce2"), 1.35, 10.0)
	for z in [-136.0, -148.0, -160.0]:
		_box("ArenaLaneStripe", Vector3(0, 0.04, z), Vector3(22.0, 0.045, 0.16), &"hazard", Color("d99a2e"))


func _box(node_name: String, position_value: Vector3, size: Vector3, surface: StringName, color: Color) -> void:
	var node := MeshInstance3D.new(); node.name = node_name; node.position = position_value
	var mesh := BoxMesh.new(); mesh.size = size; mesh.material = _material(surface, color); node.mesh = mesh; add_child(node)


func _cylinder(node_name: String, position_value: Vector3, radius: float, height: float, surface: StringName, color: Color, rotation_value := Vector3.ZERO) -> void:
	var node := MeshInstance3D.new(); node.name = node_name; node.position = position_value; node.rotation_degrees = rotation_value
	var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius * 1.12; mesh.height = height; mesh.radial_segments = 12; mesh.material = _material(surface, color); node.mesh = mesh; add_child(node)


func _sphere(node_name: String, position_value: Vector3, radius: float, surface: StringName, color: Color) -> void:
	var node := MeshInstance3D.new(); node.name = node_name; node.position = position_value
	var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius * 2.0; mesh.radial_segments = 16; mesh.rings = 8; mesh.material = _material(surface, color); node.mesh = mesh; add_child(node)


func _label(text: String, position_value: Vector3, rotation_value: Vector3, font_size: int, color: Color) -> void:
	var label := Label3D.new(); label.text = text; label.position = position_value; label.rotation_degrees = rotation_value; label.font_size = font_size; label.pixel_size = 0.0028; label.modulate = color; label.outline_size = 6; label.double_sided = false; add_child(label)


func _omni_light(node_name: String, position_value: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = position_value
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = range_value * 1.25
	light.distance_fade_length = range_value * 0.75
	add_child(light)


func _material(surface: StringName, color: Color) -> StandardMaterial3D:
	var key := "%s:%s" % [surface, color.to_html()]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	if surface in [&"metal", &"painted_metal", &"hazard"]:
		material.metallic = 0.58
		material.roughness = 0.38
		if surface == &"hazard":
			material.emission_enabled = true
			material.emission = color * 0.18
			material.emission_energy_multiplier = 0.45
	if surface in [&"display", &"lamp", &"warning"]:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.8 if surface != &"warning" else 3.0
	_materials[key] = material
	return material
