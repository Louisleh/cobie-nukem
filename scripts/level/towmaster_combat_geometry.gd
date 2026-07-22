class_name TowmasterCombatGeometry
extends RefCounted


static func attack_hits_target(attack: TowmasterAttackDefinition, target_position: Vector3, locked_origin: Vector3, locked_target: Vector3, lane_direction: Vector3) -> bool:
	if attack == null:
		return false
	match attack.shape:
		TowmasterAttackDefinition.AttackShape.TARGET_ZONE:
			if attack.radius <= 0.0 or not is_finite(attack.radius):
				return false
			return Vector2(target_position.x - locked_target.x, target_position.z - locked_target.z).length() <= attack.radius
		TowmasterAttackDefinition.AttackShape.LANE:
			if attack.length <= 0.0 or attack.width <= 0.0 or not is_finite(attack.length) or not is_finite(attack.width):
				return false
			var lane := Vector3(target_position.x - locked_origin.x, 0.0, target_position.z - locked_origin.z)
			var projection := lane.dot(lane_direction)
			return projection >= 0.0 and projection <= attack.length and (lane - lane_direction * projection).length() <= attack.width * 0.5
		TowmasterAttackDefinition.AttackShape.RING:
			if attack.radius <= 0.0 or not is_finite(attack.radius):
				return false
			return Vector2(target_position.x - locked_origin.x, target_position.z - locked_origin.z).length() <= attack.radius
		_:
			return false


static func arena_hits_target(arena_state_id: StringName, local_target: Vector3) -> bool:
	if arena_state_id == &"citation_lanes":
		var lateral := absf(local_target.x)
		return lateral >= 2.3 and lateral <= 4.7 and absf(local_target.z) <= 8.0
	if arena_state_id == &"impound_field":
		return local_target.x * local_target.x + local_target.z * local_target.z <= 4.5 * 4.5
	return false


static func particle_counts(max_particles: int, density: float, ticket_particles: int, spark_particles: int) -> Vector2i:
	var safe_max := maxi(0, max_particles)
	var tickets := maxi(0, roundi(float(ticket_particles) * clampf(density, 0.0, 1.0)))
	var sparks := maxi(0, roundi(float(spark_particles) * clampf(density, 0.0, 1.0)))
	var total := tickets + sparks
	if total > safe_max:
		var ratio := float(safe_max) / float(maxi(total, 1))
		tickets = maxi(0, roundi(float(tickets) * ratio))
		sparks = maxi(0, roundi(float(sparks) * ratio))
		if tickets + sparks > safe_max:
			sparks = maxi(0, safe_max - tickets)
	return Vector2i(clampi(tickets, 0, safe_max), clampi(sparks, 0, maxi(0, safe_max - tickets)))


static func scaled_damage(value: float, game_state: Node) -> float:
	var base := value if is_finite(value) else 0.0
	if game_state == null or not game_state.has_method("get_difficulty_profile"):
		return base
	var profile := game_state.get_difficulty_profile() as DifficultyProfile
	return profile.scaled_enemy_damage(base) if profile != null else base
