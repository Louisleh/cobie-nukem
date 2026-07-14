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

const SalmonCreekWorldBuilderScene = preload("res://scripts/level/salmon_creek_world_builder.gd")
const SalmonCreekPacing = preload("res://resources/encounters/salmon_walker_pacing.tres")
const MissionInteractionRuntimeScript = preload("res://scripts/gameplay/mission_interaction_runtime.gd")
const ROUTE_PROGRESS := [
	[-22.0, &"equipment_shed", "EQUIPMENT SHED"],
	[-47.0, &"maintenance_tunnels", "MAINTENANCE TUNNELS"],
	[-87.0, &"compliance_lab", "ANIMAL COMPLIANCE LAB"],
	[-127.0, &"walker_arena", "ANIMAL CONTROL WALKER"],
]
const ZONE_AMBIENCE: Dictionary = {
	&"forbidden_field": &"salmon_ambience_exterior",
	&"equipment_shed": &"salmon_ambience_exterior",
	&"maintenance_tunnels": &"salmon_ambience_tunnel",
	&"compliance_lab": &"salmon_ambience_lab",
	&"walker_arena": &"salmon_ambience_arena",
}

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
var _mission_presentation: MissionPresentation
var _spawn_registry: MissionSpawnRegistry
var _navigation_region: NavigationRegion3D
var _world_builder: SalmonCreekWorldBuilder
var _walker_phase_rewards: Dictionary = {}
var _walker_phase_pickups: Array[Node] = []
var _walker_cannon_attacks := 0
var _baseline_attack_budget := 3

func _ready() -> void:
	_run_started_ms = Time.get_ticks_msec()
	_apply_requested_checkpoint()
	_setup_gameplay_systems()
	_build_level()
	_setup_interaction_runtime()
	if spawn_player: _spawn_player()
	if setup_presentation: _setup_presentation()
	if start_run_automatically and get_node_or_null("/root/GameState"):
		var game_state := get_node("/root/GameState")
		game_state.begin_run(metadata.level_id)
		if not _restored_checkpoint.is_empty():
			game_state.run_stats["checkpoint_id"] = String(_restored_checkpoint.get("checkpoint_id", "start"))
	narrative_message.emit("EPISODE 1, LEVEL 1: %s\n%s" % [metadata.title, metadata.subtitle], 4.0)
	level_ready.emit(player)
	var announced := _mission_runtime.announce_available_objectives()
	if announced.is_empty():
		objective_changed.emit(metadata.opening_objective)
	# Ensure the opening encounter exists even when body-enter events settle before connections.
	_enter_zone(&"forbidden_field", "FORBIDDEN FIELD", player)


func _setup_gameplay_systems() -> void:
	_spawn_registry = MissionSpawnRegistry.new()
	_spawn_registry.name = "MissionSpawnRegistry"
	add_child(_spawn_registry)
	_spawn_registry.prewarm_encounters(content_manifest.encounters)
	_spawn_registry.configure_staged_zone(&"forbidden_field")
	_spawn_registry.pickup_collected.connect(_on_spawn_registry_pickup_collected)
	spawned_zones = _spawn_registry.completed_zones
	_mission_runtime = MissionRuntime.new()
	_mission_runtime.name = "MissionRuntime"
	add_child(_mission_runtime)
	_mission_runtime.configure(content_manifest, _spawn_scene)
	_objective_tracker = _mission_runtime.objectives
	_encounter_runner = _mission_runtime.encounters
	_mission_runtime.objective_activated.connect(_on_mission_objective_activated)
	_mission_runtime.actor_spawned.connect(_on_encounter_actor_spawned)
	_mission_runtime.actor_defeated.connect(_on_mission_actor_defeated)
	_mission_runtime.encounter_completed.connect(_on_mission_encounter_completed)
	_mission_runtime.encounter_failed.connect(_on_mission_encounter_failed)
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null:
		_baseline_attack_budget = pressure.maximum_attackers
	_restore_mission_snapshot()
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
	_world_builder = SalmonCreekWorldBuilderScene.new()
	_world_builder.name = "SalmonCreekWorldBuilder"
	_world_builder.pickup_spawn_callable = Callable(self, "_spawn_pickup")
	_world_builder.on_zone_entered = Callable(self, "_enter_zone")
	_world_builder.on_narrative_message = Callable(self, "_emit_narrative_message")
	_world_builder.on_sign_read = Callable(self, "_on_sign_read")
	_world_builder.on_secret_discovered = Callable(self, "_discover_secret")
	_world_builder.on_objective_action = Callable(_objective_tracker, "record")
	_world_builder.on_checkpoint_activated = Callable(self, "_on_checkpoint")
	_world_builder.on_golden_ball_claimed = Callable(self, "_on_golden_ball_claimed")
	add_child(_world_builder)
	_world_builder.build(self)
	_geometry = _world_builder.geometry
	_actors = _world_builder.actors
	_interactables = _world_builder.interactables
	_golden_ball = _world_builder.golden_ball
	_navigation_region = _world_builder.navigation_region
	_spawn_registry.actor_parent = _actors
	_world_builder.populate_pickups()


