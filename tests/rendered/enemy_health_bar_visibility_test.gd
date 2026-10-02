extends SceneTree

## AUTOMATED_RENDER_REGRESSION: staged real enemy, disabled AI, fixed camera.
## Root must run through the isolated safe runner with --timeout 60.
## No ordinary-route, human, OS screen-capture, or physical-device evidence.
const GULL_SCENE := preload("res://scenes/enemies/compliance_gull.tscn")
const SIZE := Vector2i(640, 480)
const MAX_FRAMES := 8
const MAX_BYTES := 64 * 1024 * 1024
const MAX_USEC := 60_000_000
const SOURCES := ["project.godot", "scripts/ai/enemy_agent.gd", "scripts/ai/compliance_gull.gd",
	"scenes/enemies/compliance_gull.tscn", "resources/enemies/compliance_gull.tres",
	"tests/rendered/enemy_health_bar_visibility_test.gd"]
var output := ""
var started_usec := 0
var start_frame := 0
var bytes_written := 0
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var source: Dictionary = {}
var stage: Node3D
var camera: Camera3D
var gull: ComplianceGull
var wall: StaticBody3D
var finishing := false

func _initialize() -> void:
	started_usec = Time.get_ticks_usec()
	start_frame = Engine.get_process_frames()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		else: failures.append("unknown user argument: " + argument)
	call_deferred("_run")

func _process(_delta: float) -> bool:
	if not finishing and Time.get_ticks_usec() - started_usec > MAX_USEC:
		failures.append("60-second wall-clock limit")
		call_deferred("_finish")
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _source_identity() -> Dictionary:
	var hashes := {}
	for path: String in SOURCES:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var git_output: Array = []
	var git_status := OS.execute("git", PackedStringArray(["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"]), git_output, true)
	return {"head": String(git_output[0]).strip_edges() if git_status == 0 and not git_output.is_empty() else "UNAVAILABLE",
		"files": hashes}

func _run() -> void:
	if not failures.is_empty() or not output.begins_with("/") or DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		push_error("Health-bar regression requires a new absolute --output directory and no other user arguments")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("Health-bar regression cannot create output")
		quit(1)
		return
	source = _source_identity()
	_expect(source.head != "UNAVAILABLE", "source commit unavailable")
	_expect(RenderingServer.get_current_rendering_method() == "gl_compatibility", "native Compatibility renderer required")
	_expect(not DisplayServer.get_name() in ["headless", "web"], "native rendered display required")
	_expect(not OS.get_cmdline_args().has("--fixed-fps"), "fixed-fps evidence forbidden")
	_expect(OS.get_cmdline_args().find("--write-movie") == -1, "Movie Maker evidence forbidden")
	root.size = SIZE
	root.content_scale_size = SIZE
	stage = Node3D.new()
	stage.name = "AUTOMATED_RENDER_REGRESSION"
	root.add_child(stage)
	current_scene = stage
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("39434d")
	world.environment = environment
	stage.add_child(world)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.0
	camera.position = Vector3(0.0, 1.15, 8.0)
	stage.add_child(camera)
	camera.current = true
	gull = GULL_SCENE.instantiate() as ComplianceGull
	stage.add_child(gull)
	gull.set_physics_process(false)
	_expect(is_equal_approx(gull.health_fraction(), 1.0) and not gull.is_dead, "real gull begins alive at full scaled health")
	wall = StaticBody3D.new()
	wall.name = "OpaqueOcclusionBox"
	wall.position = Vector3(0.0, 1.15, 4.0)
	var wall_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.0, 3.0, 0.5)
	wall_mesh.mesh = box
	var wall_material := StandardMaterial3D.new()
	wall_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_material.albedo_color = Color("345072")
	wall_mesh.material_override = wall_material
	wall.add_child(wall_mesh)
	var shape_node := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box.size
	shape_node.shape = box_shape
	wall.add_child(shape_node)
	stage.add_child(wall)
	wall.visible = false
	for heading in [0.0, PI]:
		gull.rotation.y = heading
		gull.reset_physics_interpolation()
		gull._update_health_bar_presentation()
		var sample := await _capture("full_health_yaw_0" if heading == 0.0 else "full_health_yaw_pi")
		if sample.is_empty(): break
		_expect(int(sample.green_pixels) >= 8, "full-health fill visibly green at yaw %s" % heading)
		_expect(int(sample.red_pixels) == 0, "full-health bar has no red low-health fill at yaw %s" % heading)
	if samples.size() == 2:
		wall.visible = true
		var sample := await _capture("opaque_wall_occlusion_yaw_pi")
		if not sample.is_empty():
			_expect(int(sample.green_pixels) == 0 and int(sample.red_pixels) == 0, "actual opaque world box occludes health fill")
	if samples.size() == 3:
		wall.visible = false
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 40.0
		camera.position = Vector3(8.0, 2.8, 3.0)
		var bar := gull.get_node("EnemyHealthBar") as Node3D
		camera.look_at(bar.global_position, Vector3.UP)
		gull.rotation.y = PI * 0.5
		gull.reset_physics_interpolation()
		gull._update_health_bar_presentation()
		var sample := await _capture("full_health_side_perspective_yaw_half_pi")
		if not sample.is_empty():
			var fill := gull.get_node("EnemyHealthBar/Fill") as MeshInstance3D
			var background := gull.get_node("EnemyHealthBar/Background") as MeshInstance3D
			var camera_depth_offset := (fill.global_position - background.global_position).dot(camera.global_basis.z.normalized())
			var camera_alignment_dot := (fill.global_position - background.global_position).normalized().dot(camera.global_basis.z.normalized())
			sample["camera"] = {"projection": "perspective", "fov": camera.fov,
				"position": [camera.global_position.x, camera.global_position.y, camera.global_position.z],
				"rotation": [camera.global_rotation.x, camera.global_rotation.y, camera.global_rotation.z],
				"look_at": [bar.global_position.x, bar.global_position.y, bar.global_position.z]}
			sample["camera_depth_offset"] = camera_depth_offset
			sample["camera_alignment_dot"] = camera_alignment_dot
			_expect(int(sample.green_pixels) >= 8 and int(sample.red_pixels) == 0, "quarter-turn full-health fill stays green from pitched side perspective")
			_expect(camera_depth_offset > 0.0, "fill offset stays camera-facing under pitched side perspective")
			_expect(camera_alignment_dot > 0.999, "fill offset follows the pitched camera basis rather than an actor or world axis")
	_expect(samples.size() == 4, "all four native rendered cases retained")
	_expect(_source_identity() == source, "relevant source changed during capture")
	call_deferred("_finish")

