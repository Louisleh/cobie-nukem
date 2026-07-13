class_name EpisodeOneLevel
extends Node3D

signal level_ready(player: Node3D)
signal zone_entered(zone_id: StringName, title: String)
signal narrative_message(text: String, duration: float)
signal objective_changed(text: String)
signal secret_found(secret_id: StringName, title: String, found: int, total: int)
signal checkpoint_activated(checkpoint_id: StringName, respawn_position: Vector3)
signal enemy_spawned(enemy: Node, zone_id: StringName)
signal enemy_defeated(enemy: Node, zone_id: StringName)
signal boss_state_changed(state: StringName, fraction: float)
signal level_completed(summary: Dictionary)

const DoorScene = preload("res://scenes/interactables/level_door.tscn")
const SwitchScene = preload("res://scenes/interactables/level_switch.tscn")
const SignScene = preload("res://scenes/interactables/narrative_sign.tscn")
const WallScene = preload("res://scenes/interactables/breakable_secret_wall.tscn")
const CheckpointScene = preload("res://scenes/interactables/level_checkpoint.tscn")
const ZoneScene = preload("res://scenes/interactables/zone_trigger.tscn")
const BallReturnScene = preload("res://scenes/interactables/ball_return_secret.tscn")
const GoldenBallScene = preload("res://scenes/interactables/golden_ball_finale.tscn")
const HUDScene = preload("res://scenes/ui/hud.tscn")
const PauseScene = preload("res://scenes/ui/pause_menu.tscn")
const DeathScene = preload("res://scenes/ui/death_screen.tscn")
const VictoryScene = preload("res://scenes/ui/victory_screen.tscn")
const CombatAudioScene = preload("res://scenes/ui/combat_audio_bridge.tscn")
const MobileControlsScene = preload("res://scenes/ui/mobile_controls.tscn")
const SalmonCreekPacing = preload("res://resources/encounters/salmon_walker_pacing.tres")
const MissionInteractionRuntimeScript = preload("res://scripts/gameplay/mission_interaction_runtime.gd")
const ROUTE_PROGRESS := [
	[-22.0, &"equipment_shed", "EQUIPMENT SHED"],
	[-47.0, &"maintenance_tunnels", "MAINTENANCE TUNNELS"],
	[-87.0, &"compliance_lab", "ANIMAL COMPLIANCE LAB"],
	[-127.0, &"walker_arena", "ANIMAL CONTROL WALKER"],
]
const NAVIGATION_SOURCE_LAYER := 1 << 19

@export var metadata: LevelMetadata = preload("res://resources/level/episode_1_level_1.tres")
@export var content_manifest: ContentManifest = preload("res://resources/content/salmon_creek_manifest.tres")
@export var encounter_pacing: SalmonCreekPacingProfile = SalmonCreekPacing
@export var spawn_player := true
@export var start_run_automatically := true
@export var setup_presentation := true

var player: Node3D
var current_zone: StringName = &""
var checkpoint_position := Vector3(0, 1.1, 10)
var secrets: Dictionary = {}
var spawned_zones: Dictionary = {}
var enemies_defeated := 0
var enemies_total := 0
var completion_started := false
var _run_started_ms := 0
var _golden_ball: GoldenBallFinale
var _walker: Node
var _geometry: Node3D
var _actors: Node3D
var _interactables: Node3D
var _hud: GameHUD
var _pause_menu: PauseMenu
var _death_screen: DeathScreen
var _victory_screen: VictoryScreen
var _combat_audio: CombatAudioBridge
var _mobile_controls: MobileControls
var _interaction_runtime: MissionInteractionRuntime
var _opening_enemies: Array[Node] = []
var _opening_encounter_active := false
var _objective_tracker: ObjectiveTracker
var _encounter_runner: EncounterRunner
var _last_combat_zone: StringName = &""
var _resetting_encounter := false
var _opening_grace_timer: Timer
var _completion_timer: Timer
var _route_recovery_timer: Timer
var _restored_checkpoint: Dictionary = {}
var _mission_runtime: MissionRuntime
var _spawn_registry: MissionSpawnRegistry
var _navigation_region: NavigationRegion3D
var _navigation_sources: Array[StaticBody3D] = []
var _walker_phase_rewards: Dictionary = {}
var _walker_phase_pickups: Array[Node] = []
var _walker_cannon_attacks := 0
var _baseline_attack_budget := 3

