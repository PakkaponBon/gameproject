extends Node
## Autoload: fixed simulation tick, decoupled from render framerate.

signal ticked

const TICKS_PER_SECOND := 10.0

var ticks := 0  # total simulation ticks; persisted in saves

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0 / TICKS_PER_SECOND
	timer.autostart = true
	timer.timeout.connect(_on_timeout)
	add_child(timer)

func _on_timeout() -> void:
	ticks += 1
	ticked.emit()
