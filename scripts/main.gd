extends Node2D

const MAP_WIDTH := 64
const MAP_HEIGHT := 64
const SOURCE_ID := 0

const GRASS := Vector2i(0, 0)
const DIRT := Vector2i(1, 0)
const WALL := Vector2i(2, 0)

@onready var ground: TileMapLayer = $Ground
@onready var walls: TileMapLayer = $Walls

func _ready() -> void:
	_generate_ground()

func _generate_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	for x in MAP_WIDTH:
		for y in MAP_HEIGHT:
			var tile := DIRT if noise.get_noise_2d(x, y) > 0.25 else GRASS
			ground.set_cell(Vector2i(x, y), SOURCE_ID, tile)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_wall()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_erase_wall()
	elif event is InputEventMouseMotion:
		# Drag to paint or erase.
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_place_wall()
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_erase_wall()

func _place_wall() -> void:
	var cell := walls.local_to_map(walls.get_local_mouse_position())
	if _in_bounds(cell):
		walls.set_cell(cell, SOURCE_ID, WALL)

func _erase_wall() -> void:
	walls.erase_cell(walls.local_to_map(walls.get_local_mouse_position()))

func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < MAP_WIDTH and cell.y < MAP_HEIGHT
