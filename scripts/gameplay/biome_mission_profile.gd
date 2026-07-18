class_name BiomeMissionProfile
extends Resource

## Data-only authored layout contract for campaign missions that use the shared
## five-zone host. Gameplay collision and route ownership stay independent from
## replaceable presentation meshes.

@export var mission_id: StringName = &"mission"
@export var content_revision := 1
@export var intro_message := "MISSION START"
@export var victory_line := "MISSION COMPLETE"
@export var boss_display_name := "COMPLIANCE BOSS"
@export var starting_zone_id: StringName = &"zone_1"
@export var boss_zone_id: StringName = &"zone_5"
@export var boss_enemy_id: StringName = &"boss"
@export var final_activation_target: StringName = &"final_switch"
@export var permanent_upgrade_ids: Array[StringName] = []
@export var campaign_unlock_ids: Array[StringName] = []
@export var movement_environment: MovementEnvironmentProfile
@export var zones: Array[Dictionary] = []
@export var objective_switches: Array[Dictionary] = []
@export var secrets: Array[Dictionary] = []
@export var environment: Dictionary = {}
@export var landmarks: Array[Dictionary] = []
@export var lethal_volumes: Array[Dictionary] = []


func checkpoint_positions() -> Dictionary:
	var result: Dictionary = {}
	for zone in zones:
		var checkpoint_id := StringName(zone.get("checkpoint_id", &""))
		if checkpoint_id != &"":
			result[checkpoint_id] = zone.get("checkpoint_position", Vector3.ZERO)
	return result


func first_checkpoint_id() -> StringName:
	if zones.is_empty():
		return &""
	return StringName(zones[0].get("checkpoint_id", &""))


func secret_title(secret_id: StringName) -> String:
	for secret in secrets:
		if StringName(secret.get("id", &"")) == secret_id:
			return String(secret.get("title", "FOUND SECRET"))
	return "FOUND SECRET"


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if mission_id == &"": errors.append("biome mission has empty mission_id")
	if content_revision < 1: errors.append("biome mission %s has invalid content revision" % mission_id)
	if zones.size() != 5: errors.append("biome mission %s requires exactly five authored zones" % mission_id)
	var zone_ids: Dictionary = {}
	var checkpoint_ids: Dictionary = {}
	for index in range(zones.size()):
		var zone := zones[index]
		var zone_id := StringName(zone.get("id", &""))
		var checkpoint_id := StringName(zone.get("checkpoint_id", &""))
		var center: Variant = zone.get("center")
		var size: Variant = zone.get("size")
		if zone_id == &"": errors.append("biome mission %s zone %d has empty id" % [mission_id, index])
		elif zone_ids.has(zone_id): errors.append("biome mission %s duplicates zone %s" % [mission_id, zone_id])
		else: zone_ids[zone_id] = true
		if checkpoint_id == &"": errors.append("biome mission %s zone %s has empty checkpoint" % [mission_id, zone_id])
		elif checkpoint_ids.has(checkpoint_id): errors.append("biome mission %s duplicates checkpoint %s" % [mission_id, checkpoint_id])
		else: checkpoint_ids[checkpoint_id] = true
		if center is not Vector3 or not center.is_finite(): errors.append("biome mission %s zone %s has invalid center" % [mission_id, zone_id])
		if size is not Vector3 or not size.is_finite() or size.x <= 0.0 or size.z <= 0.0: errors.append("biome mission %s zone %s has invalid size" % [mission_id, zone_id])
	if not zone_ids.has(starting_zone_id): errors.append("biome mission %s starting zone is unknown" % mission_id)
	if not zone_ids.has(boss_zone_id): errors.append("biome mission %s boss zone is unknown" % mission_id)
	if movement_environment != null: errors.append_array(movement_environment.validate())
	for entry in objective_switches:
		if StringName(entry.get("id", &"")) == &"": errors.append("biome mission %s has objective switch without id" % mission_id)
		if entry.get("position") is not Vector3: errors.append("biome mission %s has objective switch without position" % mission_id)
	for entry in secrets:
		if StringName(entry.get("id", &"")) == &"": errors.append("biome mission %s has secret without id" % mission_id)
		if String(entry.get("title", "")).strip_edges().is_empty(): errors.append("biome mission %s has untitled secret" % mission_id)
	return errors