func _ready() -> void:
	_run_started_ms = Time.get_ticks_msec()
	_apply_requested_checkpoint()
	_build_level()
	_setup_gameplay_systems()
	if spawn_player: _spawn_player()
	if setup_presentation: _setup_presentation()
	if start_run_automatically and get_node_or_null("/root/GameState"):
		var game_state := get_node("/root/GameState")
		game_state.begin_run(metadata.level_id)
		if not _restored_checkpoint.is_empty():
			game_state.run_stats["checkpoint_id"] = String(_restored_checkpoint.get("checkpoint_id", "start"))
	objective_changed.emit(metadata.opening_objective)
	narrative_message.emit("EPISODE 1, LEVEL 1: %s\n%s" % [metadata.title, metadata.subtitle], 4.0)
	level_ready.emit(player)
	# Ensure the opening encounter exists even when body-enter events settle before connections.
	_enter_zone(&"forbidden_field", "FORBIDDEN FIELD", player)


func _setup_gameplay_systems() -> void:
	_spawn_registry = MissionSpawnRegistry.new()
	_spawn_registry.name = "MissionSpawnRegistry"
	add_child(_spawn_registry)
	_spawn_registry.prewarm_encounters(content_manifest.encounters)
	spawned_zones = _spawn_registry.completed_zones
	_mission_runtime = MissionRuntime.new()
	_mission_runtime.name = "MissionRuntime"
	add_child(_mission_runtime)
	_mission_runtime.configure(content_manifest, _spawn_scene)
	_objective_tracker = _mission_runtime.objectives
	_objective_tracker.objective_activated.connect(func(definition: ObjectiveDefinition) -> void:
		objective_changed.emit(definition.title)
	)
	_encounter_runner = _mission_runtime.encounters
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null:
		_baseline_attack_budget = pressure.maximum_attackers
	_encounter_runner.actor_spawned.connect(_on_encounter_actor_spawned)
	_encounter_runner.actor_defeated.connect(func(enemy: Node, definition: EncounterDefinition) -> void:
		_on_enemy_died(enemy, definition.zone_id)
	)
	_restore_mission_snapshot()
	_setup_interaction_runtime()
	# Level-owned timers die with the scene, so a pending opening-grace or
	# completion callback can never fire into a freed level, and restarting the
	# opening encounter replaces the pending grace window instead of stacking a
	# second, earlier activation.
	_opening_grace_timer = Timer.new()
	_opening_grace_timer.name = "OpeningGraceTimer"
	_opening_grace_timer.one_shot = true
	var opening_definition := _encounter_runner.definitions.get(&"forbidden_field") as EncounterDefinition
	_opening_grace_timer.wait_time = opening_definition.opening_grace_seconds if opening_definition != null else 12.0
	_opening_grace_timer.timeout.connect(_activate_opening_encounter)
	add_child(_opening_grace_timer)
	_completion_timer = Timer.new()
	_completion_timer.name = "CompletionTimer"
	_completion_timer.one_shot = true
	_completion_timer.wait_time = 1.2
	_completion_timer.timeout.connect(_finalize_level_completion)
	add_child(_completion_timer)
	_route_recovery_timer = Timer.new()
	_route_recovery_timer.name = "RouteRecoveryTimer"
	_route_recovery_timer.wait_time = 0.25
	_route_recovery_timer.timeout.connect(_check_route_recovery)
	add_child(_route_recovery_timer)
	_route_recovery_timer.start()


func _apply_requested_checkpoint() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not bool(game_state.get("continue_requested")):
		return
	var save_manager := get_node_or_null("/root/SaveManager")
	var saved := CheckpointPayload.sanitize(save_manager.load_slot(&"checkpoint")) if save_manager != null else {}
	_restored_checkpoint = saved
	var position_values: Array = saved.get("position", [])
	if position_values.size() == 3:
		checkpoint_position = Vector3(float(position_values[0]), float(position_values[1]), float(position_values[2]))
	game_state.continue_requested = false


func _restore_mission_snapshot() -> void:
	if _restored_checkpoint.is_empty():
		return
	_mission_runtime.restore(_restored_checkpoint)
	secrets.clear()
	for raw_id: Variant in _restored_checkpoint.get("secrets", {}):
		secrets[StringName(raw_id)] = String(_restored_checkpoint.secrets[raw_id])
	_spawn_registry.completed_zones.clear()
	for zone_id: Variant in _encounter_runner.completed:
		_spawn_registry.completed_zones[zone_id] = true
	if _interaction_runtime != null:
		_interaction_runtime.restore_checkpoint_secrets(_restored_checkpoint.get("secrets", {}))


func _setup_interaction_runtime() -> void:
	if _interactables == null:
		_interaction_runtime = null
		return
	_interaction_runtime = MissionInteractionRuntimeScript.new()
	_interaction_runtime.name = "MissionInteractionRuntime"
	add_child(_interaction_runtime)
	if not _interaction_runtime.configure(content_manifest, _interactables, _spawn_registry):
		push_warning("Mission interaction runtime failed to initialize from catalog; catalog interactions are disabled.")
		_interaction_runtime.queue_free()
		_interaction_runtime = null
		return
	_interaction_runtime.secret_requested.connect(_on_interaction_secret_requested)
	_interaction_runtime.loot_requested.connect(_on_interaction_loot_requested)
	_interaction_runtime.restore_checkpoint_secrets(_restored_checkpoint.get("secrets", {}))


