class_name SalmonCreekWorldBuilder
extends Node

const DoorScene = preload("res://scenes/interactables/level_door.tscn")
const SwitchScene = preload("res://scenes/interactables/level_switch.tscn")
const SignScene = preload("res://scenes/interactables/narrative_sign.tscn")
const WallScene = preload("res://scenes/interactables/breakable_secret_wall.tscn")
const CheckpointScene = preload("res://scenes/interactables/level_checkpoint.tscn")
const ZoneScene = preload("res://scenes/interactables/zone_trigger.tscn")
const BallReturnScene = preload("res://scenes/interactables/ball_return_secret.tscn")
const GoldenBallScene = preload("res://scenes/interactables/golden_ball_finale.tscn")

const NAVIGATION_SOURCE_LAYER := 1 << 19

var pickup_spawn_callable: Callable
var on_zone_entered: Callable
var on_narrative_message: Callable
var on_sign_read: Callable
var on_secret_discovered: Callable
var on_objective_action: Callable
var on_checkpoint_activated: Callable
var on_golden_ball_claimed: Callable

var geometry: Node3D
var actors: Node3D
var interactables: Node3D
var golden_ball: GoldenBallFinale
var navigation_region: NavigationRegion3D

var _navigation_sources: Array[StaticBody3D] = []
var _build_parent: Node
var _is_built := false
var _pickups_populated := false


func build(owner: Node) -> void:
	if _is_built:
		return
	_build_parent = owner
	geometry = Node3D.new()
	geometry.name = "Geometry"
	owner.add_child(geometry)
	actors = Node3D.new()
	actors.name = "Actors"
	owner.add_child(actors)
	interactables = Node3D.new()
	interactables.name = "Interactables"
	owner.add_child(interactables)
	_build_lighting()
	_build_route_geometry()
	_build_navigation()
	_build_field_dressing()
	_build_story_objects()
	_build_zone_triggers()
	_is_built = true


func populate_pickups() -> void:
	if not _is_built:
		push_error("SalmonCreekWorldBuilder.populate_pickups called before build")
		return
	if _pickups_populated:
		return
	_pickups_populated = true
	_build_pickups()


func _build_lighting() -> void:
	var environment := WorldEnvironment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("101c29")
	sky_material.sky_horizon_color = Color("52666d")
	sky_material.ground_bottom_color = Color("111b1d")
	sky_material.ground_horizon_color = Color("46595a")
	sky_material.sun_angle_max = 8.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color("8da399")
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color("667a78")
	env.fog_density = 0.012
	env.fog_aerial_perspective = 0.7
	environment.environment = env
	_build_parent.add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-58, -25, 0)
	moon.light_color = Color("a9c5d6")
	moon.light_energy = 1.1
	moon.shadow_enabled = true
	_build_parent.add_child(moon)


