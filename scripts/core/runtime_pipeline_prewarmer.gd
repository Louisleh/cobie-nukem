class_name RuntimePipelinePrewarmer
extends Node

signal completed

const MAX_SCENES := 16
const MAX_VISUALS := 192
const VISUALS_PER_STAGE := 16

var succeeded := false
var rendered_boundaries := 0
var functional_boundaries := 0
var prepared_visuals := 0
# GLES3 queues newly configured skies until its next render update. Keep only
# our retired resources alive through that boundary, independently of a Node
# which may leave the tree. Admission below caps this shared retirement queue.
static var _retired_skies: Array[Sky] = []
static var _active_sky_count := 0
var _sky: Sky
var _viewport: SubViewport
var _light: OmniLight3D
var _sample_root: Node3D
var _paths := PackedStringArray()
var _samples: Array[GeometryInstance3D] = []
var _active: Array[GeometryInstance3D] = []
var _stage_frames := 0
var _stage_variant := 0
var _dynamic_prepared := false
var _running := false
var _failure := false
var _exiting := false


func warm(scene_paths: PackedStringArray) -> void:
	_cancel()
	succeeded = false
	rendered_boundaries = 0
	functional_boundaries = 0
	prepared_visuals = 0
	_failure = scene_paths.size() > MAX_SCENES or _active_sky_count + _retired_skies.size() >= MAX_SCENES
	if _failure:
		completed.emit()
		return
	_paths = scene_paths.duplicate()
	_viewport = SubViewport.new()
	_viewport.name = "PipelineWarmupViewport"
	_viewport.size = Vector2i(64, 64)
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var camera := Camera3D.new()
	camera.current = true
	_viewport.add_child(camera)
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = Environment.new()
	atmosphere.environment.fog_enabled = true
	atmosphere.environment.fog_density = 0.009
	# Match both first missions' sky ambient shader state, not a color-only fill.
	atmosphere.environment.background_mode = Environment.BG_SKY
	_sky = Sky.new()
	_active_sky_count += 1
	atmosphere.environment.sky = _sky
	atmosphere.environment.sky.sky_material = ProceduralSkyMaterial.new()
	atmosphere.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	atmosphere.environment.ambient_light_energy = 0.32
	_viewport.add_child(atmosphere)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key.shadow_enabled = true
	_viewport.add_child(key)
	_light = OmniLight3D.new()
	_light.position = Vector3(0.0, 0.3, -1.0)
	_light.omni_range = 4.0
	_light.visible = false
	_viewport.add_child(_light)
	_sample_root = Node3D.new()
	_viewport.add_child(_sample_root)
	_running = true
	if not RenderingServer.frame_post_draw.is_connected(_on_frame_post_draw):
		RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
	set_process(true)
	# Submit the first small sample immediately; existing callers can inspect its
	# real render state before awaiting completion. Further resources are staged.
	if not _paths.is_empty():
		_prepare_scene(_paths[0])
		_paths.remove_at(0)
		if not _samples.is_empty():
			_begin_stage()


func _process(_delta: float) -> void:
	if not _running:
		return
	# A headless gate verifies lifecycle only. It never reports real render work.
	if DisplayServer.get_name() == "headless" and not _active.is_empty():
		functional_boundaries += 1
		_stage_frames += 1
	if not _active.is_empty():
		if _stage_frames < 1:
			return
		if _stage_variant < 3:
			_stage_variant += 1
			_apply_stage_variant()
			_stage_frames = 0
			return
		_free_active()
	if not _samples.is_empty():
		_begin_stage()
		return
	if not _paths.is_empty():
		_prepare_scene(_paths[0])
		_paths.remove_at(0)
		return
	if not _dynamic_prepared:
		_dynamic_prepared = true
		_prepare_dynamic_samples()
		return
	var success := not _failure and prepared_visuals > 0
	_cancel()
	succeeded = success
	completed.emit()


func _on_frame_post_draw() -> void:
	if _running and not _active.is_empty() and DisplayServer.get_name() != "headless":
		rendered_boundaries += 1
		_stage_frames += 1


