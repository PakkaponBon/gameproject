class_name LongNightDirector
extends Node
## Act III — the Ashen Legion's final siege. When the four other factions
## are resolved and the Legion still stands, it stops raiding and comes to
## finish Vhal's work: a warning to prepare, then escalating waves with
## lulls to heal, the last led by the Cindermarked. Survive all of it and
## the Legion breaks — and the realm, and Vhal, are yours.

enum Phase { DORMANT, WARNING, WAVE, LULL, WON }

const WARNING_TICKS := int(GameClock.TICKS_PER_DAY * 1.5)
const LULL_TICKS := int(GameClock.TICKS_PER_DAY * 0.4)
const WAVES := [
	{"size": 4, "boss": false},
	{"size": 6, "boss": false},
	{"size": 8, "boss": false},
	{"size": 10, "boss": true},  # the Cindermarked leads the last
]

var phase := Phase.DORMANT
var wave_index := 0
var timer := 0

@onready var main: Node2D = get_parent()

func _ready() -> void:
	FactionManager.long_night_begins.connect(_begin)
	GameClock.ticked.connect(_on_tick)

## Save/load: resume the siege exactly where it stood.
func restore(saved_phase: int, saved_wave: int, saved_timer: int) -> void:
	phase = saved_phase
	wave_index = saved_wave
	timer = saved_timer
	if phase in [Phase.WARNING, Phase.WAVE, Phase.LULL]:
		main.raid_director.siege_active = true

func _begin() -> void:
	if phase != Phase.DORMANT:
		return
	phase = Phase.WARNING
	timer = WARNING_TICKS
	main.raid_director.siege_active = true
	EventBus.chronicle_entry.emit("The realm fell quiet, and then the Legion came for Ashfall itself.")
	main.story_panel.show_pages([
		{"title": "THE LONG NIGHT", "body":
			"The realm is settled. Four powers bow or are broken —\n"
			+ "and the fifth has stopped sending raiders.\n\n"
			+ "The Ashen Legion is coming. All of it. For you."},
		{"title": "AS THEY CAME FOR VHAL", "body":
			"They mean to finish what they began the night your city burned.\n\n"
			+ "You have a little time. Arm your people, mend the walls,\n"
			+ "lay your traps. Call in every oath.\n\n"
			+ "Then hold. Hold, and the Long Night ends with them."},
	])

func _on_tick() -> void:
	match phase:
		Phase.WARNING:
			timer -= 1
			if timer <= 0:
				_start_wave()
		Phase.WAVE:
			if get_tree().get_nodes_in_group("raiders").is_empty():
				wave_index += 1
				if wave_index >= WAVES.size():
					_win()
				else:
					phase = Phase.LULL
					timer = LULL_TICKS
					main.hud.set_event("Wave broken. They fall back to regroup — tend your wounded.",
							Color(0.9, 0.85, 0.55))
		Phase.LULL:
			timer -= 1
			if timer <= 0:
				_start_wave()

func _start_wave() -> void:
	phase = Phase.WAVE
	var wave: Dictionary = WAVES[wave_index]
	main.raid_director.spawn_legion_wave(int(wave.size), bool(wave.boss))
	var label := "The Cindermarked leads the last wave — everything, now!" if bool(wave.boss) \
			else "Wave %d of %d — the Legion comes!" % [wave_index + 1, WAVES.size()]
	main.hud.set_event(label, Color(1.0, 0.4, 0.35))
	(main.get_node("Camera") as Camera2D).shake(1.2, 7.0)

func _win() -> void:
	phase = Phase.WON
	main.raid_director.siege_active = false
	FactionManager.break_the_legion()  # → realm_ruled → main shows the ending
