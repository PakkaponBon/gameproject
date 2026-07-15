class_name FoodItem
extends Node2D
## Edible pickup. Pawns find food via the "food" group; eating frees it.
## kind: "raw" (forage/harvest) | "meal" (cooked, +mood) | "stew" (cooked
## from more raw food, +mood +joy — comfort in the cold).

const TINTS := {
	"meal": Color(1.15, 1.0, 0.7),   # golden crust
	"stew": Color(1.15, 0.85, 0.6),  # warm and hearty
}

var cell: Vector2i
var kind := "raw"
var reserved := false  # claimed by a pawn heading here to eat

func _ready() -> void:
	add_to_group("food")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	if TINTS.has(kind):
		($Body as Sprite2D).modulate = TINTS[kind]

func is_cooked() -> bool:
	return kind != "raw"
