class_name RainCityCompletionFlow
extends RefCounted


static func begin(mission: Node) -> void:
	if bool(mission.get("_completion_started")):
		return
	mission.set("_completion_started", true)
	var summary: Dictionary = mission.call("get_level_summary")
	mission.set("_completion_summary", summary)
	var save_manager: Node = mission.call("_get_save_manager")
	if save_manager == null:
		rollback(mission, ERR_UNCONFIGURED)
		return
	var difficulty_id: StringName = mission.call("_completion_difficulty_id")
	var campaign_error: Error = mission.call("_persist_campaign_completion", summary, save_manager, difficulty_id)
	if campaign_error != OK:
		rollback(mission, campaign_error)
		return
	var delete_error: Error = save_manager.delete_slot(&"checkpoint")
	if delete_error != OK:
		rollback(mission, delete_error, "completed checkpoint cleanup")
		return
	mission.emit_signal("narrative_message", "RAIN CITY: CITATION DISPUTED SUCCESSFULLY.", 4.0)
	mission.call("_start_completion_transition")


static func rollback(mission: Node, save_error: Error, context := "campaign completion") -> void:
	mission.set("_completion_started", false)
	var summary: Dictionary = mission.get("_completion_summary")
	summary.clear()
	var runtime: MissionRuntime = mission.get("_mission_runtime")
	if runtime != null and runtime.objectives != null:
		runtime.objectives.completed.erase(&"complete_harbour_pier")
		runtime.objectives.progress.erase(&"complete_harbour_pier")
	var world_builder: VancouverWaterfrontWorldBuilder = mission.get("_world_builder")
	if world_builder != null and world_builder.departure_switch != null:
		world_builder.departure_switch.is_active = false
		world_builder.departure_switch.set_enabled(true)
	mission.call("_report_persistence_failure", context, save_error)
	mission.emit_signal("narrative_message", "CAMPAIGN SAVE FAILED // USE DEPARTURE CONTROL TO RETRY", 4.0)
