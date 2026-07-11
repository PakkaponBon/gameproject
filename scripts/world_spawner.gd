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
const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")
const ORE_SCENE := preload("res://scenes/ore_node.tscn")
const STONE_NODES := 12
const IRON_NODES := 8
const RAIDER_SCENE := preload("res://scenes/raider.tscn")
const GRAVE_SCENE := preload("res://scenes/grave.tscn")
const CRITTER_SCENE := preload("res://scenes/critter.tscn")
const SPRITES := preload("res://assets/sprites.png")
const DECOR_SPRITES := [19, 20, 21, 22]  # flower, pebbles, bush, mushroom
const DECOR_COUNT := 70
const CRITTER_COUNT := 4
const PAWN_SCENE := preload("res://scenes/pawn.tscn")
const PAWN_COUNT := 3
const PAWN_SPAWN_RADIUS := 5  # around map center
const NAMES := ["Alda", "Bren", "Cort", "Dara", "Edwin", "Fenna", "Garet",
		"Hilda", "Ivo", "Joss", "Kessa", "Lorn", "Mera", "Noll", "Osric"]

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
	_scatter_ore("stone", STONE_NODES, used)
	_scatter_ore("iron_ore", IRON_NODES, used)

func generate_ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = ground_seed
	noise.frequency = 0.08
	for x in WorldGrid.MAP_SIZE.x:
		for y in WorldGrid.MAP_SIZE.y:
			var tile := DIRT if noise.get_noise_2d(x, y) > 0.25 else GRASS
			ground.set_cell(Vector2i(x, y), SOURCE_ID, tile)
	_scatter_decor()

## Cosmetic scatter (flowers, pebbles, bushes, mushrooms). Seeded from the
## terrain, so loads regenerate the exact same meadow — nothing to save.
func _scatter_decor() -> void:
	for child in ground.get_children():
		child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = ground_seed + 7
	for i in DECOR_COUNT:
		var sprite := Sprite2D.new()
		sprite.texture = SPRITES
		sprite.region_enabled = true
		sprite.region_rect = Rect2(DECOR_SPRITES[rng.randi() % DECOR_SPRITES.size()] * 16, 0, 16, 16)
		var cell := Vector2i(rng.randi() % WorldGrid.MAP_SIZE.x, rng.randi() % WorldGrid.MAP_SIZE.y)
		sprite.position = WorldGrid.cell_to_world(cell)
		ground.add_child(sprite)

func spawn_critters() -> void:
	for i in CRITTER_COUNT:
		var critter: Critter = CRITTER_SCENE.instantiate()
		var body: Sprite2D = critter.get_node("Body")
		if i % 2 == 1:  # every other one is a bird
			body.region_rect = Rect2(384, 0, 16, 16)
		critter.position = WorldGrid.cell_to_world(
				Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y))
		entities.add_child(critter)

func spawn_entity(scene: PackedScene, cell: Vector2i) -> Node2D:
	var node: Node2D = scene.instantiate()
	node.position = WorldGrid.cell_to_world(cell)
	entities.add_child(node)
	return node

func spawn_resource(cell: Vector2i, id: String) -> ResourceItem:
	var item: ResourceItem = RESOURCE_SCENE.instantiate()
	item.resource_id = id
	item.position = WorldGrid.cell_to_world(cell)
	entities.add_child(item)
	return item

func spawn_raider(cell: Vector2i, boss: bool) -> Raider:
	var raider: Raider = RAIDER_SCENE.instantiate()
	raider.is_boss = boss
	raider.position = WorldGrid.cell_to_world(cell)
	entities.add_child(raider)
	return raider

func spawn_ore(cell: Vector2i, id: String) -> OreNode:
	var node: OreNode = ORE_SCENE.instantiate()
	node.resource_id = id
	node.position = WorldGrid.cell_to_world(cell)
	entities.add_child(node)
	return node

## Drop loose resources on a cell, spilling onto free neighbors (refunds etc.).
func drop_resource(cell: Vector2i, id: String, count: int) -> void:
	var spots: Array[Vector2i] = [cell, cell + Vector2i.UP, cell + Vector2i.DOWN,
			cell + Vector2i.LEFT, cell + Vector2i.RIGHT]
	var spawned := 0
	for spot in spots:
		if spawned >= count:
			return
		if WorldGrid.in_bounds(spot) and not WorldGrid.is_wall(spot) and not WorldGrid.items.has(spot):
			spawn_resource(spot, id)
			spawned += 1
	while spawned < count:  # fallback: stack on the original cell
		spawn_resource(cell, id)
		spawned += 1

func _scatter_ore(id: String, count: int, used: Dictionary) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 1000:
		attempts += 1
		var cell := Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y)
		if used.has(cell):
			continue
		used[cell] = true
		spawn_ore(cell, id)
		placed += 1

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
		var pawn := create_pawn(cell, unused_name(), presets[count % presets.size()].duplicate())
		# Each founding survivor carries a scar from the fall + a quirk.
		var pool := TraitDefs.BACKSTORIES.duplicate()
		pool.shuffle()
		pawn.traits = [pool[count % pool.size()]]
		pawn.traits.append_array(_random_traits().slice(0, 1))
		# Varied starting talent — most colonies roll at least one archer.
		pawn.skills.xp["melee"] = float(randi_range(0, 150))
		pawn.skills.xp["archery"] = float(randi_range(0, 450))
		count += 1

## A name no living villager carries.
func unused_name() -> String:
	var taken := {}
	for node in get_tree().get_nodes_in_group("pawns"):
		taken[String(node.name)] = true
	var pool := NAMES.duplicate()
	pool.shuffle()
	for candidate: String in pool:
		if not taken.has(candidate):
			return candidate
	return "Wanderer %d" % randi_range(2, 99)

func _random_traits() -> Array:
	var pool := TraitDefs.ORDER.duplicate()
	pool.shuffle()
	return pool.slice(0, 1 + randi() % 2)  # 1-2 traits each

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
