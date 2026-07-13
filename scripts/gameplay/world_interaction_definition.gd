class_name WorldInteractionDefinition
extends Resource

enum Kind {
	BREAKABLE_PROP,
	EXPLOSIVE_PROP,
	HAZARD_ZONE,
	LOOT_CONTAINER,
	SECRET_TRIGGER,
}

@export var schema_version := 1
@export var id: StringName = &"interaction"
@export var kind: Kind = Kind.BREAKABLE_PROP
@export var prompt := "INTERACT"
@export var enabled := true
@export var persists_across_reset := false
@export var visual_size := Vector3(1.1, 1.1, 1.1)
@export var visual_color := Color("d18b35")
@export var surface_type: StringName = &"metal"

@export_multiline var description := ""

# Breakable configuration
@export_range(0.5, 4000.0, 0.5) var breakable_health := 35.0
@export_range(0.0, 4000.0, 0.5) var breakable_reset_health := 0.0
@export var breakable_secret_id: StringName = &""
@export var breakable_secret_title := "MAINTENANCE LOOPHOLE"

# Explosive configuration
@export_range(0.0, 12.0, 0.1) var explosive_health := 40.0
@export_range(0.2, 30.0, 0.1) var explosive_blast_radius := 4.0
@export_range(0.0, 600.0, 1.0) var explosive_damage := 70.0
@export_range(0.0, 2.0, 0.01) var detonation_delay := 0.02
@export_range(0.0, 18.0, 0.1) var chain_reaction_radius := 3.5
@export_range(0, 12, 1) var chain_reaction_limit := 3
@export_flags_3d_physics var explosive_collision_mask := 0xFFFFFFFF

# Hazard configuration
@export_range(0.05, 3.0, 0.01) var hazard_tick_seconds := 0.6
@export_range(0.0, 350.0, 0.5) var hazard_damage := 6.0
@export_range(0.0, 12.0, 0.1) var hazard_radius := 2.25

# Loot/secrets configuration
@export_file("*.tscn") var loot_scene: String = ""
@export_range(1, 8, 1) var loot_drop_count := 1
@export var secret_id: StringName = &""
@export var secret_title := "AUTHORIZATION REQUIRED"
@export var persistence_id: StringName = &""

func canonical_persistence_id() -> StringName:
	return persistence_id if persistence_id != &"" else secret_id


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("world interaction schema must be version 1")
	var trimmed_id := String(id).strip_edges()
	if trimmed_id.is_empty():
		errors.append("interaction id is empty")
	var title_text := String(prompt).strip_edges()
	if title_text.is_empty():
		errors.append("interaction %s must define an interaction prompt" % id)
	if not visual_size.is_finite() or visual_size.x <= 0.0 or visual_size.y <= 0.0 or visual_size.z <= 0.0:
		errors.append("interaction %s requires a positive finite visual size" % id)
	if surface_type == &"":
		errors.append("interaction %s requires a surface type" % id)
	match kind:
		Kind.BREAKABLE_PROP:
			if breakable_health <= 0.0:
				errors.append("breakable interaction %s needs breakable_health > 0" % id)
			if breakable_reset_health < 0.0:
				errors.append("breakable interaction %s has invalid breakable_reset_health" % id)
		Kind.EXPLOSIVE_PROP:
			if explosive_health < 0.0:
				errors.append("explosive interaction %s has negative health threshold" % id)
			if explosive_blast_radius <= 0.0:
				errors.append("explosive interaction %s has invalid blast radius" % id)
			if explosive_damage < 0.0:
				errors.append("explosive interaction %s has invalid blast damage" % id)
			if detonation_delay < 0.0:
				errors.append("explosive interaction %s has negative detonation delay" % id)
			if chain_reaction_radius < 0.0:
				errors.append("explosive interaction %s has invalid chain reaction radius" % id)
			if chain_reaction_limit < 0:
				errors.append("explosive interaction %s has invalid chain reaction limit" % id)
			if explosive_collision_mask == 0:
				errors.append("explosive interaction %s requires a non-zero collision mask" % id)
		Kind.HAZARD_ZONE:
			if hazard_tick_seconds <= 0.0:
				errors.append("hazard interaction %s requires hazard_tick_seconds > 0" % id)
			if hazard_damage <= 0.0:
				errors.append("hazard interaction %s requires hazard_damage > 0" % id)
			if hazard_radius <= 0.0:
				errors.append("hazard interaction %s requires hazard_radius > 0" % id)
		Kind.LOOT_CONTAINER:
			if loot_scene.is_empty():
				errors.append("loot container %s requires a valid loot_scene" % id)
			elif not ResourceLoader.exists(loot_scene):
				errors.append("loot container %s references missing loot_scene: %s" % [id, loot_scene])
			if loot_drop_count <= 0:
				errors.append("loot container %s requires loot_drop_count > 0" % id)
		Kind.SECRET_TRIGGER:
			var secret_name := String(secret_id).strip_edges()
			if secret_name.is_empty():
				errors.append("secret trigger %s requires secret_id" % id)
			if secret_title.strip_edges().is_empty():
				errors.append("secret trigger %s requires secret_title" % id)
			if persists_across_reset and String(persistence_id).strip_edges().is_empty():
				errors.append("secret trigger %s requires persistence_id when persists_across_reset is true" % id)
		_:
			errors.append("interaction %s has unknown kind %s" % [id, kind])
	if persists_across_reset and kind != Kind.SECRET_TRIGGER:
		errors.append("interaction %s only secret triggers can persist across reset" % id)
	return errors


func starting_health() -> float:
	if kind == Kind.EXPLOSIVE_PROP:
		return explosive_health
	return breakable_reset_health if breakable_reset_health > 0.0 else breakable_health
