class_name LandmarkDefs
extends RefCounted
## Frontier landmarks on the HOME map — data over code. Old, quiet places you
## discover by scouting and investigate for a reward. Adding one = adding an
## entry here; nothing else needs a new script (F2 reads the reward fields,
## the spawner reads cell/tint/scale/min_dist, the node reads name/blurb).
##
## Distinct from SiteDefs (those are abstract world-map expeditions). These sit
## on the physical tilemap. Tone rule: melancholy, never gory — every blurb is
## told, never shown.
##
## Fields:
##   name          display name, shown on discovery
##   cell          sprites.png atlas cell (reused; nothing renders blank)
##   tint          Color modulate so places read apart at a glance
##   scale         render scale — landmarks are oversized features, not props
##   blurb         one line, revealed when a villager comes upon it
##   min_dist      min tiles from home center at spawn (the reward is *out there*)
##   resources     {id: count} dropped on investigate (F2)
##   renown        renown granted on investigate (F2)
##   shard_chance  chance of a relic shard (F2)
##   relic_chance  chance of a full relic (F2)
##   renewable_days 0 = one-shot; >0 = replenishes after this many days (F2)

const ORDER := ["standing_stones", "ash_grove", "fallen_watchtower",
		"wayside_cairn", "old_shrine", "sunken_cache"]

const DEFS := {
	"standing_stones": {
		"name": "Standing Stones",
		"cell": 17,  # jagged-rock silhouette
		"tint": Color(0.72, 0.78, 0.92),
		"scale": 2.3,
		"blurb": "A ring of stones older than the ash. Standing among them, the village feels less alone.",
		"min_dist": 18,
		"resources": {"stone": 3},
		"renown": 2.0,
		"shard_chance": 0.4,
		"relic_chance": 0.0,
		"renewable_days": 0,
	},
	"ash_grove": {
		"name": "Ash-scarred Grove",
		"cell": 1,  # tree
		"tint": Color(0.62, 0.66, 0.6),
		"scale": 2.4,
		"blurb": "Trees the fire spared, half-grey with old ash. Their bark still gives, and healing grows in their shade.",
		"min_dist": 12,
		"resources": {"wood": 4, "herb": 2},
		"renown": 0.0,
		"shard_chance": 0.0,
		"relic_chance": 0.0,
		"renewable_days": 6,
	},
	"fallen_watchtower": {
		"name": "Fallen Watchtower",
		"cell": 2,  # rock/rubble
		"tint": Color(0.7, 0.68, 0.62),
		"scale": 2.5,
		"blurb": "A border tower thrown down long ago. Its armory still holds arms for hands willing to dig.",
		"min_dist": 16,
		"resources": {"iron_ingot": 1},
		"renown": 1.0,
		"shard_chance": 0.0,
		"relic_chance": 0.0,
		"renewable_days": 0,
		"weapons": ["sword", "spear"],  # F2: a cache of tier-1 arms
	},
	"wayside_cairn": {
		"name": "Wayside Cairn",
		"cell": 5,  # stone-chunk
		"tint": Color(0.8, 0.8, 0.78),
		"scale": 1.9,
		"blurb": "Travelers heaped these stones for the lost. A coin is left, a name is said, and the road feels shorter.",
		"min_dist": 8,
		"resources": {"stone": 2, "food": 2},
		"renown": 1.0,
		"shard_chance": 0.0,
		"relic_chance": 0.0,
		"renewable_days": 8,
	},
	"old_shrine": {
		"name": "Old Shrine",
		"cell": 12,  # relic-wand
		"tint": Color(0.95, 0.85, 0.5),
		"scale": 2.1,
		"blurb": "A shrine to a god whose name the ash took. Something of the old power still lingers, faint and cold.",
		"min_dist": 22,
		"resources": {},
		"renown": 3.0,
		"shard_chance": 0.6,
		"relic_chance": 0.15,
		"renewable_days": 0,
	},
	"sunken_cache": {
		"name": "Sunken Cellar",
		"cell": 22,  # mushrooms over a buried door
		"tint": Color(0.72, 0.82, 0.68),
		"scale": 2.0,
		"blurb": "A farmstead's cellar, roof long gone. The stores kept better than the house — preserves, and herbs gone wild.",
		"min_dist": 10,
		"resources": {"food": 4, "herb": 2},
		"renown": 0.0,
		"shard_chance": 0.0,
		"relic_chance": 0.0,
		"renewable_days": 0,
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]

## Uniform pick for world-gen scatter (variety comes from the six-strong catalog;
## weighting can arrive with F3's rumor/renown-gated places).
static func random_id(rng: RandomNumberGenerator) -> String:
	return String(ORDER[rng.randi() % ORDER.size()])
