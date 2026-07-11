class_name BuildingDefs
extends RefCounted
## Building catalog — data over code. Adding a building means adding an
## entry here (and an atlas tile), never a new script.
##
## block_villagers / block_enemies drive the two pathing grids (a gate is
## open to villagers, solid to enemies). storage=true makes the cell act
## as a stockpile once built. workstation=true lets ForgeKeeper run
## recipes there. cost/refund are per-resource dictionaries.

const ORDER := ["wall", "gate", "bed", "barn", "forge"]

const DEFS := {
	"wall": {
		"name": "Wall",
		"cost": {"wood": 1},
		"refund": {},
		"build_ticks": 20,
		"tile": Vector2i(2, 0),
		"ghost": Color(0.44, 0.44, 0.47),
		"block_villagers": true,
		"block_enemies": true,
		"storage": false,
	},
	"gate": {
		"name": "Gate",
		"cost": {"wood": 2},
		"refund": {"wood": 1},
		"hp": 80.0,  # bandits can batter gates down; walls are absolute
		"build_ticks": 30,
		"tile": Vector2i(3, 0),
		"ghost": Color(0.55, 0.45, 0.32),
		"block_villagers": false,
		"block_enemies": true,
		"storage": false,
	},
	"bed": {
		"name": "Bed",
		"cost": {"wood": 2},
		"refund": {"wood": 1},
		"sleep_spot": true,
		"build_ticks": 30,
		"tile": Vector2i(4, 0),
		"ghost": Color(0.55, 0.65, 0.8),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
	},
	"barn": {
		"name": "Storage Barn",
		"cost": {"wood": 3},
		"refund": {"wood": 2},
		"build_ticks": 40,
		"tile": Vector2i(5, 0),
		"ghost": Color(0.43, 0.31, 0.2),
		"block_villagers": false,
		"block_enemies": false,
		"storage": true,
	},
	"forge": {
		"name": "Forge",
		"cost": {"wood": 2, "stone": 3},
		"refund": {"wood": 1, "stone": 2},
		"build_ticks": 50,
		"tile": Vector2i(6, 0),
		"ghost": Color(0.4, 0.34, 0.32),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"workstation": true,
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