func _check_route_recovery() -> void:
	if not is_instance_valid(player):
		return
	# Low-frequency indexed recovery keeps the route playable if a browser drops
	# an Area3D transition without spending every physics frame scanning progress.
	for milestone in ROUTE_PROGRESS:
		var zone_id := StringName(milestone[1])
		if player.global_position.z <= float(milestone[0]) and not spawned_zones.has(zone_id):
			_enter_zone(zone_id, String(milestone[2]), player)


func _build_level() -> void:
	_geometry = Node3D.new(); _geometry.name = "Geometry"; add_child(_geometry)
	_actors = Node3D.new(); _actors.name = "Actors"; add_child(_actors)
	_interactables = Node3D.new(); _interactables.name = "Interactables"; add_child(_interactables)
	_build_lighting()
	_build_route_geometry()
	_build_navigation()
	_build_story_objects()
	_build_pickups()
	_build_zone_triggers()


func _build_lighting() -> void:
	var environment := WorldEnvironment.new()
	var sky_material := ProceduralSkyMaterial.new(); sky_material.sky_top_color = Color("101c29"); sky_material.sky_horizon_color = Color("52666d"); sky_material.ground_bottom_color = Color("111b1d"); sky_material.ground_horizon_color = Color("46595a"); sky_material.sun_angle_max = 8.0
	var sky := Sky.new(); sky.sky_material = sky_material
	var env := Environment.new(); env.background_mode = Environment.BG_SKY; env.sky = sky; env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_color = Color("8da399"); env.ambient_light_energy = 0.55; env.fog_enabled = true; env.fog_light_color = Color("667a78"); env.fog_density = 0.012; env.fog_aerial_perspective = 0.7
	environment.environment = env; add_child(environment)
	var moon := DirectionalLight3D.new(); moon.rotation_degrees = Vector3(-58, -25, 0); moon.light_color = Color("a9c5d6"); moon.light_energy = 1.1; moon.shadow_enabled = true; add_child(moon)


func _build_route_geometry() -> void:
	# Continuous route: field → shed → tunnels → lab → walker arena.
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
	_wall_pair(13, 0, 36); _wall_pair(7.5, -32, 25); _wall_pair(5, -64, 39)
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
	_build_field_dressing()
	# Arena cover makes the boss readable under flight-stick auto-aim.
	for pos in [Vector3(-10, 1, -140), Vector3(10, 1, -140), Vector3(-10, 1, -156), Vector3(10, 1, -156)]:
		_box("ArenaCover", pos, Vector3(3, 2, 3), Color("70584d"))


func _build_navigation() -> void:
	_navigation_region = NavigationRegion3D.new()
	_navigation_region.name = "GroundNavigation"
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
	_navigation_region.navigation_mesh = navigation_mesh
	add_child(_navigation_region)
	# CSG collision/meshes finish synchronizing after this construction pass.
	# Defer one turn, then bake synchronously so native and single-threaded Web
	# builds share the same deterministic map. Enemies retain direct steering for
	# that first turn and switch to paths as soon as the map iteration is ready.
	call_deferred("_bake_navigation")


