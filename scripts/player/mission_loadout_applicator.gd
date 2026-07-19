class_name MissionLoadoutApplicator
extends RefCounted


static func apply(player: CobiePlayer, profile: MissionLoadoutProfile, restored_payload: Dictionary = {}) -> bool:
	if player == null or profile == null or not profile.validate().is_empty() or player.weapons.is_empty():
		return false
	var payload := profile.to_payload()
	var restored: Variant = restored_payload.get("active_mission_upgrades", {})
	if restored is Dictionary and String(restored.get("mission_id", "")) == String(profile.mission_id):
		var sanitized := MissionLoadoutProfile.sanitize_payload(restored)
		if not sanitized.is_empty():
			payload.merge(sanitized, true)
	var unlocked_ids: Array = payload.get("unlocked_weapons", [])
	var ammo_map: Dictionary = payload.get("weapon_ammo", {})
	var selected_id := StringName(payload.get("selected_weapon", profile.selected_weapon))
	var selected_index := -1
	for index in player.weapons.size():
		var weapon := player.weapons[index]
		if weapon.definition == null:
			continue
		var weapon_id := String(weapon.definition.id)
		weapon.unlocked = weapon_id in unlocked_ids
		if ammo_map.has(weapon_id):
			var ammo_state: Dictionary = ammo_map[weapon_id]
			weapon.set_ammo_state(int(ammo_state.get("magazine", weapon.definition.starting_ammo)), int(ammo_state.get("reserve", weapon.definition.starting_reserve)))
		if weapon.definition.id == selected_id:
			selected_index = index
	if selected_index < 0 or not player.weapons[selected_index].unlocked:
		for index in player.weapons.size():
			if player.weapons[index].unlocked:
				selected_index = index
				break
	if selected_index < 0:
		return false
	var equipped_mods: Dictionary = restored_payload.get("equipped_weapon_mods", {})
	if equipped_mods.is_empty():
		var tree := Engine.get_main_loop() as SceneTree
		var save_manager: Node = tree.root.get_node_or_null("SaveManager") if tree != null else null
		if save_manager != null:
			var campaign := CampaignProgressRuntime.new()
			if campaign.configure(save_manager): equipped_mods = campaign.load_progress().get("equipped_weapon_mods", {}).duplicate(true)
			campaign.free()
	var episode: EpisodeDefinition = load("res://resources/campaign/episode_one.tres")
	if episode != null and episode.progression_catalog != null:
		WeaponModApplicator.apply(player, equipped_mods, episode.progression_catalog)
	player.select_weapon(selected_index)
	return true


static func snapshot(player: CobiePlayer, mission_id: StringName, mission_upgrades: Array[StringName] = []) -> Dictionary:
	if player == null:
		return {}
	var unlocked_ids: Array[StringName] = []
	var ammo_state := {}
	for weapon in player.weapons:
		if weapon.definition == null or not weapon.unlocked:
			continue
		unlocked_ids.append(weapon.definition.id)
		ammo_state[String(weapon.definition.id)] = {
			"magazine": weapon.ammo,
			"reserve": weapon.reserve_ammo,
		}
	var selected_id := &""
	if player.current_weapon_index >= 0 and player.current_weapon_index < player.weapons.size() and player.weapons[player.current_weapon_index].definition != null:
		selected_id = player.weapons[player.current_weapon_index].definition.id
	return MissionLoadoutProfile.sanitize_payload({
		"mission_id": mission_id,
		"selected_weapon": selected_id,
		"unlocked_weapons": unlocked_ids,
		"weapon_ammo": ammo_state,
		"mission_upgrades": mission_upgrades,
	})
