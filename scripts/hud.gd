class_name HudController
extends CanvasLayer
## Ambient HUD: mode line, calendar (with speed/threat tags), resource
## counts, and a fading notification feed. Per-villager info lives in
## VillagerPanel now.

const FEED_MAX := 3  # keeps the feed clear of the villager card below it
const FEED_SECONDS := 12.0

const SPRITES := preload("res://assets/sprites.png")
const RES_ICONS := {  # id -> [sprite index, tint, tooltip]
	"wood": [4, Color(0.78, 0.6, 0.35), "Wood — chop trees; builds nearly everything"],
	"stone": [5, Color(0.62, 0.62, 0.66), "Stone — mine gray deposits; forges and towers"],
	"iron_ore": [5, Color(0.72, 0.5, 0.38), "Iron ore — mine brown deposits; smelt at the forge"],
	"iron_ingot": [6, Color(0.76, 0.76, 0.82), "Ingots — smelted ore; swords and bows"],
	"food": [11, Color.WHITE, "Raw food — harvests and forage"],
	"meal": [11, Color(1.15, 1.0, 0.7), "Meals — cooked at a stove; fills and lifts mood"],
	"renown": [12, Color(0.95, 0.8, 0.35), "Renown — beat raids, resolve factions; unlocks buildings, attracts refugees"],
}

var _feed: VBoxContainer
var _raid_arrow: Label
var _res_counts := {}
var _resource_cooldown := 0

@onready var mode_label: Label = $ModeLabel
@onready var resource_label: Label = $ResourceLabel
@onready var inspect_label: Label = $InspectLabel
@onready var calendar_label: Label = $CalendarLabel

func _ready() -> void:
	resource_label.visible = false  # replaced by the icon row
	# Translucent strip across the top so mode line / icons / calendar
	# stop fighting the grass for contrast. Drawn first = behind everything.
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.07, 0.065, 0.09, 0.72)
	backdrop.anchor_right = 1.0
	backdrop.offset_bottom = 52.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop, 0)
	var row := HBoxContainer.new()
	row.offset_left = 8.0
	row.offset_top = 28.0
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	for id: String in RES_ICONS:
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = SPRITES
		atlas.region = Rect2(int(RES_ICONS[id][0]) * 16, 0, 16, 16)
		icon.texture = atlas
		icon.modulate = RES_ICONS[id][1]
		icon.tooltip_text = RES_ICONS[id][2]
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(icon)
		var count := Label.new()
		count.text = "0"
		count.tooltip_text = RES_ICONS[id][2]
		count.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(count)
		_res_counts[id] = count
	_feed = VBoxContainer.new()
	_feed.anchor_left = 1.0
	_feed.anchor_right = 1.0
	_feed.offset_left = -328.0
	_feed.offset_right = -8.0
	_feed.offset_top = 184.0  # below the FIRST STEPS panel
	_feed.add_theme_constant_override("separation", 4)
	add_child(_feed)
	var speed_row := HBoxContainer.new()
	speed_row.anchor_left = 1.0
	speed_row.anchor_right = 1.0
	speed_row.offset_left = -180.0
	speed_row.offset_right = -8.0
	speed_row.offset_top = 30.0
	add_child(speed_row)
	_speed_button(speed_row, "||", "Pause the simulation [Space]",
			func() -> void: GameClock.set_sim_paused(not GameClock.sim_paused))
	_speed_button(speed_row, "1x", "Normal speed [E]",
			func() -> void: GameClock.set_speed(1.0))
	_speed_button(speed_row, "3x", "Fast speed [E]",
			func() -> void: GameClock.set_speed(3.0))
	_raid_arrow = Label.new()
	_raid_arrow.text = "!! RAID !!"
	_raid_arrow.modulate = Color(1.0, 0.3, 0.25)
	_raid_arrow.visible = false
	add_child(_raid_arrow)
	GameClock.ticked.connect(_on_tick)
	GameClock.speed_changed.connect(_update_calendar)
	_update_calendar()

