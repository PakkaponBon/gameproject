class_name Pawn
extends Node2D

## How fast the sprite eases toward its logical cell (rendering only).
const LERP_WEIGHT := 12.0

var cell: Vector2i
var target_cell: Vector2i

func _ready() -> void:
	cell = WorldGrid.world_to_cell(position)
	target_cell = cell
	position = WorldGrid.cell_to_world(cell)
	GameClock.ticked.connect(_on_tick)

func move_to(destination: Vector2i) -> void:
	if WorldGrid.in_bounds(destination):
		target_cell = destination

func _on_tick() -> void:
	if cell == target_cell:
		return
	# Repath every tick so walls placed mid-walk are respected immediately.
	# allow_partial_path lets a click on a wall walk to the closest reachable cell.
	var path: Array[Vector2i] = WorldGrid.astar.get_id_path(cell, target_cell, true)
	if path.size() < 2:
		target_cell = cell
		return
	cell = path[1]

func _process(delta: float) -> void:
	# Rendering only: ease the visual position toward the logical grid cell.
	position = position.lerp(WorldGrid.cell_to_world(cell), minf(1.0, LERP_WEIGHT * delta))
