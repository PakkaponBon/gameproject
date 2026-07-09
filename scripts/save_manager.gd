extends Node
## Autoload: serializes the whole session to versioned JSON and rebuilds it
## on load. Loading reloads the main scene; `pending_load` survives the
## reload because this is an autoload, and the fresh Main applies it.

const SAVE_VERSION := 4
const MANUAL_SAVE_PATH := "user://save.json"
const AUTOSAVE_PATH := "user://autosave.json"
## Interim cadence — switches to "each morning" when Phase 3 adds the calendar.
const AUTOSAVE_EVERY_TICKS := 1800  # 3 in-game minutes at 10 ticks/sec

var pending_load: Dictionary = {}
var main: Node2D = null  # current Main scene; re-registers itself each load
var ticks_since_autosave := 0

func _ready() -> void:
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	# main is briefly a freed instance while the scene reloads on load_game.
	if not is_instance_valid(main):
		return
	ticks_since_autosave += 1
	if ticks_since_autosave >= AUTOSAVE_EVERY_TICKS:
		ticks_since_autosave = 0
		save_game(AUTOSAVE_PATH)

func save_game(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save file: %s" % path)
		return
	file.store_string(JSON.stringify(_collect()))

func load_game(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("No save file at %s" % path)
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data == null or int(data.get("version", -1)) != SAVE_VERSION:
		push_error("Save file is corrupt or has an incompatible version")
		return false
	pending_load = data
	get_tree().paused = false
	get_tree().reload_current_scene()
	return true

# --- saving ---------------------------------------------------------------

func _collect() -> Dictionary:
	var built: Array = []
	for cell: Vector2i in WorldGrid.buildings:
		built.append({"cell": _v(cell), "id": WorldGrid.buildings[cell]})
	var trees: Array = []
	for node in get_tree().get_nodes_in_group("trees"):
		var tree := node as TreeEntity
		trees.append({"cell": _v(tree.cell), "work": tree.job.work_ticks})
	var wood: Array = []
	for node in get_tree().get_nodes_in_group("wood"):
		var item := node as WoodItem
		if item.get_parent() is Pawn:
			continue  # carried wood is saved with its pawn
		wood.append(_v(item.cell))
	var food: Array = []
	for node in get_tree().get_nodes_in_group("food"):
		food.append(_v((node as FoodItem).cell))
	var raiders: Array = []
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		raiders.append({
			"cell": _v(raider.cell),
			"hp": raider.hp,
			"atk_cd": raider.attack_cooldown,
			"move_cd": raider.move_cooldown,
		})
	var blueprints: Array = []
	for cell: Vector2i in main.blueprints:
		var bp: Blueprint = main.blueprints[cell]
		blueprints.append({
			"cell": _v(cell),
			"id": bp.building_id,
			"delivered": bp.delivered,
			"work": bp.build_job.work_ticks if bp.build_job else -1,
		})
	var camera: Camera2D = main.get_node("Camera")
	return {
		"version": SAVE_VERSION,
		"clock_ticks": GameClock.ticks,
		"raid_ticks": main.raid_director.ticks_until_raid,
		"ground_seed": main.spawner.ground_seed,
		"buildings": built,
		"stockpiles": WorldGrid.stockpile_cells.keys().map(_v),
		"trees": trees,
		"wood": wood,
		"food": food,
		"raiders": raiders,
		"blueprints": blueprints,
		"pawns": main.pawns.map(_pawn_data),
		"selected": main.pawns.find(main.selected),
		"camera": {"pos": [camera.position.x, camera.position.y], "zoom": camera.zoom.x},
	}

func _pawn_data(pawn: Pawn) -> Dictionary:
	var priorities := {}
	for type: int in pawn.work_priorities:
		priorities[str(type)] = pawn.work_priorities[type]
	return {
		"name": String(pawn.name),
		"cell": _v(pawn.cell),
		"target": _v(pawn.target_cell),
		"hunger": pawn.needs.hunger,
		"mood": pawn.needs.mood,
		"on_break": pawn.needs.on_break,
		"hp": pawn.combat.hp,
		"atk_cd": pawn.combat.attack_cooldown,
		"wander_cd": pawn.wander_cooldown,
		"dead": pawn.dead,
		"priorities": priorities,
		"job_cell": _v(pawn.work.job.cell) if pawn.work.job else [],
		"job_type": int(pawn.work.job.type) if pawn.work.job else -1,
		"carrying": pawn.work.carrying != null,
		"reserved_dest": _v(pawn.work.reserved_dest),
		"food_cell": _v(pawn.food_target.cell) if pawn.food_target else [],
		"eat_ticks": pawn.eat_ticks_left,
	}

# --- loading ---------------------------------------------------------------

## Called by Main._ready in the freshly reloaded scene.
func apply_pending_load() -> void:
	var data := pending_load
	pending_load = {}
	WorldGrid.reset()
	JobManager.reset()
	GameClock.ticks = int(data.clock_ticks)
	main.raid_director.ticks_until_raid = int(data.raid_ticks)
	var spawner: WorldSpawner = main.spawner
	spawner.ground_seed = int(data.ground_seed)
	spawner.generate_ground()
	for b: Dictionary in data.buildings:
		main.place_building(_vec(b.cell), b.id)
	for s: Array in data.stockpiles:
		WorldGrid.set_stockpile(_vec(s), true)
	for t: Dictionary in data.trees:
		var tree: TreeEntity = spawner.spawn_entity(spawner.TREE_SCENE, _vec(t.cell))
		tree.job.work_ticks = int(t.work)
	for w: Array in data.wood:
		spawner.spawn_entity(spawner.WOOD_SCENE, _vec(w))
	for f: Array in data.food:
		spawner.spawn_entity(spawner.FOOD_SCENE, _vec(f))
	for r: Dictionary in data.raiders:
		var raider: Raider = spawner.spawn_entity(spawner.RAIDER_SCENE, _vec(r.cell))
		raider.hp = float(r.hp)
		raider.attack_cooldown = int(r.atk_cd)
		raider.move_cooldown = int(r.move_cd)
	for b: Dictionary in data.blueprints:
		main.place_blueprint(_vec(b.cell), b.id)
		var bp: Blueprint = main.blueprints[_vec(b.cell)]
		bp.restore(int(b.delivered), int(b.work))
	for p: Dictionary in data.pawns:
		_restore_pawn(p)
	main.select_pawn(int(data.selected))
	var camera: Camera2D = main.get_node("Camera")
	camera.position = Vector2(float(data.camera.pos[0]), float(data.camera.pos[1]))
	camera.zoom = Vector2.ONE * float(data.camera.zoom)

func _restore_pawn(p: Dictionary) -> void:
	var priorities := {}
	for key: String in p.priorities:
		priorities[int(key)] = int(p.priorities[key])
	var pawn: Pawn = main.spawner.create_pawn(_vec(p.cell), p.name, priorities)
	pawn.needs.hunger = float(p.hunger)
	pawn.needs.mood = float(p.mood)
	pawn.needs.on_break = bool(p.on_break)
	pawn.combat.hp = float(p.hp)
	pawn.combat.attack_cooldown = int(p.atk_cd)
	pawn.wander_cooldown = int(p.wander_cd)
	pawn.target_cell = _vec(p.target)
	if bool(p.dead):
		pawn.restore_dead()
		return
	# Carrying and a job can coexist: a SUPPLY pawn carries wood toward
	# its blueprint. Restore both independently.
	if bool(p.carrying):
		var wood: WoodItem = main.spawner.spawn_entity(main.spawner.WOOD_SCENE, pawn.cell)
		pawn.work.restore_carry(wood, _vec(p.reserved_dest))
	if int(p.job_type) >= 0:
		# Entities re-registered their jobs above; re-claim ours by cell+type.
		var job_cell := _vec(p.job_cell)
		for job in JobManager.jobs:
			if job.cell == job_cell and int(job.type) == int(p.job_type) and not job.reserved:
				job.reserved = true
				pawn.work.job = job
				break
	var food_cell: Array = p.food_cell
	if not food_cell.is_empty():
		_relink_food(pawn, _vec(food_cell), int(p.eat_ticks))

func _relink_food(pawn: Pawn, food_cell: Vector2i, eat_ticks: int) -> void:
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		if food.cell == food_cell and not food.reserved:
			food.reserved = true
			pawn.food_target = food
			pawn.eat_ticks_left = eat_ticks
			return

# --- helpers ---------------------------------------------------------------

func _v(v: Vector2i) -> Array:
	return [v.x, v.y]

func _vec(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))
