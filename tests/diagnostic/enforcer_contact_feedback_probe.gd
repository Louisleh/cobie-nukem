extends SceneTree

# Staged production instances. No ordinary-play or historical-hit inference.
const PLAYER := preload("res://scenes/player/cobie_player.tscn")
const ENFORCER := preload("res://scenes/enemies/umbrella_shield_enforcer.tscn")
const HUD := preload("res://scenes/ui/hud.tscn")
const LIMIT_USEC := 90_000_000
var output := ""
var rendered := false
var started := 0
var failures: Array[String] = []
var records: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var events: Array[Dictionary] = []
var damage_events: Array[Dictionary] = []
var stage: Node3D
var player: CobiePlayer
var enemy: UmbrellaShieldEnforcer
var hud: Node
var paw: Pawstol
var crosshair: RetroCrosshair
var bytes_written := 0
var finishing := false
var source_hashes: Dictionary = {}

func _initialize() -> void:
	started = Time.get_ticks_usec()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		elif argument == "--render": rendered = true
		else: failures.append("unknown argument: " + argument)
	call_deferred("_run")

func _process(_delta: float) -> bool:
	if not finishing and Time.get_ticks_usec() - started > LIMIT_USEC:
		failures.append("90-second probe budget exceeded")
		call_deferred("_finish")
	return false