func _bake_navigation() -> void:
	if is_instance_valid(_navigation_region):
		_navigation_region.bake_navigation_mesh(false)
		# Assign the completed resource to the server RID explicitly. Linux
		# headless otherwise defers the node's resource-change notification beyond
		# a physics-only test loop, while macOS applies it in the same turn.
		var navigation_map := _navigation_region.get_navigation_map()
		NavigationServer3D.region_set_map(_navigation_region.get_rid(), navigation_map)
		NavigationServer3D.region_set_navigation_mesh(_navigation_region.get_rid(), _navigation_region.navigation_mesh)
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
	opening_sign.sign_id = &"no_animals"; opening_sign.sign_text = "NO ANIMALS\nON SPORTS FIELD"; opening_sign.secret_after_reads = 3; opening_sign.secret_id = &"optional_sign"; opening_sign.secret_title = "SIGN SEEMS OPTIONAL"; opening_sign.position = Vector3(-5, 1.4, 5.5); opening_sign.rotation_degrees.y = 0
	opening_sign.read.connect(_on_sign_read); opening_sign.secret_requested.connect(_discover_secret); _interactables.add_child(opening_sign)
	_sign("MUTANT-FREE ZONE\n(Inspection Pending)", Vector3(5, 1.5, -27), 180)
	_sign("LEASH LENGTH SUBJECT TO\nALGORITHMIC REVIEW", Vector3(-4, 1.5, -58), 180)
	_sign("GOOD DOG STATUS:\nREVOKED", Vector3(6, 1.5, -91), 180)
	_sign("EMPLOYEE OF THE MONTH:\nVACUUM CLEANER", Vector3(-7, 1.5, -108), 180)
	_sign("JOY EVENT DETECTED.\nINCIDENT CREATED.", Vector3(7, 1.5, -116), 180)
	_sign("FETCH THIS!", Vector3(0, 2.0, -164), 180)

	var shed_gate := DoorScene.instantiate() as LevelDoor; shed_gate.name = "ShedGate"; shed_gate.position = Vector3(0, 2, -19); shed_gate.size = Vector3(8, 4, 0.6); shed_gate.access_denied.connect(_message); _interactables.add_child(shed_gate)
	var tunnel_gate := DoorScene.instantiate() as LevelDoor; tunnel_gate.name = "TunnelGate"; tunnel_gate.position = Vector3(0, 2, -44); tunnel_gate.size = Vector3(8, 4, 0.6); tunnel_gate.starts_locked = true; tunnel_gate.access_denied.connect(_message); _interactables.add_child(tunnel_gate)
	var shed_switch := SwitchScene.instantiate() as LevelSwitch; shed_switch.switch_id = &"shed_power"; shed_switch.position = Vector3(-5.8, 1.2, -39); _interactables.add_child(shed_switch); shed_switch.target_path = shed_switch.get_path_to(tunnel_gate); shed_switch.activated.connect(func(_id, _actor): narrative_message.emit("MAINTENANCE ACCESS: NEEDLESSLY DRAMATIC.", 2.5))
	var lab_gate := DoorScene.instantiate() as LevelDoor; lab_gate.name = "LabGate"; lab_gate.position = Vector3(0, 2, -83); lab_gate.size = Vector3(8, 4, 0.6); lab_gate.requires_access_collar = true; lab_gate.locked_message = "ACCESS COLLAR REQUIRED. NO EXCEPTIONS, EXCEPT COBIE."; lab_gate.access_denied.connect(_message); _interactables.add_child(lab_gate)
	var arena_gate := DoorScene.instantiate() as LevelDoor; arena_gate.name = "ArenaGate"; arena_gate.position = Vector3(0, 2, -124); arena_gate.size = Vector3(10, 4, 0.6); arena_gate.starts_locked = true; arena_gate.access_denied.connect(_message); _interactables.add_child(arena_gate)
	var lab_switch := SwitchScene.instantiate() as LevelSwitch; lab_switch.switch_id = &"walker_release"; lab_switch.prompt = "OVERRIDE ANIMAL CONTROL"; lab_switch.position = Vector3(8.5, 1.2, -117); _interactables.add_child(lab_switch); lab_switch.target_path = lab_switch.get_path_to(arena_gate); lab_switch.activated.connect(func(_id, _actor): _objective_tracker.record(ObjectiveDefinition.Kind.ACTIVATE, &"walker_release"))

	var secret_wall := WallScene.instantiate() as BreakableSecretWall; secret_wall.position = Vector3(11.8, 1.5, -103); secret_wall.rotation_degrees.y = 90; secret_wall.broken.connect(_discover_secret); _interactables.add_child(secret_wall)
	var ball_return := BallReturnScene.instantiate() as BallReturnSecret; ball_return.position = Vector3(25, 1.4, -108); ball_return.rotation_degrees.y = -90; ball_return.secret_requested.connect(_discover_secret); _interactables.add_child(ball_return)
	_golden_ball = GoldenBallScene.instantiate() as GoldenBallFinale; _golden_ball.position = Vector3(0, 1.2, -146); _golden_ball.claimed.connect(_on_golden_ball_claimed); _interactables.add_child(_golden_ball)
	var checkpoint := CheckpointScene.instantiate() as LevelCheckpoint; checkpoint.checkpoint_id = &"lab_entry"; checkpoint.position = Vector3(0, 1.5, -87); checkpoint.activated.connect(_on_checkpoint); _interactables.add_child(checkpoint)


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
	var trigger := ZoneScene.instantiate() as LevelZoneTrigger; trigger.zone_id = id; trigger.title = title; trigger.trigger_size = size; trigger.position = position_value; trigger.entered.connect(_enter_zone); _interactables.add_child(trigger)


func _enter_zone(zone_id: StringName, title: String, _actor: Node) -> void:
	current_zone = zone_id; zone_entered.emit(zone_id, title); narrative_message.emit(title, 2.0)
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.run_stats["last_zone"] = String(zone_id)
	_objective_tracker.record(ObjectiveDefinition.Kind.REACH_ZONE, zone_id)
	_spawn_wave(zone_id)