func _build_route_geometry() -> void:
	_box("WetSportsField", Vector3(0, -0.5, 0), Vector3(26, 1, 36), Color("315448"), &"soil")
	_box("ShedFloor", Vector3(0, -0.5, -32), Vector3(15, 1, 25), Color("495057"), &"wood")
	_box("TunnelFloor", Vector3(0, -0.5, -64), Vector3(10, 1, 39), Color("37474f"))
	_box("LabFloor", Vector3(0, -0.5, -103), Vector3(24, 1, 38), Color("56636a"))
	_box("DogParkFloor", Vector3(22, -0.5, -103), Vector3(18, 1, 22), Color("3d6b45"))
	_box("SecretDogParkBridge", Vector3(12.5, -0.5, -103), Vector3(2, 1, 6), Color("46634f"))
	_box("ArenaFloor", Vector3(0, -0.5, -147), Vector3(36, 1, 40), Color("514444"))
	_box("ConnectorA", Vector3(0, -0.5, -20), Vector3(8, 1, 5), Color("555b60"))
	_box("ConnectorB", Vector3(0, -0.5, -45), Vector3(8, 1, 4), Color("414b50"))
	_box("ConnectorC", Vector3(0, -0.5, -84), Vector3(8, 1, 4), Color("4b575d"))
	# Overlap the arena floor by more than one agent diameter. The previous
	# half-metre visual seam became a disconnected island after radius erosion.
	_box("ConnectorD", Vector3(0, -0.5, -124), Vector3(10, 1, 8), Color("564949"))
	# Side boundaries leave the main route readable while stopping accidental skips.
	_wall_pair(13, 0, 36)
	_wall_pair(7.5, -32, 25)
	_wall_pair(5, -64, 39)
	# Split the lab's east wall around the breakable panel. The previous full
	# boundary left invisible collision behind after the panel disappeared.
	_box("LabWestBoundary", Vector3(-12, 2, -103), Vector3(0.6, 4, 38), Color("34434a"))
	_box("LabEastBoundaryRear", Vector3(12, 2, -113.75), Vector3(0.6, 4, 16.5), Color("34434a"))
	_box("LabEastBoundaryFront", Vector3(12, 2, -92.25), Vector3(0.6, 4, 15.5), Color("34434a"))
	_wall_pair(18, -147, 40)
	# Tunnels and lab receive low ceilings; exterior zones remain storm-open.
	_box("TunnelCeiling", Vector3(0, 4.2, -64), Vector3(10, 0.5, 39), Color("29353a"))
	_box("LabCeiling", Vector3(0, 5.0, -103), Vector3(24, 0.5, 38), Color("39464c"))
	_box("ShedRoof", Vector3(0, 4.5, -32), Vector3(15, 0.45, 25), Color("293338"))
	# Arena cover makes the boss readable under flight-stick auto-aim.
	for pos in [Vector3(-10, 1, -140), Vector3(10, 1, -140), Vector3(-10, 1, -156), Vector3(10, 1, -156)]:
		_box("ArenaCover", pos, Vector3(3, 2, 3), Color("70584d"))


func _build_navigation() -> void:
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "GroundNavigation"
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.agent_radius = 0.5
	navigation_mesh.agent_height = 2.0
	navigation_mesh.agent_max_climb = 0.5
	navigation_mesh.agent_max_slope = 45.0
	navigation_mesh.cell_size = 0.25
	navigation_mesh.cell_height = 0.25
	navigation_mesh.region_min_size = 1.0
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_mesh.geometry_collision_mask = NAVIGATION_SOURCE_LAYER
	navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	navigation_mesh.geometry_source_group_name = &"salmon_navigation_source"
	# Keep ceiling and roof tops out of the traversable set while covering every
	# authored route zone and the secret dog-park bridge.
	navigation_mesh.filter_baking_aabb = AABB(Vector3(-20.0, -1.1, -170.0), Vector3(40.0, 4.0, 190.0))
	navigation_region.navigation_mesh = navigation_mesh
	_build_parent.add_child(navigation_region)
	# CSG collision/meshes finish synchronizing after this construction pass.
	# Defer one turn, then bake synchronously so native and single-threaded Web
	# builds share the same deterministic map. Enemies retain direct steering for
	# that first turn and switch to paths as soon as the map iteration is ready.
	call_deferred("_bake_navigation")


func _bake_navigation() -> void:
	if is_instance_valid(navigation_region):
		navigation_region.bake_navigation_mesh(false)
		# Assign the completed resource to the server RID explicitly. Linux
		# headless otherwise defers the node's resource-change notification beyond
		# a physics-only test loop, while macOS applies it in the same turn.
		var navigation_map := navigation_region.get_navigation_map()
		NavigationServer3D.region_set_map(navigation_region.get_rid(), navigation_map)
		NavigationServer3D.region_set_navigation_mesh(navigation_region.get_rid(), navigation_region.navigation_mesh)
		NavigationServer3D.map_set_active(navigation_map, true)
		NavigationServer3D.map_force_update(navigation_map)
	for source in _navigation_sources:
		if is_instance_valid(source):
			source.queue_free()
	_navigation_sources.clear()


