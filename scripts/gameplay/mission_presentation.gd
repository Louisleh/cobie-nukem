class_name MissionPresentation
extends Node

signal restart_requested

const HUDScene = preload("res://scenes/ui/hud.tscn")
const PauseScene = preload("res://scenes/ui/pause_menu.tscn")
const DeathScene = preload("res://scenes/ui/death_screen.tscn")
const VictoryScene = preload("res://scenes/ui/victory_screen.tscn")
const CombatAudioScene = preload("res://scenes/ui/combat_audio_bridge.tscn")
const MobileControlsScene = preload("res://scenes/ui/mobile_controls.tscn")
const DefaultAudioProfile: MissionAudioProfile = preload("res://resources/audio/salmon_mission_audio.tres")
const MissionAudioLibrary: AudioCueLibrary = preload("res://resources/audio/mission_audio_library.tres")

var _hud: GameHUD
var _pause_menu: PauseMenu
var _death_screen: DeathScreen
var _victory_screen: VictoryScreen
var _combat_audio: CombatAudioBridge
var _mobile_controls: MobileControls
var _mission_audio_director: MissionAudioDirector
var _player: Node3D
var _actors: Node
var _level: Node
var _game_state: Node
var _mission_runtime: MissionRuntime
var _encounter_runner: EncounterRunner
var _configured := false
var _level_connected := false
var _runtime_connected := false
var _encounter_runner_connected := false
var _game_state_connected := false
var _last_zone: StringName = &""
var _current_audio_state: StringName = &""
var _last_ambience: StringName = &""
var _player_weather: GPUParticles3D
var _enemy_warning_bound: Dictionary = {}
var _zone_actor_counts: Dictionary = {}
var _zone_ambience: Dictionary = {}
var _boss_zone_id: StringName = &""
var _initial_zone_id: StringName = &""


func configure(level: Node, content_manifest: ContentManifest, actors: Node, encounter_runner: EncounterRunner = null, mission_runtime: MissionRuntime = null, player: Node3D = null, game_state: Node = null, initial_zone_id: StringName = &"", boss_zone_id: StringName = &"", zone_ambience: Dictionary = {}) -> bool:
	if level == null:
		return false
	if _configured and (_level != level or _mission_runtime != mission_runtime or _encounter_runner != encounter_runner):
		push_warning("MissionPresentation cannot be reconfigured with different runtime owners")
		return false
	_level = level
	_actors = actors
	_encounter_runner = encounter_runner
	_mission_runtime = mission_runtime
	_game_state = game_state if game_state != null else get_node_or_null("/root/GameState")
	_initial_zone_id = initial_zone_id
	_boss_zone_id = boss_zone_id
	_zone_ambience.clear()
	for raw_zone_id: Variant in zone_ambience:
		_zone_ambience[StringName(raw_zone_id)] = StringName(zone_ambience[raw_zone_id])
	if content_manifest != null:
		for profile: ZonePresentationProfile in content_manifest.zone_presentations:
			if profile != null:
				_zone_ambience[profile.zone_id] = profile.ambience_cue_id

	if _hud == null:
		_create_presentation_nodes()
	if not _configured:
		_connect_level(level)
		_connect_runtime(mission_runtime)
		_connect_encounter_runner(encounter_runner)
		_connect_game_state(_game_state)
		_configure_audio(content_manifest)
		_configured = true

	set_player(player)
	if _actors != null:
		_bind_existing_enemies()

	if _last_zone != &"":
		_apply_zone_state(_last_zone)
	elif _initial_zone_id != &"":
		_apply_zone_state(_initial_zone_id)
	_request_audio_state(&"exploration")
	return true


func set_player(player: Node3D) -> void:
	if _player == player:
		return
	if _player != null and _player.has_signal("died") and _player.died.is_connected(on_player_died):
		_player.died.disconnect(on_player_died)
	_player = player
	if _player == null:
		if _mobile_controls != null:
			_mobile_controls.bind_player(null)
		return
	if _hud != null: _hud.bind_player(_player)
	if _combat_audio != null: _combat_audio.bind_player(_player)
	if _mobile_controls != null: _mobile_controls.bind_player(_player)
	if _player is CobiePlayer:
		_add_player_rain()
	if _player.has_signal("died"):
		_player.died.connect(on_player_died)


func bind_warning_enemy(enemy: Node) -> void:
	if enemy == null or not enemy.has_signal("telegraph_started"):
		return
	if enemy.has_meta(&"mission_presentation_warning_bound"):
		return
	if _hud == null or not enemy.has_signal("telegraph_started"):
		return
	enemy.set_meta(&"mission_presentation_warning_bound", true)
	_enemy_warning_bound[enemy.get_instance_id()] = weakref(enemy)
	enemy.telegraph_started.connect(_on_enemy_telegraph)


func bind_warning_enemies() -> void:
	if _actors == null:
		return
	for actor in _actors.get_children():
		bind_warning_enemy(actor)


