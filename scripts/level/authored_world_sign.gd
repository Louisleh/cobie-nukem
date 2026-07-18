class_name AuthoredWorldSign
extends Label3D

@export var placement_id: StringName = &"sign"
@export var authored_text := ""
@export var route_facing_anchor := Vector3.ZERO
@export var authored_double_sided := false
@export_range(0.01, 2.0, 0.01) var minimum_wall_clearance := 0.04


func configure(id: StringName, value: String, world_position: Vector3, route_anchor: Vector3, color: Color) -> void:
	placement_id = id
	authored_text = value
	text = value
	position = world_position
	route_facing_anchor = route_anchor
	modulate = color
	font_size = 44
	pixel_size = 0.009
	outline_size = 8
	no_depth_test = false
	if not world_position.is_equal_approx(route_anchor):
		look_at_from_position(world_position, Vector3(route_anchor.x, world_position.y, route_anchor.z), Vector3.UP, true)


func validate_authored() -> PackedStringArray:
	var errors := PackedStringArray()
	if placement_id == &"": errors.append("authored sign has no placement id")
	if authored_text.strip_edges().is_empty() or text.strip_edges().is_empty(): errors.append("authored sign %s has no text" % placement_id)
	if scale.x < 0.0 or scale.y < 0.0 or scale.z < 0.0: errors.append("authored sign %s uses mirrored negative scale" % placement_id)
	if not authored_double_sided and not global_position.is_equal_approx(route_facing_anchor):
		var toward_route := global_position.direction_to(route_facing_anchor)
		if global_basis.z.dot(toward_route) < 0.35:
			errors.append("authored sign %s faces away from its route anchor" % placement_id)
	if minimum_wall_clearance <= 0.0: errors.append("authored sign %s has invalid wall clearance" % placement_id)
	return errors
