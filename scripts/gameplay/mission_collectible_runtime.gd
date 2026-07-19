class_name MissionCollectibleRuntime
extends Node3D

signal collectible_found(id: StringName, found: int, total: int)
signal milestone_unlocked(text: String)

const MILESTONE_TAGS := {10: 25, 50: 75}
const MILESTONE_REWARDS := {
	"episode_1_level_1": {25: "hud_salmon_field", 40: "pawstol_salmon_turf", 50: "trophy_salmon_ball"},
	"episode_1_vancouver_waterfront": {25: "hud_rain_city", 40: "barkshot_rain_slick", 50: "trophy_rain_ball"},
}

var definition: MiniBallMissionDefinition
var _campaign: CampaignProgressRuntime
var _save_manager: Node


func configure(source: MiniBallMissionDefinition, save_manager: Node) -> bool:
	definition = source
	_save_manager = save_manager
	if definition == null or not definition.validate().is_empty() or save_manager == null: return false
	_campaign = CampaignProgressRuntime.new(); add_child(_campaign)
	if not _campaign.configure(save_manager): return false
	_campaign.load_progress()
	_spawn_missing()
	return true


func collected_count() -> int:
	return _campaign.collection_count(definition.mission_id) if _campaign != null else 0


func _spawn_missing() -> void:
	var progress := _campaign.snapshot()
	var collected: Array = progress.get("mission_collectibles", {}).get(String(definition.mission_id), [])
	for zone in definition.zones:
		var zone_id := String(zone.get("id", ""))
		var count := int(zone.get("count", 0))
		var origin: Vector3 = zone.get("origin", Vector3.ZERO)
		var width := maxf(1.0, float(zone.get("width", 8.0)))
		var depth := maxf(1.0, float(zone.get("depth", 7.0)))
		for index in count:
			var collectible_id := "%s_%02d" % [zone_id, index + 1]
			if collectible_id in collected: continue
			var pickup := MiniBallCollectible.new(); pickup.name = "MiniBall_%s" % collectible_id; pickup.configure(StringName(collectible_id))
			var columns := mini(5, count); var row := index / columns; var column := index % columns
			var rows := int(ceil(float(count) / float(columns)))
			pickup.position = origin + Vector3((float(column) / maxf(1.0, columns - 1.0) - 0.5) * width, 0.0, (float(row) / maxf(1.0, rows - 1.0) - 0.5) * depth)
			pickup.collected.connect(_on_collected)
			add_child(pickup)


func _on_collected(id: StringName) -> void:
	var before := _campaign.collection_count(definition.mission_id)
	if _campaign.collect_mini_ball(definition.mission_id, id) != OK: return
	var after := _campaign.collection_count(definition.mission_id)
	if after <= before: return
	collectible_found.emit(id, after, definition.total_count())
	if MILESTONE_TAGS.has(after):
		_campaign.grant_compliance_tags(int(MILESTONE_TAGS[after]))
		milestone_unlocked.emit("COLLECTION MILESTONE // +%d COMPLIANCE TAGS" % int(MILESTONE_TAGS[after]))
	var mission_rewards: Dictionary = MILESTONE_REWARDS.get(String(definition.mission_id), {})
	if mission_rewards.has(after):
		var reward_id := StringName(mission_rewards[after])
		if _campaign.grant_reward(reward_id) == OK:
			milestone_unlocked.emit("DOGHOUSE REWARD UNLOCKED // %s" % String(reward_id).replace("_", " ").to_upper())
