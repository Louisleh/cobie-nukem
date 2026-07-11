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

@export var metadata: LevelMetadata = preload("res://resources/level/episode_1_level_1.tres")
@export var spawn_player := true
@export var start_run_automatically := true

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

var waves := {
	&"forbidden_field": [
		["res://scenes/enemies/leash_enforcement_drone.tscn", Vector3(-5, 2, -4)],
		["res://scenes/enemies/leash_enforcement_drone.tscn", Vector3(5, 2, -9)],
		["res://scenes/enemies/mutant_groundskeeper.tscn", Vector3(0, 1, -14)],
	],
	&"equipment_shed": [
		["res://scenes/enemies/mutant_groundskeeper.tscn", Vector3(-3, 1, -31)],
		["res://scenes/enemies/leash_enforcement_drone.tscn", Vector3(3, 2, -37)],
	],
	&"maintenance_tunnels": [
		["res://scenes/enemies/squirrel_trooper.tscn", Vector3(-2, 1, -53)],
		["res://scenes/enemies/squirrel_trooper.tscn", Vector3(2, 1, -64)],
		["res://scenes/enemies/mutant_groundskeeper.tscn", Vector3(0, 1, -74)],
	],
	&"compliance_lab": [
		["res://scenes/enemies/leash_enforcement_drone.tscn", Vector3(-7, 2, -94)],
		["res://scenes/enemies/leash_enforcement_drone.tscn", Vector3(7, 2, -103)],
		["res://scenes/enemies/compliance_hound.tscn", Vector3(0, 1, -114)],
	],
	&"walker_arena": [
		["res://scenes/enemies/animal_control_walker.tscn", Vector3(0, 1, -150)],
	],
}


func _ready() -> void:
	_run_started_ms = Time.get_ticks_msec()
	_build_level()
	if spawn_player: _spawn_player()
	_setup_presentation()
	if start_run_automatically and get_node_or_null("/root/GameState"):
		get_node("/root/GameState").begin_run(metadata.level_id)
	objective_changed.emit(metadata.opening_objective)
	narrative_message.emit("EPISODE 1, LEVEL 1: %s\n%s" % [metadata.title, metadata.subtitle], 4.0)
	level_ready.emit(player)
	# Ensure the opening encounter exists even when body-enter events settle before connections.
	_enter_zone(&"forbidden_field", "FORBIDDEN FIELD", player)


func _build_level() -> void:
	_geometry = Node3D.new(); _geometry.name = "Geometry"; add_child(_geometry)
	_actors = Node3D.new(); _actors.name = "Actors"; add_child(_actors)
	_interactables = Node3D.new(); _interactables.name = "Interactables"; add_child(_interactables)
	_build_lighting()
	_build_route_geometry()
	_build_story_objects()
	_build_pickups()
	_build_zone_triggers()


func _build_lighting() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("25343b"); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("8da399"); env.ambient_light_energy = 0.48; env.fog_enabled = true; env.fog_light_color = Color("667a78"); env.fog_density = 0.008; env.fog_aerial_perspective = 0.55
	environment.environment = env; add_child(environment)
	var moon := DirectionalLight3D.new(); moon.rotation_degrees = Vector3(-58, -25, 0); moon.light_color = Color("a9c5d6"); moon.light_energy = 1.1; moon.shadow_enabled = true; add_child(moon)


func _build_route_geometry() -> void:
	# Continuous route: field → shed → tunnels → lab → walker arena.
	_box("WetSportsField", Vector3(0, -0.5, 0), Vector3(26, 1, 36), Color("315448"))
	_box("ShedFloor", Vector3(0, -0.5, -32), Vector3(15, 1, 25), Color("495057"))
	_box("TunnelFloor", Vector3(0, -0.5, -64), Vector3(10, 1, 39), Color("37474f"))
	_box("LabFloor", Vector3(0, -0.5, -103), Vector3(24, 1, 38), Color("56636a"))
	_box("DogParkFloor", Vector3(22, -0.5, -103), Vector3(18, 1, 22), Color("3d6b45"))
	_box("ArenaFloor", Vector3(0, -0.5, -147), Vector3(36, 1, 40), Color("514444"))
	_box("ConnectorA", Vector3(0, -0.5, -20), Vector3(8, 1, 5), Color("555b60"))
	_box("ConnectorB", Vector3(0, -0.5, -45), Vector3(8, 1, 4), Color("414b50"))
	_box("ConnectorC", Vector3(0, -0.5, -84), Vector3(8, 1, 4), Color("4b575d"))
	_box("ConnectorD", Vector3(0, -0.5, -124), Vector3(10, 1, 5), Color("564949"))
	# Side boundaries leave the main route readable while stopping accidental skips.
	_wall_pair(13, 0, 36); _wall_pair(7.5, -32, 25); _wall_pair(5, -64, 39); _wall_pair(12, -103, 38); _wall_pair(18, -147, 40)
	# Tunnels and lab receive low ceilings; exterior zones remain storm-open.
	_box("TunnelCeiling", Vector3(0, 4.2, -64), Vector3(10, 0.5, 39), Color("29353a"))
	_box("LabCeiling", Vector3(0, 5.0, -103), Vector3(24, 0.5, 38), Color("39464c"))
	# Arena cover makes the boss readable under flight-stick auto-aim.
	for pos in [Vector3(-10, 1, -140), Vector3(10, 1, -140), Vector3(-10, 1, -156), Vector3(10, 1, -156)]:
		_box("ArenaCover", pos, Vector3(3, 2, 3), Color("70584d"))


