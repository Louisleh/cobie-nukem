class_name MountHoodWorldBuilder
extends Node

signal navigation_bake_completed(success: bool)

const CheckpointScene = preload("res://scenes/interactables/level_checkpoint.tscn")
const SwitchScene = preload("res://scenes/interactables/level_switch.tscn")
const ZoneScene = preload("res://scenes/interactables/zone_trigger.tscn")
const GoldenBallScene = preload("res://scenes/interactables/golden_ball_finale.tscn")
const SURFACE_MATERIALS := {
	&"packed_snow": preload("res://assets/materials/mount_hood/packed_snow.tres"),
	&"powder": preload("res://assets/materials/mount_hood/fresh_powder.tres"),
	&"ice": preload("res://assets/materials/mount_hood/icy_slush.tres"),
	&"asphalt": preload("res://assets/materials/mount_hood/plowed_asphalt.tres"),
	&"timber": preload("res://assets/materials/mount_hood/lodge_timber.tres"),
	&"stone": preload("res://assets/materials/mount_hood/lodge_stone.tres"),
	&"steel": preload("res://assets/materials/mount_hood/lift_steel.tres"),
}

var on_zone_entered: Callable
var on_checkpoint_activated: Callable
var on_objective_action: Callable
var on_narrative_message: Callable
var on_golden_ball_claimed: Callable
@export var build_navigation := true

var geometry: Node3D
var presentation: Node3D
var actors: Node3D
var interactables: Node3D
var navigation_region: NavigationRegion3D
var lodge_power_switch: LevelSwitch
var chairlift_power_switch: LevelSwitch
var summit_relay_switch: LevelSwitch
var chairlift: MountHoodChairlift
var golden_ball: GoldenBallFinale
var _owner: Node3D
var _materials: Dictionary = {}
var _route_gates: Dictionary = {}


func build(owner: Node3D) -> bool:
	if owner == null: return false
	_owner = owner
	geometry = Node3D.new(); geometry.name = "AuthoredGameplayLayout"; owner.add_child(geometry)
	presentation = Node3D.new(); presentation.name = "MountHoodPresentation"; owner.add_child(presentation)
	actors = Node3D.new(); actors.name = "Actors"; owner.add_child(actors)
	interactables = Node3D.new(); interactables.name = "Interactables"; owner.add_child(interactables)
	_build_environment()
	_build_route()
	_build_landmarks()
	_build_story_objects()
	_build_navigation()
	return true


func _build_environment() -> void:
	var world := WorldEnvironment.new(); world.name = "WorldEnvironment"
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("5d7692"); sky_material.sky_horizon_color = Color("c8d7df")
	sky_material.ground_bottom_color = Color("263847"); sky_material.ground_horizon_color = Color("96aab5")
	var sky := Sky.new(); sky.sky_material = sky_material
	var environment := Environment.new(); environment.background_mode = Environment.BG_SKY; environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; environment.ambient_light_energy = 0.72
	environment.fog_enabled = true; environment.fog_light_color = Color("b7c9d2"); environment.fog_density = 0.008
	world.environment = environment; _owner.add_child(world)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-48, -24, 0); light.light_color = Color("e7f2ff"); light.light_energy = 1.2; light.shadow_enabled = true; _owner.add_child(light)


func _build_route() -> void:
	_floor("ForestPullout", Vector3(0, -0.5, -3), Vector3(22, 1, 34), &"packed_snow")
	_floor("MountainRoad", Vector3(0, -0.5, -39), Vector3(26, 1, 36), &"asphalt")
	_floor("SnowboundLodge", Vector3(0, -0.5, -77), Vector3(30, 1, 40), &"packed_snow")
	_floor("ServiceTunnels", Vector3(0, -0.5, -116), Vector3(22, 1, 36), &"stone")
	_floor("Summit", Vector3(0, -0.5, -158), Vector3(38, 1, 50), &"packed_snow")
	for connector_z in [-20.0, -58.0, -97.0, -136.0]:
		# Connector top sits 3 cm below the zone slabs: enough overlap for nav,
		# never an exactly coplanar visible face that can flicker in WebGL.
		var connector := _floor("RouteConnector", Vector3(0, -0.52, connector_z), Vector3(10, 0.98, 8), &"packed_snow")
		connector.add_to_group(&"mount_hood_route_connectors")
	# Authored traction patches are large and readable; none overlap coplanarly.
	_floor("PowderTutorial", Vector3(-6, 0.03, -8), Vector3(6, 0.12, 9), &"powder")
	_floor("IcyRoadBend", Vector3(6, 0.03, -43), Vector3(7, 0.12, 10), &"ice")
	for spec in [[12.0, -3.0, 34.0], [14.0, -39.0, 36.0], [16.0, -77.0, 40.0], [12.0, -116.0, 36.0]]:
		_snowbank(Vector3(-float(spec[0]), 0.65, float(spec[1])), Vector3(2.0, 1.3, float(spec[2])))
		_snowbank(Vector3(float(spec[0]), 0.65, float(spec[1])), Vector3(2.0, 1.3, float(spec[2])))
	for gate in [[&"forest_pullout", -20.0], [&"mountain_road", -58.0], [&"snowbound_lodge", -97.0], [&"service_tunnels", -136.0]]:
		var body := _box("EncounterGate_%s" % gate[0], Vector3(0, 1.45, gate[1]), Vector3(9.6, 2.9, 0.45), &"steel", true, true)
		body.set_meta(&"encounter_gate_zone", gate[0]); _route_gates[gate[0]] = body


