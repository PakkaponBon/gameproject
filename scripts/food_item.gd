class_name FoodItem
extends Node2D
## Edible pickup. Pawns find food via the "food" group; eating frees it.

var cell: Vector2i
var reserved := false  # claimed by a pawn heading here to eat

func _ready() -> void:
	add_to_group("food")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
