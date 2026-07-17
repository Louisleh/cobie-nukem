class_name EpisodeOneVancouverWaterfront
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
signal boss_phase_caption(text: String, duration: float)
signal level_completed(summary: Dictionary)

const WorldBuilderScript = preload("res://scripts/level/vancouver_waterfront_world_builder.gd")
const PLAYER_SCENE := "res://scenes/player/cobie_player.tscn"
const CONTENT_REVISION := 2
const MUNICIPAL_RECALL_OVERRIDE := &"municipal_recall_override"
const CHECKPOINT_POSITIONS: Dictionary = {
	&"checkpoint_downtown_alley": Vector3(0, 1.1, 8),
	&"checkpoint_ruse_block": Vector3(0, 1.1, -23),
	&"checkpoint_waterfront_seawall": Vector3(0, 1.1, -56),
	&"checkpoint_terminal_service": Vector3(0, 1.1, -98),
	&"checkpoint_harbour_pier": Vector3(0, 1.1, -131),
	&"checkpoint_harbour_clear": Vector3(0, 1.1, -165),
}

@export var metadata: LevelMetadata = preload("res://resources/level/episode_1_vancouver_waterfront.tres")
@export var content_manifest: ContentManifest = preload("res://resources/content/vancouver_waterfront_manifest.tres")
@export var spawn_player := true
@export var start_run_automatically := true
@export var setup_presentation := true
@export var opening_protection_seconds := 10.0

var player: Node3D
var current_zone: StringName = &""
var checkpoint_position := Vector3(0, 1.1, 8)
var secrets: Dictionary = {}
var enemies_total := 0
var enemies_defeated := 0

var _run_started_ms := 0
var _completion_started := false
var _restored_checkpoint: Dictionary = {}
var _world_builder: VancouverWaterfrontWorldBuilder
var _mission_runtime: MissionRuntime
var _route_runtime: MissionRouteRuntime
var _spawn_registry: MissionSpawnRegistry
var _interaction_runtime: MissionInteractionRuntime
var _mission_presentation: MissionPresentation
var _set_piece_runtime: MovingSetPieceRuntime
var _convoy_coordinator: MovingSetPieceEncounterCoordinator
var _route_recovery_timer: Timer
var _completion_timer: Timer
var _last_combat_zone: StringName = &""
var _resetting_encounter := false
var _mission_upgrades: Array[StringName] = []
var _baseline_attack_budget := 3


func _ready() -> void:
	_run_started_ms = Time.get_ticks_msec()
	_apply_requested_checkpoint()
	_setup_runtime()
	_build_world()
	_setup_interactions()
	_rehydrate_restored_gameplay()
	if spawn_player:
		_spawn_player()
	if setup_presentation:
		_setup_presentation()
	if start_run_automatically:
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.begin_run(metadata.level_id)
	narrative_message.emit("EPISODE 1, MISSION 2: RAIN CITY RUN\nPUBLIC BETA PREVIEW", 4.0)
	level_ready.emit(player)
	var announced := _mission_runtime.announce_available_objectives()
	if announced.is_empty():
		objective_changed.emit(metadata.opening_objective)
	if is_instance_valid(player):
		_submit_route_position(player.global_position)


