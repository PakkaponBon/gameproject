class_name PriorityGrid
extends CanvasLayer
## Work priority grid (P): villagers x job types, click a cell to cycle
## 1 -> 2 -> 3 -> off. Pauses the sim while open.

const JOBS := {Job.Type.CHOP: "Chop", Job.Type.HAUL: "Haul", Job.Type.BUILD: "Build", Job.Type.PLANT: "Farm"}

var _grid: GridContainer

func _ready() -> void:
	visible = false
	layer = 8
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "WORK PRIORITIES  (1 = first, off = never)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_grid = GridContainer.new()
	_grid.columns = JOBS.size() + 1
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 6)
	box.add_child(_grid)
	var close := Button.new()
	close.text = "Close [P]"
	close.pressed.connect(toggle)
	box.add_child(close)

func toggle() -> void:
	visible = not visible
	GameClock.set_sim_paused(visible)
	if visible:
		_rebuild()

func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_grid.add_child(_header(""))
	for type: int in JOBS:
		_grid.add_child(_header(JOBS[type]))
	var main: Node2D = get_parent()
	for pawn: Pawn in main.pawns:
		_grid.add_child(_header(String(pawn.name)))
		for type: int in JOBS:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(72, 0)
			_set_cell_text(btn, pawn, type)
			btn.pressed.connect(func() -> void:
				pawn.cycle_priority(type)
				_set_cell_text(btn, pawn, type))
			_grid.add_child(btn)

func _set_cell_text(btn: Button, pawn: Pawn, type: int) -> void:
	var value := int(pawn.work_priorities[type])
	btn.text = "off" if value == 0 else str(value)

func _header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label
