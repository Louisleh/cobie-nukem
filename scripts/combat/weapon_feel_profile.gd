class_name WeaponFeelProfile
extends Resource

@export_range(0.0, 0.5, 0.01) var raise_seconds := 0.18
@export_range(0.0, 0.5, 0.01) var lower_seconds := 0.12
@export_range(0.0, 2.0, 0.01) var recoil_recovery_seconds := 0.16
@export_range(0.0, 2.0, 0.05) var camera_impulse := 0.35
@export_range(0.0, 2.0, 0.05) var viewmodel_kick := 0.3
@export var muzzle_effect := &"compact"
@export var impact_category := &"ballistic"
@export var shot_sound_set := &"pawstol"
