class_name BuildingDefs
extends RefCounted
## Building catalog — data over code. Adding a building means adding an
## entry here (and an atlas tile), never a new script.

const DEFS := {
	"wall": {
		"name": "Wall",
		"cost": {"wood": 1},
		"build_ticks": 20,  # 2s at 10 ticks/sec
		"solid": true,
		"tile": Vector2i(2, 0),  # atlas coords in the shared tileset
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS[id]
