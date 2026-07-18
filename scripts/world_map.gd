class_name WorldMap
extends CanvasLayer
## The realm as an actual map: your village at the heart, the five
## factions and the ruins placed around it, roads tinted by standing.
## Click a place, act on it in the side panel. Still pure UI over
## FactionManager data — nothing here simulates.

const SPRITES := preload("res://assets/sprites.png")
const TILES := preload("res://assets/tiles.png")

## Layout + flavor per place. pos is a fraction of the map area.
const PLACES := {
	"village": {"pos": Vector2(0.5, 0.54), "sheet": "tiles", "cell": 10,
			"tint": Color.WHITE, "label": "Ashfall",
			"flavor": "Your hearth. Everything on this map wants something from it."},
	"black_pines": {"pos": Vector2(0.19, 0.26), "sheet": "sprites", "cell": 15,
			"tint": Color(0.75, 0.8, 0.7),
			"flavor": "Cutthroats of the near woods. They probe for weakness."},
	"vale_remnant": {"pos": Vector2(0.8, 0.2), "sheet": "sprites", "cell": 25,
			"tint": Color.WHITE,
			"flavor": "What remains of the old kingdom's honor. Envoys mean much here."},
	"mosswood": {"pos": Vector2(0.13, 0.64), "sheet": "sprites", "cell": 16,
			"tint": Color.WHITE,
			"flavor": "Deep-forest traders. Everything has a price."},
	"deepstone": {"pos": Vector2(0.87, 0.6), "sheet": "tiles", "cell": 6,
			"tint": Color.WHITE,
			"flavor": "Mountain holds, rich and wary. Gifts speak loudest."},
	"ashen_legion": {"pos": Vector2(0.5, 0.1), "sheet": "sprites", "cell": 15,
			"tint": Color(0.55, 0.2, 0.16),
			"flavor": "The ones who burned Vhal. They are not done."},
	"ruins": {"pos": Vector2(0.68, 0.86), "sheet": "sprites", "cell": 13,
			"tint": Color(0.8, 0.8, 0.9), "label": "Ruins of Vhal",
			"flavor": "The old city. Relics sleep in the ash."},
	"witchfen": {"pos": Vector2(0.24, 0.88), "sheet": "sprites", "cell": 22,
			"tint": Color(0.75, 0.85, 0.8), "label": "The Witchfen",
			"flavor": "Lights over the marsh. Herbs, and worse things, grow rich there."},
	"dwarf_road": {"pos": Vector2(0.93, 0.42), "sheet": "sprites", "cell": 6,
			"tint": Color(0.8, 0.78, 0.85), "label": "The Dwarf-road",
			"flavor": "A dead road of the deep folk. Its waystations still hold iron."},
	"howling_barrow": {"pos": Vector2(0.07, 0.44), "sheet": "sprites", "cell": 17,
			"tint": Color(0.7, 0.68, 0.78), "label": "The Howling Barrow",
			"flavor": "The oldest grave in the realm. Rich in shards; poor in mercy."},
}

const BG_PATH := "res://assets/worldmap.png"  # reserved for the asset agent's illustrated realm

var _map: Control
var _nodes := {}  # place id -> {root, icon, name, strength?, attitude?}
var _selected := "village"
var _bg: Texture2D = null  # illustrated backdrop, drawn behind the roads once it exists

var _d_title: Label
var _d_flavor: Label
var _d_stats: Label
var _d_gift: Button
var _d_envoy: Button
var _d_tribute: Button
var _d_attack: Button
var _d_expedition: Button
var _expedition_label: Label

func _ready() -> void:
	visible = false
	layer = 8
	# Graceful hook: use the illustrated realm backdrop once the asset agent
	# provides it; until then the map is the plain node graph.
	if ResourceLoader.exists(BG_PATH):
		_bg = load(BG_PATH)
	_build_ui()
	FactionManager.factions_changed.connect(_refresh)

func toggle() -> void:
	visible = not visible
	GameClock.set_sim_paused(visible)
	if visible:
		_layout_nodes()  # map size is settled by now; place the markers
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
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := Label.new()
	title.text = "THE REALM"
	title.theme_type_variation = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 10)
	box.add_child(split)
	var map_frame := PanelContainer.new()
	map_frame.theme_type_variation = "SlimPanel"
	split.add_child(map_frame)
	_map = Control.new()
	_map.custom_minimum_size = Vector2(560, 400)
	_map.draw.connect(_draw_roads)
	_map.resized.connect(_layout_nodes)
	map_frame.add_child(_map)
	for id: String in PLACES:
		_build_node(id)
	split.add_child(_build_detail())
	_expedition_label = Label.new()
	_expedition_label.theme_type_variation = "Muted"
	box.add_child(_expedition_label)
	var close := Button.new()
	close.text = "Close [M]"
	close.pressed.connect(toggle)
	box.add_child(close)

