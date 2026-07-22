class_name VancouverWaterfrontWorldBuilder
extends Node

signal navigation_bake_completed(succeeded: bool, polygon_count: int)

const CheckpointScene = preload("res://scenes/interactables/level_checkpoint.tscn")
const SwitchScene = preload("res://scenes/interactables/level_switch.tscn")
const ZoneScene = preload("res://scenes/interactables/zone_trigger.tscn")
const SpatialRouteBuilder = preload("res://scripts/level/rain_city_spatial_route_builder.gd")
const NAVIGATION_SOURCE_LAYER := 1 << 19
const SURFACE_MATERIALS := {
	&"asphalt": preload("res://assets/materials/rain_city/wet_asphalt.tres"),
	&"concrete": preload("res://assets/materials/rain_city/seawall_concrete.tres"),
	&"metal": preload("res://assets/materials/rain_city/terminal_floor.tres"),
	&"steel": preload("res://assets/materials/rain_city/harbour_steel.tres"),
}

var on_zone_entered: Callable
var on_checkpoint_activated: Callable
var on_objective_action: Callable
var on_narrative_message: Callable

@export var build_navigation := true

var geometry: Node3D
var gameplay_layout: Node3D
var presentation: Node3D
var actors: Node3D
var interactables: Node3D
var navigation_region: NavigationRegion3D
var terminal_switch: LevelSwitch
var departure_switch: LevelSwitch

var _owner: Node3D
var _navigation_sources: Array[StaticBody3D] = []
var _materials: Dictionary = {}
var _floor_materials: Dictionary = {}
var _route_gates: Dictionary = {}
var _built := false
var _navigation_bake_started := false
var _navigation_bake_finished := false
var _navigation_bake_succeeded := false


func build(owner: Node3D) -> bool:
	if _built:
		return true
	if owner == null:
		return false
	_owner = owner
	gameplay_layout = owner.get_node_or_null("GameplayLayout") as Node3D
	if gameplay_layout == null:
		gameplay_layout = Node3D.new()
		gameplay_layout.name = "GameplayLayout"
		owner.add_child(gameplay_layout)
	geometry = Node3D.new()
	geometry.name = "CollisionAndNavigation"
	gameplay_layout.add_child(geometry)
	presentation = owner.get_node_or_null("Presentation") as Node3D
	if presentation == null:
		presentation = Node3D.new()
		presentation.name = "Presentation"
		owner.add_child(presentation)
	actors = Node3D.new()
	actors.name = "Actors"
	owner.add_child(actors)
	interactables = Node3D.new()
	interactables.name = "Interactables"
	owner.add_child(interactables)
	_build_environment()
	_build_route()
	_build_encounter_gates()
	_build_landmarks()
	_build_neighbourhood_detail()
	_build_story_objects()
	_build_navigation()
	_built = true
	return true


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
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
		var connector := _floor("RouteConnector", Vector3(0.0, -0.51, connector_z), Vector3(10.0, 0.96, 8.0), Color("46545a"), &"concrete")
		connector.add_to_group(&"rain_city_route_connectors")
	# Edge rails stop accidental route skips while leaving the authored forward path open.
	for section in [
		[11.0, -3.0, 34.0], [13.0, -36.0, 32.0], [17.0, -73.0, 42.0],
		[13.0, -111.0, 34.0],
	]:
		var x := float(section[0])
		var z := float(section[1])
		var length := float(section[2])
		_prop_box("RouteRail", Vector3(-x, 0.65, z), Vector3(0.45, 1.3, length), Color("25363b"), true)
		_prop_box("RouteRail", Vector3(x, 0.65, z), Vector3(0.45, 1.3, length), Color("25363b"), true)
	# The pier keeps authored rail gaps beside the harbour. Missing the safe lane drops
	# the player below the shared kill plane instead of creating an invisible wall.
	for rail_z in [-137.0, -158.0, -173.0]:
		_prop_box("PierLandRail", Vector3(-18.8, 0.65, rail_z), Vector3(0.45, 1.3, 12.0), Color("25363b"), true)
	for rail_z in [-137.0, -170.0]:
		_prop_box("PierWaterRail", Vector3(18.8, 0.65, rail_z), Vector3(0.45, 1.3, 10.0), Color("25363b"), true)
	# Secondary ground lanes retain a full lower accessibility route.
	_floor("AlleyParkingLeg", Vector3(6.0, -0.48, 3.5), Vector3(10.0, 0.96, 9.0), Color("343d43"), &"asphalt")
	_floor("SlicePlaza", Vector3(5.0, -0.46, -37.0), Vector3(12.0, 0.92, 15.0), Color("555158"), &"concrete")
	SpatialRouteBuilder.build(self)


