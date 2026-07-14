class_name ChroniclePanel
extends CanvasLayer
## The village's story so far, newest first. Opened from the toolbar
## (memorial stone) or [C]; rebuilt from ChronicleDirector on open.

var _list: VBoxContainer

@onready var main: Node2D = get_parent()

func _ready() -> void:
	visible = false
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -270.0
	panel.offset_right = 270.0
	panel.offset_top = -190.0
	panel.offset_bottom = 190.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "THE CHRONICLE"
	title.modulate = Color(0.95, 0.85, 0.55)
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	var close := Button.new()
	close.text = "Close [C]"
	close.pressed.connect(toggle)
	box.add_child(close)

func toggle() -> void:
	visible = not visible
	if visible:
		_rebuild()

func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	var director: ChronicleDirector = main.chronicle_director
	if director.entries.is_empty():
		var empty := Label.new()
		empty.text = "Nothing yet — the story is just beginning."
		empty.theme_type_variation = "Muted"
		_list.add_child(empty)
		return
	for i in range(director.entries.size() - 1, -1, -1):  # newest first
		var entry: Dictionary = director.entries[i]
		var date := Label.new()
		date.theme_type_variation = "Header"
		date.text = director.date_of(int(entry.tick))
		_list.add_child(date)
		var text := Label.new()
		text.text = String(entry.text)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(text)
