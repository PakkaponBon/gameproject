class_name BuildPalette
extends CanvasLayer
## Mouse-first tool selection: icon buttons for buildings (BUILD mode)
## and crops (FIELD mode), with costs in tooltips. Phase 14: play a full
## day with only the mouse.

const TILES := preload("res://assets/tiles.png")
const SPRITES := preload("res://assets/sprites.png")

var _row: HBoxContainer
var _input: PlayerInput = null

func _ready() -> void:
	visible = false
	_row = HBoxContainer.new()
	_row.anchor_left = 0.5
	_row.anchor_right = 0.5
	_row.anchor_top = 1.0
	_row.anchor_bottom = 1.0
	_row.offset_top = -76.0
	_row.offset_bottom = -48.0
	_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_row.add_theme_constant_override("separation", 6)
	add_child(_row)

func show_for(mode: int, input_ctrl: PlayerInput) -> void:
	_input = input_ctrl
	for child in _row.get_children():
		child.queue_free()
	visible = mode == PlayerInput.Mode.BUILD or mode == PlayerInput.Mode.FIELD
	if not visible:
		return
	if mode == PlayerInput.Mode.BUILD:
		for id: String in BuildingDefs.ORDER:
			var def := BuildingDefs.get_def(id)
			var costs: Array[String] = []
			for res: String in def.cost:
				costs.append("%d %s" % [int(def.cost[res]), res])
			var tip: String = "%s — %s" % [def.name, " + ".join(costs)]
			if int(def.get("renown_req", 0)) > 0:
				tip += "  (renown %d)" % int(def.get("renown_req", 0))
			_add_button(TILES, Rect2(def.tile.x * 16, 0, 16, 16), Color.WHITE, tip,
					func() -> void:
						_input.current_building = id
						_input._update_mode_label())
	else:
		for id: String in CropDefs.ORDER:
			var def := CropDefs.get_def(id)
			_add_button(SPRITES, Rect2(288, 0, 16, 16), def.color,
					"%s — grows %.1f days, yields %d" % [def.name, float(def.grow_days), int(def.yield)],
					func() -> void:
						_input.current_crop = id
						_input._update_mode_label())

func _add_button(sheet: Texture2D, region: Rect2, tint: Color, tip: String, action: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(34, 30)
	button.tooltip_text = tip
	button.pressed.connect(action)
	var icon := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	icon.texture = atlas
	icon.modulate = tint
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	_row.add_child(button)
