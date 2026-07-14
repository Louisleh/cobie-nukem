class_name MissionAudioProfile
extends Resource

@export var id: StringName = &"mission_audio"
@export var exploration_ambience_cue_id: StringName = &""
@export var tension_ambience_cue_id: StringName = &""
@export var combat_ambience_cue_id: StringName = &""
@export var boss_ambience_cue_id: StringName = &""
@export var victory_ambience_cue_id: StringName = &""
@export_range(0.0, 12.0, 0.05) var crossfade_seconds := 1.0
@export_range(1, 64, 1) var web_voice_cap := 12
@export_range(1, 256, 1) var native_voice_cap := 24
@export var ambience_cue_ids: Array[StringName] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("mission_audio_profile has empty id")
	else:
		var trimmed_id := String(id).strip_edges()
		if trimmed_id.is_empty():
			errors.append("mission_audio_profile has empty id")
	if exploration_ambience_cue_id == &"":
		errors.append("mission_audio_profile %s missing exploration_ambience_cue_id" % id)
	if tension_ambience_cue_id == &"":
		errors.append("mission_audio_profile %s missing tension_ambience_cue_id" % id)
	if combat_ambience_cue_id == &"":
		errors.append("mission_audio_profile %s missing combat_ambience_cue_id" % id)
	if boss_ambience_cue_id == &"":
		errors.append("mission_audio_profile %s missing boss_ambience_cue_id" % id)
	if victory_ambience_cue_id == &"":
		errors.append("mission_audio_profile %s missing victory_ambience_cue_id" % id)
	if not is_finite(crossfade_seconds) or crossfade_seconds < 0.0:
		errors.append("mission_audio_profile %s has invalid crossfade_seconds" % id)
	if not _is_valid_voice_cap(web_voice_cap, "web_voice_cap"):
		errors.append("mission_audio_profile %s has invalid web_voice_cap" % id)
	if not _is_valid_voice_cap(native_voice_cap, "native_voice_cap"):
		errors.append("mission_audio_profile %s has invalid native_voice_cap" % id)
	if web_voice_cap > native_voice_cap:
		errors.append("mission_audio_profile %s has web_voice_cap greater than native_voice_cap" % id)
	var seen: Dictionary = {}
	for index in ambience_cue_ids.size():
		var cue_id: StringName = ambience_cue_ids[index]
		if cue_id == &"":
			errors.append("mission_audio_profile %s has empty ambience_cue_ids[%d]" % [id, index])
			continue
		var key := String(cue_id)
		if seen.has(key):
			errors.append("mission_audio_profile %s has duplicate ambience cue id: %s" % [id, cue_id])
		else:
			seen[key] = true
	return errors


func _is_valid_voice_cap(cap: int, _field_name: StringName) -> bool:
	return cap > 0 and cap <= 128
