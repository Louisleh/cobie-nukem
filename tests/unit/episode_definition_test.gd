extends SceneTree

const Campaign: EpisodeDefinition = preload("res://resources/campaign/episode_one.tres")


func _init() -> void:
	var errors := Campaign.validate()
	_assert(errors.is_empty(), "campaign definition should validate: %s" % [errors])
	_assert(Campaign.cards.size() == 5, "campaign should expose five ordered cards")
	_assert(Campaign.missions.size() == 5, "campaign should expose metadata for all five playable missions")
	_assert(Campaign.ordered_level_ids() == [&"episode_1_level_1", &"episode_1_vancouver_waterfront", &"mount_hood_whiteout", &"dark_side_fetch", &"ventura_pier_pressure"], "campaign order should be stable")
	_assert(Campaign.metadata_for(&"mount_hood_whiteout") != null, "Mount Hood metadata should be discoverable")
	_assert(Campaign.metadata_for(&"dark_side_fetch") != null, "Moon metadata is discoverable")
	_assert(Campaign.metadata_for(&"ventura_pier_pressure") != null, "Ventura metadata is discoverable")
	_assert(Campaign.metadata_for(&"mount_hood_whiteout").next_mission_id == &"dark_side_fetch", "Mount Hood continues to Moon")
	_assert(Campaign.metadata_for(&"dark_side_fetch").next_mission_id == &"ventura_pier_pressure", "Moon continues to Ventura")
	var invalid := Campaign.duplicate(true) as EpisodeDefinition
	var mount := invalid.metadata_for(&"mount_hood_whiteout")
	mount.next_mission_id = &"missing_mission"
	mount.next_mission_scene = "res://scenes/menus/main_menu.tscn"
	mount.next_mission_title = "MISSING"
	_assert(_contains(invalid.validate(), "continues to unknown mission"), "unknown campaign continuation is rejected")
	print("EPISODE DEFINITION TEST: PASS")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)


func _contains(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if fragment in error: return true
	return false