func _prepare_scene(path: String) -> void:
	var packed := load(path) as PackedScene if ResourceLoader.exists(path, "PackedScene") else null
	if packed == null:
		_failure = true
		return
	# Inspect serialized resources instead of constructing gameplay/native particle
	# actors. CPUParticles3D even consumes global RNG in its constructor.
	_collect_scene_state(packed.get_state(), path)


func _collect_scene_state(state: SceneState, path: String, depth := 0) -> void:
	if depth > 8:
		_failure = true
		return
	var sprite_profiles: Dictionary = {}
	for index in state.get_node_count():
		var properties := _scene_properties(state, index)
		var script := properties.get(&"script") as Script
		if script == null or not script.resource_path.ends_with("/enemy_sprite_presentation.gd"):
			continue
		var component_path := String(state.get_node_path(index))
		var sprite_path := String(properties.get(&"sprite_path", NodePath("../Visual/DetailedSprite")))
		var resolved := (component_path + "/" + sprite_path).simplify_path()
		sprite_profiles[resolved] = properties
	for index in state.get_node_count():
		var nested := state.get_node_instance(index)
		if nested != null:
			_collect_scene_state(nested.get_state(), path, depth + 1)
		var sample: GeometryInstance3D
		match state.get_node_type(index):
			&"MeshInstance3D": sample = MeshInstance3D.new()
			&"Sprite3D": sample = Sprite3D.new()
			&"Label3D": sample = Label3D.new()
			_: continue
		var properties := _scene_properties(state, index)
		# Surface override properties exist only after the actual mesh is assigned.
		if sample is MeshInstance3D and properties.has(&"mesh"):
			(sample as MeshInstance3D).mesh = properties[&"mesh"] as Mesh
		var native_properties: Dictionary = {}
		for property in sample.get_property_list():
			native_properties[property.name] = true
		for property in properties:
			if property != &"script" and native_properties.has(property):
				sample.set(property, properties[property])
		sample.name = state.get_node_name(index)
		sample.set_meta(&"preparation_source", path)
		sample.visible = true
		if sample is MeshInstance3D:
			_apply_production_materials(sample as MeshInstance3D)
		if sample is Sprite3D:
			var node_path := String(state.get_node_path(index)).simplify_path()
			_apply_sprite_profile(sprite_profiles.get(node_path, {}), sample as Sprite3D)
		_add_sample(sample)


func _scene_properties(state: SceneState, index: int) -> Dictionary:
	var properties: Dictionary = {}
	for property in state.get_node_property_count(index):
		properties[state.get_node_property_name(index, property)] = state.get_node_property_value(index, property)
	return properties


func _collect_visuals(source: Node, path: String) -> void:
	if source is MeshInstance3D:
		var sample := source.duplicate(0) as MeshInstance3D
		for child in sample.get_children():
			child.free()
		sample.set_meta(&"preparation_source", path)
		sample.visible = true
		_add_sample(sample)
	for child in source.get_children():
		_collect_visuals(child, path)


func _apply_production_materials(sample: MeshInstance3D) -> void:
	if sample.mesh == null:
		return
	for surface in sample.mesh.get_surface_count():
		var material := sample.get_surface_override_material(surface)
		if material == null:
			material = sample.mesh.surface_get_material(surface)
		if material == null:
			continue
		var replacement: Material = RainCityMaterialApplier.MATERIALS.get(material.resource_name)
		if replacement != null:
			sample.set_surface_override_material(surface, replacement)


func _apply_sprite_profile(properties: Dictionary, sample: Sprite3D) -> void:
	var profile := properties.get(&"presentation_profile") as EnemyPresentationProfile
	var atlas := properties.get(&"atlas_texture") as Texture2D
	if profile != null and profile.atlas_texture != null:
		sample.texture = profile.atlas_texture
		sample.hframes = EnemyPresentationProfile.HORIZONTAL_FRAMES
		sample.vframes = EnemyPresentationProfile.VERTICAL_FRAMES
	elif atlas != null:
		sample.texture = atlas
		sample.hframes = 4
		sample.vframes = 2


