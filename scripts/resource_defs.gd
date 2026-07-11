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
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