func _setup_runtime() -> void:
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null:
		_baseline_attack_budget = 2 if GameState.difficulty_id == &"story" else (4 if GameState.difficulty_id == &"mayhem" else 3)
		pressure.configure_limit(_baseline_attack_budget)
	_spawn_registry = MissionSpawnRegistry.new()
	_spawn_registry.name = "MissionSpawnRegistry"
	add_child(_spawn_registry)
	_spawn_registry.prewarm_encounters(content_manifest.encounters)
	_spawn_registry.pickup_collected.connect(_on_pickup_collected)

	_mission_runtime = MissionRuntime.new()
	_mission_runtime.name = "MissionRuntime"
	add_child(_mission_runtime)
	_mission_runtime.configure(content_manifest, _spawn_scene)
	_mission_runtime.objective_activated.connect(_on_objective_activated)
	_mission_runtime.objective_completed.connect(_on_objective_completed)
	_mission_runtime.actor_spawned.connect(_on_actor_spawned)
	_mission_runtime.actor_defeated.connect(_on_actor_defeated)
	_mission_runtime.encounter_completed.connect(_on_encounter_completed)
	_mission_runtime.encounter_failed.connect(_on_encounter_failed)

	_route_runtime = _mission_runtime.route
	if _route_runtime == null:
		push_error("Vancouver route runtime rejected the authored route")
	else:
		_mission_runtime.zone_entered.connect(_on_route_zone_entered)
		_mission_runtime.checkpoint_available.connect(_on_route_checkpoint_available)

	_route_recovery_timer = Timer.new()
	_route_recovery_timer.name = "RouteRecoveryTimer"
	_route_recovery_timer.wait_time = 0.2
	_route_recovery_timer.timeout.connect(_poll_route_position)
	add_child(_route_recovery_timer)
	_route_recovery_timer.start()

	_completion_timer = Timer.new()
	_completion_timer.name = "CompletionTimer"
	_completion_timer.one_shot = true
	_completion_timer.wait_time = 1.2
	_completion_timer.timeout.connect(_finalize_completion)
	add_child(_completion_timer)
	_restore_runtime_state()


func _build_world() -> void:
	_world_builder = WorldBuilderScript.new()
	_world_builder.name = "VancouverWaterfrontWorldBuilder"
	_world_builder.on_zone_entered = _on_world_zone_entered
	_world_builder.on_checkpoint_activated = _on_world_checkpoint
	_world_builder.on_objective_action = _mission_runtime.record_objective
	_world_builder.on_narrative_message = narrative_message.emit
	add_child(_world_builder)
	if not _world_builder.build(self):
		push_error("Vancouver world builder failed")
		return
	_spawn_registry.actor_parent = _world_builder.actors
	_setup_convoy()


func _setup_convoy() -> void:
	if content_manifest.moving_set_pieces.size() != 1:
		push_error("Vancouver requires exactly one citation convoy definition")
		return
	var definition := content_manifest.moving_set_pieces[0]
	_set_piece_runtime = MovingSetPieceRuntime.new()
	_set_piece_runtime.name = "CitationConvoyRuntime"
	add_child(_set_piece_runtime)
	var configure_error := _set_piece_runtime.configure(definition, _world_builder.actors)
	if configure_error != MovingSetPieceRuntime.ERROR_NONE:
		push_error("Citation convoy runtime rejected its definition: %s" % configure_error)
		return
	_set_piece_runtime.started.connect(_on_convoy_actor_started)
	_set_piece_runtime.completed.connect(_on_convoy_completed)
	_convoy_coordinator = MovingSetPieceEncounterCoordinator.new()
	_convoy_coordinator.name = "CitationConvoyCoordinator"
	add_child(_convoy_coordinator)
	var coordinator_error := _convoy_coordinator.configure(_set_piece_runtime, _mission_runtime, definition, &"harbour_pier")
	if coordinator_error != MovingSetPieceEncounterCoordinator.ERROR_NONE:
		push_error("Citation convoy coordinator rejected its definition: %s" % coordinator_error)


func _setup_interactions() -> void:
	if content_manifest.interaction_catalog == null or _world_builder == null:
		return
	_interaction_runtime = MissionInteractionRuntime.new()
	_interaction_runtime.name = "MissionInteractionRuntime"
	add_child(_interaction_runtime)
	if not _interaction_runtime.configure_from_payload(content_manifest, _world_builder.interactables, _restored_checkpoint, _spawn_registry):
		push_error("Vancouver interaction catalog failed to configure")
		_interaction_runtime.queue_free()
		_interaction_runtime = null
		return
	_interaction_runtime.secret_requested.connect(_on_secret_requested)
	_interaction_runtime.loot_requested.connect(_on_loot_requested)


