class_name RelicDefs
extends RefCounted
## Magic relic catalog — data over code. Relics are NOT craftable: they
## come from merchants, raid bosses, and (Phase 6) ruin expeditions.
## Each is a unique auto-cast spell on a long cooldown, usable only by
## villagers with the Magic Affinity trait.

const ORDER := ["relic_fireball", "relic_heal", "relic_barrier",
		"relic_frost", "relic_storm", "relic_ward"]

const DEFS := {
	"relic_fireball": {"name": "Fireball", "kind": "blast", "cooldown": 400, "range": 6, "damage": 30.0, "radius": 1},
	"relic_heal": {"name": "Healing", "kind": "heal", "cooldown": 500, "range": 5, "heal": 40.0},
	"relic_barrier": {"name": "Barrier", "kind": "ward", "cooldown": 600, "radius": 3, "armor": 8.0, "duration": 150},
	# v2.1 — new spells (all reuse the relic sprite, tinted per resource color)
	"relic_frost": {"name": "Frost", "kind": "frost", "cooldown": 450, "range": 6,
			"damage": 16.0, "radius": 2, "slow": 40},
	"relic_storm": {"name": "Stormcall", "kind": "storm", "cooldown": 400, "range": 7,
			"damage": 18.0, "chain": 3},
	"relic_ward": {"name": "Ward Totem", "kind": "ward", "cooldown": 450, "radius": 4,
			"armor": 6.0, "duration": 220},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
