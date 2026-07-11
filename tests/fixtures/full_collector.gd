extends Node

func heal(_amount: float) -> float:
	return 0.0

func add_armor(_amount: float) -> float:
	return 0.0

func add_ammo(_ammo_type: String, _amount: int) -> int:
	return 0

func unlock_weapon(_display_name: String) -> bool:
	return false

func restore_full() -> void:
	pass

func receive_pickup_effect(_kind: PickupDefinition.Kind, _amount: float) -> bool:
	return true
