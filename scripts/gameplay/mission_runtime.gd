class_name MissionRuntime
extends Node

## Reusable mission truth. Level scripts author narrative and geometry; this node
## owns objective/encounter lifecycle and the checkpoint-safe snapshot contract.

var objectives: ObjectiveTracker
var encounters: EncounterRunner


func configure(manifest: ContentManifest, spawner: Callable) -> void:
	objectives = ObjectiveTracker.new()
	objectives.name = "ObjectiveTracker"
	add_child(objectives)
	objectives.configure(manifest.objectives if manifest != null else [])
	encounters = EncounterRunner.new()
	encounters.name = "EncounterRunner"
	add_child(encounters)
	encounters.configure(manifest.encounters if manifest != null else [], spawner)


func snapshot() -> Dictionary:
	return {
		"objective_snapshot": objectives.snapshot(),
		"encounter_snapshot": encounters.snapshot(),
	}


func restore(data: Dictionary) -> void:
	objectives.restore(data.get("objective_snapshot", {}))
	encounters.restore(data.get("encounter_snapshot", {}))
