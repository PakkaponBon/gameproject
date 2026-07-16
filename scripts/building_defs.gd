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
		"hearth", "brazier", "table", "chair", "shrine", "trophy_wall", "brewery", "coop",
		"pasture", "loom", "spike_pit", "bell"]

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
		"workstation": true,  # awakens relic shards (station "shrine")
		"light": true,  # the old magic glows faintly
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
	"coop": {
		"name": "Chicken Coop",
		"cost": {"wood": 3},
		"refund": {"wood": 1},
		"build_ticks": 40,
		"tile": Vector2i(17, 0),
		"ghost": Color(0.6, 0.42, 0.3),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"livestock": "chicken",  # stocked with hens when built; they lay eggs
		"livestock_count": 2,
	},
	"pasture": {
		"name": "Pasture",
		"cost": {"wood": 2},
		"refund": {"wood": 1},
		"build_ticks": 30,
		"tile": Vector2i(18, 0),
		"ghost": Color(0.7, 0.6, 0.4),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"livestock": "sheep",
		"livestock_count": 2,
	},
	"loom": {
		"name": "Loom",
		"cost": {"wood": 3},
		"refund": {"wood": 1},
		"build_ticks": 40,
		"tile": Vector2i(19, 0),
		"ghost": Color(0.75, 0.6, 0.45),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"workstation": true,  # weaves wool/hide into armor (station "loom")
	},
	"spike_pit": {
		"name": "Spike Pit",
		"cost": {"wood": 1, "iron_ingot": 1},
		"refund": {},
		"build_ticks": 25,
		"tile": Vector2i(20, 0),
		"ghost": Color(0.35, 0.3, 0.25),
		# The gate trick in reverse: villagers path around it, enemies
		# walk straight onto the spikes.
		"block_villagers": true,
		"block_enemies": false,
		"storage": false,
		"trap_damage": 20.0,
		"trap_uses": 3,
	},
	"bell": {
		"name": "Alarm Bell",
		"cost": {"wood": 2},
		"refund": {"wood": 1},
		"build_ticks": 20,
		"tile": Vector2i(21, 0),
		"ghost": Color(0.8, 0.7, 0.4),
		"block_villagers": false,
		"block_enemies": false,
		"storage": false,
		"alarm_radius": 10,  # rings when a raider comes this close
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

## Plain-language "what is this for" per building, shown in the Help guide.
const DESC := {
	"wall": "Blocks villagers and enemies. Wall your colony to control where raiders can go.",
	"door": "Villagers pass; enemies don't. A cheap way to divide inner rooms (flimsier than a gate).",
	"gate": "Villagers pass freely; raiders must batter it down. Put one in your wall as the entrance.",
	"bed": "Villagers sleep and heal here — faster than on the ground. Build about one per villager.",
	"barn": "Storage. Loose resources get hauled here. Build one early so wood and food don't sit in the mud.",
	"forge": "Workshop. Smelts iron ore into ingots, then crafts swords, bows, and arrows.",
	"stove": "Kitchen. Cooks raw food into meals — and stew when food is plentiful. Cooked food fills more and lifts mood.",
	"watchtower": "An archer standing on it shoots much farther. Enemies can't climb it. Needs renown to build.",
	"hearth": "Warms an enclosed room. In winter, cold villagers work slower and get miserable — keep a hearth indoors.",
	"brazier": "A cheap, small warmth source for corners a hearth can't reach.",
	"table": "Furniture. Adds comfort to a room; villagers relax nearby on breaks and slowly regain joy.",
	"chair": "Furniture. A little comfort — pair it with a table by the hearth.",
	"shrine": "A place of quiet. Strong comfort — and it awakens relic shards (3 from wild sites) into a true relic.",
	"trophy_wall": "Prestige furniture — big comfort, needs renown. The centerpiece of a proud hall.",
	"brewery": "Brews barley into ale. Villagers drink a mug on breaks for a real joy boost.",
	"coop": "Comes stocked with hens. They lay an egg (food) about once a day — steady food with no field needed.",
	"pasture": "Comes stocked with sheep. They grow wool — the loom turns it into armor.",
	"loom": "Weaves wool into padded coats and hides into leather jerkins. Armor makes your fighters survive raids.",
	"spike_pit": "Villagers walk around it; raiders walk onto it and get hurt. Breaks after a few triggers — put it in their path.",
	"bell": "Rings loudly when a raider comes near. Early warning for the edge of your land.",
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]

static func desc(id: String) -> String:
	return DESC.get(id, "")
