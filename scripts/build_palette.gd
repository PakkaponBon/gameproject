class_name BuildPalette
extends CanvasLayer
## Cities-style toolbar: an icon-only category row (always visible) that
## expands a sub-tool row above it — buildings for BUILD, crops for FIELD.
## All wording lives in tooltips; active category and tool stay lit.

const TILES := preload("res://assets/tiles.png")
const SPRITES := preload("res://assets/sprites.png")

var _sub_panel: PanelContainer
var _sub_row: HBoxContainer
var _category_buttons := {}  # PlayerInput.Mode -> Button
var _input: PlayerInput = null

func _ready() -> void:
	_build_categories()
	_sub_panel = PanelContainer.new()
	_sub_panel.theme_type_variation = "SlimPanel"
	_sub_panel.anchor_left = 0.5
	_sub_panel.anchor_right = 0.5
	_sub_panel.anchor_top = 1.0
	_sub_panel.anchor_bottom = 1.0
	_sub_panel.offset_top = -88.0
	_sub_panel.offset_bottom = -50.0
	_sub_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_sub_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_sub_panel.visible = false
	add_child(_sub_panel)
	_sub_row = HBoxContainer.new()
	_sub_row.add_theme_constant_override("separation", 4)
	_sub_panel.add_child(_sub_row)

func _build_categories() -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "SlimPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -46.0
	panel.offset_bottom = -8.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	var cats := [
		[PlayerInput.Mode.COMMAND, SPRITES, Rect2(0, 0, 16, 16),
				"Command — click a villager to select · click ground to move, enemy to attack"],
		[PlayerInput.Mode.BUILD, TILES, Rect2(32, 0, 16, 16),
				"Build [B] — LMB place · RMB remove"],
		[PlayerInput.Mode.STOCKPILE, TILES, Rect2(80, 0, 16, 16),
				"Stockpile zone [Z] — LMB paint · RMB erase"],
		[PlayerInput.Mode.FIELD, SPRITES, Rect2(288, 0, 16, 16),
				"Crop fields [F] — LMB zone · RMB clear"],
		[PlayerInput.Mode.SAFETY, TILES, Rect2(112, 0, 16, 16),
				"Safety zone [X] — villagers flee here during raids · LMB paint · RMB erase"],
	]
	for cat: Array in cats:
		var mode_id: int = cat[0]
		var btn := UiTheme.icon_button(cat[1], cat[2], Color.WHITE, cat[3])
		btn.toggle_mode = true
		btn.pressed.connect(func() -> void: _input.set_tool(mode_id))
		row.add_child(btn)
		_category_buttons[mode_id] = btn
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(8, 0)
	row.add_child(gap)
	var map_btn := UiTheme.icon_button(SPRITES, Rect2(192, 0, 16, 16), Color.WHITE,
			"World map — factions and expeditions  [M]")
	map_btn.pressed.connect(func() -> void: get_parent().world_map.toggle())
	row.add_child(map_btn)
	var chron_btn := UiTheme.icon_button(SPRITES, Rect2(208, 0, 16, 16), Color(0.85, 0.85, 0.95),
			"The Chronicle — the village's story so far  [C]")
	chron_btn.pressed.connect(func() -> void: get_parent().chronicle_panel.toggle())
	row.add_child(chron_btn)
	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.tooltip_text = "Help  [H]"
	help_btn.custom_minimum_size = Vector2(30, 32)
	help_btn.pressed.connect(func() -> void: get_parent().help_panel.toggle())
	row.add_child(help_btn)

## Refresh everything from input state: active category highlight and the
## sub-tool row. Called by PlayerInput whenever mode or tool changes.
func sync(input_ctrl: PlayerInput) -> void:
	_input = input_ctrl
	for id: int in _category_buttons:
		(_category_buttons[id] as Button).set_pressed_no_signal(id == _input.mode)
	for child in _sub_row.get_children():
		child.queue_free()
	_sub_panel.visible = _input.mode == PlayerInput.Mode.BUILD \
			or _input.mode == PlayerInput.Mode.FIELD
	if not _sub_panel.visible:
		return
	if _input.mode == PlayerInput.Mode.BUILD:
		for id: String in BuildingDefs.ORDER:
			var def := BuildingDefs.get_def(id)
			var costs: Array[String] = []
			for res: String in def.cost:
				costs.append("%d %s" % [int(def.cost[res]), res])
			var tip: String = "%s — %s" % [def.name, " + ".join(costs)]
			if int(def.get("renown_req", 0)) > 0:
				tip += "  (renown %d)" % int(def.get("renown_req", 0))
			_add_tool(TILES, Rect2(def.tile.x * 16, 0, 16, 16), Color.WHITE, tip,
					id == _input.current_building,
					func() -> void:
						_input.current_building = id
						_input._update_mode_label())
	else:
		for id: String in CropDefs.ORDER:
			var def := CropDefs.get_def(id)
			_add_tool(SPRITES, Rect2(288, 0, 16, 16), def.color,
					"%s — grows %.1f days, yields %d" % [def.name, float(def.grow_days), int(def.yield)],
					id == _input.current_crop,
					func() -> void:
						_input.current_crop = id
						_input._update_mode_label())

func _add_tool(sheet: Texture2D, region: Rect2, tint: Color, tip: String,
		selected: bool, action: Callable) -> void:
	var btn := UiTheme.icon_button(sheet, region, tint, tip, Vector2(34, 30))
	btn.toggle_mode = true
	btn.set_pressed_no_signal(selected)
	btn.pressed.connect(action)
	_sub_row.add_child(btn)
