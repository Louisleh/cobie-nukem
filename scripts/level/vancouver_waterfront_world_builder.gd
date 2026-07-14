class_name VancouverWaterfrontWorldBuilder
extends Node

const CheckpointScene = preload("res://scenes/interactables/level_checkpoint.tscn")
const SwitchScene = preload("res://scenes/interactables/level_switch.tscn")
const ZoneScene = preload("res://scenes/interactables/zone_trigger.tscn")
const NAVIGATION_SOURCE_LAYER := 1 << 19

var on_zone_entered: Callable
var on_checkpoint_activated: Callable
var on_objective_action: Callable
var on_narrative_message: Callable

var geometry: Node3D
var actors: Node3D
var interactables: Node3D
var navigation_region: NavigationRegion3D
var terminal_switch: LevelSwitch
var departure_switch: LevelSwitch

var _owner: Node3D
var _navigation_sources: Array[StaticBody3D] = []
var _built := false


func build(owner: Node3D) -> bool:
	if _built:
		return true
	if owner == null:
		return false
	_owner = owner
	geometry = Node3D.new()
	geometry.name = "Geometry"
	owner.add_child(geometry)
	actors = Node3D.new()
	actors.name = "Actors"
	owner.add_child(actors)
	interactables = Node3D.new()
	interactables.name = "Interactables"
	owner.add_child(interactables)
	_build_environment()
	_build_route()
	_build_landmarks()
	_build_story_objects()
	_build_navigation()
	_built = true
	return true


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "RainCityEnvironment"
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("18283a")
	sky_material.sky_horizon_color = Color("6e8795")
	sky_material.ground_bottom_color = Color("17252c")
	sky_material.ground_horizon_color = Color("536c72")
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color("a5b9bd")
	environment.ambient_light_energy = 0.55
	environment.fog_enabled = true
	environment.fog_light_color = Color("708992")
	environment.fog_density = 0.009
	environment.fog_aerial_perspective = 0.72
	world_environment.environment = environment
	_owner.add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "RainCityKeyLight"
	key_light.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key_light.light_color = Color("c5d7d6")
	key_light.light_energy = 1.05
	key_light.shadow_enabled = true
	_owner.add_child(key_light)


func _build_route() -> void:
	_floor("DowntownAlley", Vector3(0.0, -0.5, -3.0), Vector3(20.0, 1.0, 34.0), Color("30383e"), &"asphalt")
	_floor("RainCitySliceBlock", Vector3(0.0, -0.5, -36.0), Vector3(24.0, 1.0, 32.0), Color("45454b"), &"concrete")
	_floor("WaterfrontSeawall", Vector3(0.0, -0.5, -73.0), Vector3(32.0, 1.0, 42.0), Color("3c5158"), &"concrete")
	_floor("TerminalService", Vector3(0.0, -0.5, -111.0), Vector3(24.0, 1.0, 34.0), Color("3e4a50"), &"metal")
	_floor("HarbourPier", Vector3(0.0, -0.5, -153.0), Vector3(36.0, 1.0, 50.0), Color("39484e"), &"steel")
	# Wide overlaps keep the baked navigation path continuous after agent-radius erosion.
	for connector_z in [-19.0, -53.0, -95.0, -128.0]:
		_floor("RouteConnector", Vector3(0.0, -0.48, connector_z), Vector3(10.0, 0.96, 8.0), Color("46545a"), &"concrete")
	# Edge rails stop accidental route skips while leaving the authored forward path open.
	for section in [
		[11.0, -3.0, 34.0], [13.0, -36.0, 32.0], [17.0, -73.0, 42.0],
		[13.0, -111.0, 34.0], [19.0, -153.0, 50.0],
	]:
		var x := float(section[0])
		var z := float(section[1])
		var length := float(section[2])
		_prop_box("RouteRail", Vector3(-x, 0.65, z), Vector3(0.45, 1.3, length), Color("25363b"), true)
		_prop_box("RouteRail", Vector3(x, 0.65, z), Vector3(0.45, 1.3, length), Color("25363b"), true)
	# The upper seawall lane creates authored vertical combat without disconnecting the lower path.
	_floor("SeawallUpperLane", Vector3(-9.5, 1.1, -76.0), Vector3(8.0, 0.5, 24.0), Color("61747a"), &"concrete")
	for step in 6:
		_floor("SeawallRampStep", Vector3(-7.5 + step * 0.7, -0.32 + step * 0.22, -62.0), Vector3(1.6, 0.35, 3.0), Color("61747a"), &"concrete")


