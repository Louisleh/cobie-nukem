extends SceneTree

const BOLT := preload("res://scenes/enemies/enemy_bolt.tscn")
const PipelinePrewarmer := preload("res://scripts/core/runtime_pipeline_prewarmer.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var prewarmer := PipelinePrewarmer.new()
	root.add_child(prewarmer)
	prewarmer.warm(PackedStringArray(["res://scenes/enemies/enemy_bolt.tscn"]))
	await prewarmer.completed
	prewarmer.queue_free()
	await process_frame
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	camera.current = true
	stage.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	stage.add_child(light)
	for _frame in 24:
		await process_frame
	var failures := PackedStringArray()
	for sample_index in 4:
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
	stage.queue_free()
	await process_frame
	if failures.is_empty():
		print("PROJECTILE PERFORMANCE PROFILE: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
