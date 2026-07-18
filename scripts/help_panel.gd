class_name HelpPanel
extends CanvasLayer
## The in-game manual (H / the ? button). Three tabs: how the game plays,
## what every building is for (built from BuildingDefs), and the keys.

const TILES := preload("res://assets/tiles.png")

const PLAY_TEXT := """YOUR GOAL
Your city burned. Rebuild the village from nothing, arm it, and deal with the five factions around you — ally them or conquer them — until you rule the realm.

YOU DON'T CONTROL VILLAGERS DIRECTLY
You set the work; they choose the nearest job themselves. Click a villager to see their card. The Chop / Haul / Build / Farm buttons set priority (1 = do first, off = never). If someone stands idle, their card tells you exactly why.

THE FIRST DAY OR TWO
1. FOOD — Press F and drag a Field near your people. They plant and harvest on their own. Berry bushes and hunted rabbits also feed you.
2. STORAGE — Press B and build a Barn so loose wood and food get stored.
3. BEDS — Build a Bed for each villager so they sleep and heal.
4. WALLS — Wall the colony and leave a Gate as the entrance. The first raid comes at the end of Day 2.
5. ARMS — Build a Forge, mine iron, and craft swords and bows before the raiders arrive.

KEEPING THEM ALIVE AND HAPPY
Villagers have needs: hunger, rest, warmth (in winter), joy, and overall mood. Meals from a stove, beds, a warm room with a hearth, furniture, ale from a brewery, and festivals all lift mood. A miserable villager works slowly or has a breakdown.

RAIDS AND FIGHTING
Press R to draft a villager — drafted fighters take your orders (click an enemy to attack) and ignore all work. Undrafted villagers flee to your Safety zone (X). IMPORTANT: undraft (R) after the fight, or they'll just stand around idle.

THE WORLD (press M)
The map shows the five factions. Send gifts and envoys to warm them toward alliance, or attack to grind them down. Resolve all five — by friendship or force — to win."""

const KEYS_TEXT := """MOUSE
  Left click — select villager / move / attack (drafted) / talk to merchant
  Right click — remove, cancel, (in a zone) erase, or set a workstation's recipe

TOOLS (or click the bottom toolbar)
  B — build      Z — stockpile zone      F — fields      X — safety zone
  Q — cycle the building or crop in the current tool

VILLAGERS
  R — draft/undraft selected      1-4 — cycle work priorities
  P — priority grid (all villagers at once)

WORLD
  M — world map      C — chronicle      Esc — menu (save/load)
  Space — pause      E — cycle game speed"""

var _panel: PanelContainer

func _ready() -> void:
	visible = false
	layer = 9
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "HOW TO PLAY"
	title.theme_type_variation = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(580, 400)
	box.add_child(tabs)
	_add_text_tab(tabs, "Play", PLAY_TEXT)
	_add_buildings_tab(tabs)
	_add_text_tab(tabs, "Keys", KEYS_TEXT)
	var close := Button.new()
	close.text = "Close [H]"
	close.pressed.connect(toggle)
	box.add_child(close)

func _add_text_tab(tabs: TabContainer, tab_name: String, text: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(560, 0)
	scroll.add_child(label)
	tabs.add_child(scroll)

## One row per building: its tile icon, name + cost, and what it's for.
func _add_buildings_tab(tabs: TabContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Buildings"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.custom_minimum_size = Vector2(560, 0)
	scroll.add_child(list)
	for id: String in BuildingDefs.ORDER:
		var def := BuildingDefs.get_def(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = TILES
		atlas.region = Rect2(def.tile.x * 16, 0, 16, 16)
		icon.texture = atlas
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var costs: Array[String] = []
		for res: String in def.cost:
			costs.append("%d %s" % [int(def.cost[res]), res])
		var heading := Label.new()
		heading.theme_type_variation = "Title"
		heading.add_theme_font_size_override("font_size", 15)
		heading.text = "%s   (%s)" % [def.name, " + ".join(costs) if not costs.is_empty() else "free"]
		text.add_child(heading)
		var desc := Label.new()
		desc.theme_type_variation = "Muted"
		desc.text = BuildingDefs.desc(id)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(500, 0)
		text.add_child(desc)
		row.add_child(text)
		list.add_child(row)
	tabs.add_child(scroll)

func toggle() -> void:
	visible = not visible
	GameClock.set_sim_paused(visible)
