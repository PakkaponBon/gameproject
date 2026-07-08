extends Node2D

enum Mode { COMMAND, BUILD, STOCKPILE }

const SOURCE_ID := 0
const GRASS := Vector2i(0, 0)
const DIRT := Vector2i(1, 0)
const WALL := Vector2i(2, 0)

const TREE_SCENE := preload("res://scenes/tree_entity.tscn")
const TREE_COUNT := 40
const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const FOOD_COUNT := 15

var mode := Mode.COMMAND

@onready var ground: TileMapLayer = $Ground
@onready var walls: TileMapLayer = $Walls
@onready var entities: Node2D = $Entities
@onready var pawn: Pawn = $Pawn
@onready var mode_label: Label = $HUD/ModeLabel
@onready var hunger_label: Label = $HUD/HungerLabel

func _ready() -> void:
	_generate_ground()
	_spawn_entities()
	_update_mode_label()
	pawn.hunger_changed.connect(_on_pawn_hunger_changed)
	pawn.died.connect(_on_pawn_died)

func _generate_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.08
	for x in WorldGrid.MAP_SIZE.x:
		for y in WorldGrid.MAP_SIZE.y:
			var tile := DIRT if noise.get_noise_2d(x, y) > 0.25 else GRASS
			ground.set_cell(Vector2i(x, y), SOURCE_ID, tile)

func _spawn_entities() -> void:
	var used := {pawn.cell: true}
	_scatter(TREE_SCENE, TREE_COUNT, used)
	_scatter(FOOD_SCENE, FOOD_COUNT, used)

func _scatter(scene: PackedScene, count: int, used: Dictionary) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 1000:
		attempts += 1
		var cell := Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y)
		if used.has(cell):
			continue
		used[cell] = true
		var node: Node2D = scene.instantiate()
		node.position = WorldGrid.cell_to_world(cell)
		entities.add_child(node)
		placed += 1

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		_set_mode(Mode.BUILD if mode != Mode.BUILD else Mode.COMMAND)
	elif event.is_action_pressed("toggle_stockpile_mode"):
		_set_mode(Mode.STOCKPILE if mode != Mode.STOCKPILE else Mode.COMMAND)
	elif event is InputEventMouseButton and event.pressed:
		_apply_tool(event.button_index)
	elif event is InputEventMouseMotion and mode != Mode.COMMAND:
		# Drag to paint or erase in build/stockpile modes.
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_apply_tool(MOUSE_BUTTON_LEFT)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_apply_tool(MOUSE_BUTTON_RIGHT)

func _apply_tool(button_index: int) -> void:
	var cell := _mouse_cell()
	match mode:
		Mode.COMMAND:
			if button_index == MOUSE_BUTTON_LEFT:
				pawn.move_to(cell)
		Mode.BUILD:
			if button_index == MOUSE_BUTTON_LEFT:
				_place_wall(cell)
			elif button_index == MOUSE_BUTTON_RIGHT:
				_erase_wall(cell)
		Mode.STOCKPILE:
			if button_index == MOUSE_BUTTON_LEFT:
				WorldGrid.set_stockpile(cell, true)
			elif button_index == MOUSE_BUTTON_RIGHT:
				WorldGrid.set_stockpile(cell, false)

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

func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_update_mode_label()

func _on_pawn_hunger_changed(value: float) -> void:
	hunger_label.text = "Hunger: %d" % roundi(value)

func _on_pawn_died() -> void:
	hunger_label.text = "DEAD — colonist starved"

func _update_mode_label() -> void:
	match mode:
		Mode.COMMAND:
			mode_label.text = "COMMAND — LMB move pawn  [B: build] [Z: stockpile]"
		Mode.BUILD:
			mode_label.text = "BUILD — LMB wall, RMB erase  [B: back]"
		Mode.STOCKPILE:
			mode_label.text = "STOCKPILE — LMB paint zone, RMB erase  [Z: back]"
