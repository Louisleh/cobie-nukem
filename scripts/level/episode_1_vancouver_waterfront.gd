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
@export var build_navigation := true
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
var _convoy_presentation: RainCityConvoyPresentation
var _route_recovery_timer: Timer
var _completion_timer: Timer
var _completion_summary: Dictionary = {}
var _last_combat_zone: StringName = &""
var _resetting_encounter := false
var _mission_upgrades: Array[StringName] = []
var _baseline_attack_budget := 3
var _terminal_reinforcement_disabled := false
var _collectible_runtime: MissionCollectibleRuntime

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
			if not _restored_checkpoint.is_empty(): game_state.restore_progression_checkpoint(int(_restored_checkpoint.get("pending_compliance_tags", 0)), String(_restored_checkpoint.get("run_mode", "standard")))
	_setup_collectibles()
	narrative_message.emit("EPISODE 1, MISSION 2: RAIN CITY RUN\nPUBLIC BETA PREVIEW", 4.0)
	level_ready.emit(player)
	var announced := _mission_runtime.announce_available_objectives()
	if announced.is_empty():
		objective_changed.emit(metadata.opening_objective)
	if is_instance_valid(player):
		_submit_route_position(player.global_position)


func _setup_collectibles() -> void:
	_collectible_runtime = MissionCollectibleRuntime.new(); _collectible_runtime.name = "MissionCollectibles"; add_child(_collectible_runtime)
	if not _collectible_runtime.configure(preload("res://resources/progression/rain_city_mini_balls.tres"), get_node_or_null("/root/SaveManager")):
		push_warning("Rain City Mini Ball runtime could not start")
		return
	_collectible_runtime.collectible_found.connect(func(_id: StringName, found: int, total: int) -> void: narrative_message.emit("MINI BALL FOUND // %d / %d" % [found, total], 1.6))
	_collectible_runtime.milestone_unlocked.connect(func(text: String) -> void: narrative_message.emit(text, 3.0))

func _setup_runtime() -> void:
	var pressure := get_node_or_null("/root/CombatPressure")
	if pressure != null:
		var game_state := get_node_or_null("/root/GameState")
		var difficulty_id := StringName(game_state.difficulty_id) if game_state != null else &"classic"
		_baseline_attack_budget = 2 if difficulty_id == &"story" else (4 if difficulty_id == &"mayhem" else 3)
		pressure.configure_limit(_baseline_attack_budget)
	var assembly := RainCityMissionAssembly.create_runtime(self, content_manifest, _spawn_scene)
	_spawn_registry = assembly.registry
	_mission_runtime = assembly.runtime
	_route_recovery_timer = assembly.route_timer
	_completion_timer = assembly.completion_timer
	_route_runtime = _mission_runtime.route
	if _route_runtime == null:
		push_error("Vancouver route runtime rejected the authored route")
	else:
		_mission_runtime.zone_entered.connect(_on_route_zone_entered)
		_mission_runtime.checkpoint_available.connect(_on_route_checkpoint_available)
	_restore_runtime_state()

func _build_world() -> void:
	_world_builder = WorldBuilderScript.new()
	_world_builder.name = "VancouverWaterfrontWorldBuilder"
	_world_builder.on_zone_entered = _on_world_zone_entered
	_world_builder.on_checkpoint_activated = _on_world_checkpoint
	_world_builder.on_objective_action = _mission_runtime.record_objective
	_world_builder.on_narrative_message = narrative_message.emit
	_world_builder.build_navigation = build_navigation
	add_child(_world_builder)
	if not _world_builder.build(self):
		push_error("Vancouver world builder failed")
		return
	_spawn_registry.actor_parent = _world_builder.actors
	_sync_route_gates()
	_setup_convoy()

func _setup_convoy() -> void:
	if content_manifest.moving_set_pieces.size() != 1:
		push_error("Vancouver requires exactly one citation convoy definition")
		return
	var assembly := RainCityMissionAssembly.create_convoy(self, content_manifest.moving_set_pieces[0], _world_builder.actors, _mission_runtime)
	if assembly.is_empty():
		return
	_set_piece_runtime = assembly.runtime
	_convoy_coordinator = assembly.coordinator
	_convoy_presentation = assembly.presentation

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
	if secrets.has(&"secret_terminal_service"):
		_disable_harbour_reinforcement()
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
		&"harbour_pier",
		{},
		"MUNICIPAL TOWMASTER // APPEAL DENIED"
	)
	_mission_presentation.bind_restart_requests(restart_from_checkpoint)
	if _convoy_presentation != null:
		_convoy_presentation.set_presentation(_mission_presentation)

