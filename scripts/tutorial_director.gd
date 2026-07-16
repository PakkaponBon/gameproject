class_name TutorialDirector
extends CanvasLayer
## Interactive onboarding: eight small steps, each completed by DOING the
## thing — never modal, the sim keeps running. Skippable, saved with the
## game, and silent on saves that predate it.

const CHECK_EVERY_TICKS := 10

var step := 0
var finished := false

var _title: Label
var _body: Label
var _cooldown := 0
var _steps: Array = []

@onready var main: Node2D = get_parent()

func _ready() -> void:
	_steps = [
		{"text": "Left-click a villager to select them. Their card opens bottom-right.",
				"done": func() -> bool: return main.selected != null},
		{"text": "With a villager selected, left-click open ground to send them walking.",
				"done": func() -> bool: return main.commands_issued > 0},
		{"text": "Food first: pick the Fields tool [F] and drag a small field onto grass. Villagers plant and harvest it themselves.",
				"done": func() -> bool: return WorldGrid.fields.size() >= 4},
		{"text": "Storage: open Build [B] and place a Barn, so wood and food get hauled out of the mud.",
				"done": func() -> bool: return _has_flag("storage")},
		{"text": "Rest: build a Bed [B]. Villagers sleep and heal in beds.",
				"done": func() -> bool: return _has_flag("sleep_spot")},
		{"text": "Safety: raise Walls with a Gate [B] — raiders will come, and they fight where you choose.",
				"done": func() -> bool: return _has_id("gate") or _has_id("door")},
		{"text": "Fighting: select a villager and press [R] to draft them. Drafted villagers obey clicks and ignore work — press [R] again after a fight!",
				"done": func() -> bool: return _any_drafted()},
		{"text": "The realm: press [M]. Gifts and envoys make friends; expeditions raid the wild sites. The rest is yours. ([H] = full guide.)",
				"done": func() -> bool: return main.world_map.visible},
	]
	_build_ui()
	visible = not finished
	GameClock.ticked.connect(_on_tick)
	_refresh()

## Save/load: resume mid-tutorial; old saves pass finished=true.
func restore(saved_step: int, saved_finished: bool) -> void:
	step = clampi(saved_step, 0, _steps.size())
	finished = saved_finished
	visible = not finished
	_refresh()

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "SlimPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = 58.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	_title = Label.new()
	_title.theme_type_variation = "Header"
	_title.modulate = Color(0.95, 0.85, 0.55)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	var skip := Button.new()
	skip.text = "Skip"
	skip.tooltip_text = "Hide the tutorial for this village."
	skip.custom_minimum_size = Vector2(52, 22)
	skip.pressed.connect(_finish)
	head.add_child(skip)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(480, 0)
	box.add_child(_body)

func _on_tick() -> void:
	if finished:
		return
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY_TICKS
	var check: Callable = _steps[step].done
	if check.call():
		EventBus.play_sfx.emit("click")
		step += 1
		if step >= _steps.size():
			_finish()
			main.hud.set_event("Tutorial complete — the village is yours.", Color(0.7, 0.95, 0.7))
			EventBus.chronicle_entry.emit("The village learned to stand on its own.")
		else:
			_refresh()

func _finish() -> void:
	finished = true
	visible = false

func _refresh() -> void:
	if finished or _steps.is_empty():
		return
	_title.text = "TUTORIAL — %d / %d" % [step + 1, _steps.size()]
	_body.text = String(_steps[step].text)

func _has_flag(flag: String) -> bool:
	for cell: Vector2i in WorldGrid.buildings:
		if BuildingDefs.get_def(WorldGrid.buildings[cell]).get(flag, false):
			return true
	return false

func _has_id(id: String) -> bool:
	for cell: Vector2i in WorldGrid.buildings:
		if WorldGrid.buildings[cell] == id:
			return true
	return false

func _any_drafted() -> bool:
	for pawn: Pawn in main.pawns:
		if pawn.drafted:
			return true
	return false