func _build_landmarks() -> void:
	# Originalized silhouettes provide navigation anchors without reproducing real maps or logos.
	for z in [-8.0, -1.0, 7.0]:
		_prop_box("DowntownTower", Vector3(-7.8, 4.0, z), Vector3(4.5, 8.0, 5.0), Color("263b46"), true)
		_prop_box("DowntownTower", Vector3(7.8, 3.0, z - 3.0), Vector3(4.5, 6.0, 5.0), Color("314753"), true)
	_prop_box("RainCitySliceShop", Vector3(-8.5, 2.0, -37.0), Vector3(6.0, 4.0, 14.0), Color("7c3f38"), true)
	_sign(&"slice_storefront", "RAIN CITY SLICE\nHOT PIZZA • COLD COMPLIANCE", Vector3(-5.35, 2.6, -33.0), Vector3(0.0, 1.5, -33.0), Color("ffc65a"))
	_sign(&"slice_patio_notice", "SORRY — PATIO CLOSED\nDUE TO EXCESSIVE JOY", Vector3(5.8, 1.4, -43.0), Vector3(0.0, 1.4, -43.0), Color("e5f0df"))
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


func _build_encounter_gates() -> void:
	var gate_specs := {
		&"downtown_alley": Vector3(0.0, 1.45, -19.0),
		&"ruse_block": Vector3(0.0, 1.45, -53.0),
		&"waterfront_seawall": Vector3(0.0, 1.45, -95.0),
		&"terminal_service": Vector3(0.0, 1.45, -128.0),
	}
	for raw_zone_id in gate_specs:
		var zone_id := StringName(raw_zone_id)
		var gate := _prop_box(
			"EncounterGate_%s" % zone_id,
			gate_specs[zone_id],
			Vector3(9.6, 2.9, 0.45),
			Color("e6a53a"),
			true,
			true
		)
		gate.set_meta(&"encounter_gate_zone", zone_id)
		gate.add_to_group(&"rain_city_encounter_gates")
		_route_gates[zone_id] = gate


func set_route_gate_open(zone_id: StringName, is_open: bool) -> void:
	var gate := _route_gates.get(zone_id) as StaticBody3D
	if gate == null:
		return
	gate.collision_layer = 0 if is_open else 1
	gate.visible = not is_open
	for child in gate.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred("disabled", is_open)


func register_route_state_gate(route_state_id: StringName, gate: StaticBody3D) -> void:
	_route_gates[route_state_id] = gate


func is_route_gate_open(zone_id: StringName) -> bool:
	var gate := _route_gates.get(zone_id) as StaticBody3D
	return gate != null and gate.collision_layer == 0