func _setup_presentation() -> void:
	_mission_presentation = MissionPresentation.new()
	_mission_presentation.name = "MissionPresentation"
	add_child(_mission_presentation)
	_mission_presentation.configure(
		self,
		content_manifest,
		_world_builder.actors,
		_mission_runtime.encounters,
		_mission_runtime,
		player,
		get_node_or_null("/root/GameState"),
		&"downtown_alley",
		&"harbour_pier"
	)
	_mission_presentation.bind_restart_requests(restart_from_checkpoint)


func _spawn_player() -> void:
	player = _spawn_scene(PLAYER_SCENE, checkpoint_position) as Node3D
	if player == null:
		return
	if player is CobiePlayer:
		var cobie := player as CobiePlayer
		cobie.health_armor.grant_invulnerability(opening_protection_seconds)
		if metadata.mission_loadout != null:
			cobie.apply_mission_loadout(metadata.mission_loadout, _restored_checkpoint)
		_load_campaign_upgrades()
		var restored_upgrades: Dictionary = _restored_checkpoint.get("active_mission_upgrades", {})
		for raw_upgrade: Variant in restored_upgrades.get("mission_upgrades", []):
			var upgrade_id := StringName(raw_upgrade)
			if upgrade_id != &"" and upgrade_id not in _mission_upgrades:
				_mission_upgrades.append(upgrade_id)
		_apply_active_mission_upgrades(cobie)
	if _mission_presentation != null:
		_mission_presentation.set_player(player)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if player.has_signal("restart_requested"):
		player.restart_requested.connect(restart_from_checkpoint)


func _load_campaign_upgrades() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	var campaign := CampaignProgressRuntime.new()
	add_child(campaign)
	if campaign.configure(save_manager):
		campaign.load_progress()
		for raw_upgrade: Variant in campaign.mission_upgrades(metadata.level_id):
			var upgrade_id := StringName(raw_upgrade)
			if upgrade_id != &"" and upgrade_id not in _mission_upgrades:
				_mission_upgrades.append(upgrade_id)
	campaign.queue_free()


func _apply_requested_checkpoint() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state == null or not bool(game_state.get("continue_requested")):
		return
	var save_manager := get_node_or_null("/root/SaveManager")
	var saved := CheckpointPayload.sanitize(save_manager.load_slot(&"checkpoint")) if save_manager != null else {}
	if String(saved.get("level_id", "")) != String(metadata.level_id):
		game_state.continue_requested = false
		return
	_restored_checkpoint = saved
	var checkpoint_id := StringName(saved.get("checkpoint_id", ""))
	var values: Array = saved.get("position", [])
	if int(saved.get("content_revision", 0)) != CONTENT_REVISION and CHECKPOINT_POSITIONS.has(checkpoint_id):
		checkpoint_position = CHECKPOINT_POSITIONS[checkpoint_id]
	elif values.size() == 3:
		checkpoint_position = Vector3(float(values[0]), float(values[1]), float(values[2]))
	game_state.continue_requested = false


func _restore_runtime_state() -> void:
	if _restored_checkpoint.is_empty():
		return
	_mission_runtime.restore(_restored_checkpoint)
	for raw_id: Variant in _restored_checkpoint.get("secrets", {}):
		secrets[StringName(raw_id)] = String(_restored_checkpoint.secrets[raw_id])
	var route_snapshot: Dictionary = _restored_checkpoint.get("route_snapshot", {})
	if not route_snapshot.is_empty():
		_route_runtime.restore(route_snapshot)
	else:
		_restore_route_from_checkpoint(StringName(_restored_checkpoint.get("checkpoint_id", "")))
	current_zone = _route_runtime.current_zone


func _rehydrate_restored_gameplay() -> void:
	if _restored_checkpoint.is_empty() or _route_runtime == null:
		return
	current_zone = _route_runtime.current_zone
	var convoy_complete := _mission_runtime.objectives.completed.has(&"stop_citation_convoy")
	if _world_builder != null and _world_builder.departure_switch != null:
		_world_builder.departure_switch.set_enabled(convoy_complete)
	if current_zone == &"harbour_pier" and not convoy_complete:
		_last_combat_zone = &"harbour_pier"
		if _set_piece_runtime != null and not bool(_set_piece_runtime.current_state().get("has_actor", false)):
			_set_piece_runtime.start()
	elif current_zone != &"" and not _mission_runtime.encounters.completed.has(current_zone):
		_activate_zone_encounter(current_zone)


