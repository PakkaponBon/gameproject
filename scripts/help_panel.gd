class_name HelpPanel
extends CanvasLayer
## Controls overlay (H). The single best answer to "how do I...?"

const HELP_TEXT := """MOUSE
  Left click — select villager / move / attack (drafted) / talk to merchant
  Right click — remove, cancel, or (in zones) erase

TOOLS
  B — build mode (Q cycles buildings)      Z — stockpile zone
  F — field mode (Q cycles crops)          X — safety zone (flee here in raids)

VILLAGERS
  R — draft/undraft selected               1-4 — cycle work priorities
  P — priority grid                        Roster bar: click select, right-click draft

WORLD
  M — world map (diplomacy, expeditions)   Esc — menu (save/load)
  Space — pause                            E — game speed 1x/3x

SURVIVAL BASICS
  Villagers work on their own: chop, farm, haul, build, craft.
  Feed them (fields!), give them beds, wall the colony, keep a gate.
  Wounded villagers heal in bed; herbs help. The forge turns ore into arms."""

var _panel: PanelContainer

func _ready() -> void:
	visible = false
	layer = 9
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var body := Label.new()
	body.text = HELP_TEXT
	box.add_child(body)
	var close := Button.new()
	close.text = "Close [H]"
	close.pressed.connect(toggle)
	box.add_child(close)

func toggle() -> void:
	visible = not visible
	GameClock.set_sim_paused(visible)
