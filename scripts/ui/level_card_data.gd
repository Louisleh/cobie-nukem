class_name LevelCardData
extends Resource

enum UnlockPolicy {
	ALWAYS,
	CAMPAIGN,
	LOCKED_TEASER,
}

@export var unlock_policy: UnlockPolicy = UnlockPolicy.LOCKED_TEASER
@export var prerequisite_mission_id: StringName = &""
@export var level_id: StringName
@export var title := "LOCKED COURSE"
@export var episode := "EPISODE ?"
@export_multiline var description := "Animal Control has classified this location."
@export_range(1, 5, 1) var difficulty := 1
@export var expected_minutes := "12–20 MIN"
@export var secrets := 0
@export var encounter := "UNKNOWN THREAT"
@export_file("*.tscn") var scene_path := ""
@export var release_badge := ""
@export_multiline var launch_notice := ""
@export var preview: Texture2D
@export var unlocked := false

func is_available(campaign_progress: CampaignProgressRuntime = null, development_override := false) -> bool:
	match unlock_policy:
		UnlockPolicy.ALWAYS:
			return true
		UnlockPolicy.LOCKED_TEASER:
			return false
		UnlockPolicy.CAMPAIGN:
			if development_override:
				return true
			if campaign_progress == null:
				return false
			# A player who completed an earlier public preview keeps access even if
			# that preview predated the campaign prerequisite chain.
			if level_id != &"" and (campaign_progress.is_mission_completed(level_id) or campaign_progress.is_mission_unlocked(level_id)):
				return true
			var prerequisite := String(prerequisite_mission_id).strip_edges()
			if prerequisite.is_empty():
				return false
			return campaign_progress.is_mission_completed(StringName(prerequisite))
		_:
			return false

func is_preview_release(campaign_progress: CampaignProgressRuntime = null, development_override := false) -> bool:
	return is_available(campaign_progress, development_override) and status_badge(campaign_progress, development_override) != "ACTIVE"

func status_badge(campaign_progress: CampaignProgressRuntime = null, development_override := false) -> String:
	if not is_available(campaign_progress, development_override):
		return "LOCKED"
	var configured := release_badge.strip_edges().to_upper()
	return configured if not configured.is_empty() else "ACTIVE"
