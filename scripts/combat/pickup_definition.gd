class_name PickupDefinition
extends Resource

enum Kind { HEALTH, ARMOR, AMMO, FULL_RESTORE, ZOOMIES, SQUEAKER, GOLDEN_TAG, ACCESS_COLLAR, WEAPON }

@export var kind: Kind = Kind.HEALTH
@export var amount := 10.0
@export var ammo_type := ""
@export var message := "GOOD DOG."
@export var respawns := false
@export var respawn_seconds := 30.0
