class_name PlayerInput
extends Node
## All player input: mode switching, tool clicks, hotkeys. Main composes
## and owns the world; this node only translates input into calls on it.

enum Mode { COMMAND, BUILD, STOCKPILE, FIELD, SAFETY }

var mode := Mode.COMMAND
var current_building := "wall"
var current_crop := "turnip"

@onready var main: Node2D = get_parent()

func mouse_cell() -> Vector2i:
	return WorldGrid.world_to_cell(main.get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_build_mode"):
		_set_mode(Mode.BUILD if mode != Mode.BUILD else Mode.COMMAND)
	elif event.is_action_pressed("toggle_stockpile_mode"):
		_set_mode(Mode.STOCKPILE if mode != Mode.STOCKPILE else Mode.COMMAND)
	elif event.is_action_pressed("toggle_field_mode"):
		_set_mode(Mode.FIELD if mode != Mode.FIELD else Mode.COMMAND)
	elif event.is_action_pressed("toggle_safety_mode"):
		_set_mode(Mode.SAFETY if mode != Mode.SAFETY else Mode.COMMAND)
	elif event.is_action_pressed("cycle_chop_priority"):
		main.cycle_selected_priority(Job.Type.CHOP)
	elif event.is_action_pressed("cycle_haul_priority"):
		main.cycle_selected_priority(Job.Type.HAUL)
	elif event.is_action_pressed("cycle_build_priority"):
		main.cycle_selected_priority(Job.Type.BUILD)
	elif event.is_action_pressed("cycle_farm_priority"):
		main.cycle_selected_priority(Job.Type.PLANT)
	elif event.is_action_pressed("cycle_building"):
		if mode == Mode.BUILD:
			var order: Array = BuildingDefs.ORDER
			current_building = order[(order.find(current_building) + 1) % order.size()]
			_update_mode_label()
		elif mode == Mode.FIELD:
			var crops: Array = CropDefs.ORDER
			current_crop = crops[(crops.find(current_crop) + 1) % crops.size()]
			_update_mode_label()
	elif event.is_action_pressed("toggle_draft"):
		main.toggle_draft_selected()
	elif event.is_action_pressed("toggle_pause"):
		GameClock.set_sim_paused(not GameClock.sim_paused)
	elif event.is_action_pressed("toggle_speed"):
		GameClock.set_speed(3.0 if GameClock.speed == 1.0 else 1.0)
	elif event.is_action_pressed("debug_spawn_relic"):
		main.spawner.spawn_resource(mouse_cell(), RelicDefs.ORDER.pick_random())
	elif event.is_action_pressed("toggle_world_map"):
		main.world_map.toggle()
	elif event.is_action_pressed("toggle_priority_grid"):
		main.priority_grid.toggle()
	elif event.is_action_pressed("toggle_help"):
		main.help_panel.toggle()
	elif event is InputEventMouseButton and event.pressed:
		_apply_tool(event.button_index)
	elif event is InputEventMouseMotion and mode != Mode.COMMAND:
		# Drag to paint or erase in the zone/build modes.
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_apply_tool(MOUSE_BUTTON_LEFT, true)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_apply_tool(MOUSE_BUTTON_RIGHT, true)

func _apply_tool(button_index: int, dragging := false) -> void:
	var cell := mouse_cell()
	match mode:
		Mode.COMMAND:
			if button_index == MOUSE_BUTTON_LEFT:
				main.handle_command_click(cell)
		Mode.BUILD:
			if button_index == MOUSE_BUTTON_LEFT:
				main.place_blueprint(cell, current_building)
			elif button_index == MOUSE_BUTTON_RIGHT:
				main.remove_at(cell, dragging)
		Mode.STOCKPILE:
			if button_index == MOUSE_BUTTON_LEFT:
				WorldGrid.set_stockpile(cell, true)
			elif button_index == MOUSE_BUTTON_RIGHT:
				WorldGrid.set_stockpile(cell, false)
		Mode.FIELD:
			if button_index == MOUSE_BUTTON_LEFT:
				WorldGrid.set_field(cell, current_crop)
				main.field_keeper.ensure_plant_job(cell)
			elif button_index == MOUSE_BUTTON_RIGHT:
				main.field_keeper.remove_plant_job(cell)
				WorldGrid.remove_field(cell)
		Mode.SAFETY:
			if button_index == MOUSE_BUTTON_LEFT:
				WorldGrid.set_safety(cell, true)
			elif button_index == MOUSE_BUTTON_RIGHT:
				WorldGrid.set_safety(cell, false)

## Toolbar entry point — clicking the active tool returns to COMMAND.
func set_tool(new_mode: Mode) -> void:
	_set_mode(Mode.COMMAND if new_mode == mode else new_mode)

func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_update_mode_label()

## Mode/tool feedback is the toolbar now (persistent labels went away in
## the Cities-style rework) — one sync refreshes highlights + sub-tools.
func _update_mode_label() -> void:
	main.build_palette.sync(self)

## Why placement would fail here (Phase 14: red ghost + reason).
func placement_reason(cell: Vector2i) -> String:
	if not WorldGrid.in_bounds(cell):
		return "Outside the map"
	match mode:
		Mode.BUILD:
			if WorldGrid.buildings.has(cell):
				return "Blocked: a building stands here"
			if main.blueprints.has(cell):
				return "Blocked: already planned"
			if main.pawn_at(cell):
				return "Blocked: someone is standing here"
			var need := int(BuildingDefs.get_def(current_building).get("renown_req", 0))
			if FactionManager.renown < need:
				return "Needs renown %d — beat raids, resolve factions" % need
		Mode.STOCKPILE:
			if WorldGrid.is_wall(cell):
				return "Blocked: wall"
			if WorldGrid.fields.has(cell):
				return "Blocked: field zone"
		Mode.FIELD:
			if WorldGrid.is_wall(cell) or WorldGrid.buildings.has(cell):
				return "Blocked: structure"
			if WorldGrid.stockpile_cells.has(cell):
				return "Blocked: stockpile zone"
		Mode.SAFETY:
			if WorldGrid.is_wall(cell):
				return "Blocked: wall"
	return ""

## Ghost-preview support: is placing at this cell currently valid?
func placement_valid(cell: Vector2i) -> bool:
	if not WorldGrid.in_bounds(cell):
		return false
	match mode:
		Mode.BUILD:
			return not WorldGrid.buildings.has(cell) and not main.blueprints.has(cell) \
					and main.pawn_at(cell) == null
		Mode.STOCKPILE:
			return not WorldGrid.is_wall(cell) and not WorldGrid.fields.has(cell)
		Mode.FIELD:
			return not WorldGrid.is_wall(cell) and not WorldGrid.buildings.has(cell) \
					and not WorldGrid.stockpile_cells.has(cell)
		Mode.SAFETY:
			return not WorldGrid.is_wall(cell)
	return true
