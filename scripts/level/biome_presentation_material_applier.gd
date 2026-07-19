class_name BiomePresentationMaterialApplier
extends RefCounted

## Applies manifested Godot material families to Blender-authored presentation
## kits. Object names use MAT_<family>__<asset>; collision and navigation stay
## owned by the gameplay layout and are never imported from these kits.

static func apply(root: Node, material_set_id: StringName) -> PackedStringArray:
	var errors := PackedStringArray()
	if root == null or material_set_id == &"":
		errors.append("presentation material application requires root and set id")
		return errors
	var applied := 0
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var family := _family_from_name(mesh.name)
		if family == &"":
			continue
		var path := "res://assets/materials/%s/%s.tres" % [material_set_id, family]
		if not ResourceLoader.exists(path):
			errors.append("missing presentation material %s for %s" % [path, mesh.name])
			continue
		mesh.material_override = load(path) as Material
		applied += 1
	if applied == 0:
		errors.append("presentation kit %s has no manifested MAT_ family meshes" % root.name)
	return errors


static func _family_from_name(node_name: String) -> StringName:
	if not node_name.begins_with("MAT_") or "__" not in node_name:
		return &""
	return StringName(node_name.trim_prefix("MAT_").get_slice("__", 0))
