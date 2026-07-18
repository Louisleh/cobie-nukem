class_name BiomeMissionWorldBuilder
extends Node

signal navigation_bake_completed(success: bool)

const CheckpointScene = preload("res://scenes/interactables/level_checkpoint.tscn")
const SwitchScene = preload("res://scenes/interactables/level_switch.tscn")
const ZoneScene = preload("res://scenes/interactables/zone_trigger.tscn")
const GoldenBallScene = preload("res://scenes/interactables/golden_ball_finale.tscn")

var on_zone_entered: Callable
var on_checkpoint_activated: Callable
var on_objective_action: Callable
var on_narrative_message: Callable
var on_golden_ball_claimed: Callable
var build_navigation := true

var geometry: Node3D
var presentation: Node3D
var actors: Node3D
var interactables: Node3D
var navigation_region: NavigationRegion3D
var golden_ball: GoldenBallFinale
var _owner: Node3D
var _profile: BiomeMissionProfile
var _materials: Dictionary = {}
var _route_gates: Dictionary = {}


func build(owner: Node3D, profile: BiomeMissionProfile) -> bool:
	if owner == null or profile == null or not profile.validate().is_empty(): return false
	_owner = owner; _profile = profile
	geometry = Node3D.new(); geometry.name = "AuthoredGameplayLayout"; owner.add_child(geometry)
	presentation = Node3D.new(); presentation.name = "AuthoredPresentation"; owner.add_child(presentation)
	actors = Node3D.new(); actors.name = "Actors"; owner.add_child(actors)
	interactables = Node3D.new(); interactables.name = "Interactables"; owner.add_child(interactables)
	_build_environment(); _build_route(); _build_landmarks(); _build_interactables(); _build_navigation()
	return true


func _build_environment() -> void:
	var sky_top := Color(String(_profile.environment.get("sky_top", "18243a")))
	var sky_horizon := Color(String(_profile.environment.get("sky_horizon", "8295a8")))
	var fog_color := Color(String(_profile.environment.get("fog_color", "8092a0")))
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = sky_top; sky_material.sky_horizon_color = sky_horizon
	sky_material.ground_bottom_color = sky_top.darkened(0.5); sky_material.ground_horizon_color = fog_color.darkened(0.25)
	var sky := Sky.new(); sky.sky_material = sky_material
	var environment := Environment.new(); environment.background_mode = Environment.BG_SKY; environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = float(_profile.environment.get("ambient_energy", 0.7))
	environment.fog_enabled = true; environment.fog_light_color = fog_color
	environment.fog_density = float(_profile.environment.get("fog_density", 0.007))
	var world := WorldEnvironment.new(); world.name = "WorldEnvironment"; world.environment = environment; _owner.add_child(world)
	var light := DirectionalLight3D.new(); light.name = "KeyLight"
	light.rotation_degrees = Vector3(-48, float(_profile.environment.get("light_yaw", -24.0)), 0)
	light.light_color = Color(String(_profile.environment.get("light_color", "e8f2ff")))
	light.light_energy = float(_profile.environment.get("light_energy", 1.15)); light.shadow_enabled = true; _owner.add_child(light)


func _build_route() -> void:
	var floor_color := Color(String(_profile.environment.get("floor_color", "47505a")))
	var accent := Color(String(_profile.environment.get("accent_color", "27dce0")))
	for index in range(_profile.zones.size()):
		var zone := _profile.zones[index]
		var center: Vector3 = zone.center
		var size: Vector3 = zone.size
		var floor := _box("%s_Floor" % zone.id, Vector3(center.x, -0.5, center.z), Vector3(size.x, 1.0, size.z), floor_color, true)
		floor.collision_layer = (1 << 19) | 1; floor.set_meta(&"surface_type", StringName(zone.get("surface", &"concrete"))); floor.add_to_group(&"biome_navigation_source")
		_wall_pair(zone, floor_color.darkened(0.35))
		if index < _profile.zones.size() - 1:
			var next_center: Vector3 = _profile.zones[index + 1].center
			var next_size: Vector3 = _profile.zones[index + 1].size
			var z_mid: float = (center.z - size.z * 0.5 + next_center.z + next_size.z * 0.5) * 0.5
			var connector := _box("RouteConnector_%d" % index, Vector3(0, -0.52, z_mid), Vector3(9.0, 0.98, maxf(6.0, abs(center.z - next_center.z) - (size.z + next_size.z) * 0.5 + 2.0)), floor_color, true)
			connector.collision_layer = (1 << 19) | 1; connector.add_to_group(&"biome_navigation_source")
			var gate_z := center.z - size.z * 0.5 + 1.0
			var gate := _box("EncounterGate_%s" % zone.id, Vector3(0, 1.45, gate_z), Vector3(8.8, 2.9, 0.45), accent.darkened(0.3), true)
			_route_gates[StringName(zone.id)] = gate