func _build_story_objects() -> void:
	var opening_sign := SignScene.instantiate() as NarrativeSign
	opening_sign.sign_id = &"no_animals"; opening_sign.sign_text = "NO ANIMALS\nON SPORTS FIELD"; opening_sign.secret_after_reads = 3; opening_sign.secret_id = &"optional_sign"; opening_sign.secret_title = "SIGN SEEMS OPTIONAL"; opening_sign.position = Vector3(-6, 1.4, 9); opening_sign.rotation_degrees.y = 180
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
	var lab_switch := SwitchScene.instantiate() as LevelSwitch; lab_switch.switch_id = &"walker_release"; lab_switch.prompt = "OVERRIDE ANIMAL CONTROL"; lab_switch.position = Vector3(8.5, 1.2, -117); _interactables.add_child(lab_switch); lab_switch.target_path = lab_switch.get_path_to(arena_gate); lab_switch.activated.connect(func(_id, _actor): objective_changed.emit("DEFEAT THE ANIMAL CONTROL WALKER"))

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
	if zone_id == &"compliance_lab": objective_changed.emit("EXPOSE THE ANIMAL COMPLIANCE FACILITY")
	if zone_id == &"walker_arena": objective_changed.emit("DEFEAT THE ANIMAL CONTROL WALKER")
	_spawn_wave(zone_id)


func _spawn_wave(zone_id: StringName) -> void:
	if spawned_zones.has(zone_id): return
	spawned_zones[zone_id] = true
	for entry in waves.get(zone_id, []):
		var enemy := _spawn_scene(entry[0], entry[1])
		if enemy:
			enemies_total += 1
			if zone_id == &"forbidden_field":
				enemy.process_mode = Node.PROCESS_MODE_DISABLED
				var delayed_enemy := enemy
				get_tree().create_timer(3.5).timeout.connect(func():
					if is_instance_valid(delayed_enemy):
						delayed_enemy.process_mode = Node.PROCESS_MODE_INHERIT
						if delayed_enemy.has_method("set_target") and player: delayed_enemy.set_target(player)
				)
			elif enemy.has_method("set_target") and player:
				enemy.set_target(player)
			if enemy.has_signal("died"): enemy.died.connect(func(dead_enemy, _source): _on_enemy_died(dead_enemy, zone_id))
			enemy_spawned.emit(enemy, zone_id)
			if enemy is AnimalControlWalker: _bind_walker(enemy)
	if zone_id == &"walker_arena" and _walker == null:
		# Development fallback: a missing boss scene must not trap QA in the level.
		_golden_ball.enable_for_boss(null)
		narrative_message.emit("BOSS ASSET MISSING — GOLDEN BALL QA FALLBACK ENABLED.", 4.0)


func _bind_walker(walker: Node) -> void:
	_walker = walker
	if walker.has_signal("golden_ball_enabled"): walker.golden_ball_enabled.connect(func(target): _golden_ball.enable_for_boss(target); objective_changed.emit("FETCH THE GOLDEN TENNIS BALL"))
	if walker.has_signal("boss_phase_changed"): walker.boss_phase_changed.connect(func(_old, phase): boss_state_changed.emit(StringName(str(phase)), walker.health_fraction()))
	if walker.has_signal("walker_defeated"): walker.walker_defeated.connect(func(): boss_state_changed.emit(&"defeated", 0.0))


