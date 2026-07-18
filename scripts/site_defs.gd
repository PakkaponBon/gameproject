class_name SiteDefs
extends RefCounted
## Wild places on the world map — data over code. Each is an expedition
## table: difficulty, loot, a cooldown before it's worth returning, and a
## chronicle vignette. Adding a site = adding an entry (+ a PLACES node
## in world_map.gd for its position and icon).

const ORDER := ["ruins", "witchfen", "dwarf_road", "howling_barrow"]

const DEFS := {
	"ruins": {
		"name": "Ruins of Vhal",
		"strength": 50.0,
		"reveal_renown": 0,  # your own burned city — known from the first day
		"cooldown_days": 4,
		"relic_chance": 0.5,
		"shards": 1,
		"resources": {"stone": 2},
		"report": "The ruins gave up their dead weight of treasure.",
		"vignette": "They walked the ash streets of Vhal and did not speak of what they saw.",
	},
	"witchfen": {
		"name": "The Witchfen",
		"strength": 65.0,
		"reveal_renown": 2,  # word of it reaches you as your name spreads
		"cooldown_days": 3,
		"relic_chance": 0.15,
		"shards": 1,
		"resources": {"herb": 4},
		"report": "The fen yielded herbs and a cold splinter of the old magic.",
		"vignette": "The fen lights led them in circles until dawn, and still they came home.",
	},
	"dwarf_road": {
		"name": "The Dwarf-road",
		"strength": 55.0,
		"reveal_renown": 1,
		"cooldown_days": 3,
		"relic_chance": 0.1,
		"shards": 1,
		"resources": {"iron_ore": 3, "iron_ingot": 1},
		"report": "The old road gave iron from its broken waystations.",
		"vignette": "The Dwarf-road still rings underfoot, as if something walks it far below.",
	},
	"howling_barrow": {
		"name": "The Howling Barrow",
		"strength": 80.0,
		"reveal_renown": 4,  # only the well-known hear the old rumor
		"cooldown_days": 5,
		"relic_chance": 0.25,
		"shards": 2,
		"resources": {},
		"report": "The barrow's silence broke — and paid in shards.",
		"vignette": "No wind on the hill, and yet the howling. They did not dig twice.",
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
