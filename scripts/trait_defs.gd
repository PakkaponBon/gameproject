class_name TraitDefs
extends RefCounted
## Trait catalog — traits are data with stat/mood modifiers, never code.
## Consumers multiply in whatever keys they care about. The full backstory
## pool (Orphaned, Last Smith, Witness...) lands in Phase 9; these three
## prove the model, and magic_affinity gates relic use in Phase 5.

const ORDER := ["brawler", "diligent", "magic_affinity"]

const DEFS := {
	"brawler": {"name": "Brawler", "melee_damage_mult": 1.25},
	"diligent": {"name": "Diligent", "work_speed_mult": 1.15},
	"magic_affinity": {"name": "Magic Affinity", "magic": true},
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
