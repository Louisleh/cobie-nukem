extends SceneTree

const CATALOG_PATH := "res://resources/interactions/vancouver_waterfront_interactions.tres"
const ROUTE_PATH := "res://resources/routes/vancouver_route_definition.tres"
const EXPECTED_LEVEL_ID := &"episode_1_vancouver_waterfront"
const CANONICAL_ZONES := [
	&"downtown_alley",
	&"ruse_block",
	&"waterfront_seawall",
	&"terminal_service",
	&"harbour_pier",
]
const EXPECTED_PERSISTENT_SECRETS := [
	&"secret_downtown_alley",
	&"secret_ruse_block",
	&"secret_waterfront_seawall",
	&"secret_terminal_service",
]
const FORBIDDEN_ID_FRAGMENT := "citation_drive"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(CATALOG_PATH) as InteractionCatalog
	var route := load(ROUTE_PATH) as MissionRouteDefinition
	_expect(catalog != null, "Vancouver waterfront catalog loads")
	_expect(route != null, "Vancouver route definition loads")
	if catalog == null or route == null:
		_finish()
		return

	_test_schema_contract(catalog)
	_test_zone_density(catalog)
	_test_transform_and_zone_bounds(catalog, route)
	_test_asset_and_effect_bounds(catalog)
	_test_secret_and_persistence_contracts(catalog)
	_test_runtime_reset_and_restore_contract(catalog)
	_finish()


func _test_schema_contract(catalog: InteractionCatalog) -> void:
	var allowed_zones: Array[StringName] = route_zone_ids()
	_expect(catalog.level_id == EXPECTED_LEVEL_ID, "Catalog level_id is stable and targetable")
	var validation := catalog.validate(allowed_zones, EXPECTED_LEVEL_ID)
	_expect(validation.is_empty(), "Catalog self validation has no errors")
	if validation.size() > 0:
		for error in validation:
			push_warning("Catalog validation detail: %s" % error)


func _test_zone_density(catalog: InteractionCatalog) -> void:
	var counts := {}
	for placement in catalog.placements:
		if placement == null:
			_expect(false, "Catalog does not contain null placement")
			continue
		var zone_key := String(placement.zone_id)
		counts[zone_key] = int(counts.get(zone_key, 0)) + 1
		var trimmed := String(placement.id).strip_edges()
		_expect(trimmed.length() > 0, "Placement has stable non-empty id")
		_expect(not zone_key.contains(FORBIDDEN_ID_FRAGMENT), "Placement %s excludes set-piece-owned forbidden ids" % trimmed)
		var route_contains := false
		for zone_id in CANONICAL_ZONES:
			if zone_key == String(zone_id):
				route_contains = true
				break
		_expect(route_contains, "Placement %s uses canonical Vancouver zone id %s" % [trimmed, zone_key])

	var seen_ids := {}
	for placement in catalog.placements:
		if placement == null:
			continue
		var placement_id := String(placement.id).strip_edges()
		_expect(not seen_ids.has(placement_id), "Placement ids are unique: %s" % placement_id)
		if not placement_id.is_empty():
			seen_ids[placement_id] = true

	for zone_id in CANONICAL_ZONES:
		var observed := int(counts.get(String(zone_id), 0))
		_expect(observed >= 3, "Zone %s has at least the minimum 3 placements" % zone_id)
		_expect(observed <= 4, "Zone %s has no extra placements above expected 4-slot intent" % zone_id)


func _test_transform_and_zone_bounds(catalog: InteractionCatalog, route: MissionRouteDefinition) -> void:
	var zone_map := {}
	for zone in route.zones:
		if zone != null:
			zone_map[String(zone.zone_id)] = zone

	for placement in catalog.placements:
		if placement == null:
			continue
		var zone := zone_map.get(String(placement.zone_id), null) as MissionRouteZone
		_expect(zone != null, "Placement %s resolves a route zone" % String(placement.id))
		if zone == null:
			continue
		var bounds := zone.bounds as AABB
		_expect(_aabb_contains_point(bounds, placement.transform.origin), "Placement %s lies inside authored bounds" % String(placement.id))
		_expect(is_finite(placement.transform.origin.x) and is_finite(placement.transform.origin.y) and is_finite(placement.transform.origin.z), "Placement %s transform origin is finite" % String(placement.id))
		_expect(placement.transform.origin.y >= 0.0 and placement.transform.origin.y <= 2.0, "Placement %s has floor-correct height" % String(placement.id))
		var scale := Vector3(
			placement.transform.basis.x.length(),
			placement.transform.basis.y.length(),
			placement.transform.basis.z.length()
		)
		_expect(scale.x > 0.0 and scale.y > 0.0 and scale.z > 0.0, "Placement %s has valid non-zero scale" % String(placement.id))


