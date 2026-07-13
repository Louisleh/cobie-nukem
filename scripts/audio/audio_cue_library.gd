class_name AudioCueLibrary
extends Resource

@export var cues: Array[AudioCueSet] = []


func cue_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for cue in cues:
		if cue != null:
			result.append(cue.id)
	return result


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for index in cues.size():
		var cue := cues[index]
		if cue == null:
			errors.append("cue %d is null" % index)
			continue
		if not cue.is_valid():
			errors.append("cue %d has an invalid contract" % index)
		if seen.has(cue.id):
			errors.append("duplicate cue id: %s" % cue.id)
		seen[cue.id] = true
		if cue.spatial:
			for stream in cue.streams:
				if stream is AudioStreamWAV and (stream as AudioStreamWAV).stereo:
					errors.append("spatial cue %s contains a stereo WAV" % cue.id)
	return errors