func _spawn_wave(zone_id: StringName) -> void:
	if not _spawn_registry.mark_zone_spawned(zone_id): return
	if _encounter_runner.definitions.has(zone_id):
		_last_combat_zone = zone_id
		var definition := _encounter_runner.definitions[zone_id] as EncounterDefinition
		var pressure := get_node_or_null("/root/CombatPressure")
		if pressure != null:
			pressure.configure_limit(mini(_baseline_attack_budget, definition.maximum_simultaneous_attackers))
	_encounter_runner.activate_zone(zone_id, player)
	if zone_id == &"walker_arena" and _walker == null:
		# Development fallback: a missing boss scene must not trap QA in the level.
		_golden_ball.enable_for_boss(null)
		narrative_message.emit("BOSS ASSET MISSING — GOLDEN BALL QA FALLBACK ENABLED.", 4.0)
	if zone_id == &"forbidden_field":
		_opening_grace_timer.start()


func _on_encounter_actor_spawned(enemy: Node, definition: EncounterDefinition) -> void:
	if enemy is ComplianceHound: enemy.name = "FetchGuard"
	if enemy.has_signal("drop_requested"): enemy.drop_requested.connect(_spawn_enemy_drop)
	if not _resetting_encounter: enemies_total += 1
	if definition.zone_id == &"forbidden_field":
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		_opening_enemies.append(enemy)
	enemy_spawned.emit(enemy, definition.zone_id)
	_bind_enemy_captions(enemy)
	if enemy is AnimalControlWalker: _bind_walker(enemy)


func _bind_enemy_captions(enemy: Node) -> void:
	if _hud == null or not enemy.has_signal("telegraph_started") or enemy.has_meta(&"caption_bound"): return
	enemy.set_meta(&"caption_bound", true)
	enemy.telegraph_started.connect(func(kind: StringName, _duration: float) -> void:
		_hud.show_caption("%s WARNING" % String(kind).replace("_", " "))
	)


func _activate_opening_encounter(_weapon: WeaponBase = null, _secondary := false) -> void:
	if _opening_encounter_active:
		return
	_opening_encounter_active = true
	for enemy in _opening_enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = Node.PROCESS_MODE_INHERIT
			if enemy.has_method("set_target") and player:
				enemy.set_target(player)


func _bind_walker(walker: Node) -> void:
	_walker = walker
	_walker_phase_rewards.clear()
	_walker_phase_pickups.clear()
	_walker_cannon_attacks = 0
	# The generic chase path advances during attack cooldowns. Give this boss an
	# authored orbit and retreat floor so it pressures from readable cannon range
	# instead of collapsing into the player's collision capsule after every shot.
	if encounter_pacing != null and walker is EnemyAgent and walker.definition != null:
		walker.definition.preferred_distance = walker.definition.attack_range
		walker.definition.retreat_distance = encounter_pacing.pressure_distance.x
		boss_state_changed.emit(encounter_pacing.phase_id(0), walker.health_fraction())
		narrative_message.emit(encounter_pacing.phase_cue(0), 2.5)
	if walker.has_signal("golden_ball_enabled"): walker.golden_ball_enabled.connect(func(target): _golden_ball.enable_for_boss(target); objective_changed.emit("FETCH THE GOLDEN TENNIS BALL"))
	if walker.has_signal("boss_phase_changed"): walker.boss_phase_changed.connect(_on_walker_phase_changed.bind(walker))
	if walker.has_signal("attack_fired"): walker.attack_fired.connect(_on_walker_attack_fired.bind(walker))
	if walker.has_signal("walker_defeated"): walker.walker_defeated.connect(func():
		boss_state_changed.emit(&"defeated", 0.0)
		_objective_tracker.record(ObjectiveDefinition.Kind.DEFEAT, &"animal_control_walker")
	)


func _on_walker_phase_changed(_previous: int, phase: int, walker: Node) -> void:
	if walker != _walker or encounter_pacing == null:
		return
	boss_state_changed.emit(encounter_pacing.phase_id(phase), walker.health_fraction())
	var cue := encounter_pacing.phase_cue(phase)
	if not cue.is_empty():
		if _hud != null:
			_hud.show_boss_phase_caption(cue, 3.0)
		narrative_message.emit(cue, 3.0)
	if _walker_phase_rewards.has(phase):
		return
	var recovery := encounter_pacing.recovery_drop(phase)
	if recovery.is_empty():
		return
	_walker_phase_rewards[phase] = true
	var pickup := _spawn_pickup(String(recovery.scene), recovery.position)
	if pickup != null:
		_walker_phase_pickups.append(pickup)
	narrative_message.emit("ARENA RECOVERY DROP DEPLOYED", 2.0)


