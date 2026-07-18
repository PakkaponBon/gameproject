class_name WeaponDefs
extends RefCounted
## Weapon catalog — data over code. Adding a weapon (club, spear...) is an
## entry here plus a ResourceDefs entry so it exists as an item.

const UNARMED_DAMAGE := 5.0

const DEFS := {
	# Melee tier-1 (anyone can wield). attack_ticks vs damage is the trade:
	# fast-weak clears swarms; slow-heavy beats armor (armor subtracts per hit).
	"sword": {"name": "Sword", "damage": 12.0, "tier": 1},  # baseline speed
	"club": {"name": "Club", "damage": 9.0, "tier": 1, "attack_ticks": 8},   # cheap, fast, light
	"spear": {"name": "Spear", "damage": 13.0, "tier": 1, "attack_ticks": 11},  # iron-light, solid
	"warhammer": {"name": "Warhammer", "damage": 22.0, "tier": 1, "attack_ticks": 18},  # slow, crushes armor
	"bow": {
		"name": "Bow", "damage": 10.0, "tier": 2,
		"ranged": true, "range": 6, "kite_range": 2,
		"skill": "archery", "skill_min": 3,  # skilled villagers only
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
