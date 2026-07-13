class_name AudioCueSet
extends Resource

## Imported-sample authoring contract. Short WAV cues stay low-latency on Web;
## spatial cues must be mono and are played through bounded 3D voice pools.

@export var id: StringName
@export var streams: Array[AudioStream] = []
@export var bus: StringName = &"SFX"
@export_range(-40.0, 12.0, 0.5) var volume_db := 0.0
@export_range(0.5, 2.0, 0.01) var pitch_min := 0.96
@export_range(0.5, 2.0, 0.01) var pitch_max := 1.04
@export_range(1, 16, 1) var maximum_polyphony := 4
@export var prevent_immediate_repeat := true
@export var spatial := false
@export_range(1.0, 100.0, 0.5) var max_distance := 28.0
@export_range(0.1, 20.0, 0.1) var unit_size := 3.0

var _last_index := -1


func choose_stream() -> AudioStream:
	if streams.is_empty(): return null
	var index := randi_range(0, streams.size() - 1)
	if prevent_immediate_repeat and streams.size() > 1 and index == _last_index:
		index = (index + 1) % streams.size()
	_last_index = index
	return streams[index]


func is_valid() -> bool:
	return id != &"" and not streams.is_empty() and maximum_polyphony > 0 and pitch_min > 0.0 and pitch_max >= pitch_min
