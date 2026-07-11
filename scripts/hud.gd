class_name HudController
extends CanvasLayer
## Ambient HUD: mode line, calendar (with speed/threat tags), resource
## counts, and a fading notification feed. Per-villager info lives in
## VillagerPanel now.

const FEED_MAX := 5
const FEED_SECONDS := 12.0

var _feed: VBoxContainer
var _resource_cooldown := 0

@onready var mode_label: Label = $ModeLabel
@onready var resource_label: Label = $ResourceLabel
@onready var inspect_label: Label = $InspectLabel
@onready var calendar_label: Label = $CalendarLabel

func _ready() -> void:
	_feed = VBoxContainer.new()
	_feed.offset_left = 8.0
	_feed.offset_top = 52.0
	_feed.offset_right = 560.0
	add_child(_feed)
	GameClock.ticked.connect(_on_tick)
	GameClock.speed_changed.connect(_update_calendar)
	_update_calendar()

## Push a message into the feed (empty strings are ignored).
func set_event(text: String, tint := Color.WHITE) -> void:
	if text == "":
		return
	var label := Label.new()
	label.text = "> " + text
	label.modulate = tint
	_feed.add_child(label)
	if _feed.get_child_count() > FEED_MAX:
		_feed.get_child(0).queue_free()
	get_tree().create_timer(FEED_SECONDS).timeout.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free())

func set_inspect(text: String) -> void:
	inspect_label.text = text

func show_command_mode() -> void:
	mode_label.modulate = Color.WHITE
	mode_label.text = "COMMAND — LMB select/move/attack  [R draft] [B/Z/F/X tools] [M map] [P priorities] [H help]"

func show_build_mode(def: Dictionary) -> void:
	var costs: Array[String] = []
	for id: String in def.cost:
		costs.append("%d %s" % [int(def.cost[id]), id])
	mode_label.modulate = Color(1.0, 0.75, 0.45)
	mode_label.text = "BUILD: %s (%s) — LMB place, RMB remove/cancel  [Q: next] [B: back]" \
			% [def.name, " + ".join(costs)]

func show_stockpile_mode() -> void:
	mode_label.modulate = Color(1.0, 0.9, 0.5)
	mode_label.text = "STOCKPILE — LMB paint zone, RMB erase  [Z: back]"

func show_field_mode(def: Dictionary) -> void:
	mode_label.modulate = Color(0.65, 0.9, 0.55)
	mode_label.text = "FIELD: %s — LMB zone field, RMB clear  [Q: next crop] [F: back]" % def.name

func show_safety_mode() -> void:
	mode_label.modulate = Color(0.75, 0.65, 0.95)
	mode_label.text = "SAFETY — LMB paint flee zone, RMB erase  [X: back]"

func _on_tick() -> void:
	_update_calendar()
	_resource_cooldown -= 1
	if _resource_cooldown > 0:
		return
	_resource_cooldown = 10
	_update_resources()

func _update_resources() -> void:
	var counts := {"wood": 0, "stone": 0, "iron_ore": 0, "iron_ingot": 0}
	for node in get_tree().get_nodes_in_group("resources"):
		var item := node as ResourceItem
		if counts.has(item.resource_id) and not (item.get_parent() is Pawn):
			counts[item.resource_id] += 1
	var raw := 0
	var meals := 0
	for node in get_tree().get_nodes_in_group("food"):
		if (node as FoodItem).meal:
			meals += 1
		else:
			raw += 1
	resource_label.text = "Wood %d   Stone %d   Ore %d   Ingots %d   Food %d (+%d meals)   Renown %d" \
			% [counts.wood, counts.stone, counts.iron_ore, counts.iron_ingot, raw, meals, FactionManager.renown]

func _update_calendar() -> void:
	var tag := ""
	if GameClock.sim_paused:
		tag = "  || PAUSED"
	elif GameClock.speed != 1.0:
		tag = "  >> x%d" % int(GameClock.speed)
	if not get_tree().get_nodes_in_group("raiders").is_empty():
		tag += "  !! RAID"
	calendar_label.text = GameClock.calendar_text() + tag
