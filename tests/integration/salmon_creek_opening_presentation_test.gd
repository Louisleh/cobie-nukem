extends SceneTree

const WORLD_BUILDER_PATH := "res://scripts/level/salmon_creek_world_builder.gd"
const ENVIRONMENT_KIT_PATH := "res://scripts/level/salmon_creek_environment_kit.gd"

const OPENING_SIGN_TEXT := "NO ANIMALS\nON SPORTS FIELD"
const OPENING_SIGN_SECRET_ID := &"optional_sign"
const OPENING_SIGN_SECRET_TITLE := "SIGN SEEMS OPTIONAL"
const OPENING_SIGN_POSITION := Vector3(-4.0, 1.4, 5.5)
const OPENING_SIGN_SCALE := Vector3(0.95, 0.95, 1.0)
const SHED_LABEL_TEXT := "EQUIPMENT SHED\nAUTHORIZED GOOD DOGS ONLY"
const SHED_LABEL_POSITION := Vector3(-2.0, 3.15, -34.8)
const SHED_LIGHT_NAME := "ShedWorkLight"
const SHED_LIGHT_POSITION := Vector3(-2.0, 3.5, -33.8)
const SHED_LIGHT_COLOR := Color("ffdc97")
const SHED_LIGHT_ENERGY := 2.8
const SHED_LIGHT_RANGE := 12.0

var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await _test_opening_sign_contracts()
	await _test_shed_landmark_contracts()
	await _await_cleanup_frames(2)
	if failures.is_empty():
		print("SALMON CREEK OPENING PRESENTATION TEST: PASS")
		call_deferred("_quit_after_cleanup", 0)
	else:
		for failure in failures:
			push_error("OPENING PRESENTATION: " + failure)
		call_deferred("_quit_after_cleanup", 1)


func _quit_after_cleanup(exit_code: int) -> void:
	# allow deferred frees and cleanup monitors to settle before exit.
	for _i in 6:
		await process_frame
	quit(exit_code)


func _test_opening_sign_contracts() -> void:
	var interactables_parent := Node3D.new()
	var builder_script := load(WORLD_BUILDER_PATH) as Script
	if builder_script == null:
		_expect(false, "world builder script loads")
		return
	var builder := builder_script.new() as Node
	root.add_child(builder)
	root.add_child(interactables_parent)
	builder.set("interactables", interactables_parent)
	builder.call("_build_story_objects")
	await process_frame

	var opening_signs: Array[NarrativeSign] = []
	for child in interactables_parent.get_children():
		var sign := child as NarrativeSign
		if sign != null and sign.sign_id == &"no_animals":
			opening_signs.append(sign)

	_expect(opening_signs.size() == 1, "exactly one NarrativeSign has sign_id no_animals")
	if opening_signs.size() == 1:
		var sign := opening_signs[0]
		_expect(sign.sign_text == OPENING_SIGN_TEXT, "no_animals sign text is preserved")
		_expect(sign.secret_after_reads == 3, "no_animals sign preserves secret_after_reads")
		_expect(sign.secret_id == OPENING_SIGN_SECRET_ID, "no_animals sign preserves secret_id")
		_expect(sign.secret_title == OPENING_SIGN_SECRET_TITLE, "no_animals sign preserves secret_title")
		_expect(sign.position.is_equal_approx(OPENING_SIGN_POSITION), "no_animals sign position is preserved")
		_expect(sign.scale.is_equal_approx(OPENING_SIGN_SCALE), "no_animals sign scale is preserved")
		_expect(sign.position.x < 0.0, "no_animals sign remains left of route")

	for child in interactables_parent.get_children():
		var sign := child as NarrativeSign
		if sign != null:
			if sign.read.is_connected(Callable(builder, "_on_sign_read")):
				sign.read.disconnect(Callable(builder, "_on_sign_read"))
			if sign.secret_requested.is_connected(Callable(builder, "_on_secret_discovered")):
				sign.secret_requested.disconnect(Callable(builder, "_on_secret_discovered"))

	builder.queue_free()
	interactables_parent.queue_free()
	await _await_cleanup_frames(2)


func _test_shed_landmark_contracts() -> void:
	var kit_parent := Node3D.new()
	var kit_script := load(ENVIRONMENT_KIT_PATH) as Script
	if kit_script == null:
		_expect(false, "environment kit script loads")
		return
	var shed_kit := kit_script.new() as Node3D
	kit_parent.add_child(shed_kit)
	root.add_child(kit_parent)
	shed_kit.call("_build_shed_landmarks")
	await process_frame

	_expect(shed_kit.get_child_count() == 21, "shed landmark-only construction has 21 direct children")

	var matching_labels: Array[Label3D] = []
	var matching_lights: Array[OmniLight3D] = []
	for child in shed_kit.get_children():
		if child is Label3D and (child as Label3D).text == SHED_LABEL_TEXT:
			matching_labels.append(child)
		if child is OmniLight3D and child.name == SHED_LIGHT_NAME:
			matching_lights.append(child)

	_expect(matching_labels.size() == 1, "exactly one shed label exists for equipment shed authorization")
	if matching_labels.size() == 1:
		var label := matching_labels[0]
		_expect(label.text == SHED_LABEL_TEXT, "shed label text is unchanged")
		_expect(label.position.is_equal_approx(SHED_LABEL_POSITION), "shed label position is unchanged")
		_expect(is_equal_approx(label.font_size, 44.0), "shed label font size is unchanged")
		_expect(is_equal_approx(label.pixel_size, 0.0028), "shed label pixel size is unchanged")

	_expect(matching_lights.size() == 1, "exactly one ShedWorkLight exists")
	if matching_lights.size() == 1:
		var light := matching_lights[0]
		_expect(light.position.is_equal_approx(SHED_LIGHT_POSITION), "shed work light position is unchanged")
		_expect(light.light_color == SHED_LIGHT_COLOR, "shed work light color is unchanged")
		_expect(is_equal_approx(light.light_energy, SHED_LIGHT_ENERGY), "shed work light energy is unchanged")
		_expect(is_equal_approx(light.omni_range, SHED_LIGHT_RANGE), "shed work light range is unchanged")

	kit_parent.queue_free()
	await _await_cleanup_frames(2)


func _await_cleanup_frames(frames: int) -> void:
	for _i in frames:
		await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