func _build_node(id: String) -> void:
	var place: Dictionary = PLACES[id]
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(96, 0)
	root.add_theme_constant_override("separation", 2)
	_map.add_child(root)
	var center := HBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(center)
	var sheet: Texture2D = TILES if place.sheet == "tiles" else SPRITES
	var icon := UiTheme.icon_button(sheet, Rect2(int(place.cell) * 16, 0, 16, 16),
			place.tint, String(place.flavor), Vector2(44, 40))
	icon.pressed.connect(_select.bind(id))
	center.add_child(icon)
	var name_label := Label.new()
	name_label.theme_type_variation = "Header"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = _place_name(id)
	root.add_child(name_label)
	var widgets := {"root": root, "icon": icon, "name": name_label}
	if FactionDefs.DEFS.has(id):
		widgets["strength"] = _mini_bar(root, 0.0, 100.0, Color(0.75, 0.35, 0.3),
				"Strength — attack and kill raiders to grind it down")
		widgets["attitude"] = _mini_bar(root, -100.0, 100.0, Color(0.35, 0.7, 0.4),
				"Attitude — gifts and envoys raise it; alliance at +100")
	_nodes[id] = widgets

func _build_detail() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "SlimPanel"
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(236, 0)
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	_d_title = Label.new()
	_d_title.theme_type_variation = "Title"
	box.add_child(_d_title)
	_d_flavor = Label.new()
	_d_flavor.theme_type_variation = "Muted"
	_d_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_d_flavor)
	_d_stats = Label.new()
	_d_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_d_stats)
	_d_gift = Button.new()
	_d_gift.text = "Send Gift (%d wood)" % FactionManager.GIFT_WOOD
	_d_gift.tooltip_text = "Spend stored wood to warm their attitude. Greedy factions love it. If they have an open request, the gift answers it."
	_d_gift.pressed.connect(func() -> void: FactionManager.send_gift(_selected))
	box.add_child(_d_gift)
	_d_envoy = Button.new()
	_d_envoy.text = "Send Envoy"
	_d_envoy.tooltip_text = "Free goodwill, once per day per faction. Honorable factions respect it."
	_d_envoy.pressed.connect(func() -> void: FactionManager.send_envoy(_selected))
	box.add_child(_d_envoy)
	_d_tribute = Button.new()
	_d_tribute.text = "Pay Tribute (%d wood)" % FactionManager.TRIBUTE_WOOD
	_d_tribute.tooltip_text = "Answer their demand before it sours relations."
	_d_tribute.pressed.connect(func() -> void: FactionManager.pay_tribute(_selected))
	box.add_child(_d_tribute)
	_d_attack = _confirm_button("Attack!",
			func() -> void: FactionManager.send_expedition(_selected))
	box.add_child(_d_attack)
	_d_expedition = _confirm_button("Send Expedition",
			func() -> void: FactionManager.send_expedition(_selected))
	box.add_child(_d_expedition)
	return panel

func _mini_bar(root: VBoxContainer, minimum: float, maximum: float, tint: Color,
		tip: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = minimum
	bar.max_value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.modulate = tint
	bar.tooltip_text = tip
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bar)
	return bar

## Two-click safety for expeditions: villagers leave the map for a day.
func _confirm_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.set_meta("base_text", text)
	button.tooltip_text = "Sends your best 3 armed villagers away for a day. Casualties are possible."
	button.pressed.connect(func() -> void:
		if button.get_meta("armed", false):
			button.set_meta("armed", false)
			action.call()
		else:
			button.set_meta("armed", true)
			button.text = "Confirm?")
	return button

func _reset_confirm(button: Button) -> void:
	button.set_meta("armed", false)
	button.text = button.get_meta("base_text")

func _select(id: String) -> void:
	_selected = id
	_refresh()

func _place_name(id: String) -> String:
	var place: Dictionary = PLACES[id]
	if place.has("label"):
		return String(place.label)
	return String(FactionDefs.get_def(id).name)

func _layout_nodes() -> void:
	for id: String in _nodes:
		var root: Control = _nodes[id].root
		root.position = Vector2(PLACES[id].pos) * _map.size - Vector2(48, 22)
	_map.queue_redraw()

## The illustrated backdrop (if any), then roads from the village outward.
func _draw_roads() -> void:
	if _bg:
		_map.draw_texture_rect(_bg, Rect2(Vector2.ZERO, _map.size), false)
	var home: Vector2 = Vector2(PLACES["village"].pos) * _map.size
	for id: String in PLACES:
		if id == "village":
			continue
		var color := Color(0.55, 0.48, 0.36, 0.5)  # neutral track
		if FactionManager.factions.has(id):
			var f: Dictionary = FactionManager.factions[id]
			if f.resolved == "allied":
				color = Color(0.9, 0.78, 0.4, 0.7)
			elif f.resolved == "destroyed":
				color = Color(0.3, 0.3, 0.32, 0.5)
			elif float(f.attitude) < 0.0:
				color = Color(0.75, 0.3, 0.25, 0.55)
		_map.draw_line(home, Vector2(PLACES[id].pos) * _map.size, color, 2.0)

