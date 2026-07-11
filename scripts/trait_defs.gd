class_name TraitDefs
extends RefCounted
## Trait catalog — traits are data with stat/mood modifiers, never code.
## Consumers multiply in whatever keys they care about. The full backstory
## pool (Orphaned, Last Smith, Witness...) lands in Phase 9; these three
## prove the model, and magic_affinity gates relic use in Phase 5.

const ORDER := ["brawler", "diligent", "magic_affinity"]  # random quirk pool
## The full backstory pool (Phase 9): every villager carries one scar
## from the fall of the city.
const BACKSTORIES := ["orphaned", "last_smith", "witness", "veteran", "forager", "stargazer"]

const DEFS := {
	"brawler": {"name": "Brawler", "melee_damage_mult": 1.25,
			"lore": "Settles arguments the old way. +25% melee damage."},
	"diligent": {"name": "Diligent", "work_speed_mult": 1.15,
			"lore": "First up, last to rest. +15% work speed."},
	"magic_affinity": {"name": "Magic Affinity", "magic": true,
			"lore": "The old blood runs thin, but it runs. Can wield relics."},
	"orphaned": {"name": "Orphaned", "melee_damage_mult": 1.15,
			"lore": "Vhal took everything. The anger stayed. +15% melee damage."},
	"last_smith": {"name": "Last Smith", "work_speed_mult": 1.12,
			"lore": "The forges of Vhal died with the city — save one pair of hands. +12% work speed."},
	"witness": {"name": "Witness", "ranged_damage_mult": 1.15,
			"lore": "Saw it all from the walls. Never misses twice. +15% ranged damage."},
	"veteran": {"name": "Veteran of the Wall", "melee_damage_mult": 1.2,
			"lore": "Held the gate until it burned. +20% melee damage."},
	"forager": {"name": "Forager", "work_speed_mult": 1.08,
			"lore": "Fed a family on hedgerows and luck. +8% work speed."},
	"stargazer": {"name": "Stargazer", "magic": true,
			"lore": "Read the omens before the fire came. Can wield relics."},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]

## Product of a multiplier key across a pawn's traits (1.0 when absent).
static func multiplier(traits: Array, key: String) -> float:
	var m := 1.0
	for id: String in traits:
		m *= float(DEFS[id].get(key, 1.0))
	return m

static func has_flag(traits: Array, key: String) -> bool:
	for id: String in traits:
		if bool(DEFS[id].get(key, false)):
			return true
	return false
