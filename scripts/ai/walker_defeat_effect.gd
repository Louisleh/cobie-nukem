extends RefCounted

## Bounded, deterministic Walker finale spectacle. The complete effect is one
## quality-budget entry and owns its lights, fragments, shockwaves, and cleanup.

const FRAGMENT_COUNT := 28
const EFFECT_LIFETIME := 1.65


static func spawn(walker: Node3D) -> Node3D:
	if walker == null or not is_instance_valid(walker) or walker.get_tree() == null:
		return null
	var parent := walker.get_tree().current_scene
	if parent == null:
		parent = walker.get_tree().root
	var effect := Node3D.new()
	effect.name = "WalkerDefeatExplosion"
	effect.add_to_group(&"temporary_combat_effects")
	parent.add_child(effect)
	effect.global_position = walker.get_auto_aim_position()
	var quality := walker.get_node_or_null("/root/QualityManager")
	if quality != null:
		quality.claim_temporary_effect(effect)
	var reduced_flashes := _reduced_flashes(walker)
	_build_core(effect, reduced_flashes)
	_build_shockwaves(effect, reduced_flashes)
	_build_fragments(effect)
	var cleanup := Timer.new()
	cleanup.name = "WalkerExplosionCleanup"
	cleanup.one_shot = true
	cleanup.wait_time = EFFECT_LIFETIME
	cleanup.timeout.connect(effect.queue_free)
	effect.add_child(cleanup)
	cleanup.start()
	return effect


static func _build_core(effect: Node3D, reduced_flashes: bool) -> void:
	var core := MeshInstance3D.new()
	core.name = "CoreBurst"
	var sphere := SphereMesh.new()
	sphere.radius = 0.7
	sphere.height = 1.4
	core.mesh = sphere
	core.material_override = _emissive_material(Color("fff1a8"), 3.2 if reduced_flashes else 7.5, 0.92)
	effect.add_child(core)
	var core_tween := core.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	core_tween.tween_property(core, "scale", Vector3.ONE * (2.6 if reduced_flashes else 4.4), 0.18)
	core_tween.set_ease(Tween.EASE_IN)
	core_tween.tween_property(core, "scale", Vector3.ZERO, 0.38)
	if not reduced_flashes:
		var light := OmniLight3D.new()
		light.name = "ExplosionKeyLight"
		light.light_color = Color("ff8a2d")
		light.light_energy = 8.0
		light.omni_range = 13.0
		light.shadow_enabled = false
		effect.add_child(light)
		var light_tween := light.create_tween()
		light_tween.tween_property(light, "light_energy", 0.0, 0.62)


static func _build_shockwaves(effect: Node3D, reduced_flashes: bool) -> void:
	var ring_count := 1 if reduced_flashes else 3
	for index in ring_count:
		var ring := MeshInstance3D.new()
		ring.name = "Shockwave%02d" % index
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 1.0
		cylinder.bottom_radius = 1.0
		cylinder.height = 0.035
		cylinder.radial_segments = 32
		ring.mesh = cylinder
		ring.material_override = _emissive_material(Color("ff9f35"), 3.0, 0.62)
		ring.position.y = -2.5
		ring.scale = Vector3.ZERO
		effect.add_child(ring)
		var tween := ring.create_tween()
		tween.tween_interval(0.10 + index * 0.14)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "scale", Vector3(7.0 + index * 2.2, 1.0, 7.0 + index * 2.2), 0.46)
		tween.parallel().tween_property(ring, "transparency", 1.0, 0.46)


static func _build_fragments(effect: Node3D) -> void:
	for index in FRAGMENT_COUNT:
		var fragment := MeshInstance3D.new()
		fragment.name = "Fragment%02d" % index
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mesh := BoxMesh.new()
		var size := 0.10 + float(index % 5) * 0.025
		mesh.size = Vector3(size, size * 0.72, size * 1.25)
		fragment.mesh = mesh
		var color := Color("ffcb4c") if index % 3 == 0 else Color("e74d2f") if index % 3 == 1 else Color("5fe7e7")
		fragment.material_override = _emissive_material(color, 3.2, 1.0)
		effect.add_child(fragment)
		var angle := TAU * float(index) / float(FRAGMENT_COUNT)
		var ring := 2.4 + float(index % 4) * 0.8
		var direction := Vector3(cos(angle) * ring, 1.2 + float(index % 7) * 0.42, sin(angle) * ring)
		var duration := 0.72 + float(index % 5) * 0.07
		var tween := fragment.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(fragment, "position", direction, duration)
		tween.tween_property(fragment, "rotation", Vector3(angle * 1.7, angle * 2.3, angle), duration)
		tween.tween_property(fragment, "scale", Vector3.ZERO, duration)


static func _emissive_material(color: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


static func _reduced_flashes(owner: Node) -> bool:
	var settings := owner.get_node_or_null("/root/SettingsManager")
	return settings != null and bool(settings.get_value(&"video", &"reduced_flashes", false))
