class_name ObjectiveTracker
extends CanvasLayer
## Early-game checklist (POLISH.md): teaches the loop without a tutorial.
## Cities-style: collapsed to a badge under the clock; click to expand.
## The whole layer hides itself once everything is done.

const CHECK_EVERY_TICKS := 10

var _labels := {}
var _badge: Button
var _panel: PanelContainer
var _cooldown := 0

@onready var main: Node2D = get_parent()

func _ready() -> void:
	_badge = Button.new()
	_badge.toggle_mode = true
	_badge.text = "! 0/3"
	_badge.tooltip_text = "First steps — click to show the checklist"
	_badge.anchor_left = 1.0
	_badge.anchor_right = 1.0
	_badge.offset_left = -72.0
	_badge.offset_right = -8.0
	_badge.offset_top = 44.0
	_badge.offset_bottom = 72.0
	_badge.toggled.connect(func(open: bool) -> void: _panel.visible = open)
	add_child(_badge)
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.offset_left = -250.0
	_panel.offset_right = -8.0
	_panel.offset_top = 78.0
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "FIRST STEPS"
	title.modulate = Color(0.95, 0.85, 0.55)
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	for id in ["beds", "food", "raid"]:
		var label := Label.new()
		box.add_child(label)
		_labels[id] = label
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY_TICKS
	var beds := 0
	for cell: Vector2i in WorldGrid.buildings:
		if BuildingDefs.get_def(WorldGrid.buildings[cell]).get("sleep_spot", false):
			beds += 1
	var food := get_tree().get_nodes_in_group("food").size()
	var raid_beaten: bool = main.raid_director.raid_count >= 1 \
			and get_tree().get_nodes_in_group("raiders").is_empty()
	_set_goal(_labels.beds, beds >= 3, "Build 3 beds (%d/3)" % mini(beds, 3))
	_set_goal(_labels.food, food >= 10, "Stock 10 food (%d/10)" % mini(food, 10))
	_set_goal(_labels.raid, raid_beaten, "Survive the first raid")
	var done := int(beds >= 3) + int(food >= 10) + int(raid_beaten)
	_badge.text = "! %d/3" % done
	visible = done < 3

func _set_goal(label: Label, done: bool, text: String) -> void:
	label.text = ("[/] " if done else "[ ] ") + text
	label.modulate = Color(0.6, 0.9, 0.6) if done else Color.WHITE
