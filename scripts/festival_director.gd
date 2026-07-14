class_name FestivalDirector
extends Node
## Three festivals a year. Work continues — a festival is mood, an evening
## gathering, and a chronicle line, never a cutscene. The static
## active_name lets pawns check for it without holding a reference.

const FESTIVALS := {  # season index -> festival (day is 1-based in season)
	0: {"day": 1, "name": "Founding Day",
			"line": "Founding Day — the village toasts another year built from nothing."},
	2: {"day": 1, "name": "Firstfruits",
			"line": "Firstfruits — the harvest is blessed and every table is full."},
	3: {"day": 3, "name": "Emberlight",
			"line": "Emberlight — candles burn through the longest night, one for every name Vhal took."},
}

static var active_name := ""

@onready var main: Node2D = get_parent()

func _ready() -> void:
	active_name = ""  # statics outlive scene reloads; start each world quiet
	GameClock.day_started.connect(_on_day_started)

func _on_day_started(_day: int) -> void:
	active_name = ""
	var season := GameClock.season_index()
	if not FESTIVALS.has(season):
		return
	var fest: Dictionary = FESTIVALS[season]
	var day_in_season := GameClock.total_days() % GameClock.DAYS_PER_SEASON + 1
	if day_in_season != int(fest.day):
		return
	active_name = String(fest.name)
	for pawn: Pawn in main.pawns:
		pawn.needs.celebrate()
	main.hud.set_event(String(fest.line), Color(0.95, 0.85, 0.55))
	EventBus.chronicle_entry.emit(String(fest.line))
