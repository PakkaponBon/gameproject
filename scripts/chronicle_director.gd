class_name ChronicleDirector
extends Node
## The village remembers: a capped log of the things worth telling.
## Any system may emit EventBus.chronicle_entry; we stamp it with the date.
## Saved with the game; ChroniclePanel reads it back as a story.

const MAX_ENTRIES := 200

var entries: Array = []  # [{"tick": int, "text": String}]

func _ready() -> void:
	EventBus.chronicle_entry.connect(record)

func record(text: String) -> void:
	entries.append({"tick": GameClock.ticks, "text": text})
	if entries.size() > MAX_ENTRIES:
		entries.pop_front()

func date_of(tick: int) -> String:
	var day := tick / GameClock.TICKS_PER_DAY
	var season: String = GameClock.SEASON_NAMES[(day / GameClock.DAYS_PER_SEASON) % 4]
	var year := day / (GameClock.DAYS_PER_SEASON * 4) + 1
	return "Year %d, %s %d" % [year, season, day % GameClock.DAYS_PER_SEASON + 1]