func on_zone_entered(zone_id: StringName, _title: String) -> void:
	_last_zone = zone_id
	_apply_zone_state(zone_id)
	_request_audio_state(&"exploration")


func on_objective_changed(text: String) -> void:
	if _hud == null:
		return
	_hud.show_objective(text)
	_hud.show_notification("OBJECTIVE: " + text)
	_hud.show_objective_caption(text, 2.0)


func on_secret_found(_id: StringName, title: String, found: int, total: int) -> void:
	if _hud != null:
		_hud.show_secret("SECRET: %s (%d/%d)" % [title, found, total])


func on_narrative_message(text: String, duration: float) -> void:
	if _hud != null:
		_hud.show_notification(text)
		_hud.show_caption(text, GameHUD.CaptionCategory.NARRATIVE, duration)


func on_checkpoint_caption(message: String) -> void:
	if _hud != null:
		_hud.show_checkpoint_caption(message)


func on_player_died(_source: Node) -> void:
	if _mobile_controls != null:
		_mobile_controls.release_all()
	if _pause_menu != null:
		_pause_menu.close_for_death()
	if _death_screen != null:
		_death_screen.show_death()


func on_level_completed(summary: Dictionary) -> void:
	if _hud != null:
		_hud.visible = false
	if _pause_menu != null:
		_pause_menu.set_suppressed(true)
		_pause_menu.visible = false
	if _victory_screen != null:
		_victory_screen.show_summary(summary)
	_request_audio_state(&"victory")


func on_actor_spawned(enemy: Node, definition: EncounterDefinition) -> void:
	bind_warning_enemy(enemy)
	if definition == null:
		return
	var zone_id := definition.zone_id
	var current_count := int(_zone_actor_counts.get(zone_id, 0))
	_zone_actor_counts[zone_id] = current_count + 1
	if zone_id == _boss_zone_id:
		_request_audio_state(&"boss")
		return
	if zone_id == _last_zone and _current_audio_state in [&"exploration", &"tension"]:
		_request_audio_state(&"combat")


func on_actor_defeated(_enemy: Node, definition: EncounterDefinition) -> void:
	if definition == null:
		return
	var zone_id := definition.zone_id
	var current_count := int(_zone_actor_counts.get(zone_id, 0))
	current_count = maxi(0, current_count - 1)
	_zone_actor_counts[zone_id] = current_count
	if zone_id == _boss_zone_id and current_count == 0:
		return
	if zone_id == _last_zone and current_count <= 0:
		_request_audio_state(&"tension")


func on_encounter_started(definition: EncounterDefinition) -> void:
	if definition == null:
		return
	if definition.zone_id == _boss_zone_id:
		_request_audio_state(&"boss")
	else:
		_request_audio_state(&"tension")


func on_encounter_completed(definition: EncounterDefinition) -> void:
	if definition == null:
		return
	var zone_id := definition.zone_id
	_zone_actor_counts.erase(zone_id)
	_request_audio_state(&"exploration")
	if zone_id == _last_zone:
		_apply_zone_state(zone_id)


func on_encounter_failed(definition: EncounterDefinition, _reason: String) -> void:
	if definition == null:
		return
	var zone_id := definition.zone_id
	_zone_actor_counts.erase(zone_id)
	_request_audio_state(&"tension")
	if zone_id == _last_zone:
		_apply_zone_state(zone_id)


func bind_restart_requests(callback: Callable) -> void:
	if not restart_requested.is_connected(callback):
		restart_requested.connect(callback)


func reset_for_checkpoint() -> void:
	if _combat_audio != null:
		_combat_audio.reset_gameplay_audio()
	if _pause_menu != null:
		_pause_menu.set_suppressed(false)
	if _death_screen != null:
		_death_screen.visible = false
	if _mobile_controls != null:
		_mobile_controls.release_all()
	_zone_actor_counts.clear()
	_current_audio_state = &""
	_request_audio_state(&"exploration")
	if _last_zone != &"":
		_apply_zone_state(_last_zone)


func is_pause_suppressed() -> bool:
	return _pause_menu != null and _pause_menu._suppressed


func bound_enemy_count() -> int:
	_prune_enemy_bindings()
	return _enemy_warning_bound.size()


func is_enemy_bound(enemy: Node) -> bool:
	if enemy == null:
		return false
	return enemy.has_meta(&"mission_presentation_warning_bound")


func get_hud() -> GameHUD:
	return _hud


func get_pause_menu() -> PauseMenu:
	return _pause_menu


func get_death_screen() -> DeathScreen:
	return _death_screen


func get_victory_screen() -> VictoryScreen:
	return _victory_screen


func get_combat_audio_bridge() -> CombatAudioBridge:
	return _combat_audio


func get_mobile_controls() -> MobileControls:
	return _mobile_controls


func get_audio_director() -> MissionAudioDirector:
	return _mission_audio_director


func add_player_rain() -> void:
	_add_player_rain()