func _on_walker_attack_fired(_kind: StringName, walker: Node) -> void:
	if walker != _walker or encounter_pacing == null or int(walker.boss_phase) != 0:
		return
	_walker_cannon_attacks += 1
	var summon_interval := int(walker.summon_attack_interval)
	if summon_interval > 0 and _walker_cannon_attacks % summon_interval == 0:
		narrative_message.emit("DRONE REINFORCEMENT DEPLOYED", 2.0)


func _on_enemy_died(enemy: Node, zone_id: StringName) -> void:
	# Checkpoint retries rebuild an authored encounter without increasing its
	# mission total. Clamp credited defeats to that total so retry kills cannot
	# corrupt completion reports or produce impossible >100% enemy statistics.
	enemies_defeated = mini(enemies_defeated + 1, enemies_total); enemy_defeated.emit(enemy, zone_id)
	var game_state := get_node_or_null("/root/GameState")
	if game_state: game_state.run_stats.enemies_defeated = enemies_defeated


func _discover_secret(secret_id: StringName, title: String) -> void:
	if secrets.has(secret_id): return
	secrets[secret_id] = title
	secret_found.emit(secret_id, title, secrets.size(), metadata.total_secrets)
	narrative_message.emit("SECRET FOUND: %s (%d/%d)" % [title, secrets.size(), metadata.total_secrets], 3.0)
	var game_state := get_node_or_null("/root/GameState")
	if game_state: game_state.run_stats.secrets_found = secrets.size()
	if secret_id == &"optional_sign": _spawn_pickup("res://scenes/pickups/golden_tag.tscn", Vector3(-6, 0.8, 7))
	elif secret_id == &"ball_return": _spawn_pickup("res://scenes/pickups/squeaker.tscn", Vector3(25, 0.8, -105))


func _on_sign_read(_id: StringName, text: String, _actor: Node, times: int) -> void:
	var suffix := "\nSIGN SEEMS OPTIONAL." if times >= 2 else ""
	narrative_message.emit(text + suffix, 2.5)


func _on_checkpoint(id: StringName, position_value: Vector3) -> void:
	checkpoint_position = position_value; checkpoint_activated.emit(id, position_value)
	if _hud != null:
		_hud.show_checkpoint_caption("CHECKPOINT: GOOD DOG STATUS TEMPORARILY RESTORED.", 2.5)
	narrative_message.emit("CHECKPOINT: GOOD DOG STATUS TEMPORARILY RESTORED.", 2.5)
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.run_stats["checkpoint_id"] = String(id)


func restart_from_checkpoint() -> void:
	if _interaction_runtime != null:
		_interaction_runtime.reset_for_checkpoint(_restored_checkpoint)
	if _combat_audio != null:
		_combat_audio.reset_gameplay_audio()
	_reset_active_encounter_for_checkpoint()
	if player:
		if player.has_method("respawn"):
			player.respawn(checkpoint_position)
		else:
			player.global_position = checkpoint_position
			if player.has_method("restore_full"): player.restore_full()
			if "velocity" in player: player.velocity = Vector3.ZERO
	if _death_screen:
		_death_screen.visible = false
	if _pause_menu:
		_pause_menu.set_suppressed(false)


func _reset_active_encounter_for_checkpoint() -> void:
	if _encounter_runner == null or _last_combat_zone == &"" or not _encounter_runner.definitions.has(_last_combat_zone): return
	var zone_id := _last_combat_zone
	_encounter_runner.reset_zone(zone_id)
	_spawn_registry.clear_zone(zone_id)
	if zone_id == &"forbidden_field":
		_opening_enemies.clear()
		_opening_encounter_active = false
	if zone_id == &"walker_arena":
		_walker = null
		_walker_phase_rewards.clear()
		for pickup in _walker_phase_pickups:
			if is_instance_valid(pickup):
				pickup.queue_free()
		_walker_phase_pickups.clear()
		_walker_cannon_attacks = 0
		# The walker's summoned drones live outside the encounter runner's actor
		# list; leaving them alive would greet the respawned player with stale
		# pressure the reset just promised to remove.
		for summon in get_tree().get_nodes_in_group(&"boss_summons"):
			summon.queue_free()
	_resetting_encounter = true
	_spawn_wave(zone_id)
	_resetting_encounter = false


func _on_golden_ball_claimed(_actor: Node) -> void:
	if completion_started: return
	completion_started = true
	_objective_tracker.record(ObjectiveDefinition.Kind.COLLECT_ITEM, &"golden_tennis_ball")
	narrative_message.emit("THEY SAID NO ANIMALS. THEY SHOULD HAVE SAID PLEASE.", 5.0)
	# A finished run must not offer a stale mid-level Continue from the menu.
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager: save_manager.delete_slot(&"checkpoint")
	_completion_timer.start()