func _emit_narrative_message(text: String, duration: float) -> void:
	narrative_message.emit(text, duration)


func _enter_zone(zone_id: StringName, title: String, _actor: Node) -> void:
	current_zone = zone_id; zone_entered.emit(zone_id, title); narrative_message.emit(title, 2.0)
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.run_stats["last_zone"] = String(zone_id)
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.REACH_ZONE, zone_id)
	_spawn_wave(zone_id)


func _spawn_wave(zone_id: StringName) -> void:
	if _spawn_registry.completed_zones.has(zone_id):
		return
	if _encounter_runner.definitions.has(zone_id):
		_last_combat_zone = zone_id
		var definition := _encounter_runner.definitions[zone_id] as EncounterDefinition
		var pressure := get_node_or_null("/root/CombatPressure")
		if pressure != null:
			pressure.configure_limit(mini(_baseline_attack_budget, definition.maximum_simultaneous_attackers))
		_spawn_registry.prepare_encounter(definition, _resetting_encounter)
		var spawned_actors := _mission_runtime.activate_zone(zone_id, player)
		if spawned_actors.size() > 0 or _encounter_runner.active.has(zone_id) or _encounter_runner.completed.has(zone_id):
			_spawn_registry.mark_zone_spawned(zone_id)
		elif _encounter_runner.failed.has(zone_id):
			_spawn_registry.clear_zone(zone_id)
	else:
		_spawn_registry.mark_zone_spawned(zone_id)
	if zone_id == &"walker_arena" and _walker == null:
		# Development fallback: a missing boss scene must not trap QA in the level.
		_golden_ball.enable_for_boss(null)
		narrative_message.emit("BOSS ASSET MISSING — GOLDEN BALL QA FALLBACK ENABLED.", 4.0)
	if zone_id == &"forbidden_field":
		_opening_grace_timer.start()


func _on_mission_objective_activated(definition: ObjectiveDefinition) -> void:
	objective_changed.emit(definition.title)


func _on_mission_actor_defeated(enemy: Node, definition: EncounterDefinition) -> void:
	_on_enemy_died(enemy, definition.zone_id)


func _on_mission_encounter_failed(definition: EncounterDefinition, _reason: String) -> void:
	_spawn_registry.finish_encounter(definition.zone_id)
	_spawn_registry.clear_zone(definition.zone_id)


func _on_mission_encounter_completed(definition: EncounterDefinition) -> void:
	_spawn_registry.finish_encounter(definition.zone_id)


func _on_encounter_actor_spawned(enemy: Node, definition: EncounterDefinition) -> void:
	if enemy is ComplianceHound: enemy.name = "FetchGuard"
	_spawn_registry.register_encounter_actor(enemy, definition, _resetting_encounter)
	enemy_spawned.emit(enemy, definition.zone_id)
	_bind_enemy_captions(enemy)
	if enemy is AnimalControlWalker: _bind_walker(enemy)
	_sync_spawn_runtime_state()


func _bind_enemy_captions(enemy: Node) -> void:
	if _mission_presentation == null:
		return
	_mission_presentation.bind_warning_enemy(enemy)


func _activate_opening_encounter(_weapon: WeaponBase = null, _secondary := false) -> void:
	_spawn_registry.activate_staged_enemies(player)
	_sync_spawn_runtime_state()


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
	enemies_defeated = _spawn_registry.record_enemy_defeat(); enemy_defeated.emit(enemy, zone_id)
	var game_state := get_node_or_null("/root/GameState")
	if game_state: game_state.run_stats.enemies_defeated = enemies_defeated
	_sync_spawn_runtime_state()


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
	if _mission_presentation != null:
		_mission_presentation.on_checkpoint_caption("CHECKPOINT: GOOD DOG STATUS TEMPORARILY RESTORED.")
	elif _hud != null:
		_hud.show_checkpoint_caption("CHECKPOINT: GOOD DOG STATUS TEMPORARILY RESTORED.", 2.5)
	narrative_message.emit("CHECKPOINT: GOOD DOG STATUS TEMPORARILY RESTORED.", 2.5)
	_save_checkpoint_payload(id, position_value)
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.run_stats["checkpoint_id"] = String(id)


