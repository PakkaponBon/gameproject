class_name BuildingDefs
extends RefCounted
## Building catalog — data over code. Adding a building means adding an
## entry here (and an atlas tile), never a new script.
##
## block_villagers / block_enemies drive the two pathing grids (a gate is
## open to villagers, solid to enemies). storage=true makes the cell act
## as a stockpile once built. workstation=true lets ForgeKeeper run
## recipes there. cost/refund are per-resource dictionaries.

const ORDER := ["wall", "door", "gate", "bed", "barn", "forge", "stove", "watchtower",
		"hearth", "brazier", "table", "chair", "shrine", "trophy_wall", "brewery"]

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
	"door": {
		"name": "Door",
		"cost": {"wood": 1},
		"refund": {},
		"hp": 40.0,  # flimsier than the gate — for inner rooms
		"build_ticks": 20,
		"tile": Vector2i(9, 0),
		"ghost": Color(0.63, 0.48, 0.28),
		"block_villagers": false,
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
	"stove": {
		"name": "Stove",
		"cost": {"wood": 1, "stone": 2},
		"refund": {"stone": 1},
		"build_ticks": 40,
		"tile": Vector2i(8, 0),
		"ghost": Color(0.5, 0.45, 0.42),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"kitchen": true,
	},
	"hearth": {
		"name": "Hearth",
		"cost": {"stone": 2, "wood": 1},
		"refund": {"stone": 1},
		"build_ticks": 40,
		"tile": Vector2i(10, 0),
		"ghost": Color(0.85, 0.55, 0.3),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"warmth_radius": 4,
		"comfort": 2,
		"light": true,  # glows like a workstation
	},
	"brazier": {
		"name": "Brazier",
		"cost": {"wood": 1, "stone": 1},
		"refund": {},
		"build_ticks": 15,
		"tile": Vector2i(15, 0),
		"ghost": Color(0.8, 0.5, 0.3),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"warmth_radius": 2,
		"light": true,
	},
	"table": {
		"name": "Table",
		"cost": {"wood": 2},
		"refund": {"wood": 1},
		"build_ticks": 25,
		"tile": Vector2i(11, 0),
		"ghost": Color(0.7, 0.55, 0.35),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"comfort": 1,
	},
	"chair": {
		"name": "Chair",
		"cost": {"wood": 1},
		"refund": {},
		"build_ticks": 15,
		"tile": Vector2i(12, 0),
		"ghost": Color(0.7, 0.55, 0.35),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"comfort": 1,
	},
	"shrine": {
		"name": "Shrine",
		"cost": {"stone": 3},
		"refund": {"stone": 1},
		"build_ticks": 50,
		"tile": Vector2i(13, 0),
		"ghost": Color(0.75, 0.75, 0.85),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"comfort": 3,
	},
	"trophy_wall": {
		"name": "Trophy Wall",
		"cost": {"wood": 2, "iron_ingot": 1},
		"refund": {"wood": 1},
		"build_ticks": 40,
		"tile": Vector2i(14, 0),
		"ghost": Color(0.6, 0.5, 0.4),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"comfort": 2,
		"renown_req": 1,  # trophies need a story behind them
	},
	"brewery": {
		"name": "Brewery",
		"cost": {"wood": 3, "stone": 1},
		"refund": {"wood": 1},
		"build_ticks": 50,
		"tile": Vector2i(16, 0),
		"ghost": Color(0.6, 0.45, 0.28),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"workstation": true,  # brews barley into ale (RecipeDefs station "brewery")
	},
	"watchtower": {
		"name": "Watchtower",
		"cost": {"wood": 3, "stone": 2},
		"refund": {"wood": 1, "stone": 1},
		"build_ticks": 60,
		"tile": Vector2i(7, 0),
		"ghost": Color(0.6, 0.6, 0.66),
		"block_villagers": false,
		"block_enemies": true,  # bandits can't climb it
		"storage": false,
		"range_bonus": 3,  # archer standing here shoots further
		"renown_req": 1,  # earn your first raid victory
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