func _expect(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _close(actual: float, expected: float, label: String) -> void:
	_expect(absf(actual - expected) < 0.002, "%s: got %.6f expected %.6f" % [label, actual, expected])

func _run() -> void:
	if not output.begins_with("/") or DirAccess.dir_exists_absolute(output) or not failures.is_empty():
		push_error("Probe needs a new absolute output path")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		quit(2)
		return
	source_hashes = _source_hashes()
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	root.get_node("GameState").select_difficulty(&"story")
	stage = Node3D.new()
	stage.name = "STAGED_ENFORCER_DIAGNOSTIC"
	root.add_child(stage)
	current_scene = stage
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("38434e")
	stage.add_child(environment)
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(0, -0.1, -6)
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = BoxShape3D.new()
	floor_shape.shape.size = Vector3(40, 0.2, 40)
	floor_body.add_child(floor_shape)
	stage.add_child(floor_body)
	player = PLAYER.instantiate() as CobiePlayer
	stage.add_child(player)
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	player.camera.current = true
	paw = player.weapons[0] as Pawstol
	hud = HUD.instantiate()
	stage.add_child(hud)
	hud.bind_player(player)
	crosshair = hud.get_node("Root/Crosshair") as RetroCrosshair
	player.combat_feedback.connect(_on_feedback)
	await create_timer(0.6).timeout
	if rendered:
		await _rendered_cases()
	else:
		await _functional_cases()
	call_deferred("_finish")

func _fresh_enemy(distance: float = 10.0, yaw: float = PI) -> void:
	if is_instance_valid(enemy):
		enemy.free()
		enemy = null
	enemy = ENFORCER.instantiate() as UmbrellaShieldEnforcer
	enemy.position = Vector3(0, 0, -distance)
	enemy.rotation.y = yaw
	stage.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.damaged.connect(_on_damage)
	player.camera.global_position = Vector3(0, 1.56, 0)
	player.camera.look_at(enemy.global_position + Vector3(0, 0.8, 0))
	player.camera.h_offset = 0
	player.camera.v_offset = 0
	paw.auto_aim = null # Controlled ray arm; production Paw spread remains enabled.
	player.select_weapon(0)
	await create_timer(0.5).timeout
	await physics_frame
	await physics_frame
	enemy._update_health_bar_presentation()
	_close(enemy.health, 112.5, "fresh authored story HP")
	_close(enemy.directional_shield.current_shield_health, 72, "fresh authored shield HP")

func _on_feedback(event: CombatFeedbackEvent) -> void:
	events.append({"kind": String(event.legacy_kind()), "hit_type": event.hit_type,
		"incoming_damage": event.damage, "killed": event.killed,
		"target_is_enforcer": event.target == enemy,
		"destination": _vec(event.destination), "tick_usec": Time.get_ticks_usec()})

func _on_damage(amount: float, _source: Node, hit_position: Vector3) -> void:
	damage_events.append({"applied": amount, "hit_position": _vec(hit_position),
		"hp_after": enemy.health, "shield_after": enemy.directional_shield.current_shield_health})

func _vec(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _snapshot(label: String) -> Dictionary:
	var fill := enemy.get_node("EnemyHealthBar/Fill") as MeshInstance3D
	var result := {"label": label, "hp": enemy.health,
		"shield": enemy.directional_shield.current_shield_health,
		"guard_active": enemy.directional_shield.is_guarding(),
		"broken": enemy.directional_shield.is_permanently_broken(),
		"guard_state": enemy.guard_state, "state": enemy.state,
		"shield_visual": enemy.get_node("Visual/Shield").visible,
		"fill_width": (fill.mesh as QuadMesh).size.x,
		"crosshair_result": String(crosshair._shot_result),
		"crosshair_seconds": crosshair._shot_result_time,
		"ammo": paw.ammo, "fov": player.camera.fov,
		"camera_position": _vec(player.camera.global_position),
		"camera_forward": _vec(-player.camera.global_basis.z),
		"tick_usec": Time.get_ticks_usec()}
	records.append(result)
	return result

func _primary(label: String) -> Dictionary:
	await create_timer(0.25).timeout
	var before := enemy.health
	var count_before := events.size()
	var damage_before := damage_events.size()
	var basis_before := player.camera.global_basis
	seed(9173 + records.size())
	_expect(paw.fire_primary(), label + " shipping primary accepts trigger")
	var result := _snapshot(label)
	result["applied_hp"] = before - enemy.health
	result["new_events"] = events.size() - count_before
	result["new_damage_events"] = damage_events.size() - damage_before
	result["feedback"] = events.back().duplicate() if events.size() > count_before else {}
	result["damage_event"] = damage_events.back().duplicate() if damage_events.size() > damage_before else {}
	_expect(events.size() == count_before + 1, label + " one terminal feedback event")
	_expect(player.camera.global_basis.is_equal_approx(basis_before), label + " recoil leaves ray basis unchanged")
	return result

func _functional_cases() -> void:
	await _fresh_enemy()
	for index in 4:
		enemy._set_state(EnemyAgent.State.CHASE) # Deliberately guarded before each contact.
		var result := await _primary("guarded_front_%d" % (index + 1))
		_expect(result.feedback.get("target_is_enforcer", false), "front ray hits actual enforcer collider")
		_close(result.applied_hp, 4.32 if index < 2 else 18.0, "authored frontal HP quantum")
		_close(result.shield, 36 if index == 0 else 0, "two guarded contacts drain72->36->0")
		_expect(result.crosshair_result == "enemy", "real weapon/player/HUD enemy feedback in collision frame")
	_close(enemy.health, 67.86, "four controlled body contacts leave67.86HP")
	_expect(enemy.directional_shield.is_permanently_broken(), "broken shield persists")
	await _fresh_enemy(10, PI * 0.5)
	var side := await _primary("side_body")
	_close(side.applied_hp, 18 * 1.34, "side body bypass amplification")
	_close(side.shield, 72, "side bypass does not drain shield")
	await _fresh_enemy()
	enemy._start_guard_recovery()
	# Fire immediately within authored story0.24s recovery, after normal weapon readiness.
	var old_hp := enemy.health
	_expect(paw.fire_primary(), "recovery primary accepts trigger")
	var recovery := _snapshot("recovery_body")
	recovery["applied_hp"] = old_hp - enemy.health
	_close(recovery.applied_hp, 18, "recovery body gets full damage")
	_close(recovery.shield, 72, "recovery contact does not drain shield")
	await _fresh_enemy()
	var first := await _primary("hurt_window_first_guarded")
	var second := await _primary("hurt_window_second_without_state_reset")
	_close(first.applied_hp, 4.32, "first contact guarded")
	_close(second.applied_hp, 18, "HURT disables guard when AI progression is deliberately stopped")
	_close(second.shield, 36, "two hits are not two guarded hits")
	await _fresh_enemy()
	enemy.set_target(player)
	enemy._set_state(EnemyAgent.State.CHASE)
	enemy.set_physics_process(true)
	paw.auto_aim = player.auto_aim
	player.camera.look_at(enemy.get_auto_aim_position())
	for index in 4:
		var result := await _primary("natural_ai_primary_%d" % (index + 1))
		_expect(result.feedback.get("target_is_enforcer", false), "natural AI primary contacts production enemy")
		_expect(result.applied_hp > 0, "natural AI contacted damage reaches HP")
		enemy._update_health_bar_presentation()
	enemy.set_physics_process(false)
	await _fresh_enemy()
	player.camera.look_at(enemy.get_auto_aim_position())
	paw.auto_aim = player.auto_aim
	var aim := await _primary("production_autoaim_primary")
	_expect(aim.feedback.get("target_is_enforcer", false), "production autoaim targets actual collider")
	_close(aim.applied_hp, 18 * 0.24 * 1.2, "autoaim-height guarded weakpoint damage")
	await _fresh_enemy()
	player.camera.rotate_y(deg_to_rad(40))
	player.camera.rotate_x(0.3) # Sky ray avoids the actual floor in the miss arm.
	var miss := await _primary("clear_miss")
	_expect(miss.feedback.get("kind") == "miss", "clear miss classified")
	_close(miss.applied_hp, 0, "miss has no enemy damage")
	await _fresh_enemy()
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 1, -5)
	var wall_shape := CollisionShape3D.new()
	wall_shape.shape = BoxShape3D.new()
	wall_shape.shape.size = Vector3(3, 3, 0.2)
	wall.add_child(wall_shape)
	stage.add_child(wall)
	await physics_frame
	await physics_frame
	paw.auto_aim = player.auto_aim
	var world := await _primary("solid_world_occlusion")
	_expect(world.feedback.get("kind") == "world", "solid world intercept classified")
	_close(world.applied_hp, 0, "world intercept has no enemy damage")
	_expect(player.auto_aim.current_target == null, "world occlusion rejects aim lock")
	wall.free()
	await _fresh_enemy()
	paw.auto_aim = player.auto_aim
	for angle in [5.0, 13.0, 20.0]:
		player.camera.look_at(enemy.get_auto_aim_position())
		player.camera.rotate_y(deg_to_rad(angle))
		player.auto_aim.current_target = null
		var direction := player.auto_aim.get_aim_direction(player.camera, 90)
		var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, player.camera.global_position + direction * 90)
		query.exclude = [player.get_rid()]
		var hit := player.camera.get_world_3d().direct_space_state.intersect_ray(query)
		records.append({"label": "bounded_autoaim", "angle": angle, "locked": player.auto_aim.current_target == enemy,
			"ray_hits_enemy": hit.get("collider") == enemy, "corrected_direction": _vec(direction)})
	await _projectile_cases()

