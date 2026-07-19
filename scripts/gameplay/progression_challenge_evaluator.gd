class_name ProgressionChallengeEvaluator
extends RefCounted

const DIFFICULTY_ORDER := {"story": 0, "classic": 1, "mayhem": 2}
const RANK_TAGS := {"D": 5, "C": 10, "B": 15, "A": 25, "S": 40}
const DIFFICULTY_MULTIPLIER := {"story": 1.0, "classic": 1.15, "mayhem": 1.35}


static func newly_completed(result: Dictionary, definitions: Array[ProgressionChallengeDefinition], already_completed: Array) -> Array[ProgressionChallengeDefinition]:
	var completed: Array[ProgressionChallengeDefinition] = []
	for definition in definitions:
		if definition == null or String(definition.id) in already_completed: continue
		if _matches(result, definition.requirements): completed.append(definition)
	return completed


static func tag_payout(result: Dictionary, first_completion: bool, challenge_reward: int) -> Dictionary:
	var difficulty := String(result.get("difficulty", "classic"))
	var multiplier := float(DIFFICULTY_MULTIPLIER.get(difficulty, 1.0))
	if String(result.get("run_mode", "standard")) == "off_leash": multiplier *= 1.5
	var enemy_tags := maxi(0, int(result.get("pending_compliance_tags", 0)))
	var completion_and_rank := 25 + int(RANK_TAGS.get(String(result.get("rank", "D")), 5))
	var scaled := int(round(float(enemy_tags + completion_and_rank) * multiplier))
	var first_bonus := 50 if first_completion else 0
	return {
		"enemy_tags": enemy_tags,
		"difficulty_multiplier": multiplier,
		"completion_rank_tags": completion_and_rank,
		"first_completion_bonus": first_bonus,
		"challenge_tags": maxi(0, challenge_reward),
		"total": scaled + first_bonus + maxi(0, challenge_reward),
	}


static func _matches(result: Dictionary, requirements: Dictionary) -> bool:
	if bool(requirements.get("all_secrets", false)) and not bool(result.get("medals", {}).get("all_secrets", false)): return false
	if bool(requirements.get("all_enemies", false)) and not bool(result.get("medals", {}).get("all_enemies", false)): return false
	if int(result.get("deaths", 0)) > int(requirements.get("max_deaths", 2147483647)): return false
	if float(result.get("damage_taken", 0.0)) > float(requirements.get("max_damage_taken", INF)): return false
	if int(result.get("completion_time_msec", 0)) > int(requirements.get("max_time_msec", 2147483647)): return false
	var minimum_difficulty := String(requirements.get("difficulty_min", "story"))
	if int(DIFFICULTY_ORDER.get(String(result.get("difficulty", "story")), 0)) < int(DIFFICULTY_ORDER.get(minimum_difficulty, 0)): return false
	var only_weapon := String(requirements.get("only_weapon", ""))
	var usage: Dictionary = result.get("weapon_usage", {})
	if not only_weapon.is_empty():
		if int(usage.get(only_weapon, 0)) < int(requirements.get("min_shots", 0)): return false
		for weapon_id in usage:
			if String(weapon_id) != only_weapon and int(usage[weapon_id]) > 0: return false
	var required_hits: Dictionary = requirements.get("weapon_hits", {})
	var hits_by_weapon: Dictionary = result.get("weapon_hits", {})
	for weapon_id in required_hits:
		if int(hits_by_weapon.get(weapon_id, 0)) < int(required_hits[weapon_id]): return false
	if bool(requirements.get("boss_defeated", false)) and not bool(result.get("boss_defeated", true)): return false
	return true