func _build_field_dressing() -> void:
	# Bold markings and silhouettes give the opening field immediate scale and
	# navigation cues even at the low internal render resolution.
	for z in [-12.0, -4.0, 4.0, 12.0]:
		_prop_box("FieldStripe", Vector3(0, 0.025, z), Vector3(23, 0.035, 0.10), Color("b7c9aa"))
	for x in [-10.0, 10.0]:
		_prop_box("Touchline", Vector3(x, 0.03, 0), Vector3(0.10, 0.04, 32), Color("b7c9aa"))
	for x in [-5.0, 5.0]:
		_prop_box("GoalPost", Vector3(x, 1.4, -15.5), Vector3(0.14, 2.8, 0.14), Color("d9ddd0"))
	_prop_box("GoalBar", Vector3(0, 2.75, -15.5), Vector3(10.1, 0.14, 0.14), Color("d9ddd0"))
	for index in 5:
		var x := -9.0 + index * 1.15
		_prop_box("SafetyCone", Vector3(x, 0.28, 7.5), Vector3(0.28, 0.56, 0.28), Color("e67924"))
	for row in 3:
		_prop_box("Bleacher", Vector3(9.8, 0.35 + row * 0.38, 6.5 + row * 0.55), Vector3(4.2, 0.18, 0.65), Color("68777a"))


func _build_story_objects() -> void:
	var opening_sign := SignScene.instantiate() as NarrativeSign
	opening_sign.sign_id = &"no_animals"
	opening_sign.sign_text = "NO ANIMALS\nON SPORTS FIELD"
	opening_sign.secret_after_reads = 3
	opening_sign.secret_id = &"optional_sign"
	opening_sign.secret_title = "SIGN SEEMS OPTIONAL"
	opening_sign.position = Vector3(-5, 1.4, 5.5)
	opening_sign.rotation_degrees.y = 0
	opening_sign.read.connect(_on_sign_read)
	opening_sign.secret_requested.connect(_on_secret_discovered)
	interactables.add_child(opening_sign)
	_sign("MUTANT-FREE ZONE\n(Inspection Pending)", Vector3(5, 1.5, -27), 180)
	_sign("LEASH LENGTH SUBJECT TO\nALGORITHMIC REVIEW", Vector3(-4, 1.5, -58), 180)
	_sign("GOOD DOG STATUS:\nREVOKED", Vector3(6, 1.5, -91), 180)
	_sign("EMPLOYEE OF THE MONTH:\nVACUUM CLEANER", Vector3(-7, 1.5, -108), 180)
	_sign("JOY EVENT DETECTED.\nINCIDENT CREATED.", Vector3(7, 1.5, -116), 180)
	_sign("FETCH THIS!", Vector3(0, 2.0, -164), 180)

	var shed_gate := DoorScene.instantiate() as LevelDoor
	shed_gate.name = "ShedGate"
	shed_gate.position = Vector3(0, 2, -19)
	shed_gate.size = Vector3(8, 4, 0.6)
	shed_gate.access_denied.connect(_on_narrative_request)
	interactables.add_child(shed_gate)
	var tunnel_gate := DoorScene.instantiate() as LevelDoor
	tunnel_gate.name = "TunnelGate"
	tunnel_gate.position = Vector3(0, 2, -44)
	tunnel_gate.size = Vector3(8, 4, 0.6)
	tunnel_gate.starts_locked = true
	tunnel_gate.access_denied.connect(_on_narrative_request)
	interactables.add_child(tunnel_gate)
	var shed_switch := SwitchScene.instantiate() as LevelSwitch
	shed_switch.switch_id = &"shed_power"
	shed_switch.position = Vector3(-5.8, 1.2, -39)
	interactables.add_child(shed_switch)
	shed_switch.target_path = shed_switch.get_path_to(tunnel_gate)
	shed_switch.activated.connect(_on_shed_switch_activated)
	var lab_gate := DoorScene.instantiate() as LevelDoor
	lab_gate.name = "LabGate"
	lab_gate.position = Vector3(0, 2, -83)
	lab_gate.size = Vector3(8, 4, 0.6)
	lab_gate.requires_access_collar = true
	lab_gate.locked_message = "ACCESS COLLAR REQUIRED. NO EXCEPTIONS, EXCEPT COBIE."
	lab_gate.access_denied.connect(_on_narrative_request)
	interactables.add_child(lab_gate)
	var arena_gate := DoorScene.instantiate() as LevelDoor
	arena_gate.name = "ArenaGate"
	arena_gate.position = Vector3(0, 2, -124)
	arena_gate.size = Vector3(10, 4, 0.6)
	arena_gate.starts_locked = true
	arena_gate.access_denied.connect(_on_narrative_request)
	interactables.add_child(arena_gate)
	var lab_switch := SwitchScene.instantiate() as LevelSwitch
	lab_switch.switch_id = &"walker_release"
	lab_switch.prompt = "OVERRIDE ANIMAL CONTROL"
	lab_switch.position = Vector3(8.5, 1.2, -117)
	interactables.add_child(lab_switch)
	lab_switch.target_path = lab_switch.get_path_to(arena_gate)
	lab_switch.activated.connect(_on_lab_switch_activated)
	var secret_wall := WallScene.instantiate() as BreakableSecretWall
	secret_wall.position = Vector3(11.8, 1.5, -103)
	secret_wall.rotation_degrees.y = 90
	secret_wall.broken.connect(_on_secret_discovered)
	interactables.add_child(secret_wall)
	var ball_return := BallReturnScene.instantiate() as BallReturnSecret
	ball_return.position = Vector3(25, 1.4, -108)
	ball_return.rotation_degrees.y = -90
	ball_return.secret_requested.connect(_on_secret_discovered)
	interactables.add_child(ball_return)
	golden_ball = GoldenBallScene.instantiate() as GoldenBallFinale
	golden_ball.position = Vector3(0, 1.2, -146)
	golden_ball.claimed.connect(_on_golden_ball_claimed)
	interactables.add_child(golden_ball)
	var checkpoint := CheckpointScene.instantiate() as LevelCheckpoint
	checkpoint.checkpoint_id = &"lab_entry"
	checkpoint.position = Vector3(0, 1.5, -87)
	checkpoint.activated.connect(_on_checkpoint_activated)
	interactables.add_child(checkpoint)


