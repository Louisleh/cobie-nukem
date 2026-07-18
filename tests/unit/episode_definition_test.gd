extends SceneTree

const Campaign: EpisodeDefinition = preload("res://resources/campaign/episode_one.tres")


func _init() -> void:
	var errors := Campaign.validate()
	_assert(errors.is_empty(), "campaign definition should validate: %s" % [errors])
	_assert(Campaign.cards.size() == 5, "campaign should expose five ordered cards")
	_assert(Campaign.missions.size() == 3, "baseline should truthfully expose metadata only for three playable missions")
	_assert(Campaign.ordered_level_ids() == [&"episode_1_level_1", &"episode_1_vancouver_waterfront", &"mount_hood_whiteout", &"dark_side_fetch", &"ventura_pier_pressure"], "campaign order should be stable")
	_assert(Campaign.metadata_for(&"mount_hood_whiteout") != null, "Mount Hood metadata should be discoverable")
	_assert(Campaign.metadata_for(&"dark_side_fetch") == null, "Moon remains a teaser until its metadata is authored")
	print("EPISODE DEFINITION TEST: PASS")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
