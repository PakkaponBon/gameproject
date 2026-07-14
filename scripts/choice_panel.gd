class_name ChoicePanel
extends CanvasLayer
## A dilemma at the gate: title, a few lines, two buttons. Pauses the sim
## while open — decisions are the game, so the game waits for them.

var _title: Label
var _body: Label
var _buttons: Array[Button] = []
var _actions: Array[Callable] = [Callable(), Callable()]
var _was_paused := false

func _ready() -> void:
	layer = 8
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.04, 0.5)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240.0
	panel.offset_right = 240.0
	panel.offset_top = -110.0
	panel.offset_bottom = 110.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_title = Label.new()
	_title.modulate = Color(0.95, 0.85, 0.55)
	_title.add_theme_font_size_override("font_size", 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(440, 70)
	box.add_child(_body)
	for i in 2:
		var button := Button.new()
		button.pressed.connect(_choose.bind(i))
		box.add_child(button)
		_buttons.append(button)

func open(title: String, body: String, option_a: String, option_b: String,
		on_a: Callable, on_b: Callable) -> void:
	_title.text = title
	_body.text = body
	_buttons[0].text = option_a
	_buttons[1].text = option_b
	_actions = [on_a, on_b]
	_was_paused = GameClock.sim_paused
	GameClock.set_sim_paused(true)
	visible = true

func _choose(index: int) -> void:
	visible = false
	GameClock.set_sim_paused(_was_paused)
	if _actions[index].is_valid():
		_actions[index].call()
