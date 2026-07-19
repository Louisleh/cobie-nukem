class_name WeaponModDefinition
extends Resource

@export var id: StringName = &""
@export var weapon_id: StringName = &""
@export var title := ""
@export_multiline var description := ""
@export var cost := 0
@export var unlock_challenge_id: StringName = &""
@export var stat_multipliers: Dictionary = {}
@export var stat_additions: Dictionary = {}


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty(): errors.append("weapon mod has no id")
	if not ResourceLoader.exists("res://resources/weapons/%s.tres" % String(weapon_id)):
		errors.append("weapon mod %s references unknown weapon %s" % [id, weapon_id])
	if title.strip_edges().is_empty(): errors.append("weapon mod %s has no title" % id)
	if cost < 0: errors.append("weapon mod %s has negative cost" % id)
	for key in stat_multipliers:
		var value: Variant = stat_multipliers[key]
		if value is not float and value is not int or float(value) <= 0.0 or not is_finite(float(value)):
			errors.append("weapon mod %s has invalid multiplier %s" % [id, key])
	return errors
