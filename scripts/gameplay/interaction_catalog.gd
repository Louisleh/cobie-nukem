class_name InteractionCatalog
extends Resource

@export var schema_version := 1
@export var level_id: StringName = &"episode_1_level_1"
@export var placements: Array[InteractionPlacement] = []
@export var required_zone_minimums: Dictionary = {}


func validate(allowed_zone_ids: Array[StringName] = [], expected_level_id: StringName = &"") -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("interaction catalog schema must be 1")
	if level_id == &"":
		errors.append("interaction catalog level_id is empty")
	if expected_level_id != &"" and level_id != expected_level_id:
		errors.append("interaction catalog level_id %s does not match manifest level_id %s" % [level_id, expected_level_id])

	var ids := {}
	var zone_counts := {}
	var allowed := {}
	for zone_id: StringName in allowed_zone_ids:
		allowed[zone_id] = true
	for placement in placements:
		if placement == null:
			errors.append("interaction catalog %s contains a null placement" % level_id)
			continue
		var raw_id := String(placement.id).strip_edges()
		if raw_id.is_empty():
			errors.append("interaction placement has empty id")
			continue
		if ids.has(raw_id):
			errors.append("duplicate interaction placement id: %s" % raw_id)
		ids[raw_id] = true
		errors.append_array(placement.validate())
		if placement.zone_id != &"":
			if not allowed.is_empty() and not allowed.has(placement.zone_id):
				errors.append("interaction placement %s uses unknown zone_id: %s" % [placement.id, placement.zone_id])
			var zone_key := String(placement.zone_id)
			zone_counts[zone_key] = int(zone_counts.get(zone_key, 0)) + 1

	var requirements := required_zone_minimums.duplicate(true)
	for zone_key in requirements.keys():
		var minimum := int(requirements[zone_key])
		if minimum <= 0:
			continue
		if int(zone_counts.get(zone_key, 0)) < minimum:
			errors.append("interaction catalog %s requires at least %d placements in zone_id %s" % [level_id, minimum, zone_key])
	return errors