func _projectile_cases() -> void:
	await _fresh_enemy(6)
	var launcher := player.weapons[2] as FetchLauncher
	launcher.unlocked = true # Stage loadout only; production values remain unchanged.
	launcher.auto_aim = null
	for index in 2:
		player.select_weapon(2)
		await create_timer(0.4).timeout
		player._process_weapon_selection_queue() # Movement physics is disabled in this stage.
		await create_timer(0.9).timeout
		enemy._set_state(EnemyAgent.State.CHASE)
		player.camera.look_at(enemy.global_position + Vector3(0, 0.8, 0))
		var before := enemy.health
		var count_before := damage_events.size()
		var fired := launcher.fire_primary()
		_expect(fired, "actual Fetch launcher fires")
		if not fired: return
		var projectile := launcher.latest_projectile
		var end := Time.get_ticks_usec() + 1_500_000
		while damage_events.size() == count_before and Time.get_ticks_usec() < end:
			await physics_frame
		var result := _snapshot("moving_fetch_contact_%d" % (index + 1))
		result["applied_hp"] = before - enemy.health
		result["damage_event"] = damage_events.back().duplicate() if damage_events.size() > count_before else {}
		result["projectile_bounces"] = projectile.bounces
		result["dedup_contains_enemy"] = projectile._damaged_on_bounce.has(enemy)
		_expect(result.dedup_contains_enemy, "actual moving projectile collision reaches enemy once")
		_close(result.applied_hp, 58 * 0.24, "projectile guarded body damage")
		_close(result.shield, 36 if index == 0 else 0, "two actual guarded projectile contacts break shield")
		projectile._return_to_pool() # Stop arm before fuse/splash; not ordinary gameplay.
		await physics_frame

