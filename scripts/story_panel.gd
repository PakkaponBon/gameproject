class_name StoryPanel
extends CanvasLayer
## Full-screen story beats: the city-fall intro and the Ruler of the
## Realm ending. Told, never shown — text on a dark screen, per the
## tone rules.

signal dismissed

func _ready() -> void:
	visible = false
	layer = 9
	%StoryContinueButton.pressed.connect(_on_continue)

func show_story(title: String, body: String) -> void:
	%StoryTitle.text = title
	%StoryBody.text = body
	visible = true
	GameClock.set_sim_paused(true)

func _on_continue() -> void:
	visible = false
	GameClock.set_sim_paused(false)
	dismissed.emit()
