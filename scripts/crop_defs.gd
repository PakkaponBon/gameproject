class_name CropDefs
extends RefCounted
## Crop catalog — data over code. Adding a crop = adding an entry.
## grow_days vs yield is the field-planning tradeoff: fast-and-thin
## (potato) vs slow-and-rich (wheat), with berries in between.

## Ordered fast-and-thin → slow-and-rich so the field palette reads as a
## tradeoff ladder. All output food except herbs. Barley + flax are held
## for v1.2's brewing/cloth chains so no crop yields a dead-end resource.
const ORDER := ["turnip", "carrot", "potato", "beans", "cabbage",
		"berries", "wheat", "corn", "pumpkin", "herbs"]

const DEFS := {
	"turnip": {"name": "Turnip", "grow_days": Balance.TURNIP_GROW_DAYS,
			"yield": Balance.TURNIP_YIELD, "color": Color(0.88, 0.82, 0.95)},
	"carrot": {"name": "Carrot", "grow_days": 1.5, "yield": 2, "color": Color(0.95, 0.6, 0.25)},
	"potato": {"name": "Potato", "grow_days": 1.5, "yield": 1, "color": Color(0.85, 0.75, 0.45)},
	"beans": {"name": "Beans", "grow_days": 2.0, "yield": 2, "color": Color(0.55, 0.75, 0.4)},
	"cabbage": {"name": "Cabbage", "grow_days": 2.5, "yield": 3, "color": Color(0.5, 0.8, 0.55)},
	"berries": {"name": "Berries", "grow_days": 2.0, "yield": 2, "color": Color(0.7, 0.3, 0.45)},
	"wheat": {"name": "Wheat", "grow_days": 3.0, "yield": 3, "color": Color(0.9, 0.8, 0.35)},
	"corn": {"name": "Corn", "grow_days": 3.5, "yield": 4, "color": Color(0.95, 0.85, 0.3)},
	"pumpkin": {"name": "Pumpkin", "grow_days": 4.0, "yield": 5, "color": Color(0.9, 0.5, 0.2)},
	"herbs": {"name": "Healing Herbs", "grow_days": 2.0, "yield": 2,
			"color": Color(0.35, 0.8, 0.6), "resource_output": "herb"},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
