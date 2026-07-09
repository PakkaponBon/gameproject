extends Node2D
## The World scene: composes the systems and handles player input.
## Spawning lives in WorldSpawner; saving in the SaveManager autoload.

enum Mode { COMMAND, BUILD, STOCKPILE }

const SOURCE_ID := 0
const BLUEPRINT_SCENE := preload("res://scenes/blueprint.tscn")
const DECON_SCENE := preload("res://scenes/deconstruct_order.tscn")

var mode := Mode.COMMAND
var current_building := "wall"
var pawns: Array[Pawn] = []
var selected: Pawn = null
var blueprints := {}  # cell -> Blueprint
var decon_orders := {}  # cell -> DeconstructOrder

@onready var walls: TileMapLayer = $Walls
@onready var entities: Node2D = $Entities
@onready var spawner: WorldSpawner = $WorldSpawner
@onready var raid_director: RaidDirector = $RaidDirector
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var mode_label: Label = $HUD/ModeLabel
@onready var stats_label: Label = $HUD/StatsLabel
@onready var priority_label: Label = $HUD/PriorityLabel
@onready var event_label: Label = $HUD/EventLabel

func _ready() -> void:
	raid_director.spawn_parent = entities
	raid_director.raid_started.connect(func() -> void: event_label.text = "RAID — a raider approaches!")
	raid_director.raid_ended.connect(func() -> void: event_label.text = "")
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
		event_label.text = "RAID — a raider approaches!"
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
	_update_stats_label()
	_update_priority_label()

func _cycle_selected_priority(type: Job.Type) -> void:
	if selected == null or selected.dead:
		return
	selected.cycle_priority(type)
	_update_priority_label()

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
		_update_stats_label()

func _on_pawn_died() -> void:
	if pawns.all(func(p: Pawn) -> bool: return p.dead):
		event_label.text = "ALL COLONISTS ARE DEAD"

func _update_stats_label() -> void:
	if selected.dead:
		stats_label.text = "%s — DEAD" % selected.name
		return
	var suffix := "  (MENTAL BREAK)" if selected.needs.on_break else ""
	stats_label.text = "%s — hunger %d  mood %d  hp %d%s" % [
		selected.name, roundi(selected.needs.hunger),
		roundi(selected.needs.mood), roundi(selected.combat.hp), suffix]

func _update_priority_label() -> void:
	if selected == null:
		priority_label.text = ""
		return
	priority_label.text = "%s — Chop: %s  Haul: %s  Build: %s   [1/2/3: cycle priority, 0 = off]" % [
		selected.name,
		_priority_text(selected.work_priorities[Job.Type.CHOP]),
		_priority_text(selected.work_priorities[Job.Type.HAUL]),
		_priority_text(selected.work_priorities[Job.Type.BUILD]),
	]

func _priority_text(value: int) -> String:
	return "off" if value == 0 else str(value)

func _update_mode_label() -> void:
	match mode:
		Mode.COMMAND:
			mode_label.text = "COMMAND — LMB select pawn / move selected  [B: build] [Z: stockpile] [Esc: menu]"
		Mode.BUILD:
			var def: Dictionary = BuildingDefs.get_def(current_building)
			mode_label.text = "BUILD: %s (%d wood) — LMB place, RMB remove/cancel  [Q: next building] [B: back]" \
					% [def.name, int(def.cost.get("wood", 0))]
		Mode.STOCKPILE:
			mode_label.text = "STOCKPILE — LMB paint zone, RMB erase  [Z: back]"