func _finalize_level_completion() -> void:
	var summary := get_level_summary(); level_completed.emit(summary)
	var game_state := get_node_or_null("/root/GameState")
	if game_state: game_state.finish_run(summary)


func get_level_summary() -> Dictionary:
	return {
		"level_id": metadata.level_id, "title": metadata.title,
		"completion_time_msec": Time.get_ticks_msec() - _run_started_ms,
		"enemies_defeated": enemies_defeated, "enemies_total": enemies_total,
		"secrets_found": secrets.size(), "secrets_total": metadata.total_secrets,
		"control_method": get_node("/root/InputManager").active_control_method if get_node_or_null("/root/InputManager") else &"unknown",
		"victory_line": "THEY SAID NO ANIMALS. THEY SHOULD HAVE SAID PLEASE.",
	}


func _spawn_player() -> void:
	player = _spawn_scene("res://scenes/player/cobie_player.tscn", checkpoint_position) as Node3D
	if player:
		_add_weather_to_player()
		for weapon in player.weapons:
			weapon.fired.connect(_activate_opening_encounter)
		if player.has_signal("died"): player.died.connect(func(_source):
			narrative_message.emit("GOOD DOG DOWN. PRESS FIRE TO RESTART.", 3.0)
			var game_state := get_node_or_null("/root/GameState")
			if game_state: game_state.run_stats["deaths"] = int(game_state.run_stats.get("deaths", 0)) + 1
		)
		if player.has_signal("restart_requested"): player.restart_requested.connect(restart_from_checkpoint)


func _setup_presentation() -> void:
	_hud = HUDScene.instantiate() as GameHUD
	_pause_menu = PauseScene.instantiate() as PauseMenu
	_death_screen = DeathScene.instantiate() as DeathScreen
	_victory_screen = VictoryScene.instantiate() as VictoryScreen
	_combat_audio = CombatAudioScene.instantiate() as CombatAudioBridge
	_mobile_controls = MobileControlsScene.instantiate() as MobileControls
	add_child(_hud)
	add_child(_pause_menu)
	add_child(_death_screen)
	add_child(_victory_screen)
	add_child(_combat_audio)
	_hud.get_node("Root").add_child(_mobile_controls)
	if player:
		_hud.bind_player(player)
		_combat_audio.bind_player(player)
		_mobile_controls.bind_player(player)
		if player.has_signal("died"):
			player.died.connect(_on_player_died_for_ui)
	for actor in _actors.get_children(): _bind_enemy_captions(actor)
	_pause_menu.restart_requested.connect(restart_from_checkpoint)
	_death_screen.retry_requested.connect(restart_from_checkpoint)
	narrative_message.connect(func(text: String, duration: float):
		_hud.show_notification(text)
		_hud.show_caption(text, GameHUD.CaptionCategory.NARRATIVE, duration)
	)
	objective_changed.connect(func(text: String):
		_hud.show_objective(text)
		_hud.show_notification("OBJECTIVE: " + text)
		_hud.show_objective_caption(text, 2.0)
	)
	_hud.show_objective(metadata.opening_objective)
	secret_found.connect(func(_id: StringName, title: String, found: int, total: int): _hud.show_secret("SECRET: %s (%d/%d)" % [title, found, total]))
	checkpoint_activated.connect(func(id: StringName, position_value: Vector3):
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager:
			var difficulty_state := get_node_or_null("/root/GameState")
			save_manager.save_slot(&"checkpoint", {
				"scene_path": "res://scenes/levels/episode_1_level_1.tscn",
				"level_id": String(metadata.level_id),
				"checkpoint_id": String(id),
				"position": [position_value.x, position_value.y, position_value.z],
				"difficulty_id": String(difficulty_state.difficulty_id) if difficulty_state != null else CheckpointPayload.DEFAULT_DIFFICULTY,
				"objective_snapshot": _mission_runtime.snapshot().objective_snapshot,
				"encounter_snapshot": _mission_runtime.snapshot().encounter_snapshot,
				"secrets": secrets.duplicate(true),
			})
	)
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.run_ended.connect(func(summary: Dictionary):
			_hud.visible = false
			_pause_menu.set_suppressed(true)
			_pause_menu.visible = false
			_victory_screen.show_summary(summary)
		, CONNECT_ONE_SHOT)


func _on_player_died_for_ui(_source: Node) -> void:
	if _mobile_controls != null: _mobile_controls.release_all()
	if _pause_menu != null:
		_pause_menu.close_for_death()
	_death_screen.show_death()


func _spawn_enemy_drop(drop_id: StringName, position_value: Vector3) -> Node:
	# Enemy definitions authored a drop_id contract that previously had no
	# listener, so drops silently never appeared.
	var path := "res://scenes/pickups/%s.tscn" % drop_id
	if not ResourceLoader.exists(path, "PackedScene"):
		push_warning("Enemy drop has no pickup scene: %s" % drop_id)
		return null
	return _spawn_pickup(path, Vector3(position_value.x, 0.8, position_value.z))


