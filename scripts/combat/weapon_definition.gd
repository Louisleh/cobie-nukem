class_name WeaponDefinition
extends Resource

@export var id := &"weapon"
@export var feel: WeaponFeelProfile
@export var display_name := "Weapon"
@export_multiline var pickup_message := "ACQUIRED."
@export var ammo_type := "none"
@export var magazine_size := 0
@export var starting_ammo := 0
@export var reserve_capacity := 0
@export var starting_reserve := 0
@export var infinite_reserve := false
@export var reload_seconds := 1.0
@export var reload_per_round := false
@export var ammo_per_primary := 1
@export var ammo_per_secondary := 1
@export var primary_damage := 10.0
@export var secondary_damage := 10.0
@export var primary_cooldown := 0.25
@export var secondary_cooldown := 0.5
@export var range := 80.0
@export var pellets := 1
@export var spread_degrees := 0.0
@export var knockback := 0.0
@export var projectile_speed := 18.0
@export var projectile_fuse := 2.5
