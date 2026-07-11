extends Node

var collected_effects: Array[int] = []
var unlocked_weapons: Array[String] = []
var ammo_received: Dictionary = {}

func heal(amount: float) -> float:
	return amount

func add_armor(amount: float) -> float:
	return amount

func add_ammo(ammo_type: String, amount: int) -> int:
	ammo_received[ammo_type] = amount
	return amount

func unlock_weapon(display_name: String) -> bool:
	unlocked_weapons.append(display_name)
	return true

func restore_full() -> void:
	pass

func receive_pickup_effect(kind: PickupDefinition.Kind, _amount: float) -> bool:
	collected_effects.append(kind)
	return true
