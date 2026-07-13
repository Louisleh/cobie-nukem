class_name MissionInteractionRuntime
extends Node

## Runtime owner for catalog-driven world interactions in a mission.
## Responsible for validating catalog/configuration, constructing interaction
## nodes, wiring interaction callbacks, and applying checkpoint restores.

signal loot_requested(loot_scene: String, count: int, source: Node)
signal secret_requested(secret_id: StringName, title: String, source: Node)

const MIN_LOOT_DROP_COUNT := 1
const MAX_LOOT_DROP_COUNT := 8

var _interactions: Dictionary = {}
var _restored_secrets: Dictionary = {}


func configure(manifest: ContentManifest, interactable_parent: Node3D, spawn_registry: MissionSpawnRegistry = null) -> bool:
	_interactions.clear()
	_restored_secrets.clear()
	if manifest == null:
		push_error("MissionInteractionRuntime: content manifest missing")
		return false
	if manifest.interaction_catalog == null:
		push_warning("MissionInteractionRuntime: content manifest does not include an interaction catalog")
		return false
	if interactable_parent == null:
		push_error("MissionInteractionRuntime: interaction parent node is missing")
		return false

	var catalog: InteractionCatalog = manifest.interaction_catalog
	var zone_ids: Array[StringName] = []
	for encounter: EncounterDefinition in manifest.encounters:
		if encounter != null and encounter.zone_id != &"":
			zone_ids.append(encounter.zone_id)
	if zone_ids.is_empty():
		for placement: InteractionPlacement in catalog.placements:
			zone_ids.append(placement.zone_id)
	var errors := catalog.validate(zone_ids, manifest.level_id)
	if not errors.is_empty():
		for issue in errors:
			push_error("MissionInteractionRuntime catalog validation failed: %s" % issue)
		return false

	var spawned: Dictionary = {}
	for placement in catalog.placements:
		var interaction := _spawn_interaction(placement as InteractionPlacement, interactable_parent)
		if interaction == null:
			for active in spawned.values():
				active.queue_free()
			_interactions.clear()
			push_error("MissionInteractionRuntime failed during construction; no interactions were placed")
			return false
		spawned[String(interaction.definition.id)] = interaction
		_interactions[String(interaction.definition.id)] = interaction
		if spawn_registry != null:
			spawn_registry.register_critical(interaction.definition.id, interaction)
	return true


func configure_from_payload(manifest: ContentManifest, interactable_parent: Node3D, checkpoint_payload: Dictionary, spawn_registry: MissionSpawnRegistry = null) -> bool:
	var configured := configure(manifest, interactable_parent, spawn_registry)
	if configured:
		restore_checkpoint_secrets(checkpoint_payload.get("secrets", {}))
	return configured


func reset_for_checkpoint(raw_checkpoint: Dictionary = {}) -> void:
	_apply_checkpoint_secrets(raw_checkpoint.get("secrets", {}))
	for interaction in _interactions.values():
		var world_interaction := interaction as WorldInteraction
		if world_interaction == null or world_interaction.definition == null or not is_instance_valid(world_interaction):
			continue
		if world_interaction.definition.kind == WorldInteractionDefinition.Kind.SECRET_TRIGGER:
			# Secrets are restored through deterministic checkpoint payloads, then kept active.
			if _is_secret_restored(world_interaction.definition.secret_id):
				_restore_secret_interaction(world_interaction)
			else:
				world_interaction.reset_interaction()
			continue
		world_interaction.reset_interaction()


func interaction_nodes() -> Array[WorldInteraction]:
	var result: Array[WorldInteraction] = []
	for interaction in _interactions.values():
		var world_interaction := interaction as WorldInteraction
		if world_interaction != null and is_instance_valid(world_interaction):
			result.append(world_interaction)
	return result


func interaction_count() -> int:
	return _interactions.size()


func interaction_for_id(placement_id: StringName) -> WorldInteraction:
	return _interactions.get(String(placement_id), null)


func restore_checkpoint_secrets(raw_secrets: Dictionary) -> void:
	_apply_checkpoint_secrets(raw_secrets)
	for interaction in _interactions.values():
		var world_interaction := interaction as WorldInteraction
		if world_interaction == null or not is_instance_valid(world_interaction):
			continue
		if world_interaction.definition == null or world_interaction.definition.kind != WorldInteractionDefinition.Kind.SECRET_TRIGGER:
			continue
		if _is_secret_restored(world_interaction.definition.secret_id):
			_restore_secret_interaction(world_interaction)


func clear() -> void:
	for interaction in _interactions.values():
		var world_interaction := interaction as WorldInteraction
		if world_interaction != null and is_instance_valid(world_interaction):
			world_interaction.queue_free()
	_interactions.clear()
	_restored_secrets.clear()


func _spawn_interaction(placement: InteractionPlacement, parent: Node3D) -> WorldInteraction:
	if placement == null:
		push_error("MissionInteractionRuntime placement is null")
		return null
	if placement.definition == null:
		push_error("MissionInteractionRuntime placement %s has no definition" % placement.id)
		return null

	var placement_id := String(placement.id).strip_edges()
	if placement_id.is_empty():
		push_error("MissionInteractionRuntime placement id is empty")
		return null
	if _interactions.has(placement_id):
		push_error("MissionInteractionRuntime duplicate placement id: %s" % placement_id)
		return null

	var definition := placement.definition.duplicate(true) as WorldInteractionDefinition
	if definition == null:
		push_error("MissionInteractionRuntime could not duplicate definition for %s" % placement_id)
		return null
	definition.id = StringName(placement_id)

	var interaction := WorldInteraction.new()
	interaction.name = "Interaction_%s" % placement_id
	interaction.definition = definition
	interaction.transform = placement.transform
	interaction.secret_requested.connect(_on_secret_requested)
	interaction.loot_requested.connect(_on_loot_requested.bind(interaction))
	parent.add_child(interaction)
	return interaction


func _on_secret_requested(secret_id: StringName, title: String, _source: Node) -> void:
	secret_requested.emit(secret_id, title, _source)


func _on_loot_requested(loot_scene: String, count: int, _actor: Node, source: Node) -> void:
	loot_requested.emit(loot_scene, clampi(count, MIN_LOOT_DROP_COUNT, MAX_LOOT_DROP_COUNT), source)


func _apply_checkpoint_secrets(raw_secrets: Variant) -> void:
	_restored_secrets.clear()
	if raw_secrets is not Dictionary:
		return
	for raw_id: Variant in raw_secrets:
		var secret_id := String(raw_id).strip_edges()
		if not secret_id.is_empty() and raw_secrets[raw_id] is String:
			_restored_secrets[secret_id] = true


func _is_secret_restored(secret_id: StringName) -> bool:
	return _restored_secrets.has(String(secret_id).strip_edges())


func _restore_secret_interaction(interaction: WorldInteraction) -> void:
	if interaction.definition == null:
		return
	var definition := interaction.definition as WorldInteractionDefinition
	var secret_id := definition.secret_id
	if String(secret_id).strip_edges().is_empty():
		return
	interaction.definition.persists_across_reset = true
	interaction.restore_state({
		"id": String(definition.id),
		"kind": int(definition.kind),
		"activated": true
	})