func _wall_pair(zone: Dictionary, color: Color) -> void:
	var center: Vector3 = zone.center; var size: Vector3 = zone.size
	_box("%s_LeftBoundary" % zone.id, Vector3(center.x - size.x * 0.5, 2.0, center.z), Vector3(0.7, 4.0, size.z), color, true)
	_box("%s_RightBoundary" % zone.id, Vector3(center.x + size.x * 0.5, 2.0, center.z), Vector3(0.7, 4.0, size.z), color, true)


func _build_landmarks() -> void:
	for landmark in _profile.landmarks:
		var kind := String(landmark.get("kind", "box"))
		var at: Vector3 = landmark.get("position", Vector3.ZERO)
		var size: Vector3 = landmark.get("size", Vector3.ONE)
		var color := Color(String(landmark.get("color", _profile.environment.get("accent_color", "27dce0"))))
		if kind == "sign":
			var sign := AuthoredWorldSign.new()
			sign.configure(StringName(landmark.get("id", &"sign")), String(landmark.get("text", "COMPLIANCE NOTICE")), at, landmark.get("route_anchor", at + Vector3.FORWARD * 4.0), color)
			sign.add_to_group(&"authored_world_signs"); presentation.add_child(sign)
		elif kind == "sphere":
			var mesh := MeshInstance3D.new(); mesh.name = String(landmark.get("id", "Landmark")); mesh.position = at
			var sphere := SphereMesh.new(); sphere.radius = size.x; sphere.height = size.y; mesh.mesh = sphere; mesh.material_override = _material(color, bool(landmark.get("emissive", false))); presentation.add_child(mesh)
		elif kind == "dish":
			_dish(String(landmark.get("id", "SatelliteDish")), at, size, color)
		elif kind == "palm":
			_palm(String(landmark.get("id", "Palm")), at, maxf(size.y, 4.0), color)
		elif kind == "cylinder":
			_cylinder_landmark(String(landmark.get("id", "Cylinder")), at, size, color, bool(landmark.get("emissive", false)))
		else:
			_box(String(landmark.get("id", "Landmark")), at, size, color, bool(landmark.get("collision", false)), bool(landmark.get("emissive", false)))


func _dish(name_value: String, at: Vector3, size: Vector3, color: Color) -> void:
	var root := Node3D.new(); root.name = name_value; root.position = at; presentation.add_child(root)
	var mast := MeshInstance3D.new(); var mast_mesh := CylinderMesh.new(); mast_mesh.top_radius = 0.12; mast_mesh.bottom_radius = 0.18; mast_mesh.height = maxf(size.y, 2.0); mast.mesh = mast_mesh; mast.position.y = size.y * 0.5; mast.material_override = _material(color.darkened(0.35)); root.add_child(mast)
	var bowl := MeshInstance3D.new(); var bowl_mesh := SphereMesh.new(); bowl_mesh.radius = maxf(size.x, 1.2); bowl_mesh.height = maxf(size.x * 0.42, 0.5); bowl.mesh = bowl_mesh; bowl.position.y = maxf(size.y, 2.0); bowl.rotation_degrees.x = -28.0; bowl.scale.z = 0.28; bowl.material_override = _material(color); root.add_child(bowl)
	var feed := MeshInstance3D.new(); var feed_mesh := SphereMesh.new(); feed_mesh.radius = 0.16; feed_mesh.height = 0.3; feed.mesh = feed_mesh; feed.position = Vector3(0, size.y + 0.35, -size.x * 0.7); feed.material_override = _material(Color("25efff"), true); root.add_child(feed)


