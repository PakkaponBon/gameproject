class_name WorldSpawner
extends Node
## World generation and entity creation. Main composes and handles input;
## this node owns what gets spawned where. SaveManager drives it on load.

signal pawn_created(pawn: Pawn)

const SOURCE_ID := 0
const GRASS := Vector2i(0, 0)
const DIRT := Vector2i(1, 0)

const TREE_SCENE := preload("res://scenes/tree_entity.tscn")
const TREE_COUNT := 40
const FOOD_SCENE := preload("res://scenes/food_item.tscn")
const FOOD_COUNT := 15
const WOOD_SCENE := preload("res://scenes/wood_item.tscn")
const RAIDER_SCENE := preload("res://scenes/raider.tscn")
const PAWN_SCENE := preload("res://scenes/pawn.tscn")
const PAWN_COUNT := 3
const PAWN_SPAWN_RADIUS := 5  # around map center

var ground_seed := 0

@onready var main: Node2D = get_parent()
@onready var ground: TileMapLayer = main.get_node("Ground")
@onready var entities: Node2D = main.get_node("Entities")

func new_game() -> void:
	ground_seed = randi()
	generate_ground()
	var used := {}
	_spawn_pawns(used)
	_scatter(TREE_SCENE, TREE_COUNT, used)
	_scatter(FOOD_SCENE, FOOD_COUNT, used)

func generate_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = ground_seed
	noise.frequency = 0.08
	for x in WorldGrid.MAP_SIZE.x:
		for y in WorldGrid.MAP_SIZE.y:
			var tile := DIRT if noise.get_noise_2d(x, y) > 0.25 else GRASS
			ground.set_cell(Vector2i(x, y), SOURCE_ID, tile)

func spawn_entity(scene: PackedScene, cell: Vector2i) -> Node2D:
	var node: Node2D = scene.instantiate()
	node.position = WorldGrid.cell_to_world(cell)
	entities.add_child(node)
	return node

## Drop loose wood on a cell, spilling onto free neighbors (refunds etc.).
func drop_wood(cell: Vector2i, count: int) -> void:
	var spots: Array[Vector2i] = [cell, cell + Vector2i.UP, cell + Vector2i.DOWN,
			cell + Vector2i.LEFT, cell + Vector2i.RIGHT]
	var spawned := 0
	for spot in spots:
		if spawned >= count:
			return
		if WorldGrid.in_bounds(spot) and not WorldGrid.is_wall(spot) and not WorldGrid.items.has(spot):
			spawn_entity(WOOD_SCENE, spot)
			spawned += 1
	while spawned < count:  # fallback: stack on the original cell
		spawn_entity(WOOD_SCENE, cell)
		spawned += 1

func create_pawn(cell: Vector2i, pawn_name: String, priorities: Dictionary) -> Pawn:
	var pawn: Pawn = PAWN_SCENE.instantiate()
	pawn.name = pawn_name
	pawn.position = WorldGrid.cell_to_world(cell)
	pawn.work_priorities = priorities
	main.add_child(pawn)  # child of Main so pawns draw above Entities
	pawn_created.emit(pawn)
	return pawn

func _spawn_pawns(used: Dictionary) -> void:
	# Showcase priorities: a lumberjack, a hauler, and a builder-farmer.
	var presets: Array[Dictionary] = [
		{Job.Type.CHOP: 1, Job.Type.HAUL: 2, Job.Type.BUILD: 2, Job.Type.PLANT: 2},
		{Job.Type.CHOP: 2, Job.Type.HAUL: 1, Job.Type.BUILD: 2, Job.Type.PLANT: 2},
		{Job.Type.CHOP: 2, Job.Type.HAUL: 2, Job.Type.BUILD: 1, Job.Type.PLANT: 1},
	]
	var center := WorldGrid.MAP_SIZE / 2
	var count := 0
	while count < PAWN_COUNT:
		var cell := center + Vector2i(
			randi_range(-PAWN_SPAWN_RADIUS, PAWN_SPAWN_RADIUS),
			randi_range(-PAWN_SPAWN_RADIUS, PAWN_SPAWN_RADIUS))
		if used.has(cell):
			continue
		used[cell] = true
		create_pawn(cell, "Pawn %d" % (count + 1), presets[count % presets.size()].duplicate())
		count += 1

func _scatter(scene: PackedScene, count: int, used: Dictionary) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 1000:
		attempts += 1
		var cell := Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y)
		if used.has(cell):
			continue
		used[cell] = true
		spawn_entity(scene, cell)
		placed += 1
