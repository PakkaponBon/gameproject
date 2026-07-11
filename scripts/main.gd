extends Node2D
## The World scene: composes the systems and handles player input.
## Spawning lives in WorldSpawner; saving in the SaveManager autoload.

enum Mode { COMMAND, BUILD, STOCKPILE, FIELD, SAFETY }

const SOURCE_ID := 0
const BLUEPRINT_SCENE := preload("res://scenes/blueprint.tscn")
const DECON_SCENE := preload("res://scenes/deconstruct_order.tscn")

var mode := Mode.COMMAND
var current_building := "wall"
var current_crop := "potato"
var pawns: Array[Pawn] = []
var selected: Pawn = null
var blueprints := {}  # cell -> Blueprint
var decon_orders := {}  # cell -> DeconstructOrder

@onready var walls: TileMapLayer = $Walls
@onready var entities: Node2D = $Entities
@onready var spawner: WorldSpawner = $WorldSpawner
@onready var raid_director: RaidDirector = $RaidDirector
@onready var field_keeper: FieldKeeper = $FieldKeeper
@onready var forge_keeper: ForgeKeeper = $ForgeKeeper
@onready var trade_director: TradeDirector = $TradeDirector
@onready var trade_panel: TradePanel = $TradePanel
@onready var world_map: WorldMap = $WorldMap
@onready var story_panel: StoryPanel = $StoryPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var hud: HudController = $HUD

func _ready() -> void:
	raid_director.spawn_parent = entities
	field_keeper.spawn_parent = entities
	forge_keeper.spawn_parent = entities
	trade_director.spawn_parent = entities
	EventBus.merchant_arrived.connect(func() -> void: hud.set_event("A traveling merchant has arrived"))
	EventBus.merchant_left.connect(func() -> void: hud.set_event(""))
	raid_director.raid_started.connect(func(fname: String) -> void: hud.set_event("RAID — %s attacks!" % fname))
	raid_director.raid_ended.connect(func() -> void: hud.set_event(""))
	pause_menu.save_requested.connect(func() -> void: SaveManager.save_game(SaveManager.MANUAL_SAVE_PATH))
	pause_menu.load_requested.connect(func(path: String) -> void: SaveManager.load_game(path))
	spawner.pawn_created.connect(_on_pawn_created)
	EventBus.building_built.connect(_on_building_built)
	EventBus.building_deconstructed.connect(_on_building_deconstructed)
	EventBus.building_destroyed.connect(_on_building_destroyed)
	SaveManager.main = self
	FactionManager.main = self
	FactionManager.announced.connect(hud.set_event)
	FactionManager.realm_ruled.connect(_on_realm_ruled)
	if SaveManager.pending_load.is_empty():
		FactionManager.reset()
		spawner.new_game()
		story_panel.show_story("THE CITY FELL",
				"Smoke behind you, ash on the wind. Three of you made it out —\n"
				+ "a wagon, tools, seed, and the road.\n\n"
				+ "The meadow ahead is quiet. Build. Endure.\n"
				+ "And one day, answer those who lit the fire.")
	else:
		SaveManager.apply_pending_load()
	if selected == null:
		_select_first_alive()
	if not get_tree().get_nodes_in_group("raiders").is_empty():
		hud.set_event("RAID — a raider approaches!")
	_update_mode_label()

## Instantly realize a finished (or loaded) building at a cell.
func place_building(cell: Vector2i, id: String) -> void:
	WorldGrid.register_building(cell, id)
	walls.set_cell(cell, SOURCE_ID, BuildingDefs.get_def(id).tile)

func place_blueprint(cell: Vector2i, id: String) -> void:
	if not WorldGrid.in_bounds(cell) or WorldGrid.buildings.has(cell) \
			or blueprints.has(cell) or _pawn_at(cell):
		return
	var bp: Blueprint = BLUEPRINT_SCENE.instantiate()
	bp.building_id = id
	bp.position = WorldGrid.cell_to_world(cell)
	entities.add_child(bp)
	blueprints[cell] = bp

## Save/load: restore the selection by index into the pawns array.
func select_pawn(index: int) -> void:
	if index >= 0 and index < pawns.size():
		_select(pawns[index])

func _on_pawn_created(pawn: Pawn) -> void:
	pawn.stats_changed.connect(_on_pawn_stats_changed.bind(pawn))
	pawn.died.connect(_on_pawn_died.bind(pawn))
	pawns.append(pawn)

