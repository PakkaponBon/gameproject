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
const BUSH_SCENE := preload("res://scenes/berry_bush.tscn")
const LIVESTOCK_SCENE := preload("res://scenes/livestock.tscn")
const RESOURCE_SCENE := preload("res://scenes/resource_item.tscn")
const ORE_SCENE := preload("res://scenes/ore_node.tscn")
const STONE_NODES := 12
const IRON_NODES := 8
const RAIDER_SCENE := preload("res://scenes/raider.tscn")
const GRAVE_SCENE := preload("res://scenes/grave.tscn")
const CRITTER_SCENE := preload("res://scenes/critter.tscn")
const SPRITES := preload("res://assets/sprites.png")
const DECOR_SPRITES := [19, 20, 21, 22]  # flower, pebbles, bush, mushroom
const DECOR_COUNT := 260  # density pass: almost no empty clusters
const CRITTER_COUNT := 4
const LANDMARK_COUNT := 6  # frontier places per 64x64; scaled up with map area
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
	var scenario := ScenarioDefs.current()
	# Start in the chosen season (Hard Winter opens in autumn — winter looms).
	GameClock.ticks = int(scenario.start_season) * GameClock.DAYS_PER_SEASON * GameClock.TICKS_PER_DAY
	ground_seed = randi()
	generate_ground()
	var used := {}
	_spawn_pawns(used, int(scenario.pawns))  # founders stay a small band, centered
	_scatter(TREE_SCENE, scaled(TREE_COUNT), used)
	_scatter_bushes(scaled(int(scenario.start_food)), used)
	_scatter_ore("stone", scaled(STONE_NODES), used)
	_scatter_ore("iron_ore", scaled(IRON_NODES), used)
	_guarantee_start_resources(used)
	_scatter_landmarks(scaled(LANDMARK_COUNT), used)  # the frontier: places to find out there

## Scale a count tuned for the original 64x64 map to the current map area,
## so a bigger world stays populated instead of barren (and auto-adjusts if
## MAP_SIZE changes again).
func scaled(base: int) -> int:
	return int(round(float(base) * WorldGrid.MAP_SIZE.x * WorldGrid.MAP_SIZE.y / 4096.0))

## Mapgen constraint (POLISH.md): wood and stone always near the wagon.
func _guarantee_start_resources(used: Dictionary) -> void:
	var center := WorldGrid.MAP_SIZE / 2
	var placed := {"tree": 0, "stone": 0, "iron": 0}
	var want := {"tree": 6, "stone": 2, "iron": 1}
	for attempt in 400:
		if placed.tree >= want.tree and placed.stone >= want.stone and placed.iron >= want.iron:
			return
		var cell := center + Vector2i(randi_range(-9, 9), randi_range(-9, 9))
		if used.has(cell) or not WorldGrid.in_bounds(cell) or WorldGrid.is_wall(cell):
			continue
		used[cell] = true
		if placed.tree < want.tree:
			spawn_entity(TREE_SCENE, cell)
			placed.tree += 1
		elif placed.stone < want.stone:
			spawn_ore(cell, "stone")
			placed.stone += 1
		else:
			spawn_ore(cell, "iron_ore")
			placed.iron += 1

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
	for i in scaled(DECOR_COUNT):
		var sprite := Sprite2D.new()
		sprite.texture = SPRITES
		sprite.region_enabled = true
		sprite.region_rect = Rect2(DECOR_SPRITES[rng.randi() % DECOR_SPRITES.size()] * 16, 0, 16, 16)
		var cell := Vector2i(rng.randi() % WorldGrid.MAP_SIZE.x, rng.randi() % WorldGrid.MAP_SIZE.y)
		sprite.position = WorldGrid.cell_to_world(cell)
		ground.add_child(sprite)
	_place_scenery(rng)

## 2-3 oversized features per map: a great tree, standing stones, a ruin.
## Pure set dressing (cosmetic) — breaks the grid feel, gives the map identity.
## Interactive frontier landmarks are a separate system (see _scatter_landmarks).
func _place_scenery(rng: RandomNumberGenerator) -> void:
	var specs := [
		{"region": Rect2(16, 0, 16, 16), "scale": 3.0, "tint": Color(0.85, 0.95, 0.85)},   # great tree
		{"region": Rect2(272, 0, 16, 16), "scale": 2.2, "tint": Color(0.8, 0.8, 0.9)},     # standing stone
		{"region": Rect2(208, 0, 16, 16), "scale": 2.5, "tint": Color(0.75, 0.75, 0.8)},   # old ruin marker
	]
	for spec: Dictionary in specs:
		var sprite := Sprite2D.new()
		sprite.texture = SPRITES
		sprite.region_enabled = true
		sprite.region_rect = spec.region
		sprite.scale = Vector2.ONE * float(spec.scale)
		sprite.modulate = spec.tint
		var cell := Vector2i(6 + rng.randi() % (WorldGrid.MAP_SIZE.x - 12),
				6 + rng.randi() % (WorldGrid.MAP_SIZE.y - 12))
		sprite.position = WorldGrid.cell_to_world(cell)
		ground.add_child(sprite)

