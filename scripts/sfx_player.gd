class_name SfxPlayer
extends Node
## Placeholder audio: procedural SFX via EventBus.play_sfx, and two music
## loops that swap with the raid state. Scene-local to Main.

const SOUNDS := {
	"hit": "res://assets/sfx/hit.wav",
	"thud": "res://assets/sfx/thud.wav",
	"spell": "res://assets/sfx/spell.wav",
	"horn": "res://assets/sfx/horn.wav",
	"death": "res://assets/sfx/death.wav",
}
const CHECK_EVERY_TICKS := 15

var _players := {}
var _music: AudioStreamPlayer
var _village: AudioStream
var _raid: AudioStream
var _raid_music := false
var _cooldown := 0

func _ready() -> void:
	for id: String in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = load(SOUNDS[id])
		player.volume_db = -8.0
		add_child(player)
		_players[id] = player
	_village = load("res://assets/sfx/village_loop.wav")
	_raid = load("res://assets/sfx/raid_loop.wav")
	_music = AudioStreamPlayer.new()
	_music.volume_db = -14.0
	_music.stream = _village
	add_child(_music)
	_music.finished.connect(func() -> void: _music.play())  # manual loop
	_music.play()
	EventBus.play_sfx.connect(_on_play)
	GameClock.ticked.connect(_on_tick)

func _on_play(id: String) -> void:
	if _players.has(id):
		_players[id].play()

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