func _palm(name_value: String, at: Vector3, height: float, leaf_color: Color) -> void:
	var root := Node3D.new(); root.name = name_value; root.position = at; presentation.add_child(root)
	var trunk := MeshInstance3D.new(); var trunk_mesh := CylinderMesh.new(); trunk_mesh.top_radius = 0.15; trunk_mesh.bottom_radius = 0.28; trunk_mesh.height = height; trunk.mesh = trunk_mesh; trunk.position.y = height * 0.5; trunk.rotation_degrees.z = -4.0; trunk.material_override = _material(Color("7a5836")); root.add_child(trunk)
	for index in range(6):
		var leaf := MeshInstance3D.new(); var leaf_mesh := PrismMesh.new(); leaf_mesh.size = Vector3(0.45, 0.12, 2.8); leaf.mesh = leaf_mesh; leaf.position.y = height; leaf.rotation_degrees = Vector3(-12.0, index * 60.0, 0.0); leaf.material_override = _material(leaf_color); root.add_child(leaf)


func _cylinder_landmark(name_value: String, at: Vector3, size: Vector3, color: Color, emissive: bool) -> void:
	var mesh := MeshInstance3D.new(); mesh.name = name_value; mesh.position = at
	var cylinder := CylinderMesh.new(); cylinder.top_radius = maxf(size.x, 0.1); cylinder.bottom_radius = maxf(size.z, size.x); cylinder.height = maxf(size.y, 0.2); mesh.mesh = cylinder; mesh.material_override = _material(color, emissive); presentation.add_child(mesh)


func _build_interactables() -> void:
	for zone in _profile.zones:
		var trigger := ZoneScene.instantiate() as LevelZoneTrigger
		trigger.zone_id = StringName(zone.id); trigger.title = String(zone.title)
		var center: Vector3 = zone.center; var size: Vector3 = zone.size
		trigger.position = Vector3(center.x, 1.5, center.z + size.z * 0.42); trigger.trigger_size = Vector3(size.x - 1.0, 4.0, minf(5.0, size.z * 0.3))
		trigger.entered.connect(_on_zone); interactables.add_child(trigger)
		var checkpoint := CheckpointScene.instantiate() as LevelCheckpoint
		checkpoint.checkpoint_id = StringName(zone.checkpoint_id); checkpoint.position = zone.checkpoint_position
		checkpoint.activated.connect(_on_checkpoint); interactables.add_child(checkpoint)
	for entry in _profile.objective_switches:
		_switch(StringName(entry.id), String(entry.get("prompt", "ACTIVATE")), entry.position)
	for entry in _profile.secrets:
		_switch(StringName(entry.id), String(entry.get("prompt", "DISCOVER SECRET")), entry.position)
	golden_ball = GoldenBallScene.instantiate() as GoldenBallFinale
	golden_ball.position = _profile.zones[-1].get("reward_position", _profile.zones[-1].center + Vector3(0, 1.2, -6))
	golden_ball.claimed.connect(_on_ball_claimed); interactables.add_child(golden_ball)
	for volume in _profile.lethal_volumes:
		var body := Area3D.new(); body.name = String(volume.get("id", "LethalVolume")); body.position = volume.get("position", Vector3.ZERO)
		var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = volume.get("size", Vector3(10, 1, 10)); shape.shape = box; body.add_child(shape)
		body.body_entered.connect(_on_lethal_body_entered); interactables.add_child(body)


func _build_navigation() -> void:
	navigation_region = NavigationRegion3D.new(); navigation_region.name = "BiomeNavigation"
	var mesh := NavigationMesh.new(); mesh.agent_radius = 0.5; mesh.agent_height = 2.0; mesh.agent_max_climb = 0.5; mesh.agent_max_slope = 45.0
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS; mesh.geometry_collision_mask = 1 << 19
	mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_EXPLICIT; mesh.geometry_source_group_name = &"biome_navigation_source"
	var first: Vector3 = _profile.zones[0].center; var last: Vector3 = _profile.zones[-1].center
	mesh.filter_baking_aabb = AABB(Vector3(-30, -2, last.z - 40), Vector3(60, 12, first.z - last.z + 80))
	navigation_region.navigation_mesh = mesh; _owner.add_child(navigation_region)
	if build_navigation: call_deferred("_bake_navigation")


