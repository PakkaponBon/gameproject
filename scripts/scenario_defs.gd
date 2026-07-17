class_name ScenarioDefs
extends RefCounted
## Starting scenarios — data over code. Picked on the main menu; the choice
## rides a static var through the scene change (like Balance.mode). Each
## just tweaks the opening state: how many founders, which season, how much
## larder, and how fast renown grows. Everything after is the same game.

const ORDER := ["standard", "hard_winter", "wanderers"]

const DEFS := {
	"standard": {
		"name": "Standard",
		"pawns": 3, "start_season": 0, "start_food": 25, "renown_mult": 1.0,
		"blurb": "Three survivors, a spring meadow, a wagon of seed. The founding tale.",
	},
	"hard_winter": {
		"name": "Hard Winter",
		"pawns": 2, "start_season": 2, "start_food": 18, "renown_mult": 1.0,
		"blurb": "Two survivors, autumn already fading — winter is days away. For the hardened.",
	},
	"wanderers": {
		"name": "Wanderers",
		"pawns": 3, "start_season": 0, "start_food": 8, "renown_mult": 1.5,
		"blurb": "No wagon, almost no larder — but your deeds spread fast. Live off the land; rise by renown.",
	},
}

static var selected := "standard"

static func get_def(id: String) -> Dictionary:
	return DEFS[id]

static func current() -> Dictionary:
	return DEFS[selected]

## Renown grows faster in scenarios that lean on fame (Wanderers).
static func renown_mult() -> float:
	return float(current().renown_mult)
