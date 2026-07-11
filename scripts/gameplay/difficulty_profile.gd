class_name DifficultyProfile
extends Resource

@export var id: StringName = &"classic"
@export var display_name := "GOOD DOG"
@export_multiline var description := "The intended Cobie Nukem balance."
@export_range(0.1, 3.0, 0.05) var enemy_health_multiplier := 1.0
@export_range(0.1, 3.0, 0.05) var enemy_damage_multiplier := 1.0
@export_range(0.1, 3.0, 0.05) var enemy_speed_multiplier := 1.0
@export_range(0.1, 3.0, 0.05) var enemy_aggression_multiplier := 1.0
@export_range(0.1, 3.0, 0.05) var pickup_amount_multiplier := 1.0
@export_range(0.0, 1.0, 0.05) var aim_assist_strength := 0.65


func scaled_enemy_health(base_value: float) -> float:
	return maxf(1.0, base_value * enemy_health_multiplier)


func scaled_enemy_damage(base_value: float) -> float:
	return maxf(0.0, base_value * enemy_damage_multiplier)


func scaled_enemy_speed(base_value: float) -> float:
	return maxf(0.1, base_value * enemy_speed_multiplier)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("difficulty id is empty")
	if display_name.strip_edges().is_empty(): errors.append("difficulty display name is empty")
	return errors
