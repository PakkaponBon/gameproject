class_name VillagerPanel
extends CanvasLayer
## Right-side panel for the selected villager: needs bars, mood, skills,
## gear, traits, current activity, priority row, draft + gear buttons.

const SPRITES := preload("res://assets/sprites.png")

var pawn: Pawn = null
var _bars := {}
var _name_label: Label
var _traits_label: Label
var _bond_label: Label
var _activity_label: Label
var _gear_label: Label
var _skills_label: Label
var _priority_buttons := {}
var _draft_button: Button
var _drop_button: Button
var _body: VBoxContainer
var _collapse_button: Button
var _collapsed := false  # sticks across selections once the player sets it

func _ready() -> void:
	visible = false
	_build_ui()

func show_pawn(selected: Pawn) -> void:
	pawn = selected
	visible = pawn != null
	refresh()

## Fold the card down to just the portrait + name, or open it back up.
func set_collapsed(on: bool) -> void:
	_collapsed = on
	_body.visible = not on
	_collapse_button.text = "+" if on else "–"
	_collapse_button.tooltip_text = "Show villager details" if on else "Hide villager details"

func refresh() -> void:
	if pawn == null or not is_instance_valid(pawn):
		visible = false
		pawn = null
		return
	_name_label.text = String(pawn.name)
	var trait_names: Array[String] = []
	var lore: Array[String] = []
	for id: String in pawn.traits:
		trait_names.append(TraitDefs.get_def(id).name)
		lore.append(String(TraitDefs.get_def(id).get("lore", "")))
	_traits_label.text = ", ".join(trait_names)
	_traits_label.tooltip_text = "\n".join(lore)
	_traits_label.mouse_filter = Control.MOUSE_FILTER_STOP
	var bond := pawn.social.strongest_bond_text()
	_bond_label.text = bond
	_bond_label.visible = bond != "" and not _collapsed
	_activity_label.text = pawn.activity_text()
	_bars.hunger.value = pawn.needs.hunger
	_bars.rest.value = pawn.needs.rest
	_bars.mood.value = pawn.needs.mood
	_bars.warmth.value = pawn.needs.warmth
	_bars.joy.value = pawn.needs.joy
	_bars.hp.value = pawn.combat.hp
	var gear := pawn.combat.weapon_id if pawn.combat.weapon_id != "" else "unarmed"
	if pawn.combat.is_ranged():
		gear += " (%d arrows)" % pawn.combat.ammo
	if pawn.combat.relic_id != "":
		gear += " + %s" % ResourceDefs.get_def(pawn.combat.relic_id).name
	_gear_label.text = "Gear: " + gear
	_skills_label.text = "Melee %d   Archery %d" \
			% [pawn.skills.level("melee"), pawn.skills.level("archery")]
	for type: int in _priority_buttons:
		var value := int(pawn.work_priorities[type])
		var btn: Button = _priority_buttons[type]
		btn.text = "%s: %s" % [btn.get_meta("job_name"), "off" if value == 0 else str(value)]
	_draft_button.text = "Undraft [R]" if pawn.drafted else "Draft [R]"
	_drop_button.visible = pawn.combat.weapon_id != ""

func _build_ui() -> void:
	# Bottom-right corner: never collides with objectives or the feed.
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -258.0
	panel.offset_right = -8.0
	panel.offset_top = -8.0
	panel.offset_bottom = -8.0
	# Sized by content, expanding upward — can never overflow the screen.
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	# Header: pixel portrait beside name + backstory.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = SPRITES
	atlas.region = Rect2(0, 0, 16, 16)
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(44, 44)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head.add_child(portrait)
	var id_box := VBoxContainer.new()
	id_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	id_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(id_box)
	_name_label = Label.new()
	_name_label.theme_type_variation = "Title"
	id_box.add_child(_name_label)
	_traits_label = Label.new()
	_traits_label.theme_type_variation = "Muted"
	id_box.add_child(_traits_label)
	_bond_label = Label.new()
	_bond_label.theme_type_variation = "Muted"
	id_box.add_child(_bond_label)
	# Collapse toggle: folds the card to just this header strip.
	_collapse_button = Button.new()
	_collapse_button.custom_minimum_size = Vector2(26, 26)
	_collapse_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_collapse_button.pressed.connect(func() -> void: set_collapsed(not _collapsed))
	head.add_child(_collapse_button)
	# Everything below the header lives in _body so it can be hidden at once.
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 5)
	box.add_child(_body)
	_body.add_child(HSeparator.new())
	_activity_label = _label(_body)
	_activity_label.modulate = Color(0.8, 0.88, 0.78)
	# Idle reasons get wordy — wrap instead of running off the card edge.
	_activity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_activity_label.custom_minimum_size = Vector2(240, 0)
	# Small-caps tag + thin pill bar per need.
	var bar_tints := {
		"hunger": Color(0.9, 0.65, 0.3), "rest": Color(0.5, 0.65, 0.9),
		"mood": Color(0.9, 0.85, 0.4), "warmth": Color(0.95, 0.6, 0.5),
		"joy": Color(0.7, 0.55, 0.9), "hp": Color(0.9, 0.4, 0.4),
	}
	for key: String in bar_tints:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var tag := Label.new()
		tag.theme_type_variation = "Header"
		tag.text = key.to_upper()
		tag.custom_minimum_size = Vector2(56, 0)
		row.add_child(tag)
		var bar := ProgressBar.new()
		bar.max_value = 100.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.modulate = bar_tints[key]
		row.add_child(bar)
		_body.add_child(row)
		_bars[key] = bar
	_body.add_child(HSeparator.new())
	_gear_label = _label(_body)
	_gear_label.theme_type_variation = "Muted"
	_skills_label = _label(_body)
	_skills_label.theme_type_variation = "Muted"
	# Priorities as a tight 2x2 grid.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_body.add_child(grid)
	var jobs := {Job.Type.CHOP: "Chop", Job.Type.HAUL: "Haul", Job.Type.BUILD: "Build", Job.Type.PLANT: "Farm"}
	for type: int in jobs:
		var btn := Button.new()
		btn.set_meta("job_name", jobs[type])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.tooltip_text = "Click to cycle: 1 (first) > 2 > 3 > off"
		btn.pressed.connect(func() -> void:
			pawn.cycle_priority(type)
			refresh())
		grid.add_child(btn)
		_priority_buttons[type] = btn
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	_body.add_child(actions)
	_draft_button = Button.new()
	_draft_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_draft_button.tooltip_text = "Drafted villagers follow your orders and ignore work/needs."
	_draft_button.pressed.connect(func() -> void:
		pawn.set_drafted(not pawn.drafted)
		refresh())
	actions.add_child(_draft_button)
	_drop_button = Button.new()
	_drop_button.text = "Drop weapon"
	_drop_button.tooltip_text = "Leave the weapon here so another villager can claim it."
	_drop_button.pressed.connect(func() -> void:
		pawn.combat.unequip()
		refresh())
	actions.add_child(_drop_button)
	set_collapsed(false)  # label the toggle, start expanded

func _label(box: VBoxContainer) -> Label:
	var label := Label.new()
	box.add_child(label)
	return label
