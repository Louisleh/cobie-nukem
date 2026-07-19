class_name MissionProgressionProfile
extends Resource

## Canonical mission-specific progression contract used by run-result evaluation.
##{
##  "mission_id": StringName,
##  "par_time_msec": int > 0,
##  "enemies_total": int >= 0,
##  "secrets_total": int >= 0,
##  "collectible_total": int >= 0,
##  "collection_status": StringName("active"|"coming_soon")
##}

@export var mission_id: StringName = &""
@export var par_time_msec := 0
@export var enemies_total := 0
@export var secrets_total := 0
@export var collectible_total := 0
@export var collection_status: StringName = &"coming_soon"


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var normalized_id := _stable_id(mission_id)
	if normalized_id.is_empty():
		errors.append("mission progression profile has invalid mission_id")
	if par_time_msec <= 0:
		errors.append("mission progression profile %s has invalid par_time_msec" % normalized_id)
	if enemies_total < 0:
		errors.append("mission progression profile %s has negative enemies_total" % normalized_id)
	if secrets_total < 0:
		errors.append("mission progression profile %s has negative secrets_total" % normalized_id)
	if collectible_total < 0:
		errors.append("mission progression profile %s has negative collectible_total" % normalized_id)
	if not _is_allowed_collection_status(collection_status):
		errors.append("mission progression profile %s has invalid collection_status: %s" % [normalized_id, String(collection_status).strip_edges()])
	return errors


func is_valid() -> bool:
	return validate().is_empty()


func _stable_id(value: Variant) -> String:
	if value is not String and value is not StringName:
		return ""
	var id := String(value).strip_edges()
	if id.is_empty() or id.find(" ") != -1 or id.find("\t") != -1 or id.find("\n") != -1 or id.find("\r") != -1:
		return ""
	return id


func _is_allowed_collection_status(value: Variant) -> bool:
	var normalized := String(value).strip_edges()
	return normalized == "active" or normalized == "coming_soon"

