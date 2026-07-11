class_name StoryPanel
extends CanvasLayer
## Full-screen story beats: the city-fall intro and the Ruler of the
## Realm ending. Told, never shown — text on a dark screen, per the
## tone rules.

signal dismissed

var _to_menu := false
var _pages: Array = []
var _page := 0

func _ready() -> void:
	visible = false
	layer = 9
	%StoryContinueButton.pressed.connect(_on_continue)
	%StorySkipButton.pressed.connect(_close)

func show_story(title: String, body: String) -> void:
	show_pages([{"title": title, "body": body}])

## Multi-panel story beat (the intro). Skippable, per POLISH.md.
func show_pages(pages: Array) -> void:
	_to_menu = false
	_pages = pages
	_page = 0
	_show_current()
	visible = true
	GameClock.set_sim_paused(true)

func _show_current() -> void:
	%StoryTitle.text = _pages[_page].title
	%StoryBody.text = _pages[_page].body
	%StoryContinueButton.text = "Continue" if _page < _pages.size() - 1 else "Begin"
	%StorySkipButton.visible = _pages.size() > 1 and _page < _pages.size() - 1

## Terminal beat (game over): Continue returns to the main menu.
func show_ending(title: String, body: String) -> void:
	show_story(title, body)
	_to_menu = true

func _on_continue() -> void:
	_page += 1
	if _page < _pages.size():
		_show_current()
	else:
		_close()

func _close() -> void:
	visible = false
	GameClock.set_sim_paused(false)
	dismissed.emit()
	if _to_menu:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
