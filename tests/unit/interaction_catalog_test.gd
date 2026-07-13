extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_valid_catalog()
	_test_invalid_catalog_catches_structural_errors()
	_test_manifest_consumes_catalog()
	if failures.is_empty():
		print("INTERACTION CATALOG TESTS: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_valid_catalog() -> void:
	var catalog := _load_catalog()
	if catalog == null:
		_expect(false, "salmon interaction catalog loads")
		return
	var zones: Array[StringName] = [
		&"forbidden_field",
		&"equipment_shed",
		&"maintenance_tunnels",
		&"compliance_lab",
		&"walker_arena",
	]
	_expect(catalog.validate(zones, &"episode_1_level_1").is_empty(), "valid interaction catalog validates")
	_expect(catalog.placements.size() >= 15, "salmon interaction catalog has at least 15 placements")
	var by_zone := {}
	for placement in catalog.placements:
		by_zone[String(placement.zone_id)] = int(by_zone.get(String(placement.zone_id), 0)) + 1
	for zone_id in zones:
		_expect(int(by_zone.get(String(zone_id), 0)) >= 3, "at least three interactions in %s" % zone_id)


func _test_invalid_catalog_catches_structural_errors() -> void:
	var catalog := _load_catalog()
	if catalog == null:
		_expect(false, "salmon interaction catalog loads for invalid-case checks")
		return

	var shared_zone_ids := catalog.placements[0].zone_id
	var baseline_definition := catalog.placements[0].definition

	var duplicate := InteractionPlacement.new()
	duplicate.id = &"duplicate_placement"
	duplicate.zone_id = shared_zone_ids
	duplicate.definition = baseline_definition
	duplicate.schema_version = 1

	var second := InteractionPlacement.new()
	second.id = &"duplicate_placement"
	second.zone_id = shared_zone_ids
	second.definition = baseline_definition
	second.schema_version = 1

	var zone_minimums := catalog.required_zone_minimums
	var duplicate_catalog := InteractionCatalog.new()
	duplicate_catalog.level_id = &"episode_1_level_1"
	duplicate_catalog.required_zone_minimums = zone_minimums
	duplicate_catalog.placements = [duplicate, second]
	var duplicate_allowed_zones: Array[StringName] = [&"forbidden_field", &"equipment_shed"]
	var duplicate_errors := duplicate_catalog.validate(duplicate_allowed_zones, &"episode_1_level_1")
	_expect(_contains_error(duplicate_errors, "duplicate interaction placement id"), "duplicate placement ids are rejected")

	var missing_zone := InteractionPlacement.new()
	missing_zone.id = &"missing_zone"
	missing_zone.definition = baseline_definition
	missing_zone.zone_id = &""
	var missing_zone_catalog := InteractionCatalog.new()
	missing_zone_catalog.level_id = &"episode_1_level_1"
	missing_zone_catalog.placements = [missing_zone]
	var missing_zone_allowed_zones: Array[StringName] = [&"forbidden_field"]
	var zone_errors := missing_zone_catalog.validate(missing_zone_allowed_zones, &"episode_1_level_1")
	_expect(_contains_error(zone_errors, "empty zone_id"), "missing zone_id is rejected")

	var invalid_transform := InteractionPlacement.new()
	invalid_transform.id = &"invalid_transform"
	invalid_transform.zone_id = &"forbidden_field"
	invalid_transform.definition = baseline_definition
	var nan := 0.0 / 0.0
	invalid_transform.transform.origin = Vector3(nan, 0.0, 0.0)
	var invalid_transform_catalog := InteractionCatalog.new()
	invalid_transform_catalog.level_id = &"episode_1_level_1"
	invalid_transform_catalog.placements = [invalid_transform]
	var transform_allowed_zones: Array[StringName] = [&"forbidden_field"]
	var transform_errors := invalid_transform_catalog.validate(transform_allowed_zones, &"episode_1_level_1")
	_expect(_contains_error(transform_errors, "non-finite transform"), "non-finite transform is rejected")

	var missing_definition := InteractionPlacement.new()
	missing_definition.id = &"missing_definition"
	missing_definition.zone_id = &"forbidden_field"
	missing_definition.schema_version = 1
	var missing_definition_catalog := InteractionCatalog.new()
	missing_definition_catalog.level_id = &"episode_1_level_1"
	missing_definition_catalog.placements = [missing_definition]
	var missing_definition_allowed_zones: Array[StringName] = [&"forbidden_field"]
	var definition_errors := missing_definition_catalog.validate(missing_definition_allowed_zones, &"episode_1_level_1")
	_expect(_contains_error(definition_errors, "missing definition"), "missing definition is rejected")

	var underfilled := InteractionCatalog.new()
	underfilled.level_id = &"episode_1_level_1"
	underfilled.required_zone_minimums = zone_minimums
	underfilled.placements = catalog.placements.slice(0, 3)
	var underfilled_allowed_zones: Array[StringName] = [&"forbidden_field", &"equipment_shed", &"maintenance_tunnels", &"compliance_lab", &"walker_arena"]
	var underfilled_errors := underfilled.validate(underfilled_allowed_zones, &"episode_1_level_1")
	_expect(_contains_error(underfilled_errors, "requires at least 3 placements"), "below-minimum zone density is rejected")


func _test_manifest_consumes_catalog() -> void:
	var manifest := load("res://resources/content/salmon_creek_manifest.tres") as ContentManifest
	_expect(manifest != null, "salmon creek manifest loads")
	if manifest == null: return
	_expect(manifest.interaction_catalog != null, "salmon creek manifest owns an interaction catalog")
	_expect(manifest.validate().is_empty(), "salmon creek manifest validation consumes catalog")


func _load_catalog() -> InteractionCatalog:
	return load("res://resources/interactions/salmon_creek_interactions.tres") as InteractionCatalog


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if String(error).find(fragment) != -1:
			return true
	return false


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
