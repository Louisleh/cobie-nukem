extends SceneTree

const MANIFEST_PATH := "res://tools/visual_quality/capture_manifest.json"
const CAPTURE_SCRIPT_PATH := "res://tools/visual_quality/capture.sh"
const VISUAL_DIRECT_CAPTURE_SCRIPT := preload("res://scripts/debug/visual_direct_capture.gd")

const CANONICAL_VIEWS := [
	"title",
	"mission_select",
	"doghouse_hub",
	"salmon_opening",
	"salmon_sports_field",
	"salmon_shed",
	"salmon_lab",
	"salmon_tunnel",
	"salmon_walker_arena",
	"salmon_walker_defeat",
	"rain_city_downtown",
	"rain_city_slice",
	"rain_city_terminal",
	"rain_city_harbour",
	"vancouver_waterfront",
	"mount_hood_foundry",
	"moon_landing_pad",
	"ventura_service_lane",
	"rain_city_towmaster",
	"touch_hud_4_3",
]
const CANONICAL_COUNT := 20
const RAIN_CITY_ROUTE_VIEWS := {
	"rain_city_downtown": {"staging_id": "rain_city_downtown", "seed": 2026072210},
	"rain_city_slice": {"staging_id": "rain_city_slice", "seed": 2026072211},
	"vancouver_waterfront": {"staging_id": "waterfront_seawall", "seed": 2026071613},
	"rain_city_terminal": {"staging_id": "rain_city_terminal", "seed": 2026072212},
	"rain_city_harbour": {"staging_id": "rain_city_harbour", "seed": 2026072213},
}

class CaptureTarget:
	extends Node3D
	var player: Node3D

var failures: Array[String] = []
var safe_filename_pattern: RegEx = RegEx.new()


