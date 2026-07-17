extends SceneTree

const BALL_RETURN_SCENE := preload("res://scenes/interactables/ball_return_secret.tscn")
const OPENING_FOUNDRY_SCENE := preload("res://assets/models/environment/salmon_creek_opening_foundry.glb")
const WEAPON_VIEWMODELS: Dictionary = {
	&"pawstol": preload("res://assets/models/weapons/pawstol_viewmodel.glb"),
	&"barkshot": preload("res://assets/models/weapons/barkshot_viewmodel.glb"),
	&"fetch_launcher": preload("res://assets/models/weapons/fetch_launcher_viewmodel.glb"),
}
const PILOT_MODELS: Dictionary = {
	&"field_kit": preload("res://assets/models/pilot/salmon_creek_field_kit.glb"),
	&"tunnel_module": preload("res://assets/models/pilot/maintenance_tunnel_module_a.glb"),
	&"lod_crate": preload("res://assets/models/pilot/compliance_supply_crate_lod.glb"),
	&"pickup_pedestal": preload("res://assets/models/pilot/fetch_charge_pedestal.glb"),
	&"future_landmark": preload("res://assets/models/pilot/rain_city_wayfinding_beacon.glb"),
}
const SENTRY_FRAMES: Array[Texture2D] = [
	preload("res://assets/sprites/experiments/compliance_sentry/sentry_front.png"),
	preload("res://assets/sprites/experiments/compliance_sentry/sentry_right.png"),
	preload("res://assets/sprites/experiments/compliance_sentry/sentry_back.png"),
	preload("res://assets/sprites/experiments/compliance_sentry/sentry_left.png"),
	preload("res://assets/sprites/experiments/compliance_sentry/sentry_hit_front.png"),
]

var failures: Array[String] = []


func _initialize() -> void:
	await _test_ball_return_production_asset()
	await _test_opening_foundry_asset()
	await _test_weapon_viewmodels()
	await _test_production_pipeline_pilot()
	if failures.is_empty():
		print("ASSET CONTRACT TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_ball_return_production_asset() -> void:
	var machine := BALL_RETURN_SCENE.instantiate() as BallReturnSecret
	get_root().add_child(machine)
	await process_frame
	var production_model := machine.get_node_or_null("ProductionModel")
	_expect(production_model != null, "ball return instantiates its authored production model")
	if production_model != null:
		var meshes := production_model.find_children("*", "MeshInstance3D", true, false)
		_expect(meshes.size() >= 9, "ball return retains its authored mesh-part vocabulary")
		_expect(not production_model.find_children("*", "StaticBody3D", true, false).is_empty(), "ball return import retains physical collision")
		_expect(is_equal_approx((production_model as Node3D).position.y, -1.4), "ball return model sits on the authored level ground plane")
	var trigger := machine.get_node_or_null("ProjectileTrigger") as CollisionShape3D
	_expect(trigger != null and trigger.shape != null, "ball return has a dedicated projectile trigger")
	var activations := [0]
	machine.secret_requested.connect(func(_id: StringName, _title: String) -> void: activations[0] += 1)
	var ordinary_body := Node3D.new()
	machine._on_body_entered(ordinary_body)
	_expect(activations[0] == 0, "ordinary actors cannot bypass the projectile puzzle")
	var fetch_body := Node3D.new()
	fetch_body.add_to_group(&"fetch_projectiles")
	machine._on_body_entered(fetch_body)
	machine._on_body_entered(fetch_body)
	_expect(activations[0] == 1 and machine.activated, "fetch projectile activates the secret exactly once")
	ordinary_body.free()
	fetch_body.free()
	machine.queue_free()
	await process_frame


func _test_weapon_viewmodels() -> void:
	var minimum_parts := {&"pawstol": 16, &"barkshot": 20, &"fetch_launcher": 18}
	for asset_id: StringName in WEAPON_VIEWMODELS:
		var packed := WEAPON_VIEWMODELS[asset_id] as PackedScene
		_expect(packed != null, "%s viewmodel imports as a PackedScene" % asset_id)
		if packed == null:
			continue
		var instance := packed.instantiate()
		get_root().add_child(instance)
		await process_frame
		var meshes := instance.find_children("*", "MeshInstance3D", true, false)
		_expect(meshes.size() >= int(minimum_parts[asset_id]), "%s retains its authored mechanical, grip, and Cobie-paw silhouette" % asset_id)
		_expect(instance.find_children("*", "StaticBody3D", true, false).is_empty(), "%s remains a presentation-only first-person asset" % asset_id)
		instance.queue_free()
		await process_frame


func _test_opening_foundry_asset() -> void:
	var instance := OPENING_FOUNDRY_SCENE.instantiate()
	get_root().add_child(instance)
	await process_frame
	var meshes := instance.find_children("*", "MeshInstance3D", true, false)
	_expect(meshes.size() == 8, "opening foundry consolidates 188 authored parts into eight material batches")
	for mesh_node in meshes:
		var mesh_instance := mesh_node as MeshInstance3D
		_expect(mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() == 1, "each opening foundry material batch exports as exactly one draw surface")
	_expect(instance.find_children("*", "StaticBody3D", true, false).is_empty(), "opening foundry remains presentation-only and cannot replace gameplay collision")
	var source_parts := 0
	for child in instance.find_children("*", "", true, false):
		var extras := child.get_meta(&"extras", {}) as Dictionary
		source_parts += int(extras.get("source_part_count", 0))
	_expect(source_parts == 188, "opening foundry retains its complete source-part vocabulary in import metadata")
	instance.queue_free()
	await process_frame


func _test_production_pipeline_pilot() -> void:
	var minimum_mesh_parts: Dictionary = {
		&"field_kit": 8,
		&"tunnel_module": 7,
		&"lod_crate": 5,
		&"pickup_pedestal": 7,
		&"future_landmark": 6,
	}
	for asset_id: StringName in PILOT_MODELS:
		var packed := PILOT_MODELS[asset_id] as PackedScene
		_expect(packed != null, "%s imports as a PackedScene" % asset_id)
		if packed == null:
			continue
		var instance := packed.instantiate()
		get_root().add_child(instance)
		await process_frame
		var meshes := instance.find_children("*", "MeshInstance3D", true, false)
		var collision_bodies := instance.find_children("*", "StaticBody3D", true, false)
		_expect(meshes.size() >= int(minimum_mesh_parts[asset_id]), "%s retains its authored visual vocabulary" % asset_id)
		_expect(not collision_bodies.is_empty(), "%s retains an explicit collision proxy" % asset_id)
		instance.queue_free()
		await process_frame
	var lod_scene := (PILOT_MODELS[&"lod_crate"] as PackedScene).instantiate()
	_expect(lod_scene.find_child("LOD0_Crate", true, false) != null, "LOD pilot contains a detailed LOD0 mesh")
	_expect(lod_scene.find_child("LOD1_Crate", true, false) != null, "LOD pilot contains a simplified LOD1 mesh")
	_expect(lod_scene.find_child("LOD2_Crate", true, false) != null, "LOD pilot contains a minimal LOD2 mesh")
	lod_scene.free()
	for index in SENTRY_FRAMES.size():
		var texture := SENTRY_FRAMES[index]
		_expect(texture != null and texture.get_width() == 384 and texture.get_height() == 384, "directional sentry frame %d imports at the authored resolution" % index)
	var normal_image := SENTRY_FRAMES[0].get_image()
	var hit_image := SENTRY_FRAMES[4].get_image()
	_expect(normal_image.get_data() != hit_image.get_data(), "sentry hit reaction is visually distinct from its neutral front frame")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
