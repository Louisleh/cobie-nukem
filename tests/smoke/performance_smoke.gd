extends SceneTree

const WARMUP_FRAMES := 30
const FRAME_COUNT := 300
const MAX_AVERAGE_MSEC := 50.0
const MAX_P95_MSEC := 50.0
const MAX_P99_MSEC := 100.0
const MAX_SINGLE_FRAME_MSEC := 250.0
const MAX_OBJECT_DRIFT := 8

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
	for _index in WARMUP_FRAMES:
		await process_frame
	var initial_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var initial_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var initial_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
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
	var ordered := samples.duplicate()
	ordered.sort()
	var p50 := _percentile(ordered, 0.50)
	var p95 := _percentile(ordered, 0.95)
	var p99 := _percentile(ordered, 0.99)
	var final_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var final_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var final_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var object_drift := final_objects - initial_objects
	var node_drift := final_nodes - initial_nodes
	print("PERFORMANCE SMOKE: scene=%s warmup=%d frames=%d average=%.3fms p50=%.3fms p95=%.3fms p99=%.3fms max=%.3fms" % [scene_path, WARMUP_FRAMES, FRAME_COUNT, average, p50, p95, p99, maximum])
	print("PERFORMANCE MONITORS: objects=%d->%d drift=%+d nodes=%d->%d drift=%+d memory=%d->%d draw_calls=%d" % [initial_objects, final_objects, object_drift, initial_nodes, final_nodes, node_drift, initial_memory, final_memory, draw_calls])
	var display_name := DisplayServer.get_name()
	if display_name == "headless":
		print("NOTE: headless timing detects stalls only; it is not rendered GPU evidence.")
	else:
		print("RENDERED PERFORMANCE: display=%s renderer=%s" % [display_name, RenderingServer.get_rendering_device() if RenderingServer.get_rendering_device() != null else "Compatibility/OpenGL"])
	var timing_ok := average <= MAX_AVERAGE_MSEC and p95 <= MAX_P95_MSEC and p99 <= MAX_P99_MSEC and maximum <= MAX_SINGLE_FRAME_MSEC
	var lifetime_ok := object_drift <= MAX_OBJECT_DRIFT and node_drift <= MAX_OBJECT_DRIFT
	instance.free()
	instance = null
	packed = null
	await process_frame
	quit(0 if timing_ok and lifetime_ok else 1)


func _percentile(ordered: Array[float], fraction: float) -> float:
	if ordered.is_empty():
		return 0.0
	var index := clampi(ceili(fraction * ordered.size()) - 1, 0, ordered.size() - 1)
	return ordered[index]

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