func _build_landmarks() -> void:
	# Originalized silhouettes provide navigation anchors without reproducing real maps or logos.
	for z in [-8.0, -1.0, 7.0]:
		_prop_box("DowntownTower", Vector3(-7.8, 4.0, z), Vector3(4.5, 8.0, 5.0), Color("263b46"), true)
		_prop_box("DowntownTower", Vector3(7.8, 3.0, z - 3.0), Vector3(4.5, 6.0, 5.0), Color("314753"), true)
	_prop_box("RainCitySliceShop", Vector3(-8.5, 2.0, -37.0), Vector3(6.0, 4.0, 14.0), Color("7c3f38"), true)
	_sign("RAIN CITY SLICE\nHOT PIZZA • COLD COMPLIANCE", Vector3(-5.35, 2.6, -33.0), 90.0, Color("ffc65a"))
	_sign("SORRY — PATIO CLOSED\nDUE TO EXCESSIVE JOY", Vector3(5.8, 1.4, -43.0), -90.0, Color("e5f0df"))
	# Harbour, bridge, mountain, ferry, and crane silhouettes are deliberately fictionalized.
	_prop_box("HarbourWater", Vector3(27.0, -0.72, -103.0), Vector3(16.0, 0.25, 120.0), Color("174755"), false, true)
	for pylon in [-12.0, 0.0, 12.0]:
		_prop_box("BridgePylon", Vector3(pylon, 7.0, -212.0), Vector3(1.4, 14.0, 1.4), Color("435e66"), false)
	_prop_box("BridgeDeck", Vector3(0.0, 8.0, -212.0), Vector3(38.0, 0.8, 2.2), Color("435e66"), false)
	_prop_box("FerrySilhouette", Vector3(25.0, 1.2, -126.0), Vector3(10.0, 2.4, 4.0), Color("d8ddd2"), false)
	for crane_x in [-13.0, 12.0]:
		_prop_box("HarbourCraneMast", Vector3(crane_x, 5.0, -167.0), Vector3(0.8, 10.0, 0.8), Color("d39635"), false)
		_prop_box("HarbourCraneArm", Vector3(crane_x + 3.0, 9.2, -167.0), Vector3(7.0, 0.5, 0.5), Color("d39635"), false)
	# Combat cover and machinery keep each major space tactically legible.
	for position in [Vector3(-5, 1, -9), Vector3(5, 1, -29), Vector3(-6, 1, -44), Vector3(7, 1, -70), Vector3(-5, 1, -88), Vector3(-7, 1, -110), Vector3(7, 1, -117), Vector3(-9, 1, -145), Vector3(9, 1, -159)]:
		_prop_box("ComplianceCrate", position, Vector3(2.8, 2.0, 2.8), Color("725638"), true)


func _build_story_objects() -> void:
	var route_zones := [
		[&"downtown_alley", "DOWNTOWN SERVICE ALLEY", Vector3(0, 1.5, 10), Vector3(20, 4, 4)],
		[&"ruse_block", "RAIN CITY SLICE", Vector3(0, 1.5, -20), Vector3(24, 4, 4)],
		[&"waterfront_seawall", "WATERFRONT SEAWALL", Vector3(0, 1.5, -53), Vector3(30, 4, 4)],
		[&"terminal_service", "TERMINAL SERVICE", Vector3(0, 1.5, -95), Vector3(22, 4, 4)],
		[&"harbour_pier", "HARBOUR PIER", Vector3(0, 1.5, -128), Vector3(34, 4, 4)],
	]
	for zone_data in route_zones:
		var trigger := ZoneScene.instantiate() as LevelZoneTrigger
		trigger.zone_id = zone_data[0]
		trigger.title = zone_data[1]
		trigger.position = zone_data[2]
		trigger.trigger_size = zone_data[3]
		trigger.entered.connect(_on_zone_triggered)
		interactables.add_child(trigger)

	var checkpoints := [
		[&"checkpoint_downtown_alley", Vector3(0, 0, 8)],
		[&"checkpoint_ruse_block", Vector3(0, 0, -23)],
		[&"checkpoint_waterfront_seawall", Vector3(0, 0, -56)],
		[&"checkpoint_terminal_service", Vector3(0, 0, -98)],
		[&"checkpoint_harbour_pier", Vector3(0, 0, -131)],
	]
	for checkpoint_data in checkpoints:
		var checkpoint := CheckpointScene.instantiate() as LevelCheckpoint
		checkpoint.checkpoint_id = checkpoint_data[0]
		checkpoint.position = checkpoint_data[1]
		checkpoint.activated.connect(_on_checkpoint)
		interactables.add_child(checkpoint)

	terminal_switch = SwitchScene.instantiate() as LevelSwitch
	terminal_switch.name = "TerminalPower"
	terminal_switch.switch_id = &"terminal_power"
	terminal_switch.prompt = "OVERRIDE TERMINAL LOCKDOWN"
	terminal_switch.position = Vector3(7.5, 1.2, -118.0)
	terminal_switch.activated.connect(_on_switch_activated)
	interactables.add_child(terminal_switch)

	departure_switch = SwitchScene.instantiate() as LevelSwitch
	departure_switch.name = "HarbourDeparture"
	departure_switch.switch_id = &"harbour_departure"
	departure_switch.prompt = "DEPART RAIN CITY"
	departure_switch.position = Vector3(0.0, 1.2, -173.0)
	departure_switch.activated.connect(_on_switch_activated)
	interactables.add_child(departure_switch)
	_sign("CITATION CONVOY\nPARKING JOY IS A TOWABLE OFFENCE", Vector3(0, 2.2, -137), 0.0, Color("ffb33b"))


