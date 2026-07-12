class_name AudioCueSet
extends Resource

## Imported-sample authoring contract. ProceduralAudio remains a temporary
## fallback until every production cue has a licensed, manifested sample set.

@export var id: StringName
@export var streams: Array[AudioStream] = []
@export var bus: StringName = &"SFX"
@export_range(-40.0, 12.0, 0.5) var volume_db := 0.0
@export_range(0.5, 2.0, 0.01) var pitch_min := 0.96
@export_range(0.5, 2.0, 0.01) var pitch_max := 1.04
@export_range(1, 16, 1) var maximum_polyphony := 4
@export var prevent_immediate_repeat := true

var _last_index := -1


func choose_stream() -> AudioStream:
	if streams.is_empty(): return null
	var index := randi_range(0, streams.size() - 1)
	if prevent_immediate_repeat and streams.size() > 1 and index == _last_index:
		index = (index + 1) % streams.size()
	_last_index = index
	return streams[index]