func _build_neighbourhood_detail() -> void:
	# Downtown service texture: fire escapes, steam vents, dumpsters, and bike markings.
	for level in 3:
		_prop_box("FireEscapeLanding", Vector3(-7.1, 2.0 + level * 1.8, -7.0), Vector3(2.6, 0.18, 1.4), Color("39464b"), false)
		_prop_box("FireEscapeRail", Vector3(-7.1, 2.7 + level * 1.8, -7.65), Vector3(2.6, 1.2, 0.12), Color("607178"), false)
	_prop_box("DowntownDumpster", Vector3(7.0, 0.75, -10.0), Vector3(2.5, 1.5, 1.4), Color("315d53"), true)
	_prop_box("SteamVent", Vector3(3.0, 0.18, -15.5), Vector3(1.6, 0.25, 1.6), Color("7b8585"), false, true)
	_sign(&"alley_rain_notice", "RAIN DELAYED\nDUE TO RAIN", Vector3(6.7, 2.0, -1.0), Vector3(0.0, 1.5, -1.0), Color("ffe28a"))

	# Rain City Slice is warm, compact, and readable against the cool exterior.
	_prop_box("SliceAwning", Vector3(-5.2, 2.5, -37.0), Vector3(1.0, 0.25, 10.0), Color("d96b3f"), false, true)
	_prop_box("DeliveryScooter", Vector3(4.8, 0.55, -34.0), Vector3(0.8, 1.1, 1.8), Color("f0b840"), true)
	_prop_box("PizzaOven", Vector3(-9.2, 1.1, -43.0), Vector3(2.2, 2.2, 2.0), Color("884a38"), true, true)
	_sign(&"slice_delivery_window", "DELIVERY WINDOW\nRING BELL • RECEIVE JUSTICE", Vector3(-5.3, 1.4, -43.0), Vector3(0.0, 1.4, -43.0), Color("fff1c3"))

	# The seawall has a lower promenade and a glass-canopy upper terrace.
	for z in [-64.0, -72.0, -80.0, -88.0]:
		_prop_box("SeawallBench", Vector3(8.5, 0.45, z), Vector3(2.4, 0.55, 0.7), Color("8a6848"), true)
	for z in [-69.0, -81.0]:
		_prop_box("GlassCanopyPost", Vector3(-12.0, 2.6, z), Vector3(0.18, 5.2, 0.18), Color("8fb8c2"), false, true)
		_prop_box("GlassCanopy", Vector3(-9.5, 4.9, z), Vector3(5.2, 0.16, 4.2), Color(0.35, 0.62, 0.70, 0.58), false, true)
	_sign(&"seawall_speed_limit", "SEAWALL SPEED LIMIT:\nZOOMIES", Vector3(12.3, 1.5, -69.0), Vector3(0.0, 1.5, -69.0), Color("f9df83"))
	_sign(&"seawall_harbour_notice", "NO FETCHING\nFROM THE HARBOUR", Vector3(16.0, 1.5, -88.0), Vector3(0.0, 1.5, -88.0), Color("ff9d70"))

	# Terminal machinery frames an interior/exterior loop and elevated control booth.
	_prop_box("TerminalShellLeft", Vector3(-11.0, 3.0, -112.0), Vector3(1.0, 6.0, 25.0), Color("38474d"), true)
	_prop_box("TerminalShellRight", Vector3(11.0, 3.0, -112.0), Vector3(1.0, 6.0, 25.0), Color("38474d"), true)
	_prop_box("TerminalControlBooth", Vector3(-8.5, 3.1, -116.0), Vector3(5.0, 3.4, 7.0), Color("526c72"), true)
	for z in [-102.0, -110.0, -121.0]:
		_prop_box("CargoMachine", Vector3(5.7, 1.2, z), Vector3(3.0, 2.4, 2.2), Color("566167"), true)
	_sign(&"terminal_cargo_routing", "CARGO ROUTING:\nDOGS FIRST • FORMS LAST", Vector3(-5.9, 2.4, -118.0), Vector3(0.0, 1.5, -118.0), Color("bce9dc"))
	_sign(&"terminal_authorized_dog", "AUTHORIZED PERSONNEL\nAND ONE VERY GOOD DOG", Vector3(10.3, 1.7, -103.0), Vector3(0.0, 1.5, -103.0), Color("f5d68a"))

	# Pier shapes a broad boss loop with obvious cover hierarchy and crane flank.
	for x in [-13.0, -6.0, 5.0, 12.0]:
		_prop_box("PierBollard", Vector3(x, 0.65, -169.0), Vector3(0.7, 1.3, 0.7), Color("d8a13d"), true)
	_prop_box("TowmasterDepartureControl", Vector3(0.0, 1.6, -174.0), Vector3(3.2, 3.2, 1.4), Color("2d5159"), true, true)
	_sign(&"pier_appeals_window", "APPEALS WINDOW\nCLOSED FOR LUNCH SINCE 1998", Vector3(-15.2, 2.0, -161.0), Vector3(0.0, 1.5, -161.0), Color("ffd16c"))
	_sign(&"pier_404", "PIER 404:\nBOAT NOT FOUND", Vector3(15.2, 1.6, -151.0), Vector3(0.0, 1.5, -151.0), Color("bbf1ea"))
	_sign(&"pier_final_notice", "FINAL NOTICE:\nEXCESSIVE TAIL WAGGING", Vector3(0.0, 2.2, -166.0), Vector3(0.0, 1.5, -155.0), Color("ff975d"))


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
	departure_switch.enabled = false
	departure_switch.position = Vector3(0.0, 1.2, -173.0)
	departure_switch.activated.connect(_on_switch_activated)
	interactables.add_child(departure_switch)
	_sign(&"pier_convoy_notice", "CITATION CONVOY\nPARKING JOY IS A TOWABLE OFFENCE", Vector3(0, 2.2, -137), Vector3(0.0, 1.5, -131.0), Color("ffb33b"))


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
	if build_navigation:
		call_deferred("_bake_navigation")


