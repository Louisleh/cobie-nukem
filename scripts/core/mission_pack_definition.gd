class_name MissionPackDefinition
extends Resource

## Declarative downloadable-mission package contract. Native builds may keep a
## pack bundled and require no mount; Web builds verify cached/downloaded bytes
## before ProjectSettings.load_resource_pack() is allowed to see them.

@export var pack_id: StringName = &"mission_pack"
@export_range(1, 9999, 1) var content_version := 1
@export var remote_url := ""
@export var expected_bytes: int = 0
@export var expected_sha256 := ""
@export var cache_file := ""
@export var bundled_on_native := true
@export_file("*.pck", "*.zip") var bundled_pack_path := ""
@export var prerequisite_pack_id: StringName = &""
@export var required_resource_paths: PackedStringArray = []


func effective_cache_file() -> String:
	if not cache_file.strip_edges().is_empty():
		return cache_file.strip_edges()
	return "%s-v%d.pck" % [String(pack_id), content_version]


func cache_path(cache_root := "user://mission_packs") -> String:
	return "%s/%s" % [cache_root.trim_suffix("/"), effective_cache_file()]


func is_download_configured() -> bool:
	return expected_bytes > 0 and _normalized_hash().length() == 64 and not remote_url.strip_edges().is_empty()


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(pack_id).strip_edges().is_empty():
		errors.append("mission pack has empty pack_id")
	if content_version <= 0:
		errors.append("mission pack %s has invalid content_version" % pack_id)
	var file_name := effective_cache_file()
	if file_name.is_empty() or file_name.get_file() != file_name or not _safe_cache_file(file_name):
		errors.append("mission pack %s has unsafe cache_file: %s" % [pack_id, file_name])
	if expected_bytes < 0:
		errors.append("mission pack %s has negative expected_bytes" % pack_id)
	var digest := _normalized_hash()
	if not digest.is_empty() and (digest.length() != 64 or not digest.is_valid_hex_number(false)):
		errors.append("mission pack %s has invalid SHA-256" % pack_id)
	if expected_bytes > 0 and digest.is_empty():
		errors.append("mission pack %s has expected bytes but no SHA-256" % pack_id)
	if not digest.is_empty() and expected_bytes <= 0:
		errors.append("mission pack %s has SHA-256 but no expected byte count" % pack_id)
	var url := remote_url.strip_edges()
	if not url.is_empty() and not (url.begins_with("https://") or url.begins_with("http://127.0.0.1") or url.begins_with("http://localhost")):
		errors.append("mission pack %s remote_url must use HTTPS or loopback HTTP" % pack_id)
	if not bundled_pack_path.is_empty() and not ResourceLoader.exists(bundled_pack_path):
		errors.append("mission pack %s bundled path is missing: %s" % [pack_id, bundled_pack_path])
	var seen := {}
	for path in required_resource_paths:
		if path.is_empty():
			errors.append("mission pack %s has an empty required resource path" % pack_id)
			continue
		if seen.has(path):
			errors.append("mission pack %s repeats required resource path: %s" % [pack_id, path])
		else:
			seen[path] = true
	return errors


func normalized_sha256() -> String:
	return _normalized_hash()


func _normalized_hash() -> String:
	return expected_sha256.strip_edges().to_lower()


func _safe_cache_file(value: String) -> bool:
	if not (value.ends_with(".pck") or value.ends_with(".zip")):
		return false
	for character in value:
		if character.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789_-.":
			continue
		return false
	return true
