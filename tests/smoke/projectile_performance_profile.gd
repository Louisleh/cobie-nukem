extends SceneTree

const BOLT := preload("res://scenes/enemies/enemy_bolt.tscn")
const FETCH_PROJECTILE := preload("res://scenes/weapons/fetch_projectile.tscn")
const PipelinePrewarmer := preload("res://scripts/core/runtime_pipeline_prewarmer.gd")

const BOLT_BENCH_SAMPLES := 4
const FETCH_CYCLE_COUNT := 18


func _initialize() -> void:
	var prewarmer := PipelinePrewarmer.new()
	get_root().add_child(prewarmer)
	prewarmer.warm(PackedStringArray([
		"res://scenes/enemies/enemy_bolt.tscn",
		"res://scenes/weapons/fetch_projectile.tscn",
	]))
	await prewarmer.completed
	prewarmer.queue_free()
	await process_frame
	var stage := Node3D.new()
	get_root().add_child(stage)
	var camera := Camera3D.new()
	camera.current = true
	stage.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	stage.add_child(light)
	for _frame in 24:
		await process_frame
	var failures := PackedStringArray()
	for sample_index in BOLT_BENCH_SAMPLES:
		var bolt := BOLT.instantiate() as EnemyProjectile
		bolt.process_mode = Node.PROCESS_MODE_DISABLED
		stage.add_child(bolt)
		bolt.position = Vector3(float(sample_index) * 0.45 - 0.7, 0.0, -2.0)
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := float(Time.get_ticks_usec() - started) / 1000.0
		print("PROJECTILE PROFILE: spawn=%d rendered_frame=%.3fms" % [sample_index + 1, elapsed])
		if elapsed > 50.0:
			failures.append("pooled projectile render %d exceeded 50ms: %.3fms" % [sample_index + 1, elapsed])
		for _frame in 20:
			await process_frame
	var pool: Node = get_root().get_node_or_null("/root/ProjectilePool")
	if pool == null:
		failures.append("ProjectilePool unavailable for fetch launch cycles")
	else:
		await _run_fetch_projectile_cycle(pool, stage, failures)
	stage.queue_free()
	if failures.is_empty():
		print("PROJECTILE PERFORMANCE PROFILE: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_fetch_projectile_cycle(pool: Node, stage: Node3D, failures: PackedStringArray) -> void:
	var fetch_owner := Node3D.new()
	stage.add_child(fetch_owner)
	fetch_owner.global_position = Vector3(0.0, 1.0, 0.0)
	var start_created: int = int(pool.created_count_for_scene(FETCH_PROJECTILE))
	await process_frame
	if start_created <= 0:
		failures.append("fetch projectile pool should prewarm at least one projectile")
		return
	var start_available: int = int(pool.available_count_for_scene(FETCH_PROJECTILE))
	var start_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var max_active := 0
	for sample_index in FETCH_CYCLE_COUNT:
		var projectile := pool.acquire(FETCH_PROJECTILE) as FetchProjectile
		if projectile == null:
			failures.append("fetch projectile cycle %d failed to acquire" % [sample_index + 1])
			continue
		projectile.begin_shot(sample_index + 1, fetch_owner, 0)
		projectile.speed = 0.0
		projectile.fuse_seconds = 0.02
		projectile.damage = 0.0
		projectile.max_bounces = 0
		projectile.set_golden_trail(sample_index % 2 == 0)
		projectile.launch(Vector3(0.0, 1.0, -2.0) + Vector3(float(sample_index % 3) * 0.1, 0.0, 0.0), Vector3.FORWARD, fetch_owner)
		for _frame in 3:
			await process_frame
		var active_count: int = int(pool.active_count_for_scene(FETCH_PROJECTILE))
		max_active = maxi(max_active, active_count)
	if pool.created_count_for_scene(FETCH_PROJECTILE) != start_created:
		failures.append("fetch pool projectiles were instantiated beyond prewarmed set")
	if pool.available_count_for_scene(FETCH_PROJECTILE) != start_available:
		failures.append("fetch cycle did not return all projectiles to pool")
	if pool.active_count_for_scene(FETCH_PROJECTILE) != 0:
		failures.append("fetch cycle left active projectiles in pool")
	if max_active > 2:
		failures.append("fetch cycle exceeded bounded active count: %d" % max_active)
	await process_frame
	var end_nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	if end_nodes > start_nodes:
		failures.append("fetch projectile cycles increased node count from %d to %d" % [start_nodes, end_nodes])
