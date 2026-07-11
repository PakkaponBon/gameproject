class_name FoodItem
extends Node2D
## Edible pickup. Pawns find food via the "food" group; eating frees it.

var cell: Vector2i
var meal := false  # cooked at a stove: fills up and lifts the mood
var reserved := false  # claimed by a pawn heading here to eat

func _ready() -> void:
	add_to_group("food")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
	if meal:
		($Body as Sprite2D).modulate = Color(1.15, 1.0, 0.7)  # golden crust
