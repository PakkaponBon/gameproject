class_name VillagerPanel
extends CanvasLayer
## Right-side panel for the selected villager: needs bars, mood, skills,
## gear, traits, current activity, priority row, draft + gear buttons.

var pawn: Pawn = null
var _bars := {}
var _name_label: Label
var _traits_label: Label
var _activity_label: Label
var _gear_label: Label
var _skills_label: Label
var _priority_buttons := {}
var _draft_button: Button
var _drop_button: Button

func _ready() -> void:
	visible = false
	_build_ui()

func show_pawn(selected: Pawn) -> void:
	pawn = selected
	visible = pawn != null
	refresh()

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
	_activity_label.text = pawn.activity_text()
	_bars.hunger.value = pawn.needs.hunger
	_bars.rest.value = pawn.needs.rest
	_bars.mood.value = pawn.needs.mood
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
	panel.offset_top = -324.0
	panel.offset_bottom = -8.0
	panel.self_modulate = Color(1, 1, 1, 0.92)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	_name_label = _label(box)
	_name_label.modulate = Color(0.95, 0.9, 0.7)
	_traits_label = _label(box)
	_traits_label.modulate = Color(0.75, 0.75, 0.8)
	_activity_label = _label(box)
	# Compact label+bar rows instead of stacked pairs.
	var bar_tints := {
		"hunger": Color(0.9, 0.65, 0.3), "rest": Color(0.5, 0.65, 0.9),
		"mood": Color(0.9, 0.85, 0.4), "hp": Color(0.9, 0.4, 0.4),
	}
	for key: String in bar_tints:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var tag := Label.new()
		tag.text = key.capitalize()
		tag.custom_minimum_size = Vector2(52, 0)
		row.add_child(tag)
		var bar := ProgressBar.new()
		bar.max_value = 100.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.modulate = bar_tints[key]
		row.add_child(bar)
		box.add_child(row)
		_bars[key] = bar
	_gear_label = _label(box)
	_skills_label = _label(box)
	# Priorities as a tight 2x2 grid.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
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
	box.add_child(actions)
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

func _label(box: VBoxContainer) -> Label:
	var label := Label.new()
	box.add_child(label)
	return label