func _capture(label: String) -> Dictionary:
	if samples.size() >= MAX_FRAMES or Time.get_ticks_usec() - started_usec > MAX_USEC:
		failures.append("capture frame/wall budget")
		return {}
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != SIZE:
		failures.append("native viewport readback size")
		return {}
	var center := camera.unproject_position(gull.get_node("EnemyHealthBar").global_position)
	var region := Rect2i(Vector2i(roundi(center.x) - 50, roundi(center.y) - 16), Vector2i(100, 32)).intersection(Rect2i(Vector2i.ZERO, SIZE))
	var green_pixels := 0
	var red_pixels := 0
	var black_pixels := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var color := image.get_pixel(x, y)
			if color.g > 0.4 and color.g > color.r * 1.3 and color.g > color.b * 1.3: green_pixels += 1
			if color.r > 0.5 and color.r > color.g * 1.4 and color.r > color.b * 1.4: red_pixels += 1
			if maxf(color.r, maxf(color.g, color.b)) < 0.18: black_pixels += 1
	var png := image.save_png_to_buffer()
	var path := output.path_join(label + ".png")
	if png.is_empty() or bytes_written + png.size() > MAX_BYTES - 65536 or FileAccess.file_exists(path):
		failures.append("PNG write budget/overwrite")
		return {}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("PNG open")
		return {}
	file.store_buffer(png)
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		failures.append("PNG write")
		return {}
	bytes_written += png.size()
	var fill := gull.get_node("EnemyHealthBar/Fill") as MeshInstance3D
	var background := gull.get_node("EnemyHealthBar/Background") as MeshInstance3D
	var material := fill.material_override as StandardMaterial3D
	var sample := {"file": label + ".png", "png_sha256": FileAccess.get_sha256(path), "png_bytes": png.size(),
		"green_pixels": green_pixels, "red_pixels": red_pixels, "black_pixels": black_pixels,
		"roi": [region.position.x, region.position.y, region.size.x, region.size.y],
		"yaw": gull.rotation.y, "health": gull.health, "health_fraction": gull.health_fraction(),
		"fill_size": [(fill.mesh as QuadMesh).size.x, (fill.mesh as QuadMesh).size.y],
		"fill_world_position": [fill.global_position.x, fill.global_position.y, fill.global_position.z],
		"background_world_position": [background.global_position.x, background.global_position.y, background.global_position.z],
		"billboard_mode": material.billboard_mode, "no_depth_test": material.no_depth_test,
		"transparency": material.transparency, "render_priority": material.render_priority,
		"world_box_visible": wall.visible, "elapsed_usec": Time.get_ticks_usec() - started_usec,
		"process_frame": Engine.get_process_frames()}
	samples.append(sample)
	return sample

func _finish() -> void:
	if finishing: return
	finishing = true
	var receipt := {"kind": "AUTOMATED_RENDER_REGRESSION", "status": "PASS" if failures.is_empty() else "FAIL",
		"source": source, "engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(),
		"viewport": [SIZE.x, SIZE.y], "ai_physics_disabled": true, "ordinary_route": false, "human_acceptance": false,
		"camera": {"position": [0.0, 1.15, 8.0], "projection": "orthogonal", "size": 3.0},
		"limits": {"capture_frames": MAX_FRAMES, "bytes": MAX_BYTES, "wall_seconds": 60},
		"wall_usec": Time.get_ticks_usec() - started_usec, "process_frame_delta": Engine.get_process_frames() - start_frame,
		"user_data_dir": OS.get_user_data_dir(), "save_directory": root.get_node("SaveManager").call("_save_directory_absolute"),
		"samples": samples, "failures": failures}
	var receipt_path := output.path_join("receipt.json")
	if not FileAccess.file_exists(receipt_path):
		var file := FileAccess.open(receipt_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(receipt, "\t"))
			var write_error := file.get_error()
			file.close()
			if write_error != OK: failures.append("receipt write")
		else: failures.append("receipt open")
	else: failures.append("receipt overwrite refused")
	current_scene = null
	if is_instance_valid(stage): stage.queue_free()
	gull = null
	camera = null
	wall = null
	stage = null
	for index in 2: await process_frame
	if failures.is_empty(): print("ENEMY HEALTH BAR VISIBILITY TEST: PASS")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