func _create_presentation_nodes() -> void:
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
	if _pause_menu != null:
		_pause_menu.restart_requested.connect(_on_pause_restart)
	if _death_screen != null:
		_death_screen.retry_requested.connect(_on_pause_restart)
	if _mobile_controls != null:
		_mobile_controls.release_all()
	_mission_audio_director = MissionAudioDirector.new()
	_mission_audio_director.name = "MissionAudioDirector"
	add_child(_mission_audio_director)


func _on_pause_restart() -> void:
	restart_requested.emit()


func _connect_level(level: Node) -> void:
	if _level_connected:
		return
	if level.has_signal("zone_entered"):
		level.zone_entered.connect(on_zone_entered)
	if level.has_signal("narrative_message"):
		level.narrative_message.connect(on_narrative_message)
	if level.has_signal("objective_changed"):
		level.objective_changed.connect(on_objective_changed)
	if level.has_signal("secret_found"):
		level.secret_found.connect(on_secret_found)
	_level_connected = true


func _connect_runtime(runtime: MissionRuntime) -> void:
	if runtime == null or _runtime_connected:
		return
	runtime.actor_spawned.connect(on_actor_spawned)
	runtime.actor_defeated.connect(on_actor_defeated)
	runtime.encounter_completed.connect(on_encounter_completed)
	runtime.encounter_failed.connect(on_encounter_failed)
	_runtime_connected = true


func _connect_encounter_runner(runner: EncounterRunner) -> void:
	if runner == null or _encounter_runner_connected:
		return
	runner.encounter_started.connect(on_encounter_started)
	_encounter_runner_connected = true


func _connect_game_state(state_node: Node) -> void:
	if state_node == null or _game_state_connected:
		return
	if state_node.has_signal("run_ended"):
		state_node.run_ended.connect(on_level_completed)
		_game_state_connected = true


func _configure_audio(content_manifest: ContentManifest) -> void:
	if content_manifest == null:
		_mission_audio_director.configure(DefaultAudioProfile, MissionAudioLibrary)
		return
	var profile := content_manifest.audio_profile as MissionAudioProfile
	if profile == null:
		profile = DefaultAudioProfile
	var configured := _mission_audio_director.configure(profile, MissionAudioLibrary)
	if not configured:
		push_warning("MissionPresentation could not configure audio director")


func _request_audio_state(state: StringName) -> void:
	if state == _current_audio_state:
		return
	if _mission_audio_director != null and _mission_audio_director.request_state(state):
		_current_audio_state = state


func _apply_zone_state(zone_id: StringName) -> void:
	var cue_id: StringName = _zone_ambience.get(zone_id, &"")
	if cue_id == &"":
		return
	var previous_ambience := _last_ambience
	_last_ambience = cue_id
	if _mission_audio_director != null and cue_id != previous_ambience:
		_mission_audio_director.set_zone_ambience(cue_id)


func _add_player_rain() -> void:
	if _player == null or _player.has_meta(&"mission_presentation_rain"):
		return
	var quality := get_node_or_null("/root/QualityManager")
	var rain_amount := 420 if quality == null or quality.current == null else mini(420, quality.current.particle_budget)
	var rain := GPUParticles3D.new()
	rain.name = "StormRain"
	rain.position.y = 8.0
	rain.amount = rain_amount
	rain.lifetime = 1.25
	rain.visibility_aabb = AABB(Vector3(-16, -12, -16), Vector3(32, 24, 32))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(14, 1, 14)
	process.direction = Vector3(0.12, -1, 0.05)
	process.spread = 4.0
	process.initial_velocity_min = 15.0
	process.initial_velocity_max = 20.0
	rain.process_material = process
	var drop := QuadMesh.new()
	drop.size = Vector2(0.018, 0.48)
	var drop_material := StandardMaterial3D.new()
	drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	drop_material.albedo_color = Color(0.58, 0.76, 0.86, 0.5)
	drop.material = drop_material
	rain.draw_pass_1 = drop
	_player.add_child(rain)
	_player.set_meta(&"mission_presentation_rain", true)
	_player_weather = rain


func _bind_existing_enemies() -> void:
	if _actors == null:
		return
	for actor in _actors.get_children():
		bind_warning_enemy(actor)


func _on_enemy_telegraph(kind: StringName, _duration: float) -> void:
	if _hud != null:
		_hud.show_caption("%s WARNING" % String(kind).replace("_", " "), GameHUD.CaptionCategory.ENEMY_WARNING, 1.2)


func _prune_enemy_bindings() -> void:
	for instance_id: Variant in _enemy_warning_bound.keys():
		var reference := _enemy_warning_bound[instance_id] as WeakRef
		if reference == null or reference.get_ref() == null:
			_enemy_warning_bound.erase(instance_id)


func _exit_tree() -> void:
	if _combat_audio != null:
		_combat_audio.reset_gameplay_audio()
	if _mobile_controls != null:
		_mobile_controls.release_all()
	if _mission_audio_director != null:
		_mission_audio_director.reset()
