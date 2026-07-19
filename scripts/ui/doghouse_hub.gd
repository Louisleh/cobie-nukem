class_name DoghouseHub
extends Control

const Campaign: EpisodeDefinition = preload("res://resources/campaign/episode_one.tres")

var _campaign: CampaignProgressRuntime
var _selected_station := &"mission_map"
var _routing := false
var _backup_edit: TextEdit
var _pending_import: Dictionary = {}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState._set_phase(GameState.Phase.MENU)
	_campaign = CampaignProgressRuntime.new(); add_child(_campaign); _campaign.configure(SaveManager); _campaign.load_progress()
	%BuildLabel.text = BuildInfo.label()
	%WalletLabel.text = "COMPLIANCE TAGS // %04d" % _campaign.compliance_tags()
	_wire(%MissionMapButton, &"mission_map")
	_wire(%GearBenchButton, &"gear")
	_wire(%BallShelfButton, &"balls")
	_wire(%ChallengeBoardButton, &"challenges")
	_wire(%KennelRecordsButton, &"records")
	%BackButton.pressed.connect(func() -> void: _route("res://scenes/menus/main_menu.tscn"))
	%MissionMapButton.grab_focus()
	_show_station(&"mission_map")


func _wire(button: Button, station: StringName) -> void:
	button.pressed.connect(func() -> void: _show_station(station))
	button.mouse_entered.connect(button.grab_focus)


func _show_station(station: StringName) -> void:
	_selected_station = station
	_pending_import.clear()
	for child in %Content.get_children(): child.queue_free()
	%WalletLabel.text = "COMPLIANCE TAGS // %04d" % _campaign.compliance_tags()
	match station:
		&"mission_map": _show_mission_map()
		&"gear": _show_gear()
		&"balls": _show_ball_shelf()
		&"challenges": _show_challenges()
		&"records": _show_records()


func _show_mission_map() -> void:
	_heading("MISSION MAP", "Five incidents. One very good dog.")
	for profile in Campaign.progression_catalog.mission_profiles:
		var metadata := Campaign.metadata_for(profile.mission_id)
		var record := _campaign.mission_record(profile.mission_id)
		var best := "--:--"
		if record.has("best_time_msec"):
			var seconds := int(record.best_time_msec) / 1000; best = "%02d:%02d" % [seconds / 60, seconds % 60]
		var collection := "%d / %d BALLS" % [_campaign.collection_count(profile.mission_id), profile.collectible_total] if profile.collection_status == &"active" else "COLLECTION COMING SOON"
		_add_label("%s  //  %s  //  BEST %s  //  %s" % [metadata.title if metadata else profile.mission_id, String(record.get("rank", "UNRANKED")), best, collection], 7)
	var play := _add_button("OPEN MISSION MAP")
	play.pressed.connect(func() -> void: _route("res://scenes/menus/level_select.tscn"))


func _show_gear() -> void:
	_heading("GEAR BENCH", "One mod per weapon. Sidegrades, never mandatory power.")
	var snapshot := _campaign.snapshot()
	var purchased: Array = snapshot.get("purchased_rewards", [])
	var equipped: Dictionary = snapshot.get("equipped_weapon_mods", {})
	var completed: Array = snapshot.get("completed_challenges", [])
	for mod in Campaign.progression_catalog.weapon_mods:
		var owned := String(mod.id) in purchased
		var eligible := mod.unlock_challenge_id == &"" or String(mod.unlock_challenge_id) in completed
		var active := String(equipped.get(String(mod.weapon_id), "")) == String(mod.id)
		var action := "EQUIPPED" if active else ("EQUIP" if owned else ("BUY %d" % mod.cost if eligible else "CHALLENGE LOCKED"))
		var button := _add_button("%s // %s // %s" % [mod.title, mod.weapon_id.to_upper(), action])
		button.tooltip_text = mod.description
		button.disabled = active or not eligible
		button.pressed.connect(func() -> void:
			var error := _campaign.equip_weapon_mod(mod.weapon_id, mod.id) if owned else _campaign.purchase_reward(mod.id, mod.cost)
			if error == OK and not owned: _campaign.equip_weapon_mod(mod.weapon_id, mod.id)
			_show_station(&"gear")
		)
	_add_label("COSMETICS", 9, Color("75d7d0"))
	for cosmetic in Campaign.progression_catalog.cosmetics:
		var owned := String(cosmetic.id) in purchased
		var milestone_only := cosmetic.cost == 0 and cosmetic.milestone_collectibles > 0
		var selected := String(snapshot.get("selected_cosmetics", {}).get(String(cosmetic.slot), "")) == String(cosmetic.id)
		var action := "SELECTED" if selected else ("SELECT" if owned else ("MILESTONE" if milestone_only else "BUY %d" % cosmetic.cost))
		var button := _add_button("%s // %s" % [cosmetic.title, action])
		button.disabled = selected or milestone_only and not owned
		button.pressed.connect(func() -> void:
			var error := _campaign.select_cosmetic(cosmetic.slot, cosmetic.id) if owned else _campaign.purchase_reward(cosmetic.id, cosmetic.cost)
			if error == OK and not owned: _campaign.select_cosmetic(cosmetic.slot, cosmetic.id)
			_show_station(&"gear")
		)