func _on_enemy_died(enemy: Node, zone_id: StringName) -> void:
	enemies_defeated += 1; enemy_defeated.emit(enemy, zone_id)
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
	checkpoint_position = position_value; checkpoint_activated.emit(id, position_value); narrative_message.emit("CHECKPOINT: GOOD DOG STATUS TEMPORARILY RESTORED.", 2.5)


func restart_from_checkpoint() -> void:
	if player:
		if player.has_method("respawn"):
			player.respawn(checkpoint_position)
		else:
			player.global_position = checkpoint_position
			if player.has_method("restore_full"): player.restore_full()
			if "velocity" in player: player.velocity = Vector3.ZERO
	if _death_screen:
		_death_screen.visible = false


func _on_golden_ball_claimed(_actor: Node) -> void:
	if completion_started: return
	completion_started = true
	narrative_message.emit("THEY SAID NO ANIMALS. THEY SHOULD HAVE SAID PLEASE.", 5.0)
	await get_tree().create_timer(1.2).timeout
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
		if player.has_signal("died"): player.died.connect(func(_source): narrative_message.emit("GOOD DOG DOWN. PRESS FIRE TO RESTART.", 3.0))
		if player.has_signal("restart_requested"): player.restart_requested.connect(restart_from_checkpoint)


func _setup_presentation() -> void:
	_hud = HUDScene.instantiate() as GameHUD
	_pause_menu = PauseScene.instantiate() as PauseMenu
	_death_screen = DeathScene.instantiate() as DeathScreen
	_victory_screen = VictoryScene.instantiate() as VictoryScreen
	_combat_audio = CombatAudioScene.instantiate() as CombatAudioBridge
	add_child(_hud)
	add_child(_pause_menu)
	add_child(_death_screen)
	add_child(_victory_screen)
	add_child(_combat_audio)
	if player:
		_hud.bind_player(player)
		_combat_audio.bind_player(player)
		if player.has_signal("died"):
			player.died.connect(func(_source): _death_screen.show_death())
	_pause_menu.restart_requested.connect(restart_from_checkpoint)
	_death_screen.retry_requested.connect(restart_from_checkpoint)
	narrative_message.connect(func(text: String, _duration: float): _hud.show_notification(text))
	objective_changed.connect(func(text: String): _hud.show_notification("OBJECTIVE: " + text))
	secret_found.connect(func(_id: StringName, title: String, found: int, total: int): _hud.show_secret("SECRET: %s (%d/%d)" % [title, found, total]))
	checkpoint_activated.connect(func(id: StringName, position_value: Vector3):
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager:
			save_manager.save_slot(&"checkpoint", {
				"scene_path": "res://scenes/levels/episode_1_level_1.tscn",
				"level_id": String(metadata.level_id),
				"checkpoint_id": String(id),
				"position": [position_value.x, position_value.y, position_value.z],
			})
	)
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.run_ended.connect(func(summary: Dictionary):
			_hud.visible = false
			_pause_menu.visible = false
			_victory_screen.show_summary(summary)
		, CONNECT_ONE_SHOT)


func _spawn_pickup(path: String, position_value: Vector3) -> Node:
	var pickup := _spawn_scene(path, position_value)
	if pickup and pickup.has_signal("collected"):
		pickup.collected.connect(func(_pickup, _collector, message): narrative_message.emit(message, 2.0))
	return pickup


func _spawn_scene(path: String, position_value: Vector3) -> Node:
	if not ResourceLoader.exists(path):
		push_warning("Optional level dependency missing: " + path); return null
	var packed := load(path) as PackedScene
	if packed == null: return null
	var instance := packed.instantiate(); _actors.add_child(instance)
	if instance is Node3D: instance.global_position = position_value
	return instance


func _message(text: String) -> void:
	narrative_message.emit(text, 2.5)


func _sign(text: String, position_value: Vector3, rotation_y: float) -> void:
	var sign := SignScene.instantiate() as NarrativeSign; sign.sign_text = text; sign.position = position_value; sign.rotation_degrees.y = rotation_y; sign.read.connect(_on_sign_read); _interactables.add_child(sign)


func _wall_pair(x: float, z: float, length: float) -> void:
	_box("Boundary", Vector3(-x, 2, z), Vector3(0.6, 4, length), Color("34434a"))
	_box("Boundary", Vector3(x, 2, z), Vector3(0.6, 4, length), Color("34434a"))


func _box(node_name: String, center: Vector3, size: Vector3, color: Color) -> CSGBox3D:
	var box := CSGBox3D.new(); box.name = node_name; box.position = center; box.size = size; box.use_collision = true
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.95; box.material = material
	_geometry.add_child(box); return box
