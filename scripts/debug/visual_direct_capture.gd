extends Node

var _target: Node
var _frame := 0
var _cleanup_frame := 60
var _staging_id := ""
var _staged := false
const RAIN_CITY_TOWMASTER_ACTOR_PARENT_PATH := "Actors"
const RAIN_CITY_TOWMASTER_PLAYER_OFFSET := Vector3(6.0, 1.1, -160.0)
const RAIN_CITY_TOWMASTER_ACTOR_POSITION := Vector3(0.0, 0.0, -151.0)
const RAIN_CITY_TOWMASTER_PHASE_INDEX := 3
const RAIN_CITY_TOWMASTER_VIEW_ATTACK_ID := &"tow_sweep"
const RAIN_CITY_TOWMASTER_VIEW_BARRAGE_ID := &"citation_barrage"
const RAIN_CITY_ROUTE_STAGES := {
	"rain_city_downtown": [Vector3(2.0, 1.1, 5.0), Vector3(6.0, 1.8, -12.0), &"downtown_alley", "DOWNTOWN SERVICE ALLEY", "REACH THE WATERFRONT SEAWALL"],
	"rain_city_slice": [Vector3(2.5, 1.1, -37.0), Vector3(-4.3, 3.35, -37.0), &"ruse_block", "RAIN CITY SLICE", "REACH THE WATERFRONT SEAWALL"],
	"waterfront_seawall": [Vector3(0.0, 1.1, -73.0), Vector3(0.0, 1.8, -92.0), &"waterfront_seawall", "WATERFRONT SEAWALL", "OVERRIDE THE TERMINAL LOCKDOWN"],
	"rain_city_terminal": [Vector3(0.0, 1.1, -104.0), Vector3(0.0, 1.8, -123.0), &"terminal_service", "TERMINAL SERVICE", "OVERRIDE THE TERMINAL LOCKDOWN"],
	"rain_city_harbour": [Vector3(0.0, 1.1, -127.5), Vector3(0.0, 1.8, -151.0), &"harbour_pier", "HARBOUR PIER", "STOP THE CITATION CONVOY"],
}
const PRODUCTION_CITATION_CONVOY_SCENE: PackedScene = preload("res://scenes/set_pieces/citation_convoy.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var target_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-size="):
			_apply_capture_size(argument.trim_prefix("--capture-size="))
		elif argument.begins_with("--capture-seed="):
			seed(int(argument.trim_prefix("--capture-seed=")))
		elif argument.begins_with("--target-scene="):
			target_path = argument.trim_prefix("--target-scene=")
		elif argument.begins_with("--cleanup-frame="):
			_cleanup_frame = maxi(10, int(argument.trim_prefix("--cleanup-frame=")))
		elif argument.begins_with("--staging-id="):
			_staging_id = argument.trim_prefix("--staging-id=")
		elif argument.begins_with("--physics-tps="):
			Engine.physics_ticks_per_second = clampi(int(argument.trim_prefix("--physics-tps=")), 10, 240)
	if not target_path.begins_with("res://"):
		push_error("Visual direct capture requires --target-scene=res://...")
		get_tree().quit(1)
		return
	var packed := load(target_path) as PackedScene
	if packed == null:
		push_error("Visual direct capture could not load %s" % target_path)
		get_tree().quit(1)
		return
	_target = packed.instantiate()
	if target_path.ends_with("/title_screen.tscn"):
		_target.set("play_intro_audio", false)
	add_child(_target)
	_suppress_focus_pause()


func _apply_capture_size(size_value: String) -> void:
	var parts := size_value.to_lower().split("x")
	if parts.size() != 2:
		push_error("Invalid direct visual capture size: %s" % size_value)
		return
	var requested := Vector2i(maxi(320, int(parts[0])), maxi(240, int(parts[1])))
	get_window().size = requested
	var logical_width := maxi(320, roundi(360.0 * float(requested.x) / float(requested.y)))
	get_window().content_scale_size = Vector2i(logical_width, 360)


func _process(_delta: float) -> void:
	if get_tree().paused:
		get_tree().paused = false
	_suppress_focus_pause()
	_stage_target_when_ready()
	if _staged and is_instance_valid(_target) and RAIN_CITY_ROUTE_STAGES.has(_staging_id):
		_clear_non_player_actors()
	if _frame == _cleanup_frame and is_instance_valid(_target):
		_stop_target_audio()
		_target.queue_free()
	if _frame >= _cleanup_frame + 12:
		get_tree().quit(0)
	_frame += 1


func _suppress_focus_pause() -> void:
	if not is_instance_valid(_target):
		return
	for pause_menu in _target.find_children("*", "PauseMenu", true, false):
		pause_menu.set_suppressed(true)


func _stop_target_audio() -> void:
	if not is_instance_valid(_target):
		return
	for sound in _target.find_children("*", "ProceduralAudio", true, false):
		sound.stop_all()
	for player in _target.find_children("*", "AudioStreamPlayer", true, false):
		player.stop()
		player.stream = null


func _stage_target_when_ready() -> void:
	if _staged or not is_instance_valid(_target):
		return
	var player := _target.get("player") as Node3D
	if player == null:
		return
	if RAIN_CITY_ROUTE_STAGES.has(_staging_id):
		_stage_rain_city_route(player, RAIN_CITY_ROUTE_STAGES[_staging_id])
	elif _staging_id == "rain_city_towmaster":
		if _stage_rain_city_towmaster(player):
			_staged = true
		else:
			get_tree().quit(1)


