class_name BiomeDefs
extends RefCounted
## Concentric wilds: the home Meadow at the map's heart, wilder rings toward the
## frontier edge — Deepwood, then Highlands, then Ashlands. Data over code: a
## biome is a function of distance-from-home nudged by noise, and each biome
## biases the ground (grass vs dirt) and what scatters there (trees, ore, bushes,
## decor, landmarks). Art-free (reuses the existing grass/dirt tiles) and derived
## from the world seed, so there is nothing new to save — it regenerates on load.
##
## The point: the enlarged open map reads as a real world with places, and the
## frontier genuinely feels like a frontier — safe green home, dangerous grey
## reaches where the richest landmarks and the ore sit.

const ORDER := ["meadow", "deepwood", "highlands", "ashlands"]

const DEFS := {
	# ground/soil are the atlas tiles for grass-side / dirt-side of each biome.
	# All point at the shared meadow tiles (0 grass / 1 dirt) until Codex packs
	# the biome terrain art (deepwood 41/42, highlands 43/44, ashlands 45/46) —
	# then these three wild biomes repoint and the regions read distinct.
	"meadow": {
		"name": "Meadow",
		"dirt_bias": 0.12,  # lush, mostly grass
		"boars": false,  # gentle country: rabbits, not tusks
		"ground": Vector2i(0, 0), "soil": Vector2i(1, 0),
		"weights": {"tree": 1.0, "ore": 0.3, "bush": 1.6, "decor": 1.6, "landmark": 0.5, "game": 1.2},
	},
	"deepwood": {
		"name": "Deepwood",
		"dirt_bias": 0.10,
		"boars": true,  # the big game runs in the trees
		"ground": Vector2i(0, 0), "soil": Vector2i(1, 0),  # → 41/42 when packed
		"weights": {"tree": 3.2, "ore": 0.4, "bush": 1.2, "decor": 1.0, "landmark": 1.0, "game": 1.8},
	},
	"highlands": {
		"name": "Highlands",
		"dirt_bias": 0.55,  # rocky, patchy ground
		"boars": true,
		"ground": Vector2i(0, 0), "soil": Vector2i(1, 0),  # → 43/44 when packed
		"weights": {"tree": 0.4, "ore": 3.2, "bush": 0.4, "decor": 0.6, "landmark": 1.2, "game": 0.9},
	},
	"ashlands": {
		"name": "Ashlands",
		"dirt_bias": 0.82,  # barren grey earth
		"boars": true,
		"ground": Vector2i(0, 0), "soil": Vector2i(1, 0),  # → 45/46 when packed
		"weights": {"tree": 0.2, "ore": 1.0, "bush": 0.2, "decor": 0.3, "landmark": 2.2, "game": 0.4},
	},
}

## Pick a biome by normalized distance from home (0 = center, 1 = edge). Callers
## add a little noise to the fraction first, so the ring borders come out ragged.
static func at_fraction(t: float) -> String:
	if t < 0.30:
		return "meadow"
	elif t < 0.55:
		return "deepwood"
	elif t < 0.80:
		return "highlands"
	return "ashlands"

static func get_def(id: String) -> Dictionary:
	return DEFS[id]

static func dirt_bias(id: String) -> float:
	return float(DEFS[id].dirt_bias)

## Atlas tile for a biome's grass-side / dirt-side ground.
static func ground_tile(id: String) -> Vector2i:
	return DEFS[id].ground

static func soil_tile(id: String) -> Vector2i:
	return DEFS[id].soil

## Does this biome's game include boars (wild, bites back) vs. only rabbits?
static func has_boars(id: String) -> bool:
	return bool(DEFS[id].boars)

## How strongly a biome favors scattering a given thing (tree/ore/bush/decor/
## landmark). 1.0 is neutral; the spawner samples a few cells and keeps the one
## with the highest weight, biasing placement toward fitting country.
static func weight(id: String, key: String) -> float:
	var w: Dictionary = DEFS[id].weights
	return float(w.get(key, 1.0))