func _test_asset_and_effect_bounds(catalog: InteractionCatalog) -> void:
	for placement in catalog.placements:
		if placement == null or placement.definition == null:
			continue
		var definition: WorldInteractionDefinition = placement.definition
		var definition_errors := definition.validate()
		_expect(definition_errors.is_empty(), "Placement %s has valid definition parameters" % String(placement.id))
		if definition_errors.size() > 0:
			continue

		match definition.kind:
			WorldInteractionDefinition.Kind.BREAKABLE_PROP:
				_expect(definition.breakable_health > 0.0 and definition.breakable_health <= 400.0, "Breakable %s has bounded health" % definition.id)
				_expect(definition.breakable_reset_health >= 0.0 and definition.breakable_reset_health <= definition.breakable_health, "Breakable %s reset health is bounded" % definition.id)
			WorldInteractionDefinition.Kind.EXPLOSIVE_PROP:
				_expect(definition.explosive_health >= 0.0 and definition.explosive_health <= 200.0, "Explosive %s has bounded damage" % definition.id)
				_expect(definition.explosive_damage >= 1.0 and definition.explosive_damage <= 100.0, "Explosive %s has bounded blast power" % definition.id)
				_expect(definition.explosive_blast_radius >= 0.5 and definition.explosive_blast_radius <= 8.0, "Explosive %s has bounded blast radius" % definition.id)
				_expect(definition.chain_reaction_radius <= 8.0 and definition.chain_reaction_limit <= 3, "Explosive %s has bounded chain settings" % definition.id)
				_expect(definition.explosive_collision_mask != 0, "Explosive %s uses non-zero collision mask" % definition.id)
			WorldInteractionDefinition.Kind.HAZARD_ZONE:
				_expect(definition.hazard_damage > 0.0 and definition.hazard_damage <= 80.0, "Hazard %s has bounded damage" % definition.id)
				_expect(definition.hazard_radius >= 0.5 and definition.hazard_radius <= 6.0, "Hazard %s has bounded radius" % definition.id)
				_expect(definition.hazard_tick_seconds >= 0.25 and definition.hazard_tick_seconds <= 2.0, "Hazard %s has bounded tick timing" % definition.id)
			WorldInteractionDefinition.Kind.LOOT_CONTAINER:
				_expect(definition.loot_scene != "", "Loot %s has a pickup scene" % definition.id)
				_expect(ResourceLoader.exists(definition.loot_scene), "Loot %s scene resolves in resource loader" % definition.id)
				if ResourceLoader.exists(definition.loot_scene):
					_expect(ResourceLoader.load(definition.loot_scene) is PackedScene, "Loot %s resolves as PackedScene" % definition.id)
				_expect(definition.loot_drop_count >= 1 and definition.loot_drop_count <= 8, "Loot %s uses bounded count" % definition.id)
			WorldInteractionDefinition.Kind.SECRET_TRIGGER:
				_expect(definition.secret_id != &"", "Secret %s has secret id" % definition.id)
				_expect(definition.secret_title.strip_edges() != "", "Secret %s has secret title" % definition.id)
				if definition.persists_across_reset:
					_expect(definition.persistence_id != &"", "Secret %s sets persistence_id for persistence restore" % definition.id)
					_expect(definition.persistence_id == definition.secret_id, "Secret %s uses canonical persistence ID" % definition.id)
					if definition.persistence_id != definition.secret_id:
						push_warning("Secret %s canonical id mismatch" % definition.id)
				else:
					pass
				_expect(not String(definition.secret_id).contains(FORBIDDEN_ID_FRAGMENT), "Secret %s excludes set-piece module ids" % definition.id)
				if definition.persistence_id != &"":
					_expect(not String(definition.persistence_id).contains(FORBIDDEN_ID_FRAGMENT), "Secret %s excludes forbidden persistence id" % definition.id)
			_:
				_expect(false, "Unknown interaction kind present in %s" % definition.id)


func _test_secret_and_persistence_contracts(catalog: InteractionCatalog) -> void:
	var route := load(ROUTE_PATH) as MissionRouteDefinition
	var route_secret_ids := {}
	var secret_by_zone := {}
	for zone in route.zones:
		if zone == null:
			continue
		for sid in zone.secret_ids:
			route_secret_ids[String(sid)] = true
	var persistent_ids: Dictionary = {}
	var persistent_count := 0
	var secret_count := 0
	for placement in catalog.placements:
		if placement == null or placement.definition == null:
			continue
		var definition: WorldInteractionDefinition = placement.definition
		if definition.kind == WorldInteractionDefinition.Kind.SECRET_TRIGGER:
			secret_count += 1
			var secret_id := String(definition.secret_id)
			_expect(secret_id != "", "Secret placement %s has route secret id" % String(placement.id))
			_expect(route_secret_ids.has(secret_id), "Secret %s aligns to route secret id list" % definition.id)
			if definition.persists_across_reset:
				persistent_count += 1
				persistent_ids[secret_id] = true
				secret_by_zone[String(placement.zone_id)] = definition.id
				_expect(definition.persistence_id == definition.secret_id, "Persistent secret %s persistence id is canonical" % definition.id)

			var duplicate := _contains_definition_by_value(secret_id, secret_by_zone)
			if duplicate:
				_expect(false, "Secret %s duplicates secret id %s" % [definition.id, definition.secret_id])

	_expect(secret_count >= 4, "Catalog has at least four secret placements")
	_expect(persistent_count == EXPECTED_PERSISTENT_SECRETS.size(), "Catalog has exactly four persistent secrets")
	for expected_secret in EXPECTED_PERSISTENT_SECRETS:
		_expect(persistent_ids.get(String(expected_secret), false), "Expected persistent secret id exists: %s" % expected_secret)
	_expect(persistent_ids.size() == EXPECTED_PERSISTENT_SECRETS.size(), "Persistent secret ID set size is exact")