func _refresh() -> void:
	if not visible:
		return
	_map.queue_redraw()
	for id: String in _nodes:
		if not FactionManager.factions.has(id):
			continue
		var f: Dictionary = FactionManager.factions[id]
		var w: Dictionary = _nodes[id]
		w.strength.value = float(f.strength)
		w.attitude.value = float(f.attitude)
		var name_label: Label = w.name
		var icon: Button = w.icon
		icon.modulate = Color.WHITE
		if f.resolved == "allied":
			name_label.text = _place_name(id) + " (ALLIED)"
			name_label.modulate = Color(0.9, 0.78, 0.4)
		elif f.resolved == "destroyed":
			name_label.text = _place_name(id) + " (BROKEN)"
			name_label.modulate = Color(0.5, 0.5, 0.52)
			icon.modulate = Color(0.45, 0.45, 0.45)
		else:
			var marks := ""
			if FactionManager.has_oath(id):
				marks += " (KIN)"
			if FactionManager.demand_pending(id):
				marks += " !"
			if not FactionManager.request.is_empty() and String(FactionManager.request.id) == id:
				marks += " ?"
			name_label.text = _place_name(id) + marks
			name_label.modulate = Color(0.95, 0.85, 0.55) if marks != "" else Color.WHITE
	_refresh_detail()
	if FactionManager.expedition_active():
		_expedition_label.text = "Expedition in the field — back at dawn."
	else:
		var party := FactionManager.party_preview()
		_expedition_label.text = "Party ready: %s" % party if party != "" \
				else "No expedition possible (needs 2+ armed villagers)."

func _refresh_detail() -> void:
	var place: Dictionary = PLACES[_selected]
	_d_title.text = _place_name(_selected)
	_d_flavor.text = String(place.flavor)
	var is_faction := FactionManager.factions.has(_selected)
	var is_site := SiteDefs.DEFS.has(_selected)
	_d_gift.visible = false
	_d_envoy.visible = false
	_d_tribute.visible = false
	_d_attack.visible = false
	_d_expedition.visible = is_site
	if _selected == "village":
		var lines := "Renown: %d" % FactionManager.renown
		if not FactionManager.request.is_empty():
			var r: Dictionary = FactionManager.request
			lines += "\nOpen request: %d %s for %s." \
					% [int(r.amount), String(r.resource), _place_name(String(r.id))]
		_d_stats.text = lines
	elif is_site:
		var sdef := SiteDefs.get_def(_selected)
		var ready_in := FactionManager.site_ready_in(_selected)
		var lines := "Danger: %d · Shards: %d · Relic odds: %d%%" \
				% [int(sdef.strength), int(sdef.shards), int(float(sdef.relic_chance) * 100.0)]
		var odds := FactionManager.expedition_odds(_selected)
		if odds != "":
			lines += "\n" + odds
		if ready_in > 0:
			lines += "\nThe trail is cold — ready in %.1f days." \
					% (float(ready_in) / GameClock.TICKS_PER_DAY)
		_d_stats.text = lines
		_d_expedition.disabled = FactionManager.expedition_active() or ready_in > 0
		_reset_confirm(_d_expedition)
	elif is_faction:
		var f: Dictionary = FactionManager.factions[_selected]
		var def := FactionDefs.get_def(_selected)
		# The face across the table: leader, their quirk, then the numbers.
		if def.has("leader"):
			_d_flavor.text = "%s — %s\n%s" % [String(def.leader), String(def.quirk), String(place.flavor)]
		_d_stats.text = "Attitude %d · Strength %d\nTemperament: %s" \
				% [int(f.attitude), int(f.strength), String(def.personality)]
		if FactionManager.has_oath(_selected):
			_d_stats.text += "\nBound to you by kinship."
		if f.resolved == "":
			var odds := FactionManager.expedition_odds(_selected)
			if odds != "":
				_d_stats.text += "\nIf attacked now: " + odds.to_lower()
		if def.has("likes"):
			_d_gift.tooltip_text = "%s prizes %s (%d) — that gift earns deep favor. Otherwise: %d wood." \
					% [String(def.leader), ResourceDefs.get_def(String(def.likes)).name,
					int(def.likes_count), FactionManager.GIFT_WOOD]
		else:
			_d_gift.tooltip_text = "Spend stored wood to warm their attitude."
		var open: bool = f.resolved == ""
		_d_gift.visible = open
		_d_envoy.visible = open
		_d_tribute.visible = open and FactionManager.demand_pending(_selected)
		_d_attack.visible = open
		_d_attack.disabled = FactionManager.expedition_active()
		_reset_confirm(_d_attack)