func _bake_navigation() -> void:
	navigation_region.bake_navigation_mesh(false)
	var map := navigation_region.get_navigation_map(); NavigationServer3D.region_set_map(navigation_region.get_rid(), map)
	NavigationServer3D.region_set_navigation_mesh(navigation_region.get_rid(), navigation_region.navigation_mesh)
	NavigationServer3D.map_set_active(map, true); NavigationServer3D.map_force_update(map)
	navigation_bake_completed.emit(navigation_region.navigation_mesh.get_polygon_count() > 0)


func set_route_gate_open(zone_id: StringName, open: bool) -> void:
	var gate := _route_gates.get(zone_id) as StaticBody3D
	if gate == null: return
	gate.visible = not open; gate.collision_layer = 0 if open else 1
	for child in gate.get_children():
		if child is CollisionShape3D: (child as CollisionShape3D).set_deferred("disabled", open)


func enable_golden_ball() -> void:
	if golden_ball != null: golden_ball.enable_as_reward()


func _switch(id: StringName, prompt: String, at: Vector3) -> LevelSwitch:
	var result := SwitchScene.instantiate() as LevelSwitch; result.switch_id = id; result.prompt = prompt; result.position = at
	result.activated.connect(_on_switch); interactables.add_child(result); return result


func _box(name_value: String, at: Vector3, size: Vector3, color: Color, collision: bool, emissive := false) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = name_value; body.position = at; body.collision_layer = 1 if collision else 0
	var mesh_instance := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size; mesh_instance.mesh = mesh; mesh_instance.material_override = _material(color, emissive); body.add_child(mesh_instance)
	if collision:
		var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = size; shape.shape = box; body.add_child(shape)
	(geometry if collision else presentation).add_child(body); return body


func _material(color: Color, emissive := false) -> Material:
	var key := color.to_html(true) + str(emissive)
	if _materials.has(key): return _materials[key]
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform vec4 base_color : source_color;
uniform float emission_strength = 0.0;
uniform float grain_scale = 2.4;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
	float broad = sin(local_position.x * grain_scale) * cos(local_position.z * grain_scale * 0.83);
	float fine = sin((local_position.x + local_position.y + local_position.z) * grain_scale * 5.7);
	float grain = broad * 0.055 + fine * 0.018;
	ALBEDO = clamp(base_color.rgb * (1.0 + grain), vec3(0.0), vec3(1.0));
	ROUGHNESS = clamp(0.72 + fine * 0.025, 0.35, 0.95);
	METALLIC = emission_strength > 0.0 ? 0.15 : 0.04;
	EMISSION = base_color.rgb * emission_strength;
}"""
	material.shader = shader
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("emission_strength", 2.3 if emissive else 0.0)
	material.set_shader_parameter("grain_scale", float(_profile.environment.get("material_grain_scale", 2.4)))
	_materials[key] = material; return material


func _on_zone(id: StringName, title: String, actor: Node) -> void:
	if on_zone_entered.is_valid(): on_zone_entered.call(id, title, actor)
func _on_checkpoint(id: StringName, at: Vector3) -> void:
	if on_checkpoint_activated.is_valid(): on_checkpoint_activated.call(id, at)
func _on_switch(id: StringName, _actor: Node) -> void:
	if on_objective_action.is_valid(): on_objective_action.call(ObjectiveDefinition.Kind.ACTIVATE, id)
	if on_narrative_message.is_valid(): on_narrative_message.call("%s // COMPLETE" % String(id).replace("_", " ").to_upper(), 2.5)
func _on_ball_claimed(actor: Node) -> void:
	if on_golden_ball_claimed.is_valid(): on_golden_ball_claimed.call(actor)
func _on_lethal_body_entered(body: Node) -> void:
	if body is CobiePlayer: (body as CobiePlayer).apply_damage(10000.0, self)