func _test_runtime_reset_and_restore_contract(catalog: InteractionCatalog) -> void:
	var runtime := MissionInteractionRuntime.new()
	var parent := Node3D.new()
	var manifest := ContentManifest.new()
	manifest.level_id = EXPECTED_LEVEL_ID
	manifest.interaction_catalog = catalog
	root.add_child(parent)
	root.add_child(runtime)
	var configured := runtime.configure(manifest, parent)
	_expect(configured, "Runtime configures with Vancouver catalog")
	if not configured:
		runtime.queue_free()
		parent.free()
		return

	var interactions := runtime.interaction_nodes()
	_expect(interactions.size() == catalog.placements.size(), "Runtime spawns an interaction node for each placement")

	var secrets_by_placement := {}
	var secrets_triggered := {}
	var persisted_payload := {}
	for interaction in interactions:
		if interaction.definition == null:
			continue
		var definition: WorldInteractionDefinition = interaction.definition
		if definition.kind != WorldInteractionDefinition.Kind.SECRET_TRIGGER:
			continue
		var placement_id := String(definition.id)
		secrets_by_placement[placement_id] = interaction
		interaction.secret_requested.connect(_on_secret_interaction.bind(placement_id, secrets_triggered))
		if definition.persists_across_reset and String(definition.secret_id) != "":
			persisted_payload[String(definition.secret_id)] = definition.secret_title

	for interaction in secrets_by_placement.values():
		var node := interaction as WorldInteraction
		if node != null:
			node.interact(null)
			expect_true(node.is_active(), "Secret interaction %s can activate on first interaction" % node.definition.id)
			# second interaction must be idempotent
			node.interact(null)
			expect_true(secrets_triggered.get(String(node.definition.id), 0) == 1, "Secret interaction %s emits exactly once" % node.definition.id)

	runtime.reset_for_checkpoint({"secrets": persisted_payload})
	for interaction in secrets_by_placement.values():
		var node := interaction as WorldInteraction
		if node != null and node.definition != null:
			if node.definition.persists_across_reset:
				expect_true(node.is_active(), "Persistent secret %s restores from checkpoint payload" % node.definition.id)

	runtime.reset_for_checkpoint({"secrets": {}})
	for interaction in secrets_by_placement.values():
		var node := interaction as WorldInteraction
		if node != null and node.definition != null and node.definition.persists_across_reset:
			expect_true(node.is_active(), "Persistent in-run secret %s remains completed when checkpoint omits it" % node.definition.id)

	runtime.reset_for_checkpoint({"secrets": persisted_payload})
	for interaction in secrets_by_placement.values():
		var node := interaction as WorldInteraction
		if node != null and node.definition != null and node.definition.persists_across_reset:
			expect_true(node.is_active(), "Persistent secret %s re-restores from checkpoint payload")

	runtime.clear()
	parent.free()
	runtime.queue_free()


func _on_secret_interaction(_secret_id: StringName, _title: String, _source: Node, placement_id: String, captured: Dictionary) -> void:
	captured[placement_id] = int(captured.get(placement_id, 0)) + 1


func _contains_definition_by_value(id: String, source: Dictionary) -> bool:
	return source.get(id, null) != null


func expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect(value: bool, message: String) -> void:
	expect_true(value, message)


func route_zone_ids() -> Array[StringName]:
	var route := load(ROUTE_PATH) as MissionRouteDefinition
	if route == null:
		return CANONICAL_ZONES
	return route.ordered_zone_ids()


func _aabb_contains_point(bounds: AABB, point: Vector3) -> bool:
	var max_corner := bounds.position + bounds.size
	return point.x >= bounds.position.x and point.y >= bounds.position.y and point.z >= bounds.position.z and point.x <= max_corner.x and point.y <= max_corner.y and point.z <= max_corner.z


func _finish() -> void:
	if failures.is_empty():
		print("VANCOUVER INTERACTION CATALOG TEST: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
