class_name CosmeticApplicator
extends RefCounted

const TINTS := {
	"pawstol_warning_stripe": Color("ffc32f"),
	"pawstol_salmon_turf": Color("70a654"),
	"barkshot_safety_orange": Color("f47d35"),
	"barkshot_rain_slick": Color("4f8d99"),
	"fetch_classic_green": Color("9fcf43"),
}


static func apply_weapon_cosmetics(player: CobiePlayer, selected: Dictionary) -> void:
	if player == null: return
	for weapon in player.weapons:
		if weapon == null or weapon.definition == null: continue
		if weapon is FetchLauncher:
			(weapon as FetchLauncher).golden_trail_enabled = String(selected.get("fetch_trail", "")) == "fetch_golden_trail"
		var reward_id := String(selected.get("%s_skin" % String(weapon.definition.id).trim_suffix("_launcher"), ""))
		if reward_id.is_empty() and weapon.definition.id == &"fetch_launcher": reward_id = String(selected.get("fetch_skin", ""))
		if not TINTS.has(reward_id): continue
		for child in weapon.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := child as MeshInstance3D
			var material := StandardMaterial3D.new(); material.albedo_color = TINTS[reward_id]; material.metallic = 0.55; material.roughness = 0.4
			mesh_instance.material_override = material