func _build_landmarks() -> void:
	# Persistent original low-poly mountain, presentation only and fixed north.
	var mountain := MeshInstance3D.new(); mountain.name = "PersistentMountHood"
	var ridge := PrismMesh.new(); ridge.size = Vector3(70, 42, 18); mountain.mesh = ridge
	mountain.position = Vector3(0, 19, -226); mountain.material_override = _material(&"powder"); presentation.add_child(mountain)
	for z in [-12, -31, -48, -69, -91, -128, -148, -174]:
		_fir(Vector3(-9.0 if z % 2 == 0 else 9.0, 0, z), 3.5 + abs(z % 3))
	# Lodge modules and warm windows create the mission's central refuge.
	_box("LodgeStoneBase", Vector3(-5, 1.4, -79), Vector3(12, 2.8, 14), &"stone", true)
	_box("LodgeTimberUpper", Vector3(-5, 4.0, -79), Vector3(12, 2.4, 14), &"timber", true)
	_box("LodgeWarmWindow", Vector3(1.1, 3.8, -75), Vector3(0.15, 1.4, 3.2), &"warm", false, true)
	_sign(&"lodge_notice", "TIMBERLINE-ish LODGE\nDOGS CHECK IN FREE", Vector3(1.25, 2.4, -82), Vector3(0, 1.5, -72), Color("ffd277"))
	# Service tunnel shell and lift vocabulary.
	for x in [-9.5, 9.5]: _box("TunnelWall", Vector3(x, 2.2, -116), Vector3(1, 4.4, 36), &"stone", true)
	for z in [-105, -116, -127]: _box("LiftMachine", Vector3(6.5, 1.2, z), Vector3(3, 2.4, 2), &"steel", true)
	for z in [-137, -151, -166]:
		_box("LiftTower", Vector3(-10, 5, z), Vector3(0.8, 10, 0.8), &"steel", false)
		_box("LiftCrossbeam", Vector3(-10, 9.2, z), Vector3(7, 0.5, 0.5), &"steel", false)
	# Cute authored snowmen and route humor.
	_snowman(Vector3(6, 0, 3)); _snowman(Vector3(-10, 0, -72))
	_sign(&"pullout_sign", "SANDY-ish 38 MI\nSUMMIT ZOOMIES 12 MI", Vector3(7.5, 2.2, 5), Vector3(0, 1.5, -4), Color("d9f1ff"))
	_sign(&"road_sign", "CHAINS REQUIRED\nCOLLARS OPTIONAL", Vector3(-10.5, 2.1, -39), Vector3(0, 1.5, -39), Color("ffe07d"))
	_sign(&"summit_sign", "OFF-LEASH SUMMIT\nWEATHER PERMIT DENIED", Vector3(0, 2.2, -140), Vector3(0, 1.5, -150), Color("ffbc5c"))