func _stage_rain_city_route(player: Node3D, stage: Array) -> void:
	_target.set_process(false)
	_target.set_physics_process(false)
	player.global_position = stage[0]
	player.set("velocity", Vector3.ZERO)
	if player is CollisionObject3D:
		(player as CollisionObject3D).collision_layer = 0
		(player as CollisionObject3D).collision_mask = 0
	player.set_process(false)
	player.set_physics_process(false)
	player.look_at(stage[1], Vector3.UP)
	var head := player.get_node_or_null("Head") as Node3D
	if head != null:
		head.rotation = Vector3.ZERO
	player.reset_physics_interpolation()
	var presentations := _target.find_children("*", "MissionPresentation", true, false)
	if not presentations.is_empty():
		(presentations[0] as MissionPresentation).on_zone_entered(stage[2], stage[3])
	var hud_nodes := _target.find_children("*", "GameHUD", true, false)
	if not hud_nodes.is_empty():
		var hud := hud_nodes[0] as GameHUD
		hud.clear_captions()
		hud.show_objective(stage[4])
	_staged = true


func _clear_non_player_actors() -> void:
	var player := _target.get("player") as Node
	var actors := _target.get_node_or_null(RAIN_CITY_TOWMASTER_ACTOR_PARENT_PATH)
	if actors == null:
		return
	if actors is Node3D:
		(actors as Node3D).visible = false
	for actor: Node in actors.get_children():
		if actor != player and not actor.is_queued_for_deletion():
			actor.queue_free()


func _stage_rain_city_towmaster(player: Node3D) -> bool:
	player.global_position = RAIN_CITY_TOWMASTER_PLAYER_OFFSET
	player.set("velocity", Vector3.ZERO)
	var actor_parent := _target.get_node_or_null(RAIN_CITY_TOWMASTER_ACTOR_PARENT_PATH) as Node
	if actor_parent == null:
		push_error("rain_city_towmaster staging requires the authored Actors node")
		return false
	var actor := PRODUCTION_CITATION_CONVOY_SCENE.instantiate() as Node
	if actor == null:
		push_error("Failed to instantiate citation_convoy for rain_city_towmaster capture staging")
		return false
	actor_parent.add_child(actor)
	var head := player.get_node_or_null("Head") as Node3D
	if head != null:
		head.rotation = Vector3.ZERO
	player.look_at(RAIN_CITY_TOWMASTER_ACTOR_POSITION + Vector3(0.0, 1.3, 0.0), Vector3.UP)
	player.reset_physics_interpolation()
	var convoy_actor := actor as CitationConvoyActor
	if convoy_actor == null or not is_instance_valid(convoy_actor):
		push_error("Production citation_convoy instance is not a CitationConvoyActor")
		actor.queue_free()
		return false
	convoy_actor.global_position = RAIN_CITY_TOWMASTER_ACTOR_POSITION
	convoy_actor.set_physics_process(false)
	convoy_actor.set_target(player)
	convoy_actor.set_active_phase(RAIN_CITY_TOWMASTER_PHASE_INDEX)
	convoy_actor.set_combat_enabled(true)
	if convoy_actor.current_arena_state_id() != &"impound_field":
		push_error("rain_city_towmaster stage did not enter impound_field arena state")
		convoy_actor.queue_free()
		return false
	if convoy_actor.current_attack_id() != &"":
		push_error("rain_city_towmaster stage started with a live attack")
		convoy_actor.queue_free()
		return false
	var profile := convoy_actor.get("combat_profile") as TowmasterCombatProfile
	if profile == null:
		push_error("rain_city_towmaster stage actor has no combat profile")
		convoy_actor.queue_free()
		return false
	var phase := profile.phase_at(RAIN_CITY_TOWMASTER_PHASE_INDEX)
	if phase == null:
		push_error("rain_city_towmaster stage actor has no phase 3 profile")
		convoy_actor.queue_free()
		return false
	if phase.attack_ids.is_empty() or phase.attack_ids[0] != RAIN_CITY_TOWMASTER_VIEW_BARRAGE_ID:
		push_error("rain_city_towmaster stage phase 3 does not begin with citation_barrage")
		convoy_actor.queue_free()
		return false
	var barrage_attack := profile.attack_for_id(phase.attack_ids[0])
	if barrage_attack == null:
		push_error("rain_city_towmaster stage profile is missing citation_barrage definition")
		convoy_actor.queue_free()
		return false

	convoy_actor.advance_combat(0.0)
	convoy_actor.advance_combat(phase.telegraph_scale * barrage_attack.telegraph_seconds + 0.001)
	convoy_actor.advance_combat(phase.cooldown_scale * barrage_attack.cooldown_seconds + 0.001)
	convoy_actor.advance_combat(0.0)
	if convoy_actor.current_attack_id() != RAIN_CITY_TOWMASTER_VIEW_ATTACK_ID:
		push_error("rain_city_towmaster stage failed to reach frozen tow_sweep telegraph")
		convoy_actor.queue_free()
		return false
	var warning_lights := convoy_actor.get_node_or_null("WarningLights") as Node
	if warning_lights != null:
		warning_lights.visible = true
	var hud_nodes := _target.find_children("*", "GameHUD", true, false)
	if hud_nodes.is_empty():
		push_error("rain_city_towmaster staging requires the production GameHUD")
		convoy_actor.queue_free()
		return false
	var hud := hud_nodes[0] as GameHUD
	hud.show_objective("DISABLE THE MUNICIPAL TOWMASTER")
	hud.set_boss_state("MUNICIPAL TOWMASTER", &"case_closed", 0.25)
	hud.show_boss_phase_caption("CASE CLOSED // CITATION CORE EXPOSED", 3.0)
	return true
