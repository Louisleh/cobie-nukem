class_name CosmeticRewardDefinition
extends Resource

@export var id: StringName = &""
@export var slot: StringName = &""
@export var title := ""
@export_multiline var description := ""
@export var cost := 0
@export var milestone_mission_id: StringName = &""
@export var milestone_collectibles := 0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty(): errors.append("cosmetic reward has no id")
	if String(slot).strip_edges().is_empty(): errors.append("cosmetic reward %s has no slot" % id)
	if title.strip_edges().is_empty(): errors.append("cosmetic reward %s has no title" % id)
	if cost < 0 or milestone_collectibles < 0: errors.append("cosmetic reward %s has invalid cost/milestone" % id)
	if milestone_collectibles > 0 and String(milestone_mission_id).strip_edges().is_empty():
		errors.append("cosmetic reward %s has milestone without mission" % id)
	return errors
