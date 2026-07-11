class_name CropDefs
extends RefCounted
## Crop catalog — data over code. Adding a crop = adding an entry.
## grow_days vs yield is the field-planning tradeoff: fast-and-thin
## (potato) vs slow-and-rich (wheat), with berries in between.

const ORDER := ["potato", "wheat", "berries", "herbs"]

const DEFS := {
	"potato": {"name": "Potato", "grow_days": 1.5, "yield": 1, "color": Color(0.85, 0.75, 0.45)},
	"wheat": {"name": "Wheat", "grow_days": 3.0, "yield": 3, "color": Color(0.9, 0.8, 0.35)},
	"berries": {"name": "Berries", "grow_days": 2.0, "yield": 2, "color": Color(0.7, 0.3, 0.45)},
	"herbs": {"name": "Healing Herbs", "grow_days": 2.0, "yield": 2,
			"color": Color(0.35, 0.8, 0.6), "resource_output": "herb"},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
