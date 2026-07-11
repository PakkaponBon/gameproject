extends Node
## Autoload (POLISH.md Phase 12): all SFX with pitch randomization and
## per-sound throttles, music that follows the raid state, day/night
## ambience, UI click sniffing, and the death hitstop.

const SOUNDS := {
	"hit": "res://assets/sfx/hit.wav",
	"thud": "res://assets/sfx/thud.wav",
	"spell": "res://assets/sfx/spell.wav",
	"horn": "res://assets/sfx/horn.wav",
	"death": "res://assets/sfx/death.wav",
	"chop": "res://assets/sfx/chop.wav",
	"mine": "res://assets/sfx/mine.wav",
	"hammer": "res://assets/sfx/hammer.wav",
	"eat": "res://assets/sfx/eat.wav",
	"step": "res://assets/sfx/step.wav",
	"bow": "res://assets/sfx/bow.wav",
	"hurt": "res://assets/sfx/hurt.wav",
	"click": "res://assets/sfx/click.wav",
}
const VOLUMES := {"step": -24.0, "click": -12.0, "hit": -6.0}
const MIN_INTERVALS := {"step": 0.12, "hit": 0.06, "thud": 0.08}
const CHECK_EVERY_TICKS := 15

var _players := {}
var _last_played := {}
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _village: AudioStream
var _raid: AudioStream
var _birds: AudioStream
var _crickets: AudioStream
var _raid_music := false
var _night := false
var _cooldown := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id: String in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = load(SOUNDS[id])
		player.volume_db = float(VOLUMES.get(id, -8.0))
		player.max_polyphony = 3
		add_child(player)
		_players[id] = player
	_village = load("res://assets/sfx/village_loop.wav")
	_raid = load("res://assets/sfx/raid_loop.wav")
	_birds = load("res://assets/sfx/birds_loop.wav")
	_crickets = load("res://assets/sfx/crickets_loop.wav")
	_music = _make_loop(_village, -16.0)
	_ambience = _make_loop(_birds, -14.0)
	EventBus.play_sfx.connect(play)
	GameClock.ticked.connect(_on_tick)

func play(id: String) -> void:
	if not _players.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(id, -1.0)) < float(MIN_INTERVALS.get(id, 0.03)):
		return
	_last_played[id] = now
	var player: AudioStreamPlayer = _players[id]
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()
	if id == "death":
		_hitstop()

## Brief slow-motion beat when someone dies. Real-time timer, so it
## recovers even while the sim is paused.
func _hitstop() -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.12, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_tick() -> void:
	_cooldown -= 1
	if _cooldown > 0:
		return
	_cooldown = CHECK_EVERY_TICKS
	var raiding := not get_tree().get_nodes_in_group("raiders").is_empty()
	if raiding != _raid_music:
		_raid_music = raiding
		_music.stream = _raid if raiding else _village
		_music.play()
	if GameClock.is_night() != _night:
		_night = GameClock.is_night()
		_ambience.stream = _crickets if _night else _birds
		_ambience.play()

## Soft click for any UI button press, without wiring every button.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered is Button:
			play("click")

func _make_loop(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(func() -> void: player.play())
	player.play()
	return player
