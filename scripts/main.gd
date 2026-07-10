extends Node2D
## The World scene: composes the systems and handles player input.
## Spawning lives in WorldSpawner; saving in the SaveManager autoload.

enum Mode { COMMAND, BUILD, STOCKPILE, FIELD }

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
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var hud: HudController = $HUD

func _ready() -> void:
	raid_director.spawn_parent = entities
	field_keeper.spawn_parent = entities
	raid_director.raid_started.connect(func() -> void: hud.set_event("RAID — a raider approaches!"))
	raid_director.raid_ended.connect(func() -> void: hud.set_event(""))
	pause_menu.save_requested.connect(func() -> void: SaveManager.save_game(SaveManager.MANUAL_SAVE_PATH))
	pause_menu.load_requested.connect(func(path: String) -> void: SaveManager.load_game(path))
	spawner.pawn_created.connect(_on_pawn_created)
	EventBus.building_built.connect(_on_building_built)
	EventBus.building_deconstructed.connect(_on_building_deconstructed)
	SaveManager.main = self
	if SaveManager.pending_load.is_empty():
		spawner.new_game()
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
	pawn.died.connect(_on_pawn_died)
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
				if clicked:
					_select(clicked)
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

func _mouse_cell() -> Vector2i:
	return WorldGrid.world_to_cell(get_global_mouse_position())

func _pawn_at(cell: Vector2i) -> Pawn:
	for pawn in pawns:
		if pawn.cell == cell:
			return pawn
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

func _on_building_deconstructed(cell: Vector2i) -> void:
	decon_orders.erase(cell)
	var refund := int(BuildingDefs.get_def(WorldGrid.buildings[cell]).refund)
	WorldGrid.remove_building(cell)
	walls.erase_cell(cell)
	spawner.drop_wood(cell, refund)

func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_update_mode_label()

func _on_pawn_stats_changed(pawn: Pawn) -> void:
	if pawn == selected:
		hud.update_stats(selected)

func _on_pawn_died() -> void:
	if pawns.all(func(p: Pawn) -> bool: return p.dead):
		hud.set_event("ALL COLONISTS ARE DEAD")

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
