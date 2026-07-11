class_name FactionDefs
extends RefCounted
## The five factions around the meadow — data over code. Faction #5 is
## the enemy that burned the city: strongest, hostile, the de-facto boss.
## personality drives diplomacy math: aggressive drifts hostile, greedy
## loves gifts, honorable respects envoys.

const ORDER := ["black_pines", "vale_remnant", "mosswood", "deepstone", "ashen_legion"]

const DEFS := {
	"black_pines": {"name": "Black Pine Bandits", "personality": "aggressive", "strength": 40, "attitude": -40},
	"vale_remnant": {"name": "Vale Remnant", "personality": "honorable", "strength": 60, "attitude": 10},
	"mosswood": {"name": "Mosswood Tribe", "personality": "greedy", "strength": 50, "attitude": 0},
	"deepstone": {"name": "Deepstone Holds", "personality": "greedy", "strength": 70, "attitude": -10},
	"ashen_legion": {"name": "The Ashen Legion", "personality": "aggressive", "strength": 100, "attitude": -60},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
