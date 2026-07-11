extends SceneTree

const FRAME_COUNT := 180
const MAX_AVERAGE_MSEC := 50.0
const MAX_SINGLE_FRAME_MSEC := 250.0

var samples: Array[float] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_path := _first_scene("res://scenes/levels")
	if scene_path.is_empty():
		scene_path = "res://scenes/boot/boot.tscn"
		print("PENDING: no level scene; measuring boot composition only")
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("PERFORMANCE: cannot load %s" % scene_path)
		quit(1)
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	for _index in FRAME_COUNT:
		var started := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
	var total := 0.0
	var maximum := 0.0
	for sample in samples:
		total += sample
		maximum = maxf(maximum, sample)
	var average := total / samples.size()
	print("PERFORMANCE SMOKE: scene=%s frames=%d average=%.3fms max=%.3fms" % [scene_path, FRAME_COUNT, average, maximum])
	print("NOTE: headless timing detects stalls only; it is not M4 Mac rendering evidence.")
	quit(0 if average <= MAX_AVERAGE_MSEC and maximum <= MAX_SINGLE_FRAME_MSEC else 1)

func _first_scene(path: String) -> String:
	var directory := DirAccess.open(path)
	if directory == null:
		return ""
	var entries := directory.get_files()
	entries.sort()
	for entry in entries:
		if entry.ends_with(".tscn"):
			return path.path_join(entry)
	return ""

