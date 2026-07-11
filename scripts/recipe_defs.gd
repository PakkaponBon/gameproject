class_name RecipeDefs
extends RefCounted
## Crafting catalog — data over code. ORDER is priority: a workstation
## picks the first recipe whose inputs exist as free items.

const ORDER := ["forge_sword", "smelt_iron"]

const DEFS := {
	"smelt_iron": {
		"name": "Smelt Iron",
		"station": "forge",
		"inputs": {"iron_ore": 1},
		"output": "iron_ingot",
		"craft_ticks": 30,
	},
	"forge_sword": {
		"name": "Forge Sword",
		"station": "forge",
		"inputs": {"iron_ingot": 2},
		"output": "sword",
		"craft_ticks": 50,
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