func _rendered_cases() -> void:
	_expect(not DisplayServer.get_name() in ["headless", "web"], "rendered run requires native display")
	_expect(RenderingServer.get_current_rendering_method() == "gl_compatibility", "native Compatibility rendering")
	_expect(not OS.get_cmdline_args().has("--fixed-fps") and not OS.get_cmdline_args().has("--write-movie"), "real-time viewport capture only")
	for distance in [8.0, 15.0]:
		await _fresh_enemy(distance)
		paw.auto_aim = player.auto_aim
		player.camera.look_at(enemy.get_auto_aim_position())
		player.camera.reset_physics_interpolation()
		await physics_frame
		await physics_frame
		enemy._update_health_bar_presentation()
		await _capture("before_%.0fm" % distance)
		var result := await _primary("rendered_contact_%.0fm" % distance)
		_expect(result.feedback.get("target_is_enforcer", false) and result.applied_hp > 0, "rendered real ray damages target")
		enemy._update_health_bar_presentation()
		await _capture("immediate_%.0fm" % distance)
		await create_timer(0.45).timeout
		enemy._update_health_bar_presentation()
		await _capture("delayed_%.0fm" % distance)
		_expect(crosshair._shot_result == "", "hit marker expires before delayed ordinary screenshot")

func _capture(label: String) -> void:
	if captures.size() >= 10:
		failures.append("capture count cap")
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("viewport readback unavailable")
		return
	var bar := enemy.get_node("EnemyHealthBar") as Node3D
	var fill := enemy.get_node("EnemyHealthBar/Fill") as MeshInstance3D
	var mesh := fill.mesh as QuadMesh
	var upper := player.camera.unproject_position(fill.to_global(Vector3(0, mesh.size.y * 0.5, 0)))
	var lower := player.camera.unproject_position(fill.to_global(Vector3(0, -mesh.size.y * 0.5, 0)))
	var left := player.camera.unproject_position(fill.to_global(Vector3(-mesh.size.x * 0.5, 0, 0)))
	var right := player.camera.unproject_position(fill.to_global(Vector3(mesh.size.x * 0.5, 0, 0)))
	var bar_center := player.camera.unproject_position(bar.global_position)
	var region := Rect2i(Vector2i(roundi(bar_center.x) - 40, roundi(bar_center.y) - 10), Vector2i(80, 20)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var green_points: Array[Vector2i] = []
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var color := image.get_pixel(x, y)
			if color.g > 0.4 and color.g > color.r * 1.3 and color.g > color.b * 1.3:
				green_points.append(Vector2i(x, y))
	var green_bounds := Rect2i()
	if not green_points.is_empty():
		green_bounds = Rect2i(green_points[0], Vector2i.ONE)
		var minimum := green_points[0]
		var maximum := green_points[0]
		for point in green_points:
			minimum = minimum.min(point)
			maximum = maximum.max(point)
		green_bounds = Rect2i(minimum, maximum - minimum + Vector2i.ONE)
	var material := fill.material_override as StandardMaterial3D
	var png := image.save_png_to_buffer()
	if png.is_empty() or bytes_written + png.size() >= 32 * 1024 * 1024:
		failures.append("capture byte cap or empty PNG")
		return
	var path := output.path_join(label + ".png")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("PNG open")
		return
	file.store_buffer(png)
	_expect(file.get_error() == OK, "PNG write")
	file.close()
	bytes_written += png.size()
	captures.append({"label": label, "file": path, "sha256": FileAccess.get_sha256(path), "bytes": png.size(),
		"image_size": [image.get_width(), image.get_height()], "bar_center": [bar_center.x, bar_center.y],
		"raster_green_pixels": green_points.size(), "raster_green_bounds": [green_bounds.position.x, green_bounds.position.y, green_bounds.size.x, green_bounds.size.y],
		"pixel_roi": [region.position.x, region.position.y, region.size.x, region.size.y],
		"billboard_keep_scale": material.billboard_keep_scale, "geometric_projection_only": "Transform projection is not raster coverage when billboard shader changes basis/scale",
		"projected_fill_width": left.distance_to(right), "projected_fill_height": upper.distance_to(lower),
		"bar_visible": bar.visible, "hp_digits_visible": enemy.get_node("EnemyHealthBar/HealthPoints").visible,
		"state": _snapshot(label), "elapsed_usec": Time.get_ticks_usec() - started})

func _finish() -> void:
	if finishing: return
	finishing = true
	_expect(source_hashes == _source_hashes(), "source inputs stable during probe")
	var receipt := {"status": "PASS" if failures.is_empty() else "FAIL", "scope": "Staged production contact/feedback; no ordinary or human claim",
		"base": "e89e029053af8c641cc975940f18c3c2db6e436b", "probe_sha256": FileAccess.get_sha256("res://tests/diagnostic/enforcer_contact_feedback_probe.gd"),
		"rendered": rendered, "wall_usec": Time.get_ticks_usec() - started,
		"source_hashes": source_hashes, "renderer": RenderingServer.get_current_rendering_method(), "display": DisplayServer.get_name(),
		"limits": {"seconds": 90, "pngs": 10, "png_bytes": 32 * 1024 * 1024},
		"user_data_dir": OS.get_user_data_dir(), "records": records, "events": events, "damage_events": damage_events,
		"captures": captures, "failures": failures}
	var file := FileAccess.open(output.path_join("receipt.json"), FileAccess.WRITE)
	if file == null: failures.append("receipt open")
	else:
		file.store_string(JSON.stringify(receipt, "\t"))
		if file.get_error() != OK: failures.append("receipt write")
		file.close()
	current_scene = null
	if is_instance_valid(stage): stage.queue_free()
	stage = null
	player = null
	enemy = null
	hud = null
	paw = null
	crosshair = null
	for index in 4: await process_frame
	if failures.is_empty(): print("ENFORCER CONTACT FEEDBACK PROBE: PASS")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _source_hashes() -> Dictionary:
	var result := {}
	for path in ["project.godot", "scripts/ai/umbrella_shield_enforcer.gd", "scripts/ai/directional_shield_component.gd", "scripts/ai/enemy_agent.gd", "scenes/enemies/umbrella_shield_enforcer.tscn", "scripts/combat/pawstol.gd", "scripts/combat/weapon_base.gd", "scripts/combat/fetch_launcher.gd", "scripts/combat/fetch_projectile.gd", "scripts/player/auto_aim_component.gd", "scripts/player/player_controller.gd", "scripts/player/tactile_feedback.gd", "scripts/ui/hud.gd", "scripts/ui/crosshair.gd", "scenes/ui/hud.tscn", "scenes/player/cobie_player.tscn", "resources/difficulty/story.tres", "resources/enemies/umbrella_shield_enforcer.tres", "resources/weapons/pawstol.tres", "resources/weapons/fetch_launcher.tres", "tests/diagnostic/enforcer_contact_feedback_probe.gd"]:
		result[path] = FileAccess.get_sha256("res://" + path)
	return result
