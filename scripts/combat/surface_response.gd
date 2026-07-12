class_name SurfaceResponse
extends Resource

@export var id := &"default"
@export var impact_color := Color("ffd166")
@export var impact_scale := 1.0
@export var impulse_scale := 1.0
@export_range(0.05, 5.0, 0.05) var lifetime_seconds := 0.3
@export var sound_set := &"impact_default"
@export var decal_id := &"scorch_small"
