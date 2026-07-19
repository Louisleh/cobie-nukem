class_name WeaponModApplicator
extends RefCounted


static func apply(player: CobiePlayer, equipped_mods: Dictionary, catalog: EpisodeProgressionCatalog) -> PackedStringArray:
	var applied := PackedStringArray()
	if player == null or catalog == null: return applied
	for weapon in player.weapons:
		if weapon == null or weapon.definition == null: continue
		var weapon_id := String(weapon.definition.id)
		var mod_id := StringName(equipped_mods.get(weapon_id, &""))
		var mod := catalog.mod_for(mod_id)
		if mod == null or mod.weapon_id != weapon.definition.id: continue
		var duplicated := weapon.definition.duplicate(true) as WeaponDefinition
		if duplicated == null: continue
		if duplicated.feel != null: duplicated.feel = duplicated.feel.duplicate(true) as WeaponFeelProfile
		for stat_name in mod.stat_multipliers:
			_apply_multiplier(duplicated, weapon, StringName(stat_name), float(mod.stat_multipliers[stat_name]))
		for stat_name in mod.stat_additions:
			_apply_addition(duplicated, weapon, StringName(stat_name), float(mod.stat_additions[stat_name]))
		weapon.definition = duplicated
		applied.append(String(mod.id))
	return applied


static func _apply_multiplier(definition: WeaponDefinition, weapon: WeaponBase, stat_name: StringName, multiplier: float) -> void:
	if multiplier <= 0.0 or not is_finite(multiplier): return
	if stat_name == &"recall_speed" and weapon is FetchLauncher:
		(weapon as FetchLauncher).mod_recall_speed_multiplier *= multiplier
		(weapon as FetchLauncher).refresh_recall_multipliers()
		return
	if definition.feel != null and stat_name in [&"raise_seconds", &"lower_seconds"]:
		definition.feel.set(stat_name, float(definition.feel.get(stat_name)) * multiplier)
		return
	if definition.get(stat_name) != null:
		definition.set(stat_name, float(definition.get(stat_name)) * multiplier)


static func _apply_addition(_definition: WeaponDefinition, weapon: WeaponBase, stat_name: StringName, amount: float) -> void:
	if stat_name == &"max_bounces" and weapon is FetchLauncher:
		(weapon as FetchLauncher).mod_bounce_bonus += int(round(amount))
