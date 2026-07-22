class_name RainCitySpatialRouteBuilder
extends RefCounted

const RETURN_ROUTE_ID := &"rainline_return"


static func build(builder: VancouverWaterfrontWorldBuilder) -> void:
	_build_seawall_loop(builder)
	_build_terminal_loop(builder)
	_build_pier_loop(builder)
	_build_return_route(builder)
	_build_sightline_windows(builder)
	_build_landmark_anchors(builder)


static func _build_seawall_loop(builder: VancouverWaterfrontWorldBuilder) -> void:
	var lane := builder._floor("SeawallUpperLane", Vector3(-9.5, 1.1, -76.0), Vector3(8.0, 0.5, 24.0), Color("61747a"), &"concrete")
	_tag_feature(lane, &"loop", &"seawall_overlook", &"path")
	_build_stair(builder, "SeawallNorthStep", &"seawall_overlook", Vector3(-7.0, -0.28, -60.5), Vector3(0.0, 0.25, -0.65))
	_build_stair(builder, "SeawallSouthStep", &"seawall_overlook", Vector3(-7.0, 0.97, -88.5), Vector3(0.0, -0.25, -0.65))


static func _build_terminal_loop(builder: VancouverWaterfrontWorldBuilder) -> void:
	var lane := builder._floor("TerminalControlLoop", Vector3(-7.5, 1.15, -115.0), Vector3(7.0, 0.45, 13.0), Color("596970"), &"metal")
	_tag_feature(lane, &"loop", &"terminal_control", &"path")
	_build_stair(builder, "TerminalNorthStep", &"terminal_control", Vector3(-5.5, -0.28, -105.0), Vector3(0.0, 0.25, -0.65))
	_build_stair(builder, "TerminalSouthStep", &"terminal_control", Vector3(-5.5, 0.97, -122.0), Vector3(0.0, -0.25, -0.65))


static func _build_pier_loop(builder: VancouverWaterfrontWorldBuilder) -> void:
	var lane := builder._floor("PierCraneFlank", Vector3(-12.5, 1.0, -155.0), Vector3(8.0, 0.45, 17.0), Color("4f6065"), &"steel")
	_tag_feature(lane, &"loop", &"pier_crane_flank", &"path")
	_build_stair(builder, "PierNorthStep", &"pier_crane_flank", Vector3(-10.0, -0.28, -143.5), Vector3(0.0, 0.22, -0.65))
	_build_stair(builder, "PierSouthStep", &"pier_crane_flank", Vector3(-10.0, 0.82, -164.0), Vector3(0.0, -0.22, -0.65))


static func _build_return_route(builder: VancouverWaterfrontWorldBuilder) -> void:
	var walkway := builder._floor("RainLineReturnWalkway", Vector3(-9.5, 1.15, -98.5), Vector3(6.0, 0.45, 19.0), Color("4f666c"), &"metal")
	_tag_feature(walkway, &"shortcut", RETURN_ROUTE_ID, &"path")
	walkway.set_meta(&"revisit_zone_id", &"waterfront_seawall")
	var gate := builder._prop_box("RouteStateGate_RainLineReturn", Vector3(-9.5, 2.45, -89.3), Vector3(5.8, 2.5, 0.45), Color("65d1c2"), true, true)
	gate.add_to_group(&"rain_city_route_state_gates")
	gate.set_meta(&"route_state_id", RETURN_ROUTE_ID)
	gate.set_meta(&"unlocked_by", &"terminal_power")
	builder.register_route_state_gate(RETURN_ROUTE_ID, gate)


static func _build_stair(builder: VancouverWaterfrontWorldBuilder, node_prefix: String, loop_id: StringName, start: Vector3, delta: Vector3) -> void:
	for step_index in 6:
		var step := builder._floor(node_prefix, start + delta * step_index, Vector3(3.0, 0.32, 1.5), Color("61747a"), &"concrete")
		var endpoint := &"entry" if step_index == 0 else (&"exit" if step_index == 5 else &"step")
		_tag_feature(step, &"loop", loop_id, endpoint)


static func _build_sightline_windows(builder: VancouverWaterfrontWorldBuilder) -> void:
	_add_probe(builder, &"slice_to_seawall", Vector3(-8.0, 2.2, -49.0), Vector3(-9.5, 4.6, -69.0), &"ruse_block", &"waterfront_seawall", &"vancouver_waterfront_pier")
	_add_probe(builder, &"terminal_to_harbour", Vector3(8.0, 2.2, -123.0), Vector3(12.0, 8.5, -167.0), &"terminal_service", &"harbour_pier", &"vancouver_harbour_mast")


static func _add_probe(builder: VancouverWaterfrontWorldBuilder, probe_id: StringName, origin: Vector3, target: Vector3, from_zone: StringName, to_zone: StringName, landmark_id: StringName) -> void:
	var marker := Node3D.new()
	marker.name = "Sightline_%s" % probe_id
	marker.position = origin
	marker.add_to_group(&"rain_city_sightline_windows")
	marker.set_meta(&"sightline_id", probe_id)
	marker.set_meta(&"target_position", target)
	marker.set_meta(&"from_zone_id", from_zone)
	marker.set_meta(&"to_zone_id", to_zone)
	marker.set_meta(&"target_landmark_id", landmark_id)
	builder.gameplay_layout.add_child(marker)


static func _build_landmark_anchors(builder: VancouverWaterfrontWorldBuilder) -> void:
	_add_landmark_anchor(builder, &"opening", &"vancouver_downtown_waypoint", Vector3(0.0, 1.7, 8.0), Vector3(-7.8, 4.0, -8.0))
	_add_landmark_anchor(builder, &"mid_route", &"vancouver_waterfront_pier", Vector3(0.0, 1.7, -56.0), Vector3(25.0, 1.2, -126.0))
	_add_landmark_anchor(builder, &"finale", &"vancouver_harbour_mast", Vector3(0.0, 1.7, -131.0), Vector3(12.0, 9.2, -167.0))


static func _add_landmark_anchor(builder: VancouverWaterfrontWorldBuilder, role: StringName, landmark_id: StringName, origin: Vector3, target: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = "LandmarkAnchor_%s" % role
	marker.position = origin
	marker.add_to_group(&"rain_city_landmark_anchors")
	marker.set_meta(&"canonical_role", role)
	marker.set_meta(&"landmark_id", landmark_id)
	marker.set_meta(&"target_position", target)
	builder.gameplay_layout.add_child(marker)


static func _tag_feature(node: Node3D, kind: StringName, feature_id: StringName, role: StringName) -> void:
	node.add_to_group(&"rain_city_route_features")
	node.set_meta(&"route_feature_kind", kind)
	node.set_meta(&"route_feature_id", feature_id)
	node.set_meta(&"route_feature_role", role)