func _build_story_objects() -> void:
	var zones := [
		[&"forest_pullout", "FOREST PULLOUT", Vector3(0, 1.5, 10), Vector3(20, 4, 4)],
		[&"mountain_road", "PLOWED MOUNTAIN ROAD", Vector3(0, 1.5, -20), Vector3(24, 4, 4)],
		[&"snowbound_lodge", "SNOWBOUND LODGE", Vector3(0, 1.5, -58), Vector3(28, 4, 4)],
		[&"service_tunnels", "SERVICE TUNNELS", Vector3(0, 1.5, -97), Vector3(20, 4, 4)],
		[&"summit", "OFF-LEASH SUMMIT", Vector3(0, 1.5, -136), Vector3(36, 4, 4)],
	]
	for data in zones:
		var trigger := ZoneScene.instantiate() as LevelZoneTrigger; trigger.zone_id = data[0]; trigger.title = data[1]; trigger.position = data[2]; trigger.trigger_size = data[3]; trigger.entered.connect(_on_zone); interactables.add_child(trigger)
	var checkpoints := [[&"checkpoint_forest_start", Vector3(0, 0, 8)], [&"checkpoint_road_clear", Vector3(0, 0, -23)], [&"checkpoint_lodge_power", Vector3(0, 0, -61)], [&"checkpoint_lift_restored", Vector3(0, 0, -100)], [&"checkpoint_summit_arrival", Vector3(0, 0, -139)]]
	for data in checkpoints:
		var checkpoint := CheckpointScene.instantiate() as LevelCheckpoint; checkpoint.checkpoint_id = data[0]; checkpoint.position = data[1]; checkpoint.activated.connect(_on_checkpoint); interactables.add_child(checkpoint)
	lodge_power_switch = _switch(&"lodge_power", "RESTORE LODGE POWER", Vector3(5, 1.2, -86))
	chairlift_power_switch = _switch(&"chairlift_power", "RESTART CHAIRLIFT", Vector3(-6, 1.2, -123))
	summit_relay_switch = _switch(&"summit_relay", "DISABLE WEATHER RELAY", Vector3(7, 1.2, -171))
	_switch(&"secret_snowman_nose", "BOOP THE VERY COLD NOSE", Vector3(6, 1.25, 3.0))
	_switch(&"secret_treat_pantry", "OPEN GOOD-DOG TREAT PANTRY", Vector3(-12.5, 1.2, -83.0))
	_switch(&"secret_service_valves", "SET VALVES TO ZOOMIES", Vector3(8.0, 1.2, -111.0))
	_switch(&"secret_good_dog_seat", "CLAIM GOOD-DOG CHAIR", Vector3(-8.0, 1.2, -128.0))
	chairlift = MountHoodChairlift.new(); chairlift.name = "Chairlift"; chairlift.position = Vector3(-8, 1.2, -129); chairlift.end_position = Vector3(-8, 1.2, -153); chairlift.ride_started.connect(_on_lift_started); chairlift.ride_completed.connect(_on_lift_completed); interactables.add_child(chairlift)
	golden_ball = GoldenBallScene.instantiate() as GoldenBallFinale; golden_ball.position = Vector3(0, 1.2, -174); golden_ball.claimed.connect(_on_ball_claimed); interactables.add_child(golden_ball)


func set_route_gate_open(zone_id: StringName, open: bool) -> void:
	var gate := _route_gates.get(zone_id) as StaticBody3D
	if gate == null: return
	gate.visible = not open; gate.collision_layer = 0 if open else 1
	for child in gate.get_children():
		if child is CollisionShape3D: (child as CollisionShape3D).set_deferred("disabled", open)


func is_route_gate_open(zone_id: StringName) -> bool:
	var gate := _route_gates.get(zone_id) as StaticBody3D
	return gate != null and gate.collision_layer == 0


func enable_golden_ball() -> void:
	if golden_ball != null: golden_ball.enable_as_reward()


func reset_chairlift() -> void:
	if chairlift != null: chairlift.reset_lift()


func _build_navigation() -> void:
	navigation_region = NavigationRegion3D.new(); navigation_region.name = "MountHoodNavigation"
	var mesh := NavigationMesh.new(); mesh.agent_radius = 0.5; mesh.agent_height = 2.0; mesh.agent_max_climb = 0.5; mesh.agent_max_slope = 45.0; mesh.cell_size = 0.25; mesh.cell_height = 0.25
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS; mesh.geometry_collision_mask = 1 << 19
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	mesh.geometry_source_group_name = &"mount_hood_navigation_source"
	mesh.filter_baking_aabb = AABB(Vector3(-20, -1.2, -184), Vector3(40, 5, 198)); navigation_region.navigation_mesh = mesh; _owner.add_child(navigation_region)
	if build_navigation: call_deferred("_bake_navigation")


func _bake_navigation() -> void:
	navigation_region.bake_navigation_mesh(false)
	var navigation_map := navigation_region.get_navigation_map()
	NavigationServer3D.region_set_map(navigation_region.get_rid(), navigation_map)
	NavigationServer3D.region_set_navigation_mesh(navigation_region.get_rid(), navigation_region.navigation_mesh)
	NavigationServer3D.map_set_active(navigation_map, true)
	NavigationServer3D.map_force_update(navigation_map)
	navigation_bake_completed.emit(navigation_region.navigation_mesh.get_polygon_count() > 0)