func _initialize() -> void:
	safe_filename_pattern.compile("^[a-z0-9_]+_[0-9]+x[0-9]+\\.png$")
	_validate_manifest_json()
	_validate_route_actor_cleanup()
	if failures.is_empty():
		print("VISUAL CAPTURE MANIFEST TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _validate_manifest_json() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		failures.append("Could not open manifest: " + MANIFEST_PATH)
		return
	var payload := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Manifest is not a JSON object")
		return

	var manifest: Dictionary = parsed
	_validate_schema(manifest)
	_validate_support_states(manifest)
	_validate_aspects(manifest)
	_validate_views(manifest)
	_validate_capture_script_policy()


func _validate_schema(manifest: Dictionary) -> void:
	if int(manifest.get("schema_version", 0)) != 1:
		failures.append("schema_version must be 1")


func _validate_support_states(manifest: Dictionary) -> void:
	var support_states: Variant = manifest.get("support_states", [])
	if typeof(support_states) != TYPE_ARRAY or support_states.is_empty():
		failures.append("support_states must be a non-empty array")
		return
	var allowed := {}
	for state in support_states:
		allowed[String(state)] = true
	if not bool(allowed.get("supported", false)):
		failures.append("support_states must include 'supported'")
	if not bool(allowed.get("unsupported", false)):
		failures.append("support_states must include 'unsupported'")


func _validate_aspects(manifest: Dictionary) -> void:
	var aspects: Variant = manifest.get("aspects", [])
	if typeof(aspects) != TYPE_ARRAY:
		failures.append("aspects must be an array")
		return
	if aspects.size() != 4:
		failures.append("Manifest must declare exactly four aspect families")
	var expected_sizes := {
		"1280x720": true,
		"1680x1050": true,
		"1024x768": true,
		"3440x1440": true,
	}
	var seen := {}
	for index in aspects.size():
		var entry: Dictionary = aspects[index]
		var aspect_id := String(entry.get("id", ""))
		var width := int(entry.get("width", 0))
		var height := int(entry.get("height", 0))
		if not expected_sizes.has(aspect_id):
			failures.append("Unexpected aspect id: %s" % aspect_id)
		elif seen.has(aspect_id):
			failures.append("Duplicate aspect id: %s" % aspect_id)
		elif width == 0 or height == 0:
			failures.append("Invalid aspect dimensions for %s: %sx%s" % [aspect_id, width, height])
		else:
			seen[aspect_id] = true
			var dims := aspect_id.split("x")
			if dims.size() != 2 or width != int(dims[0]) or height != int(dims[1]):
				failures.append("Aspect dimensions do not match id %s" % aspect_id)
	for size_id in expected_sizes.keys():
		if not seen.has(size_id):
			failures.append("Missing aspect family: %s" % size_id)


func _validate_views(manifest: Dictionary) -> void:
	var views: Variant = manifest.get("views", [])
	if typeof(views) != TYPE_ARRAY:
		failures.append("views must be an array")
		return
	if views.size() != CANONICAL_COUNT:
		failures.append("views must contain exactly %d canonical entries" % CANONICAL_COUNT)
	var ids: Dictionary = {}
	var native_route_seed := 0
	var expected_ids := {}
	for expected_id in CANONICAL_VIEWS:
		expected_ids[expected_id] = true
	for item in views:
		if typeof(item) != TYPE_DICTIONARY:
			failures.append("Each view must be a dictionary")
			continue
		var view: Dictionary = item
		var view_id := String(view.get("id", ""))
		var scene_path := String(view.get("scene_path", ""))
		var staging_id := String(view.get("staging_id", ""))
		var support := String(view.get("capture_support", ""))
		var adapter := String(view.get("adapter", ""))
		var filenames: Variant = view.get("filenames", {})
		var capture: Variant = view.get("capture", null)
		var frame: Variant = view.get("frame")
		var seed: Variant = view.get("seed")
		var safe_support_states: Variant = manifest.get("support_states", [])

		if view_id.is_empty():
			failures.append("View has missing id")
			continue
		if ids.has(view_id):
			failures.append("Duplicate view id: %s" % view_id)
		else:
			ids[view_id] = true
		if scene_path.begins_with("res://") == false:
			failures.append("Scene path must be res:// for view %s" % view_id)
		if staging_id.is_empty() or not staging_id.is_valid_filename():
			failures.append("staging_id must be filename-safe for view %s" % view_id)
		if view_id == "rain_city_towmaster":
			if scene_path != "res://scenes/levels/episode_1_vancouver_waterfront.tscn":
				failures.append("rain_city_towmaster must use the production Rain City scene")
			if staging_id != "rain_city_towmaster" or adapter != "direct_scene_capture":
				failures.append("rain_city_towmaster must use its direct staging adapter")
			if int(seed) != 2026072107 or int(frame) != 80:
				failures.append("rain_city_towmaster seed/frame contract drifted")
		if RAIN_CITY_ROUTE_VIEWS.has(view_id):
			var route_contract: Dictionary = RAIN_CITY_ROUTE_VIEWS[view_id]
			if scene_path != "res://scenes/levels/episode_1_vancouver_waterfront.tscn":
				failures.append("%s must use the production Rain City scene" % view_id)
			if staging_id != String(route_contract["staging_id"]) or adapter != "direct_scene_capture":
				failures.append("%s must use its direct route staging adapter" % view_id)
			if int(seed) != int(route_contract["seed"]) or int(frame) != 80:
				failures.append("%s seed/frame contract drifted" % view_id)
			if not bool(view.get("require_camera_pose_receipt", false)):
				failures.append("%s must require a render-time camera pose receipt" % view_id)
			if String(view.get("distinctness_group", "")) != "rain_city_non_boss_routes" or not is_equal_approx(float(view.get("distinctness_edge_iou_max", 0.0)), 0.80) or not is_equal_approx(float(view.get("distinctness_min_edge_fraction", 0.0)), 0.002) or not is_equal_approx(float(view.get("distinctness_low_frequency_mae_min", 0.0)), 0.055):
				failures.append("%s must use the Rain City route distinctness guard" % view_id)
			if not VISUAL_DIRECT_CAPTURE_SCRIPT.supports_rain_city_route_stage(staging_id):
				failures.append("%s staging id is missing from visual_direct_capture.gd" % view_id)
			else:
				_validate_route_pose_contract(view_id, staging_id, view.get("expected_camera_pose"))
		if not (support == "supported" or support == "unsupported"):
			failures.append("Invalid capture_support for view %s: %s" % [view_id, support])
		elif safe_support_states.has(support) == false:
			failures.append("capture_support %s for %s not in manifest support_states" % [support, view_id])
		elif support == "supported":
			if not (typeof(capture) == TYPE_DICTIONARY):
				failures.append("supported view %s must include capture object" % view_id)
			elif adapter in ["native_vertical_slice_capture", "native_vertical_slice_touch_capture"] and String(capture.get("source_file", "")).is_empty():
				failures.append("native view %s must include capture.source_file" % view_id)
			elif adapter == "direct_scene_capture" and int(capture.get("quit_after", 0)) <= int(frame):
				failures.append("direct view %s must quit after its selected frame" % view_id)
			elif adapter not in ["native_vertical_slice_capture", "native_vertical_slice_touch_capture", "direct_scene_capture"]:
				failures.append("supported view %s uses unknown adapter %s" % [view_id, adapter])
			if typeof(frame) not in [TYPE_INT, TYPE_FLOAT] or int(frame) <= 0:
				failures.append("supported view %s must include positive frame" % view_id)
			if typeof(seed) not in [TYPE_INT, TYPE_FLOAT] or int(seed) <= 0:
				failures.append("supported view %s must include positive seed" % view_id)
			elif adapter == "native_vertical_slice_capture":
				if native_route_seed == 0:
					native_route_seed = int(seed)
				elif native_route_seed != int(seed):
					failures.append("native route views must share one deterministic seed")
		elif support == "unsupported":
			if capture != null:
				failures.append("unsupported view %s must not include capture config" % view_id)

		if typeof(filenames) != TYPE_DICTIONARY:
			failures.append("View %s must include filenames dictionary" % view_id)
			continue
		for aspect in manifest.get("aspects", []):
			var aspect_id := String(aspect.get("id", ""))
			var filename := String(filenames.get(aspect_id, ""))
			if filename.is_empty():
				failures.append("Missing filename for %s at %s" % [view_id, aspect_id])
			elif not safe_filename_pattern.search(filename):
				failures.append("Unsafe filename for %s at %s: %s" % [view_id, aspect_id, filename])

	for expected_id in CANONICAL_VIEWS:
		if not ids.has(expected_id):
			failures.append("Missing canonical view id: " + expected_id)
	for id in ids.keys():
		if not expected_ids.has(id):
			failures.append("Unexpected canonical view id: " + String(id))


func _validate_capture_script_policy() -> void:
	var file := FileAccess.open(CAPTURE_SCRIPT_PATH, FileAccess.READ)
	if file == null:
		failures.append("Capture script is missing and cannot be inspected")
		return
	var source := file.get_as_text()
	file.close()
	if source.find("--approve") == -1:
		failures.append("capture.sh does not expose approve-based baseline overwrite control")
	if source.find("policy requires --approve") == -1 and source.find("without --approve") == -1:
		failures.append("capture.sh does not reveal baseline non-overwrite policy in source")


func _validate_route_pose_contract(view_id: String, staging_id: String, expected_pose: Variant) -> void:
	if typeof(expected_pose) != TYPE_DICTIONARY:
		failures.append("%s must declare expected_camera_pose" % view_id)
		return
	var expected: Dictionary = expected_pose
	var player_values: Variant = expected.get("player_origin")
	var camera_values: Variant = expected.get("camera_origin")
	var look_values: Variant = expected.get("look_target")
	var fov_value: Variant = expected.get("camera_fov")
	if typeof(player_values) != TYPE_ARRAY or (player_values as Array).size() != 3:
		failures.append("%s expected player_origin must contain three values" % view_id)
		return
	if typeof(camera_values) != TYPE_ARRAY or (camera_values as Array).size() != 3:
		failures.append("%s expected camera_origin must contain three values" % view_id)
		return
	if typeof(look_values) != TYPE_ARRAY or (look_values as Array).size() != 3:
		failures.append("%s expected look_target must contain three values" % view_id)
		return
	if typeof(fov_value) not in [TYPE_INT, TYPE_FLOAT]:
		failures.append("%s expected camera_fov must be numeric" % view_id)
		return
	var player_array: Array = player_values
	var camera_array: Array = camera_values
	var look_array: Array = look_values
	var expected_player := Vector3(float(player_array[0]), float(player_array[1]), float(player_array[2]))
	var expected_camera := Vector3(float(camera_array[0]), float(camera_array[1]), float(camera_array[2]))
	var expected_look := Vector3(float(look_array[0]), float(look_array[1]), float(look_array[2]))
	var runtime_pose := VISUAL_DIRECT_CAPTURE_SCRIPT.rain_city_route_stage_pose(staging_id)
	if runtime_pose.is_empty():
		failures.append("%s route staging pose is missing" % view_id)
		return
	var runtime_player: Vector3 = runtime_pose.get("player_origin", Vector3.INF)
	var runtime_camera: Vector3 = runtime_pose.get("camera_origin", Vector3.INF)
	var runtime_look: Vector3 = runtime_pose.get("look_target", Vector3.INF)
	var runtime_fov: float = runtime_pose.get("camera_fov", -1.0)
	if not expected_player.is_equal_approx(runtime_player) or not expected_camera.is_equal_approx(runtime_camera) or not expected_look.is_equal_approx(runtime_look) or not is_equal_approx(float(fov_value), runtime_fov):
		failures.append("%s expected camera pose drifted from visual_direct_capture.gd" % view_id)


func _validate_route_actor_cleanup() -> void:
	var target := CaptureTarget.new()
	var actors := Node3D.new()
	actors.name = "Actors"
	target.add_child(actors)
	var player := Node3D.new()
	player.name = "Player"
	actors.add_child(player)
	target.player = player
	var non_player_actor := Node3D.new()
	non_player_actor.name = "Enemy"
	actors.add_child(non_player_actor)
	root.add_child(target)
	var capture := VISUAL_DIRECT_CAPTURE_SCRIPT.new()
	capture.set("_target", target)
	capture.call("_clear_non_player_actors")
	if not actors.visible or not player.is_visible_in_tree():
		failures.append("Route actor cleanup must preserve the visible player camera hierarchy")
	if not non_player_actor.is_queued_for_deletion():
		failures.append("Route actor cleanup must queue non-player actors for deletion")
	target.queue_free()
	capture.free()