func _spawn_player() -> void:
	player = _spawn_scene(PLAYER_SCENE, checkpoint_position) as Node3D
	if player == null:
		return
	if player is CobiePlayer:
		var cobie := player as CobiePlayer
		cobie.health_armor.grant_invulnerability(opening_protection_seconds)
		if metadata.mission_loadout != null:
			cobie.apply_mission_loadout(metadata.mission_loadout, _restored_checkpoint)
		RainCityCheckpointState.restore_player_state(cobie, _restored_checkpoint)
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
	var save_manager := get_node_or_null("/root/SaveManager")
	var restored := RainCityCheckpointState.consume_requested(metadata, CONTENT_REVISION, CHECKPOINT_POSITIONS, game_state, save_manager)
	if restored.is_empty():
		return
	_restored_checkpoint = restored.payload
	checkpoint_position = restored.position
func _restore_runtime_state() -> void:
	var restored := RainCityCheckpointState.restore(_restored_checkpoint, _mission_runtime, _route_runtime, content_manifest.route_definition)
	if restored.is_empty():
		return
	secrets = restored.secrets
	current_zone = restored.current_zone
func _rehydrate_restored_gameplay() -> void:
	if _restored_checkpoint.is_empty() or _route_runtime == null:
		return
	current_zone = _route_runtime.current_zone
	var convoy_complete := _mission_runtime.objectives.completed.has(&"stop_citation_convoy")
	if _world_builder != null and _world_builder.departure_switch != null:
		_world_builder.departure_switch.set_enabled(convoy_complete)
	if convoy_complete:
		_last_combat_zone = &""
		if _set_piece_runtime != null and not bool(_set_piece_runtime.current_state().get("completion_emitted", false)):
			_set_piece_runtime.restore_completed_state()
	elif current_zone == &"harbour_pier":
		_last_combat_zone = &"harbour_pier"
		if _set_piece_runtime != null and not bool(_set_piece_runtime.current_state().get("has_actor", false)):
			_set_piece_runtime.start()
	elif current_zone != &"" and not _mission_runtime.encounters.completed.has(current_zone):
		_activate_zone_encounter(current_zone)
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
	if zone_id != &"harbour_pier":
		_activate_zone_encounter(zone_id)
	elif _set_piece_runtime != null and _set_piece_runtime.current_state().get("has_actor", false) == false:
		_last_combat_zone = &"harbour_pier"
		_set_piece_runtime.start()
func _activate_zone_encounter(zone_id: StringName) -> void:
	if _mission_runtime.encounters == null or not _mission_runtime.encounters.definitions.has(zone_id):
		return
	if _mission_runtime.encounters.completed.has(zone_id) or _mission_runtime.encounters.active.has(zone_id):
		return
	if _world_builder != null:
		_world_builder.set_route_gate_open(zone_id, false)
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

func _save_checkpoint(checkpoint_id: StringName, position_value: Vector3, announce := true) -> Error:
	var save_manager := _get_save_manager()
	var save_error := OK
	if save_manager != null:
		var payload := _build_checkpoint_payload(checkpoint_id, position_value)
		save_error = _write_checkpoint(save_manager, payload)
	if save_error != OK:
		_report_persistence_failure("checkpoint", save_error)
		return save_error
	checkpoint_position = position_value
	if announce:
		checkpoint_activated.emit(checkpoint_id, position_value)
		narrative_message.emit("CHECKPOINT: RAIN DELAY APPROVED.", 2.2)
		if _mission_presentation != null:
			_mission_presentation.on_checkpoint_caption("CHECKPOINT: RAIN DELAY APPROVED.")
	return OK

func _build_checkpoint_payload(checkpoint_id: StringName, position_value: Vector3) -> Dictionary:
	var runtime_snapshot := _mission_runtime.snapshot()
	var game_state := get_node_or_null("/root/GameState")
	var active_loadout: Dictionary = player.mission_loadout_snapshot(metadata.level_id, _mission_upgrades) if player is CobiePlayer else {}
	var player_state := {}
	if player is CobiePlayer and (player as CobiePlayer).health_armor != null:
		player_state = {"health": (player as CobiePlayer).health_armor.health, "armor": (player as CobiePlayer).health_armor.armor}
	var difficulty_id: StringName = game_state.difficulty_id if game_state != null else CheckpointPayload.DEFAULT_DIFFICULTY
	return RainCityCheckpointState.build_payload("res://scenes/levels/episode_1_vancouver_waterfront.tscn", metadata, checkpoint_id, CONTENT_REVISION, position_value, difficulty_id, runtime_snapshot, _route_runtime.snapshot(), secrets, active_loadout, player_state)

func _write_checkpoint(save_manager: Node, payload: Dictionary) -> Error:
	return save_manager.save_slot(&"checkpoint", payload)

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
	if _world_builder != null:
		_world_builder.set_route_gate_open(definition.zone_id, true)

func _on_encounter_failed(definition: EncounterDefinition, _reason: String) -> void:
	_spawn_registry.finish_encounter(definition.zone_id)
	_spawn_registry.clear_zone(definition.zone_id)

func _sync_route_gates() -> void:
	if _world_builder == null or _mission_runtime == null or _mission_runtime.encounters == null:
		return
	for zone_id in [&"downtown_alley", &"ruse_block", &"waterfront_seawall", &"terminal_service"]:
		_world_builder.set_route_gate_open(zone_id, _mission_runtime.encounters.completed.has(zone_id))