func _spawn_pickup(path: String, position_value: Vector3) -> Node:
	var pickup := _spawn_scene(path, position_value)
	if pickup and pickup.has_signal("collected"):
		pickup.collected.connect(func(_pickup, _collector, message):
			narrative_message.emit(message, 2.0)
			var game_state := get_node_or_null("/root/GameState")
			if game_state != null: game_state.record_pickup()
		)
	return pickup


func _on_interaction_secret_requested(secret_id: StringName, title: String, _source: Node) -> void:
	_discover_secret(secret_id, title)


func _on_interaction_loot_requested(loot_scene: String, count: int, source: Node) -> void:
	var actor := source as Node3D
	if actor == null:
		actor = player
	var base_position := actor.global_position if actor != null else Vector3.ZERO
	var safe_count := clampi(count, 1, 8)
	for index in safe_count:
		var angle := TAU * float(index) / float(max(safe_count, 1))
		var radius := 0.72 + 0.14 * float(index % 4)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
		var drop_position := Vector3(base_position.x + offset.x, max(0.8, base_position.y), base_position.z + offset.z)
		if player != null and player.global_position.distance_to(drop_position) < 0.4:
			drop_position += Vector3(0.36, 0.0, 0.36)
		_spawn_pickup(loot_scene, drop_position)


func _spawn_scene(path: String, position_value: Vector3) -> Node:
	if not ResourceLoader.exists(path):
		push_warning("Optional level dependency missing: " + path); return null
	var packed := _spawn_registry.resolve_scene(path) if _spawn_registry != null else load(path) as PackedScene
	if packed == null: return null
	var instance := packed.instantiate()
	# Place actors before _ready() runs so hover origins, drone flight heights,
	# and physics interpolation all begin at the intended world transform.
	if instance is Node3D: instance.position = position_value
	_actors.add_child(instance)
	if _spawn_registry != null: _spawn_registry.register_actor(instance)
	return instance


func _message(text: String) -> void:
	narrative_message.emit(text, 2.5)


func _exit_tree() -> void:
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null:
		pressure.configure_limit(_baseline_attack_budget, true)


func _sign(text: String, position_value: Vector3, rotation_y: float) -> void:
	var sign := SignScene.instantiate() as NarrativeSign; sign.sign_text = text; sign.position = position_value; sign.rotation_degrees.y = rotation_y; sign.read.connect(_on_sign_read); _interactables.add_child(sign)


func _wall_pair(x: float, z: float, length: float) -> void:
	_box("Boundary", Vector3(-x, 2, z), Vector3(0.6, 4, length), Color("34434a"))
	_box("Boundary", Vector3(x, 2, z), Vector3(0.6, 4, length), Color("34434a"))


func _box(node_name: String, center: Vector3, size: Vector3, color: Color, surface_type: StringName = &"concrete") -> CSGBox3D:
	var box := CSGBox3D.new(); box.name = node_name; box.position = center; box.size = size; box.use_collision = true
	box.set_meta(&"surface_type", surface_type)
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.95; box.material = material
	_geometry.add_child(box)
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
	_geometry.add_child(navigation_source)
	_navigation_sources.append(navigation_source)
	return box


func _prop_box(node_name: String, center: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var prop := MeshInstance3D.new(); prop.name = node_name; prop.position = center
	var mesh := BoxMesh.new(); mesh.size = size; prop.mesh = mesh
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.88; mesh.material = material
	_geometry.add_child(prop)
	return prop


func _add_weather_to_player() -> void:
	var quality := get_node_or_null("/root/QualityManager")
	var rain_amount := 420 if quality == null or quality.current == null else mini(420, quality.current.particle_budget)
	var rain := GPUParticles3D.new(); rain.name = "StormRain"; rain.position.y = 8.0; rain.amount = rain_amount; rain.lifetime = 1.25; rain.visibility_aabb = AABB(Vector3(-16, -12, -16), Vector3(32, 24, 32))
	var process := ParticleProcessMaterial.new(); process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; process.emission_box_extents = Vector3(14, 1, 14); process.direction = Vector3(0.12, -1, 0.05); process.spread = 4.0; process.initial_velocity_min = 15.0; process.initial_velocity_max = 20.0; rain.process_material = process
	var drop := QuadMesh.new(); drop.size = Vector2(0.018, 0.48)
	var drop_material := StandardMaterial3D.new(); drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; drop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; drop_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; drop_material.albedo_color = Color(0.58, 0.76, 0.86, 0.5); drop.material = drop_material; rain.draw_pass_1 = drop
	player.add_child(rain)
