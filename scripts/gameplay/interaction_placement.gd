class_name InteractionPlacement
extends Resource

@export var schema_version := 1
@export var id: StringName = &"placement"
@export var zone_id: StringName = &"forbidden_field"
@export var definition: WorldInteractionDefinition
@export var transform: Transform3D = Transform3D.IDENTITY


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("interaction placement %s schema must be 1" % id)
	var trimmed_id := String(id).strip_edges()
	if trimmed_id.is_empty():
		errors.append("interaction placement id is empty")
	if String(zone_id).strip_edges().is_empty():
		errors.append("interaction placement %s has empty zone_id" % id)
	if definition == null:
		errors.append("interaction placement %s missing definition" % id)
	else:
		var definition_errors := definition.validate()
		for error in definition_errors:
			errors.append("interaction placement %s uses invalid definition: %s" % [id, error])
	if not transform.origin.is_finite():
		errors.append("interaction placement %s has non-finite transform origin" % id)
	if not transform.basis.x.is_finite() or not transform.basis.y.is_finite() or not transform.basis.z.is_finite():
		errors.append("interaction placement %s has non-finite transform basis" % id)
	var basis_scale := Vector3(transform.basis.x.length(), transform.basis.y.length(), transform.basis.z.length())
	if basis_scale.x <= 0.0 or basis_scale.y <= 0.0 or basis_scale.z <= 0.0:
		errors.append("interaction placement %s requires non-zero positive scale" % id)
	return errors
