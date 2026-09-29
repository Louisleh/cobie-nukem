extends SceneTree

const Builder := preload("res://scripts/level/salmon_creek_world_builder.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Node3D.new()
	var builder := Builder.new()
	root.add_child(host)
	root.add_child(builder)
	builder.set("_build_parent", host)
	builder.call("_build_lighting")
	_expect(host.get_child_count() == 2, "lighting adds only the existing environment and directional key")
	var environment := host.get_child(0) as WorldEnvironment
	var key := host.get_child(1) as DirectionalLight3D
	_expect(environment != null and key != null, "existing light types preserved")
	if environment != null and key != null:
		var env := environment.environment
		_expect(env.background_mode == Environment.BG_SKY and env.sky != null, "authored storm sky retained")
		_expect(env.fog_enabled and env.fog_density >= 0.003 and env.fog_density <= 0.006, "restrained depth fog, not a near-field wash")
		_expect(env.fog_aerial_perspective <= 0.4, "aerial wash bounded")
		_expect(env.ambient_light_energy >= 0.4 and env.ambient_light_energy <= 0.5, "ambient remains readable without flattening key")
		_expect(key.light_energy >= 1.2 and key.light_energy <= 1.4, "directional value separation remains bounded")
		_expect(key.rotation_degrees.is_equal_approx(Vector3(-58, -25, 0)), "key direction unchanged")
		_expect(key.shadow_enabled, "existing shadows retained")
		_expect(key.light_color == Color("a9c5d6"), "cool storm key identity retained")
		_expect(env.sky.sky_material is ProceduralSkyMaterial, "no new sky asset")
	host.queue_free()
	builder.queue_free()
	for index in 4: await process_frame
	if failures.is_empty():
		print("SALMON CREEK OPENING LIGHTING TEST: PASS")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