func _show_ball_shelf() -> void:
	_heading("BALL SHELF", "Mini Balls save immediately. Find all 50 in each active collection.")
	for profile in Campaign.progression_catalog.mission_profiles:
		var metadata := Campaign.metadata_for(profile.mission_id)
		if profile.collection_status == &"active":
			var found := _campaign.collection_count(profile.mission_id)
			_add_label("%s // %02d / %02d // %d%%" % [metadata.title, found, profile.collectible_total, int(100.0 * found / max(1, profile.collectible_total))], 8)
		else:
			_add_label("%s // COLLECTION COMING SOON" % metadata.title, 7, Color("8c9992"))


func _show_challenges() -> void:
	_heading("CHALLENGE BOARD", "%d / %d COMPLETE // permanent, no timers" % [_campaign.challenge_count(), Campaign.progression_catalog.challenges.size()])
	var completed: Array = _campaign.snapshot().get("completed_challenges", [])
	for challenge in Campaign.progression_catalog.challenges:
		var state := "COMPLETE" if String(challenge.id) in completed else "+%d TAGS" % challenge.tag_reward
		_add_label("%s // %s\n%s" % [challenge.title, state, challenge.description], 7, Color("ffcf55") if state == "COMPLETE" else Color("d7dfd0"))


func _show_records() -> void:
	_heading("KENNEL RECORDS", "Offline guest profile. Backup code contains campaign progress only.")
	if not OS.is_userfs_persistent(): _add_label("WARNING // THIS BROWSER MAY CLEAR LOCAL SAVES", 7, Color("ff684d"))
	_backup_edit = TextEdit.new(); _backup_edit.custom_minimum_size = Vector2(0, 76); _backup_edit.placeholder_text = "COBIE1 backup code"; _backup_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY; %Content.add_child(_backup_edit)
	var export_button := _add_button("EXPORT BACKUP CODE")
	export_button.pressed.connect(func() -> void:
		_backup_edit.text = CampaignBackupCodec.encode(_campaign.snapshot())
		_backup_edit.select_all(); DisplayServer.clipboard_set(_backup_edit.text)
		%StatusLabel.text = "BACKUP COPIED // STORE IT SOMEWHERE SAFE"
	)
	var import_button := _add_button("PREVIEW IMPORT")
	import_button.pressed.connect(func() -> void: _handle_import(import_button))


func _handle_import(button: Button) -> void:
	if _pending_import.is_empty():
		_pending_import = CampaignBackupCodec.decode(_backup_edit.text.strip_edges())
		if _pending_import.is_empty(): %StatusLabel.text = "BACKUP REJECTED // CHECK CODE"; return
		%StatusLabel.text = "PREVIEW // %d MISSIONS // %d CHALLENGES // %d TAGS" % [_pending_import.completed_missions.size(), _pending_import.completed_challenges.size(), int(_pending_import.wallet.compliance_tags)]
		button.text = "CONFIRM REPLACE PROFILE"
		return
	SaveManager.save_slot(&"campaign_progress_import_backup", _campaign.snapshot())
	if _campaign.replace_profile_from_import(_pending_import) == OK:
		%StatusLabel.text = "PROFILE IMPORTED // PREVIOUS PROFILE BACKED UP"
		_show_station(&"records")


func _heading(title: String, subtitle: String) -> void:
	_add_label(title, 14, Color("ffbb38")); _add_label(subtitle, 7, Color("9fb5aa"))


func _add_label(text: String, size: int, color := Color("d7dfd0")) -> Label:
	var label := Label.new(); label.text = text; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; %Content.add_child(label); return label


func _add_button(text: String) -> Button:
	var button := Button.new(); button.text = text; button.custom_minimum_size.y = 27; button.alignment = HORIZONTAL_ALIGNMENT_LEFT; button.mouse_entered.connect(button.grab_focus); %Content.add_child(button); return button


func _route(path: String) -> void:
	if _routing: return
	if SceneRouter.go_to(path) == OK: _routing = true
