extends RefCounted


static func spawn(enemy: Node) -> void:
	var parent := enemy.get_tree().current_scene
	if parent == null:
		return
	var pop := Node3D.new()
	pop.name = "EnemyDeathPop"
	parent.add_child(pop)
	pop.global_position = enemy.get_auto_aim_position()
	var quality := enemy.get_node_or_null("/root/QualityManager")
	if quality != null:
		quality.claim_temporary_effect(pop)
	for index in 10:
		var fragment := MeshInstance3D.new()
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE * randf_range(0.05, 0.11)
		fragment.mesh = mesh
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("ffb22e") if index % 2 == 0 else Color("e94b35")
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 3.0
		fragment.material_override = material
		pop.add_child(fragment)
		var direction := Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.3), randf_range(-1.0, 1.0)).normalized()
		var tween := fragment.create_tween().set_parallel()
		tween.tween_property(fragment, "position", direction * randf_range(0.45, 0.95), 0.38)
		tween.tween_property(fragment, "scale", Vector3.ZERO, 0.38)
	var cleanup := Timer.new()
	cleanup.name = "CleanupTimer"
	cleanup.one_shot = true
	cleanup.wait_time = 0.42
	cleanup.timeout.connect(pop.queue_free)
	pop.add_child(cleanup)
	cleanup.start()