func _restore_route_from_checkpoint(checkpoint_id: StringName) -> void:
	var ordered := content_manifest.route_definition.ordered_zone_ids()
	var checkpoint_zone := &""
	for zone_id in ordered:
		var zone := content_manifest.route_definition.zone_for_id(zone_id)
		if zone != null and zone.checkpoint_ids.has(checkpoint_id):
			checkpoint_zone = zone_id
			break
	if checkpoint_zone == &"":
		return
	var target_index := ordered.find(checkpoint_zone)
	var visited: Array[String] = []
	for index in target_index + 1:
		visited.append(String(ordered[index]))
	_route_runtime.restore({
		"route_id": String(content_manifest.route_definition.route_id),
		"current_zone": String(checkpoint_zone),
		"current_index": target_index,
		"visited_zones": visited,
		"checkpoint_id": String(checkpoint_id),
		"is_completed": target_index == ordered.size() - 1,
	})
	current_zone = checkpoint_zone


func _poll_route_position() -> void:
	if is_instance_valid(player):
		_submit_route_position(player.global_position)


func _submit_route_position(position: Vector3) -> void:
	_mission_runtime.submit_actor_position(position)


func _on_world_zone_entered(_zone_id: StringName, _title: String, actor: Node) -> void:
	if actor is Node3D:
		_submit_route_position((actor as Node3D).global_position)


func _on_route_zone_entered(zone_id: StringName, title: String) -> void:
	if current_zone == zone_id:
		return
	current_zone = zone_id
	zone_entered.emit(zone_id, title)
	narrative_message.emit(title, 2.0)
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.REACH_ZONE, zone_id)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.run_stats["last_zone"] = String(zone_id)
	_clear_abandoned_encounters(zone_id)
	if zone_id != &"harbour_pier":
		_activate_zone_encounter(zone_id)
	elif _set_piece_runtime != null and _set_piece_runtime.current_state().get("has_actor", false) == false:
		_last_combat_zone = &"harbour_pier"
		_set_piece_runtime.start()


func _clear_abandoned_encounters(entering_zone: StringName) -> void:
	if _mission_runtime == null or _mission_runtime.encounters == null:
		return
	for raw_zone_id: Variant in _mission_runtime.encounters.active.keys().duplicate():
		var zone_id := StringName(raw_zone_id)
		if zone_id == entering_zone:
			continue
		_spawn_registry.clear_zone(zone_id)
		_mission_runtime.reset_zone(zone_id)


func _activate_zone_encounter(zone_id: StringName) -> void:
	if _mission_runtime.encounters == null or not _mission_runtime.encounters.definitions.has(zone_id):
		return
	if _mission_runtime.encounters.completed.has(zone_id) or _mission_runtime.encounters.active.has(zone_id):
		return
	_last_combat_zone = zone_id
	var definition := _mission_runtime.encounters.definitions[zone_id] as EncounterDefinition
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null:
		pressure.configure_limit(mini(_baseline_attack_budget, definition.maximum_simultaneous_attackers))
	_spawn_registry.prepare_encounter(definition, _resetting_encounter)
	var spawned := _mission_runtime.activate_zone(zone_id, player)
	if not spawned.is_empty() or _mission_runtime.encounters.active.has(zone_id):
		_spawn_registry.mark_zone_spawned(zone_id)


func _on_route_checkpoint_available(checkpoint_id: StringName, _zone_id: StringName) -> void:
	var position_value: Vector3 = CHECKPOINT_POSITIONS.get(checkpoint_id, checkpoint_position)
	_save_checkpoint(checkpoint_id, position_value)


func _on_world_checkpoint(checkpoint_id: StringName, respawn_position: Vector3) -> void:
	if _mission_runtime.activate_checkpoint(checkpoint_id):
		return
	if checkpoint_id == _route_runtime.current_checkpoint_id:
		checkpoint_position = respawn_position