func _floor(name_value: String, at: Vector3, size: Vector3, surface: StringName) -> StaticBody3D:
	var body := _box(name_value, at, size, surface, true)
	body.collision_layer = (1 << 19) | 1; body.set_meta(&"surface_type", surface); body.add_to_group(&"mount_hood_navigation_source")
	return body


func _box(name_value: String, at: Vector3, size: Vector3, family: StringName, collision: bool, emissive := false) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = name_value; body.position = at; body.collision_layer = 1 if collision else 0
	var mesh_instance := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size; mesh_instance.mesh = mesh; mesh_instance.material_override = _material(family, emissive); body.add_child(mesh_instance)
	if collision:
		var shape := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = size; shape.shape = box_shape; body.add_child(shape)
	(geometry if collision else presentation).add_child(body); return body


func _snowbank(at: Vector3, size: Vector3) -> void:
	_box("AuthoredSnowbank", at, size, &"powder", true)


func _fir(at: Vector3, height: float) -> void:
	var root := Node3D.new(); root.name = "Fir"; root.position = at; presentation.add_child(root)
	var trunk := MeshInstance3D.new(); var cylinder := CylinderMesh.new(); cylinder.top_radius = 0.16; cylinder.bottom_radius = 0.24; cylinder.height = height * 0.55; trunk.mesh = cylinder; trunk.position.y = height * 0.28; trunk.material_override = _color_material(Color("513b2b")); root.add_child(trunk)
	for tier in 3:
		var crown := MeshInstance3D.new(); var cone := CylinderMesh.new(); cone.top_radius = 0.0; cone.bottom_radius = 1.2 - tier * 0.2; cone.height = height * 0.45; crown.mesh = cone; crown.position.y = height * (0.42 + tier * 0.19); crown.material_override = _color_material(Color("173e38")); root.add_child(crown)


func _snowman(at: Vector3) -> void:
	var root := Node3D.new(); root.name = "GoodDogSnowman"; root.position = at; presentation.add_child(root)
	for data in [[0.0, 0.65, 0.7], [0.0, 1.55, 0.48]]:
		var part := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = data[2]; sphere.height = data[2] * 2.0; part.mesh = sphere; part.position.y = data[1]; part.material_override = _material(&"powder"); root.add_child(part)


func _sign(id: StringName, value: String, at: Vector3, route_anchor: Vector3, color: Color) -> void:
	var sign := AuthoredWorldSign.new(); sign.configure(id, value, at, route_anchor, color); sign.add_to_group(&"authored_world_signs"); presentation.add_child(sign)


func _switch(id: StringName, prompt_value: String, at: Vector3) -> LevelSwitch:
	var result := SwitchScene.instantiate() as LevelSwitch; result.switch_id = id; result.prompt = prompt_value; result.position = at; result.activated.connect(_on_switch); interactables.add_child(result); return result


func _material(family: StringName, emissive := false) -> StandardMaterial3D:
	if family == &"warm":
		return preload("res://assets/materials/mount_hood/warm_windows.tres")
	var material := SURFACE_MATERIALS.get(family) as StandardMaterial3D
	if material != null: return material
	return _color_material(Color("92a8b4"), emissive)


func _color_material(color: Color, emissive := false) -> StandardMaterial3D:
	var key := color.to_html(true) + str(emissive)
	if _materials.has(key): return _materials[key]
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.82
	if emissive: material.emission_enabled = true; material.emission = color * 0.5
	_materials[key] = material; return material


func _on_zone(id: StringName, title: String, actor: Node) -> void:
	if on_zone_entered.is_valid(): on_zone_entered.call(id, title, actor)
func _on_checkpoint(id: StringName, at: Vector3) -> void:
	if on_checkpoint_activated.is_valid(): on_checkpoint_activated.call(id, at)
func _on_switch(id: StringName, _actor: Node) -> void:
	if id == &"chairlift_power" and chairlift != null: chairlift.set_enabled(true)
	if on_objective_action.is_valid(): on_objective_action.call(ObjectiveDefinition.Kind.ACTIVATE, id)
	if on_narrative_message.is_valid(): on_narrative_message.call("%s // COMPLETE" % String(id).replace("_", " ").to_upper(), 2.5)
func _on_lift_started() -> void:
	if on_narrative_message.is_valid(): on_narrative_message.call("CHAIRLIFT MOVING // HOLD ON, GOOD DOG.", 2.5)
func _on_lift_completed() -> void:
	if on_narrative_message.is_valid(): on_narrative_message.call("SUMMIT ARRIVAL // WHITEOUT WARNING.", 2.5)
func _on_ball_claimed(actor: Node) -> void:
	if on_golden_ball_claimed.is_valid(): on_golden_ball_claimed.call(actor)
