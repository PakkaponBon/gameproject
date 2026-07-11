class_name HudController
extends CanvasLayer
## Owns every HUD label and its text. Main pushes state changes here;
## the calendar readout updates itself off the clock.

@onready var mode_label: Label = $ModeLabel
@onready var stats_label: Label = $StatsLabel
@onready var priority_label: Label = $PriorityLabel
@onready var event_label: Label = $EventLabel
@onready var calendar_label: Label = $CalendarLabel

func _ready() -> void:
	GameClock.ticked.connect(_update_calendar)
	GameClock.speed_changed.connect(_update_calendar)
	_update_calendar()

func set_event(text: String) -> void:
	event_label.text = text

func clear_selection() -> void:
	stats_label.text = ""
	priority_label.text = ""

func show_command_mode() -> void:
	mode_label.text = "COMMAND — LMB select / move / attack (drafted)  [R: draft] [B/Z/F/X: modes] [Esc: menu]"

func show_build_mode(def: Dictionary) -> void:
	var costs: Array[String] = []
	for id: String in def.cost:
		costs.append("%d %s" % [int(def.cost[id]), id])
	mode_label.text = "BUILD: %s (%s) — LMB place, RMB remove/cancel  [Q: next building] [B: back]" \
			% [def.name, " + ".join(costs)]

func show_stockpile_mode() -> void:
	mode_label.text = "STOCKPILE — LMB paint zone, RMB erase  [Z: back]"

func show_field_mode(def: Dictionary) -> void:
	mode_label.text = "FIELD: %s — LMB zone field, RMB clear  [Q: next crop] [F: back]" % def.name

func show_safety_mode() -> void:
	mode_label.text = "SAFETY — LMB paint flee zone, RMB erase  [X: back]"

func update_stats(pawn: Pawn) -> void:
	if pawn.dead:
		stats_label.text = "%s — DEAD" % pawn.name
		return
	var suffix := ""
	if pawn.collapsed:
		suffix = "  (COLLAPSED — starving!)"
	elif pawn.drafted:
		suffix = "  (DRAFTED)"
	elif pawn.survival.sleeping:
		suffix = "  (SLEEPING)"
	elif pawn.needs.on_break:
		suffix = "  (MENTAL BREAK)"
	elif pawn.combat.is_wounded():
		suffix = "  (WOUNDED)"
	var gear := pawn.combat.weapon_id if pawn.combat.weapon_id != "" else "unarmed"
	if pawn.combat.is_ranged():
		gear += " x%d" % pawn.combat.ammo
	if pawn.combat.relic_id != "":
		gear += ", " + RelicDefs.get_def(pawn.combat.relic_id).name
	stats_label.text = "%s — hunger %d  rest %d  mood %d  hp %d [%s | melee %d, arch %d]%s" % [
		pawn.name, roundi(pawn.needs.hunger), roundi(pawn.needs.rest),
		roundi(pawn.needs.mood), roundi(pawn.combat.hp), gear,
		pawn.skills.level("melee"), pawn.skills.level("archery"), suffix]

func update_priorities(pawn: Pawn) -> void:
	var trait_names: Array[String] = []
	for id: String in pawn.traits:
		trait_names.append(TraitDefs.get_def(id).name)
	var trait_text := "" if trait_names.is_empty() else " (%s)" % ", ".join(trait_names)
	priority_label.text = "%s%s — Chop: %s  Haul: %s  Build: %s  Farm: %s   [1-4: cycle priority, 0 = off]" % [
		pawn.name, trait_text,
		_priority_text(pawn.work_priorities[Job.Type.CHOP]),
		_priority_text(pawn.work_priorities[Job.Type.HAUL]),
		_priority_text(pawn.work_priorities[Job.Type.BUILD]),
		_priority_text(pawn.work_priorities[Job.Type.PLANT]),
	]

func _priority_text(value: int) -> String:
	return "off" if value == 0 else str(value)

func _update_calendar() -> void:
	var speed_tag := ""
	if GameClock.sim_paused:
		speed_tag = "  || PAUSED"
	elif GameClock.speed != 1.0:
		speed_tag = "  >> x%d" % int(GameClock.speed)
	calendar_label.text = GameClock.calendar_text() + speed_tag
