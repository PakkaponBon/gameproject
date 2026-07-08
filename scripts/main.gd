extends Node2D

const SOURCE_ID := 0
const GRASS := Vector2i(0, 0)
const DIRT := Vector2i(1, 0)
const WALL := Vector2i(2, 0)

var build_mode := false

@onready var ground: TileMapLayer = $Ground
@onready var walls: TileMapLayer = $Walls
@onready var pawn: Pawn = $Pawn
@onready var mode_label: Label = $HUD/ModeLabel

func _ready() -> void:
	_generate_ground()
	_update_mode_label()

func _generate_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	for x in WorldGrid.MAP_SIZE.x:
		for y in WorldGrid.MAP_SIZE.y:
			var tile := DIRT if noise.get_noise_2d(x, y) > 0.25 else GRASS
			ground.set_cell(Vector2i(x, y), SOURCE_ID, tile)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		build_mode = not build_mode
		_update_mode_label()
	elif event is InputEventMouseButton and event.pressed:
		_handle_click(event.button_index)
	elif event is InputEventMouseMotion and build_mode:
		# Drag to paint or erase while in build mode.
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_place_wall(_mouse_cell())
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_erase_wall(_mouse_cell())

func _handle_click(button_index: int) -> void:
	var cell := _mouse_cell()
	if build_mode:
		if button_index == MOUSE_BUTTON_LEFT:
			_place_wall(cell)
		elif button_index == MOUSE_BUTTON_RIGHT:
			_erase_wall(cell)
	elif button_index == MOUSE_BUTTON_LEFT:
		pawn.move_to(cell)

func _mouse_cell() -> Vector2i:
	return WorldGrid.world_to_cell(get_global_mouse_position())

func _place_wall(cell: Vector2i) -> void:
	# Never wall in the pawn's own cell.
	if not WorldGrid.in_bounds(cell) or cell == pawn.cell:
		return
	WorldGrid.set_wall(cell, true)
	walls.set_cell(cell, SOURCE_ID, WALL)

func _erase_wall(cell: Vector2i) -> void:
	WorldGrid.set_wall(cell, false)
	walls.erase_cell(cell)

func _update_mode_label() -> void:
	if build_mode:
		mode_label.text = "BUILD — LMB place wall, RMB erase  [B: command mode]"
	else:
		mode_label.text = "COMMAND — LMB move pawn  [B: build mode]"
