class_name WeaponDefs
extends RefCounted
## Weapon catalog — data over code. Adding a weapon (club, spear...) is an
## entry here plus a ResourceDefs entry so it exists as an item.

const UNARMED_DAMAGE := 5.0

const DEFS := {
	"sword": {"name": "Sword", "damage": 12.0, "tier": 1},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