func _save_checkpoint_payload(id: StringName, position_value: Vector3) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
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


func restart_from_checkpoint() -> void:
	if _interaction_runtime != null:
		# Secrets are permanent for the current run even when the player dies;
		# checkpoint saves persist the same dictionary across app restarts.
		_interaction_runtime.reset_for_checkpoint({"secrets": secrets})
	if _mission_presentation != null:
		_mission_presentation.reset_for_checkpoint()
	elif _combat_audio != null:
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
	_mission_runtime.reset_zone(zone_id)
	_spawn_registry.clear_zone(zone_id)
	if zone_id == &"forbidden_field":
		_spawn_registry.reset_staged_enemies()
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
	_sync_spawn_runtime_state()


func _on_golden_ball_claimed(_actor: Node) -> void:
	if completion_started: return
	# A finished run must not offer a stale mid-level Continue from the menu.
	completion_started = true
	_objective_tracker.record(ObjectiveDefinition.Kind.COLLECT_ITEM, &"golden_tennis_ball")
	narrative_message.emit("THEY SAID NO ANIMALS. THEY SHOULD HAVE SAID PLEASE.", 5.0)
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
		if _mission_presentation != null:
			_mission_presentation.set_player(player)
		else:
			_add_weather_to_player()
		for weapon in player.weapons:
			weapon.fired.connect(_activate_opening_encounter)
		if player.has_signal("died"): player.died.connect(func(_source):
			narrative_message.emit("GOOD DOG DOWN. PRESS FIRE TO RESTART.", 3.0)
			var game_state := get_node_or_null("/root/GameState")
			if game_state: game_state.run_stats["deaths"] = int(game_state.run_stats.get("deaths", 0)) + 1
			_on_player_died_for_ui(_source)
		)
		if player.has_signal("restart_requested"): player.restart_requested.connect(restart_from_checkpoint)


func _setup_presentation() -> void:
	if _mission_presentation == null:
		_mission_presentation = MissionPresentation.new()
		_mission_presentation.name = "MissionPresentation"
		add_child(_mission_presentation)
	_mission_presentation.configure(self, content_manifest, _actors, _encounter_runner, _mission_runtime, player, get_node_or_null("/root/GameState"), &"forbidden_field", &"walker_arena", ZONE_AMBIENCE)
	_hud = _mission_presentation.get_hud()
	_pause_menu = _mission_presentation.get_pause_menu()
	_death_screen = _mission_presentation.get_death_screen()
	_victory_screen = _mission_presentation.get_victory_screen()
	_combat_audio = _mission_presentation.get_combat_audio_bridge()
	_mobile_controls = _mission_presentation.get_mobile_controls()
	_mission_presentation.bind_restart_requests(restart_from_checkpoint)


func _on_player_died_for_ui(_source: Node) -> void:
	if _mission_presentation != null:
		_mission_presentation.on_player_died(_source)
	else:
		if _mobile_controls != null: _mobile_controls.release_all()
		if _pause_menu != null:
			_pause_menu.close_for_death()
		if _death_screen != null:
			_death_screen.show_death()


func _spawn_enemy_drop(drop_id: StringName, position_value: Vector3) -> Node:
	return _spawn_registry.spawn_enemy_drop(drop_id, position_value)


func _spawn_pickup(path: String, position_value: Vector3) -> Node:
	return _spawn_registry.spawn_pickup(path, position_value)


func _on_interaction_secret_requested(secret_id: StringName, title: String, _source: Node) -> void:
	_discover_secret(secret_id, title)


func _on_interaction_loot_requested(loot_scene: String, count: int, source: Node) -> void:
	var actor := source as Node3D
	if actor == null:
		actor = player
	_spawn_registry.spawn_loot_burst(loot_scene, count, actor, player)


func _spawn_scene(path: String, position_value: Vector3) -> Node:
	return _spawn_registry.spawn_scene(path, position_value)


func _on_spawn_registry_pickup_collected(message: String) -> void:
	narrative_message.emit(message, 2.0)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.record_pickup()


func _sync_spawn_runtime_state() -> void:
	enemies_total = _spawn_registry.enemies_total
	enemies_defeated = _spawn_registry.enemies_defeated
	_opening_enemies = _spawn_registry.opening_enemies_snapshot()
	_opening_encounter_active = _spawn_registry.opening_enemies_active()


func _exit_tree() -> void:
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null:
		pressure.configure_limit(_baseline_attack_budget, true)


func _add_weather_to_player() -> void:
	if _mission_presentation == null:
		return
	_mission_presentation.add_player_rain()