func _build_navigation() -> void:
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "VancouverGroundNavigation"
	var mesh := NavigationMesh.new()
	mesh.agent_radius = 0.5
	mesh.agent_height = 2.0
	mesh.agent_max_climb = 0.5
	mesh.agent_max_slope = 45.0
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	mesh.region_min_size = 1.0
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = NAVIGATION_SOURCE_LAYER
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	mesh.geometry_source_group_name = &"vancouver_navigation_source"
	mesh.filter_baking_aabb = AABB(Vector3(-20.0, -1.2, -181.0), Vector3(40.0, 4.0, 194.0))
	navigation_region.navigation_mesh = mesh
	_owner.add_child(navigation_region)
	call_deferred("_bake_navigation")


func _bake_navigation() -> void:
	if not is_instance_valid(navigation_region):
		return
	navigation_region.bake_navigation_mesh(false)
	var navigation_map := navigation_region.get_navigation_map()
	NavigationServer3D.region_set_map(navigation_region.get_rid(), navigation_map)
	NavigationServer3D.region_set_navigation_mesh(navigation_region.get_rid(), navigation_region.navigation_mesh)
	NavigationServer3D.map_set_active(navigation_map, true)
	NavigationServer3D.map_force_update(navigation_map)
	for source in _navigation_sources:
		if is_instance_valid(source):
			source.queue_free()
	_navigation_sources.clear()


func _floor(node_name: String, position: Vector3, size: Vector3, color: Color, surface_id: StringName) -> void:
	var body := _prop_box(node_name, position, size, color, true)
	body.add_to_group(&"vancouver_navigation_source")
	body.set_meta(&"surface_id", surface_id)
	body.collision_layer = NAVIGATION_SOURCE_LAYER | 1
	_navigation_sources.append(body)


func _prop_box(node_name: String, position: Vector3, size: Vector3, color: Color, collision := false, emissive := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1 if collision else 0
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if emissive:
		material.emission_enabled = true
		material.emission = color * 0.45
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
	geometry.add_child(body)
	return body


func _sign(text: String, position: Vector3, yaw: float, color: Color) -> void:
	var label := Label3D.new()
	label.name = "RainCitySign"
	label.text = text
	label.position = position
	label.rotation_degrees.y = yaw
	label.font_size = 44
	label.pixel_size = 0.009
	label.modulate = color
	label.outline_size = 8
	label.no_depth_test = false
	geometry.add_child(label)


func _on_zone_triggered(zone_id: StringName, title: String, actor: Node) -> void:
	if on_zone_entered.is_valid():
		on_zone_entered.call(zone_id, title, actor)


func _on_checkpoint(checkpoint_id: StringName, respawn_position: Vector3) -> void:
	if on_checkpoint_activated.is_valid():
		on_checkpoint_activated.call(checkpoint_id, respawn_position)


func _on_switch_activated(switch_id: StringName, actor: Node) -> void:
	if on_objective_action.is_valid():
		on_objective_action.call(ObjectiveDefinition.Kind.ACTIVATE, switch_id)
	if on_narrative_message.is_valid():
		var message := "TERMINAL LOCKDOWN OVERRIDDEN." if switch_id == &"terminal_power" else "RAIN CITY DEPARTURE CLEARED."
		on_narrative_message.call(message, 2.5)
