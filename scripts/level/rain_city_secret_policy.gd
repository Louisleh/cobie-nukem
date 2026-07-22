class_name RainCitySecretPolicy
extends RefCounted

const TERMINAL_SECRET_REINFORCEMENT_ID := &"terminal_secret_cancelled_reinforcement"


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
		push_error("RainCitySecretPolicy.reduced_harbour_definition expected a non-null encounter definition")
		return null

	var source_errors := source.validate()
	if not source_errors.is_empty():
		push_error("RainCitySecretPolicy.reduced_harbour_definition source definition is invalid: %s" % source_errors)
		return null

	var reduced := source.duplicate(true) as EncounterDefinition
	var waves := reduced.waves
	if waves.is_empty():
		push_error("RainCitySecretPolicy.reduced_harbour_definition source has no waves")
		return null

	var tagged_wave_index := -1
	var tagged_spawn_index := -1
	for wave_index in range(waves.size()):
		var wave := waves[wave_index] as Dictionary
		var wave_spawns := (wave.get("spawns", []) as Array)
		if wave_spawns is not Array:
			push_error("RainCitySecretPolicy.reduced_harbour_definition wave %d has non-array spawns" % wave_index)
			return null
		for spawn_index in range(wave_spawns.size()):
			var spawn_value: Variant = wave_spawns[spawn_index]
			if spawn_value is not Dictionary:
				push_error("RainCitySecretPolicy.reduced_harbour_definition wave %d spawn %d is not a Dictionary" % [wave_index, spawn_index])
				return null
			var spawn := spawn_value as Dictionary
			var tag_value := StringName(spawn.get("optional_reinforcement_id", &""))
			if tag_value == &"":
				continue
			if tag_value != TERMINAL_SECRET_REINFORCEMENT_ID:
				push_error("RainCitySecretPolicy.reduced_harbour_definition uses unsupported optional_reinforcement_id %s in wave %d spawn %d" % [tag_value, wave_index, spawn_index])
				return null
			if tagged_wave_index != -1:
				push_error("RainCitySecretPolicy.reduced_harbour_definition found multiple terminal secret reinforcements")
				return null
			tagged_wave_index = wave_index
			tagged_spawn_index = spawn_index

	if tagged_wave_index == -1:
		push_error("RainCitySecretPolicy.reduced_harbour_definition has no terminal_secret_cancelled_reinforcement")
		return null

	var tagged_wave := (waves[tagged_wave_index] as Dictionary).duplicate(true) as Dictionary
	var tagged_spawns := (tagged_wave.get("spawns", []) as Array).duplicate(true)
	if tagged_spawns.is_empty():
		push_error("RainCitySecretPolicy.reduced_harbour_definition tagged wave is empty")
		return null
	tagged_spawns.remove_at(tagged_spawn_index)
	tagged_wave["spawns"] = tagged_spawns
	waves[tagged_wave_index] = tagged_wave

	reduced.waves = waves
	reduced.enemy_budget = reduced.enemy_budget - 1
	var reduced_errors := reduced.validate()
	if not reduced_errors.is_empty():
		push_error("RainCitySecretPolicy.reduced_harbour_definition produced invalid reduced definition: %s" % reduced_errors)
		return null
	return reduced
