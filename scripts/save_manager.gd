extends Node
## Autoload: serializes the whole session to versioned JSON and rebuilds it
## on load. Loading reloads the main scene; `pending_load` survives the
## reload because this is an autoload, and the fresh Main applies it.

const SAVE_VERSION := 9
const MANUAL_SAVE_PATH := "user://save.json"
const AUTOSAVE_PATH := "user://autosave.json"

var pending_load: Dictionary = {}
var main: Node2D = null  # current Main scene; re-registers itself each load

func _ready() -> void:
	GameClock.day_started.connect(_on_day_started)

## Autosave each morning.
func _on_day_started(_day: int) -> void:
	# main is briefly a freed instance while the scene reloads on load_game.
	if is_instance_valid(main):
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
	var loose_items: Array = []
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if item.get_parent() is Pawn:
			continue  # carried items are saved with their pawn
		loose_items.append({"cell": _v(item.cell), "id": item.resource_id})
	var ore_nodes: Array = []
	for node in get_tree().get_nodes_in_group("ore_nodes"):
		var ore := node as OreNode
		ore_nodes.append({"cell": _v(ore.cell), "id": ore.resource_id, "work": ore.job.work_ticks})
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
	var decon: Array = []
	for cell: Vector2i in main.decon_orders:
		decon.append({"cell": _v(cell), "work": main.decon_orders[cell].job.work_ticks})
	var field_zones: Array = []
	for cell: Vector2i in WorldGrid.fields:
		field_zones.append({"cell": _v(cell), "crop": WorldGrid.fields[cell]})
	var crops: Array = []
	for node in get_tree().get_nodes_in_group("crops"):
		var crop := node as Crop
		crops.append({"cell": _v(crop.cell), "id": crop.crop_id, "growth": crop.growth_ticks})
	var camera: Camera2D = main.get_node("Camera")
	return {
		"version": SAVE_VERSION,
		"clock_ticks": GameClock.ticks,
		"raid_ticks": main.raid_director.ticks_until_raid,
		"ground_seed": main.spawner.ground_seed,
		"buildings": built,
		"stockpiles": WorldGrid.stockpile_cells.keys().map(_v),
		"trees": trees,
		"items": loose_items,
		"ore_nodes": ore_nodes,
		"food": food,
		"raiders": raiders,
		"blueprints": blueprints,
		"decon_orders": decon,
		"fields": field_zones,
		"crops": crops,
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
		"rest": pawn.needs.rest,
		"mood": pawn.needs.mood,
		"on_break": pawn.needs.on_break,
		"sleeping": pawn.survival.sleeping,
		"bed": _v(pawn.survival.bed_cell),
		"hp": pawn.combat.hp,
		"atk_cd": pawn.combat.attack_cooldown,
		"wander_cd": pawn.wander_cooldown,
		"dead": pawn.dead,
		"collapsed": pawn.collapsed,
		"carrying_food": pawn.work.carrying_food,
		"carrying_id": pawn.work.carrying.resource_id if pawn.work.carrying else "",
		"priorities": priorities,
		"job_cell": _v(pawn.work.job.cell) if pawn.work.job else [],
		"job_type": int(pawn.work.job.type) if pawn.work.job else -1,
		"reserved_dest": _v(pawn.work.reserved_dest),
		"food_cell": _v(pawn.survival.food_target.cell) if pawn.survival.food_target else [],
		"eat_ticks": pawn.survival.eat_ticks_left,
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
	for i: Dictionary in data.items:
		spawner.spawn_resource(_vec(i.cell), i.id)
	for o: Dictionary in data.ore_nodes:
		var ore: OreNode = spawner.spawn_ore(_vec(o.cell), o.id)
		ore.restore(int(o.work))
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
	for d: Dictionary in data.decon_orders:
		main.mark_deconstruct(_vec(d.cell))
		main.decon_orders[_vec(d.cell)].restore(int(d.work))
	for f: Dictionary in data.fields:
		WorldGrid.set_field(_vec(f.cell), f.crop)
	for c: Dictionary in data.crops:
		var crop: Crop = main.field_keeper.spawn_crop(_vec(c.cell), c.id)
		crop.restore(int(c.growth))
	main.field_keeper.sync_all()  # plant jobs for empty, non-winter field cells
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
	pawn.needs.rest = float(p.rest)
	pawn.needs.mood = float(p.mood)
	pawn.needs.on_break = bool(p.on_break)
	pawn.survival.bed_cell = _vec(p.bed)
	if bool(p.sleeping):
		pawn.survival.restore_sleep()
	pawn.combat.hp = float(p.hp)
	pawn.combat.attack_cooldown = int(p.atk_cd)
	pawn.wander_cooldown = int(p.wander_cd)
	pawn.target_cell = _vec(p.target)
	if bool(p.dead):
		pawn.restore_dead()
		return
	if bool(p.collapsed):
		pawn.restore_collapse()  # re-registers its FEED job
		return
	if bool(p.carrying_food):
		pawn.work.carrying_food = true
	# Carrying and a job can coexist: a SUPPLY pawn carries wood toward
	# its blueprint. Restore both independently.
	if String(p.carrying_id) != "":
		var item := main.spawner.spawn_resource(pawn.cell, p.carrying_id)
		pawn.work.restore_carry(item, _vec(p.reserved_dest))
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
			pawn.survival.food_target = food
			pawn.survival.eat_ticks_left = eat_ticks
			return

# --- helpers ---------------------------------------------------------------

func _v(v: Vector2i) -> Array:
	return [v.x, v.y]

func _vec(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))
