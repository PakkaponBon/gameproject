class_name WorldMap
extends CanvasLayer
## The realm as a screen: five faction cards + the ruins, driven entirely
## by FactionManager data. Opening it pauses the sim.

var _rows := {}  # faction id -> {strength, attitude, status, gift, envoy, tribute, expedition}
var _ruins_button: Button
var _expedition_label: Label

func _ready() -> void:
	visible = false
	layer = 8
	_build_ui()
	FactionManager.factions_changed.connect(_refresh)

func toggle() -> void:
	visible = not visible
	GameClock.set_sim_paused(visible)
	if visible:
		_refresh()

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.92)
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
	title.text = "THE REALM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for id: String in FactionDefs.ORDER:
		box.add_child(_build_faction_row(id))
	box.add_child(_build_ruins_row())
	_expedition_label = Label.new()
	box.add_child(_expedition_label)
	var close := Button.new()
	close.text = "Close [M]"
	close.pressed.connect(toggle)
	box.add_child(close)

func _build_faction_row(id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var def := FactionDefs.get_def(id)
	var name_label := Label.new()
	name_label.text = "%s (%s)" % [def.name, def.personality]
	name_label.custom_minimum_size = Vector2(240, 0)
	row.add_child(name_label)
	var widgets := {}
	widgets["strength"] = _add_bar(row, 0.0, 100.0, Color(0.75, 0.35, 0.3))
	widgets["attitude"] = _add_bar(row, -100.0, 100.0, Color(0.35, 0.7, 0.4))
	var status := Label.new()
	status.custom_minimum_size = Vector2(88, 0)
	row.add_child(status)
	widgets["status"] = status
	widgets["gift"] = _add_button(row, "Gift (%d wood)" % FactionManager.GIFT_WOOD,
			func() -> void: FactionManager.send_gift(id))
	widgets["envoy"] = _add_button(row, "Envoy",
			func() -> void: FactionManager.send_envoy(id))
	widgets["tribute"] = _add_button(row, "Pay Tribute",
			func() -> void: FactionManager.pay_tribute(id))
	widgets["expedition"] = _add_button(row, "Attack!",
			func() -> void: FactionManager.send_expedition(id))
	_rows[id] = widgets
	return row

func _build_ruins_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = "Ruins of the Old City — relics sleep in the ash"
	label.custom_minimum_size = Vector2(516, 0)
	row.add_child(label)
	_ruins_button = _add_button(row, "Expedition",
			func() -> void: FactionManager.send_expedition("ruins"))
	return row

func _add_bar(row: HBoxContainer, minimum: float, maximum: float, tint: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = minimum
	bar.max_value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(90, 14)
	bar.modulate = tint
	row.add_child(bar)
	return bar

func _add_button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	row.add_child(button)
	return button

func _refresh() -> void:
	if not visible:
		return
	for id: String in _rows:
		var f: Dictionary = FactionManager.factions[id]
		var w: Dictionary = _rows[id]
		w.strength.value = float(f.strength)
		w.strength.tooltip_text = "Strength %d" % int(f.strength)
		w.attitude.value = float(f.attitude)
		w.attitude.tooltip_text = "Attitude %d" % int(f.attitude)
		var status: String = f.resolved
		w.status.text = "ALLIED" if status == "allied" else ("DESTROYED" if status == "destroyed" else "—")
		var open := status == ""
		w.gift.visible = open
		w.envoy.visible = open
		w.tribute.visible = open and FactionManager.demand_pending(id)
		w.expedition.visible = open
		w.expedition.disabled = FactionManager.expedition_active()
	_ruins_button.disabled = FactionManager.expedition_active()
	if FactionManager.expedition_active():
		_expedition_label.text = "Expedition in the field — back at dawn."
	else:
		var party := FactionManager.party_preview()
		_expedition_label.text = "Party ready: %s" % party if party != "" \
				else "No expedition possible (needs 2+ armed villagers)."
