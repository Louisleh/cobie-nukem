extends SceneTree

const CAMPAIGN_SLOT := &"campaign_progress"
const SALMON_CARD: LevelCardData = preload("res://resources/level/salmon_creek_card.tres")
const VANCOUVER_CARD: LevelCardData = preload("res://resources/level/rain_city_card.tres")
const MOUNT_HOOD_CARD: LevelCardData = preload("res://resources/level/mountain_card.tres")
const LATER_PUBLIC_BETA_CARDS: Array[LevelCardData] = [
	preload("res://resources/level/moon_card.tres"),
	preload("res://resources/level/ventura_card.tres"),
]

var failures: Array[String] = []
var save_manager: Node
var campaign_runtime: CampaignProgressRuntime


func _initialize() -> void:
	save_manager = get_root().get_node_or_null("SaveManager")
	if save_manager == null:
		push_error("SaveManager autoload unavailable")
		quit(1)
		return

	campaign_runtime = CampaignProgressRuntime.new()
	if not campaign_runtime.configure(save_manager):
		push_error("Campaign progress runtime could not configure with SaveManager")
		quit(1)
		return

	campaign_runtime.load_progress()
	campaign_runtime.reset_progress()
	_test_salmon_availability()
	_test_vancouver_public_beta()
	_test_mount_hood_public_beta()
	_test_later_missions_are_public_betas()

	_save_manager_delete(CAMPAIGN_SLOT)
	campaign_runtime.queue_free()

	if failures.is_empty():
		print("RAIN CITY CAMPAIGN TEST: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _test_salmon_availability() -> void:
	_expect(SALMON_CARD != null, "Salmon card resource loads")
	if SALMON_CARD == null:
		return
	_expect(SALMON_CARD.level_id == &"episode_1_level_1", "Salmon level_id is authored for Episode 1")
	_expect(SALMON_CARD.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Salmon is always available")
	_expect(SALMON_CARD.is_available(), "Salmon is available without campaign progress")
	_expect(SALMON_CARD.is_preview_release() == false, "Salmon preview state is disabled")


func _test_vancouver_public_beta() -> void:
	_expect(VANCOUVER_CARD != null, "Vancouver card resource loads")
	if VANCOUVER_CARD == null:
		return
	_expect(VANCOUVER_CARD.level_id == &"episode_1_vancouver_waterfront", "Vancouver level id remains stable")
	_expect(VANCOUVER_CARD.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Vancouver public BETA uses always-available policy")
	_expect(VANCOUVER_CARD.prerequisite_mission_id == &"", "Vancouver public BETA has no campaign prerequisite")
	_expect(VANCOUVER_CARD.is_available(), "Vancouver public BETA is available without campaign state")
	_expect(VANCOUVER_CARD.is_available(campaign_runtime), "Vancouver public BETA remains available with an empty campaign")

	# Existing campaign records remain readable even though public access no
	# longer depends on them.
	campaign_runtime.record_completion(VANCOUVER_CARD.level_id, {})
	campaign_runtime.load_progress()
	_expect(VANCOUVER_CARD.is_available(campaign_runtime), "Completed Vancouver preview remains available")
	campaign_runtime.reset_progress()
	campaign_runtime.unlock_mission(VANCOUVER_CARD.level_id)
	campaign_runtime.load_progress()
	_expect(VANCOUVER_CARD.is_available(campaign_runtime), "Explicitly unlocked Vancouver remains available")
	campaign_runtime.reset_progress()

	campaign_runtime.record_completion(&"episode_1_level_1", {})
	campaign_runtime.load_progress()
	_expect(campaign_runtime.is_mission_completed(&"episode_1_level_1"), "Campaign runtime records Salmon completion")
	_expect(VANCOUVER_CARD.is_available(campaign_runtime), "Vancouver remains available after Salmon completion")


func _test_later_missions_are_public_betas() -> void:
	for card: LevelCardData in LATER_PUBLIC_BETA_CARDS:
		_expect(card != null, "Later public-beta card resource loads")
		if card == null:
			continue
		_expect(card.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Later card uses always-available public-beta policy: %s" % card.level_id)
		_expect(card.is_available(campaign_runtime), "Later public-beta card remains available with an empty campaign: %s" % card.level_id)
		_expect(card.is_preview_release(campaign_runtime), "Later mission retains an honest preview badge: %s" % card.level_id)


func _test_mount_hood_public_beta() -> void:
	_expect(MOUNT_HOOD_CARD != null, "Mount Hood card resource loads")
	if MOUNT_HOOD_CARD == null:
		return
	_expect(MOUNT_HOOD_CARD.level_id == &"mount_hood_whiteout", "Mount Hood keeps its stable mission id")
	_expect(MOUNT_HOOD_CARD.unlock_policy == LevelCardData.UnlockPolicy.ALWAYS, "Mount Hood public BETA is always available")
	_expect(MOUNT_HOOD_CARD.is_available(campaign_runtime), "Mount Hood public BETA does not depend on campaign state")
	_expect(MOUNT_HOOD_CARD.release_badge == "BETA" and not MOUNT_HOOD_CARD.launch_notice.is_empty(), "Mount Hood carries its honest BETA warning")


func _save_manager_delete(slot: StringName) -> void:
	if save_manager != null:
		save_manager.delete_slot(slot)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