func _build_pickups() -> void:
	_spawn_pickup("res://scenes/pickups/treat.tscn", Vector3(-5, 0.8, 1))
	_spawn_pickup("res://scenes/pickups/barkshot_weapon.tscn", Vector3(0, 0.8, -34))
	_spawn_pickup("res://scenes/pickups/shells.tscn", Vector3(4, 0.8, -38))
	_spawn_pickup("res://scenes/pickups/access_collar.tscn", Vector3(0, 0.8, -72))
	_spawn_pickup("res://scenes/pickups/premium_treat.tscn", Vector3(-3, 0.8, -76))
	_spawn_pickup("res://scenes/pickups/fetch_launcher_weapon.tscn", Vector3(0, 0.8, -105))
	_spawn_pickup("res://scenes/pickups/tennis_balls.tscn", Vector3(6, 0.8, -110))
	_spawn_pickup("res://scenes/pickups/leather_padding.tscn", Vector3(22, 0.8, -99))
	_spawn_pickup("res://scenes/pickups/water_bowl.tscn", Vector3(27, 0.8, -102))
	_spawn_pickup("res://scenes/pickups/zoomies.tscn", Vector3(-10, 0.8, -132))


func _build_zone_triggers() -> void:
	_add_zone(&"equipment_shed", "EQUIPMENT SHED", Vector3(0, 1.5, -24), Vector3(12, 3, 3))
	_add_zone(&"maintenance_tunnels", "MAINTENANCE TUNNELS", Vector3(0, 1.5, -48), Vector3(8, 3, 3))
	_add_zone(&"compliance_lab", "ANIMAL COMPLIANCE LAB", Vector3(0, 1.5, -88), Vector3(18, 3, 3))
	_add_zone(&"secret_dog_park", "SECRET DOG PARK", Vector3(15, 1.5, -103), Vector3(3, 3, 15))
	_add_zone(&"walker_arena", "ANIMAL CONTROL WALKER", Vector3(0, 1.5, -128), Vector3(28, 3, 3))