func _save_checkpoint(checkpoint_id: StringName, position_value: Vector3) -> void:
	checkpoint_position = position_value
	checkpoint_activated.emit(checkpoint_id, position_value)
	narrative_message.emit("CHECKPOINT: RAIN DELAY APPROVED.", 2.2)
	if _mission_presentation != null:
		_mission_presentation.on_checkpoint_caption("CHECKPOINT: RAIN DELAY APPROVED.")
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null:
		return
	var runtime_snapshot := _mission_runtime.snapshot()
	var game_state := get_node_or_null("/root/GameState")
	var active_loadout: Dictionary = player.mission_loadout_snapshot(metadata.level_id, _mission_upgrades) if player is CobiePlayer else {}
	save_manager.save_slot(&"checkpoint", {
		"scene_path": "res://scenes/levels/episode_1_vancouver_waterfront.tscn",
		"level_id": String(metadata.level_id),
		"checkpoint_id": String(checkpoint_id),
		"content_revision": CONTENT_REVISION,
		"position": [position_value.x, position_value.y, position_value.z],
		"difficulty_id": String(game_state.difficulty_id) if game_state != null else CheckpointPayload.DEFAULT_DIFFICULTY,
		"objective_snapshot": runtime_snapshot.objective_snapshot,
		"encounter_snapshot": runtime_snapshot.encounter_snapshot,
		"route_snapshot": _route_runtime.snapshot(),
		"secrets": secrets.duplicate(true),
		"unlocked_weapons": active_loadout.get("unlocked_weapons", []),
		"active_mission_upgrades": active_loadout,
	})


func restart_from_checkpoint() -> void:
	if _interaction_runtime != null:
		_interaction_runtime.reset_for_checkpoint({"secrets": secrets})
	if _mission_presentation != null:
		_mission_presentation.reset_for_checkpoint()
	if _last_combat_zone != &"":
		_spawn_registry.clear_zone(_last_combat_zone)
		_resetting_encounter = true
		if _last_combat_zone == &"harbour_pier" and _convoy_coordinator != null:
			_convoy_coordinator.reset()
		else:
			_mission_runtime.reset_zone(_last_combat_zone)
			_activate_zone_encounter(_last_combat_zone)
		_resetting_encounter = false
	if is_instance_valid(player):
		if player.has_method("respawn"):
			player.respawn(checkpoint_position, opening_protection_seconds)
		else:
			player.global_position = checkpoint_position
			player.reset_physics_interpolation()


func _on_actor_spawned(enemy: Node, definition: EncounterDefinition) -> void:
	_spawn_registry.register_encounter_actor(enemy, definition, _resetting_encounter)
	enemy_spawned.emit(enemy, definition.zone_id)
	if _mission_presentation != null:
		_mission_presentation.bind_warning_enemy(enemy)
	enemies_total = _spawn_registry.enemies_total


func _on_actor_defeated(enemy: Node, definition: EncounterDefinition) -> void:
	enemies_defeated = _spawn_registry.record_enemy_defeat()
	enemy_defeated.emit(enemy, definition.zone_id)


func _on_encounter_completed(definition: EncounterDefinition) -> void:
	_spawn_registry.finish_encounter(definition.zone_id)


func _on_convoy_actor_started(actor: Node3D, generation: int) -> void:
	var convoy := actor as CitationConvoyActor
	if convoy == null:
		push_error("Citation convoy scene does not implement CitationConvoyActor")
		return
	convoy.module_destroyed.connect(func(module_id: StringName) -> void:
		if _convoy_coordinator != null:
			_convoy_coordinator.report_module_destroyed(module_id, generation)
	)


func _on_convoy_completed(event_id: StringName, _generation: int) -> void:
	if event_id != &"citation_convoy_stopped":
		return
	_mission_runtime.record_objective(ObjectiveDefinition.Kind.DEFEAT, &"citation_convoy")
	_mission_runtime.activate_checkpoint(&"checkpoint_harbour_clear")
	narrative_message.emit("CITATION CONVOY DISABLED. MUNICIPAL JOY RESTORED.", 3.0)


