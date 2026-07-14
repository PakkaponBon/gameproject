class_name ObjectiveTracker
extends CanvasLayer
## The goal ladder: three stages that walk a new player from surviving
## (FIRST STEPS) through settling in (MAKE IT HOME) to the faction arc
## (MAKE IT KNOWN). Collapsed to a badge under the clock; click to expand.
## Every goal is re-derived from world state, so nothing needs saving.

const CHECK_EVERY_TICKS := 10
const GOAL_SLOTS := 3

var _labels: Array[Label] = []
var _title: Label
var _badge: Button
var _panel: PanelContainer
var _cooldown := 0

@onready var main: Node2D = get_parent()

func _ready() -> void:
	_badge = Button.new()
	_badge.toggle_mode = true
	_badge.text = "! 0/3"
	_badge.tooltip_text = "Goals — click to show the checklist"
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
	_panel.offset_left = -260.0
	_panel.offset_right = -8.0
	_panel.offset_top = 78.0
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	_title = Label.new()
	_title.modulate = Color(0.95, 0.85, 0.55)
	_title.add_theme_font_size_override("font_size", 14)
	box.add_child(_title)
	for i in GOAL_SLOTS:
		var label := Label.new()
		box.add_child(label)
		_labels.append(label)
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY_TICKS
	var stage := _current_stage()
	if stage.is_empty():
		visible = false  # the ladder is climbed; the rest is theirs to write
		return
	visible = true
	_title.text = stage.title
	var goals: Array = stage.goals
	var done := 0
	for i in GOAL_SLOTS:
		var label := _labels[i]
		if i >= goals.size():
			label.visible = false
			continue
		label.visible = true
		var goal: Dictionary = goals[i]
		_set_goal(label, bool(goal.done), String(goal.text))
		if goal.done:
			done += 1
	_badge.text = "! %d/%d" % [done, goals.size()]
	_badge.tooltip_text = "%s — click to show the checklist" % stage.title

## First incomplete stage, or {} when the whole ladder is done.
func _current_stage() -> Dictionary:
	var beds := _count_flag("sleep_spot")
	var food := get_tree().get_nodes_in_group("food").size()
	var raid_beaten: bool = main.raid_director.raid_count >= 1 \
			and get_tree().get_nodes_in_group("raiders").is_empty()
	var s1: Array = [
		{"done": beds >= 3, "text": "Build 3 beds (%d/3)" % mini(beds, 3)},
		{"done": food >= 10, "text": "Stock 10 food (%d/10)" % mini(food, 10)},
		{"done": raid_beaten, "text": "Survive the first raid"},
	]
	if not _all_done(s1):
		return {"title": "FIRST STEPS", "goals": s1}
	var s2: Array = [
		{"done": _hearth_indoors(), "text": "Warm a room: hearth inside walls"},
		{"done": _count_flag("workstation") > 0, "text": "Build a forge"},
		{"done": FactionManager.renown >= 2,
				"text": "Renown 2 (%d/2) — beat raids, help factions" % mini(FactionManager.renown, 2)},
	]
	if not _all_done(s2):
		return {"title": "MAKE IT HOME", "goals": s2}
	var s3: Array = [
		{"done": FactionManager.renown >= 4,
				"text": "Renown 4 (%d/4)" % mini(FactionManager.renown, 4)},
		{"done": _any_resolved(), "text": "Resolve a faction — ally or break one [M]"},
	]
	if not _all_done(s3):
		return {"title": "MAKE IT KNOWN", "goals": s3}
	return {}

func _all_done(goals: Array) -> bool:
	for goal: Dictionary in goals:
		if not goal.done:
			return false
	return true

func _count_flag(flag: String) -> int:
	var total := 0
	for cell: Vector2i in WorldGrid.buildings:
		if BuildingDefs.get_def(WorldGrid.buildings[cell]).get(flag, false):
			total += 1
	return total

func _hearth_indoors() -> bool:
	for cell: Vector2i in WorldGrid.warmth_sources:
		if WorldGrid.is_indoors(cell):
			return true
	return false

func _any_resolved() -> bool:
	for id: String in FactionManager.factions:
		if FactionManager.factions[id].resolved != "":
			return true
	return false

func _set_goal(label: Label, done: bool, text: String) -> void:
	label.text = ("[/] " if done else "[ ] ") + text
	label.modulate = Color(0.6, 0.9, 0.6) if done else Color.WHITE