func _on_building_built(cell: Vector2i, building_id: String) -> void:
	blueprints.erase(cell)
	place_building(cell, building_id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		_set_mode(Mode.BUILD if mode != Mode.BUILD else Mode.COMMAND)
	elif event.is_action_pressed("toggle_stockpile_mode"):
		_set_mode(Mode.STOCKPILE if mode != Mode.STOCKPILE else Mode.COMMAND)
	elif event.is_action_pressed("toggle_field_mode"):
		_set_mode(Mode.FIELD if mode != Mode.FIELD else Mode.COMMAND)
	elif event.is_action_pressed("toggle_safety_mode"):
		_set_mode(Mode.SAFETY if mode != Mode.SAFETY else Mode.COMMAND)
	elif event.is_action_pressed("toggle_draft"):
		if selected and not selected.dead:
			selected.set_drafted(not selected.drafted)
			hud.update_stats(selected)
	elif event.is_action_pressed("toggle_pause"):
		GameClock.set_sim_paused(not GameClock.sim_paused)
	elif event.is_action_pressed("toggle_speed"):
		GameClock.set_speed(3.0 if GameClock.speed == 1.0 else 1.0)
	elif event.is_action_pressed("debug_spawn_relic"):
		spawner.spawn_resource(_mouse_cell(), RelicDefs.ORDER.pick_random())
	elif event.is_action_pressed("toggle_world_map"):
		world_map.toggle()
	elif event.is_action_pressed("cycle_farm_priority"):
		_cycle_selected_priority(Job.Type.PLANT)
	elif event.is_action_pressed("cycle_chop_priority"):
		_cycle_selected_priority(Job.Type.CHOP)
	elif event.is_action_pressed("cycle_haul_priority"):
		_cycle_selected_priority(Job.Type.HAUL)
	elif event.is_action_pressed("cycle_build_priority"):
		_cycle_selected_priority(Job.Type.BUILD)
	elif event.is_action_pressed("cycle_building"):
		if mode == Mode.BUILD:
			var order: Array = BuildingDefs.ORDER
			current_building = order[(order.find(current_building) + 1) % order.size()]
			_update_mode_label()
		elif mode == Mode.FIELD:
			var crops: Array = CropDefs.ORDER
			current_crop = crops[(crops.find(current_crop) + 1) % crops.size()]
			_update_mode_label()
	elif event is InputEventMouseButton and event.pressed:
		_apply_tool(event.button_index)
	elif event is InputEventMouseMotion and mode != Mode.COMMAND:
		# Drag to paint or erase in build/stockpile modes.
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_apply_tool(MOUSE_BUTTON_LEFT, true)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_apply_tool(MOUSE_BUTTON_RIGHT, true)

func _apply_tool(button_index: int, dragging := false) -> void:
	var cell := _mouse_cell()
	match mode:
		Mode.COMMAND:
			if button_index == MOUSE_BUTTON_LEFT:
				var clicked := _pawn_at(cell)
				var raider := _raider_at(cell)
				var merchant := _merchant_at(cell)
				if clicked:
					_select(clicked)
				elif merchant:
					trade_panel.open(merchant)
				elif raider and selected and selected.drafted:
					selected.attack(raider)
				elif selected:
					selected.move_to(cell)
		Mode.BUILD:
			if button_index == MOUSE_BUTTON_LEFT:
				place_blueprint(cell, current_building)
			elif button_index == MOUSE_BUTTON_RIGHT:
				_remove_at(cell, dragging)
		Mode.STOCKPILE:
			if button_index == MOUSE_BUTTON_LEFT:
				WorldGrid.set_stockpile(cell, true)
			elif button_index == MOUSE_BUTTON_RIGHT:
				WorldGrid.set_stockpile(cell, false)
		Mode.FIELD:
			if button_index == MOUSE_BUTTON_LEFT:
				WorldGrid.set_field(cell, current_crop)
				field_keeper.ensure_plant_job(cell)
			elif button_index == MOUSE_BUTTON_RIGHT:
				field_keeper.remove_plant_job(cell)
				WorldGrid.remove_field(cell)
		Mode.SAFETY:
			if button_index == MOUSE_BUTTON_LEFT:
				WorldGrid.set_safety(cell, true)
			elif button_index == MOUSE_BUTTON_RIGHT:
				WorldGrid.set_safety(cell, false)

func _mouse_cell() -> Vector2i:
	return WorldGrid.world_to_cell(get_global_mouse_position())

func _pawn_at(cell: Vector2i) -> Pawn:
	for pawn in pawns:
		if pawn.cell == cell:
			return pawn
	return null

func _raider_at(cell: Vector2i) -> Raider:
	for node in get_tree().get_nodes_in_group("raiders"):
		var raider := node as Raider
		if raider.cell == cell:
			return raider
	return null

func _merchant_at(cell: Vector2i) -> Merchant:
	for node in get_tree().get_nodes_in_group("merchants"):
		var merchant := node as Merchant
		if merchant.cell == cell:
			return merchant
	return null

func _select_first_alive() -> void:
	for pawn in pawns:
		if not pawn.dead:
			_select(pawn)
			return
	if not pawns.is_empty():
		_select(pawns[0])

func _select(pawn: Pawn) -> void:
	if selected:
		selected.set_selected(false)
	selected = pawn
	selected.set_selected(true)
	hud.update_stats(selected)
	hud.update_priorities(selected)

func _cycle_selected_priority(type: Job.Type) -> void:
	if selected == null or selected.dead:
		return
	selected.cycle_priority(type)
	hud.update_priorities(selected)

## RMB: cancel a blueprint, toggle a deconstruct order, or mark a building.
## While dragging, never un-mark — otherwise motion events would flicker it.
func _remove_at(cell: Vector2i, dragging := false) -> void:
	if blueprints.has(cell):
		blueprints[cell].cancel()
		blueprints.erase(cell)
	elif decon_orders.has(cell):
		if not dragging:
			decon_orders[cell].cancel()
			decon_orders.erase(cell)
	elif WorldGrid.buildings.has(cell):
		mark_deconstruct(cell)

func mark_deconstruct(cell: Vector2i) -> void:
	var order: DeconstructOrder = DECON_SCENE.instantiate()
	order.position = WorldGrid.cell_to_world(cell)
	entities.add_child(order)
	decon_orders[cell] = order

## Expedition glue: villagers leave the map as data and come home changed.
func remove_pawn_for_expedition(pawn: Pawn) -> void:
	pawn.prepare_depart()
	pawns.erase(pawn)
	if selected == pawn:
		selected = null
		if pawns.is_empty():
			hud.clear_selection()
		else:
			_select_first_alive()
	pawn.queue_free()

func return_expedition_member(pdata: Dictionary) -> void:
	var cell := _free_cell_near(WorldGrid.MAP_SIZE / 2)
	var pawn := spawner.create_pawn(cell, pdata.name,
			{Job.Type.CHOP: 1, Job.Type.HAUL: 1, Job.Type.BUILD: 1, Job.Type.PLANT: 1})
	pawn.traits = pdata.traits
	for skill_id: String in pdata.skills:
		pawn.skills.xp[skill_id] = float(pdata.skills[skill_id])
	if String(pdata.weapon) != "":
		pawn.combat.equip(pdata.weapon)
	pawn.combat.ammo = int(pdata.ammo)
	pawn.combat.relic_id = String(pdata.relic)
	pawn.combat.hp = maxf(float(pdata.hp) * 0.8, 30.0)  # battle-worn
	if selected == null:
		_select(pawn)

func mourn_expedition_loss() -> void:
	spawner.spawn_entity(spawner.GRAVE_SCENE, _free_cell_near(WorldGrid.MAP_SIZE / 2))
	for pawn in pawns:
		pawn.needs.mourn()

func _free_cell_near(center: Vector2i) -> Vector2i:
	for radius in 6:
		var cell := center + Vector2i(randi_range(-radius, radius), randi_range(-radius, radius))
		if WorldGrid.in_bounds(cell) and not WorldGrid.is_wall(cell):
			return cell
	return center

func _on_realm_ruled() -> void:
	story_panel.show_story("RULER OF THE REALM",
			"Every banner in the realm bows or burns.\n\n"
			+ "From three survivors and a wagon to this: the roads are yours,\n"
			+ "the tributes flow, and the ones who lit the fire are answered.\n\n"
			+ "The hearth you built still burns. Warmer now, for all of it.")

## Smashed by enemies: gone, no refund.
func _on_building_destroyed(cell: Vector2i) -> void:
	if decon_orders.has(cell):
		decon_orders[cell].cancel()
		decon_orders.erase(cell)
	WorldGrid.remove_building(cell)
	walls.erase_cell(cell)

func _on_building_deconstructed(cell: Vector2i) -> void:
	decon_orders.erase(cell)
	var refund: Dictionary = BuildingDefs.get_def(WorldGrid.buildings[cell]).refund
	WorldGrid.remove_building(cell)
	walls.erase_cell(cell)
	for id: String in refund:
		spawner.drop_resource(cell, id, int(refund[id]))

func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_update_mode_label()

func _on_pawn_stats_changed(pawn: Pawn) -> void:
	if pawn == selected:
		hud.update_stats(selected)

func _on_pawn_died(pawn: Pawn) -> void:
	spawner.spawn_entity(spawner.GRAVE_SCENE, pawn.cell)
	if pawn.combat.weapon_id != "":
		spawner.drop_resource(pawn.cell, pawn.combat.weapon_id, 1)  # gear outlives its owner
	pawns.erase(pawn)
	for other in pawns:
		other.needs.mourn()  # loss is real: colony-wide mood hit
	if pawns.is_empty():
		selected = null
		hud.clear_selection()
		hud.set_event("ALL COLONISTS ARE DEAD")
	elif selected == pawn:
		_select_first_alive()

func _update_mode_label() -> void:
	match mode:
		Mode.COMMAND:
			hud.show_command_mode()
		Mode.BUILD:
			hud.show_build_mode(BuildingDefs.get_def(current_building))
		Mode.STOCKPILE:
			hud.show_stockpile_mode()
		Mode.FIELD:
			hud.show_field_mode(CropDefs.get_def(current_crop))
		Mode.SAFETY:
			hud.show_safety_mode()
