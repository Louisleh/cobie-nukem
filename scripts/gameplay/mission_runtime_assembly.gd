class_name MissionRuntimeAssembly
extends RefCounted

## Shared mission host wiring. Mission controllers retain narrative sequencing and
## set pieces; this helper owns no mission-specific ids or behavior.

static func create(host: Node, manifest: ContentManifest, spawn_scene: Callable) -> Dictionary:
	var registry := MissionSpawnRegistry.new()
	registry.name = "MissionSpawnRegistry"
	host.add_child(registry)
	registry.prewarm_encounters(manifest.encounters)
	if host.has_method("_on_pickup_collected"):
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