func _on_objective_activated(definition: ObjectiveDefinition) -> void:
	objective_changed.emit(definition.title)

func _on_objective_completed(definition: ObjectiveDefinition) -> void:
	if definition.id == &"restore_terminal":
		_award_municipal_recall_override()
	if definition.id == &"stop_citation_convoy" and _world_builder != null and _world_builder.departure_switch != null:
		# Once the clear checkpoint is authoritative, death/retry must preserve the
		# wreck instead of treating the harbour as an active encounter reset.
		_last_combat_zone = &""
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
	RainCityCompletionFlow.begin(self)

func _finalize_completion() -> void:
	var summary := _completion_summary.duplicate(true) if not _completion_summary.is_empty() else get_level_summary()
	level_completed.emit(summary)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.finish_run(summary)
func _persist_campaign_completion(summary: Dictionary, save_manager: Node, difficulty_id: StringName) -> Error:
	return _mission_runtime.record_campaign_completion(metadata.level_id, summary, save_manager, difficulty_id, [], _mission_upgrades)
func _rollback_completion_for_retry(save_error: Error) -> void:
	RainCityCompletionFlow.rollback(self, save_error)
func _start_completion_transition() -> void:
	if _completion_timer != null:
		_completion_timer.start()
func _get_save_manager() -> Node:
	return get_node_or_null("/root/SaveManager")
func _completion_difficulty_id() -> StringName:
	var game_state := get_node_or_null("/root/GameState")
	return game_state.difficulty_id if game_state != null else &"classic"
func _active_control_method() -> StringName:
	var input_manager := get_node_or_null("/root/InputManager")
	return input_manager.active_control_method if input_manager != null else &"unknown"
func _report_persistence_failure(context: String, save_error: Error) -> void:
	var payload := {"context": context, "error": save_error, "error_name": error_string(save_error)}
	var debug_log := get_node_or_null("/root/DebugLog")
	if debug_log != null and debug_log.has_method("warn"):
		debug_log.warn("Rain City persistence failed", payload)
	else:
		push_warning("Rain City persistence failed %s" % payload)
func get_level_summary() -> Dictionary:
	return {
		"level_id": metadata.level_id,
		"title": metadata.title,
		"completion_time_msec": Time.get_ticks_msec() - _run_started_ms,
		"enemies_defeated": enemies_defeated,
		"enemies_total": enemies_total,
		"secrets_found": secrets.size(),
		"secrets_total": metadata.total_secrets,
		"control_method": _active_control_method(),
		"victory_line": "RAIN CITY: CITATION DISPUTED SUCCESSFULLY.",
	}
func _on_player_died(_source: Node) -> void:
	narrative_message.emit("GOOD DOG DOWN. PRESS FIRE TO RESTART.", 3.0)
func _on_secret_requested(secret_id: StringName, title: String, _source: Node) -> void:
	if secrets.has(secret_id):
		return
	secrets[secret_id] = title
	# Reward first so the checkpoint's loadout snapshot captures the resulting
	# health/armor/ammo state before the secret becomes permanently complete.
	_apply_secret_reward(secret_id)
	var checkpoint_id := _route_runtime.current_checkpoint_id if _route_runtime != null else &"checkpoint_downtown_alley"
	_save_checkpoint(checkpoint_id, CHECKPOINT_POSITIONS.get(checkpoint_id, checkpoint_position), false)
	secret_found.emit(secret_id, title, secrets.size(), metadata.total_secrets)
	narrative_message.emit("SECRET FOUND: %s (%d/%d)" % [title, secrets.size(), metadata.total_secrets], 3.0)

func _apply_secret_reward(secret_id: StringName) -> void:
	if secret_id == &"secret_terminal_service":
		_disable_harbour_reinforcement()
	var message := RainCitySecretPolicy.apply_player_reward(player if is_instance_valid(player) else null, secret_id)
	if message != "":
		var duration := 2.8 if secret_id == &"secret_terminal_service" else 2.4
		narrative_message.emit(message, duration)

func _disable_harbour_reinforcement() -> void:
	if _terminal_reinforcement_disabled or _mission_runtime == null or _mission_runtime.encounters == null:
		return
	var source := _mission_runtime.encounters.definitions.get(&"harbour_pier") as EncounterDefinition
	var reduced := RainCitySecretPolicy.reduced_harbour_definition(source)
	if reduced == null:
		return
	_mission_runtime.encounters.definitions[&"harbour_pier"] = reduced
	_terminal_reinforcement_disabled = true

func _on_loot_requested(loot_scene: String, count: int, source: Node) -> void:
	_spawn_registry.spawn_loot_burst(loot_scene, count, source as Node3D, player)

func _on_pickup_collected(message: String) -> void:
	narrative_message.emit(message, 2.0)

func _spawn_scene(path: String, position_value: Vector3) -> Node:
	return _spawn_registry.spawn_scene(path, position_value)
