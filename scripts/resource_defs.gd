class_name ResourceDefs
extends RefCounted
## Resource catalog — data over code. Adding a resource = adding an entry.
## node_color/node_yield only apply to resources that come from ore nodes.

const DEFS := {
	"wood": {"name": "Wood", "color": Color(0.784314, 0.607843, 0.352941)},
	"stone": {"name": "Stone", "color": Color(0.62, 0.62, 0.66),
			"node_color": Color(0.33, 0.33, 0.36), "node_yield": 3},
	"iron_ore": {"name": "Iron Ore", "color": Color(0.72, 0.5, 0.38),
			"node_color": Color(0.37, 0.29, 0.23), "node_yield": 2},
	"iron_ingot": {"name": "Iron Ingot", "color": Color(0.76, 0.76, 0.82)},
	"sword": {"name": "Sword", "color": Color(0.8, 0.82, 0.88)},
	"bow": {"name": "Bow", "color": Color(0.6, 0.45, 0.3)},
	"arrow": {"name": "Arrows", "color": Color(0.85, 0.85, 0.7), "shots": 5},
	"herb": {"name": "Herb", "color": Color(0.35, 0.8, 0.6), "medicine": 25.0},
	"relic_fireball": {"name": "Fireball Relic", "color": Color(0.9, 0.45, 0.2), "relic": true},
	"relic_heal": {"name": "Healing Relic", "color": Color(0.4, 0.85, 0.5), "relic": true},
	"relic_barrier": {"name": "Barrier Relic", "color": Color(0.5, 0.55, 0.95), "relic": true},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
