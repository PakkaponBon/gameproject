class_name HudController
extends CanvasLayer
## Ambient HUD, Cities-style: slim corner clusters only. Resources top-left,
## clock + speed top-right, notification chips under that. Tool selection
## lives in BuildPalette (bottom toolbar); per-villager info in VillagerPanel.

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
var _calendar: Label

@onready var mode_label: Label = $ModeLabel
@onready var resource_label: Label = $ResourceLabel
@onready var inspect_label: Label = $InspectLabel
@onready var calendar_label: Label = $CalendarLabel

func _ready() -> void:
	# Corner clusters replaced the old full-width strip and text labels;
	# the scene's legacy labels stay as hidden nodes.
	mode_label.visible = false
	resource_label.visible = false
	calendar_label.visible = false
	_build_resource_strip()
	_build_clock_cluster()
	_feed = VBoxContainer.new()
	_feed.anchor_left = 1.0
	_feed.anchor_right = 1.0
	_feed.offset_left = -328.0
	_feed.offset_right = -8.0
	_feed.offset_top = 205.0  # below the clock cluster + objectives badge
	_feed.add_theme_constant_override("separation", 4)
	add_child(_feed)
	_raid_arrow = Label.new()
	_raid_arrow.text = "!! RAID !!"
	_raid_arrow.modulate = Color(1.0, 0.3, 0.25)
	_raid_arrow.visible = false
	add_child(_raid_arrow)
	GameClock.ticked.connect(_on_tick)
	GameClock.speed_changed.connect(_update_calendar)
	_update_calendar()

## Slim icon+count strip, top-left. Meaning lives in the tooltips.
func _build_resource_strip() -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "SlimPanel"
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for id: String in RES_ICONS:
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = SPRITES
		atlas.region = Rect2(int(RES_ICONS[id][0]) * 16, 0, 16, 16)
		icon.texture = atlas
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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

## One top-right cluster: calendar text + pause/1x/3x.
func _build_clock_cluster() -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "SlimPanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_right = -8.0
	panel.offset_top = 8.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	_calendar = Label.new()
	row.add_child(_calendar)
	_speed_button(row, "||", "Pause the simulation [Space]",
			func() -> void: GameClock.set_sim_paused(not GameClock.sim_paused))
	_speed_button(row, "1x", "Normal speed [E]",
			func() -> void: GameClock.set_speed(1.0))
	_speed_button(row, "3x", "Fast speed [E]",
			func() -> void: GameClock.set_speed(3.0))

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
	button.custom_minimum_size = Vector2(34, 24)
	button.pressed.connect(action)
	row.add_child(button)

func set_inspect(text: String) -> void:
	inspect_label.text = text

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
	_calendar.text = GameClock.calendar_text() + tag
