class_name RecipeDefs
extends RefCounted
## Crafting catalog — data over code. ORDER is priority: a workstation
## picks the first recipe whose inputs exist as free items.

const ORDER := ["forge_sword", "craft_bow", "craft_arrows", "smelt_iron", "brew_ale"]

const DEFS := {
	"smelt_iron": {
		"name": "Smelt Iron",
		"station": "forge",
		"inputs": {"iron_ore": 1},
		"output": "iron_ingot",
		"craft_ticks": 30,
		"max_stock": 6,
	},
	"forge_sword": {
		"name": "Forge Sword",
		"station": "forge",
		"inputs": {"iron_ingot": 2},
		"output": "sword",
		"craft_ticks": 50,
		"max_stock": 3,
	},
	"craft_bow": {
		"name": "Craft Bow",
		"station": "forge",
		"inputs": {"wood": 2, "iron_ingot": 1},
		"output": "bow",
		"craft_ticks": 60,
		"max_stock": 2,
	},
	"craft_arrows": {
		"name": "Fletch Arrows",
		"station": "forge",
		"inputs": {"wood": 1},
		"output": "arrow",
		"output_count": 2,
		"craft_ticks": 25,
		"max_stock": 8,
	},
	"brew_ale": {
		"name": "Brew Ale",
		"station": "brewery",
		"inputs": {"barley": 2},
		"output": "ale",
		"craft_ticks": 40,
		"max_stock": 4,  # enough to keep spirits up, not a lake of it
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
