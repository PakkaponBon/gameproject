extends Control
## Title screen: new game / load / quit. The .md files call it Ashfall.

func _ready() -> void:
	%NewGameButton.pressed.connect(func() -> void:
		SaveManager.pending_load = {}
		get_tree().change_scene_to_file("res://scenes/main.tscn"))
	%LoadGameButton.pressed.connect(func() -> void:
		SaveManager.load_game(SaveManager.MANUAL_SAVE_PATH))
	%QuitButton.pressed.connect(func() -> void: get_tree().quit())
	%LoadGameButton.disabled = not FileAccess.file_exists(SaveManager.MANUAL_SAVE_PATH)
