class_name EpisodeDefinition
extends Resource

## Data-driven campaign graph shared by mission selection and victory routing.
## Cards own player-facing availability; metadata owns replay/continuation data.

@export var id: StringName = &"episode"
@export var title := "COBIE NUKEM"
@export var cards: Array[LevelCardData] = []
@export var missions: Array[LevelMetadata] = []
@export var mission_packs: Array[MissionPackDefinition] = []
@export var completion_upgrade: StringName = &""


func card_for(level_id: StringName) -> LevelCardData:
	for card in cards:
		if card != null and card.level_id == level_id:
			return card
	return null


func metadata_for(level_id: StringName) -> LevelMetadata:
	for mission in missions:
		if mission != null and mission.level_id == level_id:
			return mission
	return null


func pack_for(pack_id: StringName) -> MissionPackDefinition:
	for pack in mission_packs:
		if pack != null and pack.pack_id == pack_id:
			return pack
	return null


func ordered_level_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for card in cards:
		if card != null and card.level_id != &"":
			result.append(card.level_id)
	return result


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("episode definition has empty id")
	if cards.is_empty():
		errors.append("episode definition %s has no cards" % id)
	var card_ids: Dictionary = {}
	for index in cards.size():
		var card := cards[index]
		if card == null:
			errors.append("episode definition %s has null card at index %d" % [id, index])
			continue
		if card.level_id == &"":
			errors.append("episode definition %s has card with empty level_id" % id)
			continue
		if card_ids.has(card.level_id):
			errors.append("episode definition %s has duplicate card %s" % [id, card.level_id])
		else:
			card_ids[card.level_id] = true
	var metadata_ids: Dictionary = {}
	for mission in missions:
		if mission == null:
			errors.append("episode definition %s has null mission metadata" % id)
			continue
		if mission.level_id == &"":
			errors.append("episode definition %s has metadata with empty level_id" % id)
			continue
		if metadata_ids.has(mission.level_id):
			errors.append("episode definition %s has duplicate metadata %s" % [id, mission.level_id])
		else:
			metadata_ids[mission.level_id] = mission
		if not ResourceLoader.exists(mission.replay_scene, "PackedScene"):
			errors.append("episode mission %s replay scene is missing: %s" % [mission.level_id, mission.replay_scene])
	var pack_ids: Dictionary = {}
	for pack in mission_packs:
		if pack == null:
			errors.append("episode definition %s has null mission pack" % id)
			continue
		if pack_ids.has(pack.pack_id):
			errors.append("episode definition %s has duplicate mission pack %s" % [id, pack.pack_id])
		else:
			pack_ids[pack.pack_id] = true
		errors.append_array(pack.validate())
		if pack.prerequisite_pack_id != &"" and not pack_ids.has(pack.prerequisite_pack_id):
			errors.append("episode mission pack %s has unknown or later prerequisite %s" % [pack.pack_id, pack.prerequisite_pack_id])
	for card in cards:
		if card == null or card.level_id == &"":
			continue
		var available_payload := not card.scene_path.is_empty()
		if available_payload and not ResourceLoader.exists(card.scene_path, "PackedScene"):
			errors.append("episode card %s scene is missing: %s" % [card.level_id, card.scene_path])
		if available_payload and not metadata_ids.has(card.level_id):
			errors.append("playable episode card %s has no mission metadata" % card.level_id)
	for mission_id in metadata_ids.keys():
		if not card_ids.has(mission_id):
			errors.append("episode mission %s has no level card" % mission_id)
			continue
		var mission := metadata_ids[mission_id] as LevelMetadata
		if mission.has_next_mission():
			if not card_ids.has(mission.next_mission_id):
				errors.append("episode mission %s continues to unknown mission %s" % [mission.level_id, mission.next_mission_id])
			elif not ResourceLoader.exists(mission.next_mission_scene, "PackedScene"):
				errors.append("episode mission %s next scene is missing: %s" % [mission.level_id, mission.next_mission_scene])
	return errors
