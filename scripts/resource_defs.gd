class_name ResourceDefs
extends RefCounted
## Resource catalog — data over code. Adding a resource = adding an entry.
## node_color/node_yield only apply to resources that come from ore nodes.

## sprite = cell index in assets/sprites.png (item sprites are drawn
## light and tinted by color at runtime).
const DEFS := {
	"wood": {"name": "Wood", "color": Color(0.784314, 0.607843, 0.352941), "sprite": 4},
	"stone": {"name": "Stone", "color": Color(0.62, 0.62, 0.66), "sprite": 5,
			"node_color": Color(0.33, 0.33, 0.36), "node_yield": 3},
	"iron_ore": {"name": "Iron Ore", "color": Color(0.72, 0.5, 0.38), "sprite": 5,
			"node_color": Color(0.37, 0.29, 0.23), "node_yield": 2},
	"iron_ingot": {"name": "Iron Ingot", "color": Color(0.76, 0.76, 0.82), "sprite": 6},
	"sword": {"name": "Sword", "color": Color(0.85, 0.87, 0.95), "sprite": 7},
	"bow": {"name": "Bow", "color": Color(0.75, 0.6, 0.4), "sprite": 8},
	"arrow": {"name": "Arrows", "color": Color(0.9, 0.9, 0.78), "sprite": 9, "shots": 5},
	"herb": {"name": "Herb", "color": Color(0.35, 0.8, 0.6), "sprite": 10, "medicine": 25.0},
	"barley": {"name": "Barley", "color": Color(0.9, 0.78, 0.34), "sprite": 3},
	"ale": {"name": "Ale", "color": Color(0.85, 0.6, 0.22), "sprite": 10},
	"wool": {"name": "Wool", "color": Color(0.95, 0.93, 0.85), "sprite": 6},
	"hide": {"name": "Hide", "color": Color(0.62, 0.45, 0.3), "sprite": 6},
	# The armor ladder: value flows straight into the damage math.
	"padded_coat": {"name": "Padded Coat", "color": Color(0.88, 0.82, 0.68), "sprite": 27, "armor": 2.0},
	"leather_jerkin": {"name": "Leather Jerkin", "color": Color(0.7, 0.5, 0.32), "sprite": 27, "armor": 3.5},
	"iron_mail": {"name": "Iron Mail", "color": Color(0.8, 0.82, 0.9), "sprite": 27, "armor": 5.0},
	"relic_shard": {"name": "Relic Shard", "color": Color(0.6, 0.75, 0.95), "sprite": 12},
	"relic_fireball": {"name": "Fireball Relic", "color": Color(0.95, 0.5, 0.25), "sprite": 12, "relic": true},
	"relic_heal": {"name": "Healing Relic", "color": Color(0.45, 0.9, 0.55), "sprite": 12, "relic": true},
	"relic_barrier": {"name": "Barrier Relic", "color": Color(0.55, 0.6, 1.0), "sprite": 12, "relic": true},
	"relic_frost": {"name": "Frost Relic", "color": Color(0.6, 0.85, 1.0), "sprite": 12, "relic": true},
	"relic_storm": {"name": "Stormcall Relic", "color": Color(0.95, 0.9, 0.4), "sprite": 12, "relic": true},
	"relic_ward": {"name": "Ward Totem", "color": Color(0.7, 0.95, 0.7), "sprite": 12, "relic": true},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
