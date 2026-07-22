extends SceneTree

const MANIFEST_PATH := "res://tools/visual_quality/capture_manifest.json"
const CAPTURE_SCRIPT_PATH := "res://tools/visual_quality/capture.sh"
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
	"vancouver_waterfront",
	"mount_hood_foundry",
	"moon_landing_pad",
	"ventura_service_lane",
	"rain_city_towmaster",
	"touch_hud_4_3",
]
const CANONICAL_COUNT := 16

var failures: Array[String] = []
var safe_filename_pattern: RegEx = RegEx.new()


func _initialize() -> void:
	safe_filename_pattern.compile("^[a-z0-9_]+_[0-9]+x[0-9]+\\.png$")
	_validate_manifest_json()
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
