class_name ZonePresentationProfile
extends Resource

const VALID_WEATHER := [
	&"clear",
	&"overcast",
	&"fog",
	&"rain",
	&"storm",
	&"night"
]

@export var id: StringName = &"zone_presentation"
@export var zone_id: StringName = &""
@export var palette_id: StringName = &""
@export_range(0, 16, 1) var lighting_budget := 3
@export_range(0, 128, 1) var decal_budget := 24
@export_range(0, 400, 1) var particle_budget := 120
@export var weather: StringName = &"clear"
@export var fog_color: Color = Color(0.38, 0.46, 0.56, 1.0)
@export_range(0.0, 1.0, 0.01) var fog_density := 0.10
@export var fog_enabled := true
@export var landmark_ids: Array[StringName] = []
@export var ambience_cue_id: StringName = &""


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("zone_presentation_profile has empty id")
	else:
		var trimmed_id := String(id).strip_edges()
		if trimmed_id.is_empty():
			errors.append("zone_presentation_profile has empty id")
	if zone_id == &"":
		errors.append("zone_presentation_profile %s has empty zone_id" % id)
	if palette_id == &"":
		errors.append("zone_presentation_profile %s has empty palette_id" % id)
	if lighting_budget < 0:
		errors.append("zone_presentation_profile %s has negative lighting_budget" % id)
	if decal_budget < 0:
		errors.append("zone_presentation_profile %s has negative decal_budget" % id)
	if particle_budget < 0:
		errors.append("zone_presentation_profile %s has negative particle_budget" % id)
	if weather == &"":
		errors.append("zone_presentation_profile %s has empty weather" % id)
	elif weather not in VALID_WEATHER:
		errors.append("zone_presentation_profile %s has unsupported weather %s" % [id, weather])
	if not is_finite(fog_density) or fog_density < 0.0 or fog_density > 1.0:
		errors.append("zone_presentation_profile %s has invalid fog_density" % id)
	if ambience_cue_id == &"":
		errors.append("zone_presentation_profile %s missing ambience_cue_id" % id)
	var seen: Dictionary = {}
	for index in landmark_ids.size():
		var landmark_id: StringName = landmark_ids[index]
		if landmark_id == &"":
			errors.append("zone_presentation_profile %s has empty landmark_ids[%d]" % [id, index])
			continue
		var key := String(landmark_id)
		if seen.has(key):
			errors.append("zone_presentation_profile %s has duplicate landmark_id: %s" % [id, landmark_id])
		else:
			seen[key] = true
	return errors
