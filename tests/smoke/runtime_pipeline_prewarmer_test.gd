extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var effects := ImpactEffectPool.new()
	seed(8765)
	var expected_random := randf()
	seed(8765)
	var effect_samples := effects.create_pipeline_samples()
	_expect(effects.allocated_count() == 0 and effects.active_count() == 0, "Render samples never acquire gameplay pool entries")
	_expect(is_equal_approx(randf(), expected_random), "Impact render samples do not consume global RNG")
	for sample in effect_samples:
		sample.free()
	effect_samples.clear()
	var groups_before := [get_nodes_in_group(&"enemies").size(), get_nodes_in_group(&"auto_aim_targets").size(), get_nodes_in_group(&"player").size()]
	var game_state := root.get_node("GameState")
	var run_stats_before: Dictionary = game_state.run_stats.duplicate(true)
	var warmup := RuntimePipelinePrewarmer.new()
	root.add_child(warmup)
	var completed_count := [0]
	warmup.completed.connect(func() -> void: completed_count[0] += 1)
	seed(54321)
	expected_random = randf()
	seed(54321)
	warmup.warm(PackedStringArray([
		"res://scenes/enemies/mutant_groundskeeper.tscn",
		"res://scenes/weapons/fetch_projectile.tscn",
		"res://scenes/enemies/umbrella_shield_enforcer.tscn",
		"res://assets/models/environment/rain_city_slice_landmark.glb",
		"res://scenes/weapons/pawstol.tscn",
	]))
	var saw_muzzle := false
	var saw_mapped_material := false
	var saw_profile_sprite := false
	var saw_impact := false
	var saw_health_label := false
	var saw_omni := false
	var saw_without_omni := false
	var observed_mesh_views: Dictionary = {}
	var temporary_ids := PackedInt64Array()
	for frame in 500:
		await process_frame
		if is_instance_valid(warmup._viewport):
			temporary_ids.append(warmup._viewport.get_instance_id())
			var camera := warmup._viewport.get_camera_3d()
			_expect(warmup._active.size() <= RuntimePipelinePrewarmer.VISUALS_PER_STAGE, "Only a bounded batch enters the render world")
			for sample in warmup._active:
				_expect(sample.get_script() == null, "Native render samples have no gameplay scripts")
				_expect(sample.get_child_count() == 0, "Geometry proxies have no gameplay children")
				_expect(camera.is_position_in_frustum(sample.global_position), "Each rendered proxy is inside the camera frustum")
				saw_muzzle = saw_muzzle or sample.name == "MuzzleBurst"
				saw_impact = saw_impact or sample.get_meta(&"preparation_source", "") == "impact_effect_pool"
				saw_health_label = saw_health_label or sample.get_meta(&"preparation_source", "") == "enemy_health_points"
				if sample is MeshInstance3D:
					observed_mesh_views[warmup._stage_variant] = sample.rotation
					for surface in sample.mesh.get_surface_count():
						var material: Material = (sample as MeshInstance3D).get_surface_override_material(surface)
						saw_mapped_material = saw_mapped_material or material == RainCityMaterialApplier.MATERIALS["RC_RainBrick"] or material == RainCityMaterialApplier.MATERIALS["RC_HarbourSteel"]
				if sample is Sprite3D:
					saw_profile_sprite = saw_profile_sprite or (sample.texture != null and sample.hframes == EnemyPresentationProfile.HORIZONTAL_FRAMES)
			if not warmup._active.is_empty():
				saw_omni = saw_omni or warmup._light.visible
				saw_without_omni = saw_without_omni or not warmup._light.visible
			_expect(get_nodes_in_group(&"enemies").size() == groups_before[0], "Warmup never registers enemies")
			_expect(get_nodes_in_group(&"auto_aim_targets").size() == groups_before[1], "Warmup never registers aim targets")
			_expect(get_nodes_in_group(&"player").size() == groups_before[2], "Warmup never registers a player")
		if completed_count[0] > 0:
			break
	_expect(warmup.succeeded and completed_count[0] == 1, "Enabled preparation completes exactly once")
	_expect(saw_muzzle and saw_mapped_material and saw_profile_sprite, "Actual hidden muzzle, mapped material and production sprite variants are prepared")
	_expect(saw_impact and saw_health_label, "Production impact and healthbar label variants are prepared")
	_expect(saw_omni and saw_without_omni, "Both live lighting states are exercised")
	_expect(observed_mesh_views.has(0) and observed_mesh_views.has(1) and observed_mesh_views.has(2) and observed_mesh_views.has(3), "Both opposite mesh orientations render under both lighting states")
	if observed_mesh_views.has(0) and observed_mesh_views.has(1):
		var front_normal: Vector3 = Basis.from_euler(observed_mesh_views[0]) * Vector3.RIGHT
		var back_normal: Vector3 = Basis.from_euler(observed_mesh_views[1]) * Vector3.RIGHT
		_expect(front_normal.z * back_normal.z < 0.0 and absf(front_normal.z) > 0.1, "Thin X-facing planes have a front-facing orientation instead of edge-on coverage")
	_expect(game_state.run_stats == run_stats_before, "Warmup does not mutate run state")
	_expect(is_equal_approx(randf(), expected_random), "Scene preparation does not consume global RNG")
	_expect(warmup._viewport == null and warmup._samples.is_empty() and warmup._active.is_empty(), "Completion releases all temporary render ownership")
	for id in temporary_ids:
		_expect(not is_instance_id_valid(id), "Completed temporary viewport is freed")
	if DisplayServer.get_name() == "headless":
		_expect(warmup.rendered_boundaries == 0 and warmup.functional_boundaries > 0, "Headless ticks are explicitly not render evidence")
	else:
		_expect(warmup.rendered_boundaries > 0, "Rendered completion requires actual post-draw boundaries")
	warmup.warm(PackedStringArray(["res://missing_warmup_scene.tscn"]))
	for frame in 100:
		await process_frame
		if completed_count[0] > 1:
			break
	_expect(not warmup.succeeded and completed_count[0] == 2, "Missing required resource reports failed readiness")
	warmup.warm(PackedStringArray(["res://scenes/enemies/mutant_groundskeeper.tscn"]))
	await process_frame
	var replaced_id := warmup._viewport.get_instance_id()
	warmup.warm(PackedStringArray(["res://scenes/weapons/pawstol.tscn"]))
	_expect(not is_instance_id_valid(replaced_id), "Repeated preparation immediately retires the previous viewport")
	var cancelled_id := warmup._viewport.get_instance_id()
	warmup.queue_free()
	await process_frame
	await process_frame
	_expect(not is_instance_id_valid(cancelled_id), "Parent cancellation releases the live viewport")
	await process_frame
	if failures.is_empty():
		print("RUNTIME PIPELINE PREPARATION: PASS (rendered boundaries are separate from headless lifecycle)")
	else:
		for failure in failures:
			push_error(failure)
	_finish.call_deferred(0 if failures.is_empty() else 1)

func _finish(exit_code: int) -> void:
	await process_frame
	quit(exit_code)

func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
