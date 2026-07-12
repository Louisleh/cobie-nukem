class_name DamageReactionProfile
extends Resource

@export var flinch_threshold := 1.0
@export var stagger_threshold := 35.0
@export_range(0.0, 1.0, 0.05) var stagger_resistance := 0.0
@export var directional_reactions := true
@export var death_response := &"standard"
