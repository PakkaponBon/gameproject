class_name RecipeDefs
extends RefCounted
## Crafting catalog — data over code. ORDER is priority: a workstation
## picks the first recipe whose inputs exist as free items.

const ORDER := ["forge_sword", "craft_bow", "craft_arrows", "forge_mail", "smelt_iron",
		"brew_ale", "cut_leather", "weave_padded", "awaken_relic"]

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
	"weave_padded": {
		"name": "Weave Padded Coat",
		"station": "loom",
		"inputs": {"wool": 2},
		"output": "padded_coat",
		"craft_ticks": 40,
		"max_stock": 2,
	},
	"cut_leather": {
		"name": "Cut Leather Jerkin",
		"station": "loom",
		"inputs": {"hide": 2},
		"output": "leather_jerkin",
		"craft_ticks": 45,
		"max_stock": 2,
	},
	"forge_mail": {
		"name": "Forge Iron Mail",
		"station": "forge",
		"inputs": {"iron_ingot": 3},
		"output": "iron_mail",
		"craft_ticks": 60,
		"max_stock": 2,
	},
	"awaken_relic": {
		# Magic stays treasure: shards come only from wild sites, so
		# assembly is expedition-gated, never crafted from raw material.
		"name": "Awaken Relic",
		"station": "shrine",
		"inputs": {"relic_shard": 3},
		"output_pool": ["relic_fireball", "relic_heal", "relic_barrier"],
		"craft_ticks": 60,
		"max_stock": 1,
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
