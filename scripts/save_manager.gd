extends Node
## Autoload: versioned JSON save/load. Collection lives in SaveCollector;
## this side owns file IO, autosave, and rebuilding the world on load.
## Loading reloads the main scene; `pending_load` survives the reload
## because this is an autoload, and the fresh Main applies it.

const SAVE_VERSION := 25
## Keys a save must carry; anything less is corrupt, and corrupt saves
## get an error message — never a crash to desktop.
const REQUIRED_KEYS := ["clock_ticks", "ground_seed", "buildings", "pawns", "realm", "items", "fields"]
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
	file.store_string(JSON.stringify(SaveCollector.collect(main, SAVE_VERSION)))

func load_game(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("No save file at %s" % path)
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data == null or not (data is Dictionary) or int(data.get("version", -1)) != SAVE_VERSION:
		push_error("Save file is corrupt or has an incompatible version")
		return false
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			push_error("Save file is damaged (missing '%s') — refusing to load" % key)
			return false
	pending_load = data
	get_tree().paused = false
	# Works both in-game and from the main menu.
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	return true

## Called by Main._ready in the freshly reloaded scene.
func apply_pending_load() -> void:
	var data := pending_load
	pending_load = {}
	WorldGrid.reset()
	JobManager.reset()
	GameClock.ticks = int(data.clock_ticks)
	main.raid_director.ticks_until_raid = int(data.raid_ticks)
	main.raid_director.raid_count = int(data.raid_count)
	FactionManager.deserialize(data.realm)
	var spawner: WorldSpawner = main.spawner
	spawner.ground_seed = int(data.ground_seed)
	spawner.generate_ground()
	for b: Dictionary in data.buildings:
		main.place_building(_vec(b.cell), b.id)
	for d: Dictionary in data.building_hp:
		WorldGrid.building_hp[_vec(d.cell)] = float(d.hp)  # keep battle damage
	for t: Dictionary in data.get("trap_uses", []):
		WorldGrid.traps[_vec(t.cell)] = int(t.uses)  # keep spent spikes spent
	for s: Array in data.stockpiles:
		WorldGrid.set_stockpile(_vec(s), true)
	for s: Array in data.safety:
		WorldGrid.set_safety(_vec(s), true)
	for t: Dictionary in data.trees:
		var tree: TreeEntity = spawner.spawn_entity(spawner.TREE_SCENE, _vec(t.cell))
		tree.job.work_ticks = int(t.work)
	for i: Dictionary in data.items:
		spawner.spawn_resource(_vec(i.cell), i.id)
	for o: Dictionary in data.ore_nodes:
		var ore: OreNode = spawner.spawn_ore(_vec(o.cell), o.id)
		ore.restore(int(o.work))
	for f: Dictionary in data.food:
		var food: FoodItem = spawner.FOOD_SCENE.instantiate()
		# Back-compat: pre-v23 saves stored a "meal" bool instead of "kind".
		food.kind = String(f.get("kind", "meal" if bool(f.get("meal", false)) else "raw"))
		food.position = WorldGrid.cell_to_world(_vec(f.cell))
		main.entities.add_child(food)
	for g: Array in data.graves:
		spawner.spawn_entity(spawner.GRAVE_SCENE, _vec(g))
	for b: Dictionary in data.get("bushes", []):
		var bush: BerryBush = spawner.spawn_bush(_vec(b.cell), false)
		bush.regrow_ticks = int(b.regrow)
	for a: Dictionary in data.get("livestock", []):
		spawner.spawn_livestock(_vec(a.cell), String(a.kind), int(a.lay))
	for r: Dictionary in data.raiders:
		var raider: Raider = spawner.spawn_raider(_vec(r.cell), bool(r.boss))
		raider.faction_id = String(r.faction)
		# Kind flags before hp: make_wolf/make_elite reset stats, then the
		# saved hp below restores battle damage on top.
		if bool(r.get("beast", false)):
			raider.make_wolf()
		if bool(r.get("elite", false)):
			raider.make_elite()
		raider.hp = float(r.hp)
		raider.attack_cooldown = int(r.atk_cd)
		raider.move_cooldown = int(r.move_cd)
		if bool(r.get("looter", false)):
			raider.make_looter()
		raider.carrying_loot = bool(r.get("loot", false))
	for b: Dictionary in data.blueprints:
		main.place_blueprint(_vec(b.cell), b.id)
		var bp: Blueprint = main.blueprints[_vec(b.cell)]
		bp.restore(b.delivered, int(b.work))
	for c: Dictionary in data.craft_orders:
		var order: CraftOrder = main.forge_keeper.start_order(_vec(c.cell), c.recipe)
		order.restore(c.delivered, int(c.work))
	for d: Dictionary in data.decon_orders:
		main.mark_deconstruct(_vec(d.cell))
		main.decon_orders[_vec(d.cell)].restore(int(d.work))
	for f: Dictionary in data.fields:
		WorldGrid.set_field(_vec(f.cell), f.crop)
	for c: Dictionary in data.crops:
		var crop: Crop = main.field_keeper.spawn_crop(_vec(c.cell), c.id)
		crop.restore(int(c.growth))
	main.field_keeper.sync_all()  # plant jobs for empty, non-winter field cells
	main.weather_director.set_weather(String(data.get("weather", "clear")))
	main.chronicle_director.entries = data.get("chronicle", [])
	# Saves that predate the tutorial default to finished — no nagging.
	main.tutorial.restore(int(data.get("tutorial_step", 0)), bool(data.get("tutorial_done", true)))
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
	pawn.needs.warmth = float(p.get("warmth", 100.0))
	pawn.needs.joy = float(p.get("joy", 70.0))
	for other_name: String in p.get("bonds", {}):
		pawn.social.bonds[other_name] = float(p.bonds[other_name])
	pawn.needs.on_break = bool(p.on_break)
	pawn.survival.bed_cell = _vec(p.bed)
	if bool(p.sleeping):
		pawn.survival.restore_sleep()
	pawn.combat.hp = float(p.hp)
	pawn.combat.attack_cooldown = int(p.atk_cd)
	if String(p.weapon) != "":
		pawn.combat.equip(p.weapon)
	if String(p.get("armor", "")) != "":
		pawn.combat.equip_armor(String(p.armor))
	pawn.combat.ammo = int(p.ammo)
	pawn.combat.relic_id = String(p.relic)
	pawn.combat.relic_cooldown = int(p.relic_cd)
	for skill_id: String in p.skills:
		pawn.skills.xp[skill_id] = float(p.skills[skill_id])
	pawn.traits = p.traits
	pawn.survival.wander_cooldown = int(p.wander_cd)
	pawn.target_cell = _vec(p.target)
	if bool(p.collapsed):
		pawn.restore_collapse()  # re-registers its FEED job
		return
	if bool(p.drafted):
		pawn.set_drafted(true)
		pawn.target_cell = _vec(p.target)  # set_drafted resets it
		var attack_cell: Array = p.attack_cell
		if not attack_cell.is_empty():
			pawn.combat.attack_target = _raider_at(_vec(attack_cell))
		return  # drafted pawns hold no jobs
	if bool(p.carrying_food):
		pawn.work.carrying_food = true
	if bool(p.carrying_herb):
		pawn.work.carrying_herb = true
	# Carrying and a job can coexist: a SUPPLY pawn carries wood toward
	# its blueprint. Restore both independently.
	if String(p.carrying_id) != "":
		var item: ResourceItem = main.spawner.spawn_resource(pawn.cell, p.carrying_id)
		pawn.work.restore_carry(item, _vec(p.reserved_dest))
	if int(p.job_type) >= 0:
		# Entities re-registered their jobs above; re-claim ours by
		# cell + type (+ material for supply runs).
		var job_cell := _vec(p.job_cell)
		for job in JobManager.jobs:
			if job.cell == job_cell and int(job.type) == int(p.job_type) \
					and job.resource_id == String(p.job_res) and not job.reserved:
				job.reserved = true
				pawn.work.job = job
				break
	var food_cell: Array = p.food_cell
	if not food_cell.is_empty():
		_relink_food(pawn, _vec(food_cell), int(p.eat_ticks))

func _raider_at(cell: Vector2i) -> Raider:
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		if raider.cell == cell:
			return raider
	return null

func _relink_food(pawn: Pawn, food_cell: Vector2i, eat_ticks: int) -> void:
	for node in get_tree().get_nodes_in_group("food"):
		var food := node as FoodItem
		if food.cell == food_cell and not food.reserved:
			food.reserved = true
			pawn.survival.food_target = food
			pawn.survival.eat_ticks_left = eat_ticks
			return

func _vec(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))
