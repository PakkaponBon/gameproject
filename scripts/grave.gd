class_name Grave
extends Node2D
## Marks where a villager died. Permanent, walkable, saved.
## Tone rule: death is a knockdown-and-fade, then this — no gore.

var cell: Vector2i

func _ready() -> void:
	add_to_group("graves")
	cell = WorldGrid.world_to_cell(position)
	position = WorldGrid.cell_to_world(cell)
