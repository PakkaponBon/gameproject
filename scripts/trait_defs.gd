class_name TraitDefs
extends RefCounted
## Trait catalog — traits are data with stat/mood modifiers, never code.
## Consumers multiply in whatever keys they care about. The full backstory
## pool (Orphaned, Last Smith, Witness...) lands in Phase 9; these three
## prove the model, and magic_affinity gates relic use in Phase 5.

const ORDER := ["brawler", "diligent", "magic_affinity", "loner",
		"swift", "marksman", "hot_blooded", "warm", "clumsy", "old_blood"]  # random quirk pool
## The full backstory pool: every villager carries one scar from the fall.
const BACKSTORIES := ["orphaned", "last_smith", "witness", "veteran", "forager", "stargazer",
		"bellringer", "gravedigger", "physician", "runaway"]

const DEFS := {
	"brawler": {"name": "Brawler", "melee_damage_mult": 1.25,
			"lore": "Settles arguments the old way. +25% melee damage."},
	"diligent": {"name": "Diligent", "work_speed_mult": 1.15,
			"lore": "First up, last to rest. +15% work speed."},
	"magic_affinity": {"name": "Magic Affinity", "magic": true,
			"lore": "The old blood runs thin, but it runs. Can wield relics."},
	"loner": {"name": "Loner", "solitary": true,
			"lore": "Better company in silence. Bonds sour instead of forming."},
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
	# --- v2.1 quirks ---
	"swift": {"name": "Swift", "work_speed_mult": 1.12,
			"lore": "Never wastes a motion. +12% work speed."},
	"marksman": {"name": "Marksman", "ranged_damage_mult": 1.2,
			"lore": "Born with a bow in hand. +20% ranged damage."},
	"hot_blooded": {"name": "Hot-Blooded", "melee_damage_mult": 1.3,
			"lore": "Fights first, thinks later. +30% melee damage."},
	"warm": {"name": "Warm", "gregarious": true,
			"lore": "Everyone's friend by the second week. Bonds form fast."},
	"clumsy": {"name": "Clumsy", "work_speed_mult": 0.9,
			"lore": "Means well. Breaks things. -10% work speed."},
	"old_blood": {"name": "Old Blood", "magic": true,
			"lore": "The gift skipped ten generations and landed here. Can wield relics."},
	# --- v2.1 backstories ---
	"bellringer": {"name": "Bellringer", "ranged_damage_mult": 1.12,
			"lore": "Rang the alarm until the ropes burned. Sharp eyes since. +12% ranged damage."},
	"gravedigger": {"name": "Gravedigger", "work_speed_mult": 1.1,
			"lore": "Buried more than anyone should. Works without complaint. +10% work speed."},
	"physician": {"name": "Physician", "work_speed_mult": 1.08,
			"lore": "Set bones by lamplight as the city fell. Steady hands. +8% work speed."},
	"runaway": {"name": "Runaway", "melee_damage_mult": 1.12,
			"lore": "Ran, and hated the running. Won't run again. +12% melee damage."},
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