## Push a message into the feed as a translucent chip. Pass a world
## position to make it clickable (jumps the camera there).
func set_event(text: String, tint := Color.WHITE, jump := Vector2.INF) -> void:
	if text == "":
		return
	var chip := PanelContainer.new()
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = tint
	chip.add_child(label)
	if jump.is_finite():
		label.text = "» " + text
		chip.tooltip_text = "Click to look"
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed \
					and event.button_index == MOUSE_BUTTON_LEFT:
				(get_parent().get_node("Camera") as Camera2D).position = jump)
	else:
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE  # don't eat map clicks
	_feed.add_child(chip)
	if _feed.get_child_count() > FEED_MAX:
		_feed.get_child(0).queue_free()
	get_tree().create_timer(FEED_SECONDS).timeout.connect(func() -> void:
		if is_instance_valid(chip):
			chip.queue_free())

func _speed_button(row: HBoxContainer, text: String, tip: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tip
	button.custom_minimum_size = Vector2(40, 26)
	button.pressed.connect(action)
	row.add_child(button)

func set_inspect(text: String) -> void:
	inspect_label.text = text

func show_command_mode() -> void:
	mode_label.modulate = Color.WHITE
	mode_label.text = "COMMAND — LMB select/move/attack  [R draft] [B/Z/F/X tools] [M map] [P priorities] [H help]"

func show_build_mode(def: Dictionary) -> void:
	var costs: Array[String] = []
	for id: String in def.cost:
		costs.append("%d %s" % [int(def.cost[id]), id])
	mode_label.modulate = Color(1.0, 0.75, 0.45)
	mode_label.text = "BUILD: %s (%s) — LMB place, RMB remove/cancel  [Q: next] [B: back]" \
			% [def.name, " + ".join(costs)]

func show_stockpile_mode() -> void:
	mode_label.modulate = Color(1.0, 0.9, 0.5)
	mode_label.text = "STOCKPILE — LMB paint zone, RMB erase  [Z: back]"

func show_field_mode(def: Dictionary) -> void:
	mode_label.modulate = Color(0.65, 0.9, 0.55)
	mode_label.text = "FIELD: %s — LMB zone field, RMB clear  [Q: next crop] [F: back]" % def.name

func show_safety_mode() -> void:
	mode_label.modulate = Color(0.75, 0.65, 0.95)
	mode_label.text = "SAFETY — LMB paint flee zone, RMB erase  [X: back]"

func _on_tick() -> void:
	_update_calendar()
	_resource_cooldown -= 1
	if _resource_cooldown > 0:
		return
	_resource_cooldown = 10
	_update_resources()

func _update_resources() -> void:
	var counts := {"wood": 0, "stone": 0, "iron_ore": 0, "iron_ingot": 0, "food": 0, "meal": 0}
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if counts.has(item.resource_id) and not (item.get_parent() is Pawn):
			counts[item.resource_id] += 1
	for node in get_tree().get_nodes_in_group("food"):
		counts["meal" if (node as FoodItem).meal else "food"] += 1
	counts["renown"] = FactionManager.renown
	for id: String in _res_counts:
		_res_counts[id].text = str(counts[id])

## Red edge-of-screen pointer toward the nearest raider.
func _process(_delta: float) -> void:
	var raiders := get_tree().get_nodes_in_group("raiders")
	_raid_arrow.visible = not raiders.is_empty()
	if raiders.is_empty():
		return
	var camera: Camera2D = get_parent().get_node("Camera")
	var nearest: Node2D = raiders[0]
	for node in raiders:
		if (node as Node2D).position.distance_to(camera.position) \
				< nearest.position.distance_to(camera.position):
			nearest = node
	var view := get_viewport().get_visible_rect().size
	var dir: Vector2 = (nearest.position - camera.position)
	if dir.length() < 8.0:
		dir = Vector2.DOWN
	var edge := view / 2.0 + dir.normalized() * (minf(view.x, view.y) / 2.0 - 48.0)
	_raid_arrow.position = edge - _raid_arrow.size / 2.0

func _update_calendar() -> void:
	var tag := ""
	if GameClock.sim_paused:
		tag = "  || PAUSED"
	elif GameClock.speed != 1.0:
		tag = "  >> x%d" % int(GameClock.speed)
	if not get_tree().get_nodes_in_group("raiders").is_empty():
		tag += "  !! RAID"
	calendar_label.text = GameClock.calendar_text() + tag