func _add_zone(id: StringName, title: String, position_value: Vector3, size: Vector3) -> void:
	var trigger := ZoneScene.instantiate() as LevelZoneTrigger
	trigger.zone_id = id
	trigger.title = title
	trigger.trigger_size = size
	trigger.position = position_value
	trigger.entered.connect(_on_zone_entered)
	interactables.add_child(trigger)


func _sign(text: String, position_value: Vector3, rotation_y: float) -> void:
	var sign := SignScene.instantiate() as NarrativeSign
	sign.sign_text = text
	sign.position = position_value
	sign.rotation_degrees.y = rotation_y
	sign.read.connect(_on_sign_read)
	interactables.add_child(sign)


func _wall_pair(x: float, z: float, length: float) -> void:
	_box("Boundary", Vector3(-x, 2, z), Vector3(0.6, 4, length), Color("34434a"))
	_box("Boundary", Vector3(x, 2, z), Vector3(0.6, 4, length), Color("34434a"))


func _box(node_name: String, center: Vector3, size: Vector3, color: Color, surface_type: StringName = &"concrete") -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = node_name
	box.position = center
	box.size = size
	box.use_collision = true
	box.set_meta(&"surface_type", surface_type)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	box.material = material
	geometry.add_child(box)
	# A temporary CPU-side collider avoids copying CSG render meshes back from
	# the GPU during the runtime bake. It lives on a navigation-only layer and is
	# removed immediately after the one-time bake.
	var navigation_source := StaticBody3D.new()
	navigation_source.name = "%sNavigationSource" % node_name
	navigation_source.position = center
	navigation_source.collision_layer = NAVIGATION_SOURCE_LAYER
	navigation_source.collision_mask = 0
	navigation_source.add_to_group(&"salmon_navigation_source")
	var navigation_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	navigation_shape.shape = box_shape
	navigation_source.add_child(navigation_shape)
	geometry.add_child(navigation_source)
	_navigation_sources.append(navigation_source)
	return box


func _prop_box(node_name: String, center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var prop := MeshInstance3D.new()
	prop.name = node_name
	prop.position = center
	var mesh := BoxMesh.new()
	mesh.size = size
	prop.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	mesh.material = material
	geometry.add_child(prop)
	return prop


func _on_zone_entered(zone_id: StringName, title: String, _actor: Node) -> void:
	if on_zone_entered.is_valid():
		on_zone_entered.call(zone_id, title, _actor)


func _on_sign_read(_id: StringName, text: String, _actor: Node, times: int) -> void:
	if on_sign_read.is_valid():
		on_sign_read.call(_id, text, _actor, times)


func _on_secret_discovered(secret_id: StringName, title: String, _source: Node = null) -> void:
	if on_secret_discovered.is_valid():
		on_secret_discovered.call(secret_id, title)


func _on_shed_switch_activated(_id: StringName, _actor: Node) -> void:
	_emit_narrative_message("MAINTENANCE ACCESS: NEEDLESSLY DRAMATIC.", 2.5)


func _on_lab_switch_activated(_id: StringName, _actor: Node) -> void:
	if on_objective_action.is_valid():
		on_objective_action.call(ObjectiveDefinition.Kind.ACTIVATE, &"walker_release")


func _on_narrative_request(text: String) -> void:
	_emit_narrative_message(text, 2.5)


func _on_checkpoint_activated(id: StringName, position_value: Vector3) -> void:
	if on_checkpoint_activated.is_valid():
		on_checkpoint_activated.call(id, position_value)


func _on_golden_ball_claimed(_actor: Node) -> void:
	if on_golden_ball_claimed.is_valid():
		on_golden_ball_claimed.call(_actor)


func _emit_narrative_message(text: String, duration: float) -> void:
	if on_narrative_message.is_valid():
		on_narrative_message.call(text, duration)


func _spawn_pickup(path: String, position_value: Vector3) -> void:
	if pickup_spawn_callable.is_valid():
		pickup_spawn_callable.call(path, position_value)
