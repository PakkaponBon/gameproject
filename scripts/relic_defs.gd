class_name RelicDefs
extends RefCounted
## Magic relic catalog — data over code. Relics are NOT craftable: they
## come from merchants, raid bosses, and (Phase 6) ruin expeditions.
## Each is a unique auto-cast spell on a long cooldown, usable only by
## villagers with the Magic Affinity trait.

const ORDER := ["relic_fireball", "relic_heal", "relic_barrier"]

const DEFS := {
	"relic_fireball": {"name": "Fireball", "cooldown": 400, "range": 6, "damage": 30.0, "radius": 1},
	"relic_heal": {"name": "Healing", "cooldown": 500, "range": 5, "heal": 40.0},
	"relic_barrier": {"name": "Barrier", "cooldown": 600, "radius": 3, "armor": 8.0, "duration": 150},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
