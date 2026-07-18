class_name RainCityMissionAssembly
extends RefCounted


static func create_runtime(host: Node, manifest: ContentManifest, spawn_scene: Callable) -> Dictionary:
	return MissionRuntimeAssembly.create(host, manifest, spawn_scene)


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
