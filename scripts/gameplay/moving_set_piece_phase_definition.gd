class_name MovingSetPiecePhaseDefinition
extends Resource

@export var schema_version := 2
@export var phase_id: StringName = &"phase"
@export_range(0.0, 1.0, 0.001) var stop_marker := 0.0
@export var encounter_wave_index := 0
@export var encounter_id: StringName = &""
@export var required_module_id: StringName = &""
@export var display_caption := "PHASE"
@export_range(0.0, 1.0, 0.01) var music_intensity := 0.35
@export_range(0.0, 1000.0, 1.0) var health_allocation := 250.0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 2:
		errors.append("moving_set_piece_phase_definition %s has unsupported schema_version %d" % [phase_id, schema_version])
	if String(phase_id).strip_edges().is_empty():
		errors.append("moving_set_piece_phase_definition has empty phase_id")
	if not is_finite(stop_marker) or stop_marker < 0.0 or stop_marker > 1.0:
		errors.append("moving_set_piece_phase_definition %s stop_marker must be finite in [0.0, 1.0]" % phase_id)
	if encounter_wave_index < 0:
		errors.append("moving_set_piece_phase_definition %s has negative encounter_wave_index" % phase_id)
	if encounter_id == &"":
		errors.append("moving_set_piece_phase_definition %s has empty encounter_id" % phase_id)
	if required_module_id == &"":
		errors.append("moving_set_piece_phase_definition %s has empty required_module_id" % phase_id)
	if String(display_caption).strip_edges().is_empty():
		errors.append("moving_set_piece_phase_definition %s has empty display_caption" % phase_id)
	if not is_finite(health_allocation) or health_allocation <= 0.0:
		errors.append("moving_set_piece_phase_definition %s has invalid health_allocation" % phase_id)
	if not is_finite(music_intensity) or music_intensity < 0.0 or music_intensity > 1.0:
		errors.append("moving_set_piece_phase_definition %s music_intensity must be in [0.0, 1.0]" % phase_id)
	return errors