func _on_encounter_failed(definition: EncounterDefinition, _reason: String) -> void:
	_spawn_registry.finish_encounter(definition.zone_id)
	_spawn_registry.clear_zone(definition.zone_id)


func _on_objective_activated(definition: ObjectiveDefinition) -> void:
	objective_changed.emit(definition.title)


func _on_objective_completed(definition: ObjectiveDefinition) -> void:
	if definition.id == &"restore_terminal":
		_award_municipal_recall_override()
	if definition.id == &"stop_citation_convoy" and _world_builder != null and _world_builder.departure_switch != null:
		_world_builder.departure_switch.set_enabled(true)
	if definition.id == &"complete_harbour_pier":
		_begin_completion()


func _award_municipal_recall_override() -> void:
	if MUNICIPAL_RECALL_OVERRIDE in _mission_upgrades:
		return
	_mission_upgrades.append(MUNICIPAL_RECALL_OVERRIDE)
	if player is CobiePlayer:
		_apply_active_mission_upgrades(player as CobiePlayer)
	narrative_message.emit("MUNICIPAL RECALL OVERRIDE // FETCH RETURN SPEED +35% // DOUBLE SHIELD STAGGER", 4.0)
	if _mission_presentation != null:
		_mission_presentation.on_checkpoint_caption("UPGRADE: MUNICIPAL RECALL OVERRIDE")
	var checkpoint_id := _route_runtime.current_checkpoint_id if _route_runtime != null else &"checkpoint_terminal_service"
	_save_checkpoint(checkpoint_id, CHECKPOINT_POSITIONS.get(checkpoint_id, checkpoint_position))


func _apply_active_mission_upgrades(cobie: CobiePlayer) -> void:
	if MUNICIPAL_RECALL_OVERRIDE not in _mission_upgrades:
		return
	for weapon in cobie.weapons:
		if weapon is FetchLauncher:
			(weapon as FetchLauncher).apply_municipal_recall_override()


func _begin_completion() -> void:
	if _completion_started:
		return
	_completion_started = true
	narrative_message.emit("RAIN CITY: CITATION DISPUTED SUCCESSFULLY.", 4.0)
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.delete_slot(&"checkpoint")
	_completion_timer.start()


func _finalize_completion() -> void:
	var summary := get_level_summary()
	level_completed.emit(summary)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.finish_run(summary)
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		_mission_runtime.record_campaign_completion(metadata.level_id, summary, save_manager, game_state.difficulty_id if game_state != null else &"classic", [], _mission_upgrades)


func get_level_summary() -> Dictionary:
	return {
		"level_id": metadata.level_id,
		"title": metadata.title,
		"completion_time_msec": Time.get_ticks_msec() - _run_started_ms,
		"enemies_defeated": enemies_defeated,
		"enemies_total": enemies_total,
		"secrets_found": secrets.size(),
		"secrets_total": metadata.total_secrets,
		"victory_line": "RAIN CITY: CITATION DISPUTED SUCCESSFULLY.",
	}


func _on_player_died(_source: Node) -> void:
	narrative_message.emit("GOOD DOG DOWN. PRESS FIRE TO RESTART.", 3.0)


func _on_secret_requested(secret_id: StringName, title: String, _source: Node) -> void:
	if secrets.has(secret_id):
		return
	secrets[secret_id] = title
	secret_found.emit(secret_id, title, secrets.size(), metadata.total_secrets)
	narrative_message.emit("SECRET FOUND: %s (%d/%d)" % [title, secrets.size(), metadata.total_secrets], 3.0)


func _on_loot_requested(loot_scene: String, count: int, source: Node) -> void:
	_spawn_registry.spawn_loot_burst(loot_scene, count, source as Node3D, player)


func _on_pickup_collected(message: String) -> void:
	narrative_message.emit(message, 2.0)


func _spawn_scene(path: String, position_value: Vector3) -> Node:
	return _spawn_registry.spawn_scene(path, position_value)
