class_name ObjectiveTracker
extends CanvasLayer
## Early-game checklist (POLISH.md): teaches the loop without a tutorial.
## Hides itself once everything is done.

const CHECK_EVERY_TICKS := 10

var _labels := {}
var _box: VBoxContainer
var _cooldown := 0

@onready var main: Node2D = get_parent()

func _ready() -> void:
	# Top-right, under the speed buttons; backdrop for legibility.
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -250.0
	panel.offset_right = -8.0
	panel.offset_top = 62.0
	panel.self_modulate = Color(1, 1, 1, 0.85)
	add_child(panel)
	_box = VBoxContainer.new()
	panel.add_child(_box)
	var title := Label.new()
	title.text = "FIRST STEPS"
	title.modulate = Color(0.95, 0.85, 0.55)
	_box.add_child(title)
	for id in ["beds", "food", "raid"]:
		var label := Label.new()
		_box.add_child(label)
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
	visible = not (beds >= 3 and food >= 10 and raid_beaten)

func _set_goal(label: Label, done: bool, text: String) -> void:
	label.text = ("[/] " if done else "[ ] ") + text
	label.modulate = Color(0.6, 0.9, 0.6) if done else Color.WHITE
