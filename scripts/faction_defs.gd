class_name FactionDefs
extends RefCounted
## The five factions around the meadow — data over code. Faction #5 is
## the enemy that burned the city: strongest, hostile, the de-facto boss.
## personality drives diplomacy math: aggressive drifts hostile, greedy
## loves gifts, honorable respects envoys.

const ORDER := ["black_pines", "vale_remnant", "mosswood", "deepstone", "ashen_legion"]

## leader/quirk are flavor shown on the world map; likes/likes_count is a
## gift preference — gifting that item earns deep favor (S3).
const DEFS := {
	"black_pines": {"name": "Black Pine Bandits", "personality": "aggressive",
			"strength": 40, "attitude": -40,
			"leader": "Varga Redmark", "quirk": "Respects only strength; despises beggars.",
			"likes": "sword", "likes_count": 1},
	"vale_remnant": {"name": "Vale Remnant", "personality": "honorable",
			"strength": 60, "attitude": 10,
			"leader": "Lord Alden Vale", "quirk": "Holds to the old courtesies of a kingdom that is gone.",
			"likes": "wool", "likes_count": 2},
	"mosswood": {"name": "Mosswood Tribe", "personality": "greedy",
			"strength": 50, "attitude": 0,
			"leader": "Mother Fern", "quirk": "Trades in everything; the forest gives no iron.",
			"likes": "iron_ingot", "likes_count": 2},
	"deepstone": {"name": "Deepstone Holds", "personality": "greedy",
			"strength": 70, "attitude": -10,
			"leader": "Thane Borvik", "quirk": "The halls are rich, cold, and thirsty.",
			"likes": "ale", "likes_count": 2},
	"ashen_legion": {"name": "The Ashen Legion", "personality": "aggressive",
			"strength": 100, "attitude": -60,
			"leader": "The Cindermarked", "quirk": "What they want, they take. What they fear, they burn."},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
