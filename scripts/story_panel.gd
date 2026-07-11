class_name StoryPanel
extends CanvasLayer
## Full-screen story beats: the city-fall intro and the Ruler of the
## Realm ending. Told, never shown — text on a dark screen, per the
## tone rules.

signal dismissed

var _to_menu := false

func _ready() -> void:
	visible = false
	layer = 9
	%StoryContinueButton.pressed.connect(_on_continue)

func show_story(title: String, body: String) -> void:
	_to_menu = false
	%StoryTitle.text = title
	%StoryBody.text = body
	visible = true
	GameClock.set_sim_paused(true)

## Terminal beat (game over): Continue returns to the main menu.
func show_ending(title: String, body: String) -> void:
	show_story(title, body)
	_to_menu = true

func _on_continue() -> void:
	visible = false
	GameClock.set_sim_paused(false)
	dismissed.emit()
	if _to_menu:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