func _prepare_dynamic_samples() -> void:
	var effects := ImpactEffectPool.new()
	for source in effects.create_pipeline_samples():
		_collect_visuals(source, "impact_effect_pool")
		source.free()
	for color in [Color("101416"), Color("65d36e")]:
		var bar := MeshInstance3D.new()
		bar.mesh = QuadMesh.new()
		bar.material_override = EnemyAgent.create_health_bar_material(color)
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar.set_meta(&"preparation_source", "enemy_health_bar")
		_add_sample(bar)
	var label := EnemyAgent.create_health_points_label()
	label.text = "100"
	label.visible = true
	label.set_meta(&"preparation_source", "enemy_health_points")
	_add_sample(label)


func _add_sample(sample: GeometryInstance3D) -> void:
	if prepared_visuals >= MAX_VISUALS:
		_failure = true
		sample.free()
		return
	prepared_visuals += 1
	_samples.append(sample)


func _begin_stage() -> void:
	_stage_frames = 0
	_stage_variant = 0
	var count := mini(VISUALS_PER_STAGE, _samples.size())
	for _index in count:
		var sample := _samples.pop_front() as GeometryInstance3D
		_sample_root.add_child(sample)
		_active.append(sample)
	_apply_stage_variant()


func _apply_stage_variant() -> void:
	# Opposite diagonal views reveal both sides of authored thin planes. Each
	# orientation is drawn once with and once without the bounded point light.
	_light.visible = _stage_variant >= 2
	for index in _active.size():
		var sample := _active[index]
		sample.scale = Vector3.ONE
		if sample is MeshInstance3D:
			sample.rotation = Vector3(-PI / 6.0, PI / 4.0, 0.0) if _stage_variant % 2 == 0 else Vector3(PI / 6.0, PI * 1.25, 0.0)
		else:
			# Sprite/label billboard flags remain authoritative for camera facing.
			sample.rotation = Vector3.ZERO
		var bounds := sample.get_aabb()
		var oriented_bounds: AABB = Transform3D(sample.basis, Vector3.ZERO) * bounds
		var longest := maxf(oriented_bounds.size.x, maxf(oriented_bounds.size.y, oriented_bounds.size.z))
		var fit := 0.32 / maxf(longest, 0.001)
		sample.scale = Vector3.ONE * fit
		var slot := Vector3((float(index % 4) - 1.5) * 0.45, (1.5 - float(floori(float(index) / 4.0))) * 0.45, -2.0)
		sample.position = slot - sample.basis * bounds.get_center()


func _free_active() -> void:
	for sample in _active:
		if is_instance_valid(sample):
			sample.free()
	_active.clear()


static func _release_skies() -> void:
	_retired_skies.clear()


func _cancel() -> void:
	if _sky != null:
		_active_sky_count -= 1
		if DisplayServer.get_name() != "headless":
			_retired_skies.append(_sky)
			if not RenderingServer.frame_post_draw.is_connected(_release_skies):
				RenderingServer.frame_post_draw.connect(_release_skies, CONNECT_ONE_SHOT)
	_sky = null
	_running = false
	set_process(false)
	if RenderingServer.frame_post_draw.is_connected(_on_frame_post_draw):
		RenderingServer.frame_post_draw.disconnect(_on_frame_post_draw)
	if _exiting:
		_active.clear() # The viewport owns these live nodes during tree teardown.
	else:
		_free_active()
	for sample in _samples:
		if is_instance_valid(sample):
			sample.free()
	_samples.clear()
	_paths.clear()
	_dynamic_prepared = false
	if is_instance_valid(_viewport):
		if _exiting:
			_viewport.queue_free()
		else:
			_viewport.free()
	_viewport = null
	_sample_root = null
	_light = null


func _exit_tree() -> void:
	_exiting = true
	_cancel()
