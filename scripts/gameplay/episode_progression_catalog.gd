class_name EpisodeProgressionCatalog
extends Resource

@export var mission_profiles: Array[MissionProgressionProfile] = []
@export var challenges: Array[ProgressionChallengeDefinition] = []
@export var weapon_mods: Array[WeaponModDefinition] = []
@export var cosmetics: Array[CosmeticRewardDefinition] = []


func profile_for(mission_id: StringName) -> MissionProgressionProfile:
	for profile in mission_profiles:
		if profile != null and profile.mission_id == mission_id: return profile
	return null


func challenges_for(mission_id: StringName) -> Array[ProgressionChallengeDefinition]:
	var result: Array[ProgressionChallengeDefinition] = []
	for challenge in challenges:
		if challenge != null and challenge.mission_id == mission_id: result.append(challenge)
	return result


func mod_for(mod_id: StringName) -> WeaponModDefinition:
	for definition in weapon_mods:
		if definition != null and definition.id == mod_id: return definition
	return null


func cosmetic_for(reward_id: StringName) -> CosmeticRewardDefinition:
	for definition in cosmetics:
		if definition != null and definition.id == reward_id: return definition
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	for profile in mission_profiles:
		if profile == null:
			errors.append("progression catalog has null mission profile")
			continue
		errors.append_array(profile.validate())
		_register_id(profile.mission_id, "mission profile", ids, errors)
	for challenge in challenges:
		if challenge == null:
			errors.append("progression catalog has null challenge")
			continue
		errors.append_array(challenge.validate())
		_register_id(challenge.id, "challenge", ids, errors)
		if profile_for(challenge.mission_id) == null: errors.append("challenge %s references unknown mission" % challenge.id)
	for definition in weapon_mods:
		if definition == null:
			errors.append("progression catalog has null weapon mod")
			continue
		errors.append_array(definition.validate())
		_register_id(definition.id, "weapon mod", ids, errors)
	for definition in cosmetics:
		if definition == null:
			errors.append("progression catalog has null cosmetic")
			continue
		errors.append_array(definition.validate())
		_register_id(definition.id, "cosmetic", ids, errors)
	return errors


func _register_id(value: StringName, kind: String, ids: Dictionary, errors: PackedStringArray) -> void:
	var text := String(value).strip_edges()
	if text.is_empty(): return
	if ids.has(text): errors.append("progression catalog duplicates %s id %s" % [kind, text])
	ids[text] = true