func spawn_critters() -> void:
	for i in scaled(CRITTER_COUNT):
		spawn_one_critter(i % 2 == 1)  # every other one is a bird

## One critter. Rabbits (and boars) are huntable game; birds stay set
## dressing. A boar yields more meat but wounds whoever corners it.
func spawn_one_critter(is_bird: bool, boar := false) -> void:
	var critter: Critter = CRITTER_SCENE.instantiate()
	critter.huntable = not is_bird
	var body: Sprite2D = critter.get_node("Body")
	if is_bird:
		body.region_rect = Rect2(384, 0, 16, 16)
	elif boar:
		critter.fierce = true
		critter.meat_count = Balance.MEAT_PER_KILL + 1
		body.modulate = Color(0.55, 0.42, 0.32)  # dark bristled hide
		body.scale = Vector2(1.15, 1.15)
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

func spawn_bush(cell: Vector2i, with_berries: bool) -> BerryBush:
	var bush: BerryBush = BUSH_SCENE.instantiate()
	bush.start_with_berries = with_berries
	bush.position = WorldGrid.cell_to_world(cell)
	entities.add_child(bush)
	return bush

## Wild forage: each bush starts bearing food, then regrows after picking.
func _scatter_bushes(count: int, used: Dictionary) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 1000:
		attempts += 1
		var cell := Vector2i(randi() % WorldGrid.MAP_SIZE.x, randi() % WorldGrid.MAP_SIZE.y)
		if used.has(cell):
			continue
		used[cell] = true
		spawn_bush(cell, true)
		placed += 1

func spawn_livestock(cell: Vector2i, kind: String, lay_timer := 0) -> Livestock:
	var animal: Livestock = LIVESTOCK_SCENE.instantiate()
	animal.kind = kind
	animal.lay_timer = lay_timer
	animal.position = WorldGrid.cell_to_world(cell)
	entities.add_child(animal)
	return animal

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

## Build a frontier landmark in code (no scene). def_id must be set before the
## node enters the tree, so _ready can size/tint its sprite from the catalog.
func spawn_landmark(cell: Vector2i, def_id: String, discovered := false,
		claimed := false, regrow := 0) -> Landmark:
	var node := Landmark.new()
	node.def_id = def_id
	node.discovered = discovered
	node.claimed = claimed
	node.regrow_ticks = regrow
	node.spawner_ref = self  # so it can drop its reward goods on investigate
	node.position = WorldGrid.cell_to_world(cell)
	entities.add_child(node)
	return node

## Scatter landmarks across the open map, each kept its own minimum distance
## from home so the reward is genuinely *out there* (seeded, so a given world
## seed lays them the same; they're also saved, so reloads are exact).
func _scatter_landmarks(count: int, used: Dictionary) -> void:
	var center := WorldGrid.MAP_SIZE / 2
	var rng := RandomNumberGenerator.new()
	rng.seed = ground_seed + 99
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 2000:
		attempts += 1
		var id := LandmarkDefs.random_id(rng)
		var def := LandmarkDefs.get_def(id)
		var min_dist: int = def.min_dist
		var cell := Vector2i(4 + rng.randi() % (WorldGrid.MAP_SIZE.x - 8),
				4 + rng.randi() % (WorldGrid.MAP_SIZE.y - 8))
		if used.has(cell) or not WorldGrid.in_bounds(cell) or WorldGrid.is_wall(cell):
			continue
		if float((cell - center).length_squared()) < float(min_dist * min_dist):
			continue
		used[cell] = true
		spawn_landmark(cell, id)
		placed += 1

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
	entities.add_child(pawn)  # y-sorted with trees and props
	pawn_created.emit(pawn)
	return pawn

func _spawn_pawns(used: Dictionary, pawn_count := PAWN_COUNT) -> void:
	# Showcase priorities: a lumberjack, a hauler, and a builder-farmer.
	var presets: Array[Dictionary] = [
		{Job.Type.CHOP: 1, Job.Type.HAUL: 2, Job.Type.BUILD: 2, Job.Type.PLANT: 2},
		{Job.Type.CHOP: 2, Job.Type.HAUL: 1, Job.Type.BUILD: 2, Job.Type.PLANT: 2},
		{Job.Type.CHOP: 2, Job.Type.HAUL: 2, Job.Type.BUILD: 1, Job.Type.PLANT: 1},
	]
	var center := WorldGrid.MAP_SIZE / 2
	var count := 0
	while count < pawn_count:
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
