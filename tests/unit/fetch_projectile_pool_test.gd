extends SceneTree

const FETCH_PROJECTILE := preload("res://scenes/weapons/fetch_projectile.tscn")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_fetch_projectile_reuse()
	if failures == 0:
		print("FETCH PROJECTILE POOL TEST: PASS")
	else:
		push_error("FETCH PROJECTILE POOL TEST: %d FAILURE(S)" % failures)
	quit(failures)


func _test_fetch_projectile_reuse() -> void:
	var pool: Node = get_root().get_node_or_null("ProjectilePool")
	_expect(pool != null, "ProjectilePool autoload exists")
	if pool == null:
		return
	var scene: Node = get_root()
	var owner := Node3D.new()
	scene.add_child(owner)
	await process_frame
	var start_created: int = int(pool.created_count_for_scene(FETCH_PROJECTILE))
	var start_available: int = int(pool.available_count_for_scene(FETCH_PROJECTILE))
	if start_created <= 0:
		_expect(false, "fetch projectile pool is prewarmed before lifecycle assertions")
	for index in 12:
		var projectile := pool.acquire(FETCH_PROJECTILE) as FetchProjectile
		_expect(projectile != null, "fetch pool returns a valid projectile")
		if projectile == null:
			continue
		var shot_id := index + 1
		projectile.begin_shot(shot_id, owner, 0)
		projectile.speed = 0.0
		projectile.fuse_seconds = 0.01
		projectile.launch(Vector3(0.0, 1.0, -2.0), Vector3.BACK, owner)
		await physics_frame
		await physics_frame
		_expect(not projectile.can_recall(shot_id), "recalled token is inactive after automatic return")
		if projectile.can_recall(shot_id):
			break
	_expect(pool.created_count_for_scene(FETCH_PROJECTILE) == start_created, "fetch projectile pool has fixed creation budget")
	_expect(pool.available_count_for_scene(FETCH_PROJECTILE) == start_available, "fetch pool fully returns projectiles after repeated reuse")
	_expect(pool.active_count_for_scene(FETCH_PROJECTILE) == 0, "fetch pool has zero active projectiles after cycle")
	var held: Array[FetchProjectile] = []
	for index in start_created + 4:
		var projectile := pool.acquire(FETCH_PROJECTILE) as FetchProjectile
		_expect(projectile != null, "bounded fetch pool recycles under capacity pressure")
		if projectile != null:
			projectile.begin_shot(1000 + index, owner, 0)
			held.append(projectile)
	_expect(pool.created_count_for_scene(FETCH_PROJECTILE) == start_created, "capacity pressure does not instantiate overflow fetch projectiles")
	_expect(pool.active_count_for_scene(FETCH_PROJECTILE) <= start_created, "capacity pressure keeps active fetch projectiles bounded")
	var unique_projectiles: Dictionary = {}
	for projectile in held:
		unique_projectiles[projectile.get_instance_id()] = projectile
	for projectile in unique_projectiles.values():
		pool.release_projectile(projectile)
	_expect(pool.available_count_for_scene(FETCH_PROJECTILE) == start_available, "capacity-pressure projectiles fully return to the pool")
	owner.queue_free()
	await process_frame


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