func _bake_navigation() -> void:
	if _navigation_bake_started or _navigation_bake_finished:
		return
	_navigation_bake_started = true
	if not is_instance_valid(navigation_region):
		_finish_navigation_bake(false)
		return
	navigation_region.bake_navigation_mesh(false)
	var navigation_map := navigation_region.get_navigation_map()
	NavigationServer3D.region_set_map(navigation_region.get_rid(), navigation_map)
	NavigationServer3D.region_set_navigation_mesh(navigation_region.get_rid(), navigation_region.navigation_mesh)
	NavigationServer3D.map_set_active(navigation_map, true)
	NavigationServer3D.map_force_update(navigation_map)
	_finish_navigation_bake(navigation_region.navigation_mesh.get_polygon_count() > 0)
	# Navigation sources are the authoritative gameplay floors. Removing them after
	# baking used to make the level appear stable briefly and then drop actors and
	# pickups through the world. Keep them owned by AuthoredGameplayLayout.


func navigation_bake_status() -> Dictionary:
	var polygon_count := 0
	if is_instance_valid(navigation_region) and navigation_region.navigation_mesh != null:
		polygon_count = navigation_region.navigation_mesh.get_polygon_count()
	return {
		"requested": build_navigation,
		"started": _navigation_bake_started,
		"finished": _navigation_bake_finished,
		"succeeded": _navigation_bake_succeeded,
		"polygon_count": polygon_count,
	}


func _finish_navigation_bake(succeeded: bool) -> void:
	_navigation_bake_finished = true
	_navigation_bake_succeeded = succeeded
	var polygon_count := 0
	if is_instance_valid(navigation_region) and navigation_region.navigation_mesh != null:
		polygon_count = navigation_region.navigation_mesh.get_polygon_count()
	navigation_bake_completed.emit(succeeded, polygon_count)


func _floor(node_name: String, position: Vector3, size: Vector3, color: Color, surface_id: StringName) -> StaticBody3D:
	var body := _prop_box(node_name, position, size, color, true)
	var mesh_instance := body.get_child(0) as MeshInstance3D
	var production_material := _route_floor_material(surface_id)
	if mesh_instance != null and production_material != null:
		mesh_instance.material_override = production_material
	body.add_to_group(&"vancouver_navigation_source")
	body.set_meta(&"surface_id", surface_id)
	body.collision_layer = NAVIGATION_SOURCE_LAYER | 1
	_navigation_sources.append(body)
	return body


func _route_floor_material(surface_id: StringName) -> StandardMaterial3D:
	if _floor_materials.has(surface_id):
		return _floor_materials[surface_id] as StandardMaterial3D
	var source := SURFACE_MATERIALS.get(surface_id) as StandardMaterial3D
	if source == null:
		return null
	var lightweight := source.duplicate() as StandardMaterial3D
	# Large route floors keep the distinctive albedo but avoid three extra texture
	# samples over most of the screen. Full normal/ORM families remain on the
	# authored presentation batches where they materially affect the silhouette.
	lightweight.normal_enabled = false
	lightweight.ao_enabled = false
	lightweight.orm_texture = null
	lightweight.metallic = 0.0
	_floor_materials[surface_id] = lightweight
	return lightweight


func _prop_box(node_name: String, position: Vector3, size: Vector3, color: Color, collision := false, emissive := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1 if collision else 0
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var material := _shared_material(color, emissive)
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
	var parent := geometry if collision else presentation
	parent.add_child(body)
	return body


func _shared_material(color: Color, emissive: bool) -> StandardMaterial3D:
	var key := "%s:%s" % [color.to_html(true), str(emissive)]
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	material.metallic = 0.12 if emissive else 0.0
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b, 1.0) * 0.45
	_materials[key] = material
	return material


func _sign(id: StringName, text: String, position: Vector3, route_anchor: Vector3, color: Color) -> void:
	var sign := AuthoredWorldSign.new()
	sign.name = "RainCitySign_%s" % id
	sign.configure(id, text, position, route_anchor, color)
	sign.add_to_group(&"authored_world_signs")
	presentation.add_child(sign)


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
