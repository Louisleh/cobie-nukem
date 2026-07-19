class_name MiniBallMissionDefinition
extends Resource

@export var mission_id: StringName = &""
@export var zones: Array[Dictionary] = []


func total_count() -> int:
	var total := 0
	for zone in zones: total += maxi(0, int(zone.get("count", 0)))
	return total


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(mission_id).strip_edges().is_empty(): errors.append("mini ball definition has no mission id")
	var zone_ids := {}
	for zone in zones:
		var zone_id := String(zone.get("id", "")).strip_edges()
		if zone_id.is_empty() or zone_ids.has(zone_id): errors.append("mini ball definition has invalid/duplicate zone %s" % zone_id)
		zone_ids[zone_id] = true
		if int(zone.get("count", 0)) <= 0: errors.append("mini ball zone %s has no collectibles" % zone_id)
		if zone.get("origin") is not Vector3: errors.append("mini ball zone %s has no Vector3 origin" % zone_id)
	if total_count() != 50: errors.append("mini ball mission %s must author exactly 50 collectibles" % mission_id)
	return errors
