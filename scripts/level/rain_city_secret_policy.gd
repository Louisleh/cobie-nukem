class_name RainCitySecretPolicy
extends RefCounted


static func apply_player_reward(player: Node, secret_id: StringName) -> String:
	match secret_id:
		&"secret_downtown_alley":
			if player != null and player.has_method("add_armor"):
				player.add_armor(40.0)
			return "FIRE-ALARM CACHE // +40 ARMOR"
		&"secret_ruse_block":
			if player != null and player.has_method("heal"):
				player.heal(999.0)
			return "RAIN CITY SLICE // FULL HEALTH"
		&"secret_waterfront_seawall":
			if player != null and player.has_method("add_ammo"):
				player.add_ammo("tennis_balls", 6)
			if player != null and player.has_method("add_armor"):
				player.add_armor(25.0)
			return "BALL RETURN // +6 FETCH // +25 ARMOR"
		&"secret_terminal_service":
			return "CARGO ROUTING // ONE FINALE REINFORCEMENT CANCELLED"
	return ""


static func reduced_harbour_definition(source: EncounterDefinition) -> EncounterDefinition:
	if source == null:
		return null
	var reduced := source.duplicate(true) as EncounterDefinition
	var waves := reduced.effective_waves()
	if waves.size() < 2:
		return null
	var reinforcement := waves[1].duplicate(true) as Dictionary
	var spawns: Array = (reinforcement.get("spawns", []) as Array).duplicate(true)
	if spawns.is_empty():
		return null
	spawns.pop_back()
	reinforcement["spawns"] = spawns
	waves[1] = reinforcement
	reduced.waves = waves
	reduced.enemy_budget = maxi(1, reduced.enemy_budget - 1)
	return reduced
