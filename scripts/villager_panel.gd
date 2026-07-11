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
	for id: String in pawn.traits:
		trait_names.append(TraitDefs.get_def(id).name)
	_traits_label.text = ", ".join(trait_names)
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
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240.0
	panel.offset_right = -8.0
	panel.offset_top = -160.0
	panel.offset_bottom = 160.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	_name_label = _label(box)
	_traits_label = _label(box)
	_activity_label = _label(box)
	var bar_tints := {
		"hunger": Color(0.9, 0.65, 0.3), "rest": Color(0.5, 0.65, 0.9),
		"mood": Color(0.9, 0.85, 0.4), "hp": Color(0.9, 0.4, 0.4),
	}
	for key: String in bar_tints:
		box.add_child(_label_for(key))
		var bar := ProgressBar.new()
		bar.max_value = 100.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 10)
		bar.modulate = bar_tints[key]
		box.add_child(bar)
		_bars[key] = bar
	_gear_label = _label(box)
	_skills_label = _label(box)
	var jobs := {Job.Type.CHOP: "Chop", Job.Type.HAUL: "Haul", Job.Type.BUILD: "Build", Job.Type.PLANT: "Farm"}
	for type: int in jobs:
		var btn := Button.new()
		btn.set_meta("job_name", jobs[type])
		btn.pressed.connect(func() -> void:
			pawn.cycle_priority(type)
			refresh())
		box.add_child(btn)
		_priority_buttons[type] = btn
	_draft_button = Button.new()
	_draft_button.tooltip_text = "Drafted villagers follow your orders and ignore work/needs."
	_draft_button.pressed.connect(func() -> void:
		pawn.set_drafted(not pawn.drafted)
		refresh())
	box.add_child(_draft_button)
	_drop_button = Button.new()
	_drop_button.text = "Drop weapon"
	_drop_button.tooltip_text = "Leave the weapon here so another villager can claim it."
	_drop_button.pressed.connect(func() -> void:
		pawn.combat.unequip()
		refresh())
	box.add_child(_drop_button)

func _label(box: VBoxContainer) -> Label:
	var label := Label.new()
	box.add_child(label)
	return label

func _label_for(key: String) -> Label:
	var label := Label.new()
	label.text = key.capitalize()
	return label
