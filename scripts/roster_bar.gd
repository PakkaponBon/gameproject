class_name RosterBar
extends CanvasLayer
## Bottom-left squad bar: one button per villager. Click selects,
## right-click toggles draft. Colors mirror villager state.

var _box: HBoxContainer
var _refresh_cooldown := 0

@onready var main: Node2D = get_parent()

func _ready() -> void:
	_box = HBoxContainer.new()
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = 8.0
	_box.offset_top = -40.0
	_box.offset_bottom = -8.0
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	GameClock.ticked.connect(_on_tick)

func _on_tick() -> void:
	_refresh_cooldown -= 1
	if _refresh_cooldown > 0:
		return
	_refresh_cooldown = 5  # twice a second, so urgency flashes read
	_rebuild()

func _rebuild() -> void:
	for child in _box.get_children():
		child.queue_free()
	for pawn: Pawn in main.pawns:
		var btn := Button.new()
		btn.text = String(pawn.name)
		btn.custom_minimum_size = Vector2(72, 28)
		var urgent := pawn.collapsed or pawn.combat.is_wounded() or pawn.needs.is_hungry()
		if urgent and int(Time.get_ticks_msec() / 500) % 2 == 0:
			btn.modulate = Color(1.0, 0.35, 0.3)  # flash: needs attention
		elif pawn.drafted:
			btn.modulate = Color(1.0, 0.55, 0.5)
		elif pawn.collapsed:
			btn.modulate = Color(0.7, 0.75, 1.0)
		elif pawn.combat.is_wounded():
			btn.modulate = Color(1.0, 0.85, 0.5)
		btn.tooltip_text = "Click: select (again: jump camera). Right-click: draft."
		btn.pressed.connect(func() -> void: main.select_or_focus(pawn))
		btn.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed \
					and event.button_index == MOUSE_BUTTON_RIGHT:
				pawn.set_drafted(not pawn.drafted))
		_box.add_child(btn)
