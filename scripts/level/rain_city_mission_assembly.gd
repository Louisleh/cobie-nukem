class_name RainCityMissionAssembly
extends RefCounted


static func create_runtime(host: Node, manifest: ContentManifest, spawn_scene: Callable) -> Dictionary:
	var registry := MissionSpawnRegistry.new()
	registry.name = "MissionSpawnRegistry"
	host.add_child(registry)
	registry.prewarm_encounters(manifest.encounters)
	registry.pickup_collected.connect(host._on_pickup_collected)
	var runtime := MissionRuntime.new()
	runtime.name = "MissionRuntime"
	host.add_child(runtime)
	runtime.configure(manifest, spawn_scene)
	runtime.objective_activated.connect(host._on_objective_activated)
	runtime.objective_completed.connect(host._on_objective_completed)
	runtime.actor_spawned.connect(host._on_actor_spawned)
	runtime.actor_defeated.connect(host._on_actor_defeated)
	runtime.encounter_completed.connect(host._on_encounter_completed)
	runtime.encounter_failed.connect(host._on_encounter_failed)
	var route_timer := Timer.new()
	route_timer.name = "RouteRecoveryTimer"
	route_timer.wait_time = 0.2
	route_timer.timeout.connect(host._poll_route_position)
	host.add_child(route_timer)
	route_timer.start()
	var completion_timer := Timer.new()
	completion_timer.name = "CompletionTimer"
	completion_timer.one_shot = true
	completion_timer.wait_time = 1.2
	completion_timer.timeout.connect(host._finalize_completion)
	host.add_child(completion_timer)
	return {"registry": registry, "runtime": runtime, "route_timer": route_timer, "completion_timer": completion_timer}


static func create_convoy(host: Node, definition: MovingSetPieceDefinition, actor_parent: Node, mission_runtime: MissionRuntime) -> Dictionary:
	var runtime := MovingSetPieceRuntime.new()
	runtime.name = "CitationConvoyRuntime"
	host.add_child(runtime)
	var configure_error := runtime.configure(definition, actor_parent)
	if configure_error != MovingSetPieceRuntime.ERROR_NONE:
		push_error("Citation convoy runtime rejected its definition: %s" % configure_error)
		return {}
	var coordinator := MovingSetPieceEncounterCoordinator.new()
	coordinator.name = "CitationConvoyCoordinator"
	host.add_child(coordinator)
	var coordinator_error := coordinator.configure(runtime, mission_runtime, definition, &"harbour_pier")
	if coordinator_error != MovingSetPieceEncounterCoordinator.ERROR_NONE:
		push_error("Citation convoy coordinator rejected its definition: %s" % coordinator_error)
		return {}
	var presentation := RainCityConvoyPresentation.new()
	presentation.name = "RainCityConvoyPresentation"
	host.add_child(presentation)
	presentation.configure(runtime, coordinator, mission_runtime)
	presentation.boss_state_changed.connect(host.boss_state_changed.emit)
	presentation.boss_phase_caption.connect(host.boss_phase_caption.emit)
	presentation.narrative_message.connect(host.narrative_message.emit)
	return {"runtime": runtime, "coordinator": coordinator, "presentation": presentation}
